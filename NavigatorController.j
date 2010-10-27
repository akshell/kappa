// (c) 2010 by Anton Korenyushkin

@import "NavigatorItemView.j"
@import "CodeManager.j"
@import "EnvManager.j"
@import "LibManager.j"

@implementation NavigatorController : CPObject
{
    App app;
    CodeManager codeManager;
    EnvManager envManager;
    LibManager libManager;
    CPArray managers;
    CPOutlineView outlineView;
    CPButton plusButton;
    CPButton minusButton;
    CPMenu actionsMenu @accessors(readonly);
    CPMenuItem newFileMenuItem;
    CPMenuItem newFolderMenuItem;
    CPMenuItem newEnvMenuItem;
    CPMenuItem useLibMenuItem;
    CPArray deleteMenuItems;
    CPArray moveMenuItems;
    CPArray duplicateMenuItems;
    CPArray renameMenuItems;
}

- (id)initWithApp:(App)anApp view:(CPView)superview // public
{
    if (self = [super init]) {
        app = anApp;
        [app addObserver:self forKeyPath:"code"];
        [app addObserver:self forKeyPath:"envs"];
        [app addObserver:self forKeyPath:"libs"];

        codeManager = [[CodeManager alloc] initWithApp:app];
        envManager = [[EnvManager alloc] initWithApp:app];
        libManager = [[LibManager alloc] initWithCodeManager:codeManager];
        managers = [codeManager, envManager, libManager];
        managers.forEach(
            function (manager) {
                [manager addChangeObserver:self selector:@selector(didManagerChange:)];
                [manager setRevealTarget:self];
                [manager setRevealAction:@selector(revealItems:)];
            });

        plusButton = [CPButtonBar plusButton];
        [plusButton setTarget:self];
        [plusButton setAction:@selector(showAdd)];
        minusButton = [CPButtonBar minusButton];
        [minusButton setTarget:self];
        [minusButton setAction:@selector(showDelete)];
        var actionButton = [CPButtonBar actionPopupButton];
        var actionButtonMenu = [actionButton menu];
        newFileMenuItem = [actionButtonMenu addItemWithTitle:"New File" target:self action:@selector(showNewFile)];
        newFolderMenuItem = [actionButtonMenu addItemWithTitle:"New Folder" target:self action:@selector(showNewFolder)];
        newEnvMenuItem = [actionButtonMenu addItemWithTitle:"New Environment" target:self action:@selector(showNewEnv)];
        useLibMenuItem = [actionButtonMenu addItemWithTitle:"Use Library…" target:self action:@selector(showUseLib)];
        [actionButtonMenu addItem:[CPMenuItem separatorItem]];
        actionsMenu = [CPMenu new];
        deleteMenuItems = [];
        moveMenuItems = [];
        duplicateMenuItems = [];
        renameMenuItems = [];
        [actionButtonMenu, actionsMenu].forEach(
            function (menu) {
                [menu setAutoenablesItems:NO];
                deleteMenuItems.push([menu addItemWithTitle:"Delete…" target:self action:@selector(showDelete)]);
                moveMenuItems.push([menu addItemWithTitle:"Move…" target:self action:@selector(showMove)]);
                duplicateMenuItems.push([menu addItemWithTitle:"Duplicate" target:self action:@selector(duplicate)]);
                renameMenuItems.push([menu addItemWithTitle:"Rename" target:self action:@selector(showRename)]);
            });
        [newFileMenuItem, newFolderMenuItem, newEnvMenuItem, useLibMenuItem].forEach(
            function (menuItem) { [menuItem setEnabled:NO]; });

        var superviewSize = [superview boundsSize];
        var buttonBar = [[CPButtonBar alloc] initWithFrame:CGRectMake(0, superviewSize.height - 26, superviewSize.width, 26)];
        [buttonBar setAutoresizingMask:CPViewWidthSizable | CPViewMinYMargin];
        [buttonBar setButtons:[plusButton, minusButton, actionButton]];
        [superview addSubview:buttonBar];

        var scrollView = [[CPScrollView alloc] initWithFrame:CGRectMake(0, 0, superviewSize.width, superviewSize.height - 26)];
        [scrollView setAutoresizingMask:CPViewWidthSizable | CPViewHeightSizable];
        [scrollView setHasHorizontalScroller:NO];
        [scrollView setAutohidesScrollers:YES];
        [superview addSubview:scrollView];

        outlineView = [CPOutlineView new];
        [outlineView setAllowsMultipleSelection:YES];
        [outlineView setAllowsEmptySelection:NO];
        [outlineView setAutoresizingMask:CPViewWidthSizable | CPViewHeightSizable];
        [outlineView setColumnAutoresizingStyle:CPTableViewLastColumnOnlyAutoresizingStyle];
        var column = [CPTableColumn new];
        [column setDataView:[NavigatorItemView new]];
        [[column headerView] setStringValue:"Navigator"];
        [[column headerView] setValue:[[column headerView] valueForThemeAttribute:"background-color"]
                    forThemeAttribute:"background-color"];
        [outlineView addTableColumn:column];
        [outlineView setOutlineTableColumn:column];
        [outlineView setDataSource:self];
        managers.forEach(function (manager) { [outlineView expandItem:manager]; });
        [outlineView setDelegate:self];
        [outlineView selectRowIndexes:[CPIndexSet indexSetWithIndex:0] byExtendingSelection:NO];
        [scrollView setDocumentView:outlineView];
        [outlineView sizeLastColumnToFit];
    }
    return self;
}

- (BOOL)outlineView:(CPOutlineView)anOutlineview isItemExpandable:(id)item // private
{
    return [item isExpandable]
}

- (int)outlineView:(CPOutlineView)anOutlineview numberOfChildrenOfItem:(id)item // private
{
    return item ? [item numberOfChildren] : managers.length;
}

- (id)outlineView:(CPOutlineView)anOutlineview child:(int)index ofItem:(id)item // private
{
    return item ? [item childAtIndex:index] : managers[index];
}

- (id)outlineView:(CPOutlineView)anOutlineview objectValueForTableColumn:(CPTableColumn)tableColumn byItem:(id)item // private
{
    return item;
}

- (void)outlineViewSelectionDidChange:(id)sender // private
{
    var items = [outlineView selectedItems];
    var firstManager;
    var managerIsCommon = YES;
    var itemsAreDeletable = YES;
    for (var i = 0; i < items.length && managerIsCommon; ++i) {
        var item = items[i];
        var manager = [outlineView rootForItem:item];
        if (firstManager)
            managerIsCommon = manager === firstManager;
        else
            firstManager = manager;
        itemsAreDeletable =
            itemsAreDeletable && managerIsCommon && item !== manager &&
            (manager !== libManager || [item isKindOfClass:Lib]) &&
            (manager !== envManager || item !== app.envs[0]);
    }
    var itemsAreMovableAndDuplicatable = itemsAreDeletable && firstManager === codeManager;
    var itemIsRenamable = itemsAreDeletable && items.length == 1;
    [plusButton setEnabled:managerIsCommon && [firstManager isReady]];
    [minusButton setEnabled:itemsAreDeletable];
    [
        [deleteMenuItems, itemsAreDeletable],
        [moveMenuItems, itemsAreMovableAndDuplicatable],
        [duplicateMenuItems, itemsAreMovableAndDuplicatable],
        [renameMenuItems, itemIsRenamable]
    ].forEach(
        function (pair) {
            pair[0].forEach(function (menuItem) { [menuItem doSetEnabled:pair[1]]; });
        });
}

- (void)outlineViewItemWillExpand:(CPNotification)notification // private
{
    var items = [outlineView selectedItems];
    setTimeout(function () { [outlineView selectItems:items]; }, 0);
}

- (void)outlineViewItemWillCollapse:(CPNotification)notification // private
{
    var items = [outlineView selectedItems];
    var collapsedItem = [[[notification userInfo] allValues] objectAtIndex:0];
    setTimeout(
        function () {
            items = items.map(
                function (item) {
                    for (var parentItem = item; parentItem; parentItem = [outlineView parentForItem:parentItem])
                        if (parentItem === collapsedItem)
                            return collapsedItem;
                    return item;
                });
            [outlineView selectItems:items];
        },
        0);
}

- (void)observeValueForKeyPath:(CPString)keyPath ofObject:(id)object change:(CPDictionary)change context:(id)context // private
{
    [app removeObserver:self forKeyPath:keyPath];
    var manager;
    switch (keyPath) {
    case "code":
        [newFileMenuItem doSetEnabled:YES];
        [newFolderMenuItem doSetEnabled:YES];
        manager = codeManager;
        break;
    case "envs":
        [newEnvMenuItem doSetEnabled:YES];
        manager = envManager;
        break;
    case "libs":
        [useLibMenuItem doSetEnabled:YES];
        manager = libManager;
        break;
    }
    var items = [outlineView selectedItems];
    for (var i = 0; i < items.length; ++i)
        if ([outlineView rootForItem:items[i]] !== manager)
            break;
    if (i == items.length)
        [plusButton setEnabled:YES];
}

- (void)didManagerChange:(CPNotification)notification // private
{
    [outlineView reloadItem:[notification object] reloadChildren:YES];
    [outlineView load];
}

- (void)revealItems:(CPArray)items // private
{
    // FIXME: Hack fixing wrong displaying of expanded items moved to a different level
    items.forEach(
        function (item) {
            if ([outlineView isItemExpanded:item]) {
                [outlineView collapseItem:item];
                [outlineView expandItem:item];
            }
        });
    if (items.length != 1) {
        [outlineView selectItems:items];
        return;
    }
    var item = items[0];
    [outlineView showItem:item];
    if (!item.isEditable)
        [outlineView selectItems:[item]];
}

- (void)showNewFile // public
{
    [self showNewEntryWithSelector:@selector(newFileInFolder:)];
}

- (void)showNewFolder // public
{
    [self showNewEntryWithSelector:@selector(newFolderInFolder:)];
}

- (void)showNewEntryWithSelector:(SEL)selector // private
{
    var selectedItem = [outlineView selectedItem];
    var parentFolder, parentItem;
    if ([outlineView rootForItem:selectedItem] !== codeManager || selectedItem === codeManager) {
        parentFolder = app.code;
        parentItem = codeManager;
    } else {
        parentFolder = parentItem = [selectedItem isKindOfClass:File] ? selectedItem.parentFolder : selectedItem;
    }
    [outlineView expandItem:parentItem];
    [outlineView load];
    [outlineView expandItem:objj_msgSend(codeManager, selector, parentFolder)];
}

- (void)showNewEnv // public
{
    [outlineView expandItem:envManager];
    [outlineView load];
    [envManager newEnv];
}

- (void)showUseLib // public
{
    [libManager showUseLib];
    [outlineView expandItem:libManager];
}

- (void)showAdd // private
{
    switch ([outlineView rootForItem:[outlineView selectedItem]]) {
    case codeManager:
        [self showNewFile];
        break;
    case envManager:
        [self showNewEnv];
        break;
    case libManager:
        [self showUseLib];
        break;
    }
}

- (void)showRename // private
{
    var item = [outlineView selectedItem];
    [[outlineView rootForItem:item] markRenameItem:item];
    [outlineView reloadItem:item];
}

- (void)showDelete // private
{
    var items = [outlineView selectedItems];
    var description = [[outlineView rootForItem:items[0]] descriptionOfItems:items];
    [[[Confirm alloc] initWithMessage:"Are you sure want to delete the " + description + "?"
                              comment:"You cannot undo this action."
                               target:self
                               action:@selector(doDelete)]
        showPanel];
}

- (void)doDelete // private
{
    var items = [outlineView selectedItems];
    var manager = [outlineView rootForItem:items[0]];
    [manager deleteItems:items];
    [outlineView selectItems:[manager]];
}

- (void)duplicate // private
{
    [codeManager duplicateEntries:[outlineView selectedItems]];
}

- (void)showMove // private
{
    [codeManager showMoveEntries:[outlineView selectedItems]];
}

@end