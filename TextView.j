// (c) 2010 by Anton Korenyushkin

@implementation TextView : CPView
{
    DOMElement textarea;
    id delegate @accessors(readonly);
}

- (id)initWithFrame:(CGRect)frame font:(CPFont)font // public
{
    if (self = [super initWithFrame:frame]) {
        textarea = document.createElement("textarea");
        [self adjustTextareaSize];
        textarea.style.position = "absolute";
        textarea.style.left = "0";
        textarea.style.top = "0";
        textarea.style.margin = "0";
        textarea.style.padding = "2px";
        textarea.style.border = "1px solid 7D7D7D";
        textarea.style.resize = "none";
        textarea.style.font = [font cssString];
        _DOMElement.appendChild(textarea);
    }
    return self;
}

- (id)initWithFrame:(CGRect)frame // public
{
    return [self initWithFrame:frame font:SystemFont];
}

- (void)setFrame:(CGRect)frame // public
{
    [super setFrame:frame];
    [self adjustTextareaSize];
}

- (void)adjustTextareaSize // private
{
    textarea.style.width = (CGRectGetWidth(_frame) - 6) + "px";
    textarea.style.height = (CGRectGetHeight(_frame) - 6) + "px";
}

- (void)setEditable:(BOOL)flag // public
{
    textarea.readOnly = !flag;
}

- (CPString)stringValue // public
{
    return textarea.value;
}

- (void)setStringValue:(CPString)value // public
{
    textarea.value = value;
}

- (void)setDelegate:(id)aDelegate // public
{
    var defaultCenter = [CPNotificationCenter defaultCenter];
    if (delegate)
        [defaultCenter removeObserver:delegate name:CPControlTextDidChangeNotification object:self];
    delegate = aDelegate;
    if ([delegate respondsToSelector:@selector(controlTextDidChange:)])
        [defaultCenter addObserver:delegate
                          selector:@selector(controlTextDidChange:)
                              name:CPControlTextDidChangeNotification
                            object:self];
}

- (BOOL)acceptsFirstResponder // public
{
  return YES;
}

- (BOOL)becomeFirstResponder // public
{
    setTimeout(function() { textarea.focus(); }, 0);
    return YES;
}

- (void)propagate // private
{
    [[[self window] platformWindow] _propagateCurrentDOMEvent:YES];
}

- (void)keyDown:(CPEvent)event // public
{
    if ([event keyCode] == CPTabKeyCode)
        [[self window] selectKeyViewFollowingView:self];
    else
        [self propagate];
}

- (void)keyUp:(CPEvent)event // public
{
    [self propagate];
    [[CPNotificationCenter defaultCenter] postNotificationName:CPControlTextDidChangeNotification object:self userInfo:nil];
}

- (void)mouseDown:(CPEvent)event // public
{
    [self propagate];
}

- (void)mouseUp:(CPEvent)event // public
{
    [self propagate];
}

- (void)mouseDragged:(CPEvent)event // public
{
    [self propagate];
}

@end
