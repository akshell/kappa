// (c) 2010 by Anton Korenyushkin

@implementation CPObject (Utils)

- (void)addObserver:(id)observer forKeyPath:(CPString)keyPath // public
{
    [self addObserver:observer forKeyPath:keyPath options:0 context:nil];
}

- (void)addObserver:(id)observer forKeyPath:(CPString)keyPath context:(id)context // public
{
    [self addObserver:observer forKeyPath:keyPath options:0 context:context];
}

@end
