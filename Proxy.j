// (c) 2010-2011 by Anton Korenyushkin

@implementation Proxy : CPObject
{
    id object;
    CPString keyPath;
}

- (id)initWithObject:(id)anObject keyPath:(CPString)aKeyPath // public
{
    if (self = [super init]) {
        object = anObject;
        keyPath = aKeyPath;
    }
    return self;
}

- (CPMethodSignature)methodSignatureForSelector:(SEL)selector // protected
{
    return YES;
}

- (void)forwardInvocation:(CPInvocation)invocation // protected
{
    [invocation setTarget:[object valueForKeyPath:keyPath]];
    [invocation invoke];
}

@end
