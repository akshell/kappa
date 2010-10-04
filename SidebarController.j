// (c) 2010 by Anton Korenyushkin

@import "NodeView.j"
@import "NodeItems.j"

@implementation SidebarController : CPObject
{
    @outlet CPButtonBar buttonBar;
    @outlet CPScrollView scrollView;
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
    [actionMenu addItemWithTitle:"New File" action:nil keyEquivalent:nil];
    [actionMenu addItemWithTitle:"New Folder" action:nil keyEquivalent:nil];
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
    if (DATA.app && DATA.app.cache.rootItems) {
        items = DATA.app.cache.rootItems;
        [scrollView setDocumentView:DATA.app.cache.outlineView];
        return;
    }
    var outlineView = [[CPOutlineView alloc] initWithFrame:[[scrollView contentView] bounds]];
    [outlineView setAutoresizingMask:CPViewWidthSizable | CPViewHeightSizable];
    [outlineView setHeaderView:nil];
    [outlineView setCornerView:nil];
    var column = [CPTableColumn new];
    [column setWidth:10000];
    [column setDataView:[NodeView new]];
    [outlineView addTableColumn:column];
    [outlineView setOutlineTableColumn:column];
    if (DATA.app) {
        items = DATA.app.cache.rootItems = [
            [[CodeItem alloc] initWithOutlineView:outlineView app:DATA.app],
            [[EnvsItem alloc] initWithOutlineView:outlineView app:DATA.app],
            [[LibsItem alloc] initWithOutlineView:outlineView app:DATA.app]
        ];
        DATA.app.cache.outlineView = outlineView;
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

- (id)outlineView:(CPOutlineView)outlineview child:(int)index ofItem:(id)item
{
    return item ? [item childAtIndex:index] : items[index];
}

- (BOOL)outlineView:(CPOutlineView)outlineview isItemExpandable:(id)item
{
    return [item isExpandable]
}

- (int)outlineView:(CPOutlineView)outlineview numberOfChildrenOfItem:(id)item
{
    return item ? [item numberOfChildren] : items.length;
}

- (id)outlineView:(CPOutlineView)outlineview objectValueForTableColumn:(CPTableColumn)tableColumn byItem:(id)item
{
    return item;
}

@end
