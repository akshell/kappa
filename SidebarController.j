// (c) 2010 by Anton Korenyushkin

@import "BufferManager.j"
@import "NavigatorController.j"
@import "WorkspaceController.j"

@implementation SidebarController : CPObject
{
    CPView superview;
    CPSplitView splitView;
}

- (id)initWithApp:(App)app view:(CPView)aSuperview // public
{
    if (self = [super init]) {
        superview = aSuperview;
        splitView = [[CPSplitView alloc] initWithFrame:[superview bounds]];
        [splitView setVertical:NO];
        [splitView setAutoresizingMask:CPViewWidthSizable | CPViewHeightSizable];
        var workspaceView = [CPView new];
        [splitView addSubview:workspaceView];
        var navigatorView = [CPView new];
        [splitView addSubview:navigatorView];
        [splitView setPosition:[superview boundsSize].height * 0.3 ofDividerAtIndex:0];
        var bufferManager = [[BufferManager alloc] initWithApp:app];
        app.navigatorController = [[NavigatorController alloc] initWithApp:app view:navigatorView bufferManager:bufferManager];
        app.workspaceController = [[WorkspaceController alloc] initWithApp:app view:workspaceView bufferManager:bufferManager];
    }
    return self;
}

- (void)show // public
{
    [splitView setFrame:[superview bounds]];
    [superview addSubview:splitView];
}

@end
