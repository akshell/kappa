// (c) 2010 by Anton Korenyushkin

@import "BaseManager.j"
@import "EntityDeleting.j"

@implementation Buffer (BufferManager)

- (void)setManager:(BufferManager)aManager // public
{
    self.manager = aManager;
    [[self prepare] addDeleteObserver:self selector:@selector(close)];
}

- (Entity)prepare // protected
{
    return nil;
}

- (void)close // private
{
    [manager closeBuffer:self];
}

- (void)observeValueForKeyPath:(CPString)keyPath ofObject:(id)object change:(CPDictionary)change context:(id)context // private
{
    [manager notify];
    [self didChangeValueForKey:"name"];
}

@end

@implementation CodeFileBuffer (BufferManager)

- (Entity)prepare // protected
{
    [file addObserver:self forKeyPath:"name"];
    return file;
}

@end

@implementation LibFileBuffer (BufferManager)

- (Entity)prepare // protected
{
    [lib addObserver:self forKeyPath:"name"];
    return lib;
}

@end

@implementation EvalBuffer (BufferManager)

- (Entity)prepare // protected
{
    [env addObserver:self forKeyPath:"name"];
    return env;
}

@end

@implementation WebBuffer (BufferManager)

- (Entity)prepare // protected
{
    [self addObserver:self forKeyPath:"title"];
    return nil;
}

@end

@implementation PreviewBuffer (BufferManager)

- (Entity)prepare // protected
{
    [super prepare];
    [env addObserver:self forKeyPath:"name"];
    return env;
}

@end

@implementation BufferManager : BaseManager
{
    unsigned lastVisitTag;
}

- (id)initWithApp:(App)anApp // public
{
    if (self = [super initWithApp:anApp]) {
        lastVisitTag = 0;
        ["code", "envs", "libs", "buffers", "buffer"].forEach(function (keyPath) { [app addObserver:self forKeyPath:keyPath]; });
    }
    return self;
}

- (void)observeValueForKeyPath:(CPString)keyPath ofObject:(id)object change:(CPDictionary)change context:(id)context // private
{
    switch (keyPath) {
    case "buffers":
        for (var i = 0; i < app.buffers.length; ++i) {
            var buffer = app.buffers[i];
            [buffer setManager:self];
            buffer.visitTag = -i;
        }
        break;
    case "buffer":
        if (app.buffer)
            app.buffer.visitTag = ++lastVisitTag;
        break;
    default:
        [app removeObserver:self forKeyPath:keyPath];
        if (app.code && app.envs && app.libs)
            [app setupBuffers];
    }
}

- (void)openNewBuffer:(Buffer)buffer // public
{
    [buffer setManager:self];
    app.buffers.push(buffer);
    [self notify];
    [app setBufferIndex:app.buffers.length - 1];
}

- (void)openBuffer:(Buffer)buffer // public
{
    for (var i = 0; i < app.buffers.length; ++i) {
        if ([app.buffers[i] isEqual:buffer]) {
            [app setBufferIndex:i];
            return;
        }
    }
    [self openNewBuffer:buffer];
}

- (BOOL)openBufferOfClass:(Class)bufferClass // public
{
    var foundBuffer;
    var foundBufferIndex;
    for (var i = 0; i < app.buffers.length; ++i) {
        var buffer = app.buffers[i];
        if ([buffer isKindOfClass:bufferClass] && (!foundBuffer || foundBuffer.visitTag < buffer.visitTag)) {
            foundBuffer = buffer;
            foundBufferIndex = i;
        }
    }
    if (!foundBuffer)
        return NO;
    [app setBufferIndex:foundBufferIndex];
    return YES;
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

- (void)moveBufferWithIndex:(unsigned)srcIndex to:(unsigned)dstIndex // public
{
    var buffer = app.buffers[srcIndex];
    app.buffers.splice(srcIndex, 1);
    if (srcIndex < dstIndex)
        --dstIndex;
    app.buffers.splice(dstIndex, 0, buffer);
    [self notify];
    if (app.bufferIndex == srcIndex) {
        [app setBufferIndex:dstIndex];
    } else if (app.bufferIndex > srcIndex) {
        if (app.bufferIndex <= dstIndex)
            [app setBufferIndex:app.bufferIndex - 1];
    } else {
        if (app.bufferIndex >= dstIndex)
            [app setBufferIndex:app.bufferIndex + 1];
    }
}

@end
