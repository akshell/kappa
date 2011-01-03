// (c) 2010-2011 by Anton Korenyushkin

@implementation CPImage (Utils)

+ (CPImage)imageFromPath:(CPString)path // public
{
    return [[CPImage alloc] initWithContentsOfFile:[[CPBundle mainBundle] pathForResource:path]];
}

@end
