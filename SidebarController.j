// (c) 2010 by Anton Korenyushkin

@import "NodeView.j"
@import "NodeItems.j"

@implementation SidebarController : CPObject
{
    @outlet CPButtonBar buttonBar;
    @outlet CPScrollView scrollView;
    CPOutlineView outlineView;
    CPArray items;
}

- (void)awakeFromCib
{
    [self setOutlineView];
    [DATA addObserver:self forKeyPath:"app" options:CPKeyValueObservingOptionNew context:nil];

    var plusButton = [CPButtonBar plusButton];
    var minusButton = [CPButtonBar minusButton];
    var actionPopupButton = [CPButtonBar actionPopupButton];
    var actionMenu = [actionPopupButton menu];
    [[actionMenu addItemWithTitle:"New File" action:@selector(showNewFile) keyEquivalent:nil] setTarget:self];
    [[actionMenu addItemWithTitle:"New Folder" action:@selector(showNewFolder) keyEquivalent:nil] setTarget:self];
    [actionMenu addItemWithTitle:"New Environment" action:nil keyEquivalent:nil];
    [actionMenu addItemWithTitle:"Use Library…" action:nil keyEquivalent:nil];
    [actionMenu addItem:[CPMenuItem separatorItem]];
    [actionMenu addItemWithTitle:"Delete…" action:nil keyEquivalent:nil];
    [actionMenu addItemWithTitle:"Move…" action:nil keyEquivalent:nil];
    [actionMenu addItemWithTitle:"Duplicate" action:nil keyEquivalent:nil];
    [actionMenu addItemWithTitle:"Rename" action:nil keyEquivalent:nil];
    [buttonBar setButtons:[plusButton, minusButton, actionPopupButton]];
}

- (void)setOutlineView
{
    if (DATA.app && DATA.app.rootItems) {
        items = DATA.app.rootItems;
        outlineView = DATA.app.outlineView;
        [scrollView setDocumentView:outlineView];
        return;
    }
    outlineView = [[CPOutlineView alloc] initWithFrame:[[scrollView contentView] bounds]];
    [outlineView setAllowsMultipleSelection:YES];
    [outlineView setAutoresizingMask:CPViewWidthSizable | CPViewHeightSizable];
    [outlineView setColumnAutoresizingStyle:CPTableViewLastColumnOnlyAutoresizingStyle];
    [outlineView setHeaderView:nil];
    [outlineView setCornerView:nil];
    var column = [[CPTableColumn alloc] initWithIdentifier:"column"];
    [column setDataView:[NodeView new]];
    [outlineView addTableColumn:column];
    [outlineView setOutlineTableColumn:column];
    if (DATA.app) {
        items = DATA.app.rootItems = [
            [[CodeItem alloc] initWithApp:DATA.app],
            [[EnvsItem alloc] initWithApp:DATA.app],
            [[LibsItem alloc] initWithApp:DATA.app]
        ];
        DATA.app.outlineView = outlineView;
    } else {
        items = [];
    }
    [outlineView setDataSource:self];
    [outlineView expandItem:items[0]];
    [scrollView setDocumentView:outlineView];
}

- (void)observeValueForKeyPath:(CPString)keyPath ofObject:(id)object change:(CPDictionary)change context:(id)context
{
    if (keyPath == "app")
        [self setOutlineView];
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
