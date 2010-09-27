// (c) 2010 by Anton Korenyushkin

@import "PanelController.j"
@import "HTTPRequest.j"
@import "Alert.j"

@implementation RequestPanelController : PanelController
{
}

- (void)requestWithMethod:(CPString)method URL:(CPString)url data:(JSObject)data
{
    [[[HTTPRequest alloc] initWithMethod:method URL:url target:self action:@selector(didReceiveResponseWithStatus:data:)]
        send:data];
}

- (void)requestWithMethod:(CPString)method URL:(CPString)url
{
    [self requestWithMethod:method URL:url data:nil];
}

- (void)didReceiveResponseWithStatus:(unsigned)status data:(JSObject)data
{
    if (status == 200 || status == 201) {
        [self didReceiveResponse:data];
        return;
    }
    var message, comment;
    if (typeof(data) == "string") {
        message = data;
    } else {
        message = data.message;
        comment = data.comment;
    }
    [[[Alert alloc] initWithMessage:message comment:comment target:self action:@selector(didEndRequestErrorSheet:)]
        displaySheetForWindow:[self window]];
}

- (void)didEndRequestErrorSheet:(Alert)sender
{
}

@end
