// (c) 2010 by Anton Korenyushkin

@implementation NavigatorItemController : CPObject
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

@implementation NavigatorItemView : CPView
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

- (CPTextField)textField // private
{
    return [self subviews][1];
}

- (void)setObjectValue:(id)item // public
{
    if (!item)
        return;
    isLoading = item.isLoading;
    [[self subviews][0] setImage:[CPImage imageFromPath:isLoading ? "WhiteSpinner16.gif" : [item imageName] + "16.png"]];
    if (!item.isEditable) {
        [[self textField] setStringValue:[item name]];
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
    var controller = [[NavigatorItemController alloc] initWithItem:item];
    [textField setDelegate:controller];
    [textField setTarget:controller];
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
    if (state == CPThemeStateSelectedDataView) {
        [[self textField] setTextColor:[CPColor whiteColor]];
        if (isLoading)
            [[self subviews][0] setImage:[CPImage imageFromPath:"BlueSpinner16.gif"]];
    }
    return [super setThemeState:state];
}

- (BOOL)unsetThemeState:(CPThemeState)state // protected
{
    if (state == CPThemeStateSelectedDataView) {
        [[self textField] setTextColor:[CPColor blackColor]];
        if (isLoading)
            [[self subviews][0] setImage:[CPImage imageFromPath:"WhiteSpinner16.gif"]];
    }
    return [super unsetThemeState:state];
}

@end
