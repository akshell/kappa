// (c) 2010 by Anton Korenyushkin

@import "Data.j"

@implementation AppPropertyProxy : CPObject
{
    CPString propertyName;
}

- (id)initWithPropertyName:(CPString)aPropertyName
{
    if (self = [super init])
        propertyName = aPropertyName;
    return self;
}

- (CPMethodSignature)methodSignatureForSelector:(SEL)selector
{
    return YES;
}

- (void)forwardInvocation:(CPInvocation)invocation
{
    [invocation setTarget:DATA.app[propertyName]];
    [invocation invoke];
}

@end
