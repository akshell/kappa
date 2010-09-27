// (c) 2010 by Anton Korenyushkin

var MAX_LABEL_WIDTH = 190;

@implementation Alert : CPObject
{
    CPString message @accessors(readonly);
    CPString comment @accessors(readonly);
    CPPanel panel;
    CPInvocation invocation;
}

+ (CPTextField)createLabelWithText:(CPString)text y:y isBold:isBold
{
    var font = isBold ? [CPFont boldSystemFontOfSize:12] : [CPFont systemFontOfSize:12];
    var size = [text sizeWithFont:font];
    if (size.width > MAX_LABEL_WIDTH)
        size = [text sizeWithFont:font inWidth:MAX_LABEL_WIDTH];
    else
        size.width += 4;
    var label = [[CPTextField alloc] initWithFrame:CGRectMake(80, y, size.width, size.height + 3)];
    [label setFont:font];
    [label setLineBreakMode:CPLineBreakByWordWrapping];
    [label setStringValue:text];
    return label;
}

- (void)createPanelWithStyleMask:(unsigned)styleMask selector:(SEL)selector
{
    var messageLabel = [Alert createLabelWithText:message y:16 isBold:YES];
    var labelMaxX = CGRectGetMaxX([messageLabel frame]);
    var commentLabel;
    if (comment) {
        commentLabel = [Alert createLabelWithText:comment y:CGRectGetMaxY([messageLabel frame]) + 8 isBold:NO];
        labelMaxX = MAX(labelMaxX, CGRectGetMaxX([commentLabel frame]));
    }
    var okButtonY = MAX(CGRectGetMaxY([commentLabel || messageLabel frame]), 64) + 8;
    var okButton = [[CPButton alloc] initWithFrame:CGRectMake(labelMaxX - 60, okButtonY, 60, 24)];
    [okButton setTitle:"OK"];
    [okButton setTarget:self];
    [okButton setAction:selector];
    [okButton setKeyEquivalent:CPCarriageReturnCharacter];
    panel = [[CPPanel alloc] initWithContentRect:CGRectMake(0, 0, labelMaxX + 16, okButtonY + 24 + 16)
                                       styleMask:styleMask];
    var contentView = [panel contentView];
    var imageView = [[CPImageView alloc] initWithFrame:CGRectMake(16, 16, 48, 48)];
    [imageView setImage:[[CPImage alloc] initWithContentsOfFile:[[CPBundle mainBundle] pathForResource:"Error.png"]]];
    [contentView addSubview:imageView];
    [contentView addSubview:messageLabel];
    if (commentLabel)
        [contentView addSubview:commentLabel];
    [contentView addSubview:okButton];
    [panel setDelegate:self];
}

- (void)initWithMessage:(CPString)aMessage comment:(CPString)aComment target:(id)target action:(SEL)action
{
    if (self = [super init]) {
        message = aMessage;
        comment = aComment;
        invocation = [CPInvocation invocationWithMethodSignature:nil];
        [invocation setTarget:target];
        [invocation setSelector:action];
        [invocation setArgument:self atIndex:2];
    }
    return self;
}

- (void)initWithMessage:(CPString)aMessage comment:(CPString)aComment
{
    [self initWithMessage:aMessage comment:aComment target:nil action:nil];
}

- (void)displayAlert
{
    [self createPanelWithStyleMask:CPTitledWindowMask selector:@selector(stopModal)];
    [CPApp runModalForWindow:panel];
}

- (void)stopModal
{
    [CPApp stopModal];
    [panel close];
}

- (void)displaySheetForWindow:(CPWindow)window
{
    [self createPanelWithStyleMask:CPDocModalWindowMask selector:@selector(endSheet)];
    [CPApp beginSheet:panel modalForWindow:window modalDelegate:nil didEndSelector:nil contextInfo:nil];
}

- (void)endSheet
{
    [CPApp endSheet:panel];
}

- (void)windowWillClose:(id)sender
{
    [invocation invoke];
}

@end
