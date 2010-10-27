// (c) 2010 by Anton Korenyushkin

@import "BaseManager.j"

@implementation BufferManager : BaseManager

- (id)initWithApp:(App)anApp // public
{
    if (self = [super initWithApp:anApp])
        ["code", "envs", "libs"].forEach(function (keyPath) { [app addObserver:self forKeyPath:keyPath]; });
    return self;
}

- (void)observeValueForKeyPath:(CPString)keyPath ofObject:(id)object change:(CPDictionary)change context:(id)context // private
{
    [app removeObserver:self forKeyPath:keyPath];
    if (app.code && app.envs && app.libs)
        [app setBuffers:[app oldBuffers]];
}

@end
