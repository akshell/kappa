// (c) 2010-2011 by Anton Korenyushkin

@import "BaseConsoleController.j"
@import "HTTPRequest.j"

var CommandsChangingWorkTree = ['checkout', 'clean', 'merge', 'mv', 'pull', 'rebase', 'reset', 'revert', 'rm', 'stash'];

@implementation GitController : BaseConsoleController

- (id)initWithApp:(App)anApp buffer:(Buffer)aBuffer // public
{
    return [super initWithApp:anApp
                       buffer:aBuffer
                 infoBoxWidth:240
                      message:"Run Git commands."
                      comment:"Type \"help\" to get started."
             inputButtonTitle:"Run"];
}

- (void)handleInput:(CPString)input // protected
{
    var request = [[HTTPRequest alloc] initWithMethod:"POST"
                                                  URL:[app URL] + "git"
                                               target:self
                                               action:@selector(didReceiveResponse:withContext:)];
    [request setErrorAction:@selector(didReceiveError:withContext:)];
    [request setContext:{
                            questionNumber: [outputView addQuestion:input],
                            shouldReloadCode: CommandsChangingWorkTree.indexOf(input.trimLeft().split(' ', 1)[0]) != -1
                        }];
    [request send:{command: input}];
}

- (void)didReceiveResponse:(CPString)data withContext:(JSObject)context // private
{
    [outputView setAnswer:data negative:NO forQuestionNumber:context.questionNumber];
    if (context.shouldReloadCode)
        [app.navigatorController reloadCode];
}

- (BOOL)didReceiveError:(CPString)data withContext:(JSObject)context // private
{
    [outputView setAnswer:data.message + "\n\n" + data.comment negative:YES forQuestionNumber:context.questionNumber];
    return YES;
}

@end
