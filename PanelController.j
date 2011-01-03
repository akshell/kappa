// (c) 2010-2011 by Anton Korenyushkin

@implementation PanelController : CPWindowController

- (id)initWithWindow:(CPWindow)window // public
{
    if (self = [super initWithWindow:window])
        [DATA addObserver:self forKeyPath:"username"];
    return self;
}

- (void)close // public
{
    // This function is smarter than the original: _window isn't created if it was nil.
    [_window close];
}

- (void)observeValueForKeyPath:(CPString)keyPath ofObject:(id)object change:(CPDictionary)change context:(id)context // protected
{
    if (keyPath == "username")
        [self close];
}

- (void)loadWindow // public
{
    [super loadWindow];
    [[self window] setDelegate:self];
}

- (void)windowWillClose:(id)sender // private
{
    [self setWindow:nil];
}

- (@action)showWindow:(id)sender // public
{
    if (![[self window] isVisible])
        [[self window] center];
    [super showWindow:sender];
}

@end
