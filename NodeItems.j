// (c) 2010 by Anton Korenyushkin

@import "HTTPRequest.j"
@import "Data.j"

@implementation DeferredItem : CPObject
{
    CPOutlineView outlineView;
    BOOL isLoading;
}

- (id)initWithOutlineView:(CPOutlineView)anOutlineView
{
    if (self = [super init])
        outlineView = anOutlineView;
    return self;
}

- (BOOL)isExpandable
{
    return YES;
}

- (CPString)imageName
{
    return isLoading ? "Spinner" : [self getImageName];
}

- (unsigned)numberOfChildren
{
    if ([self isReady])
        return [self getNumberOfChildren];
    isLoading = YES;
    var request = [[HTTPRequest alloc] initWithMethod:"GET" URL:[self url] target:self action:@selector(didReceiveResponse:)];
    [request setErrorAction:@selector(didEndRequestErrorPanel)];
    [request send];
    return 0;
}

- (void)didReceiveResponse:(JSObject)data
{
    [self processData:data];
    isLoading = NO;
    setTimeout(function () { [outlineView reloadItem:self reloadChildren:YES]; }, 0);
}

- (void)didEndRequestErrorPanel
{
    isLoading = NO;
    setTimeout(function () { [outlineView collapseItem:self]; }, 0);
}

@end

@implementation File (NodeItem)

- (BOOL)isExpandable
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

@implementation AppDeferredItem : DeferredItem
{
    App app;
}

- (id)initWithOutlineView:(CPOutlineView)anOutlineView app:(App)anApp
{
    if (self = [super initWithOutlineView:anOutlineView])
        app = anApp;
    return self;
}

@end

@implementation CodeItem : AppDeferredItem

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

@implementation EnvsItem : AppDeferredItem

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

- (id)initWithOutlineView:(CPOutlineView)anOutlineView name:(CPString)aName identifier:(CPString)anIdentifier
{
    if (self = [super initWithOutlineView:anOutlineView]) {
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

@implementation LibsItem : AppDeferredItem

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
    return app.cache.libItems;
}

- (CPString)url
{
    return "/apps/" + app.name + "/code/manifest.json";
}

- (void)processData:(CPString)data
{
    app.cache.libItems = [];
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
            app.cache.libItems.push([[LibItem alloc] initWithOutlineView:outlineView name:name identifier:identifier]);
    }
}

- (unsigned)getNumberOfChildren
{
    return app.cache.libItems.length;
}

- (id)childAtIndex:(unsigned)index
{
    return app.cache.libItems[index];
}

@end
