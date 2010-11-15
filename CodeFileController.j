// (c) 2010 by Anton Korenyushkin

@import "BaseFileController.j"

@implementation CodeFileController : BaseFileController

- (BOOL)isReadOnly // protected
{
    return NO;
}

- (CPString)fileName // protected
{
    return buffer.file.name;
}

- (CPString)fileContent // protected
{
    return buffer.file.content;
}

- (void)load // protected
{
    [buffer.file addObserver:self forKeyPath:"content"];
    [app loadFile:buffer.file];
}

- (void)observeValueForKeyPath:(CPString)keyPath ofObject:(id)object change:(CPDictionary)change context:(id)context // private
{
    [buffer setProcessing:NO];
    if (!editorView)
        [self createEditorView];
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
