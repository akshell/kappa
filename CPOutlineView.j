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
    var indexSet = [self selectedRowIndexes];
    var items = [];
    for (var index = [indexSet firstIndex]; index != CPNotFound; index = [indexSet indexGreaterThanIndex:index])
        items.push([self itemAtRow:index]);
    return items;
}

- (void)selectItem:(id)item
{
    [self selectRowIndexes:[CPIndexSet indexSetWithIndex:[self rowForItem:item]] byExtendingSelection:NO];
}

- (void)showItem:(id)item
{
    [self scrollRectToVisible:[self frameOfDataViewAtColumn:0 row:[self rowForItem:item]]];
}

- (void)revealChildItem:(id)childItem ofItem:(id)parentItem
{
    [self reloadItem:parentItem reloadChildren:YES];
    [self expandItem:parentItem];
    var row = [self rowForItem:childItem];
    [self selectRowIndexes:[CPIndexSet indexSetWithIndex:row] byExtendingSelection:NO];
    [self scrollRectToVisible:[self frameOfDataViewAtColumn:0 row:row]];
}

@end
