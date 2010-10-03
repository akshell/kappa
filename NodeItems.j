// (c) 2010 by Anton Korenyushkin

@import "HTTPRequest.j"

@implementation NodeItem : CPObject
{
    CPString title @accessors(readonly);
    CPString imageName @accessors(readonly);
    CPArray children @accessors(readonly);
}

- (id)initWithTitle:(CPString)aTitle imageName:(CPString)anImageName children:(CPArray)items
{
    if (self = [super init]) {
        title = aTitle;
        imageName = anImageName;
        children = items;
    }
    return self;
}

- (id)initWithTitle:(CPString)aTitle imageName:(CPString)anImageName
{
    return [self initWithTitle:aTitle imageName:anImageName children:nil];
}

- (BOOL)hasChildren
{
    return children;
}

@end

@implementation DeferredNodeItem : NodeItem
{
    CPOutlineView outlineView;
    BOOL isLoading;
}

- (id)initWithTitle:(CPString)aTitle imageName:(CPString)anImageName outlineView:(CPOutlineView)anOutlineView
{
    if (self = [super initWithTitle:aTitle imageName:anImageName])
        outlineView = anOutlineView;
    return self;
}

- (CPString)imageName
{
    return isLoading ? "Spinner" : imageName;
}

- (BOOL)hasChildren
{
    return YES;
}

- (CPArray)children
{
    if (children)
        return children;
    if (isLoading)
        return [];
    [self loadChildren];
    if (children)
        return children;
    isLoading = YES;
    var request = [[HTTPRequest alloc] initWithMethod:"GET" URL:[self url] target:self action:@selector(didReceiveResponse:)];
    [request setErrorAction:@selector(didEndRequestErrorPanel)];
    [request send];
    return [];
}

- (void)didReceiveResponse:(JSObject)data
{
    [self processData:data];
    [self loadChildren];
    isLoading = NO;
    setTimeout(function () { [outlineView reloadItem:self reloadChildren:YES]; }, 0);
}

- (void)didEndRequestErrorPanel
{
    children = [];
    isLoading = NO;
    setTimeout(function () { [outlineView reloadItem:self reloadChildren:NO]; }, 0);
}

@end

var traverse = function (tree) {
    var folderNames = [];
    var fileNames = [];
    for (var name in tree)
        (tree[name] ? folderNames : fileNames).push(name);
    folderNames.sort();
    fileNames.sort();
    var items = [];
    folderNames.forEach(
        function (name) {
            items.push([[NodeItem alloc] initWithTitle:name imageName:"Folder" children:traverse(tree[name])]);
        });
    fileNames.forEach(
        function (name) {
            items.push([[NodeItem alloc] initWithTitle:name imageName:"File"]);
        });
    return items;
};

@implementation CodeNodeItem : DeferredNodeItem
{
    JSObject app;
}

- (id)initWithOutlineView:(CPOutlineView)anOutlineView app:(JSObject)anApp
{
    if (self = [super initWithTitle:"Code" imageName:"Code" outlineView:anOutlineView])
        app = anApp;
    return self;
}

- (CPString)url
{
    return "/apps/" + app.name + "/code/";
}

- (void)loadChildren
{
    if (app.tree)
        children = traverse(app.tree);
}

- (void)processData:(JSObject)data
{
    app.tree = data;
}

@end

@implementation EnvsNodeItem : DeferredNodeItem
{
    JSObject app;
}

- (id)initWithOutlineView:(CPOutlineView)anOutlineView app:(JSObject)anApp
{
    if (self = [super initWithTitle:"Environments" imageName:"Envs" outlineView:anOutlineView])
        app = anApp;
    return self;
}

- (CPString)url
{
    return "/apps/" + app.name + "/envs/";
}

- (void)loadChildren
{
    if (app.envs)
        children = [[[NodeItem alloc] initWithTitle:"release" imageName:"Env"]].concat(
            app.envs.map(function (name) { return [[NodeItem alloc] initWithTitle:name imageName:"Env"]; }));
}

- (void)processData:(CPArray)data
{
    app.envs = data;
}

@end

@implementation LibNodeItem : DeferredNodeItem
{
    CPString id;
    CPString author;
    CPString name;
    CPString version;
}

- (id)initWithTitle:(CPString)aTitle outlineView:(CPOutlineView)anOutlineView id:(CPString)anId
{
    if (self = [super initWithTitle:aTitle imageName:"Lib" outlineView:anOutlineView]) {
        id = anId;
        var slashIndex = id.indexOf("/");
        var colonIndex = id.indexOf(":", slashIndex + 1);
        if (slashIndex != -1 && colonIndex != -1) {
            author = id.substring(0, slashIndex);
            name = id.substring(slashIndex + 1, colonIndex);
            version = id.substring(colonIndex + 1);
        };
    }
    return self;
}

- (BOOL)hasChildren
{
    return author && name && version;
}

- (CPString)url
{
    return "/libs/" + author + "/" + name + "/" + version + "/";
}

- (void)loadChildren
{
    var tree = DATA.libs[id];
    if (tree)
        children = traverse(tree);
}

- (void)processData:(CPArray)data
{
    DATA.libs[id] = data;
}

@end

@implementation LibsNodeItem : DeferredNodeItem
{
    JSObject app;
}

- (id)initWithOutlineView:(CPOutlineView)anOutlineView app:(JSObject)anApp
{
    if (self = [super initWithTitle:"Libraries" imageName:"Libs" outlineView:anOutlineView])
        app = anApp;
    return self;
}

- (CPString)url
{
    return "/apps/" + app.name + "/code/manifest.json";
}

- (void)loadChildren
{
    if (app.libs) {
        children = [];
        for (var alias in app.libs)
            children.push([[LibNodeItem alloc] initWithTitle:alias outlineView:outlineView id:app.libs[alias]]);
    }
}

- (void)processData:(CPArray)data
{
    app.libs = {};
    try {
        data = JSON.parse(data);
    } catch (error) {
        return;
    }
    if (!data.libs || typeof(data.libs) != "object")
        return;
    for (var alias in data.libs) {
        var id = data.libs[alias];
        if (typeof(id) == "string")
            app.libs[alias] = id;
    }
}

@end
