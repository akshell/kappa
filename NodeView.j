// (c) 2010 by Anton Korenyushkin

@import "NodeItems.j"

var makeImage = function (path) {
    return [[CPImage alloc] initWithContentsOfFile:[[CPBundle mainBundle] pathForResource:path]];
};

@implementation NodeView : CPView
{
    BOOL isSpinner;
}

- (id)init
{
    if (self = [super init]) {
        [self addSubview:[[CPImageView alloc] initWithFrame:CGRectMake(2, 3, 16, 16)]];
        [self addSubview:[[CPTextField alloc] initWithFrame:CGRectMake(20, 3, 10000, 18)]];
    }
    return self
}

- (void)setObjectValue:(NodeItem)item
{
    if (!item)
        return;
    isSpinner = [item imageName] == "Spinner";
    var path = isSpinner ? "WhiteSpinner.gif" : [item imageName] + ".png";
    [[self subviews][0] setImage:makeImage(path)];
    if (![item isEditable]) {
        [[self subviews][1] setStringValue:[item name]];
        return;
    }
    // FIXME: There should be a better way of displaying fields in small space
    var textField = [[CPTextField alloc] initWithFrame:CGRectMake(20, -3, MAX(20, [self boundsSize].width - 20), 28)];
    [textField setDelegate:item];
    [textField setTarget:item];
    [textField setAction:@selector(submit:)];
    [textField setBordered:YES];
    [textField setBezeled:YES];
    [textField setEditable:YES];
    [textField setStringValue:[item name]];
    [self addSubview:textField];
    [textField selectAll:nil];
    [[textField window] makeFirstResponder:textField];
}

- (BOOL)setThemeState:(CPThemeState)state
{
    if (state == CPThemeStateSelectedDataView && isSpinner)
        [[self subviews][0] setImage:makeImage("BlueSpinner.gif")];
    return [super setThemeState:state];
}

- (BOOL)unsetThemeState:(CPThemeState)state
{
    if (state == CPThemeStateSelectedDataView && isSpinner)
        [[self subviews][0] setImage:makeImage("WhiteSpinner.gif")];
    return [super unsetThemeState:state];
}

@end