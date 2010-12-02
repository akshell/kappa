// (c) 2010 by Anton Korenyushkin

@import "SmartScrollView.j"
@import "EditorView.j"
@import "BasePresentationController.j"
@import "GoToLinePanelController.j"

@implementation BaseFileController : BasePresentationController
{
    GoToLinePanelController goToLinePanelController;
    CPView searchView;
    CPSearchField searchField;
    CPSegmentedControl segmentedControl;
    EditorView editorView;
    SmartScrollView scrollView;
    CPImageView spinnerImageView;
}

- (id)initWithApp:(App)anApp buffer:(Buffer)aBuffer // public
{
    self = [super initWithApp:anApp buffer:aBuffer];

    if (!self)
        return self;

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
        scrollView = [[SmartScrollView alloc] initWithFrame:CGRectMakeZero()];
        [scrollView setAutoresizingMask:CPViewWidthSizable | CPViewHeightSizable];
        [scrollView setAutohidesScrollers:YES];
        var imageView = [[CPImageView alloc] initWithFrame:CGRectMakeZero()];
        [imageView setImageScaling:CPScaleNone];
        var image = [[CPImage alloc] initWithContentsOfFile:[self fileURL]];
        [image setDelegate:self];
        [imageView setImage:image];
        [scrollView setDocumentView:imageView];
        [view addSubview:scrollView];
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
    if (editorView)
        [[view window] makeFirstResponder:editorView];
    else
        window.focus();
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

- (void)imageDidLoad:(CPImage)image // private
{
    [buffer setProcessing:NO];
    [spinnerImageView removeFromSuperview];
    [scrollView setBaseSize:[image size]];
}

@end
