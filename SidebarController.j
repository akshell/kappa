// (c) 2010 by Anton Korenyushkin

@import "UseLibPanelController.j"
@import "NodeView.j"
@import "NodeItems.j"

@implementation SidebarController : CPObject
{
    @outlet CPButtonBar buttonBar;
    @outlet CPView sidebarView;
    UseLibPanelController useLibPanelController;
    CPScrollView scrollView;
    App app;
}

- (void)awakeFromCib
{
    useLibPanelController = [UseLibPanelController new];

    [self reload];
    [DATA addObserver:self forKeyPath:"app" options:CPKeyValueObservingOptionNew context:nil];

    var plusButton = [CPButtonBar plusButton];
    var minusButton = [CPButtonBar minusButton];
    var actionPopupButton = [CPButtonBar actionPopupButton];
    var actionMenu = [actionPopupButton menu];
    [[actionMenu addItemWithTitle:"New File" action:@selector(showNewFile) keyEquivalent:nil] setTarget:self];
    [[actionMenu addItemWithTitle:"New Folder" action:@selector(showNewFolder) keyEquivalent:nil] setTarget:self];
    [[actionMenu addItemWithTitle:"New Environment" action:@selector(showNewEnv) keyEquivalent:nil] setTarget:self];
    [[actionMenu addItemWithTitle:"Use Library…" action:@selector(showWindow:) keyEquivalent:nil]
        setTarget:useLibPanelController];
    [actionMenu addItem:[CPMenuItem separatorItem]];
    [actionMenu addItemWithTitle:"Delete…" action:nil keyEquivalent:nil];
    [actionMenu addItemWithTitle:"Move…" action:nil keyEquivalent:nil];
    [actionMenu addItemWithTitle:"Duplicate" action:nil keyEquivalent:nil];
    [actionMenu addItemWithTitle:"Rename" action:nil keyEquivalent:nil];
    [buttonBar setButtons:[plusButton, minusButton, actionPopupButton]];
}

- (void)reload
{
    app = DATA.app;
    [scrollView removeFromSuperview];
    var sidebarBoundsSize = [sidebarView boundsSize];
    var scrollViewFrame = CGRectMake(0, 0, sidebarBoundsSize.width, sidebarBoundsSize.height - [buttonBar frameSize].height);
    if (app && app.scrollView) {
        scrollView = app.scrollView;
        [scrollView setFrame:scrollViewFrame];
        [sidebarView addSubview:scrollView];
        return;
    }
    scrollView = [[CPScrollView alloc] initWithFrame:scrollViewFrame];
    [scrollView setAutoresizingMask:CPViewWidthSizable | CPViewHeightSizable];
    [scrollView setHasHorizontalScroller:NO];
    [scrollView setAutohidesScrollers:YES];
    [sidebarView addSubview:scrollView];
    if (!app)
        return;
    outlineView = [[CPOutlineView alloc] initWithFrame:[[scrollView contentView] bounds]];
    [outlineView setAllowsMultipleSelection:YES];
    [outlineView setAutoresizingMask:CPViewWidthSizable | CPViewHeightSizable];
    [outlineView setColumnAutoresizingStyle:CPTableViewLastColumnOnlyAutoresizingStyle];
    [outlineView setHeaderView:nil];
    [outlineView setCornerView:nil];
    var column = [CPTableColumn new];
    [column setDataView:[NodeView new]];
    [outlineView addTableColumn:column];
    [outlineView setOutlineTableColumn:column];
    app.scrollView = scrollView;
    app.outlineView = outlineView;
    app.code = [[CodeItem alloc] initWithApp:app];
    app.envsItem = [[EnvsItem alloc] initWithApp:app];
    app.libsItem = [[LibsItem alloc] initWithApp:app];
    [outlineView setDataSource:self];
    [outlineView expandItem:app.code];
    [scrollView setDocumentView:outlineView];
    [outlineView sizeLastColumnToFit];
}

- (void)observeValueForKeyPath:(CPString)keyPath ofObject:(id)object change:(CPDictionary)change context:(id)context
{
    if (keyPath == "app")
        [self setScrollView];
}

- (id)rootForItem:(id)item
{
    for (var parentItem = item; parentItem; parentItem = [outlineView parentForItem:parentItem])
        item = parentItem;
    return item;
}

- (void)showNewFile
{
    function callback(parentFolder) {
        var newFileItem = [[NewFileItem alloc] initWithApp:app
                                                      name:[parentFolder uniqueChildNameWithPrefix:"untitled file"]];
        [parentFolder addFile:newFileItem];
        return newFileItem;
    };
    [app.code loadWithTarget:self action:@selector(showNewEntry:) context:callback];
}

- (void)showNewFolder
{
    function callback(parentFolder) {
        var newFolderItem = [[NewFolderItem alloc] initWithApp:app
                                                          name:[parentFolder uniqueChildNameWithPrefix:"untitled folder"]];
        [parentFolder addFolder:newFolderItem];
        return newFolderItem;
    };
    [app.code loadWithTarget:self action:@selector(showNewEntry:) context:callback];
}

- (void)showNewEntry:(Function)callback
{
    var selectedItem = [outlineView itemAtRow:[outlineView selectedRow]];
    var parentFolder = (
        [self rootForItem:selectedItem] === app.code
        ? [selectedItem isKindOfClass:File] ? [outlineView parentForItem:selectedItem] : selectedItem
        : app.code);
    [outlineView expandItem:parentFolder];
    setTimeout(
        function () {
            var item = callback(parentFolder);
            [outlineView reloadItem:parentFolder reloadChildren:YES];
            [outlineView scrollRectToVisible:[outlineView frameOfDataViewAtColumn:0 row:[outlineView rowForItem:item]]];
        },
        0);
}

- (void)showNewEnv
{
    [app.envsItem loadWithTarget:self action:@selector(doShowNewEnv)];
}

- (void)doShowNewEnv
{
    [outlineView expandItem:app.envsItem];
    var name = "untitled-env";
    if ([app hasEnvWithName:name]) {
        name += "-";
        var newName;
        for (var i = 2;; ++i) {
            newName = name + i;
            if (![app hasEnvWithName:newName])
                break;
        }
        name = newName;
    }
    var newEnvItem = [[NewEnvItem alloc] initWithApp:app name:name];
    setTimeout(
        function () {
            [app addEnv:newEnvItem];
            [outlineView reloadItem:app.envsItem reloadChildren:YES];
            [outlineView scrollRectToVisible:[outlineView frameOfDataViewAtColumn:0 row:[outlineView rowForItem:newEnvItem]]];
        },
        0);
}

- (id)outlineView:(CPOutlineView)anOutlineview child:(int)index ofItem:(id)item
{
    return item ? [item childAtIndex:index] : [app.code, app.envsItem, app.libsItem][index];
}

- (BOOL)outlineView:(CPOutlineView)anOutlineview isItemExpandable:(id)item
{
    return [item isExpandable]
}

- (int)outlineView:(CPOutlineView)anOutlineview numberOfChildrenOfItem:(id)item
{
    return item ? [item numberOfChildren] : 3;
}

- (id)outlineView:(CPOutlineView)anOutlineview objectValueForTableColumn:(CPTableColumn)tableColumn byItem:(id)item
{
    return item;
}

@end
