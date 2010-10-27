// (c) 2010 by Anton Korenyushkin

@import "Data.j"

@implementation WorkspaceItemView : CPView

- (id)init // public
{
    if (self = [super init]) {
        [self addSubview:[[CPImageView alloc] initWithFrame:CGRectMake(18, 3, 16, 16)]];
        [self addSubview:[[CPTextField alloc] initWithFrame:CGRectMake(36, 3, 10000, 18)]];
    }
    return self;
}

- (void)setObjectValue:(Buffer)buffer // public
{
    [[self subviews][0] setImage:[CPImage imageFromPath:[buffer imageName] + ".png"]];
    [[self subviews][1] setStringValue:[buffer name]];
}

@end
