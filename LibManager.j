// (c) 2010 by Anton Korenyushkin

@import "BaseEntityManager.j"
@import "FileHandling.j"
@import "UseLibPanelController.j"

var libCode = {};

@implementation Lib (LibManager)

- (CPString)imageName // public
{
    return "Lib";
}

- (BOOL)isExpandable // public
{
    return !self.isBad;
}

- (unsigned)numberOfChildren // public
{
    if (libCode.hasOwnProperty(identifier))
        return [libCode[identifier] numberOfChildren];
    if (authorName && appName && version) {
        self.isLoading = YES;
        var request = [[HTTPRequest alloc] initWithMethod:"GET" URL:[self URL] target:self action:@selector(didLoadTree:)];
        [request setErrorAction:@selector(didFailToLoadTree)];
        [request send];
    } else {
        self.isBad = YES;
        [[[Alert alloc] initWithMessage:"The description of the \"" + name + "\" library is incorrect."
                                comment:"Please fix the \"manifest.json\" file."]
            showPanel];
        [manager notify];
    }
    return 0;
}

- (void)didLoadTree:(JSObject)tree // private
{
    libCode[identifier] = [[Folder alloc] initWithTree:tree];
    delete self.isLoading;
    [manager notify];
}

- (void)didFailToLoadTree // private
{
    delete self.isLoading;
    self.isBad = YES;
    [manager notify];
}

- (Entry)childAtIndex:(unsigned)index // public
{
    return [libCode[identifier] childAtIndex:index];
}

- (CPString)URL // public
{
    return "/libs/" + authorName + "/" + appName + "/" + version + "/";
}

@end

@implementation LibManager : BaseEntityManager
{
    CodeManager codeManager;
    UseLibPanelController useLibPanelController;
    File manifestFile;
    JSObject manifest;
    BOOL isProcessing;
}

- (id)initWithCodeManager:(CodeManager)aCodeManager // public
{
    if (self = [super initWithApp:aCodeManager.app keyName:"libs"]) {
        isLoading = YES;
        codeManager = aCodeManager;
        useLibPanelController = [[UseLibPanelController alloc] initWithTarget:self action:@selector(useLib:)];
        [app addObserver:self forKeyPath:"code"];
    }
    return self;
}

- (CPString)name // public
{
    return "Libraries";
}

- (CPString)imageName // public
{
    return "Libs";
}

- (unsigned)numberOfChildren // public
{
    return app.libs ? app.libs.length : 0;
}

- (Lib)childAtIndex:(unsigned)index // public
{
    return app.libs[index];
}

- (BOOL)isReady // public
{
    return !!app.libs;
}

- (void)setLibs:(CPArray)libs // private
{
    isLoading = NO;
    if (app.libs)
        app.libs.forEach(function (lib) { [lib noteDeleted]; });
    [app setLibs:libs];
}

- (BOOL)manifestIsCorrect // private
{
    return manifest && typeof(manifest) == "object" && manifest.libs && typeof(manifest.libs) == "object";
}

- (void)saveManifest // private
{
    [app saveFile:manifestFile content:JSON.stringify(manifest, null, "  ")];
}

- (void)observeValueForKeyPath:(CPString)keyPath ofObject:(id)object change:(CPDictionary)change context:(id)context // private
{
    switch (keyPath) {
    case "code":
        var entry = [app.code childWithName:"manifest.json"];
        if (entry === manifestFile && app.libs)
            return;
        [manifestFile removeObserver:self forKeyPath:"content"];
        if ([entry isKindOfClass:File]) {
            manifestFile = entry;
            [manifestFile addObserver:self forKeyPath:"content"];
            if (manifestFile.content === nil) {
                // FIXME: Race! A request getting the content is sent before receiving a response to a request changing the code.
                [app loadFile:manifestFile];
                if (!isLoading) {
                    isLoading = YES;
                    [self notify];
                }
            } else {
                [self readManifest];
            }
        } else {
            manifestFile = nil;
            [self setLibs:[]];
        }
        break;
    case "content":
        [self readManifest];
        break;
    }
}

- (void)readManifest // private
{
    try {
        manifest = JSON.parse(manifestFile.content);
    } catch (error) {
        [self setLibs:[]];
        return;
    }
    if (![self manifestIsCorrect]) {
        [self setLibs:[]];
        return;
    }
    var oldLibs = app.libs || [];
    var newLibs = [];
    for (var name in manifest.libs) {
        var identifier = manifest.libs[name] + "";
        var lib = nil;
        for (var i = 0; i < oldLibs.length; ++i) {
            if (oldLibs[i].identifier == identifier) {
                lib = oldLibs[i];
                oldLibs.splice(i, 1);
                [lib setName:name];
                delete lib.isLoading;
                break;
            }
        }
        if (!lib) {
            lib = [[Lib alloc] initWithName:name identifier:identifier];
            lib.manager = self;
        }
        newLibs.push(lib);
    }
    [self setLibs:newLibs];
}

- (void)showUseLib // public
{
    [useLibPanelController showWindow:nil];
}

- (void)useLib:(Lib)lib // public
{
    if (isProcessing)
        return;
    if (manifestFile) {
        if (![self manifestIsCorrect]) {
            [useLibPanelController close];
            [[[Alert alloc] initWithMessage:"The file \"manifest.json\" is incorrect."
                                    comment:"Please fix the manifest file."]
                showPanel];
            return;
        }
        if (manifest.libs.hasOwnProperty(lib.name)) {
            [[[Alert alloc] initWithMessage:"The alias \"" + lib.name + "\" is already taken."
                                    comment:"Please choose another alias."
                                     target:useLibPanelController
                                     action:@selector(didEndErrorSheet:)]
                showSheetForWindow:[useLibPanelController window]];
            return;
        }
    }
    if (libCode.hasOwnProperty(lib.idenitifier)) {
        [self doUseLib:lib];
        return;
    }
    isProcessing = YES;
    [[useLibPanelController window] setTitle:"Processing..."];
    var request = [[HTTPRequest alloc] initWithMethod:"GET" URL:[lib URL] target:self action:@selector(didGetTree:ofLib:)];
    [request setFinishAction:@selector(didLibTreeRequestFinished)];
    [request setErrorMessageAction:@selector(didEndLibTreeRequestErrorSheet:)];
    [request setWindow:[useLibPanelController window]];
    [request setContext:lib];
    [request send];
}

- (void)doUseLib:(Lib)lib // private
{
    isLoading = YES;
    [self notify];
    [useLibPanelController close];
    if (!manifestFile) {
        manifest = {libs: {}};
        manifestFile = [[File alloc] initWithName:"manifest.json" parentFolder:app.code];
        [manifestFile addObserver:self forKeyPath:"content"];
        [codeManager insertItem:manifestFile];
        [codeManager notify];
    }
    manifest.libs[lib.name] = lib.identifier;
    [self saveManifest];
}

- (void)didLibTreeRequestFinished // private
{
    isProcessing = NO;
    [[useLibPanelController window] setTitle:"Use Library"];
}

- (void)didGetTree:(JSObject)tree ofLib:(Lib)lib // private
{
    libCode[lib.identifier] = [[Folder alloc] initWithTree:tree];
    [self doUseLib:lib];
}

- (void)didEndLibTreeRequestErrorSheet:(Alert)sender // private
{
    [useLibPanelController didEndErrorSheet:sender];
}

- (void)renameItem:(Lib)lib to:(CPString)name // protected
{
    lib.manager = self;
    if (manifest.libs.hasOwnProperty(name)) {
        [[[Alert alloc] initWithMessage:"The alias \"" + name + "\" is already taken."
                                comment:"Please choose another alias."]
            showPanel];
        return;
    }
    manifest.libs[name] = lib.identifier;
    delete manifest.libs[lib.name];
    [self saveManifest];
    lib.isLoading = YES;
    [lib setName:name];
    [app.libs removeObject:lib];
    app.libs.push(lib);
}

- (CPString)descriptionOfItems:(CPArray)libs // public
{
    return libs.length == 1 ? "library \"" + libs[0].name + "\"" : "selected " + libs.length + " libraries";
}

- (void)deleteItems:(CPArray)libs // public
{
    libs.forEach(
        function (lib) {
            lib.isLoading = YES;
            delete manifest.libs[lib.name];
        });
    [self saveManifest];
    [self notify];
}

@end
