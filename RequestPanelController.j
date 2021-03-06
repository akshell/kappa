// (c) 2010-2011 by Anton Korenyushkin

@import "PanelController.j"
@import "HTTPRequest.j"
@import "Alert.j"

@implementation RequestPanelController : PanelController
{
    BOOL isProcessing;
    CPString panelTitle;
}

- (void)requestWithMethod:(CPString)method
                      URL:(CPString)url
                     data:(JSObject)data
                  context:(JSObject)context
                 selector:(SEL)selector // private
{
    if (isProcessing)
        return;
    isProcessing = YES;
    panelTitle = [[self window] title];
    [[self window] setTitle:"Processing..."];
    var request = [[HTTPRequest alloc] initWithMethod:method URL:url target:self action:selector];
    [request setFinishAction:@selector(didRequestFinished)];
    [request setErrorMessageAction:@selector(didEndRequestErrorSheet:)];
    [request setWindow:[self window]];
    [request setContext:context];
    [request send:data];
}

- (void)requestWithMethod:(CPString)method URL:(CPString)url data:(JSObject)data context:(JSObject)context // protected
{
    [self requestWithMethod:method URL:url data:data context:context selector:@selector(didReceiveResponse:withContext:)];
}

- (void)requestWithMethod:(CPString)method URL:(CPString)url data:(JSObject)data // protected
{
    [self requestWithMethod:method URL:url data:data context:nil selector:@selector(didReceiveResponse:)];
}

- (void)requestWithMethod:(CPString)method URL:(CPString)url // protected
{
    [self requestWithMethod:method URL:url data:nil];
}

- (void)didRequestFinished // protected
{
    isProcessing = NO;
    [[self window] setTitle:panelTitle];
}

- (void)didEndRequestErrorSheet:(Alert)sender // protected
{
    [self showWindow:nil];
}

@end
