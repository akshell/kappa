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
    CPArray invocations;
}

- (id)initWithApp:(App)anApp
{
    if (self = [super initWithApp:anApp])
        invocations = [];
    return self;
}

- (BOOL)isExpandable
{
    return YES;
}

- (BOOL)isEditable
{
    return NO;
}

- (void)doLoad
{
    if (isLoading)
        return;
    isLoading = YES;
    var request = [[HTTPRequest alloc] initWithMethod:"GET" URL:[self url] target:self action:@selector(didReceiveResponse:)];
    [request setErrorAction:@selector(didReceiveError)];
    [request send];
}

- (void)load
{
    if (![self isReady])
        [self doLoad];
}

- (void)loadWithTarget:(id)target action:(SEL)action context:(JSObject)context
{
    if ([self isReady]) {
        objj_msgSend(target, action, context);
        return;
    }
    var invocation = [CPInvocation invocationWithMethodSignature:nil];
    [invocation setTarget:target];
    [invocation setSelector:action];
    [invocation setArgument:context atIndex:2];
    invocations.push(invocation);
    [self doLoad];
    [app.outlineView reloadItem:self];
}

- (void)loadWithTarget:(id)aTarget action:(SEL)anAction
{
    [self loadWithTarget:aTarget action:anAction context:nil];
}

- (unsigned)numberOfChildren
{
    if ([self isReady])
        return [self getNumberOfChildren];
    [self doLoad];
    return 0;
}

- (void)didReceiveResponse:(JSObject)data
{
    [self processData:data];
    isLoading = NO;
    setTimeout(
        function () {
            [app.outlineView reloadItem:self reloadChildren:YES];
            invocations.forEach(function (invocation) { [invocation invoke]; });
            invocations = [];
        },
        0);
}

- (void)didReceiveError
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

@implementation CodeItem : DeferredItem
{
    Folder root;
}

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
    return root;
}

- (CPString)url
{
    return "/apps/" + app.name + "/code/";
}

- (void)processData:(JSObject)data
{
    root = [[Folder alloc] initWithTree:data];
}

- (unsigned)getNumberOfChildren
{
    return [root numberOfChildren];
}

- (id)forward:(SEL)selector :(marg_list)args
{
    var newArgs = [root, selector];
    for (var i = 2; i < args.length; ++i)
        newArgs.push(args[i]);
    return objj_msgSend.apply(objj_msgSend, newArgs);
}

@end

@implementation Env (NodeItem)

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

+ (CPString)identifierForAuthorName:(CPString)authorName appName:(CPString)appName version:(CPString)version
{
    return authorName + "/" + appName + ":" + version;
}

- (id)initWithApp:(App)anApp
             name:(CPString)aName
       authorName:(CPString)anAuthorName
          appName:(CPString)anAppName
          version:(CPString)aVersion
{
    if (self = [super initWithApp:anApp]) {
        name = aName;
        authorName = anAuthorName;
        appName = anAppName;
        version = aVersion;
        identifier = [LibItem identifierForAuthorName:authorName appName:appName version:version];
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
    DATA.libs[identifier] = [[Folder alloc] initWithTree:data];
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
    return app.libs;
}

- (CPString)url
{
    return "/apps/" + app.name + "/code/manifest.json";
}

- (void)processData:(CPString)data
{
    [app.code loadWithTarget:self action:@selector(setManifest:) context:data];
    [app setLibs:[]];
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
            [app addLib:[[LibItem alloc] initWithApp:app name:name identifier:identifier]];
    }
}

- (void)setManifest:(CPString)data
{
    [[app.code fileWithName:"manifest.json"] setContent:data];
}

- (BOOL)didReceiveError
{
    isLoading = NO;
    [app setLibs:[]];
    setTimeout(function () { [app.outlineView reloadItem:self]; }, 0);
    return YES;
}

- (unsigned)getNumberOfChildren
{
    return app.libs.length;
}

- (id)childAtIndex:(unsigned)index
{
    return app.libs[index];
}

@end

@implementation NewItem : SmartItem
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

@end

@implementation NewEntryItem : NewItem

- (id)parentFolder
{
    return [app.outlineView parentForItem:self];
}

- (void)submit:(CPTextField)sender
{
    isLoading = YES;
    [sender removeFromSuperview];
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
    [app.outlineView reloadItem:self];
    [self doSubmit];
}

- (void)removeSelf
{
    var parentFolder = [self parentFolder];
    [parentFolder removeFile:self];
    [app.outlineView reloadItem:parentFolder reloadChildren:YES];
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
    var parentFolder = [self parentFolder];
    [parentFolder removeFile:self];
    var file = [[File alloc] initWithName:name];
    [parentFolder addFile:file];
    [app.outlineView revealChildItem:file ofItem:parentFolder];
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
    var parentFolder = [self parentFolder];
    [parentFolder removeFolder:self];
    var folder = [[Folder alloc] initWithName:name];
    [parentFolder addFolder:folder];
    [app.outlineView revealChildItem:folder ofItem:parentFolder];
}

@end

@implementation NewEnvItem : NewItem

- (CPString)getImageName
{
    return "Env";
}

- (void)submit:(CPTextField)sender
{
    isLoading = YES;
    [sender removeFromSuperview];
    var newName = [sender stringValue];
    if (newName) {
        var initialName = name;
        name = "";
        if ([app hasEnvWithName:newName]) {
            [[[Alert alloc] initWithMessage:"The environment with the name \"" + newName.toLowerCase() + "\" already exists."
                                    comment:"Environment name must be case-insensitively unique."]
                showPanel];
            name = initialName;
        } else {
            name = newName;
        }
    }
    var request = [[HTTPRequest alloc] initWithMethod:"POST"
                                                  URL:"/apps/" + app.name + "/envs/"
                                               target:self
                                               action:@selector(didReceiveResponse)];
    [request setErrorAction:@selector(removeSelf)];
    [request send:{name: name}];
    [app.outlineView reloadItem:self];
}

- (void)didReceiveResponse
{
    [app removeEnv:self];
    var env = [[Env alloc] initWithName:name];
    [app addEnv:env];
    [app.outlineView revealChildItem:env ofItem:app.envsItem];
}

- (void)removeSelf
{
    [app removeEnv:self];
    [app.outlineView reloadItem:app.envsItem reloadChildren:YES];
}

@end
