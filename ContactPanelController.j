// (c) 2010 by Anton Korenyushkin

@import "RequestPanelController.j"

@implementation ContactPanelController : RequestPanelController
{
    @outlet CPTextField emailField;
    @outlet TextView messageTextView;
    @outlet CPButton sendButton;
}

- (void)init // public
{
    return [super initWithWindowCibName:"ContactPanel"];
}

- (void)awakeFromCib // private
{
    [messageTextView setDelegate:self];
    [sendButton setEnabled:NO];
    if (DATA.email) {
        [emailField setStringValue:DATA.email];
        [[self window] makeFirstResponder:messageTextView];
    }
}

- (void)controlTextDidChange:(id)sender // private
{
    [sendButton setEnabled:[messageTextView stringValue]];
}

- (@action)submit:(id)sender // private
{
    [self requestWithMethod:"POST" URL:"/contact" data:{email: [emailField stringValue], message:[messageTextView stringValue]}];
}

- (void)didReceiveResponse:(JSObject)data // protected
{
    [self close];
}

@end
