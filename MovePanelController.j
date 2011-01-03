// (c) 2010-2011 by Anton Korenyushkin

@import "PanelController.j"
@import "Alert.j"

@implementation MovePanelController : PanelController
{
    id target;
    SEL action;
    @outlet CPTextField moveLabel;
    @outlet CPTextField pathField;
    @outlet CPButton moveButton;
}

- (id)initWithTarget:(id)aTarget action:(SEL)anAction // public
{
    if (self = [super initWithWindowCibName:"MovePanel"]) {
        target = aTarget;
        action = anAction;
    }
    return self;
}

- (void)awakeFromCib // private
{
    [moveButton setKeyEquivalent:CPCarriageReturnCharacter];
}

- (void)showWindowWithDescription:(CPString)description // public
{
    [CPApp runModalForWindow:[self window]];
    [moveLabel setStringValue:"Move the " + description + " to:"];
    [pathField setStringValue:""];
    [moveButton setEnabled:NO];
}

- (void)controlTextDidChange:(id)sender // private
{
    [moveButton setEnabled:[pathField stringValue]];
}

- (@action)submit:(id)sender // private
{
    objj_msgSend(target, action, [pathField stringValue]);
}

- (void)windowWillClose:(id)sender // private
{
    [CPApp stopModal];
}

@end
