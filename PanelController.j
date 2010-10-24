// (c) 2010 by Anton Korenyushkin

@implementation PanelController : CPWindowController

- (id)initWithWindow:(CPWindow)window // public
{
    if (self = [super initWithWindow:window])
        [DATA addObserver:self forKeyPath:"username"];
    return self;
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
