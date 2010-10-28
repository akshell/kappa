// (c) 2010 by Anton Korenyushkin

@import "Data.j"
@import "BufferManager.j"

@implementation WorkspaceItemController : CPObject
{
    BufferManager bufferManager;
    Buffer buffer @accessors(readonly);
}

- (id)initWithBufferManager:(BufferManager)aBufferManager buffer:(Buffer)aBuffer // public
{
    if (self = [super init]) {
        bufferManager = aBufferManager;
        buffer = aBuffer;
    }
    return self;
}

- (void)close // public
{
    [bufferManager closeBuffer:buffer];
}

@end

