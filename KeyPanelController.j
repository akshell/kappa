// (c) 2010 by Anton Korenyushkin

@import "TextView.j"
@import "RequestPanelController.j"

var keyValue;

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
    if (keyValue)
        [textView setStringValue:keyValue];
    else
        [self requestWithMethod:"GET" URL:"/rsa.pub"];
}

- (void)didReceiveResponse:(CPString)data
{
    keyValue = data;
    [textView setStringValue:keyValue];
}

+ (void)resetKeyValue
{
    keyValue = nil;
}

@end
