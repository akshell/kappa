// (c) 2010 by Anton Korenyushkin

@import "App.j"

DATA = nil

@implementation Data : CPObject
{
    CPString username @accessors;
    CPArray apps @accessors(readonly);
    unsigned appIndex @accessors(readonly);
    App app @accessors(readonly);
}

+ (void)setup
{
    DATA = [Data new];
}

- (id)init
{
    if (self = [super init]) {
        username = USERNAME;
        apps = APPS.map(function (name) { return [[App alloc] initWithName:name]; });
        [self setAppIndex:CONFIG.appIndex || 0];
        window.onbeforeunload = function () {
            var request = new XMLHttpRequest();
            request.open("PUT", "/config", false);
            request.setRequestHeader("X-Requested-With", "XMLHttpRequest");
            request.setRequestHeader("Content-Type", "application/json");
            request.send(JSON.stringify({appIndex: appIndex}));
        };
    }
    return self;
}

- (void)setAppIndex:(unsigned)value
{
    appIndex = value;
    if (app !== apps[appIndex]) {
        [self willChangeValueForKey:"app"];
        app = apps[appIndex];
        [self didChangeValueForKey:"app"];
    }
}

@end
