// (c) 2010 by Anton Korenyushkin

@import "BufferManager.j"
@import "WorkspaceItemView.j"

var DragType = "WorkspaceDragType";

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
        [tableView registerForDraggedTypes:[DragType]];
        [tableView setDraggingDestinationFeedbackStyle:CPTableViewDropAbove];
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
        if ([tableView isHidden]) {
            [spinnerImageView removeFromSuperview];
            [tableView setDataSource:self];
            [tableView setDelegate:self];
            [tableView setHidden:NO];
        } else {
            [tableView reloadData];
        }
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
    return app.buffers[row];
}

- (BOOL)tableView:(CPTableView)aTableView
writeRowsWithIndexes:(CPIndexSet)rowIndexes
     toPasteboard:(CPPasteboard)pasteboard // private
{
    [pasteboard declareTypes:[DragType] owner:self];
    [pasteboard setData:rowIndexes forType:DragType];
    return YES;
}

- (CPDragOperation)tableView:(CPTableView)aTableView
                validateDrop:(id)info
                 proposedRow:(CPInteger)row
       proposedDropOperation:(CPTableViewDropOperation)operation // private
{
    [tableView setDropRow:row dropOperation:CPTableViewDropAbove];
    return CPDragOperationMove;
}

- (BOOL)tableView:(CPTableView)aTableView
       acceptDrop:(id)info
              row:(int)row
    dropOperation:(CPTableViewDropOperation)operation // private
{
    [bufferManager moveBufferWithIndex:[[[info draggingPasteboard] dataForType:DragType] firstIndex] to:row];
    return YES;
}

- (void)tableViewSelectionDidChange:(id)sender // private
{
    [app setBufferIndex:[tableView selectedRow]];
}

- (void)switchToEdit // public
{
    if ([bufferManager openBufferOfClass:FileBuffer])
        return;
    var entry = [app.code childWithName:"main.js"];
    if ([entry isKindOfClass:File])
        [bufferManager openNewBuffer:[[CodeFileBuffer alloc] initWithFile:entry]];
}

- (void)switchToGit // public
{
    [bufferManager openBuffer:[GitBuffer new]];
}

- (void)closeCurrentBuffer // public
{
    [bufferManager closeBuffer:app.buffer askToSave:YES];
}

- (void)switchToPreviousBuffer // public
{
    [app setBufferIndex:app.bufferIndex - 1];
}

- (void)switchToNextBuffer // public
{
    [app setBufferIndex:app.bufferIndex + 1];
}

@end
