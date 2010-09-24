// (c) 2010 by Anton Korenyushkin

@import "RequestPanelController.j"
@import "Link.j"

@implementation LoginPanelController : RequestPanelController
{
    @outlet CPTextField nameLabel;
    @outlet CPTextField nameField;
    @outlet CPTextField passwordLabel;
    @outlet CPTextField passwordField;
    @outlet Link resetPasswordLink;
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
    [resetPasswordLink setFont:[CPFont systemFontOfSize:11]];
    [resetPasswordLink sizeToFit];
}

- (void)controlTextDidChange:(id)sender
{
    [loginButton setEnabled:[nameField stringValue] && [passwordField stringValue]];
}

- (@action)submit:(id)sender
{
    [self requestWithMethod:"POST" URL:"/login" data:{name: [nameField stringValue], password: [passwordField stringValue]}];
}

- (void)didReceiveResponse:(JSObject)data
{
    [[CPApp delegate] setUsername:[nameField stringValue]];
}

- (@action)resetPassword:(id)sender
{
    [[self window] close];
    [[CPApp delegate] orderFrontPasswordPanel];
}

@end
