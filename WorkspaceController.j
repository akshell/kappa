// (c) 2010 by Anton Korenyushkin

@import "WorkspaceItemView.j"

@implementation FileBuffer (WorkspaceController)

- (CPString)imageName // public
{
    return "File16";
}

@end

@implementation GitBuffer (WorkspaceController)

- (CPString)imageName // public
{
    return "Git16";
}

@end

@implementation EvalBuffer (WorkspaceController)

- (CPString)imageName // public
{
    return "Eval16";
}

@end

@implementation HelpBuffer (WorkspaceController)

- (CPString)imageName // public
{
    return "Help16";
}

@end

@implementation PreviewBuffer (WorkspaceController)

- (CPString)imageName // public
{
    return "Preview16";
}

@end

@implementation WorkspaceController : CPObject
{
    App app;
    CPTableView tableView;
    CPImageView spinnerImageView;
}

- (id)initWithApp:(App)anApp view:(CPView)superview // public
{
    if (self = [super init]) {
        app = anApp;
        ["code", "envs", "libs"].forEach(function (keyPath) { [app addObserver:self forKeyPath:keyPath]; });
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
            [[CPImageView alloc] initWithFrame:CGRectMake(superviewSize.width / 2 - 16, superviewSize.height / 2 - 16, 32, 32)];
        [spinnerImageView setAutoresizingMask:CPViewMinXMargin | CPViewMaxXMargin | CPViewMinYMargin | CPViewMaxYMargin];
        [spinnerImageView setImage:[CPImage imageFromPath:"WhiteSpinner32.gif"]];
        [superview addSubview:spinnerImageView];
    }
    return self;
}

- (void)observeValueForKeyPath:(CPString)keyPath ofObject:(id)object change:(CPDictionary)change context:(id)context // private
{
    [app removeObserver:self forKeyPath:keyPath];
    if (!(app.code && app.envs && app.libs))
        return;
    [app setupBuffers];
    [spinnerImageView removeFromSuperview];
    [tableView setDataSource:self];
    [tableView setHidden:NO];
}

- (unsigned)numberOfRowsInTableView:(CPTableView)aTableView // private
{
    return app.buffers.length;
}

- (id)tableView:(CPTableView)aTableView objectValueForTableColumn:(unsigned)column row:(unsigned)row // private
{
    return app.buffers[row];
}

@end
