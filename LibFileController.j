// (c) 2010 by Anton Korenyushkin

@import "BaseFileController.j"

var fileContents = {};

@implementation LibFileController : BaseFileController
{
    CPString fileURL @accessors(readonly);
}

- (id)initWithApp:(App)anApp buffer:(Buffer)aBuffer // public
{
    fileURL = [aBuffer.lib URL] + aBuffer.path;
    return [super initWithApp:anApp buffer:aBuffer];
}

- (BOOL)isReadOnly // protected
{
    return YES;
}

- (CPString)fileName // protected
{
    return buffer.path.substring(buffer.path.lastIndexOf("/"));
}

- (CPString)fileContent // protected
{
    return fileContents.hasOwnProperty(fileURL) ? fileContents[fileURL] : nil;
}

- (void)load // protected
{
    [[[HTTPRequest alloc] initWithMethod:"GET" URL:fileURL target:self action:@selector(didLoadContent:)] send];
}

- (void)didLoadContent:(CPString)content // private
{
    [buffer setProcessing:NO];
    fileContents[fileURL] = content;
    [self setupEditor];
}

@end
