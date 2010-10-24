// (c) 2010 by Anton Korenyushkin

@implementation ItemController : CPObject
{
    id item;
}

- (id)initWithItem:(id)anItem // public
{
    if (self = [super init])
        item = anItem;
    return self;
}

- (void)controlTextDidBlur:(CPNotification)notification // private
{
    [self submit:[notification object]];
}

- (void)submit:(CPTextField)sender // public
{
    if (!item.textField)
        return;
    delete item.textField;
    [sender removeFromSuperview];
    [item.manager submitItem:item withName:[sender stringValue]];
}

@end

var makeImage = function (path) {
    return [[CPImage alloc] initWithContentsOfFile:[[CPBundle mainBundle] pathForResource:path]];
};

@implementation ItemView : CPView
{
    BOOL isLoading;
}

- (id)init // public
{
    if (self = [super init]) {
        [self addSubview:[[CPImageView alloc] initWithFrame:CGRectMake(2, 3, 16, 16)]];
        [self addSubview:[[CPTextField alloc] initWithFrame:CGRectMake(20, 3, 10000, 18)]];
    }
    return self
}

- (void)setObjectValue:(id)item // public
{
    if (!item)
        return;
    isLoading = item.isLoading;
    [[self subviews][0] setImage:makeImage(isLoading ? "WhiteSpinner.gif" : [[item class] imageName] + ".png")];
    if (!item.isEditable) {
        [[self subviews][1] setStringValue:[item name]];
        return;
    }
    // FIXME: There should be a better way of displaying fields in small space
    var origin = [self frameOrigin];
    var textFieldFrame = CGRectMake(origin.x + 20, origin.y - 3, MAX(20, [self boundsSize].width - 20), 28);
    if (item.textField) {
        [item.textField setFrame:textFieldFrame];
        return;
    }
    var textField = item.textField = [[CPTextField alloc] initWithFrame:textFieldFrame];
    var itemController = [[ItemController alloc] initWithItem:item];
    [textField setDelegate:itemController];
    [textField setTarget:itemController];
    [textField setAction:@selector(submit:)];
    [textField setBordered:YES];
    [textField setBezeled:YES];
    [textField setEditable:YES];
    [textField setStringValue:[item name]];
    [[self superview] addSubview:textField];
    [textField selectAll:nil];
    [[textField window] makeFirstResponder:textField];
}

- (BOOL)setThemeState:(CPThemeState)state // protected
{
    if (state == CPThemeStateSelectedDataView && isLoading)
        [[self subviews][0] setImage:makeImage("BlueSpinner.gif")];
    return [super setThemeState:state];
}

- (BOOL)unsetThemeState:(CPThemeState)state // protected
{
    if (state == CPThemeStateSelectedDataView && isLoading)
        [[self subviews][0] setImage:makeImage("WhiteSpinner.gif")];
    return [super unsetThemeState:state];
}

@end
