// (c) 2010 by Anton Korenyushkin

@import "SmartScrollView.j"

@implementation QAView : CPView
{
    CPImageView spinnerImageView;
}

- (id)initWithOrigin:(CGPoint)origin question:(CPString)question // public
{
    var questionSize = [question realSizeWithFont:MonospaceFont];
    if (self = [super initWithFrame:CGRectMake(origin.x, origin.y, questionSize.width + 40, questionSize.height + 40)]) {
        var questionLabel = [[CPTextField alloc] initWithFrame:CGRectMake(20, 0, questionSize.width, questionSize.height)];
        [questionLabel setStringValue:question];
        [questionLabel setFont:MonospaceFont];
        [questionLabel setTextColor:[CPColor blueColor]];
        [questionLabel setSelectable:YES];
        [self addSubview:questionLabel];
        spinnerImageView = [[CPImageView alloc] initWithFrame:CGRectMake(23, questionSize.height + 2, 16, 16)];
        [spinnerImageView setImage:[CPImage imageFromPath:"WhiteSpinner16.gif"]];
        [self addSubview:spinnerImageView];
    }
    return self;
}

- (void)setAnswer:(CPString)answer isPositive:(BOOL)isPositive // public
{
    [spinnerImageView removeFromSuperview];
    var answerSize = [answer realSizeWithFont:MonospaceFont];
    var frameSize = [self frameSize];
    var answerLabel = [[CPTextField alloc] initWithFrame:CGRectMake(20, frameSize.height - 40,
                                                                    answerSize.width, answerSize.height)];
    [answerLabel setStringValue:answer];
    [answerLabel setFont:MonospaceFont];
    if (!isPositive)
        [answerLabel setTextColor:[CPColor redColor]];
    [answerLabel setSelectable:YES];
    [self addSubview:answerLabel];
    [self setFrameSize:CGSizeMake(MAX(frameSize.width, answerSize.width + 40), frameSize.height + answerSize.height - 20)];
}

@end

@implementation ConsoleOutputView : SmartScrollView
{
    CPView talkView;
}

- (void)initWithFrame:(CGRect)frame // public
{
    if (self = [super initWithFrame:frame]) {
        [self setAutohidesScrollers:YES];
        var documentView = [[CPView alloc] initWithFrame:[self bounds]];
        talkView = [[CPView alloc] initWithFrame:CGRectMake(0, 0, 0, 20)];
        [documentView addSubview:talkView];
        [self setDocumentView:talkView];
    }
    return self;
}

- (void)setTalkViewSize:(CGSize)size // private
{
    [self setBaseSize:size];
    [talkView setFrame:CGRectMake(0, [[self documentView] boundsSize].height - size.height, size.width, size.height)];
}

- (unsigned)addQuestion:(CPString)question // public
{
    var talkViewSize = [talkView frameSize];
    var qaView = [[QAView alloc] initWithOrigin:CGPointMake(0, talkViewSize.height) question:question];
    var qaViewSize = [qaView frameSize];
    [self setTalkViewSize:CGSizeMake(MAX(talkViewSize.width, qaViewSize.width), talkViewSize.height + qaViewSize.height)];
    [talkView addSubview:qaView];
    [talkView scrollRectToVisible:[qaView frame]];
    return [talkView subviews].length - 1;
}

- (void)setAnswer:(CPString)answer isPositive:(BOOL)isPositive forQuestionNumber:(unsigned)questionNumber // public
{
    var qaViews = [talkView subviews];
    var qaView = qaViews[questionNumber];
    var oldQAViewSize = [qaView frameSize];
    [qaView setAnswer:answer isPositive:isPositive];
    var newQAViewSize = [qaView frameSize];
    var heightShift = newQAViewSize.height - oldQAViewSize.height;
    var talkViewSize = [talkView frameSize];
    [self setTalkViewSize:CGSizeMake(MAX(talkViewSize.width, newQAViewSize.width), talkViewSize.height + heightShift)];
    if (heightShift) {
        for (var i = questionNumber + 1; i < qaViews.length; ++i)
            [qaViews[i] setFrameOrigin:CGPointMake(0, [qaViews[i] frameOrigin].y + heightShift)];
        [self moveByOffset:CGSizeMake(0, heightShift)];
    }
    [[CPRunLoop currentRunLoop] limitDateForMode:CPDefaultRunLoopMode];
}

@end
