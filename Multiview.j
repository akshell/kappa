// (c) 2010 by Anton Korenyushkin

@implementation Multiview : CPView
{
    CPView currentView;
}

- (void)showView:(CPView)view // public
{
    [currentView setHidden:YES];
    currentView = view;
    if (!view)
        return;
    if ([view superview] === self) {
        [view setHidden:NO];
        return
    }
    [view setFrame:[self bounds]];
    [view setAutoresizingMask:CPViewWidthSizable | CPViewHeightSizable];
    [self addSubview:view];
}

@end
