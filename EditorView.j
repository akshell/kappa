// (c) 2010 by Anton Korenyushkin

@implementation EditorView : CPControl
{
    DOMElement iframe;
    JSObject editor;
    CPString stringValue;
    id delegate @accessors(readonly);
}

- (id)initWithFrame:(CGRect)frame syntax:(CPString)syntax readOnly:(BOOL)readOnly // public
{
    if (self = [super initWithFrame: frame]) {
        stringValue = "";
        iframe = document.createElement("iframe");
        iframe.style.width = "100%";
        iframe.style.height = "100%";
        iframe.style.border = "none";
        iframe.frameBorder = "0";
        iframe.src = [[CPBundle mainBundle] pathForResource:"Editor.html"];
        iframe.onload = function () {
            var doc = iframe.contentDocument;
            if (CPBrowserIsEngine(CPGeckoBrowserEngine))
                doc.body.style.marginTop = "-14px";
            doc.onkeydown = function (event) {
                if (CPPlatformActionKeyMask == CPCommandKeyMask ? event.metaKey : event.ctrlKey) {
                    [[[self window] platformWindow] keyEvent:event];
                    if (BoundKeys.indexOf(String.fromCharCode(event.keyCode).toLowerCase()) != -1)
                        return false;
                } else if (event.keyCode == CPEscapeKeyCode ||
                           (event.altKey && (event.keyCode == CPUpArrowKeyCode || event.keyCode == CPDownArrowKeyCode))) {
                    [[[self window] platformWindow] keyEvent:event];
                    return false;
                }
            };
            function setupBespin() {
                if (!doc.body || !doc.body.bespin) {
                    setTimeout(setupBespin, 50);
                    return;
                }
                if (editor)
                    return;
                editor = doc.body.bespin.editor;
                editor.syntax = syntax;
                editor.value = stringValue;
                editor.setLineNumber(1);
                editor.readOnly = readOnly;
                editor.textChanged.add(
                    function () {
                        [self textDidChange:[CPNotification notificationWithName:CPControlTextDidChangeNotification object:self]];
                    });
                doc.body.onclick = function () {
                    if ([CPApp modalWindow]) {
                        editor.focus = NO;
                    } else {
                        var window = [self window];
                        [window makeKeyWindow];
                        [window makeFirstResponder:self];
                    }
                };
                doc.body.onblur = function () {
                    [self refocus];
                };
            };
            iframe.contentWindow.onBespinLoad = setupBespin;
            setupBespin();
        };
        _DOMElement.appendChild(iframe);
        [[CPNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(refocus)
                                                     name:CPMenuDidEndTrackingNotification
                                                   object:[CPApp mainMenu]];
    }
    return self;
}

- (void)refocus // private
{
    var window = [self window];
    if (!(editor && [window isKeyWindow] && [window firstResponder] === self))
        return;
    editor.focus = YES;
    setTimeout(
        function () {
            if ([window isKeyWindow])
                iframe.focus();
        },
        0);
}

- (CPString)stringValue // public
{
    return editor ? editor.value : stringValue;
}

- (void)setStringValue:(CPString)aStringValue // public
{
    if (!editor) {
        stringValue = aStringValue;
        return;
    }
    var wasReadOnly = editor.readOnly;
    editor.readOnly = NO;
    editor.value = aStringValue;
    editor.setLineNumber(1);
    editor.readOnly = wasReadOnly;
}

- (void)setLineNumber:(unsigned)lineNumber // public
{
    editor.setLineNumber(lineNumber);
}

- (void)setSearchString:(CPString)searchString // public
{
    editor.searchController.setSearchText(searchString, NO);
}

- (void)selectRange:(JSObject)range // private
{
    if (range)
        editor.textView.setSelection(range, YES);
}

- (void)findNext // public
{
    [self selectRange:editor.searchController.findNext(editor.selection.end, YES)];
}

- (void)findPrevious // public
{
    [self selectRange:editor.searchController.findPrevious(editor.selection.start, YES)];
}

- (void)setDelegate:(id)aDelegate // public
{
    var defaultCenter = [CPNotificationCenter defaultCenter];
    if (delegate)
        [defaultCenter removeObserver:delegate name:CPControlTextDidChangeNotification object:self];
    delegate = aDelegate;
    if ([delegate respondsToSelector:@selector(controlTextDidChange:)])
        [defaultCenter addObserver:delegate
                          selector:@selector(controlTextDidChange:)
                              name:CPControlTextDidChangeNotification
                            object:self];
}

- (BOOL)acceptsFirstResponder // public
{
    return YES;
}

- (BOOL)becomeFirstResponder // public
{
    iframe.focus();
    if (editor)
        editor.focus = YES;
    return YES;
}

- (BOOL)resignFirstResponder // public
{
    if (editor)
        editor.focus = NO;
    return YES;
}

- (void)becomeKeyWindow // public
{
    [self becomeFirstResponder];
}

- (void)resignKeyWindow // public
{
    if (editor)
        editor.focus = NO;
}

@end
