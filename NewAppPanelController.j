// (c) 2010 by Anton Korenyushkin

@import "RequestPanelController.j"

@implementation NewAppPanelController : RequestPanelController
{
    @outlet CPTextField nameField;
    @outlet CPButton createButton;
    id target;
    SEL action;
}

- (void)initWithTarget:(id)aTarget action:(SEL)anAction // public
{
    if (self = [super initWithWindowCibName:"NewAppPanel"]) {
        target = aTarget;
        action = anAction;
    }
    return self;
}

- (void)awakeFromCib // private
{
    [createButton setEnabled:NO];
    [createButton setKeyEquivalent:CPCarriageReturnCharacter];
}

- (void)controlTextDidChange:(id)sender // private
{
    [createButton setEnabled:[nameField stringValue]];
}

- (@action)submit:(id)sender // private
{
    [self requestWithMethod:"POST" URL:"/apps/" data:{name: [nameField stringValue]}];
}

- (void)didReceiveResponse:(JSObject)data // protected
{
    objj_msgSend(target, action, [nameField stringValue]);
    [self close];
}

@end
