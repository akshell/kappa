// (c) 2010 by Anton Korenyushkin

@implementation Entry : CPObject
{
    CPString name @accessors(readonly);
}

- (id)initWithName:(CPString)aName
{
    if (self = [super init])
        name = aName;
    return self;
}

@end

@implementation File : Entry
{
    CPString content @accessors;
}

@end

@implementation Folder : Entry
{
    CPArray folders;
    CPArray files;
}

- (id)initWithName:(CPString)aName folders:(CPArray)folders_ files:(CPArray)files_
{
    if (self = [super initWithName:aName]) {
        folders = folders_;
        files = files_;
    }
    return self;
}

- (id)initWithName:(CPString)aName tree:(JSObject)tree
{
    if (self = [super initWithName:aName]) {
        var folderNames = [];
        var fileNames = [];
        for (var childName in tree)
            (tree[childName] ? folderNames : fileNames).push(childName);
        folders = folderNames.sort().map(
            function (folderName) { return [[Folder alloc] initWithName:folderName tree:tree[folderName]]; });
        files = fileNames.sort().map(
            function (fileName) { return [[File alloc] initWithName:fileName]; });
    }
    return self;
}

- (id)initWithTree:(JSObject)tree
{
    return [self initWithName:"" tree:tree];
}

- (id)initWithName:(CPString)aName
{
    return [self initWithName:aName folders:[] files:[]];
}

- (BOOL)hasChildWithName:(CPString)aName
{
    for (var i = 0; i < folders.length; ++i)
        if (folders[i].name == aName)
            return YES;
    for (var i = 0; i < files.length; ++i)
        if (files[i].name == aName)
            return YES;
    return NO;
}

- (void)addFile:(File)file
{
    for (var i = 0; i < files.length; ++i)
        if (files[i].name > file.name)
            break;
    files.splice(i, 0, file);
}

- (void)addFolder:(Folder)folder
{
    for (var i = 0; i < folders.length; ++i)
        if (folders[i].name > folder.name)
            break;
    folders.splice(i, 0, folder);
}

- (void)removeFile:(File)file
{
    [files removeObject:file];
}

- (void)removeFolder:(Folder)folder
{
    [folders removeObject:folder];
}

- (CPString)uniqueChildNameWithPrefix:(CPString)prefix
{
    if (![self hasChildWithName:prefix])
        return prefix;
    prefix += " ";
    for (var i = 2;; ++i) {
        var childName = prefix + i;
        if (![self hasChildWithName:childName])
            return childName;
    }
}

- (File)fileWithName:(CPString)aName
{
    for (var i = 0; i < files.length; ++i)
        if (files[i].name == aName)
            return files[i];
    return nil;
}

@end

@implementation Env : Entry
@end

@implementation App : Entry
{
    Folder code @accessors;
    CPArray envs @accessors;
    CPArray libs @accessors;
}

- (CPString)url
{
    return "/apps/" + name + "/";
}

- (BOOL)hasEnvWithName:(CPString)aName
{
    var nameLower = aName.toLowerCase();
    for (var i = 0; i < envs.length; ++i)
        if (envs[i].name.toLowerCase() == nameLower)
            return YES;
    return NO;
}

- (void)addEnv:(Env)env
{
    var nameLower = env.name.toLowerCase();
    for (var i = 1; i < envs.length; ++i)
        if (envs[i].name.toLowerCase() > nameLower)
            break;
    envs.splice(i, 0, env);
}

- (BOOL)removeEnv:(Env)env
{
    [envs removeObject:env];
}

- (BOOL)hasLibWithName:(CPString)aName
{
    for (var i = 0; i < libs.length; ++i)
        if (libs[i].name == aName)
            return YES;
    return NO;
}

- (void)addLib:(id)lib
{
    libs.push(lib);
}

- (void)removeLib:(id)lib
{
    [libs removeObject:lib];
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
