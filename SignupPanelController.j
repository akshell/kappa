// (c) 2010 by Anton Korenyushkin

@import "ErrorPanelController.j"
@import "RequestPanelController.j"

@implementation SignupPanelController : RequestPanelController
{
    @outlet CPTextField nameLabel;
    @outlet CPTextField nameField;
    @outlet CPTextField emailLabel;
    @outlet CPTextField emailField;
    @outlet CPTextField passwordLabel;
    @outlet CPTextField passwordField;
    @outlet CPTextField confirmLabel;
    @outlet CPTextField confirmField;
    @outlet CPButton signupButton;
}

- (id)init
{
    return [super initWithWindowCibName:"SignupPanel"];
}

- (void)awakeFromCib
{
    [nameLabel, emailLabel, passwordLabel, confirmLabel].forEach(
        function (label) { [label setAlignment:CPRightTextAlignment]; });
    [passwordField setSecure:YES];
    [confirmField setSecure:YES];
    [signupButton setEnabled:NO];
    [signupButton setKeyEquivalent:CPCarriageReturnCharacter];
}

- (void)controlTextDidChange:(id)sender
{
    [signupButton setEnabled:([nameField stringValue] &&
                              [emailField stringValue] &&
                              [passwordField stringValue] &&
                              [confirmField stringValue])];
}

- (@action)logIn:(id)sender
{
    [[self window] close];
    [[CPApp delegate] orderFrontLoginPanel];
}

- (@action)submit:(id)sender
{
    var password = [passwordField stringValue];
    if ([confirmField stringValue] == password)
        [self requestWithMethod:"POST"
                            URL:"/signup"
                           data:{name: [nameField stringValue], email: [emailField stringValue], password: password}];
    else
        [[[ErrorPanelController alloc] initWithMessage:"The passwords don't match."
                                               comment:"Please retype the password twice."
                                                target:self
                                                action:@selector(didEndPasswordErrorSheet)]
            displaySheetForWindow:[self window]];
}

- (void)didEndPasswordErrorSheet
{
    [passwordField setStringValue:""];
    [confirmField setStringValue:""];
    [signupButton setEnabled:NO];
    [[self window] makeFirstResponder:passwordField];
}

- (void)didEndRequestErrorSheet:(ErrorPanelController)sender
{
    [[self window] makeFirstResponder:[sender message].indexOf("email") == -1 ? nameField : emailField];
}

- (void)didReceiveResponse:(JSObject)data
{
    [[self window] close];
    [[CPApp delegate] setUsername:[nameField stringValue]];
}

@end