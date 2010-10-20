// (c) 2010 by Anton Korenyushkin

@import "PanelController.j"
@import "HTTPRequest.j"
@import "Alert.j"

@implementation RequestPanelController : PanelController
{
}

- (void)requestWithMethod:(CPString)method URL:(CPString)url data:(JSObject)data // protected
{
    var request = [[HTTPRequest alloc] initWithMethod:method URL:url target:self action:@selector(didReceiveResponse:)];
    [request setErrorMessageAction:@selector(didEndRequestErrorSheet:)];
    [request setWindow:[self window]];
    [request send:data];
}

- (void)requestWithMethod:(CPString)method URL:(CPString)url // protected
{
    [self requestWithMethod:method URL:url data:nil];
}

- (void)didEndRequestErrorSheet:(Alert)sender // protected
{
}

@end
