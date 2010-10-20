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
    [self selectRowIndexes:indexSet byExtendingSelection:NO];
}

- (void)showItem:(id)item // public
{
    [self scrollRectToVisible:[self frameOfDataViewAtColumn:0 row:[self rowForItem:item]]];
}

@end
