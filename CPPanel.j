// (c) 2010 by Anton Korenyushkin

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
    if ([event characters] == CPEscapeFunctionKey) {
        [self dismiss];
        return YES;
    }
    return [super performKeyEquivalent:event];
}

@end
