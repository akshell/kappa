// (c) 2010 by Anton Korenyushkin

@import "BufferManager.j"
@import "WorkspaceItemView.j"

var DocsURL = "http://www.akshell.com/docs/0.3/";

@implementation WorkspaceController : CPObject
{
    App app;
    BufferManager bufferManager;
    CPTableView tableView;
    CPImageView spinnerImageView;
}

- (id)initWithApp:(App)anApp view:(CPView)superview bufferManager:(BufferManager)aBufferManager // public
{
    if (self = [super init]) {
        app = anApp;
        bufferManager = aBufferManager;
        [app addObserver:self forKeyPath:"buffers"];
        [app addObserver:self forKeyPath:"bufferIndex"];
        [bufferManager addChangeObserver:self selector:@selector(didBuffersChange)];
        var scrollView = [[CPScrollView alloc] initWithFrame:[superview bounds]];
        [scrollView setAutoresizingMask:CPViewWidthSizable | CPViewHeightSizable];
        [scrollView setHasHorizontalScroller:NO];
        [scrollView setAutohidesScrollers:YES];
        [superview addSubview:scrollView];
        tableView = [[CPTableView alloc] initWithFrame:[scrollView bounds]];
        [tableView setHidden:YES];
        [tableView setAllowsEmptySelection:NO];
        [tableView setAutoresizingMask:CPViewWidthSizable | CPViewHeightSizable];
        [tableView setColumnAutoresizingStyle:CPTableViewLastColumnOnlyAutoresizingStyle];
        [tableView setSelectionHighlightStyle:CPTableViewSelectionHighlightStyleSourceList];
        var column = [CPTableColumn new];
        [column setDataView:[WorkspaceItemView new]];
        [[column headerView] setStringValue:"Workspace"];
        [[column headerView] setValue:[[column headerView] valueForThemeAttribute:"background-color"]
                    forThemeAttribute:"background-color"];
        [tableView addTableColumn:column];
        [scrollView setDocumentView:tableView];
        [tableView sizeLastColumnToFit];
        var superviewSize = [superview boundsSize];
        spinnerImageView =
            [[CPImageView alloc] initWithFrame:CGRectMake(superviewSize.width / 2 - 16, superviewSize.height / 2 - 4, 32, 32)];
        [spinnerImageView setAutoresizingMask:CPViewMinXMargin | CPViewMaxXMargin | CPViewMinYMargin | CPViewMaxYMargin];
        [spinnerImageView setImage:[CPImage imageFromPath:"WhiteSpinner32.gif"]];
        [superview addSubview:spinnerImageView];
    }
    return self;
}

- (void)observeValueForKeyPath:(CPString)keyPath ofObject:(id)object change:(CPDictionary)change context:(id)context // private
{
    switch (keyPath) {
    case "buffers":
        [app removeObserver:self forKeyPath:keyPath];
        [spinnerImageView removeFromSuperview];
        [tableView setDataSource:self];
        [tableView setDelegate:self];
        [tableView setHidden:NO];
        break;
    case "bufferIndex":
        [tableView scrollRectToVisible:[tableView frameOfDataViewAtColumn:0 row:app.bufferIndex]];
        [tableView selectRowIndexes:[CPIndexSet indexSetWithIndex:app.bufferIndex] byExtendingSelection:NO];
        break;
    }
}

- (unsigned)numberOfRowsInTableView:(CPTableView)aTableView // private
{
    return app.buffers.length;
}

- (id)tableView:(CPTableView)aTableView objectValueForTableColumn:(unsigned)column row:(unsigned)row // private
{
    return [[WorkspaceItemController alloc] initWithBufferManager:bufferManager buffer:app.buffers[row]];
}

- (void)tableViewSelectionDidChange:(id)sender // private
{
    [app setBufferIndex:[tableView selectedRow]];
}

- (void)didBuffersChange // private
{
    [tableView reloadData];
}

- (void)openGit // public
{
    [bufferManager openBuffer:[GitBuffer new]];
}

- (void)openGettingStarted // public
{
    [bufferManager openBuffer:[[HelpBuffer alloc] initWithURL:DocsURL + "intro/" title:"Getting Started"]];
}

- (void)openUserGuide // public
{
    [bufferManager openBuffer:[[HelpBuffer alloc] initWithURL:DocsURL + "guide/" title:"User Guide"]];
}

- (void)openReference // public
{
    [bufferManager openBuffer:[[HelpBuffer alloc] initWithURL:DocsURL + "ref/" title:"Reference"]];
}

@end
