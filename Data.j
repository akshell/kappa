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

@end

@implementation Env : Entry
@end

@implementation App : Entry
{
    Folder code @accessors;
    CPArray envs @accessors;
    JSObject cache;
}

- (id)initWithName:(CPString)aName
{
    if (self = [super initWithName:aName])
        cache = {};
    return self;
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
