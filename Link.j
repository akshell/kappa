// (c) 2010 by Anton Korenyushkin

@implementation Link : CPTextField
{
}

- (id)initWithCoder:(CPCoder)coder
{
    if (self = [super initWithCoder:coder]) {
        [self setValue:"DarkBlue" forThemeAttribute:"text-color"];
        _DOMElement.style.cursor = "pointer";
    }
    return self;
}

- (void)mouseDown:(CPEvent)event
{
    [self sendAction:[self action] to:[self target]];
}

@end