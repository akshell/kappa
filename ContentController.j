// (c) 2010 by Anton Korenyushkin

@import "BufferManager.j"
@import "NavigatorController.j"
@import "WorkspaceController.j"

@implementation ContentController : CPObject
{
    NavigatorController navigatorController @accessors(readonly);
    WorkspaceController workspaceController;
    CPView sidebarView;
    CPSplitView splitView;
}

- (id)initWithApp:(App)app
      sidebarView:(CPView)aSidebarView
 presentationView:(CPView)aPresentationView // public
{
    if (self = [super init]) {
        sidebarView = aSidebarView;
        splitView = [[CPSplitView alloc] initWithFrame:[sidebarView bounds]];
        [splitView setVertical:NO];
        [splitView setAutoresizingMask:CPViewWidthSizable | CPViewHeightSizable];
        var workspaceView = [CPView new];
        [splitView addSubview:workspaceView];
        var navigatorView = [CPView new];
        [splitView addSubview:navigatorView];
        [splitView setPosition:[sidebarView boundsSize].height * 0.3 ofDividerAtIndex:0];
        var bufferManager = [[BufferManager alloc] initWithApp:app];
        navigatorController = [[NavigatorController alloc] initWithApp:app view:navigatorView bufferManager:bufferManager];
        workspaceController = [[WorkspaceController alloc] initWithApp:app view:workspaceView bufferManager:bufferManager];
    }
    return self;
}

- (void)show // public
{
    [splitView setFrame:[sidebarView bounds]];
    [sidebarView addSubview:splitView];
}

@end
