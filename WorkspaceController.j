// (c) 2010 by Anton Korenyushkin

@import "WorkspaceItemView.j"

@implementation FileBuffer (WorkspaceController)

- (CPString)imageName // public
{
    return "File";
}

@end

@implementation GitBuffer (WorkspaceController)

- (CPString)imageName // public
{
    return "GitSmall";
}

@end

@implementation EvalBuffer (WorkspaceController)

- (CPString)imageName // public
{
    return "EvalSmall";
}

@end

@implementation HelpBuffer (WorkspaceController)

- (CPString)imageName // public
{
    return "Help";
}

@end

@implementation PreviewBuffer (WorkspaceController)

- (CPString)imageName // public
{
    return "PreviewSmall";
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
        [tableView setHeaderView:nil];
        [tableView setCornerView:nil];
        [tableView setSelectionHighlightStyle:CPTableViewSelectionHighlightStyleSourceList];
        var column = [CPTableColumn new];
        [column setDataView:[WorkspaceItemView new]];
        [tableView addTableColumn:column];
        [scrollView setDocumentView:tableView];
        [tableView sizeLastColumnToFit];
        var superviewSize = [superview boundsSize];
        spinnerImageView =
            [[CPImageView alloc] initWithFrame:CGRectMake(superviewSize.width / 2 - 16, superviewSize.height / 2 - 16, 32, 32)];
        [spinnerImageView setAutoresizingMask:CPViewMinXMargin | CPViewMaxXMargin | CPViewMinYMargin | CPViewMaxYMargin];
        [spinnerImageView setImage:[CPImage imageFromPath:"BigWhiteSpinner.gif"]];
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
