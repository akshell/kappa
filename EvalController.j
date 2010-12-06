// (c) 2010 by Anton Korenyushkin

@import "BaseConsoleController.j"
@import "HTTPRequest.j"

@implementation EvalController : BaseConsoleController

- (id)initWithApp:(App)anApp buffer:(Buffer)aBuffer // public
{
    return [super initWithApp:anApp
                       buffer:aBuffer
                 infoBoxWidth:400
                      message:"Evaluate JavaScript expressions in the \"" + aBuffer.env.name + "\" environment."
                      comment:("Your app has a number of isolated environments. The \"release\" "+
                               "environment operates on the \"master\" branch of the app's repository; " +
                               "it's intended for serving your users. Other environments operate on " +
                               "the working tree; they're intended for testing and debugging. Click on " +
                               "an environment item in the navigator to open its evaluator. Alt-click " +
                               "on it to open its preview tab.")
             inputButtonTitle:"Evaluate"];
}

- (void)handleInput:(CPString)input // protected
{
    var request = [[HTTPRequest alloc] initWithMethod:"POST"
                                                  URL:[app URL] + "envs/" + buffer.env.name
                                               target:self
                                               action:@selector(didReceiveResponse:forQuestionNumber:)];
    [request setContext:[outputView addQuestion:input]];
    [request send:{action: "eval", expr: input}];
}

- (void)didReceiveResponse:(JSObject)data forQuestionNumber:(unsigned)questionNumber // private
{
    [outputView setAnswer:data.result negative:!data.ok forQuestionNumber:questionNumber];
}

@end
