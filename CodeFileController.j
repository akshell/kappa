// (c) 2010 by Anton Korenyushkin

@import "BaseFileController.j"

@implementation CodeFileController : BaseFileController

- (id)initWithApp:(App)anApp buffer:(Buffer)aBuffer // public
{
    if (self = [super initWithApp:anApp
                           buffer:aBuffer
                         fileName:aBuffer.file.name
                          fileURL:[anApp URL] + "code/" + [aBuffer.file path]
                         readOnly:NO])
        [buffer.file addObserver:self forKeyPath:"content"];
    return self;
}

- (CPString)fileContent // protected
{
    return buffer.file.content;
}

- (void)load // protected
{
    [app loadFile:buffer.file];
}

- (void)observeValueForKeyPath:(CPString)keyPath ofObject:(id)object change:(CPDictionary)change context:(id)context // private
{
    [buffer setProcessing:NO];
    if (!buffer.isEditable)
        [self setupEditor];
}

- (void)controlTextDidChange:(id)sender // private
{
    [buffer setModified:YES];
}

- (void)save // public
{
    if (!buffer.isModified)
        return;
    [buffer setModified:NO];
    [buffer setProcessing:YES];
    [app saveFile:buffer.file content:[editorView stringValue]];
}

@end
