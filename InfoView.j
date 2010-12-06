// (c) 2010 by Anton Korenyushkin

@implementation InfoView : CPView

- (id)initWithFrame:(CGRect)frame boxWidth:(unsigned)boxWidth message:(CPString)message comment:(CPString)comment // public
{
    if (self = [super initWithFrame:frame]) {
        var labelWidth = boxWidth - 96;
        var messageSize = [message realSizeWithFont:BoldSystemFont inWidth:labelWidth];
        var commentSize = [comment realSizeWithFont:SystemFont inWidth:labelWidth];
        var boxHeight = MAX(80, messageSize.height + commentSize.height + 40);
        var box = [[CPBox alloc] initWithFrame:CGRectMake((CGRectGetWidth(frame) - boxWidth) / 2,
                                                          (CGRectGetHeight(frame) - boxHeight) / 2,
                                                          boxWidth,
                                                          boxHeight)];
        [box setAutoresizingMask:CPViewMinXMargin | CPViewMaxXMargin | CPViewMinYMargin | CPViewMaxYMargin];
        [box setBackgroundColor:PanelBackgroundColor];
        var imageView = [[CPImageView alloc] initWithFrame:CGRectMake(16, 16, 48, 48)];
        [imageView setImage:[CPImage imageFromPath:"Info48.png"]];
        [box addSubview:imageView];
        var messageLabel = [[CPTextField alloc] initWithFrame:CGRectMake(80, 16, messageSize.width, messageSize.height)];
        [messageLabel setStringValue:message];
        [messageLabel setFont:BoldSystemFont];
        [messageLabel setLineBreakMode:CPLineBreakByWordWrapping];
        [box addSubview:messageLabel];
        var commentLabel = [[CPTextField alloc] initWithFrame:CGRectMake(80, messageSize.height + 24,
                                                                         commentSize.width, commentSize.height)];
        [commentLabel setStringValue:comment];
        [commentLabel setLineBreakMode:CPLineBreakByWordWrapping];
        [box addSubview:commentLabel];
        [self addSubview:box];
    }
    return self;
}

@end
