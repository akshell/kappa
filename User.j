// (c) 2010 by Anton Korenyushkin

var sharedUser;

@implementation User : CPObject
{
    CPString name @accessors;
}

+ (User)sharedUser
{
    if (!sharedUser) {
        sharedUser = [User new];
        [sharedUser setName:USERNAME];
    }
    return sharedUser;
}

@end
