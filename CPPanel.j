// (c) 2010-2011 by Anton Korenyushkin

@implementation CPPanel (Utils)

- (void)dismiss // public
{
    if ([self isSheet])
        [CPApp endSheet:self];
    else
        [self close];
}

- (BOOL)performKeyEquivalent:(CPEvent)event // public
{
    var characters = [event characters];
    if (characters == CPEscapeFunctionKey || characters == "w" && [event modifierFlags] == CPPlatformActionKeyMask) {
        [self dismiss];
        return YES;
    }
    return [super performKeyEquivalent:event];
}

@end
