// (c) 2010 by Anton Korenyushkin

@import "RequestPanelController.j"

@implementation LoginPanelController : RequestPanelController
{
    @outlet CPTextField nameLabel;
    @outlet CPTextField nameField;
    @outlet CPTextField passwordLabel;
    @outlet CPTextField passwordField;
    @outlet CPButton loginButton;
}

- (id)init
{
    return [super initWithWindowCibName:"LoginPanel"];
}

- (void)awakeFromCib
{
    [nameLabel, passwordLabel].forEach(
        function (label) { [label setAlignment:CPRightTextAlignment]; });
    [passwordField setSecure:YES];
    [loginButton setEnabled:NO];
    [loginButton setKeyEquivalent:CPCarriageReturnCharacter];
}

- (void)controlTextDidChange:(id)sender
{
    [loginButton setEnabled:[nameField stringValue] && [passwordField stringValue]];
}

- (@action)signUp:(id)sender
{
    [[self window] close];
    [[CPApp delegate] orderFrontSignupPanel];
}

- (@action)submit:(id)sender
{
    [self requestWithMethod:"POST" URL:"/login" data:{name: [nameField stringValue], password: [passwordField stringValue]}];
}

- (void)didReceiveResponse:(JSObject)data
{
    [[CPApp delegate] setUsername:[nameField stringValue]];
}

@end
