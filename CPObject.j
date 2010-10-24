// (c) 2010 by Anton Korenyushkin

@implementation CPObject (Utils)

- (void)addObserver:(id)observer forKeyPath:(CPString)keyPath
{
    [self addObserver:observer forKeyPath:keyPath options:0 context:nil];
}

- (void)addObserver:(id)observer forKeyPath:(CPString)keyPath context:(id)context
{
    [self addObserver:observer forKeyPath:keyPath options:0 context:context];
}

@end
