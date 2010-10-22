// (c) 2010 by Anton Korenyushkin

@import "PanelController.j"
@import "Data.j"

@implementation UseLibPanelController : PanelController
{
    id target;
    SEL action;
    @outlet CPTextField authorLabel;
    @outlet CPTextField authorField;
    @outlet CPTextField nameLabel;
    @outlet CPTextField nameField;
    @outlet CPTextField versionLabel;
    @outlet CPTextField versionField;
    @outlet CPTextField aliasLabel;
    @outlet CPTextField aliasField;
    @outlet CPButton useButton;
}

- (id)initWithTarget:(id)aTarget action:(SEL)anAction // public
{
    if (self = [super initWithWindowCibName:"UseLibPanel"]) {
        target = aTarget;
        action = anAction;
        [DATA addObserver:self forKeyPath:"app" options:nil context:nil];
    }
    return self;
}

- (void)awakeFromCib // private
{
    [authorLabel, nameLabel, versionLabel, aliasLabel].forEach(
        function (label) { [label setAlignment:CPRightTextAlignment]; });
    [authorField selectAll:nil];
    [useButton setEnabled:NO];
    [useButton setKeyEquivalent:CPCarriageReturnCharacter];
}

- (void)observeValueForKeyPath:(CPString)keyPath ofObject:(id)object change:(CPDictionary)change context:(id)context // private
{
    if (keyPath == "app")
        [self close];
}

- (void)controlTextDidChange:(id)sender // private
{
    [useButton setEnabled:([authorField stringValue] &&
                           [nameField stringValue] &&
                           [versionField stringValue] &&
                           [aliasField stringValue])];
}

- (void)controlTextDidFocus:(CPNotification)notification // private
{
    if ([notification object] === aliasField && ![aliasField stringValue]) {
        [aliasField setStringValue:[nameField stringValue]];
        [aliasField selectAll:nil];
        [self controlTextDidChange:nil];
    }
}

- (@action)submit:(id)sender // private
{
    objj_msgSend(target, action, [[Lib alloc] initWithName:[aliasField stringValue]
                                                authorName:[authorField stringValue]
                                                   appName:[nameField stringValue]
                                                   version:[versionField stringValue]]);
}

- (void)didEndErrorSheet:(Alert)sender // public
{
    var message = [sender message];
    if (message.indexOf("version") != -1)
        [[self window] makeFirstResponder:versionField];
    else if (message.indexOf("library") != -1)
        [[self window] makeFirstResponder:nameField];
    else if (message.indexOf("author") != -1)
        [[self window] makeFirstResponder:authorField];
    else if (message.indexOf("alias") != -1)
        [[self window] makeFirstResponder:aliasField];
}

@end
