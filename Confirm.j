// (c) 2010 by Anton Korenyushkin

@implementation Confirm : Alert
{
    BOOL shouldSendAction @accessors(readonly);
}

- (CPString)imagePath
{
    return "Caution.png";
}

- (void)createPanelWithStyleMask:(unsigned)styleMask
{
    [super createPanelWithStyleMask:styleMask];
    var contentView = [panel contentView];
    var cancelButton = [[CPButton alloc] initWithFrame:CGRectMake(138, [contentView boundsSize].height - 16 - 24, 64, 24)];
    [cancelButton setTitle:"Cancel"];
    [cancelButton setTarget:panel];
    [cancelButton setAction:@selector(dismiss)];
    [contentView addSubview:cancelButton];
}

- (void)confirm
{
    shouldSendAction = YES;
    [super confirm];
}

@end
