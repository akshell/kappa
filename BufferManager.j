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
        [app setupBuffers];
}

- (void)openBuffer:(Buffer)buffer // public
{
    for (var i = 0; i < app.buffers.length; ++i) {
        if ([app.buffers[i] isEqual:buffer]) {
            [app setBufferIndex:i];
            return;
        }
    }
    app.buffers.push(buffer);
    [self notify];
    [app setBufferIndex:app.buffers.length - 1];
}

- (void)closeBuffer:(Buffer)buffer // public
{
    var index = app.buffers.indexOf(buffer);
    if (index == -1)
        return;
    app.buffers.splice(index, 1);
    [self notify];
    if (index < app.bufferIndex || app.bufferIndex == app.buffers.length)
        [app setBufferIndex:app.bufferIndex - 1];
}

@end
