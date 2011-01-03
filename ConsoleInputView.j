// (c) 2010-2011 by Anton Korenyushkin

@implementation History : CPObject
{
    CPArray items;
    unsigned index;
}

- (id)init // public
{
    if (self = [super init]) {
        items = [["", ""]];
        index = 0;
    }
    return self;
}

- (void)addStringValue:(CPString)stringValue // public
{
    items[index][1] = items[index][0];
    if (items.length == 1 || items[1][1] != stringValue) {
        items[0] = [stringValue, stringValue];
        items.unshift(["", ""]);
    } else {
        items[0][1] = "";
    }
    index = 0;
}

- (CPString)stringValueWithShift:(int)shift currentStringValue:(CPString)currentStringValue // public
{
    if (!items[index + shift])
        return nil;
    items[index][1] = currentStringValue;
    index += shift;
    return items[index][1];
}

@end

@implementation ConsoleTextField : CPTextField

- (void)textDidFocus:(CPNotification)note // protected
{
    [self _inputElement].onkeydown = function (event) { [_delegate handleKeyDown:event]; };
    [super textDidFocus:note];
}

- (void)textDidBlur:(CPNotification)note // protected
{
    [self _inputElement].onkeydown = nil;
    [super textDidBlur:note];
}

@end

@implementation ConsoleInputView : CPView
{
    id target @accessors;
    SEL action @accessors;
    History history;
    ConsoleTextField textField;
}

- (id)initWithFrame:(CGRect)frame target:(id)aTarget action:(SEL)anAction buttonTitle:(CPString)buttonTitle // public
{
    if (self = [super initWithFrame:frame]) {
        target = aTarget;
        action = anAction;
        history = [History new];
        var frameWidth = CGRectGetWidth(frame);
        var buttonWidth = [buttonTitle realSizeWithFont:SystemFont].width + 18;
        textField = [[ConsoleTextField alloc] initWithFrame:CGRectMake(14, 15, frameWidth - buttonWidth - 36, 31)];
        [textField setAutoresizingMask:CPViewWidthSizable];
        [textField setDelegate:self];
        [textField setTarget:self];
        [textField setAction:@selector(submit)];
        [textField setFont:MonospaceFont];
        [textField setBordered:YES];
        [textField setBezeled:YES];
        [textField setEditable:YES];
        var button = [[CPButton alloc] initWithFrame:CGRectMake(frameWidth - buttonWidth - 18, 19, buttonWidth, 24)];
        [button setAutoresizingMask:CPViewMinXMargin];
        [button setTitle:buttonTitle];
        [button setTarget:self];
        [button setAction:@selector(submit)];
        [self addSubview:button];
        [self addSubview:textField];
    }
    return self;
}

- (void)submit // private
{
    var stringValue = [textField stringValue];
    if (stringValue.trim()) {
        objj_msgSend(target, action, stringValue);
        [history addStringValue:stringValue];
        [textField setStringValue:""];
    }
    [[self window] makeFirstResponder:textField];
}

- (void)focus // public
{
    [[self window] makeFirstResponder:textField];
}

- (void)handleKeyDown:(DOMEvent)event // private
{
    var shift;
    switch (event.keyCode) {
    case CPUpArrowKeyCode:   shift = +1; break;
    case CPDownArrowKeyCode: shift = -1; break;
    default:
        if (!event.ctrlKey)
            return;
        switch (event.keyCode) {
        case "P".charCodeAt(0): shift = +1; break;
        case "N".charCodeAt(0): shift = -1; break;
        default:                            return;
        }
    }
    event.preventDefault();
    var newStringValue = [history stringValueWithShift:shift currentStringValue:[textField stringValue]];
    if (newStringValue !== nil)
        [textField setStringValue:newStringValue];
    return YES;
}

@end
