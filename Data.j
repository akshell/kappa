// (c) 2010 by Anton Korenyushkin

@implementation Data : CPObject
{
    CPString username @accessors;
}

- (id)init
{
    if (self = [super init])
        username = USERNAME;
    return self;
}

@end
