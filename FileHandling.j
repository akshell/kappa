// (c) 2010 by Anton Korenyushkin

@import "Data.j"
@import "HTTPRequest.j"

@implementation App (FileHandling)

- (CPString)URLOfFile:(File)file // public
{
    return [self URL] + "code/" + [file path];
}

- (void)loadFile:(File)file // public
{
    [[[HTTPRequest alloc] initWithMethod:"GET"
                                     URL:[self URLOfFile:file]
                                  target:file
                                  action:@selector(didLoadContent:)]
        send];
}

- (void)saveFile:(File)file // public
{
    var request = [[HTTPRequest alloc] initWithMethod:"PUT"
                                                  URL:[self URLOfFile:file]
                                               target:file
                                               action:@selector(didSave:content:)];
    [request setContext:file.currentContent];
    [request send:file.currentContent];
}

@end

@implementation File (FileHandling)

- (void)didLoadContent:(CPString)content // public
{
    var isSaved = currentContent == savedContent;
    [self setSavedContent:content];
    if (isSaved)
        [self setCurrentContent:content];
}

- (void)didSave:(CPString)data content:(CPString)content // public
{
    [self setSavedContent:content];
}

@end
