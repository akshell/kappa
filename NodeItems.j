// (c) 2010 by Anton Korenyushkin

@import "HTTPRequest.j"
@import "Data.j"

@implementation SmartItem : CPObject
{
    App app;
    BOOL isLoading;
}

- (id)initWithApp:(App)anApp
{
    if (self = [super init])
        app = anApp
    return self;
}

- (CPString)imageName
{
    return isLoading ? "Spinner" : [self getImageName];
}

@end

@implementation DeferredItem : SmartItem
{
    id target;
    SEL action;
    JSObject context;
}

- (BOOL)isExpandable
{
    return YES;
}

- (BOOL)isEditable
{
    return NO;
}

- (void)load
{
    if (isLoading)
        return;
    isLoading = YES;
    var request = [[HTTPRequest alloc] initWithMethod:"GET" URL:[self url] target:self action:@selector(didReceiveResponse:)];
    [request setErrorAction:@selector(didEndRequestErrorPanel)];
    [request send];
}

- (void)loadWithTarget:(id)aTarget action:(SEL)anAction context:(JSObject)aContext
{
    if ([self isReady]) {
        objj_msgSend(aTarget, anAction, aContext);
        return;
    }
    target = aTarget;
    action = anAction;
    context = aContext;
    [self load];
    [app.outlineView reloadItem:self];
}

- (unsigned)numberOfChildren
{
    if ([self isReady])
        return [self getNumberOfChildren];
    [self load];
    return 0;
}

- (void)didReceiveResponse:(JSObject)data
{
    [self processData:data];
    isLoading = NO;
    setTimeout(
        function () {
            [app.outlineView reloadItem:self reloadChildren:YES];
            objj_msgSend(target, action, context);
            target = nil;
        },
        0);
}

- (void)didEndRequestErrorPanel
{
    isLoading = NO;
    setTimeout(function () { [app.outlineView collapseItem:self]; }, 0);
}

@end

@implementation File (NodeItem)

- (BOOL)isExpandable
{
    return NO;
}

- (BOOL)isEditable
{
    return NO;
}

- (CPString)imageName
{
    return "File";
}

@end

@implementation Folder (NodeItem)

- (BOOL)isExpandable
{
    return YES;
}

- (BOOL)isEditable
{
    return NO;
}

- (CPString)imageName
{
    return "Folder";
}

- (unsigned)numberOfChildren
{
    return folders.length + files.length;
}

- (id)childAtIndex:(unsigned)index
{
    return index < folders.length ? folders[index] : files[index - folders.length];
}

@end

var traverse = function (name, tree) {
    var folderNames = [];
    var fileNames = [];
    for (var childName in tree)
        (tree[childName] ? folderNames : fileNames).push(childName);
    folderNames.sort();
    fileNames.sort();
    return [[Folder alloc] initWithName:name
                                folders:folderNames.map(function (folderName) { return traverse(folderName, tree[folderName]); })
                                  files:fileNames.map(function (fileName) { return [[File alloc] initWithName:fileName]; })];
};

@implementation CodeItem : DeferredItem

- (CPString)name
{
    return "Code";
}

- (CPString)getImageName
{
    return "Code";
}

- (BOOL)isReady
{
    return app.code;
}

- (CPString)url
{
    return "/apps/" + app.name + "/code/";
}

- (void)processData:(JSObject)data
{
    [app setCode:traverse('', data)];
}

- (unsigned)getNumberOfChildren
{
    return [app.code numberOfChildren];
}

- (id)childAtIndex:(unsigned)index
{
    return [app.code childAtIndex:index];
}

@end

@implementation Env (NodeItem)

- (BOOL)isExpandable
{
    return NO;
}

- (CPString)imageName
{
    return "Env";
}

@end

@implementation EnvsItem : DeferredItem

- (CPString)name
{
    return "Environments";
}

- (CPString)getImageName
{
    return "Envs";
}

- (BOOL)isReady
{
    return app.envs;
}

- (CPString)url
{
    return "/apps/" + app.name + "/envs/";
}

- (void)processData:(CPArray)data
{
    [app setEnvs:[[[Env alloc] initWithName:"release"]].concat(
            data.map(function (name) { return [[Env alloc] initWithName:name]; }))];
}

- (unsigned)getNumberOfChildren
{
    return app.envs.length;
}

- (id)childAtIndex:(unsigned)index
{
    return app.envs[index];
}

@end

@implementation LibItem : DeferredItem
{
    CPString name @accessors(readonly);
    CPString identifier;
    CPString authorName;
    CPString appName;
    CPString version;
}

- (id)initWithApp:(App)anApp name:(CPString)aName identifier:(CPString)anIdentifier
{
    if (self = [super initWithApp:anApp]) {
        name = aName;
        identifier = anIdentifier;
        var slashIndex = identifier.indexOf("/");
        var colonIndex = identifier.indexOf(":", slashIndex + 1);
        if (slashIndex != -1 && colonIndex != -1) {
            authorName = identifier.substring(0, slashIndex);
            appName = identifier.substring(slashIndex + 1, colonIndex);
            version = identifier.substring(colonIndex + 1);
        }
    }
    return self;
}

- (BOOL)isExpandable
{
    return authorName && appName && version;
}

- (CPString)imageName
{
    return "Lib";
}

- (BOOL)isReady
{
    return DATA.libs.hasOwnProperty(identifier);
}

- (CPString)url
{
    return "/libs/" + authorName + "/" + appName + "/" + version + "/";
}

- (void)processData:(JSObject)data
{
    DATA.libs[identifier] = traverse('', data);
}

- (unsigned)getNumberOfChildren
{
    return [DATA.libs[identifier] numberOfChildren];
}

- (id)childAtIndex:(unsigned)index
{
    return [DATA.libs[identifier] childAtIndex:index];
}

@end

@implementation LibsItem : DeferredItem

- (CPString)name
{
    return "Libraries";
}

- (CPString)getImageName
{
    return "Libs";
}

- (BOOL)isReady
{
    return app.libItems;
}

- (CPString)url
{
    return "/apps/" + app.name + "/code/manifest.json";
}

- (void)processData:(CPString)data
{
    app.libItems = [];
    try {
        data = JSON.parse(data);
    } catch (error) {
        return;
    }
    if (!data.libs || typeof(data.libs) != "object")
        return;
    for (var name in data.libs) {
        var identifier = data.libs[name];
        if (typeof(identifier) == "string")
            app.libItems.push([[LibItem alloc] initWithApp:app name:name identifier:identifier]);
    }
}

- (unsigned)getNumberOfChildren
{
    return app.libItems.length;
}

- (id)childAtIndex:(unsigned)index
{
    return app.libItems[index];
}

@end

@implementation NewEntryItem : SmartItem
{
    CPString name @accessors(readonly);
}

- (id)initWithApp:(App)anApp name:(CPString)aName
{
    if (self = [super initWithApp:anApp])
        name = aName;
    return self;
}

- (BOOL)isExpandable
{
    return NO;
}

- (BOOL)isEditable
{
    return !isLoading;
}

- (void)controlTextDidBlur:(CPNotification)notification
{
    if (!isLoading)
        [self submit:[notification object]];
}

- (id)parentItem
{
    return [app.outlineView parentForItem:self];
}

- (id)parentFolder
{
    var parentItem = [self parentItem];
    return [parentItem isKindOfClass:Folder] ? parentItem : app.code;
}

- (void)submit:(CPTextField)sender
{
    isLoading = YES;
    var newName = [sender stringValue];
    if (newName) {
        if (newName.indexOf("/") != -1) {
            [[[Alert alloc] initWithMessage:"File name cannot contain slashes." comment:"Please choose another name."] showPanel];
        } else {
            var initialName = name;
            name = "";
            if ([[self parentFolder] hasChildWithName:newName]) {
                [[[Alert alloc] initWithMessage:"The entry \"" + newName + "\" already exists."
                                        comment:"Please choose another name."]
                    showPanel];
                name = initialName;
            } else {
                name = newName;
            }
        }
    }
    [sender removeFromSuperview];
    [app.outlineView reloadItem:self reloadChildren:NO];
    [self doSubmit];
}

- (void)removeSelf
{
    [[self parentFolder] removeFile:self];
    [app.outlineView reloadItem:[self parentItem] reloadChildren:YES];
}

- (CPString)path
{
    var parts = [];
    var item = self;
    do {
        parts.unshift(item.name);
        item = [app.outlineView parentForItem:item];
    } while ([item isKindOfClass:Folder]);
    return parts.join("/");
}

@end

@implementation NewFileItem : NewEntryItem

- (CPString)getImageName
{
    return "File";
}

- (void)doSubmit
{
    var request = [[HTTPRequest alloc] initWithMethod:"PUT"
                                                  URL:"/apps/" + app.name + "/code/" + [self path]
                                               target:self
                                               action:@selector(didReceiveResponse)];
    [request setErrorAction:@selector(removeSelf)];
    [request send:""];
}

- (void)didReceiveResponse
{
    var parentItem = [self parentItem];
    var parentFolder = [self parentFolder];
    [parentFolder removeFile:self];
    var file = [[File alloc] initWithName:name];
    [parentFolder addFile:file];
    [app.outlineView reloadItem:parentItem reloadChildren:YES];
    [app.outlineView selectRowIndexes:[CPIndexSet indexSetWithIndex:[app.outlineView rowForItem:file]]
                 byExtendingSelection:NO];
}

@end

@implementation NewFolderItem : NewEntryItem

- (CPString)getImageName
{
    return "Folder";
}

- (void)doSubmit
{
    var request = [[HTTPRequest alloc] initWithMethod:"POST"
                                                  URL:"/apps/" + app.name + "/code/"
                                               target:self
                                               action:@selector(didReceiveResponse)];
    [request setErrorAction:@selector(removeSelf)];
    [request send:{action: "mkdir", path: [self path]}];
}

- (void)didReceiveResponse
{
    var parentItem = [self parentItem];
    var parentFolder = [self parentFolder];
    [parentFolder removeFolder:self];
    var folder = [[Folder alloc] initWithName:name];
    [parentFolder addFolder:folder];
    [app.outlineView reloadItem:parentItem reloadChildren:YES];
    [app.outlineView expandItem:folder];
    [app.outlineView selectRowIndexes:[CPIndexSet indexSetWithIndex:[app.outlineView rowForItem:folder]]
                 byExtendingSelection:NO];
}

@end
