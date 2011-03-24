// (c) 2010-2011 by Anton Korenyushkin

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
            var win = iframe.contentWindow;
            editor = win.ace.edit(doc.body);
            editor.setReadOnly(readOnly);
            var canon = win.require("pilot/canon");
            canon.removeCommand("gotoline");
            canon.removeCommand("find");
            var session = editor.getSession();
            session.setTabSize(2);
            var modeName = {
                js: "javascript",
                html: "html",
                css: "css"
            }[syntax];
            if (modeName)
                session.setMode(new (win.require("ace/mode/" + modeName).Mode)());
            session.setValue(stringValue);
            editor.gotoLine(1);
            session.addEventListener(
                "change",
                function (event) {
                    [self textDidChange:[CPNotification notificationWithName:CPControlTextDidChangeNotification object:self]];
                    [[CPRunLoop currentRunLoop] limitDateForMode:CPDefaultRunLoopMode];
                });
            editor.addEventListener(
                "blur",
                function (event) {
                    [self refocus];
                });
            doc.body.onclick = function () {
                if ([CPApp modalWindow]) {
                    editor.renderer.hideCursor();
                } else {
                    var window = [self window];
                    [window makeKeyWindow];
                    [window makeFirstResponder:self];
                }
            };
            if ([[self window] isKeyWindow])
                editor.focus();
            else
                [[CPApp keyWindow] makeKeyAndOrderFront:nil];
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
    editor.focus();
    setTimeout(
        function () {
            if ([window isKeyWindow])
                iframe.focus();
        },
        0);
}

- (CPString)stringValue // public
{
    return editor ? editor.getSession().getValue() : stringValue;
}

- (void)setStringValue:(CPString)aStringValue // public
{
    if (!editor) {
        stringValue = aStringValue;
        return;
    }
    editor.getSession().setValue(aStringValue);
    editor.gotoLine(1);
}

- (void)setLineNumber:(unsigned)lineNumber // public
{
    editor.gotoLine(lineNumber);
}

- (void)find:(CPString)searchString // public
{
    editor.find(searchString);
}

- (void)selectRange:(JSObject)range // private
{
    if (range)
        editor.textView.setSelection(range, YES);
}

- (void)findNext // public
{
    editor.findNext();
}

- (void)findPrevious // public
{
    editor.findPrevious();
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
        editor.focus();
    return YES;
}

- (BOOL)resignFirstResponder // public
{
    if (editor)
        editor.renderer.hideCursor();
    return YES;
}

- (void)becomeKeyWindow // public
{
    [self becomeFirstResponder];
}

- (void)resignKeyWindow // public
{
    if (editor) {
        editor.renderer.hideCursor();
        if (CPBrowserIsEngine(CPGeckoBrowserEngine)) {
            var callback = function (event) {
                if (console)
                    console.log("hack");
                editor.blur();
            };
            editor.addEventListener("focus", callback);
            setTimeout(function () { editor.removeEventListener("focus", callback); }, 100);
            iframe.blur();
        }
    }
}

@end
