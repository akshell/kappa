// (c) 2010 by Anton Korenyushkin

@import "Data.j"

@implementation BaseManager : CPObject
{
    App app;
    CPString keyName;
}

- (id)initWithApp:(App)anApp keyName:(CPString)aKeyName // public
{
    if (self = [super init]) {
        app = anApp;
        keyName = aKeyName;
    }
    return self;
}

- (void)notify // protected
{
    [app didChangeValueForKey:keyName];
}

@end
