// (c) 2010 by Anton Korenyushkin

@import "BasePresentationController.j"
@import "EditorView.j"
@import "GoToLinePanelController.j"

@implementation BaseFileController : BasePresentationController
{
    GoToLinePanelController goToLinePanelController;
    CPView view @accessors(readonly);
    CPView searchView;
    CPSearchField searchField;
    CPSegmentedControl segmentedControl;
    EditorView editorView;
    CPScrollView scrollView;
    CPImageView imageView;
    CPImage image;
    CPImageView spinnerImageView;
}

- (id)initWithApp:(App)anApp buffer:(Buffer)aBuffer // public
{
    self = [super initWithApp:anApp buffer:aBuffer];

    if (!self)
        return self;

    view = [CPView new];

    var fileName = [self fileName];
    var dotIndex = fileName.lastIndexOf(".");
    var extension = dotIndex == -1 ? "" : fileName.substring(dotIndex + 1).toLowerCase();

    if (["jpg", "jpeg", "gif", "png", "bmp"].indexOf(extension) == -1) {
        goToLinePanelController = [[GoToLinePanelController alloc] initWithTarget:self action:@selector(goToLine:)];

        searchView = [CPView new];
        [searchView setAutoresizingMask:CPViewWidthSizable];
        [searchView setBackgroundColor:[CPColor colorWithPatternImage:[CPImage imageFromPath:"SearchViewBackground.png"]]];
        var doneButton = [[CPButton alloc] initWithFrame:CGRectMake(-58, 3, 50, 24)];
        [doneButton setAutoresizingMask:CPViewMinXMargin];
        [doneButton setKeyEquivalent:CPEscapeFunctionKey];
        [doneButton setTitle:"Done"];
        [doneButton setTarget:self];
        [doneButton setAction:@selector(hideFind)];
        [searchView addSubview:doneButton];
        searchField = [[CPSearchField alloc] initWithFrame:CGRectMake(-270, 0, 207, 30)];
        [searchField setAutoresizingMask:CPViewMinXMargin];
        [searchField setTarget:self];
        [searchField setAction:@selector(find)];
        var searchButton = [searchField searchButton];
        [searchView addSubview:searchField];
        segmentedControl = [[CPSegmentedControl alloc] initWithFrame:CGRectMake(-335, 3, 0, 24)];
        [segmentedControl setAutoresizingMask:CPViewMinXMargin];
        [segmentedControl setTrackingMode:CPSegmentSwitchTrackingMomentary];
        [segmentedControl setTarget:self];
        [segmentedControl setAction:@selector(didClickOnSegmentedControl)];
        [segmentedControl setSegmentCount:2];
        [segmentedControl setLabel:"◀" forSegment:0];
        [segmentedControl setWidth:30 forSegment:0];
        [segmentedControl setLabel:"▶" forSegment:1];
        [segmentedControl setWidth:31 forSegment:1];
        [searchView addSubview:segmentedControl];

        editorView = [[EditorView alloc] initWithFrame:CGRectMakeZero() syntax:extension readOnly:[self isReadOnly]];
        [editorView setAutoresizingMask:CPViewWidthSizable | CPViewHeightSizable];
        [editorView setDelegate:self];

        if ([self fileContent] !== nil) {
            [self setupEditor];
            return self;
        }

        [self load];
    } else {
        scrollView = [[CPScrollView alloc] initWithFrame:CGRectMakeZero()];
        [scrollView setAutoresizingMask:CPViewWidthSizable | CPViewHeightSizable];
        [scrollView setAutohidesScrollers:YES];
        [scrollView setPostsFrameChangedNotifications:YES];
        [[CPNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(resizeImageView)
                                                     name:CPViewFrameDidChangeNotification
                                                   object:scrollView];
        imageView = [[CPImageView alloc] initWithFrame:CGRectMakeZero()];
        [imageView setImageScaling:CPScaleNone];
        image = [[CPImage alloc] initWithContentsOfFile:[self fileURL]];
        [image setDelegate:self];
        [imageView setImage:image];
        [scrollView setDocumentView:imageView];
    }

    spinnerImageView = [[CPImageView alloc] initWithFrame:[view bounds]];
    [spinnerImageView setImage:[CPImage imageFromPath:"WhiteSpinner32.gif"]];
    [spinnerImageView setAutoresizingMask:CPViewWidthSizable | CPViewHeightSizable];
    [spinnerImageView setImageScaling:CPScaleNone];
    [view addSubview:spinnerImageView];
    [buffer setProcessing:YES];

    return self;
}

- (void)focus // public
{
    [[view window] makeFirstResponder:editorView];
}

- (void)setupEditor // private
{
    [spinnerImageView removeFromSuperview];
    [editorView setFrame:[view bounds]];
    [editorView setStringValue:[self fileContent]];
    [view addSubview:editorView];
    [self focus];
    [buffer setEditable:YES];
}

- (void)showGoToLine // public
{
    [goToLinePanelController showWindow:nil];
}

- (void)goToLine:(unsigned)lineNumber // private
{
    [editorView setLineNumber:lineNumber];
    [self focus];
}

- (void)showFind // public
{
    if (![searchView superview]) {
        var boundsSize = [view boundsSize];
        [editorView setFrame:CGRectMake(0, 31, boundsSize.width, boundsSize.height - 31)];
        [searchView setFrame:CGRectMake(0, 0, boundsSize.width, 31)];
        [view addSubview:searchView];
    }
    [[view window] makeFirstResponder:searchField];
}

- (void)hideFind // private
{
    [searchView removeFromSuperview];
    [editorView setFrame:[view bounds]];
    [self focus];
}

- (void)find // private
{
    [editorView setSearchString:[searchField stringValue]];
    [editorView findNext];
}

- (void)didClickOnSegmentedControl // private
{
    if ([segmentedControl selectedSegment] == 0)
        [editorView findPrevious];
    else
        [editorView findNext];
    [[view window] makeFirstResponder:searchField];
}

- (void)findNext // public
{
    [editorView findNext];
}

- (void)findPrevious // public
{
    [editorView findPrevious];
}

- (void)imageDidLoad:(CPImage)anImage // private
{
    [buffer setProcessing:NO];
    [spinnerImageView removeFromSuperview];
    [scrollView setFrame:[view bounds]];
    [view addSubview:scrollView];
}

- (void)resizeImageView // private
{
    var imageSize = [image size];
    var boundsSize = [scrollView boundsSize];
    var scrollerWidth = [CPScroller scrollerWidth];
    [imageView setFrameSize:CGSizeMake(MAX(imageSize.width, boundsSize.width - scrollerWidth),
                                       MAX(imageSize.height, boundsSize.height - scrollerWidth))];
}

@end
