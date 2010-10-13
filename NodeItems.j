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

@implementation Entry (NodeItem)

- (BOOL)isEditable
{
    return NO;
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

@implementation CodeItem : DeferredItem
{
    Folder root;
}

- (CPString)name
{
    return "Code";
}

- (CPString)imageName
{
    return "Code";
}

- (BOOL)isReady
{
    return root;
}

- (CPString)url
{
    return [app url] + "code/";
}

- (void)processData:(JSObject)data
{
    root = [[Folder alloc] initWithTree:data];
}

- (unsigned)getNumberOfChildren
{
    return [root numberOfChildren];
}

- (CPString)pathOfItem:(id)item
{
    var parts = [];
    while (item !== self) {
        if (!item)
            return nil;
        parts.unshift(item.name);
        item = [app.outlineView parentForItem:item];
    }
    return parts.join("/");
}

- (CPMethodSignature)methodSignatureForSelector:(SEL)selector
{
    return YES;
}

- (void)forwardInvocation:(CPInvocation)invocation
{
    [invocation setTarget:root];
    [invocation invoke];
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

@implementation App (NodeItemUtils)

- (BOOL)hasEnvWithName:(CPString)aName
{
    var env = [self envWithName:aName];
    if (env)
        [[[Alert alloc] initWithMessage:"The environment \"" + env.name + "\" already exists."
                                comment:"Environment name must be case-insensitively unique."]
            showPanel];
    return !!env;
}

@end

@implementation EnvsItem : DeferredItem

- (CPString)name
{
    return "Environments";
}

- (CPString)imageName
{
    return "Envs";
}

- (BOOL)isReady
{
    return app.envs;
}

- (CPString)url
{
    return [app url] + "envs/";
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

- (CPString)imageName
{
    return "Libs";
}

- (BOOL)isReady
{
    return app.libs;
}

- (CPString)url
{
    return [app url] + "code/manifest.json";
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

@implementation EditableItem : SmartItem
{
    CPString name @accessors(readonly);
}

- (id)initWithApp:(App)anApp name:(CPString)aName
{
    if (self = [super initWithApp:anApp])
        name = aName;
    return self;
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

- (void)submit:(CPTextField)sender
{
    isLoading = YES;
    [sender removeFromSuperview];
    var outlineView = app.outlineView;
    [self doSubmit:sender];
    [outlineView reloadItem:self];
}

@end

@implementation NewEntryItem : EditableItem

- (BOOL)isExpandable
{
    return NO;
}

- (id)parentFolder
{
    return [app.outlineView parentForItem:self];
}

- (void)doSubmit:(CPTextField)sender
{
    var newName = [sender stringValue];
    if (newName) {
        if (newName.indexOf("/") != -1) {
            [[[Alert alloc] initWithMessage:"File name cannot contain slashes." comment:"Please choose another name."] showPanel];
        } else {
            var initialName = name;
            name = "";
            name = [[self parentFolder] hasChildWithName:newName] ? initialName : newName;
        }
    }
    [self sendRequest];
}

- (void)removeSelf
{
    var parentFolder = [self parentFolder];
    [parentFolder removeFile:self];
    [app.outlineView reloadItem:parentFolder reloadChildren:YES];
}

@end

@implementation NewFileItem : NewEntryItem

- (CPString)imageName
{
    return "File";
}

- (void)sendRequest
{
    var request = [[HTTPRequest alloc] initWithMethod:"PUT"
                                                  URL:[app url] + "code/" + [app.code pathOfItem:self]
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

- (CPString)imageName
{
    return "Folder";
}

- (void)sendRequest
{
    var request = [[HTTPRequest alloc] initWithMethod:"POST"
                                                  URL:[app url] + "code/"
                                               target:self
                                               action:@selector(didReceiveResponse)];
    [request setErrorAction:@selector(removeSelf)];
    [request send:{action: "mkdir", path: [app.code pathOfItem:self]}];
}

- (void)didReceiveResponse
{
    var parentFolder = [self parentFolder];
    [parentFolder removeFolder:self];
    var folder = [[Folder alloc] initWithName:name];
    [parentFolder addFolder:folder];
    [app.outlineView revealChildItem:folder ofItem:parentFolder];
    [app.outlineView expandItem:folder];
}

@end

@implementation NewEnvItem : EditableItem

- (BOOL)isExpandable
{
    return NO;
}

- (CPString)imageName
{
    return "Env";
}

- (void)doSubmit:(CPTextField)sender
{
    var newName = [sender stringValue];
    if (newName) {
        var initialName = name;
        name = "";
        name = [app hasEnvWithName:newName] ? initialName : newName;
    }
    var request = [[HTTPRequest alloc] initWithMethod:"POST"
                                                  URL:[app url] + "envs/"
                                               target:self
                                               action:@selector(didReceiveResponse)];
    [request setErrorAction:@selector(removeSelf)];
    [request send:{name: name}];
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

@implementation RenameItem : EditableItem
{
    Class oldIsa;
    CPString initialName;
}

+ (void)stealItem:(id)item withApp:(App)app
{
    item.oldIsa = item.isa;
    item.isa = self;
    item.isLoading = nil;
    item.app = app;
    item.initialName = item.name;
}

- (void)restore
{
    isa = oldIsa;
    delete self.oldIsa;
    delete self.isLoading;
    delete self.app;
    delete self.initialName;
}

- (void)doSubmit:(CPTextField)sender
{
    var newName = [sender stringValue];
    if (newName && newName != name)
        [self rename:newName];
    else
        [self restore];
}

- (void)didReceiveError
{
    name = initialName;
    var outlineView = app.outlineView;
    [self restore];
    [outlineView reloadItem:self];
}

- (void)didReceiveResponse
{
    var outlineView = app.outlineView;
    var parentItem = [outlineView parentForItem:self];
    [self refresh];
    [self restore];
    [outlineView revealChildItem:self ofItem:parentItem];
}

- (void)requestWithMethod:(CPString)method URL:(CPString)url data:(JSObject)data
{
    var request = [[HTTPRequest alloc] initWithMethod:method URL:url target:self action:@selector(didReceiveResponse)];
    [request setErrorAction:@selector(didReceiveError)];
    [request send:data];
}

@end

@implementation RenameEntryItem : RenameItem

- (void)rename:(CPString)newName
{
    if ([[app.outlineView parentForItem:self] hasChildWithName:newName]) {
        [self restore];
        return;
    }
    var oldPath = [app.code pathOfItem:self];
    name = newName;
    var newPath = [app.code pathOfItem:self];
    [self requestWithMethod:"POST" URL:[app url] + "code/" data:{action: "mv", pathPairs: [[oldPath, newPath]]}];
}

@end

@implementation RenameFileItem : RenameEntryItem

- (BOOL)isExpandable
{
    return NO;
}

- (CPString)imageName
{
    return "File";
}

- (void)refresh
{
    var parentFolder = [app.outlineView parentForItem:self];
    [parentFolder removeFile:self];
    [parentFolder addFile:self];
}

@end

@implementation RenameFolderItem : RenameEntryItem

- (BOOL)isExpandable
{
    return YES;
}

- (CPString)imageName
{
    return "Folder";
}

- (void)refresh
{
    var parentFolder = [app.outlineView parentForItem:self];
    [parentFolder removeFolder:self];
    [parentFolder addFolder:self];
}

@end

@implementation RenameEnvItem : RenameItem

- (BOOL)isExpandable
{
    return NO;
}

- (CPString)imageName
{
    return "Env";
}

- (void)rename:(CPString)newName
{
    if ([app hasEnvWithName:newName]) {
        [self restore];
        return;
    }
    name = newName;
    [self requestWithMethod:"POST" URL:[app url] + "envs/" + initialName data:{action: "rename", name: name}];
}

- (void)refresh
{
    [app removeEnv:self];
    [app addEnv:self];
}

@end

@implementation RenameLibItem : RenameItem

- (BOOL)isExpandable
{
    return YES;
}

- (CPString)imageName
{
    return "Lib";
}

- (void)rename:(CPString)newName
{
    if ([app libWithName:newName]) {
        [[[Alert alloc] initWithMessage:"The alias \"" + newName + "\" is already taken."
                                comment:"Please choose another alias."]
            showPanel];
        [self restore];
        return;
    }
    var file = [app.code fileWithName:"manifest.json"];
    var manifest = JSON.parse(file.content);
    manifest.libs[newName] = manifest.libs[name];
    delete manifest.libs[name];
    name = newName;
    [file setContent:JSON.stringify(manifest, null, "  ")];
    var request = [[HTTPRequest alloc] initWithMethod:"PUT"
                                                  URL:[app url] + "code/manifest.json"
                                               target:self
                                               action:@selector(didReceiveResponse)];
    [request setErrorAction:@selector(didReceiveError)];
    [request setValue:"application/json" forHeader:"Content-Type"];
    [request send:file.content];
}

- (void)restore
{
    isLoading = NO;
    isa = oldIsa;
    delete self.oldIsa;
    delete self.initialName;
}

- (void)refresh
{
    [app removeLib:self];
    [app addLib:self];
}

@end
