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
        iframe.onload = function () {
            iframe.onload = null;
            var doc = iframe.contentDocument;
            doc.open();
            doc.write(
                "<!DOCTYPE html PUBLIC '-//W3C//DTD HTML 4.01//EN' 'http://www.w3.org/TR/html4/strict.dtd'>" +
                "<html><head><style>" +
                "html {margin: 0; padding: 0; width: 100%; height: 100%;} " +
                "body {margin: 0; padding: 0; width: 100%; height: 100%; overflow: hidden} " +
                "</style>" +
                "<link id='bespin_base' href='/frontend/Bespin'/>" +
                "<script src='/frontend/Bespin/BespinEmbedded.js'></script>" +
                "</head>" +
                "<body class='bespin'></body>" +
                "</html>");
            doc.close();
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
            iframe.contentWindow.onBespinLoad = function () {
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
            }
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
