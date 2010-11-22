// (c) 2010 by Anton Korenyushkin

@import "BaseFileController.j"

var fileContents = {};

@implementation LibFileController : BaseFileController
{
    CPString url;
}

- (id)initWithApp:(App)anApp buffer:(Buffer)aBuffer // public
{
    url = [aBuffer.lib URL] + aBuffer.path;
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
    return fileContents.hasOwnProperty(url) ? fileContents[url] : nil;
}

- (void)load // protected
{
    [[[HTTPRequest alloc] initWithMethod:"GET" URL:url target:self action:@selector(didLoadContent:)] send];
}

- (void)didLoadContent:(CPString)content // private
{
    [buffer setProcessing:NO];
    fileContents[url] = content;
    [self setupEditor];
}

@end
