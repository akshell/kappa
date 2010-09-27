// (c) 2010 by Anton Korenyushkin

@implementation PanelController : CPWindowController
{
}

- (id)initWithWindow:(CPWindow)window
{
    if (self = [super initWithWindow:window])
        [DATA addObserver:self forKeyPath:"username" options:nil context:nil];
    return self;
}

- (void)observeValueForKeyPath:(CPString)keyPath ofObject:(id)object change:(CPDictionary)change context:(id)context
{
    if (keyPath == "username")
        [self close];
}

- (void)loadWindow
{
    [super loadWindow];
    [[self window] setDelegate:self];
}

- (void)windowWillClose:(id)sender
{
    [self setWindow:nil];
}

- (@action)showWindow:(id)sender
{
    if (![[self window] isVisible])
        [[self window] center];
    [super showWindow:sender];
}

@end
