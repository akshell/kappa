// (c) 2010 by Anton Korenyushkin

@implementation Data : CPObject
{
    BOOL isDirty;
    CPString username @accessors;
    CPString email @accessors;
    CPArray apps;
    unsigned appIndex;
    JSObject app;
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
    apps = appNames.map(function (name) { return {name: name}; });
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
