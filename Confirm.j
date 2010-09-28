// (c) 2010 by Anton Korenyushkin

@implementation Confirm : Alert
{
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
    [cancelButton setTarget:self];
    [cancelButton setAction:@selector(cancel)];
    [contentView addSubview:cancelButton];
}

- (void)cancel
{
    invocation = nil;
    [self close];
}

@end
