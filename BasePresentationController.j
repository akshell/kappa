// (c) 2010-2011 by Anton Korenyushkin

@import "Data.j"

@implementation BasePresentationController : CPObject
{
    App app;
    Buffer buffer;
}

- (id)initWithApp:(App)anApp buffer:(Buffer)aBuffer // public
{
    if (self = [super init]) {
        app = anApp;
        buffer = aBuffer;
    }
    return self;
}

- (void)save // public
{
}

@end
