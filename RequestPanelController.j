// (c) 2010 by Anton Korenyushkin

@import "PanelController.j"
@import "HTTPRequest.j"
@import "Alert.j"

@implementation RequestPanelController : PanelController
{
}

- (void)requestWithMethod:(CPString)method URL:(CPString)url data:(JSObject)data
{
    var request = [[HTTPRequest alloc] initWithMethod:method
                                                  URL:url
                                               target:self
                                        successAction:@selector(didReceiveResponse:)
                                          errorAction:@selector(didEndRequestErrorSheet:)];
    [request setWindow:[self window]];
    [request send:data];
}

- (void)requestWithMethod:(CPString)method URL:(CPString)url
{
    [self requestWithMethod:method URL:url data:nil];
}

- (void)didEndRequestErrorSheet:(Alert)sender
{
}

@end
