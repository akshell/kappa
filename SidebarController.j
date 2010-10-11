// (c) 2010 by Anton Korenyushkin

@import "UseLibPanelController.j"
@import "NodeView.j"
@import "NodeItems.j"

@implementation SidebarController : CPObject
{
    App app;
    UseLibPanelController useLibPanelController;
    CPScrollView scrollView;
    CPButtonBar buttonBar;
    CPButton plusButton;
    CPMenu actionsMenu;
    CPMenu actionButtonMenu;
    CPArray deleteControls;
    CPArray moveControls;
    CPArray duplicateControls;
    CPArray renameControls;
}

- (id)initWithApp:(App)anApp useLibPanelController:(UseLibPanelController)aUseLibPanelController
{
    if (self = [super init]) {
        app = anApp;
        useLibPanelController = aUseLibPanelController;

        plusButton = [CPButtonBar plusButton];
        [plusButton setTarget:self];
        [plusButton setAction:@selector(showAdd)];
        var minusButton = [CPButtonBar minusButton];
        [minusButton setTarget:self];
        [minusButton setAction:@selector(showDelete)];
        var actionButton = [CPButtonBar actionPopupButton];
        actionButtonMenu = [actionButton menu];
        [actionButtonMenu addItemWithTitle:"New File" target:self action:@selector(showNewFile)];
        [actionButtonMenu addItemWithTitle:"New Folder" target:self action:@selector(showNewFolder)];
        [actionButtonMenu addItemWithTitle:"New Environment" target:self action:@selector(showNewEnv)];
        [actionButtonMenu addItemWithTitle:"Use Library…" target:useLibPanelController action:@selector(showWindow:)];
        [actionButtonMenu addItem:[CPMenuItem separatorItem]];
        actionsMenu = [CPMenu new];
        deleteControls = [minusButton];
        moveControls = [];
        duplicateControls = [];
        renameControls = [];
        [actionButtonMenu, actionsMenu].forEach(
            function (menu) {
                [menu setAutoenablesItems:NO];
                deleteControls.push([menu addItemWithTitle:"Delete…" target:self action:@selector(showDelete)]);
                moveControls.push([menu addItemWithTitle:"Move…" target:nil action:nil]);
                duplicateControls.push([menu addItemWithTitle:"Duplicate" target:nil action:nil]);
                renameControls.push([menu addItemWithTitle:"Rename" target:nil action:nil]);
            });

        buttonBar = [CPButtonBar new];
        [buttonBar setAutoresizingMask:CPViewWidthSizable | CPViewHeightSizable];
        [buttonBar setButtons:[plusButton, minusButton, actionButton]];

        scrollView = [CPScrollView new];
        [scrollView setAutoresizingMask:CPViewWidthSizable | CPViewHeightSizable];
        [scrollView setHasHorizontalScroller:NO];
        [scrollView setAutohidesScrollers:YES];

        var outlineView = [CPOutlineView new];
        [outlineView setAllowsMultipleSelection:YES];
        [outlineView setAllowsEmptySelection:NO];
        [outlineView setAutoresizingMask:CPViewWidthSizable | CPViewHeightSizable];
        [outlineView setColumnAutoresizingStyle:CPTableViewLastColumnOnlyAutoresizingStyle];
        [outlineView setHeaderView:nil];
        [outlineView setCornerView:nil];
        var column = [CPTableColumn new];
        [column setDataView:[NodeView new]];
        [outlineView addTableColumn:column];
        [outlineView setOutlineTableColumn:column];
        app.outlineView = outlineView;
        app.code = [[CodeItem alloc] initWithApp:app];
        app.envsItem = [[EnvsItem alloc] initWithApp:app];
        app.libsItem = [[LibsItem alloc] initWithApp:app];
        [outlineView setDataSource:self];
        [outlineView setDelegate:self];
        [outlineView expandItem:app.code];
        [outlineView selectRowIndexes:[CPIndexSet indexSetWithIndex:0] byExtendingSelection:NO];
        [scrollView setDocumentView:outlineView];
    }
    return self;
}

- (void)showInView:(CPView)superview withActionsMenuItem:(CPMenuItem)actionsMenuItem
{
    var superviewSize = [superview boundsSize];
    [buttonBar setFrame:CGRectMake(0, superviewSize.height - 26, superviewSize.width, 26)];
    [scrollView setFrame:CGRectMake(0, 0, superviewSize.width, superviewSize.height - 26)];
    [app.outlineView sizeLastColumnToFit];
    [superview addSubview:scrollView];
    [superview addSubview:buttonBar];
    [[actionsMenuItem submenu] setSupermenu:nil];
    [actionsMenuItem setSubmenu:actionsMenu];
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
    var selectedItem = [app.outlineView selectedItem];
    var parentFolder = (
        [app.outlineView rootForItem:selectedItem] === app.code
        ? [selectedItem isKindOfClass:File] ? [app.outlineView parentForItem:selectedItem] : selectedItem
        : app.code);
    [app.outlineView expandItem:parentFolder];
    setTimeout(
        function () {
            var item = callback(parentFolder);
            [app.outlineView reloadItem:parentFolder reloadChildren:YES];
            [app.outlineView showItem:item];
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
            [app.outlineView showItem:newEnvItem];
        },
        0);
}

- (void)showAdd
{
    switch ([app.outlineView rootForItem:[app.outlineView selectedItem]]) {
    case app.code:
        [self showNewFile];
        break;
    case app.envsItem:
        [self showNewEnv];
        break;
    case app.libsItem:
        [useLibPanelController showWindow:nil];
        break;
    }
}

- (void)showDelete
{
    var items = [app.outlineView selectedItems];
    var description;
    var action;
    switch ([app.outlineView rootForItem:items[0]]) {
    case app.code:
        description =
            items.length == 1
            ? ([items[0] isKindOfClass:File] ? "file" : "folder") + " \"" + items[0].name + "\""
            : "selected " + items.length + " entries";
        action = @selector(deleteEntries);
        break;
    case app.envsItem:
        description =
            items.length == 1 ? "environment \"" + items[0].name + "\"" : "selected " + items.length + " environments";
        action = @selector(deleteEnvs);
        break;
    case app.libsItem:
        description =
            (items.length == 1 ? "library \"" + items[0].name + "\"" : "selected " + items.length + " libraries") +
            " from the app";
        action = @selector(deleteLibs);
        break;
    }
    [[[Confirm alloc] initWithMessage:"Are you sure want to delete the " + description + "?"
                              comment:"You cannot undo this action."
                               target:self
                               action:action]
        showPanel];
}

- (void)deleteEntries
{
    var entries = [app.outlineView selectedItems];
    entries.reverse();
    var paths = entries.map(
        function (entry) {
            entry.isLoading = YES;
            [app.outlineView reloadItem:entry];
            return [app.code pathOfItem:entry];
        });
    var request = [[HTTPRequest alloc] initWithMethod:"POST"
                                                  URL:[app url] + "code/"
                                               target:self
                                               action:@selector(didDelete:entries:)];
    [request setContext:entries];
    [request send:{action: "rm", paths: paths}];
    [app.outlineView selectItem:app.code];
}

- (void)didDelete:(JSObject)data entries:(CPArray)entries
{
    entries.forEach(
        function (entry) {
            var parentFolder = [app.outlineView parentForItem:entry];
            if ([entry isKindOfClass:File])
                [parentFolder removeFile:entry];
            else
                [parentFolder removeFolder:entry];
            [app.outlineView reloadItem:parentFolder reloadChildren:YES];
            if (parentFolder === app.code && entry.name == "manifest.json") {
                app.libs = [];
                [app.outlineView reloadItem:app.libsItem reloadChildren:YES];
            }
        });
}

- (void)deleteEnvs
{
    [app.outlineView selectedItems].forEach(
        function (env) {
            env.isLoading = YES;
            [app.outlineView reloadItem:env];
            var request = [[HTTPRequest alloc] initWithMethod:"DELETE"
                                                          URL:[app url] + "envs/" + env.name
                                                       target:self
                                                       action:@selector(didDelete:env:)];
            [request setContext:env];
            [request send];
        });
    [app.outlineView selectItem:app.envsItem];
}

- (void)didDelete:(JSObject)data env:(Env)env
{
    [app removeEnv:env];
    [app.outlineView reloadItem:app.envsItem reloadChildren:YES];
}

- (void)deleteLibs
{
    var manifest = JSON.parse([app.code fileWithName:"manifest.json"].content);
    var libs = [app.outlineView selectedItems];
    libs.forEach(
        function (lib) {
            lib.isLoading = YES;
            [app.outlineView reloadItem:lib];
            delete manifest.libs[lib.name];
        });
    var content = JSON.stringify(manifest, null, "  ");
    var request = [[HTTPRequest alloc] initWithMethod:"PUT"
                                                  URL:[app url] + "code/manifest.json"
                                               target:self
                                               action:@selector(didDelete:libs:)];
    [request setContext:{content:content, libs: libs}];
    [request setValue:"application/json" forHeader:"Content-Type"];
    [request send:content];
    [app.outlineView selectItem:app.libsItem];
}

- (void)didDelete:(JSObject)data libs:(JSObject)context
{
    [[app.code fileWithName:"manifest.json"] setContent:context.content];
    context.libs.forEach(function (lib) { [app removeLib:lib]; });
    [app.outlineView reloadItem:app.libsItem reloadChildren:YES];
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
    var items = [app.outlineView selectedItems];
    var firstRootItem;
    var rootIsCommon = YES;
    var itemsAreDeletable = YES;
    for (var i = 0; i < items.length && rootIsCommon; ++i) {
        var item = items[i];
        var rootItem = [app.outlineView rootForItem:item];
        if (firstRootItem)
            rootIsCommon = rootItem === firstRootItem;
        else
            firstRootItem = rootItem;
        itemsAreDeletable =
            itemsAreDeletable && rootIsCommon && item !== rootItem &&
            (rootItem !== app.libsItem || [item isKindOfClass:LibItem]) &&
            (rootItem !== app.envsItem || item !== app.envs[0]);
    }
    var itemsAreMovableAndDuplicatable = itemsAreDeletable && firstRootItem === app.code;
    var itemIsRenamable = itemsAreDeletable && items.length == 1;
    [actionsMenu _highlightItemAtIndex:CPNotFound];
    [actionButtonMenu _highlightItemAtIndex:CPNotFound];
    [plusButton setEnabled:rootIsCommon];
    [
        [deleteControls, itemsAreDeletable],
        [moveControls, itemsAreMovableAndDuplicatable],
        [duplicateControls, itemsAreMovableAndDuplicatable],
        [renameControls, itemIsRenamable]
    ].forEach(
        function (pair) {
            pair[0].forEach(function (control) { [control setEnabled:pair[1]]; });
        });
}

@end
