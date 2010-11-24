// (c) 2010 by Anton Korenyushkin

@import "NavigatorItemView.j"
@import "CodeManager.j"
@import "EnvManager.j"
@import "LibManager.j"
@import "TabOpener.j"

@implementation App (NavigatorController)

- (Env)defaultEnv // public
{
    return envs[envs.length > 1 ? 1 : 0];
}

@end

var DragType = "NavigatorDragType";

@implementation NavigatorController : CPObject
{
    App app;
    BufferManager bufferManager;
    CodeManager codeManager;
    EnvManager envManager;
    LibManager libManager;
    CPArray resourceManagers;
    TabOpener previewTabOpener;
    CPOutlineView outlineView;
    CPButton plusButton;
    CPButton minusButton;
    CPMenu actionsMenu @accessors(readonly);
    CPMenu evalMenu @accessors(readonly);
    CPMenu previewMenu @accessors(readonly);
    CPMenuItem newFileMenuItem;
    CPMenuItem newFolderMenuItem;
    CPMenuItem uploadFileMenuItem;
    CPMenuItem newEnvMenuItem;
    CPMenuItem useLibMenuItem;
    CPArray deleteMenuItems;
    CPArray moveMenuItems;
    CPArray duplicateMenuItems;
    CPArray renameMenuItems;
}

- (id)initWithApp:(App)anApp view:(CPView)superview bufferManager:(BufferManager)aBufferManager // public
{
    if (self = [super init]) {
        app = anApp;
        bufferManager = aBufferManager;

        ["code", "envs", "libs"].forEach(function (keyPath) { [app addObserver:self forKeyPath:keyPath]; });

        codeManager = [[CodeManager alloc] initWithApp:app bufferManager:bufferManager];
        envManager = [[EnvManager alloc] initWithApp:app];
        libManager = [[LibManager alloc] initWithCodeManager:codeManager];
        resourceManagers = [codeManager, envManager, libManager];
        resourceManagers.forEach(
            function (manager) {
                [manager setRevealTarget:self];
                [manager setRevealAction:@selector(revealItems:)];
            });

        previewTabOpener = [TabOpener new];

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
        uploadFileMenuItem = [actionButtonMenu addItemWithTitle:"Upload File…"];
        [uploadFileMenuItem setUploadTarget:self action:@selector(uploadDOMFile:)];
        newEnvMenuItem = [actionButtonMenu addItemWithTitle:"New Environment" target:self action:@selector(showNewEnv)];
        useLibMenuItem = [actionButtonMenu addItemWithTitle:"Use Library…" target:self action:@selector(showUseLib)];
        [actionButtonMenu addItem:[CPMenuItem separatorItem]];
        actionsMenu = [CPMenu new];
        evalMenu = [CPMenu new];
        previewMenu = [CPMenu new];
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
        [newFileMenuItem, newFolderMenuItem, uploadFileMenuItem, newEnvMenuItem, useLibMenuItem].forEach(
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
        [outlineView registerForDraggedTypes:[DragType]];
        var column = [CPTableColumn new];
        [column setDataView:[NavigatorItemView new]];
        [[column headerView] setStringValue:"Navigator"];
        [[column headerView] setValue:[[column headerView] valueForThemeAttribute:"background-color"]
                    forThemeAttribute:"background-color"];
        [outlineView addTableColumn:column];
        [outlineView setOutlineTableColumn:column];
        [outlineView setDataSource:self];
        resourceManagers.forEach(function (manager) { [outlineView expandItem:manager]; });
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
    return item ? [item numberOfChildren] : resourceManagers.length;
}

- (id)outlineView:(CPOutlineView)anOutlineview child:(int)index ofItem:(id)item // private
{
    return item ? [item childAtIndex:index] : resourceManagers[index];
}

- (id)outlineView:(CPOutlineView)anOutlineview objectValueForTableColumn:(CPTableColumn)tableColumn byItem:(id)item // private
{
    return item;
}

- (BOOL)outlineView:(CPOutlineView)anOutlineview writeItems:(CPArray)items toPasteboard:(CPPasteboard)pasteboard // private
{
    for (var i = 0; i < items.length; ++i)
        if (![items[i] isKindOfClass:Entry])
            return NO;
    [pasteboard declareTypes:[DragType] owner:self];
    [pasteboard setData:items forType:DragType];
    return YES;
}

- (CPDragOperation)outlineView:(CPOutlineView)anOutlineview
                  validateDrop:(id)info
                  proposedItem:(id)item
            proposedChildIndex:(unsigned)index // private
{
    if (index != -1)
        return CPDragOperationNone;
    if (item === codeManager)
        return CPDragOperationMove;
    if (![item isKindOfClass:Folder])
        return CPDragOperationNone;
    var entries = [[info draggingPasteboard] dataForType:DragType];
    for (var folder = item; folder.parentFolder; folder = folder.parentFolder)
        if (entries.indexOf(folder) != -1)
            return CPDragOperationNone;
    return CPDragOperationMove;
}

- (BOOL)outlineView:(CPOutlineView)anOutlineview acceptDrop:(id)info item:(id)item childIndex:(unsigned)index // private
{
    [codeManager moveEntries:[[info draggingPasteboard] dataForType:DragType] toFolder:item === codeManager ? app.code : item];
    return YES;
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

- (void)outlineView:(CPOutlineView)anOutlineView didClickItem:(id)item // private
{
    if ([[outlineView selectedRowIndexes] count] != 1)
        return;
    if ([item isKindOfClass:File]) {
        for (var entry = item; entry.parentFolder.parentFolder; entry = entry.parentFolder)
            ;
        var baseItem = [outlineView parentForItem:entry];
        [bufferManager openBuffer:(baseItem === codeManager
                                   ? [[CodeFileBuffer alloc] initWithFile:item]
                                   : [[LibFileBuffer alloc] initWithLib:baseItem path:[item path]])];
    } else if ([item isKindOfClass:Env]) {
        [bufferManager openBuffer:[[EvalBuffer alloc] initWithEnv:item]];
    }
}

- (void)observeValueForKeyPath:(CPString)keyPath ofObject:(id)object change:(CPDictionary)change context:(id)context // private
{
    var manager;
    var menuItems;
    switch (keyPath) {
    case "code":
        manager = codeManager;
        menuItems = [newFileMenuItem, newFolderMenuItem, uploadFileMenuItem];
        break;
    case "envs":
        manager = envManager;
        menuItems = [newEnvMenuItem];
        break;
    case "libs":
        manager = libManager;
        menuItems = [useLibMenuItem];
        break;
    }
    if (![menuItems[0] isEnabled]) {
        menuItems.forEach(function (menuItem) { [menuItem doSetEnabled:YES]; });
        var items = [outlineView selectedItems];
        if (items.length == 1 && items[0] === manager)
            [plusButton setEnabled:YES];
    }
    [outlineView reloadItem:manager reloadChildren:YES];
    [outlineView load];
    if (keyPath != "envs")
        return;
    [[evalMenu, @selector(openEval:)], [previewMenu, @selector(openPreview:)]].forEach(
        function (pair) {
            [pair[0] removeAllItems];
            app.envs.forEach(
                function (env) {
                    [[pair[0] addItemWithTitle:env.name target:self action:pair[1]] setTag:env];
                });
        });
}

- (void)revealItems:(CPArray)items // private
{
    // XXX: Hacks fixing expanding
    items.forEach(
        function (item) {
            if ([item isKindOfClass:Entry]) {
                var folders = [];
                for (var folder = item.parentFolder; folder.parentFolder; folder = folder.parentFolder)
                    folders.unshift(folder);
                folders.forEach(function (folder) { [outlineView expandItem:folder]; });
            }
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

- (void)uploadDOMFile:(DOMFile)domFile // public
{
    var selectedItem = [outlineView selectedItem];
    var folder;
    if ([selectedItem isKindOfClass:File]) {
        folder = selectedItem.parentFolder;
    } else if ([selectedItem isKindOfClass:Folder]) {
        folder = selectedItem;
        [outlineView expandItem:selectedItem];
    } else {
        folder = app.code;
        [outlineView expandItem:codeManager];
    }
    [codeManager uploadDOMFile:domFile toFolder:folder];
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
    [[[Confirm alloc] initWithMessage:"Are you sure you want to delete the " + description + "?"
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

- (void)openEval:(CPMenuItem)sender // private
{
    [bufferManager openBuffer:[[EvalBuffer alloc] initWithEnv:[sender tag]]];
}

- (void)switchToEval // public
{
    if (![bufferManager openBufferOfClass:EvalBuffer])
        [bufferManager openBuffer:[[EvalBuffer alloc] initWithEnv:[app defaultEnv]]];
}

- (void)openPreview:(CPMenuItem)sender // private
{
    [previewTabOpener openURL:[app URLOfEnv:[sender tag]]];
}

- (void)switchToPreview // public
{
    if (![previewTabOpener switchToLastTab])
        [previewTabOpener openURL:[app URLOfEnv:[app defaultEnv]]];
}

@end
