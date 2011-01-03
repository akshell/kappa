// (c) 2010-2011 by Anton Korenyushkin

@import "PanelController.j"

@implementation GoToLinePanelController : PanelController
{
    @outlet CPTextField lineField;
    @outlet CPButton goButton;
    id target;
    SEL action;
}

- (id)initWithTarget:(id)aTarget action:(SEL)anAction // public
{
    if (self = [super initWithWindowCibName:"GoToLinePanel"]) {
        target = aTarget;
        action = anAction;
        [DATA addObserver:self forKeyPath:"app.buffer"];
    }
    return self;
}

- (void)awakeFromCib // private
{
    [goButton setEnabled:NO];
    [goButton setKeyEquivalent:CPCarriageReturnCharacter];
}

- (void)observeValueForKeyPath:(CPString)keyPath ofObject:(id)object change:(CPDictionary)change context:(id)context // protected
{
    if (keyPath == "app.buffer")
        [self close];
    else
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
}

- (void)controlTextDidChange:(id)sender // private
{
    var lineNumber = +[lineField stringValue];
    [goButton setEnabled:!isNaN(lineNumber) && lineNumber >= 0 && lineNumber % 1 == 0];
}

- (@action)submit:(id)sender // private
{
    objj_msgSend(target, action, +[lineField stringValue]);
    [self close];
}

@end
