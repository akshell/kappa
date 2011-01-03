// (c) 2010-2011 by Anton Korenyushkin

@implementation SmartScrollView : CPScrollView
{
    CGSize baseSize @accessors(readonly);
}

- (void)setBaseSize:(CGRect)aBaseSize // public
{
    baseSize = aBaseSize;
    [self adjustDocumentSize];
}

- (void)setFrame:(CGRect)frame // public
{
    [super setFrame:frame];
    [self adjustDocumentSize];
}

- (void)adjustDocumentSize // private
{
    if (!baseSize)
        return;
    var documentView = [self documentView];
    var boundsSize = [self boundsSize];
    var scrollerWidth = [CPScroller scrollerWidth];
    if (baseSize.width > boundsSize.width)
        [documentView setFrameSize:CGSizeMake(baseSize.width, MAX(baseSize.height, boundsSize.height - scrollerWidth))];
    else if (baseSize.height > boundsSize.height)
        [documentView setFrameSize:CGSizeMake(MAX(baseSize.width, boundsSize.width - scrollerWidth), baseSize.height)];
    else
        [documentView setFrameSize:boundsSize];
}

@end
