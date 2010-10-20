// (c) 2010 by Anton Korenyushkin

@import "RequestPanelController.j"

@implementation ChangePasswordPanelController : RequestPanelController
{
    @outlet CPTextField oldPasswordLabel;
    @outlet CPTextField oldPasswordField;
    @outlet CPTextField newPasswordLabel;
    @outlet CPTextField newPasswordField;
    @outlet CPTextField confirmLabel;
    @outlet CPTextField confirmField;
    @outlet CPButton changeButton;
}

- (void)init // public
{
    return [super initWithWindowCibName:"ChangePasswordPanel"];
}

- (void)awakeFromCib // private
{
    [oldPasswordLabel, newPasswordLabel, confirmLabel].forEach(
        function (label) { [label setAlignment:CPRightTextAlignment]; });
    [oldPasswordField, newPasswordField, confirmField].forEach(
        function (field) { [field setSecure:YES]; });
    [changeButton setEnabled:NO];
    [changeButton setKeyEquivalent:CPCarriageReturnCharacter];
}

- (void)controlTextDidChange:(id)sender // private
{
    [changeButton setEnabled:[oldPasswordField stringValue] && [newPasswordField stringValue] && [confirmField stringValue]];
}

- (@action)changePassword:(id)sender // private
{
    var newPassword = [newPasswordField stringValue];
    if ([confirmField stringValue] == newPassword)
        [self requestWithMethod:"POST"
                            URL:"/password"
                           data:{"old": [oldPasswordField stringValue], "new": newPassword}];
    else
        [[[Alert alloc] initWithMessage:"The new password and its confirmation don't match."
                                comment:"Please retype the new password twice."
                                 target:self
                                 action:@selector(didEndMatchErrorSheet)]
                     showSheetForWindow:[self window]];
}

- (void)didEndRequestErrorSheet:(Alert)sender // protected
{
    [oldPasswordField setStringValue:""];
    [changeButton setEnabled:NO];
    [[self window] makeFirstResponder:oldPasswordField];
}

- (void)didEndMatchErrorSheet // private
{
    [newPasswordField setStringValue:""];
    [confirmField setStringValue:""];
    [changeButton setEnabled:NO];
    [[self window] makeFirstResponder:newPasswordField];
}

- (void)didReceiveResponse:(JSObject)data // protected
{
   [[self window] close];
   [oldPasswordField, newPasswordField, confirmField].forEach(
       function (field) { [field setStringValue:""]; });
   [changeButton setEnabled:NO];
}

@end
