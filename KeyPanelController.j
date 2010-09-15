// (c) 2010 by Anton Korenyushkin

@import "TextView.j"


@implementation KeyPanelController : CPWindowController
{
    @outlet TextView textView;
}

- (void)awakeFromCib
{
    [CPURLConnection connectionWithRequest:[CPURLRequest requestWithURL:'/rsa.pub'] delegate:self];
}

- (void)connection:(CPURLConnection)connection didReceiveData:(CPString)data
{
    [textView setStringValue:data];
}

@end
