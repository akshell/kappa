// (c) 2010 by Anton Korenyushkin

@import "TextView.j"
@import "RequestPanelController.j"

@implementation KeyPanelController : RequestPanelController
{
    @outlet TextView keyTextView;
    CPString keyValue;
}

- (id)init
{
    return [super initWithWindowCibName:"KeyPanel"];
}

- (void)awakeFromCib
{
    [keyTextView setEditable:NO];
}

- (void)showWindow:(id)sender
{
    [super showWindow:sender];
    if (keyValue) {
        [keyTextView setStringValue:keyValue];
    } else {
        [keyTextView setStringValue:""];
        [self requestWithMethod:"GET" URL:"/rsa.pub"];
    }
}

- (void)didReceiveResponse:(CPString)data
{
    keyValue = data;
    [keyTextView setStringValue:keyValue];
}

- (void)observeValueForKeyPath:(CPString)keyPath ofObject:(id)object change:(CPDictionary)change context:(id)context
{
    if (keyPath == "username")
        keyValue = nil;
    [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
}

@end
