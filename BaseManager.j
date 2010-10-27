// (c) 2010 by Anton Korenyushkin

@import "Data.j"

var NotificationName = "ManagerNotification";

@implementation BaseManager : CPObject
{
    App app;
}

- (id)initWithApp:(App)anApp // public
{
    if (self = [super init])
        app = anApp;
    return self;
}

- (void)addChangeObserver:(id)observer selector:(SEL)selector // public
{
    [[CPNotificationCenter defaultCenter] addObserver:observer selector:selector name:NotificationName object:self];
}

- (void)notify // protected
{
    [[CPNotificationCenter defaultCenter] postNotificationName:NotificationName object:self];
}

@end
