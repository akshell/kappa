// (c) 2010 by Anton Korenyushkin

@import "Alert.j"

@implementation Confirm : Alert
{
    BOOL shouldSendAction @accessors(readonly);
}

- (void)createPanelWithStyleMask:(unsigned)styleMask // protected
{
    [super createPanelWithStyleMask:styleMask];
    var contentView = [panel contentView];
    var cancelButton = [[CPButton alloc] initWithFrame:CGRectMake(134, [contentView boundsSize].height - 20 - 24, 64, 24)];
    [cancelButton setTitle:"Cancel"];
    [cancelButton setTarget:panel];
    [cancelButton setAction:@selector(dismiss)];
    [contentView addSubview:cancelButton];
}

- (CPString)imagePath // protected
{
    return "Caution48.png";
}

- (void)confirm // protected
{
    shouldSendAction = YES;
    [super confirm];
}

@end
