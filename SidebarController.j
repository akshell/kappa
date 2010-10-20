// (c) 2010 by Anton Korenyushkin

@import "ItemView.j"
@import "CodeManager.j"
@import "EnvManager.j"
@import "LibManager.j"

@implementation SidebarController : CPObject
{
    App app;
    CodeManager codeManager;
    EnvManager envManager;
    LibManager libManager;
    CPArray managers;
    CPScrollView scrollView;
    CPOutlineView outlineView;
    CPButtonBar buttonBar;
    CPButton plusButton;
    CPButton minusButton;
    CPMenu actionsMenu;
    CPMenuItem newFileMenuItem;
    CPMenuItem newFolderMenuItem;
    CPMenuItem newEnvMenuItem;
    CPMenuItem useLibMenuItem;
    CPArray deleteMenuItems;
    CPArray moveMenuItems;
    CPArray duplicateMenuItems;
    CPArray renameMenuItems;
}

- (id)initWithApp:(App)anApp // public
{
    if (self = [super init]) {
        app = anApp;
        [app addObserver:self forKeyPath:"code" options:nil context:nil];
        [app addObserver:self forKeyPath:"envs" options:nil context:nil];
        [app addObserver:self forKeyPath:"libs" options:nil context:nil];

        codeManager = [[CodeManager alloc] initWithApp:app];
        envManager = [[EnvManager alloc] initWithApp:app];
        libManager = [[LibManager alloc] initWithCodeManager:codeManager];
        managers = [codeManager, envManager, libManager];
        managers.forEach(
            function (manager) {
                [manager addObserver:self selector:@selector(didManagerChange:)];
                [manager setRevealTarget:self];
                [manager setRevealAction:@selector(revealItem:)];
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
                moveMenuItems.push([menu addItemWithTitle:"Move…" target:nil action:nil]);
                duplicateMenuItems.push([menu addItemWithTitle:"Duplicate" target:self action:@selector(duplicate)]);
                renameMenuItems.push([menu addItemWithTitle:"Rename" target:self action:@selector(showRename)]);
            });
        [newFileMenuItem, newFolderMenuItem, newEnvMenuItem, useLibMenuItem].forEach(
            function (menuItem) { [menuItem setEnabled:NO]; });

        buttonBar = [CPButtonBar new];
        [buttonBar setAutoresizingMask:CPViewWidthSizable | CPViewMinYMargin];
        [buttonBar setButtons:[plusButton, minusButton, actionButton]];

        scrollView = [CPScrollView new];
        [scrollView setAutoresizingMask:CPViewWidthSizable | CPViewHeightSizable];
        [scrollView setHasHorizontalScroller:NO];
        [scrollView setAutohidesScrollers:YES];

        outlineView = [CPOutlineView new];
        [outlineView setAllowsMultipleSelection:YES];
        [outlineView setAllowsEmptySelection:NO];
        [outlineView setAutoresizingMask:CPViewWidthSizable | CPViewHeightSizable];
        [outlineView setColumnAutoresizingStyle:CPTableViewLastColumnOnlyAutoresizingStyle];
        [outlineView setHeaderView:nil];
        [outlineView setCornerView:nil];
        var column = [CPTableColumn new];
        [column setDataView:[ItemView new]];
        [outlineView addTableColumn:column];
        [outlineView setOutlineTableColumn:column];
        [outlineView setDataSource:self];
        [outlineView setDelegate:self];
        [outlineView expandItem:codeManager];
        [outlineView selectRowIndexes:[CPIndexSet indexSetWithIndex:0] byExtendingSelection:NO];
        [scrollView setDocumentView:outlineView];
    }
    return self;
}

- (void)showInView:(CPView)superview withActionsMenuItem:(CPMenuItem)actionsMenuItem // public
{
    var superviewSize = [superview boundsSize];
    [buttonBar setFrame:CGRectMake(0, superviewSize.height - 26, superviewSize.width, 26)];
    [scrollView setFrame:CGRectMake(0, 0, superviewSize.width, superviewSize.height - 26)];
    [outlineView sizeLastColumnToFit];
    [superview addSubview:scrollView];
    [superview addSubview:buttonBar];
    [[actionsMenuItem submenu] setSupermenu:nil];
    [actionsMenuItem setSubmenu:actionsMenu];
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

- (void)observeValueForKeyPath:(CPString)keyPath ofObject:(id)object change:(CPDictionary)change context:(id)context // private
{
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

- (void)revealItem:(id)item // private
{
    if (item.isEditable) {
        [outlineView showItem:item];
        return;
    }
    // FIXME: Condition should be more robust
    var mainWindow = [CPApp mainWindow];
    if ([mainWindow firstResponder] === mainWindow) {
        [outlineView showItem:item];
        [outlineView selectItems:[item]];
    }
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
    objj_msgSend(codeManager, selector, parentFolder);
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
    [outlineView selectItems:[codeManager duplicateEntries:[outlineView selectedItems]]];
}

@end
