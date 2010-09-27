// (c) 2010 by Anton Korenyushkin

@import "RequestPanelController.j"
@import "ResetPasswordPanelController.j"
@import "Link.j"

@implementation LoginPanelController : RequestPanelController
{
    @outlet CPTextField nameLabel;
    @outlet CPTextField nameField;
    @outlet CPTextField passwordLabel;
    @outlet CPTextField passwordField;
    @outlet Link resetPasswordLink;
    @outlet CPButton loginButton;
    ResetPasswordPanelController resetPasswordPanelController;
}

- (id)initWithResetPasswordPanelController:(ResetPasswordPanelController)aResetPasswordPanelController
{
    if (self = [super initWithWindowCibName:"LoginPanel"])
        resetPasswordPanelController = aResetPasswordPanelController;
    return self;
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
    [[User sharedUser] setName:[nameField stringValue]];
}

- (@action)resetPassword:(id)sender
{
    [self close];
    [resetPasswordPanelController showWindow:nil];
}

@end
