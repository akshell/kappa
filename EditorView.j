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
                    iframe.focus();
                    editor.focus = YES;
                };
                doc.body.onblur = function () {
                    editor.focus = NO;
                };
            }
        };
        _DOMElement.appendChild(iframe);
    }
    return self;
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

@end
