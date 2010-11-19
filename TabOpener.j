// (c) 2010 by Anton Korenyushkin

@implementation TabOpener : CPObject
{
    CPArray windows;
}

- (id)init // public
{
    if (self = [super init])
        windows = [];
    return self;
}

- (void)openURL:(CPString)url // public
{
    windows.push(window.open(url));
}

- (BOOL)switchToLastTab // public
{
    for (var i = windows.length; i > 0; --i) {
        if (!windows[i - 1].closed) {
            windows[i - 1].focus();
            break;
        }
    }
    windows.splice(i, windows.length - i);
    return !!i;
}

@end
