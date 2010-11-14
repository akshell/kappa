// (c) 2010 by Anton Korenyushkin

@implementation FileBuffer (WorkspaceItemView)

- (CPString)imageName // public
{
    return "File";
}

@end

@implementation GitBuffer (WorkspaceItemView)

- (CPString)imageName // public
{
    return "Git";
}

@end

@implementation EvalBuffer (WorkspaceItemView)

- (CPString)imageName // public
{
    return "Eval";
}

@end

@implementation HelpBuffer (WorkspaceItemView)

- (CPString)imageName // public
{
    return "Help";
}

@end

@implementation PreviewBuffer (WorkspaceItemView)

- (CPString)imageName // public
{
    return "Preview";
}

@end

@implementation CloseButton : CPControl
{
    BOOL isModified;
    BOOL isActive;
    BOOL isSelected;
    BOOL isHighlighted;
}

- (void)setModified:(BOOL)flag // public
{
    isModified = flag;
    [self setNeedsDisplay:YES];
}

- (void)setActive:(BOOL)flag // public
{
    isActive = flag;
    [self setNeedsDisplay:YES];
}

- (void)setSelected:(BOOL)flag // public
{
    isSelected = flag;
    [self setNeedsDisplay:YES];
}

- (void)setHighlighted:(BOOL)flag // private
{
    isHighlighted = flag;
    [self setNeedsDisplay:YES];
}

- (void)mouseEntered:(CPEvent)event // protected
{
    [self setHighlighted:YES];
    [super mouseEntered:event];
}

- (void)mouseExited:(CPEvent)event // protected
{
    [self setHighlighted:NO];
    [super mouseExited:event];
}

- (void)drawEllipseInRect:(CGRect)rect // private
{
    var context = [[CPGraphicsContext currentContext] graphicsPort];
    CGContextBeginPath(context);
    CGContextAddEllipseInRect(context, rect);
    CGContextClosePath(context);
    CGContextSetFillColor(context, isSelected ? [CPColor whiteColor] : [CPColor grayColor]);
    CGContextFillPath(context);
}

- (void)drawRect:(CGRect)rect // public
{
    if (!isActive) {
        if (isModified)
            [self drawEllipseInRect:CGRectMake(5, 5, 6, 6)];
        return;
    }
    if (isHighlighted)
        [self drawEllipseInRect:CGRectMake(1, 1, 14, 14)];
    var context = [[CPGraphicsContext currentContext] graphicsPort];
    CGContextBeginPath(context);
    CGContextMoveToPoint(context, 5, 4);
    [[8, 7], [11, 4], [12, 5], [9, 8], [12, 11], [11, 12], [8, 9], [5, 12], [4, 11], [7, 8], [4, 5], [5, 4]].forEach(
        function (pair) { CGContextAddLineToPoint(context, pair[0], pair[1]); });
    CGContextClosePath(context);
    CGContextSetFillColor(context, !isSelected == !isHighlighted ? [CPColor grayColor] : [CPColor whiteColor]);
    CGContextFillPath(context);
}

@end

@implementation WorkspaceItemView : CPView

- (id)init // public
{
    if (self = [super init]) {
        var backView = [CPView new];
        [backView setAutoresizingMask:CPViewWidthSizable | CPViewHeightSizable];
        [self addSubview:backView];
        var closeButton = [[CloseButton alloc] initWithFrame:CGRectMake(2, 3, 16, 16)];
        [closeButton setAction:@selector(close)];
        [self addSubview:closeButton];
        [self addSubview:[[CPImageView alloc] initWithFrame:CGRectMake(18, 3, 16, 16)]];
        [self addSubview:[[CPTextField alloc] initWithFrame:CGRectMake(36, 3, 10000, 18)]];
    }
    return self;
}

- (CloseButton)closeButton // private
{
    return [self subviews][1];
}

- (void)setObjectValue:(Buffer)buffer // public
{
    [[self closeButton] setTarget:buffer];
    [[self subviews][2] setImage:[CPImage imageFromPath:[buffer imageName] + "16.png"]];
    [[self subviews][3] setStringValue:[buffer name]];
    [buffer addObserver:self forKeyPath:"isModified" options:CPKeyValueObservingOptionInitial];
}

- (void)observeValueForKeyPath:(CPString)keyPath ofObject:(id)object change:(CPDictionary)change context:(id)context // private
{
    [[self closeButton] setModified:object.isModified];
    [[CPRunLoop currentRunLoop] limitDateForMode:CPDefaultRunLoopMode];
}

- (BOOL)setThemeState:(CPThemeState)state // protected
{
    if (state == CPThemeStateSelectedDataView)
        [[self closeButton] setSelected:YES];
    return [super setThemeState:state];
}

- (BOOL)unsetThemeState:(CPThemeState)state // protected
{
    if (state == CPThemeStateSelectedDataView)
        [[self closeButton] setSelected:NO];
    return [super unsetThemeState:state];
}

- (void)mouseEntered:(CPEvent)event // protected
{
    [[self closeButton] setActive:YES];
    [super mouseEntered:event];
}

- (void)mouseExited:(CPEvent)event // protected
{
    [[self closeButton] setActive:NO];
    [super mouseExited:event];
}

@end
