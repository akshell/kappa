// (c) 2010 by Anton Korenyushkin

@import "BaseFileController.j"

var fileContents = {};

@implementation LibFileController : BaseFileController
{
    CPString fileURL;
}

- (id)initWithApp:(App)anApp buffer:(Buffer)aBuffer // public
{
    fileURL = [aBuffer.lib URL] + aBuffer.path;
    return [super initWithApp:anApp
                       buffer:aBuffer
                     fileName:aBuffer.path.substring(aBuffer.path.lastIndexOf("/"))
                      fileURL:fileURL
                     readOnly:YES];
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
