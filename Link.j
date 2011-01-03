// (c) 2010-2011 by Anton Korenyushkin

@implementation Link : CPTextField

- (id)initWithCoder:(CPCoder)coder // public
{
    if (self = [super initWithCoder:coder]) {
        [self setValue:"DarkBlue" forThemeAttribute:"text-color"];
        _DOMElement.style.cursor = "pointer";
    }
    return self;
}

- (void)mouseDown:(CPEvent)event // protected
{
    [self sendAction:[self action] to:[self target]];
}

@end
