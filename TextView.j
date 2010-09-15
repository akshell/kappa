// (c) 2010 by Anton Korenyushkin


@implementation TextView : CPControl
{
    DOMElement textarea;
}

- (id)initWithFrame:(CGRect)aFrame
{
    if (self = [super initWithFrame: aFrame]) {
        textarea = document.createElement('textarea');
        textarea.readOnly = true;
        textarea.style.width = (CGRectGetWidth(aFrame) - 6) + 'px';
        textarea.style.height = (CGRectGetHeight(aFrame) - 6) + 'px';
        textarea.style.overflow = document.selection ? 'auto' : 'hidden';
        textarea.style.position = 'absolute';
        textarea.style.left = '0';
        textarea.style.top = '0';
        textarea.style.margin = '0';
        textarea.style.padding = '2px';
        textarea.style.border = '1px solid 7D7D7D';
        textarea.style.fontSize = '14px';
        textarea.style.fontFamily = 'Monospace';
        textarea.style.resize = 'none';
        _DOMElement.appendChild(textarea);
    }
    return self;
}

- (void)setStringValue:(CPString)aValue
{
    textarea.value = aValue;
}

- (void)mouseDown:(CPEvent)anEvent
{
    setTimeout(function() { textarea.select(); }, 0);
}

@end
