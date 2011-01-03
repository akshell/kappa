// (c) 2010-2011 by Anton Korenyushkin

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

- (id)initWithResetPasswordPanelController:(ResetPasswordPanelController)aResetPasswordPanelController // public
{
    if (self = [super initWithWindowCibName:"LoginPanel"])
        resetPasswordPanelController = aResetPasswordPanelController;
    return self;
}

- (void)awakeFromCib // private
{
    [nameLabel, passwordLabel].forEach(
        function (label) { [label setAlignment:CPRightTextAlignment]; });
    [passwordField setSecure:YES];
    [loginButton setEnabled:NO];
    [loginButton setKeyEquivalent:CPCarriageReturnCharacter];
    [resetPasswordLink setFont:[CPFont systemFontOfSize:11]];
    [resetPasswordLink sizeToFit];
}

- (void)controlTextDidChange:(id)sender // private
{
    [loginButton setEnabled:[nameField stringValue] && [passwordField stringValue]];
}

- (@action)submit:(id)sender // private
{
    var username = [nameField stringValue];
    [self requestWithMethod:"POST" URL:"/login" data:{name: username, password: [passwordField stringValue]}];
}

- (void)didReceiveResponse:(JSObject)basis // protected
{
    [DATA loadFromBasis:basis];
}

- (@action)resetPassword:(id)sender // private
{
    [self close];
    [resetPasswordPanelController showWindow:nil];
}

@end
