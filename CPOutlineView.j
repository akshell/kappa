// (c) 2010 by Anton Korenyushkin

@implementation CPOutlineView (Utils)

- (id)rootForItem:(id)item
{
    for (var parentItem = item; parentItem; parentItem = [self parentForItem:parentItem])
        item = parentItem;
    return item;
}

- (id)selectedItem
{
    return [self itemAtRow:[self selectedRow]];
}

- (CPArray)selectedItems
{
    var indexes = []
    [[self selectedRowIndexes] getIndexes:indexes maxCount:-1 inIndexRange:nil];
    return indexes.map(function (index) { return [self itemAtRow:index]; });
}

- (void)selectItem:(id)item
{
    [self selectRowIndexes:[CPIndexSet indexSetWithIndex:[self rowForItem:item]] byExtendingSelection:NO];
}

- (void)showItem:(id)item
{
    [self scrollRectToVisible:[self frameOfDataViewAtColumn:0 row:[self rowForItem:item]]];
}

@end
