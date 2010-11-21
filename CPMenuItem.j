// (c) 2010 by Anton Korenyushkin

@implementation CPMenuItem (Utils)

// FIXME: Dirty hack
- (void)doSetEnabled:(BOOL)flag // public
{
    if (_isEnabled == !!flag)
        return;
    if (flag) {
        _isEnabled = YES;
        [_menuItemView highlight:YES];
        [_menuItemView highlight:NO];
    } else {
        [_menuItemView highlight:NO];
        _isEnabled = NO;
    }
}

@end
