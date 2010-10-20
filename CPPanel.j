// (c) 2010 by Anton Korenyushkin

@implementation CPPanel (EscapeAddition)

- (void)dismiss
{
    if ([self isSheet])
        [CPApp endSheet:self];
    else
        [self close];
}

- (BOOL)performKeyEquivalent:(CPEvent)event
{
    if ([event characters] == CPEscapeFunctionKey) {
        [self dismiss];
        return YES;
    }
    return [super performKeyEquivalent:event];
}

@end
