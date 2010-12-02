// (c) 2010 by Anton Korenyushkin

@import "BasePresentationController.j"
@import "ConsoleInputView.j"
@import "ConsoleOutputView.j"

@implementation BaseConsoleController : BasePresentationController
{
    CPBox infoBox;
    ConsoleOutputView outputView;
    ConsoleInputView inputView;
}

- (id)initWithApp:(App)anApp
           buffer:(Buffer)aBuffer
     infoBoxWidth:(unsigned)infoBoxWidth
          message:(CPString)message
          comment:(CPString)comment
 inputButtonTitle:(CPString)inputButtonTitle // public
{
    if (self = [super initWithApp:anApp buffer:aBuffer]) {
        var labelWidth = infoBoxWidth - 96;
        var messageSize = [message realSizeWithFont:BoldSystemFont inWidth:labelWidth];
        var commentSize = [comment realSizeWithFont:SystemFont inWidth:labelWidth];
        var infoBoxHeight = MAX(80, messageSize.height + commentSize.height + 40);
        infoBox = [[CPBox alloc] initWithFrame:CGRectMake(infoBoxWidth / -2, (infoBoxHeight + 61) / -2,
                                                          infoBoxWidth, infoBoxHeight)];
        [infoBox setAutoresizingMask:CPViewMinXMargin | CPViewMaxXMargin | CPViewMinYMargin | CPViewMaxYMargin];
        [infoBox setBackgroundColor:[CPColor colorWithHexString:"f4f4f4"]];
        var imageView = [[CPImageView alloc] initWithFrame:CGRectMake(16, 16, 48, 48)];
        [imageView setImage:[CPImage imageFromPath:"Info48.png"]];
        [infoBox addSubview:imageView];
        var messageLabel = [[CPTextField alloc] initWithFrame:CGRectMake(80, 16, messageSize.width, messageSize.height)];
        [messageLabel setStringValue:message];
        [messageLabel setFont:BoldSystemFont];
        [messageLabel setLineBreakMode:CPLineBreakByWordWrapping];
        [infoBox addSubview:messageLabel];
        var commentLabel = [[CPTextField alloc] initWithFrame:CGRectMake(80, messageSize.height + 24,
                                                                         commentSize.width, commentSize.height)];
        [commentLabel setStringValue:comment];
        [commentLabel setLineBreakMode:CPLineBreakByWordWrapping];
        [infoBox addSubview:commentLabel];
        [view addSubview:infoBox];

        outputView = [[ConsoleOutputView alloc] initWithFrame:CGRectMake(0, 0, 0, -61)];
        [outputView setAutoresizingMask:CPViewWidthSizable | CPViewHeightSizable];
        [view addSubview:outputView];

        inputView = [[ConsoleInputView alloc] initWithFrame:CGRectMake(0, -61, 0, 61)
                                                     target:self
                                                     action:@selector(removeInfoBoxAndHandleInput:)
                                                buttonTitle:inputButtonTitle];
        [inputView setBackgroundColor:[CPColor colorWithPatternImage:[CPImage imageFromPath:"ConsoleInputViewBackground.png"]]];
        [inputView setAutoresizingMask:CPViewWidthSizable | CPViewMinYMargin];
        [view addSubview:inputView];
    }
    return self;
}

- (void)removeInfoBoxAndHandleInput:(CPString)input // private
{
    [infoBox removeFromSuperview];
    [inputView setAction:@selector(handleInput:)];
    [self handleInput:input];
}

- (void)focus // public
{
    [inputView focus];
}

@end
