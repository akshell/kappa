// (c) 2010 by Anton Korenyushkin

@import "BaseEntityManager.j"
@import "BufferManager.j"
@import "MovePanelController.j"
@import "ReplacePanelController.j"
@import "Alert.j"

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
    return "File";
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
                              content:content];
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
                                                                                         content:file.content]; })];
}

- (CPArray)entriesFromTree:(JSObject)tree
                 withNames:(CPArray)names
                oldEntries:(CPArray)oldEntries
                entryClass:(Class)entryClass
              initSelector:(SEL)initSelector
              syncSelector:(SEL)syncSelector // private
{
    names.sort();
    var newEntries = [];
    var j = 0;
    for (var i = 0; i < names.length; ++i) {
        while (j < oldEntries.length && oldEntries[j].name < names[i])
            [oldEntries[j++] noteDeleted];
        var arg = tree[names[i]] || nil;
        if (j < oldEntries.length && oldEntries[j].name == names[i]) {
            objj_msgSend(oldEntries[j], syncSelector, arg);
            newEntries.push(oldEntries[j++]);
        } else {
            newEntries.push(objj_msgSend([entryClass alloc], initSelector, names[i], self, arg));
        }
    }
    while (j < oldEntries.length)
        [oldEntries[j++] noteDeleted];
    return newEntries;
};

- (void)syncWithTree:(JSObject)tree // public
{
    var folderNames = [];
    var fileNames = [];
    for (var childName in tree)
        (tree[childName] ? folderNames : fileNames).push(childName);
    folders = [self entriesFromTree:tree
                          withNames:folderNames
                         oldEntries:folders
                         entryClass:Folder
                       initSelector:@selector(initWithName:parentFolder:tree:)
                       syncSelector:@selector(syncWithTree:)];
    files = [self entriesFromTree:tree
                        withNames:fileNames
                       oldEntries:files
                       entryClass:File
                     initSelector:@selector(initWithName:parentFolder:content:)
                     syncSelector:@selector(setContent:)];
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

@implementation CodeManager : BaseEntityManager
{
    BufferManager bufferManager;
    MovePanelController movePanelController;
    ReplacePanelController replacePanelController;
    CPArray moveEntries;
    unsigned moveEntriesIndex;
    Folder moveFolder;
}

- (id)initWithApp:(App)anApp bufferManager:(BufferManager)aBufferManager// public
{
    if (self = [super initWithApp:anApp keyName:"code"]) {
        bufferManager = aBufferManager;
        movePanelController = [[MovePanelController alloc] initWithTarget:self action:@selector(moveToPath:)];
        replacePanelController = [[ReplacePanelController alloc] initWithTarget:self
                                                                  replaceAction:@selector(moveReplacing)
                                                                     skipAction:@selector(moveSkipping)];
        [self load];
    }
    return self;
}

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
    if (app.code) {
        [app.code syncWithTree:tree];
        [self notify];
    } else {
        [app setCode:[[Folder alloc] initWithTree:tree]];
    }
}

- (void)insertItem:(Entry)entry // protected
{
    var neighbours = [entry neighbours];
    for (var i = 0; i < neighbours.length; ++i) {
        var neighbour = neighbours[i];
        if (neighbour.name > entry.name)
            break;
        if (neighbour.name == entry.name) {
            neighbours.splice(i, 1, entry);
            [neighbour noteDeleted];
            return;
        }
    }
    neighbours.splice(i, 0, entry);
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
    if (name && name != entry.name && entryNameIsCorrect(name) && ![entry.parentFolder hasChildWithName:name])
        [self changeNameOfItem:entry to:name];
    if ([entry isKindOfClass:File])
        [self createItem:entry byRequestWithMethod:"PUT" URL:[self URL] + [entry path] data:""];
    else
        [self createItem:entry byRequestWithMethod:"POST" URL:[self URL] data:{action: "mkdir", path: [entry path]}];
}

- (void)didCreateItem:(Entry)entry // protected
{
    [super didCreateItem:entry];
    if ([entry isKindOfClass:File] && entry.content !== nil)
        [bufferManager openBuffer:[[CodeFileBuffer alloc] initWithFile:entry]];
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
    moveFolder = folder;
    for (; folder.parentFolder; folder = folder.parentFolder) {
        if (moveEntries.indexOf(folder) != -1) {
            [[[Alert alloc] initWithMessage:"The " + [folder description] + " cannot be moved into itself."
                                    comment:"Please correct the move operation."]
                showSheetForWindow:[movePanelController window]];
            return;
        }
    }
    [movePanelController close];
    moveEntriesIndex = 0;
    [self move];
}

- (void)moveEntries:(CPArray)entries toFolder:(Folder)folder // public
{
    moveEntries = entries;
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

- (void)uploadDOMFile:(DOMFile)domFile toFolder:(Folder)folder // public
{
    for (var i = 0; i < folder.files.length; ++i) {
        var neighbour = folder.files[i];
        if (neighbour.name > domFile.name)
            break;
        if (neighbour.name == domFile.name) {
            [[[Alert alloc] initWithMessage:"The entry \"" + domFile.name + "\" already exists."
                                    comment:"Please rename or delete it before upload."]
                showPanel];
            return;
        }
    }
    var file = [[File alloc] initWithName:domFile.name parentFolder:folder];
    folder.files.splice(i, 0, file);
    file.isLoading = YES;
    [self notify];
    [self requestWithMethod:"PUT"
                        URL:[self URL] + [file path]
                       data:domFile
                   selector:@selector(didCreateItem:)
              errorSelector:@selector(didFailToCreateItem:)
                       args:[file]];
}

@end
