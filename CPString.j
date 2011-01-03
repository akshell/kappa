// (c) 2010-2011 by Anton Korenyushkin

function realSize(size) {
    return CGSizeMake(size.width + 4, size.height + 4);
};

@implementation CPString (Utils)

- (CGSize)realSizeWithFont:(CPFont)font // public
{
    return realSize([self sizeWithFont:font]);
}

- (CGSize)realSizeWithFont:(CPFont)font inWidth:(float)width // public
{
    return realSize([self sizeWithFont:font inWidth:width - 4]);
}

@end
