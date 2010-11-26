// (c) 2010 by Anton Korenyushkin

@import "RequestPanelController.j"

@implementation SignupPanelController : RequestPanelController
{
    id target @accessors;
    SEL action @accessors;
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

- (id)init // public
{
    return [super initWithWindowCibName:"SignupPanel"];
}

- (void)awakeFromCib // private
{
    [nameLabel, emailLabel, passwordLabel, confirmLabel].forEach(
        function (label) { [label setAlignment:CPRightTextAlignment]; });
    [passwordField setSecure:YES];
    [confirmField setSecure:YES];
    [signupButton setEnabled:NO];
    [signupButton setKeyEquivalent:CPCarriageReturnCharacter];
}

- (void)controlTextDidChange:(id)sender // private
{
    [signupButton setEnabled:([nameField stringValue] &&
                              [emailField stringValue] &&
                              [passwordField stringValue] &&
                              [confirmField stringValue])];
}

- (@action)submit:(id)sender // private
{
    var password = [passwordField stringValue];
    if ([confirmField stringValue] == password) {
        var data = {name: [nameField stringValue], email: [emailField stringValue], password: password};
        [self requestWithMethod:"POST" URL:"/signup" data:data context:data];
    } else {
        [[[Alert alloc] initWithMessage:"The passwords don't match."
                                comment:"Please retype the password twice."
                                 target:self
                                 action:@selector(didEndMatchErrorSheet)]
                     showSheetForWindow:[self window]];
    }
}

- (void)didEndMatchErrorSheet // private
{
    [passwordField setStringValue:""];
    [confirmField setStringValue:""];
    [signupButton setEnabled:NO];
    [[self window] makeFirstResponder:passwordField];
}

- (void)didEndRequestErrorSheet:(Alert)sender // protected
{
    [[self window] makeFirstResponder:[sender message].indexOf("email") == -1 ? nameField : emailField];
}

- (void)didReceiveResponse:(JSObject)data withContext:context // protected
{
    objj_msgSend(target, action);
    [DATA setUsername:context.name];
    [DATA setEmail:context.email];
}

- (void)windowWillClose:(id)sender // private
{
    target = action = nil;
}

@end
