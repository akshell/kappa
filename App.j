// (c) 2010 by Anton Korenyushkin

@implementation App : CPObject
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
