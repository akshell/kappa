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

- (CPMenuItem)addItemWithTitle:(CPString)title target:(id)target action:(SEL)action keyEquivalent:(CPString)keyEquivalent // public
{
    var item = [self addItemWithTitle:title action:action keyEquivalent:keyEquivalent];
    [item setTarget:target];
    return item;
}

- (CPMenuItem)addItemWithTitle:(CPString)title target:(id)target action:(SEL)action // public
{
    return [self addItemWithTitle:title target:target action:action keyEquivalent:nil];
}

@end
