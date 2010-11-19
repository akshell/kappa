// (c) 2010 by Anton Korenyushkin

@import "BaseManager.j"
@import "EntityDeleting.j"
@import "SavePanelController.j"

@implementation Buffer (BufferManager)

- (Entity)entity // public
{
    return nil;
}

- (void)didDeleteEntity // public
{
    [manager closeBuffer:self askToSave:NO];
}

@end

@implementation CodeFileBuffer (BufferManager)

- (Entity)entity // public
{
    return file;
}

@end

@implementation LibFileBuffer (BufferManager)

- (Entity)entity // public
{
    return lib;
}

@end

@implementation EvalBuffer (BufferManager)

- (Entity)entity // public
{
    return env;
}

@end

@implementation BufferManager : BaseManager
{
    unsigned lastVisitTag;
    unsigned closeBufferIndex;
    SavePanelController savePanelController;
}

- (id)initWithApp:(App)anApp // public
{
    if (self = [super initWithApp:anApp]) {
        lastVisitTag = 0;
        savePanelController = [[SavePanelController alloc] initWithTarget:self
                                                               saveAction:@selector(saveAndCloseBuffer)
                                                           dontSaveAction:@selector(doCloseBuffer)];
        ["code", "envs", "libs", "buffers", "buffer"].forEach(function (keyPath) { [app addObserver:self forKeyPath:keyPath]; });
    }
    return self;
}

- (id)observeBuffer:(Buffer)buffer // private
{
    buffer.manager = self;
    [buffer addObserver:self forKeyPath:"name"];
    [buffer addObserver:self forKeyPath:"isModified"];
    [[buffer entity] addDeleteObserver:buffer selector:@selector(didDeleteEntity)];
}

- (void)observeValueForKeyPath:(CPString)keyPath ofObject:(id)object change:(CPDictionary)change context:(id)context // private
{
    switch (keyPath) {
    case "name":
        [self notify];
        break;
    case "isModified":
        [app setNumberOfModifiedBuffers:app.numberOfModifiedBuffers + (object.isModified ? +1 : -1)];
        break;
    case "buffers":
        for (var i = 0; i < app.buffers.length; ++i) {
            var buffer = app.buffers[i];
            [self observeBuffer:buffer];
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
    [self observeBuffer:buffer];
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

- (void)closeBuffer:(Buffer)buffer askToSave:(BOOL)askToSave // public
{
    var closeBufferIndex = app.buffers.indexOf(buffer);
    if (closeBufferIndex == -1)
        return;
    if (askToSave && [buffer isModified])
        [savePanelController showWindowWithFileName:buffer.file.name];
    else
        [self doCloseBuffer];
}

- (void)doCloseBuffer // private
{
    var buffer = app.buffers[closeBufferIndex];
    [buffer removeObserver:self forKeyPath:"name"];
    [[buffer entity] removeDeleteObserver:buffer];
    app.buffers.splice(closeBufferIndex, 1);
    [self notify];
    if (closeBufferIndex < app.bufferIndex || app.bufferIndex == app.buffers.length)
        [app setBufferIndex:app.bufferIndex - 1];
    if ([buffer isModified])
        [app setNumberOfModifiedBuffers:app.numberOfModifiedBuffers - 1];
}

- (void)saveAndCloseBuffer // private
{
    [app.buffers[closeBufferIndex].presentationController save];
    [self doCloseBuffer];
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
