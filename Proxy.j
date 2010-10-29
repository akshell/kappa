// (c) 2010 by Anton Korenyushkin

@implementation Proxy : CPObject
{
    Function func;
}

- (id)initWithFunction:(Function)aFunc // public
{
    if (self = [super init])
        func = aFunc;
    return self;
}

- (CPMethodSignature)methodSignatureForSelector:(SEL)selector // protected
{
    return YES;
}

- (void)forwardInvocation:(CPInvocation)invocation // protected
{
    [invocation setTarget:func()];
    [invocation invoke];
}

@end
