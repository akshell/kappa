// (c) 2010 by Anton Korenyushkin

@import "User.j"

@implementation PanelController : CPWindowController
{
}

- (id)initWithWindow:(CPWindow)window
{
    if (self = [super initWithWindow:window])
        [[User sharedUser] addObserver:self forKeyPath:"name" options:nil context:nil];
    return self;
}

- (void)observeValueForKeyPath:(CPString)keyPath ofObject:(id)object change:(CPDictionary)change context:(id)context
{
    if (object === [User sharedUser])
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
