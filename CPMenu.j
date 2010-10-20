// (c) 2010 by Anton Korenyushkin

@implementation CPMenu (Utils)

- (void)removeAllItems // public
{
    for (var index = [self numberOfItems] - 1; index >= 0; --index)
        [self removeItemAtIndex:index];
}

- (CPMenuItem)addItemWithTitle:(CPString)title // public
{
    return [self addItemWithTitle:title action:nil keyEquivalent:nil];
}

- (CPMenuItem)addItemWithTitle:(CPString)title target:(id)target action:(SEL)action // public
{
    var item = [self addItemWithTitle:title action:action keyEquivalent:nil];
    [item setTarget:target];
    return item;
}

@end
