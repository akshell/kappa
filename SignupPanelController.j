// (c) 2010 by Anton Korenyushkin

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

- (@action)submit:(id)sender
{
    var password = [passwordField stringValue];
    if ([confirmField stringValue] == password)
        [self requestWithMethod:"POST"
                            URL:"/signup"
                           data:{name: [nameField stringValue], email: [emailField stringValue], password: password}];
    else
        [[[Alert alloc] initWithMessage:"The passwords don't match."
                                comment:"Please retype the password twice."
                                 target:self
                                 action:@selector(didEndMatchErrorSheet)]
            displaySheetForWindow:[self window]];
}

- (void)didEndMatchErrorSheet
{
    [passwordField setStringValue:""];
    [confirmField setStringValue:""];
    [signupButton setEnabled:NO];
    [[self window] makeFirstResponder:passwordField];
}

- (void)didEndRequestErrorSheet:(Alert)sender
{
    [[self window] makeFirstResponder:[sender message].indexOf("email") == -1 ? nameField : emailField];
}

- (void)didReceiveResponse:(JSObject)data
{
    [[CPApp delegate] setUsername:[nameField stringValue]];
}

@end
