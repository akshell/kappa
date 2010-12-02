// (c) 2010 by Anton Korenyushkin

@import "BaseConsoleController.j"

@implementation GitController : BaseConsoleController

- (id)initWithApp:(App)anApp buffer:(Buffer)aBuffer // public
{
    return [super initWithApp:anApp
                       buffer:aBuffer
                 infoBoxWidth:240
                      message:"Run Git commands."
                      comment:"Type \"help\" to get started."
             inputButtonTitle:"Run"];
}

- (void)handleInput:(CPString)input // protected
{
    // TODO
}

@end
