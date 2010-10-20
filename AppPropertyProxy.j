// (c) 2010 by Anton Korenyushkin

@import "Data.j"

@implementation AppPropertyProxy : CPObject
{
    CPString propertyName;
}

- (id)initWithPropertyName:(CPString)aPropertyName // public
{
    if (self = [super init])
        propertyName = aPropertyName;
    return self;
}

- (CPMethodSignature)methodSignatureForSelector:(SEL)selector // protected
{
    return YES;
}

- (void)forwardInvocation:(CPInvocation)invocation // protected
{
    [invocation setTarget:DATA.app[propertyName]];
    [invocation invoke];
}

@end
