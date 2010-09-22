// (c) 2010 by Anton Korenyushkin

@implementation CPPanel (EscapeAddition)

- (BOOL)performKeyEquivalent:(CPEvent)event
{
    if ([event characters] == CPEscapeFunctionKey) {
        [self close];
        return YES;
    }
    return [super performKeyEquivalent:event];
}

@end
