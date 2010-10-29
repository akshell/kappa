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

@implementation File : Entry
{
    CPString currentContent @accessors;
    CPString savedContent @accessors;
}

- (id)initWithName:(CPString)aName parentFolder:(Folder)aParentFolder content:(CPString)content // public
{
    if (self = [self initWithName:aName parentFolder:aParentFolder])
        savedContent = currentContent = content;
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

- (BOOL)isModified // public
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

+ (Buffer)bufferOfApp:(App)app fromArchive:(JSObject)archive // public
{
    return [[bufferSubclasses[archive.type] alloc] initWithApp:app archive:archive];
}

@end

@implementation FileBuffer : Buffer
@end

@implementation CodeFileBuffer : FileBuffer
{
    File file @accessors(readonly);
}

- (id)initWithFile:(File)aFile // public
{
    if (self = [super init])
        file = aFile;
    return self;
}

- (CPString)name // public
{
    return file.name;
}

- (BOOL)isModified // public
{
    return file.currentContent != file.savedContent;
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
    }
    return self;
}

- (CPString)name // public
{
    return path.substring(path.lastIndexOf("/") + 1) + " (" + lib.name + ")";
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

@implementation GitBuffer : Buffer

- (CPString)name // public
{
    return "Git";
}

- (BOOL)isEqualToSameClassBuffer:(GitFileBuffer)other // protected
{
    return YES;
}

- (void)archiveTo:(JSObject)archive // protected
{
}

- (id)initWithApp:(App)app archive:(JSObject)archive // protected
{
    return [super init];
}

@end

[Buffer registerSubclass:GitBuffer withTypeName:"git"];

@implementation EvalBuffer : Buffer
{
    Env env;
}

- (id)initWithEnv:(Env)anEnv // public
{
    if (self = [super init])
        env = anEnv;
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

@implementation WebBuffer : Buffer
{
    CPString url @accessors(property=URL);
    CPString title @accessors;
}

- (id)initWithURL:(CPString)anURL title:(CPString)aTitle // public
{
    if (self = [super init]) {
        url = anURL;
        title = aTitle;
    }
    return self;
}

- (BOOL)isEqualToSameClassBuffer:(WebBuffer)other // protected
{
    return url == other.url;
}

- (void)archiveTo:(JSObject)archive // protected
{
    archive.url = url;
    archive.title = title;
}

- (id)initWithApp:(App)app archive:(JSObject)archive // protected
{
    return [self initWithURL:archive.url title:archive.title];
}

@end

@implementation HelpBuffer : WebBuffer

- (id)initWithURL:(CPString)anURL // public
{
    return [super initWithURL:anURL title:"Help"];
}

- (CPString)name // public
{
    return title;
}

@end

[Buffer registerSubclass:HelpBuffer withTypeName:"help"];

@implementation PreviewBuffer : WebBuffer
{
    Env env;
}

- (id)initWithApp:(App)app env:(Env)anEnv // public
{
    if (self = [super initWithURL:[app URLofEnv:anEnv] title:"Preview"])
        env = anEnv;
    return self;
}

- (CPString)name // public
{
    return title + " (" + env.name + ")";
}

- (void)archiveTo:(JSObject)archive // protected
{
    archive.env = env.name;
    [super archiveTo:archive];
}

- (id)initWithApp:(App)app archive:(JSObject)archive // protected
{
    env = [app envWithName:archive.env];
    return env ? [super initWithApp:app archive:archive] : nil;
}

@end

[Buffer registerSubclass:PreviewBuffer withTypeName:"preview"];

@implementation App : Entity
{
    JSObject oldArchive;
    Folder code @accessors;
    CPArray envs @accessors;
    CPArray libs @accessors;
    CPArray buffers @accessors; // private setter
    unsigned bufferIndex;
    Buffer buffer @accessors; // private setter
}

- (id)initWithName:(CPString)aName archive:(JSObject)archive // public
{
    if (self = [super initWithName:aName])
        oldArchive = archive;
    return self;
}

- (id)initWithName:(CPString)aName // public
{
    return [self initWithName:aName archive:{}];
}

- (CPString)URL // public
{
    return "/apps/" + name + "/";
}

- (CPString)URLofEnv:(Env)env // public
{
    return env.name + ".TODO";
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
            var buffer = [Buffer bufferOfApp:self fromArchive:oldArchive.buffers[i]];
            if (buffer)
                restoredBuffers.push(buffer);
        }
    } else {
        var file = [code childWithName:"main.js"];
        if (file)
            restoredBuffers.push([[CodeFileBuffer alloc] initWithFile:file]);
    }
    [self setBuffers:restoredBuffers];
    [self setBufferIndex:oldArchive.bufferIndex ? MIN(oldArchive.bufferIndex, buffers.length - 1) : 0];
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
    CPArray apps;
    unsigned appIndex;
    App app @accessors; // private setter
}

- (id)init // public
{
    if (self = [super init]) {
        username = window.USERNAME;
        email = window.EMAIL;
        [self setAppNames:window.APP_NAMES || [] config:window.CONFIG || {}];
    }
    return self;
}

- (void)setAppNames:(CPArray)appNames config:(JSObject)config // public
{
    [self willChangeValueForKey:"apps"];
    var appsArchive = config.apps || {};
    apps = appNames.map(function (name) { return [[App alloc] initWithName:name archive:appsArchive[name] || {}]; });
    [self setAppIndex:config.appIndex && apps.length ? MIN(config.appIndex, apps.length - 1) : 0];
    [self didChangeValueForKey:"apps"];
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
