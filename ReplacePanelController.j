// (c) 2010-2011 by Anton Korenyushkin

@implementation ReplacePanelController : CPWindowController
{
    id target;
    SEL replaceAction;
    SEL skipAction;
    CPTextField messageLabel;
}

- (id)initWithTarget:(id)aTarget replaceAction:(SEL)aReplaceAction skipAction:(SEL)aSkipAction // public
{
    if (self = [super init]) {
        target = aTarget;
        replaceAction = aReplaceAction;
        skipAction = aSkipAction;

        [self setWindow:[[CPPanel alloc] initWithContentRect:CGRectMake(0, 0, 350, 134) styleMask:CPTitledWindowMask]];
        [[self window] setDelegate:self];
        var contentView = [[self window] contentView];
        var imageView = [[CPImageView alloc] initWithFrame:CGRectMake(16, 16, 48, 48)];
        [imageView setImage:[[CPImage alloc] initWithContentsOfFile:[[CPBundle mainBundle] pathForResource:"Caution48.png"]]];
        [contentView addSubview:imageView];
        messageLabel = [[CPTextField alloc] initWithFrame:CGRectMake(80, 16, 254, 40)];
        [messageLabel setLineBreakMode:CPLineBreakByWordWrapping];
        [messageLabel setFont:BoldSystemFont];
        [contentView addSubview:messageLabel];
        var commentLabel = [CPTextField labelWithTitle:"You cannot undo the replacement."];
        [commentLabel setFrameOrigin:CGPointMake(80, 56)];
        [contentView addSubview:commentLabel];
        var replaceButton = [[CPButton alloc] initWithFrame:CGRectMake(259, 90, 71, 24)];
        [replaceButton setTitle:"Replace"];
        [replaceButton setTarget:self];
        [replaceButton setAction:@selector(replace)];
        [replaceButton setKeyEquivalent:CPCarriageReturnCharacter];
        [contentView addSubview:replaceButton];
        var cancelButton = [[CPButton alloc] initWithFrame:CGRectMake(187, 90, 64, 24)];
        [cancelButton setTitle:"Cancel"];
        [cancelButton setTarget:self];
        [cancelButton setAction:@selector(close)];
        [contentView addSubview:cancelButton];
        var skipButton = [[CPButton alloc] initWithFrame:CGRectMake(128, 90, 51, 24)];
        [skipButton setTitle:"Skip"];
        [skipButton setTarget:self];
        [skipButton setAction:@selector(skip)];
        [contentView addSubview:skipButton];
    }
    return self;
}

- (void)showWindowWithDescription:(CPString)description // public
{
    [messageLabel setStringValue:"The " + description + " already exists in this location. Do you want to replace it?"];
    [CPApp runModalForWindow:[self window]];
}

- (void)replace // private
{
    [self close];
    objj_msgSend(target, replaceAction);
}

- (void)skip // private
{
    [self close];
    objj_msgSend(target, skipAction);
}

- (void)windowWillClose:(id)sender // private
{
    [CPApp stopModal];
}

@end
