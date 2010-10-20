// (c) 2010 by Anton Korenyushkin

@import "Manager.j"

@implementation Entry (CodeManager)

- (CPString)path // public
{
    var parts = [];
    for (var entry = self; entry; entry = entry.parentFolder)
        parts.unshift(entry.name);
    return parts.join("/");
}

@end

@implementation File (CodeManager)

- (BOOL)isExpandable // public
{
    return NO;
}

- (CPString)imageName // public
{
    return "File";
}

- (CPArray)neighbours // public
{
    return parentFolder.files;
}

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

@implementation Folder (CodeManager)

- (BOOL)isExpandable // public
{
    return YES;
}

- (CPString)imageName // public
{
    return "Folder";
}

- (unsigned)numberOfChildren // public
{
    return folders.length + files.length;
}

- (id)childAtIndex:(unsigned)index // public
{
    return index < folders.length ? folders[index] : files[index - folders.length];
}

- (CPArray)neighbours // public
{
    return parentFolder.folders;
}

- (CPString)uniqueChildNameWithPrefix:(CPString)prefix // public
{
    if (![self childWithName:prefix])
        return prefix;
    prefix += " ";
    for (var i = 2;; ++i) {
        var childName = prefix + i;
        if (![self childWithName:childName])
            return childName;
    }
}

- (BOOL)hasChildWithName:(CPString)aName
{
    var child = [self childWithName:aName];
    if (child)
        [[[Alert alloc] initWithMessage:"The entry \"" + aName + "\" already exists."
                                comment:"Please choose another name."]
            showPanel];
    return !!child;
}

@end

var entryNameIsCorrect = function (name) {
    if (name.indexOf("/") == -1)
        return YES;
    [[[Alert alloc] initWithMessage:"Entry names cannot contain slashes."
                            comment:"Please fix the entry name."]
        showPanel];
    return NO;
};

@implementation CodeManager : Manager

- (CPString)name // public
{
    return "Code";
}

- (CPString)imageName // public
{
    return "Code";
}

- (unsigned)numberOfChildren // public
{
    return app.code ? [app.code numberOfChildren] : 0;
}

- (Entry)childAtIndex:(unsigned)index // public
{
    return [app.code childAtIndex:index];
}

- (BOOL)isReady // public
{
    return !!app.code;
}

- (CPString)URL // protected
{
    return [app URL] + "code/";
}

- (void)processRepr:(JSObject)tree // protected
{
    [app setCode:[[Folder alloc] initWithTree:tree]];
}

- (void)insertItem:(Entry)entry // protected
{
    var neighbours = [entry neighbours];
    for (var i = 0; i < neighbours.length; ++i)
        if (neighbours[i].name > entry.name)
            break;
    neighbours.splice(i, 0, entry);
}

- (void)removeItem:(Entry)entry // protected
{
    [[entry neighbours] removeObject:entry];
}

- (File)newFileInFolder:(Folder)parentFolder // public
{
    var file = [[File alloc] initEmptyWithName:[parentFolder uniqueChildNameWithPrefix:"untitled file"]
                                  parentFolder:parentFolder];
    [self insertNewItem:file];
    return file;
}

- (Folder)newFolderInFolder:(Folder)parentFolder // public
{
    var folder = [[Folder alloc] initWithName:[parentFolder uniqueChildNameWithPrefix:"untitled folder"]
                                 parentFolder:parentFolder];
    [self insertNewItem:folder];
    return folder;
}

- (void)createItem:(Entry)entry withName:(CPString)name // protected
{
    if (name != entry.name && entryNameIsCorrect(name) && ![entry.parentFolder hasChildWithName:name])
        [entry setName:name];
    if ([entry isKindOfClass:File])
        [self createItem:entry byRequestWithMethod:"PUT" URL:[self URL] + [entry path] data:""];
    else
        [self createItem:entry byRequestWithMethod:"POST" URL:[self URL] data:{action: "mkdir", path: [entry path]}];
}

- (void)renameItem:(Entry)entry to:(CPString)name // protected
{
    if (!entryNameIsCorrect(name) || [entry.parentFolder hasChildWithName:name])
        return;
    var pathPrefix = [entry.parentFolder path];
    if (pathPrefix)
        pathPrefix += "/";
    [self renameItem:entry to:name byRequestWithMethod:"POST" URL:[self URL]
                data:{action: "mv", pathPairs: [[pathPrefix + entry.name, pathPrefix + name]]}];
}

- (CPString)descriptionOfItems:(CPArray)entries // public
{
    return (entries.length == 1
            ? ([entries[0] isKindOfClass:File] ? "file" : "folder") + " \"" + entries[0].name + "\""
            : "selected " + entries.length + " entries");
}

- (void)deleteItems:(CPArray)entries // public
{
    [self deleteItems:entries byRequestWithMethod:"POST" URL:[self URL]
                 data:{action: "rm", paths: entries.map(function (entry) { return [entry path]; })}];
    [self notify];
}

- (void)loadFile:(File)file // public
{
    [[[HTTPRequest alloc] initWithMethod:"GET" URL:[self URL] + [file path] target:file action:@selector(didLoadContent:)] send];
}

- (void)saveFile:(File)file // public
{
    var request = [[HTTPRequest alloc] initWithMethod:"PUT"
                                                  URL:[self URL] + [file path]
                                               target:file
                                               action:@selector(didSave:content:)];
    [request setContext:file.currentContent];
    [request send:file.currentContent];
}

- (void)moveEntries:(CPArray)entries toFolder:(Folder)folder // public
{
    // TODO
}

- (void)duplicateEntries:(CPArray)entries // public
{
    // TODO
}

@end
