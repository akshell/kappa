// (c) 2010 by Anton Korenyushkin

@import "UseLibPanelController.j"
@import "NodeView.j"
@import "NodeItems.j"

@implementation SidebarController : CPObject
{
    @outlet CPButtonBar buttonBar;
    @outlet CPView sidebarView;
    UseLibPanelController useLibPanelController;
    CPButton plusButton;
    CPButton minusButton;
    CPButton actionPopUpButton;
    CPMenu actionsMenu;
    CPArray addControls;
    CPArray deleteControls;
    CPArray moveControls;
    CPArray duplicateControls;
    CPArray renameControls;
    CPScrollView scrollView;
    App app;
}

- (void)awakeFromCib
{
    useLibPanelController = [UseLibPanelController new];
    plusButton = [CPButtonBar plusButton];
    minusButton = [CPButtonBar minusButton];
    actionPopUpButton = [CPButtonBar actionPopupButton];
    var actionMenu = [actionPopUpButton menu];
    [actionMenu setAutoenablesItems:NO];
    [[actionMenu addItemWithTitle:"New File" action:@selector(showNewFile) keyEquivalent:nil] setTarget:self];
    [[actionMenu addItemWithTitle:"New Folder" action:@selector(showNewFolder) keyEquivalent:nil] setTarget:self];
    [[actionMenu addItemWithTitle:"New Environment" action:@selector(showNewEnv) keyEquivalent:nil] setTarget:self];
    [[actionMenu addItemWithTitle:"Use Library…" action:@selector(showWindow:) keyEquivalent:nil]
        setTarget:useLibPanelController];
    [actionMenu addItem:[CPMenuItem separatorItem]];
    addControls = [plusButton];
    deleteControls = [[actionMenu addItemWithTitle:"Delete…" action:nil keyEquivalent:nil], minusButton];
    moveControls = [[actionMenu addItemWithTitle:"Move…" action:nil keyEquivalent:nil]];
    duplicateControls = [[actionMenu addItemWithTitle:"Duplicate" action:nil keyEquivalent:nil]];
    renameControls = [[actionMenu addItemWithTitle:"Rename" action:nil keyEquivalent:nil]];
    [buttonBar setButtons:[plusButton, minusButton, actionPopUpButton]];
    [DATA addObserver:self forKeyPath:"app" options:CPKeyValueObservingOptionNew context:nil];
}

- (void)reload
{
    app = DATA.app;
    [plusButton, minusButton, actionPopUpButton].forEach(function (button) { [button setEnabled:app]; });
    [scrollView removeFromSuperview];
    var sidebarBoundsSize = [sidebarView boundsSize];
    var scrollViewFrame = CGRectMake(0, 0, sidebarBoundsSize.width, sidebarBoundsSize.height - [buttonBar frameSize].height);
    if (app && app.scrollView) {
        scrollView = app.scrollView;
        [scrollView setFrame:scrollViewFrame];
        [sidebarView addSubview:scrollView];
        [self outlineViewSelectionDidChange:nil];
        return;
    }
    scrollView = [[CPScrollView alloc] initWithFrame:scrollViewFrame];
    [scrollView setAutoresizingMask:CPViewWidthSizable | CPViewHeightSizable];
    [scrollView setHasHorizontalScroller:NO];
    [scrollView setAutohidesScrollers:YES];
    [sidebarView addSubview:scrollView];
    if (!app)
        return;
    var outlineView = [[CPOutlineView alloc] initWithFrame:[[scrollView contentView] bounds]];
    [outlineView setAllowsMultipleSelection:YES];
    [outlineView setAllowsEmptySelection:NO]
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
    [outlineView setDelegate:self];
    [outlineView expandItem:app.code];
    [outlineView selectRowIndexes:[CPIndexSet indexSetWithIndex:0] byExtendingSelection:NO];
    [scrollView setDocumentView:outlineView];
    [outlineView sizeLastColumnToFit];
}

- (void)setActionsMenu:(CPMenu)anActionsMenu
{
    actionsMenu = anActionsMenu;
    [actionsMenu setAutoenablesItems:NO];
    [deleteControls, moveControls, duplicateControls, renameControls].forEach(
        function (controls) {
            var item = [controls[0] copy];
            controls.push(item);
            [actionsMenu addItem:item];
        });
    [self reload];
}

- (void)observeValueForKeyPath:(CPString)keyPath ofObject:(id)object change:(CPDictionary)change context:(id)context
{
    if (keyPath == "app")
        [self reload];
}

- (id)rootForItem:(id)item
{
    for (var parentItem = item; parentItem; parentItem = [app.outlineView parentForItem:parentItem])
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
    var selectedItem = [app.outlineView itemAtRow:[app.outlineView selectedRow]];
    var parentFolder = (
        [self rootForItem:selectedItem] === app.code
        ? [selectedItem isKindOfClass:File] ? [app.outlineView parentForItem:selectedItem] : selectedItem
        : app.code);
    [app.outlineView expandItem:parentFolder];
    setTimeout(
        function () {
            var item = callback(parentFolder);
            [app.outlineView reloadItem:parentFolder reloadChildren:YES];
            [app.outlineView scrollRectToVisible:[app.outlineView frameOfDataViewAtColumn:0 row:[app.outlineView rowForItem:item]]];
        },
        0);
}

- (void)showNewEnv
{
    [app.envsItem loadWithTarget:self action:@selector(doShowNewEnv)];
}

- (void)doShowNewEnv
{
    [app.outlineView expandItem:app.envsItem];
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
            [app.outlineView reloadItem:app.envsItem reloadChildren:YES];
            [app.outlineView scrollRectToVisible:[app.outlineView frameOfDataViewAtColumn:0 row:[app.outlineView rowForItem:newEnvItem]]];
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

- (void)outlineViewSelectionDidChange:(id)sender
{
    var indexSet = [app.outlineView selectedRowIndexes];
    var isAddable = YES;
    var isDeletable = YES;
    var isMovable = YES;
    var isDuplicatable = YES;
    var firstRootItem;
    var firstParentItem;
    for (var index = [indexSet firstIndex]; index != CPNotFound; index = [indexSet indexGreaterThanIndex:index]) {
        var item = [app.outlineView itemAtRow:index];
        var rootItem = [self rootForItem:item];
        if (firstRootItem)
            isAddable = isAddable && rootItem === firstRootItem;
        else
            firstRootItem = rootItem;
        isDeletable = isDeletable && item !== rootItem && (rootItem !== app.libsItem || [item isKindOfClass:LibItem]);
        isDuplicatable = isDuplicatable && item !== rootItem && rootItem === app.code;
        isMovable = isMovable && isDuplicatable;
        if (isMovable) {
            var parentItem = [app.outlineView parentForItem:item];
            if (firstParentItem)
                isMovable = firstParentItem === parentItem;
            else
                firstParentItem = parentItem;
        }
    }
    var isRenamable = [indexSet count] == 1 && isDeletable;
    [actionsMenu _highlightItemAtIndex:CPNotFound];
    [[actionPopUpButton menu] _highlightItemAtIndex:CPNotFound];
    [
        [addControls, isAddable],
        [deleteControls, isDeletable],
        [moveControls, isMovable],
        [duplicateControls, isDuplicatable],
        [renameControls, isRenamable]
    ].forEach(
        function (pair) {
            pair[0].forEach(function (control) { [control setEnabled:pair[1]]; });
        });
}

@end
