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
                                  action:@selector(setContent:)]
        send];
}

- (void)saveFile:(File)file content:(CPString)newContent // public
{
    var request = [[HTTPRequest alloc] initWithMethod:"PUT"
                                                  URL:[self URLOfFile:file]
                                               target:file
                                               action:@selector(didSave:content:)];
    [request setContext:newContent];
    [request send:newContent];
}

@end

@implementation File (FileHandling)

- (void)didSave:(CPString)data content:(CPString)newContent // public
{
    [self setContent:newContent];
}

@end
