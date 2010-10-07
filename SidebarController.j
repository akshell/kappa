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
    CPOutlineView outlineView;
    CPArray items;
}

- (void)awakeFromCib
{
    useLibPanelController = [UseLibPanelController new];

    [self setScrollView];
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

- (void)setScrollView
{
    [scrollView removeFromSuperview];
    var sidebarBoundsSize = [sidebarView boundsSize];
    var scrollViewFrame = CGRectMake(0, 0, sidebarBoundsSize.width, sidebarBoundsSize.height - [buttonBar frameSize].height);
    if (DATA.app && DATA.app.scrollView) {
        scrollView = DATA.app.scrollView;
        outlineView = DATA.app.outlineView;
        items = DATA.app.rootItems;
        [scrollView setFrame:scrollViewFrame];
        [sidebarView addSubview:scrollView];
        return;
    }
    scrollView = [[CPScrollView alloc] initWithFrame:scrollViewFrame];
    [scrollView setAutoresizingMask:CPViewWidthSizable | CPViewHeightSizable];
    [scrollView setHasHorizontalScroller:NO];
    [scrollView setAutohidesScrollers:YES];
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
    if (DATA.app) {
        DATA.app.scrollView = scrollView;
        DATA.app.outlineView = outlineView;
        DATA.app.rootItems = items = [
            [[CodeItem alloc] initWithApp:DATA.app],
            [[EnvsItem alloc] initWithApp:DATA.app],
            [[LibsItem alloc] initWithApp:DATA.app]
        ];
    } else {
        items = [];
    }
    [outlineView setDataSource:self];
    [outlineView expandItem:items[0]];
    [scrollView setDocumentView:outlineView];
    [sidebarView addSubview:scrollView];
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
    function callback(parentItem, parentFolder) {
        var newFileItem = [[NewFileItem alloc] initWithApp:DATA.app
                                                      name:[parentFolder uniqueChildNameWithPrefix:"untitled file"]];
        [parentFolder addFile:newFileItem];
        return newFileItem;
    };
    [items[0] loadWithTarget:self action:@selector(showNewEntry:) context:callback];
}

- (void)showNewFolder
{
    function callback(parentItem, parentFolder) {
        var newFolderItem = [[NewFolderItem alloc] initWithApp:DATA.app
                                                          name:[parentFolder uniqueChildNameWithPrefix:"untitled folder"]];
        [parentFolder addFolder:newFolderItem];
        return newFolderItem;
    };
    [items[0] loadWithTarget:self action:@selector(showNewEntry:) context:callback];
}

- (void)showNewEntry:(Function)callback
{
    var selectedItem = [outlineView itemAtRow:[outlineView selectedRow]];
    var parentItem = (
        [self rootForItem:selectedItem] === items[0]
        ? [selectedItem isKindOfClass:File] ? [outlineView parentForItem:selectedItem] : selectedItem
        : items[0]);
    var parentFolder = parentItem === items[0] ? DATA.app.code : parentItem;
    [outlineView expandItem:parentItem];
    setTimeout(
        function () {
            var item = callback(parentItem, parentFolder);
            [outlineView reloadItem:parentItem reloadChildren:YES];
            [outlineView scrollRectToVisible:[outlineView frameOfDataViewAtColumn:0 row:[outlineView rowForItem:item]]];
        },
        0);
}

- (void)showNewEnv
{
    [items[1] loadWithTarget:self action:@selector(doShowNewEnv)];
}

- (void)doShowNewEnv
{
    [outlineView expandItem:items[1]];
    var name = "untitled-env";
    if ([DATA.app hasEnvWithName:name]) {
        name += "-";
        var newName;
        for (var i = 2;; ++i) {
            newName = name + i;
            if (![DATA.app hasEnvWithName:newName])
                break;
        }
        name = newName;
    }
    var newEnvItem = [[NewEnvItem alloc] initWithApp:DATA.app name:name];
    setTimeout(
        function () {
            [DATA.app addEnv:newEnvItem];
            [outlineView reloadItem:items[1] reloadChildren:YES];
            [outlineView scrollRectToVisible:[outlineView frameOfDataViewAtColumn:0 row:[outlineView rowForItem:newEnvItem]]];
        },
        0);
}

- (id)outlineView:(CPOutlineView)anOutlineview child:(int)index ofItem:(id)item
{
    return item ? [item childAtIndex:index] : items[index];
}

- (BOOL)outlineView:(CPOutlineView)anOutlineview isItemExpandable:(id)item
{
    return [item isExpandable]
}

- (int)outlineView:(CPOutlineView)anOutlineview numberOfChildrenOfItem:(id)item
{
    return item ? [item numberOfChildren] : items.length;
}

- (id)outlineView:(CPOutlineView)anOutlineview objectValueForTableColumn:(CPTableColumn)tableColumn byItem:(id)item
{
    return item;
}

@end
