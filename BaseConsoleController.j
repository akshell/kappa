// (c) 2010-2011 by Anton Korenyushkin

@import "BasePresentationController.j"
@import "InfoView.j"
@import "ConsoleInputView.j"
@import "ConsoleOutputView.j"

@implementation BaseConsoleController : BasePresentationController
{
    CPView view @accessors(readonly);
    InfoView infoView;
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
        view = [CPView new];
        var topFrame = CGRectMake(0, 0, 0, -61);
        infoView = [[InfoView alloc] initWithFrame:topFrame boxWidth:infoBoxWidth message:message comment:comment];
        [infoView setAutoresizingMask:CPViewWidthSizable | CPViewHeightSizable];
        [view addSubview:infoView];
        outputView = [[ConsoleOutputView alloc] initWithFrame:topFrame];
        [outputView setAutoresizingMask:CPViewWidthSizable | CPViewHeightSizable];
        [view addSubview:outputView];
        inputView = [[ConsoleInputView alloc] initWithFrame:CGRectMake(0, -61, 0, 61)
                                                     target:self
                                                     action:@selector(removeInfoViewAndHandleInput:)
                                                buttonTitle:inputButtonTitle];
        [inputView setBackgroundColor:[CPColor colorWithPatternImage:[CPImage imageFromPath:"ConsoleInputViewBackground.png"]]];
        [inputView setAutoresizingMask:CPViewWidthSizable | CPViewMinYMargin];
        [view addSubview:inputView];
    }
    return self;
}

- (void)removeInfoViewAndHandleInput:(CPString)input // private
{
    [infoView removeFromSuperview];
    [inputView setAction:@selector(handleInput:)];
    [self handleInput:input];
}

- (void)focus // public
{
    [inputView focus];
}

@end
