// (c) 2010 by Anton Korenyushkin

@import "BasePresentationController.j"
@import "EditorView.j"
@import "GoToLinePanelController.j"

@implementation BaseFileController : BasePresentationController
{
    CPImageView spinnerImageView;
    EditorView editorView;
    GoToLinePanelController goToLinePanelController;
}

- (id)initWithApp:(App)anApp buffer:(Buffer)aBuffer // public
{
    if (self = [super initWithApp:anApp buffer:aBuffer]) {
        view = [CPView new];
        if ([self fileContent] === nil) {
            spinnerImageView = [[CPImageView alloc] initWithFrame:[view bounds]];
            [spinnerImageView setImage:[CPImage imageFromPath:"WhiteSpinner32.gif"]];
            [spinnerImageView setAutoresizingMask:CPViewWidthSizable | CPViewHeightSizable];
            [spinnerImageView setImageScaling:CPScaleNone];
            [view addSubview:spinnerImageView];
            [buffer setProcessing:YES];
            [self load];
        } else {
            [self createEditorView];
        }
    }
    return self;
}

- (void)focus // public
{
    [[view window] makeFirstResponder:editorView];
}

- (void)createEditorView // private
{
    [spinnerImageView removeFromSuperview];
    var fileName = [self fileName];
    var dotIndex = fileName.lastIndexOf(".");
    var syntax = dotIndex == -1 ? "plain" : fileName.substring(dotIndex + 1);
    editorView = [[EditorView alloc] initWithFrame:[view bounds] syntax:syntax readOnly:[self isReadOnly]];
    [editorView setDelegate:self];
    [editorView setStringValue:[self fileContent]];
    [editorView setAutoresizingMask:CPViewWidthSizable | CPViewHeightSizable];
    [view addSubview:editorView];
    [self focus];
    goToLinePanelController = [[GoToLinePanelController alloc] initWithTarget:editorView action:@selector(goToLine:)];
    [buffer setEditable:YES];
}

- (void)showGoToLine // public
{
    [goToLinePanelController showWindow:nil];
}

@end
