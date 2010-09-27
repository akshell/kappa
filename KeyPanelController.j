// (c) 2010 by Anton Korenyushkin

@import "TextView.j"
@import "RequestPanelController.j"

@implementation KeyPanelController : RequestPanelController
{
    @outlet TextView textView;
    CPString keyValue;
}

- (id)init
{
    return [super initWithWindowCibName:"KeyPanel"];
}

- (void)showWindow:(id)sender
{
    [super showWindow:sender];
    if (keyValue) {
        [textView setStringValue:keyValue];
    } else {
        [textView setStringValue:""];
        [self requestWithMethod:"GET" URL:"/rsa.pub"];
    }
}

- (void)didReceiveResponse:(CPString)data
{
    keyValue = data;
    [textView setStringValue:keyValue];
}

- (void)observeValueForKeyPath:(CPString)keyPath ofObject:(id)object change:(CPDictionary)change context:(id)context
{
    if (object === [User sharedUser])
        keyValue = nil;
    [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
}

@end
