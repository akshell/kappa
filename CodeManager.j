// (c) 2010 by Anton Korenyushkin

@import "Manager.j"
@import "MovePanelController.j"
@import "ReplacePanelController.j"

var getDuplicatePrefix = function (base) {
    if (base.substring(base.length - 5) == " copy")
        return base;
    var spaceIndex = base.lastIndexOf(" ");
    return (spaceIndex == -1 || isNaN(base.substring(spaceIndex + 1)) || base.substring(spaceIndex - 5, spaceIndex) != " copy"
            ? base + " copy"
            : base.substring(0, spaceIndex));
};

@implementation File (CodeManager)

- (BOOL)isExpandable // public
{
    return NO;
}

- (CPString)imageName // public
{
    return "File16";
}

- (CPString)description // public
{
    return "file \"" + name + "\"";
}

- (CPArray)neighbours // public
{
    return parentFolder.files;
}

- (File)duplicate // public
{
    var base, suffix;
    var dotIndex = name.lastIndexOf(".");
    if (dotIndex < 1) {
        base = name;
        suffix = "";
    } else {
        base = name.substring(0, dotIndex);
        suffix = name.substring(dotIndex);
    }
    return [[File alloc] initWithName:[parentFolder uniqueChildNameWithPrefix:getDuplicatePrefix(base) suffix:suffix]
                         parentFolder:parentFolder
                              content:savedContent];
}

@end

@implementation Folder (CodeManager)

- (BOOL)isExpandable // public
{
    return YES;
}

- (CPString)imageName // public
{
    return "Folder16";
}

- (CPString)description // public
{
    return "folder \"" + name + "\"";
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

- (CPString)uniqueChildNameWithPrefix:(CPString)prefix suffix:(CPString)suffix // public
{
    var childName = prefix + suffix;
    if (![self childWithName:childName])
        return childName;
    prefix += " ";
    for (var i = 2;; ++i) {
        childName = prefix + i + suffix;
        if (![self childWithName:childName])
            return childName;
    }
}

- (CPString)uniqueChildNameWithPrefix:(CPString)prefix // public
{
    return [self uniqueChildNameWithPrefix:prefix suffix:""];
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

- (Folder)duplicate // public
{
    var newFolder = [self cloneTo:parentFolder];
    [newFolder setName:[parentFolder uniqueChildNameWithPrefix:getDuplicatePrefix(name)]];
    return newFolder;
}

- (Folder)cloneTo:(Folder)newParentFolder // private
{
    var newFolder = [Folder alloc];
    return [newFolder initWithName:name
                      parentFolder:newParentFolder
                           folders:folders.map(function (folder) { return [folder cloneTo:newFolder]; })
                             files:files.map(function (file) { return [[File alloc] initWithName:file.name
                                                                                    parentFolder:newFolder
                                                                                         content:file.savedContent]; })];
}

@end

var entryNameIsCorrect = function (name) {
    if (name == "." || name == "..") {
        [[[Alert alloc] initWithMessage:"The name \"" + name + "\" is incorrect."
                                comment:"Please fix the entry name."]
            showPanel];
        return NO;
    }
    if (name.indexOf("/") != -1) {
        [[[Alert alloc] initWithMessage:"Entry names cannot contain slashes."
                                comment:"Please fix the entry name."]
            showPanel];
        return NO;
    }
    return YES;
};

@implementation CodeManager : Manager
{
    MovePanelController movePanelController;
    ReplacePanelController replacePanelController;
    CPArray moveEntries;
    unsigned moveEntriesIndex;
    Folder moveFolder;
}

- (id)initWithApp:(App)anApp // public
{
    if (self = [super initWithApp:anApp]) {
        movePanelController = [[MovePanelController alloc] initWithTarget:self action:@selector(moveToPath:)];
        replacePanelController = [[ReplacePanelController alloc] initWithTarget:self
                                                                  replaceAction:@selector(moveReplacing)
                                                                     skipAction:@selector(moveSkipping)];
    }
    return self;
}

- (CPString)name // public
{
    return "Code";
}

- (CPString)imageName // public
{
    return "Code16";
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
    var count = 0;
    for (var i = 0; i < neighbours.length; ++i) {
        var neighbourName = neighbours[i].name;
        if (neighbourName == entry.name) {
            count = 1;
            break;
        } else if (neighbourName > entry.name) {
            break;
        }
    }
    neighbours.splice(i, count, entry);
}

- (void)removeItem:(Entry)entry // protected
{
    [[entry neighbours] removeObject:entry];
}

- (File)newFileInFolder:(Folder)parentFolder // public
{
    var file = [[File alloc] initWithName:[parentFolder uniqueChildNameWithPrefix:"untitled file"]
                             parentFolder:parentFolder
                                  content:""];
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
        [self changeNameOfItem:entry to:name];
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
    return entries.length == 1 ? [entries[0] description] : "selected " + entries.length + " entries";
}

- (void)deleteItems:(CPArray)entries // public
{
    [self deleteItems:entries byRequestWithMethod:"POST" URL:[self URL]
                 data:{action: "rm", paths: entries.map(function (entry) { return [entry path]; })}];
    [self notify];
}

- (void)duplicateEntries:(CPArray)entries // public
{
    var newEntries = [];
    var pathPairs = [];
    for (var i = 0; i < entries.length; ++i) {
        var entry = entries[i];
        var newEntry = [entry duplicate];
        newEntry.isLoading = YES;
        [self insertItem:newEntry];
        newEntries.push(newEntry);
        pathPairs.push([[entry path], [newEntry path]]);
    }
    [self requestWithMethod:"POST"
                        URL:[self URL]
                       data:{action: "cp", pathPairs: pathPairs}
                   selector:@selector(didDuplicateEntriesTo:)
              errorSelector:@selector(didFailToDuplicateEntriesTo:)
                       args:[newEntries]];
    [self notify];
    [self revealItems:newEntries];
}

- (void)didDuplicateEntriesTo:(CPArray)newEntries // private
{
    newEntries.forEach(function (newEntry) { delete newEntry.isLoading; });
    [self notify];
}

- (void)didFailToDuplicateEntriesTo:(CPArray)newEntries // private
{
    newEntries.forEach(function (newEntry) { [self removeItem:newEntry]; });
    [self notify];
}

- (void)showMoveEntries:(CPArray)entries // public
{
    moveEntries = entries;
    [movePanelController showWindowWithDescription:[self descriptionOfItems:entries]];
}

- (void)moveToPath:(CPString)path // private
{
    var folder;
    var parts = path.split("/");
    if (parts[0] == "." || parts[0] == "..") {
        folder = moveEntries[0].parentFolder;
        for (var i = 1; i < moveEntries.length; ++i) {
            if (moveEntries[i].parentFolder !== folder) {
                [[[Alert alloc] initWithMessage:"The path cannot be relative because the entries are not in the same folder."
                                        comment:"Please specify an absolute path."]
                    showSheetForWindow:[movePanelController window]];
                return;
            }
        }
    } else {
        folder = app.code;
    }
    for (var i = 0; i < parts.length; ++i) {
        var part = parts[i];
        if (!part || part == ".")
            continue;
        folder = part == ".." ? folder.parentFolder : [folder childWithName:part];
        if (![folder isKindOfClass:Folder]) {
            [[[Alert alloc] initWithMessage:"The path \"" + path + "\" is incorrect."
                                    comment:"Please fix the destination folder path."]
                showSheetForWindow:[movePanelController window]];
            return;
        }
    }
    [movePanelController close];
    moveFolder = folder;
    moveEntriesIndex = 0;
    [self move];
}

- (void)move // private
{
    while (moveEntriesIndex < moveEntries.length) {
        var srcEntry = moveEntries[moveEntriesIndex];
        if (srcEntry.parentFolder === moveFolder) {
            moveEntries.splice(moveEntriesIndex, 1);
            continue;
        }
        var dstEntry = [moveFolder childWithName:srcEntry.name];
        if (dstEntry) {
            [replacePanelController showWindowWithDescription:[dstEntry description]];
            return;
        }
        ++moveEntriesIndex;
    }
    if (!moveEntries.length)
        return;
    var dstPathPrefix = [moveFolder path];
    if (dstPathPrefix)
        dstPathPrefix += "/";
    moveEntries.reverse();
    var pathPairs = moveEntries.map(
        function (srcEntry) {
            srcEntry.isLoading = YES;
            return [[srcEntry path], dstPathPrefix + srcEntry.name];
        });
    [self requestWithMethod:"POST"
                        URL:[self URL]
                       data:{action: "mv", pathPairs: pathPairs}
                   selector:@selector(didMoveEntries:toFolder:)
              errorSelector:@selector(didFailToMoveEntries:)
                       args:[moveEntries, moveFolder]];
    [self notify];
    [self revealItems:moveEntries];
}

- (void)moveReplacing // private
{
    ++moveEntriesIndex;
    [self move];
}

- (void)moveSkipping // private
{
    moveEntries.splice(moveEntriesIndex, 1);
    [self move];
}

- (void)didMoveEntries:(CPArray)entries toFolder:(Folder)folder // private
{
    entries.forEach(
        function (entry) {
            delete entry.isLoading;
            [self removeItem:entry];
            [entry setParentFolder:folder];
            [self insertItem:entry];
        });
    [self notify];
    [self revealItems:entries];
}

- (void)didFailToMoveEntries:(CPArray)entries // private
{
    entries.forEach(function (entry) { delete entry.isLoading; });
    [self notify];
}

@end
