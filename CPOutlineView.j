// (c) 2010 by Anton Korenyushkin

@implementation CPOutlineView (Utils)

- (id)rootForItem:(id)item // public
{
    for (var parentItem = item; parentItem; parentItem = [self parentForItem:parentItem])
        item = parentItem;
    return item;
}

- (id)selectedItem // public
{
    return [self itemAtRow:[self selectedRow]];
}

- (CPArray)selectedItems // public
{
    var indexes = []
    [[self selectedRowIndexes] getIndexes:indexes maxCount:-1 inIndexRange:nil];
    return indexes.map(function (index) { return [self itemAtRow:index]; });
}

- (void)selectItems:(CPArray)items // public
{
    var indexSet = [CPIndexSet new];
    items.forEach(function (item) { [indexSet addIndex:[self rowForItem:item]]; });
    if ([indexSet isEqualToIndexSet:_selectedRowIndexes])
        [self _noteSelectionDidChange];
    else
        [self selectRowIndexes:indexSet byExtendingSelection:NO];
}

- (void)showItem:(id)item // public
{
    [self scrollRectToVisible:[self frameOfDataViewAtColumn:0 row:[self rowForItem:item]]];
}

// XXX: Monkey patching cappuccino
- (void)expandItem:(id)anItem expandChildren:(BOOL)shouldExpandChildren
{
    var itemInfo = null;
    if (!anItem)
        itemInfo = _rootItemInfo;
    else
        itemInfo = _itemInfosForItems[[anItem UID]];
    if (!itemInfo)
        return;
    if (!itemInfo.isExpanded) {
        [self _noteItemWillExpand:anItem];
        var selectedItems = [self selectedItems];
        itemInfo.isExpanded = YES;
        [self reloadItem:anItem reloadChildren:YES];
        [self selectItems:selectedItems];
        [self _noteItemDidExpand:anItem];
    }
    if (shouldExpandChildren) {
        var children = itemInfo.children;
        var childIndex = children.length;
        while (childIndex--)
            [self expandItem:children[childIndex] expandChildren:YES];
    }
}

// XXX: Monkey patching cappuccino
- (void)collapseItem:(id)anItem
{
    if (!anItem)
        return;
    var itemInfo = _itemInfosForItems[[anItem UID]];
    if (!itemInfo)
        return;
    if (!itemInfo.isExpanded)
        return;
    [self _noteItemWillCollapse:anItem];
    var selectedItems = [self selectedItems];
    itemInfo.isExpanded = NO;
    [self reloadItem:anItem reloadChildren:YES];
    selectedItems = selectedItems.map(
        function (item) {
            for (var parentItem = item; parentItem; parentItem = [self parentForItem:parentItem])
                if (parentItem === anItem)
                    return anItem;
            return item;
        });
    [self selectItems:selectedItems];
    [self _noteItemDidCollapse:anItem];
}

@end
