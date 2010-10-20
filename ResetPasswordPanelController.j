// (c) 2010 by Anton Korenyushkin

@import "RequestPanelController.j"

@implementation ResetPasswordPanelController : RequestPanelController
{
    @outlet CPTextField nameOrEmailField;
    @outlet CPButton submitButton;
}

- (void)init // public
{
    return [super initWithWindowCibName:"ResetPasswordPanel"];
}

- (void)awakeFromCib // private
{
    [submitButton setEnabled:NO];
    [submitButton setKeyEquivalent:CPCarriageReturnCharacter];
}

- (void)controlTextDidChange:(id)sender // private
{
    [submitButton setEnabled:[nameOrEmailField stringValue]];
}

- (@action)submit:(id)sender // private
{
    var value = [nameOrEmailField stringValue];
    var data = {};
    data[value.indexOf("@") == -1 ? "name" : "email"] = value;
    [self requestWithMethod:"POST" URL:"/password" data:data];
}

- (void)didReceiveResponse:(JSObject)data // protected
{
    [[self window] close];
    var panel = [[CPPanel alloc] initWithContentRect:CGRectMake(0, 0, 318, 104) styleMask:CPTitledWindowMask];
    var contentView = [panel contentView];
    var imageView = [[CPImageView alloc] initWithFrame:CGRectMake(16, 16, 48, 48)];
    [imageView setImage:[[CPImage alloc] initWithContentsOfFile:[[CPBundle mainBundle] pathForResource:"Info.png"]]];
    [contentView addSubview:imageView];
    var label = [[CPTextField alloc] initWithFrame:CGRectMake(80, 16, 222, 48)];
    [label setLineBreakMode:CPLineBreakByWordWrapping];
    [label setFont:[CPFont boldSystemFontOfSize:12]];
    [label setStringValue:"An email containing confirmation URL has been sent."];
    [contentView addSubview:label];
    var button = [[CPButton alloc] initWithFrame:CGRectMake(238, 64, 64, 24)];
    [button setTitle:"OK"];
    [button setKeyEquivalent:CPCarriageReturnCharacter];
    [button setTarget:self];
    [button setAction:@selector(stopModal:)];
    [contentView addSubview:button];
    [CPApp runModalForWindow:panel];
}

- (void)stopModal:(CPButton)sender // private
{
    [CPApp stopModal];
    [[sender window] close];
}

@end
