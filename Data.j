// (c) 2010 by Anton Korenyushkin

@import "App.j"

@implementation Data : CPObject
{
    CPString username @accessors;
    CPArray apps @accessors(readonly);
    unsigned appIndex @accessors(readonly);
    App app @accessors(readonly);
}

- (id)init
{
    if (self = [super init]) {
        username = USERNAME;
        apps = APPS.map(function (name) { return [[App alloc] initWithName:name]; });
        [self setAppIndex:CONFIG.appIndex || 0];
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
