// (c) 2010 by Anton Korenyushkin

@implementation Entity : CPObject
{
    CPString name @accessors;
}

- (id)initWithName:(CPString)aName // public
{
    if (self = [super init])
        name = aName;
    return self;
}

@end

@implementation Entry : Entity
{
    Folder parentFolder @accessors;
}

- (id)initWithName:(CPString)aName parentFolder:(Folder)aParentFolder // public
{
    if (self = [super initWithName:aName])
        parentFolder = aParentFolder;
    return self;
}

- (CPString)path // public
{
    var parts = [];
    for (var entry = self; entry.name; entry = entry.parentFolder)
        parts.unshift(entry.name);
    return parts.join("/");
}

@end

DOMFile = File;

@implementation File : Entry
{
    CPString content @accessors;
}

- (id)initWithName:(CPString)aName parentFolder:(Folder)aParentFolder content:(CPString)aContent // public
{
    if (self = [self initWithName:aName parentFolder:aParentFolder])
        content = aContent;
    return self;
}

@end

@implementation Folder : Entry
{
    CPArray folders;
    CPArray files;
}

- (id)initWithName:(CPString)aName parentFolder:(Folder)aParentFolder folders:(CPArray)folders_ files:(CPArray)files_ // public
{
    if (self = [super initWithName:aName parentFolder:aParentFolder]) {
        folders = folders_;
        files = files_;
    }
    return self;
}

- (id)initWithName:(CPString)aName parentFolder:(Folder)aParentFolder tree:(JSObject)tree // public
{
    if (self = [super initWithName:aName parentFolder:aParentFolder]) {
        var folderNames = [];
        var fileNames = [];
        for (var childName in tree)
            (tree[childName] ? folderNames : fileNames).push(childName);
        folders = folderNames.sort().map(
            function (folderName) { return [[Folder alloc] initWithName:folderName parentFolder:self tree:tree[folderName]]; });
        files = fileNames.sort().map(
            function (fileName) { return [[File alloc] initWithName:fileName parentFolder:self]; });
    }
    return self;
}

- (id)initWithTree:(JSObject)tree // public
{
    return [self initWithName:"" parentFolder:nil tree:tree];
}

- (id)initWithName:(CPString)aName parentFolder:(Folder)aParentFolder // public
{
    return [self initWithName:aName parentFolder:aParentFolder folders:[] files:[]];
}

- (Entry)childWithName:(CPString)aName // public
{
    for (var i = 0; i < folders.length; ++i)
        if (folders[i].name == aName)
            return folders[i];
    for (var i = 0; i < files.length; ++i)
        if (files[i].name == aName)
            return files[i];
    return nil;
}

@end

@implementation Env : Entity
@end

@implementation Lib : Entity
{
    CPString identifier;
    CPString authorName;
    CPString appName;
    CPString version;
}

+ (CPString)identifierForAuthorName:(CPString)authorName appName:(CPString)appName version:(CPString)version // public
{
    return authorName + "/" + appName + ":" + version;
}

- (id)initWithName:(CPString)aName
        authorName:(CPString)anAuthorName
           appName:(CPString)anAppName
           version:(CPString)aVersion // public
{
    if (self = [super initWithName:aName]) {
        authorName = anAuthorName;
        appName = anAppName;
        version = aVersion;
        identifier = [Lib identifierForAuthorName:authorName appName:appName version:version];
    }
    return self;
}

- (id)initWithName:(CPString)aName identifier:(CPString)anIdentifier // public
{
    if (self = [super initWithName:aName]) {
        identifier = anIdentifier;
        var slashIndex = identifier.indexOf("/");
        var colonIndex = identifier.indexOf(":", slashIndex + 1);
        if (slashIndex != -1 && colonIndex != -1) {
            authorName = identifier.substring(0, slashIndex);
            appName = identifier.substring(slashIndex + 1, colonIndex);
            version = identifier.substring(colonIndex + 1);
        }
    }
    return self;
}

@end

var bufferSubclasses = {};

@implementation Buffer : CPObject
{
    BOOL isProcessing;
}

- (id)init // public
{
    if (self = [super init])
        isProcessing = NO;
    return self;
}

- (void)setProcessing:(BOOL)flag // public
{
    if (isProcessing == !!flag)
        return;
    isProcessing = !!flag;
    [self didChangeValueForKey:"isProcessing"];
}

- (BOOL)isModified // public
{
    return NO;
}

- (BOOL)isEditable // public
{
    return NO;
}

- (BOOL)isEqual:(id)other // public
{
    if (self === other)
        return YES;
    if ([self class] !== [other class])
        return NO;
    return [self isEqualToSameClassBuffer:other];
}

- (BOOL)isEqualToSameClassBuffer:(Buffer)other // protected
{
    return YES;
}

+ (void)registerSubclass:(Class)subclass withTypeName:(CPString)typeName // protected
{
    bufferSubclasses[typeName] = subclass;
    subclass.typeName = typeName;
}

- (JSObject)archive // public
{
    var archive = {type: [self class].typeName};
    [self archiveTo:archive];
    return archive;
}

- (void)archiveTo:(JSObject)archive // protected
{
}

- (id)initWithApp:(App)app archive:(JSObject)archive // protected
{
    return [self init];
}

+ (Buffer)bufferOfApp:(App)app fromArchive:(JSObject)archive // public
{
    return [[bufferSubclasses[archive.type] alloc] initWithApp:app archive:archive];
}

- (void)observeValueForKeyPath:(CPString)keyPath ofObject:(id)object change:(CPDictionary)change context:(id)context // private
{
    [self didChangeValueForKey:"name"];
}

@end

@implementation FileBuffer : Buffer
{
    BOOL isEditable @accessors(readonly);
}

- (id)init // public
{
    if (self = [super init])
        isEditable = NO;
    return self;
}

- (void)setEditable:(BOOL)flag // public
{
    if (isEditable == !!flag)
        return;
    isEditable = !!flag;
    [self didChangeValueForKey:"isEditable"];
}

@end

@implementation CodeFileBuffer : FileBuffer
{
    File file;
    BOOL isModified @accessors(readonly);
}

- (id)initWithFile:(File)aFile // public
{
    if (self = [super init]) {
        file = aFile;
        isModified = NO;
        [file addObserver:self forKeyPath:"name"];
    }
    return self;
}

- (void)setModified:(BOOL)flag // public
{
    if (isModified == !!flag)
        return;
    isModified = !!flag;
    [self didChangeValueForKey:"isModified"];
}

- (CPString)name // public
{
    return file.name;
}

- (BOOL)isEqualToSameClassBuffer:(CodeFileBuffer)other // protected
{
    return file === other.file;
}

- (void)archiveTo:(JSObject)archive // protected
{
    archive.path = [file path];
}

- (id)initWithApp:(App)app archive:(JSObject)archive // protected
{
    var parts = archive.path.split("/");
    var folder = app.code;
    for (var i = 0; i < parts.length - 1; ++i) {
        folder = [folder childWithName:parts[i]];
        if (![folder isKindOfClass:Folder])
            return nil;
    }
    var aFile = [folder childWithName:parts[parts.length - 1]];
    return [aFile isKindOfClass:File] ? [self initWithFile:aFile] : nil;
}

@end

[Buffer registerSubclass:CodeFileBuffer withTypeName:"code file"];

@implementation LibFileBuffer : FileBuffer
{
    Lib lib;
    CPString path;
}

- (id)initWithLib:(Lib)aLib path:(CPString)aPath // public
{
    if (self = [super init]) {
        lib = aLib;
        path = aPath;
        [lib addObserver:self forKeyPath:"name"];
    }
    return self;
}

- (CPString)name // public
{
    return path.substring(path.lastIndexOf("/") + 1) + " – " + lib.name; // EN DASH
}

- (BOOL)isEqualToSameClassBuffer:(LibFileBuffer)other // protected
{
    return lib === other.lib && path == other.path;
}

- (void)archiveTo:(JSObject)archive // protected
{
    archive.lib = lib.name;
    archive.path = path;
}

- (id)initWithApp:(App)app archive:(JSObject)archive // protected
{
    var aLib = [app libWithName:archive.lib];
    return aLib ? [self initWithLib:aLib path:archive.path] : nil;
}

@end

[Buffer registerSubclass:LibFileBuffer withTypeName:"lib file"];

@implementation EvalBuffer : Buffer
{
    Env env;
}

- (id)initWithEnv:(Env)anEnv // public
{
    if (self = [super init]) {
        env = anEnv;
        [env addObserver:self forKeyPath:"name"];
    }
    return self;
}

- (CPString)name // public
{
    return env.name;
}

- (BOOL)isEqualToSameClassBuffer:(EvalBuffer)other // protected
{
    return env === other.env;
}

- (void)archiveTo:(JSObject)archive // protected
{
    archive.env = env.name;
}

- (id)initWithApp:(App)app archive:(JSObject)archive // protected
{
    var anEnv = [app envWithName:archive.env];
    return anEnv ? [self initWithEnv:anEnv] : nil;
}

@end

[Buffer registerSubclass:EvalBuffer withTypeName:"eval"];

@implementation CommitBuffer : Buffer

- (CPString)name // public
{
    return "Commit";
}

@end

[Buffer registerSubclass:CommitBuffer withTypeName:"commit"];

@implementation GitBuffer : Buffer

- (CPString)name // public
{
    return "Git";
}

@end

[Buffer registerSubclass:GitBuffer withTypeName:"git"];

@implementation App : Entity
{
    BOOL isPublic @accessors;
    JSObject oldArchive;
    Folder code @accessors;
    CPArray envs @accessors;
    CPArray libs @accessors;
    CPArray buffers @accessors; // private setter
    unsigned bufferIndex;
    Buffer buffer @accessors; // private setter
    unsigned numberOfModifiedBuffers @accessors;
}

- (id)initWithName:(CPString)aName isPublic:(BOOL)flag archive:(JSObject)archive // public
{
    if (self = [super initWithName:aName]) {
        isPublic = flag;
        oldArchive = archive;
    }
    return self;
}

- (id)initWithName:(CPString)aName // public
{
    return [self initWithName:aName isPublic:NO archive:{}];
}

- (void)setPublic:(BOOL)flag // public
{
    isPublic = !!flag;
    [self didChangeValueForKey:"isPublic"];
}

- (CPString)URL // public
{
    return "/apps/" + name + "/";
}

- (CPString)URLOfEnv:(Env)env // public
{
    return "http://" + env.name + "." + DATA.username + "." + name + location.host.substring(3);
}

- (Env)envWithName:(CPString)aName // public
{
    var nameLower = aName.toLowerCase();
    for (var i = 0; i < envs.length; ++i)
        if (envs[i].name.toLowerCase() == nameLower)
            return envs[i];
    return nil;
}

- (Lib)libWithName:(CPString)aName // public
{
    for (var i = 0; i < libs.length; ++i)
        if (libs[i].name == aName)
            return libs[i];
    return nil;
}

- (CPArray)setupBuffers // public
{
    var restoredBuffers = [];
    if (oldArchive.buffers) {
        for (var i = 0; i < oldArchive.buffers.length; ++i) {
            var restoredBuffer = [Buffer bufferOfApp:self fromArchive:oldArchive.buffers[i]];
            if (restoredBuffer)
                restoredBuffers.push(restoredBuffer);
        }
    } else {
        var file = [code childWithName:"main.js"];
        if (file)
            restoredBuffers.push([[CodeFileBuffer alloc] initWithFile:file]);
    }
    [self setBuffers:restoredBuffers];
    [self setBufferIndex:oldArchive.bufferIndex ? MIN(oldArchive.bufferIndex, buffers.length - 1) : 0];
    numberOfModifiedBuffers = 0;
}

- (void)setBufferIndex:(unsigned)aBufferIndex // public
{
    bufferIndex = aBufferIndex;
    if (buffer !== buffers[bufferIndex])
        [self setBuffer:buffers[bufferIndex]];
}

- (JSObject)archive // public
{
    return (buffers
            ? {buffers: buffers.map(function (buffer) { return [buffer archive]; }), bufferIndex: bufferIndex}
            : oldArchive);
}

@end

@implementation Data : CPObject
{
    CPString username @accessors;
    CPString email @accessors;
    CPArray apps @accessors; // private setter
    unsigned appIndex;
    App app @accessors; // private setter
}

- (void)loadFromBasis:(JSObject)basis // public
{
    [self setUsername:basis.username];
    [self setEmail:basis.email];
    var appsArchive = basis.config.apps || {};
    [self setApps:basis.appNames.map(
            function (name) {
                return [[App alloc] initWithName:name
                                        isPublic:basis.libNames.indexOf(name) != -1
                                         archive:appsArchive[name] || {}];
            })];
    [self setAppIndex:basis.config.appIndex && apps.length ? MIN(basis.config.appIndex, apps.length - 1) : 0];
}

- (void)setAppIndex:(unsigned)anAppIndex // public
{
    appIndex = anAppIndex;
    if (app !== apps[appIndex])
        [self setApp:apps[appIndex] || nil];
}

- (JSObject)archive // public
{
    var archive = {appIndex: appIndex, apps: {}};
    apps.forEach(function (app) { archive.apps[app.name] = [app archive]; });
    return archive;
}

@end
