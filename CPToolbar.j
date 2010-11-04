// (c) 2010 by Anton Korenyushkin

@implementation CPToolbar (Utils)

- (void)reloadChangedToolbarItems // public
{
    var newItemIdentifiers = [_delegate toolbarDefaultItemIdentifiers:self];
    for (var fromIndex = 0;; ++fromIndex) {
        if (fromIndex == _itemIdentifiers.length || fromIndex == newItemIdentifiers.length)
            return;
        if (_itemIdentifiers[fromIndex] != newItemIdentifiers[fromIndex])
            break;
    }
    for (var shift = 0;; ++shift)
        if (_itemIdentifiers[_itemIdentifiers.length - 1 - shift] != newItemIdentifiers[newItemIdentifiers.length - 1 - shift])
            break;
    var args = [fromIndex, _itemIdentifiers.length - fromIndex - shift];
    var toIndex = newItemIdentifiers.length - shift;
    for (var i = fromIndex; i < toIndex; ++i) {
        var identifier = newItemIdentifiers[i];
        args.push([CPToolbarItem _standardItemWithItemIdentifier:identifier] ||
                  [_delegate toolbar:self itemForItemIdentifier:identifier willBeInsertedIntoToolbar:YES]);
    }
    Array.prototype.splice.apply(_items, args);
    _itemsSortedByVisibilityPriority = _items;
    _itemIdentifiers = newItemIdentifiers;
    [_toolbarView reloadToolbarItemsFrom:fromIndex to:toIndex];
}

@end

@implementation _CPToolbarView (Utils)

- (void)reloadToolbarItemsFrom:(unsigned)fromIndex to:(unsigned)toIndex // public
{
    var items = [_toolbar items];
    var oldUIDs = {};
    for (var i = 0; i < fromIndex; ++i)
        oldUIDs[[items[i] UID]] = true;
    for (var i = toIndex; i < items.length; ++i)
        oldUIDs[[items[i] UID]] = true;
    for (var uid in _viewsForToolbarItems) {
        if (!oldUIDs.hasOwnProperty(uid)) {
            var view = _viewsForToolbarItems[uid];
            _minWidth -= [view minSize].width + 10;
            [view removeFromSuperview];
            delete _viewsForToolbarItems[uid];
        }
    }
    for (var i = fromIndex; i < toIndex; ++i) {
        var item = items[i];
        var view = [[_CPToolbarItemView alloc] initWithToolbarItem:item toolbar:self];
        _viewsForToolbarItems[[item UID]] = view;
        [self addSubview:view];
        _minWidth += [view minSize].width + 10;
    }
    [self tile];
}

@end

@implementation CPToolbarItem (Hack)

- (id)copy // public
{
    return self;
}

@end
