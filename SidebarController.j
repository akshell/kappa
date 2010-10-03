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
    [self createOutlineView];
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

- (void)createOutlineView
{
    outlineView = [[CPOutlineView alloc] initWithFrame:[[scrollView contentView] bounds]];
    [outlineView setAutoresizingMask:CPViewWidthSizable | CPViewHeightSizable];
    [outlineView setHeaderView:nil];
    [outlineView setCornerView:nil];
    var column = [CPTableColumn new];
    [column setWidth:10000];
    [column setDataView:[NodeView new]];
    [outlineView addTableColumn:column];
    [outlineView setOutlineTableColumn:column];
    if (DATA.app)
        items = [
            [[CodeNodeItem alloc] initWithOutlineView:outlineView app:DATA.app],
            [[EnvsNodeItem alloc] initWithOutlineView:outlineView app:DATA.app],
            [[LibsNodeItem alloc] initWithOutlineView:outlineView app:DATA.app]
        ];
    else
        items = [];
    [outlineView setDataSource:self];
    [outlineView expandItem:items[0]];
    [scrollView setDocumentView:outlineView];
}

- (void)observeValueForKeyPath:(CPString)keyPath ofObject:(id)object change:(CPDictionary)change context:(id)context
{
    if (keyPath == "app")
        [self createOutlineView];
}

- (id)outlineView:(CPOutlineView)anOutlineview child:(int)index ofItem:(id)item
{
    return (item ? [item children] : items)[index];
}

- (BOOL)outlineView:(CPOutlineView)anOutlineview isItemExpandable:(id)item
{
    return [item hasChildren]
}

- (int)outlineView:(CPOutlineView)anOutlineview numberOfChildrenOfItem:(id)item
{
    return item ? [item children].length : items.length;
}

- (id)outlineView:(CPOutlineView)anOutlineview objectValueForTableColumn:(CPTableColumn)tableColumn byItem:(id)item
{
    return item;
}

@end
