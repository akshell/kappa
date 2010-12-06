// (c) 2010 by Anton Korenyushkin

@import "BasePresentationController.j"
@import "InfoView.j"
@import "TextView.j"
@import "HTTPRequest.j"

@implementation DiffView : CPView

- (void)setStringValue:(CPString)stringValue // public
{
    var width = 0;
    var height = 20;
    var labels = stringValue.split("\n").map(
        function (line) {
            var labelSize = [line realSizeWithFont:MonospaceFont];
            var label = [[CPTextField alloc] initWithFrame:CGRectMake(20, height, labelSize.width, 22)];
            [label setStringValue:line + "\n"];
            [label setSelectable:YES];
            var prefix = line.substring(0, 4);
            if (prefix == "+++ " || prefix == "--- ") {
                [label setFont:BoldMonospaceFont];
            } else {
                var color = {
                    " ": [CPColor blackColor],
                    "\\": [CPColor blackColor],
                    "+": PositiveColor,
                    "-": NegativeColor,
                    "@": CommentColor,
                }[line[0]];
                if (color) {
                    [label setTextColor:color];
                    [label setFont:MonospaceFont];
                } else {
                    [label setFont:BoldMonospaceFont];
                }
            }
            height += 22;
            width = MAX(width, labelSize.width);
            return label;
        });
    [self setFrameSize:CGSizeMake(width + 40, height - 2)];
    [self setSubviews:labels];
}

@end

@implementation CommitController : BasePresentationController
{
    unsigned currentState;
    CPSplitView splitView;
    CPImageView spinnerImageView;
    InfoView infoView;
    CPScrollView scrollView;
    DiffView diffView;
    TextView textView;
    CPButton commitButton;
    CPButton amendButton;
}

- (id)initWithApp:(App)anApp buffer:(Buffer)aBuffer // public
{
    if (self = [super initWithApp:anApp buffer:aBuffer]) {
        currentState = 0;

        splitView = [[CPSplitView alloc] initWithFrame:CGRectMake(0, 0, 1000, 1000)];
        [splitView setVertical:NO];
        [splitView setDelegate:self];

        spinnerImageView = [[CPImageView alloc] initWithFrame:CGRectMakeZero()];
        [spinnerImageView setAutoresizingMask:CPViewHeightSizable];
        [spinnerImageView setImage:[CPImage imageFromPath:"WhiteSpinner32.gif"]];
        [spinnerImageView setImageScaling:CPScaleNone];
        [splitView addSubview:spinnerImageView];

        infoView = [[InfoView alloc] initWithFrame:CGRectMakeZero()
                                          boxWidth:240
                                           message:"Nothing to commit."
                                           comment:"The working tree is clean."];
        [infoView setAutoresizingMask:CPViewHeightSizable];

        scrollView = [[CPScrollView alloc] initWithFrame:CGRectMakeZero()];
        [scrollView setAutoresizingMask:CPViewHeightSizable];
        [scrollView setAutohidesScrollers:YES];

        diffView = [DiffView new];
        [scrollView setDocumentView:diffView];

        var actionView = [CPView new];
        [actionView setBackgroundColor:PanelBackgroundColor];
        [splitView addSubview:actionView];
        [splitView setPosition:840 ofDividerAtIndex:0];
        var boundsSize = [actionView boundsSize];

        var label = [[CPTextField alloc] initWithFrame:CGRectMake(20, 16, 200, 18)];
        [label setStringValue:"Commit message:"];
        [actionView addSubview:label];

        textView = [[TextView alloc] initWithFrame:CGRectMake(20, 36, boundsSize.width - 40, boundsSize.height - 86)
                                              font:MonospaceFont];
        [textView setAutoresizingMask:CPViewWidthSizable | CPViewHeightSizable];
        [textView setDelegate:self];
        [actionView addSubview:textView];

        amendButton = [[CPButton alloc] initWithFrame:CGRectMake(boundsSize.width - 161, boundsSize.height - 44, 63, 24)];
        [amendButton setTitle:"Amend"];
        [amendButton setTarget:self];
        [amendButton setAction:@selector(amend)];
        [amendButton setEnabled:NO];
        [amendButton setAutoresizingMask:CPViewMinXMargin | CPViewMinYMargin];
        [actionView addSubview:amendButton];

        commitButton = [[CPButton alloc] initWithFrame:CGRectMake(boundsSize.width - 90, boundsSize.height - 44, 70, 24)];
        [commitButton setTitle:"Commit"];
        [commitButton setTarget:self];
        [commitButton setAction:@selector(commit)];
        [commitButton setEnabled:NO];
        [commitButton setAutoresizingMask:CPViewMinXMargin | CPViewMinYMargin];
        [actionView addSubview:commitButton];

        [app addObserver:self forKeyPath:"code"];
        [self observeFolder:app.code];
    }
    return self;
}

- (void)observeFolder:(Folder)folder // private
{
    folder.folders.forEach(function (childFolder) { [self observeFolder:childFolder] });
    folder.files.forEach(function (childFile) { [childFile addObserver:self forKeyPath:"content"]; });
}

- (void)setTopView:(CPView)newTopView // private
{
    var oldTopView = [splitView subviews][0];
    [newTopView setFrame:[oldTopView frame]];
    [splitView replaceSubview:oldTopView with:newTopView];
}

- (void)observeValueForKeyPath:(CPString)keyPath ofObject:(id)object change:(CPDictionary)change context:(id)context // private
{
    ++currentState;
    if (keyPath == "code")
        [self observeFolder:app.code];
    if (![spinnerImageView superview]) {
        [self setTopView:spinnerImageView];
        if (![splitView isHidden]) {
            var state = currentState;
            setTimeout(
                function () {
                    if (state == currentState)
                        [self requestDiff];
                },
                100);
        }
    }
}

- (CPView)view // public
{
    if ([spinnerImageView superview])
        [self requestDiff];
    return splitView;
}

- (void)focus // public
{
    [[splitView window] makeFirstResponder:textView];
}

- (void)requestDiff // private
{
    var request = [[HTTPRequest alloc] initWithMethod:"GET" URL:[app URL] + "diff" target:self action:@selector(didReceiveDiff:forState:)];
    [request setContext:currentState];
    [request send];
}

- (void)didReceiveDiff:(CPString)diff forState:(unsigned)state // private
{
    if (state != currentState)
        return;
    var newTopView;
    if (diff) {
        [diffView setStringValue:diff];
        newTopView = scrollView;
    } else {
        newTopView = infoView;
    }
    [self setTopView:newTopView];
}

- (void)controlTextDidChange:(id)sender // private
{
    var stringValue = [textView stringValue];
    [amendButton setEnabled:stringValue];
    [commitButton setEnabled:stringValue && [scrollView superview]];
}

- (unsigned)splitView:(CPSplitView)aSplitView constrainSplitPosition:(unsigned)position ofSubviewAt:(unsigned)index // private
{
    return MIN(position, [splitView boundsSize].height - 130);
}

- (void)commit // private
{
    [self commitAmend:NO];
}

- (void)amend // private
{
    [self commitAmend:YES];
}

- (void)commitAmend:(BOOL)isAmend // private
{
    var request = [[HTTPRequest alloc] initWithMethod:"POST"
                                                  URL:[app URL] + "commit"
                                               target:self
                                               action:@selector(didCommit:state:)];
    [request setContext:currentState];
    [request send:{message: [textView stringValue], amend: isAmend}];
    [textView setStringValue:""];
    [self setTopView:spinnerImageView];
}

- (void)didCommit:(JSObject)data state:(unsigned)state // private
{
    if (state != currentState)
        return;
    [self setTopView:infoView];
}

@end
