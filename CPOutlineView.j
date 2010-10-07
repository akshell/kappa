// (c) 2010 by Anton Korenyushkin

@implementation CPOutlineView (RevealChildItemOfItem)

- (void)revealChildItem:(id)childItem ofItem:(id)parentItem
{
    [self reloadItem:parentItem reloadChildren:YES];
    [self expandItem:parentItem];
    [self expandItem:childItem];
    var row = [self rowForItem:childItem];
    [self selectRowIndexes:[CPIndexSet indexSetWithIndex:row] byExtendingSelection:NO];
    [self scrollRectToVisible:[self frameOfDataViewAtColumn:0 row:row]];
}

@end
