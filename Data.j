// (c) 2010 by Anton Korenyushkin

@implementation Entity : CPObject
{
    CPString name @accessors;
}

- (id)initWithName:(CPString)aName
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

- (id)initWithName:(CPString)aName parentFolder:(Folder)aParentFolder
{
    if (self = [super initWithName:aName])
        parentFolder = aParentFolder;
    return self;
}

@end

@implementation File : Entry
{
    CPString currentContent @accessors;
    CPString savedContent @accessors;
}

- (id)initEmptyWithName:(CPString)aName parentFolder:(Folder)aParentFolder
{
    if (self = [self initWithName:aName parentFolder:aParentFolder])
        savedContent = currentContent = "";
    return self;
}

@end

@implementation Folder : Entry
{
    CPArray folders;
    CPArray files;
}

- (id)initWithName:(CPString)aName parentFolder:(Folder)aParentFolder folders:(CPArray)folders_ files:(CPArray)files_
{
    if (self = [super initWithName:aName parentFolder:aParentFolder]) {
        folders = folders_;
        files = files_;
    }
    return self;
}

- (id)initWithName:(CPString)aName parentFolder:(Folder)aParentFolder tree:(JSObject)tree
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

- (id)initWithTree:(JSObject)tree
{
    return [self initWithName:"" parentFolder:nil tree:tree];
}

- (id)initWithName:(CPString)aName parentFolder:(Folder)aParentFolder
{
    return [self initWithName:aName parentFolder:aParentFolder folders:[] files:[]];
}

- (Entry)childWithName:(CPString)aName
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

+ (CPString)identifierForAuthorName:(CPString)authorName appName:(CPString)appName version:(CPString)version
{
    return authorName + "/" + appName + ":" + version;
}

- (id)initWithName:(CPString)aName
        authorName:(CPString)anAuthorName
           appName:(CPString)anAppName
           version:(CPString)aVersion
{
    if (self = [super initWithName:aName]) {
        authorName = anAuthorName;
        appName = anAppName;
        version = aVersion;
        identifier = [Lib identifierForAuthorName:authorName appName:appName version:version];
    }
    return self;
}

- (id)initWithName:(CPString)aName identifier:(CPString)anIdentifier
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

@implementation App : Entity
{
    Folder code @accessors;
    CPArray envs @accessors;
    CPArray libs @accessors;
}

- (CPString)URL
{
    return "/apps/" + name + "/";
}

- (Env)envWithName:(CPString)aName
{
    var nameLower = aName.toLowerCase();
    for (var i = 0; i < envs.length; ++i)
        if (envs[i].name.toLowerCase() == nameLower)
            return envs[i];
    return nil;
}

- (Lib)libWithName:(CPString)aName
{
    for (var i = 0; i < libs.length; ++i)
        if (libs[i].name == aName)
            return libs[i];
    return nil;
}

@end

@implementation Data : CPObject
{
    BOOL isDirty;
    CPString username @accessors;
    CPString email @accessors;
    CPArray apps;
    unsigned appIndex;
    App app;
    JSObject libs;
}

- (id)init
{
    if (self = [super init]) {
        username = USERNAME;
        email = EMAIL;
        [self setAppNames:APP_NAMES config:CONFIG];
        libs = {};
        isDirty = NO;
        window.onbeforeunload = function () {
            if (!isDirty)
                return;
            var request = new XMLHttpRequest();
            request.open("PUT", "/config", false);
            request.setRequestHeader("X-Requested-With", "XMLHttpRequest");
            request.setRequestHeader("Content-Type", "application/json");
            request.send(JSON.stringify({appIndex: appIndex}));
        };
    }
    return self;
}

- (void)setAppNames:(CPArray)appNames config:(JSObject)config
{
    [self willChangeValueForKey:"apps"];
    apps = appNames.map(function (name) { return [[App alloc] initWithName:name]; });
    [self setAppIndex:config.appIndex && apps.length ? MIN(config.appIndex, apps.length - 1) : 0];
    [self didChangeValueForKey:"apps"];
}

- (void)setAppIndex:(unsigned)anAppIndex
{
    isDirty = YES;
    appIndex = anAppIndex;
    if (app !== apps[appIndex]) {
        [self willChangeValueForKey:"app"];
        app = apps[appIndex] || nil;
        [self didChangeValueForKey:"app"];
    }
}

@end
