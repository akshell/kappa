// (c) 2010 by Anton Korenyushkin

@import "TextView.j"
@import "RequestPanelController.j"

@implementation KeyPanelController : RequestPanelController
{
    @outlet TextView textView;
}

- (id)init
{
    return [super initWithWindowCibName:"KeyPanel"];
}

- (void)awakeFromCib
{
    [self requestWithMethod:"GET" URL:"/rsa.pub"];
}

- (void)didReceiveResponse:(CPString)data
{
    [textView setStringValue:data];
}

@end
