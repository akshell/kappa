// (c) 2010 by Anton Korenyushkin

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
    var size = [text sizeWithFont:font inWidth:190];
    var label = [[CPTextField alloc] initWithFrame:CGRectMake(80, y, size.width, size.height + 4)];
    [label setFont:font];
    [label setLineBreakMode:CPLineBreakByWordWrapping];
    [label setStringValue:text];
    return label;
}

- (CPString)imagePath
{
    return "Error.png";
}

- (void)createPanelWithStyleMask:(unsigned)styleMask
{
    var messageLabel = [Alert createLabelWithText:message y:16 isBold:YES];
    var commentLabel;
    if (comment)
        commentLabel = [Alert createLabelWithText:comment y:CGRectGetMaxY([messageLabel frame]) + 8 isBold:NO];
    var okButtonY = MAX(CGRectGetMaxY([commentLabel || messageLabel frame]), 64) + 16;
    var okButton = [[CPButton alloc] initWithFrame:CGRectMake(210, okButtonY, 60, 24)];
    [okButton setTitle:"OK"];
    [okButton setTarget:self];
    [okButton setAction:@selector(close)];
    [okButton setKeyEquivalent:CPCarriageReturnCharacter];
    panel = [[CPPanel alloc] initWithContentRect:CGRectMake(0, 0, 286, okButtonY + 24 + 16) styleMask:styleMask];
    var contentView = [panel contentView];
    console.log([contentView boundsSize]);
    var imageView = [[CPImageView alloc] initWithFrame:CGRectMake(16, 16, 48, 48)];
    [imageView setImage:[[CPImage alloc] initWithContentsOfFile:[[CPBundle mainBundle] pathForResource:[self imagePath]]]];
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

- (id)initWithMessage:(CPString)aMessage comment:(CPString)aComment
{
    return [self initWithMessage:aMessage comment:aComment target:nil action:nil];
}

- (void)showPanel
{
    [self createPanelWithStyleMask:CPTitledWindowMask];
    [CPApp runModalForWindow:panel];
}

- (void)showSheetForWindow:(CPWindow)window
{
    [self createPanelWithStyleMask:CPDocModalWindowMask];
    [CPApp beginSheet:panel modalForWindow:window modalDelegate:self didEndSelector:@selector(didEndSheet) contextInfo:nil];
}

- (void)close
{
    if ([panel isSheet]) {
        [CPApp endSheet:panel];
    } else {
        [CPApp stopModal];
        [panel close];
        [invocation invoke];
    }
}

- (void)didEndSheet
{
    [invocation invoke];
}

@end
