// (c) 2010 by Anton Korenyushkin

@implementation CPMenu (RemoveAllItems)

- (void)removeAllItems
{
    for (var index = [self numberOfItems] - 1; index >= 0; --index)
        [self removeItemAtIndex:index];
}

@end
