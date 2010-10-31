// (c) 2010 by Anton Korenyushkin

var createLabel = function (text, y, isBold) {
    var font = isBold ? [CPFont boldSystemFontOfSize:12] : [CPFont systemFontOfSize:12];
    var label = [[CPTextField alloc] initWithFrame:CGRectMake(80, y, 190, [text sizeWithFont:font inWidth:188].height + 4)];
    [label setFont:font];
    [label setLineBreakMode:CPLineBreakByWordWrapping];
    [label setStringValue:text];
    return label;
};

@implementation Alert : CPObject
{
    CPString message @accessors;
    CPString comment @accessors;
    id target @accessors;
    SEL action @accessors;
    CPPanel panel;
}

- (void)initWithMessage:(CPString)aMessage comment:(CPString)aComment target:(id)aTarget action:(SEL)anAction // public
{
    if (self = [super init]) {
        message = aMessage;
        comment = aComment;
        target = aTarget;
        action = anAction;
    }
    return self;
}

- (id)initWithMessage:(CPString)aMessage comment:(CPString)aComment // public
{
    return [self initWithMessage:aMessage comment:aComment target:nil action:nil];
}

- (id)initWithMessage:(CPString)aMessage // public
{
    return [self initWithMessage:aMessage comment:nil target:nil action:nil];
}

- (void)showPanel // public
{
    [self createPanelWithStyleMask:CPTitledWindowMask];
    [CPApp runModalForWindow:panel];
}

- (void)showSheetForWindow:(CPWindow)window // public
{
    [self createPanelWithStyleMask:CPDocModalWindowMask];
    [CPApp beginSheet:panel modalForWindow:window modalDelegate:nil didEndSelector:nil contextInfo:nil];
}

- (void)createPanelWithStyleMask:(unsigned)styleMask // protected
{
    var messageLabel = createLabel(message, 16, YES);
    var commentLabel;
    if (comment)
        commentLabel = createLabel(comment, CGRectGetMaxY([messageLabel frame]) + 8, NO);
    var okButtonY = MAX(CGRectGetMaxY([commentLabel || messageLabel frame]), 64) + 16;
    var okButton = [[CPButton alloc] initWithFrame:CGRectMake(206, okButtonY, 60, 24)];
    [okButton setTitle:"OK"];
    [okButton setTarget:self];
    [okButton setAction:@selector(confirm)];
    [okButton setKeyEquivalent:CPCarriageReturnCharacter];
    panel = [[CPPanel alloc] initWithContentRect:CGRectMake(0, 0, 286, okButtonY + 24 + 20) styleMask:styleMask];
    var contentView = [panel contentView];
    var imageView = [[CPImageView alloc] initWithFrame:CGRectMake(16, 16, 48, 48)];
    [imageView setImage:[[CPImage alloc] initWithContentsOfFile:[[CPBundle mainBundle] pathForResource:[self imagePath]]]];
    [contentView addSubview:imageView];
    [contentView addSubview:messageLabel];
    if (commentLabel)
        [contentView addSubview:commentLabel];
    [contentView addSubview:okButton];
    [panel setDelegate:self];
}

- (CPString)imagePath // protected
{
    return "Error48.png";
}

- (void)confirm // protected
{
    [panel dismiss];
}

- (void)windowWillClose:(id)sender // private
{
    if (![panel isSheet])
        [CPApp stopModal];
    if ([self shouldSendAction])
        objj_msgSend(target, action, self);
}

- (BOOL)shouldSendAction // protected
{
    return YES;
}

@end
