// (c) 2010 by Anton Korenyushkin

@implementation SavePanelController : CPWindowController
{
    id target;
    SEL saveAction;
    SEL dontSaveAction;
    CPTextField messageLabel;
}

- (id)initWithTarget:(id)aTarget saveAction:(SEL)aSaveAction dontSaveAction:(SEL)aDontSaveAction // public
{
    if (self = [super init]) {
        target = aTarget;
        saveAction = aSaveAction;
        dontSaveAction = aDontSaveAction;

        [self setWindow:[[CPPanel alloc] initWithContentRect:CGRectMake(0, 0, 362, 134) styleMask:CPTitledWindowMask]];
        [[self window] setDelegate:self];
        var contentView = [[self window] contentView];
        var imageView = [[CPImageView alloc] initWithFrame:CGRectMake(16, 16, 48, 48)];
        [imageView setImage:[[CPImage alloc] initWithContentsOfFile:[[CPBundle mainBundle] pathForResource:"Caution48.png"]]];
        [contentView addSubview:imageView];
        messageLabel = [[CPTextField alloc] initWithFrame:CGRectMake(80, 16, 254, 40)];
        [messageLabel setLineBreakMode:CPLineBreakByWordWrapping];
        [messageLabel setFont:[CPFont boldSystemFontOfSize:12]];
        [contentView addSubview:messageLabel];
        var commentLabel = [CPTextField labelWithTitle:"Your changes will be lost if you don't save them."];
        [commentLabel setFrameOrigin:CGPointMake(80, 56)];
        [contentView addSubview:commentLabel];
        var saveButton = [[CPButton alloc] initWithFrame:CGRectMake(286, 90, 56, 24)];
        [saveButton setTitle:"Save"];
        [saveButton setTarget:self];
        [saveButton setAction:@selector(save)];
        [saveButton setKeyEquivalent:CPCarriageReturnCharacter];
        [contentView addSubview:saveButton];
        var cancelButton = [[CPButton alloc] initWithFrame:CGRectMake(214, 90, 64, 24)];
        [cancelButton setTitle:"Cancel"];
        [cancelButton setTarget:self];
        [cancelButton setAction:@selector(close)];
        [contentView addSubview:cancelButton];
        var dontSaveButton = [[CPButton alloc] initWithFrame:CGRectMake(120, 90, 86, 24)];
        [dontSaveButton setTitle:"Don't Save"];
        [dontSaveButton setTarget:self];
        [dontSaveButton setAction:@selector(dontSave)];
        [contentView addSubview:dontSaveButton];
    }
    return self;
}

- (void)showWindowWithFileName:(CPString)fileName // public
{
    [messageLabel setStringValue:"Do you want to save the changes you made to the file \"" + fileName + "\"?"];
    [CPApp runModalForWindow:[self window]];
}

- (void)save // private
{
    [self close];
    objj_msgSend(target, saveAction);
}

- (void)dontSave // private
{
    [self close];
    objj_msgSend(target, dontSaveAction);
}

- (void)windowWillClose:(id)sender // private
{
    [CPApp stopModal];
}

@end
