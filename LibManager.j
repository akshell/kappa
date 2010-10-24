// (c) 2010 by Anton Korenyushkin

@import "Manager.j"
@import "UseLibPanelController.j"

var libCode = {};

@implementation Lib (LibManager)

+ (CPString)imageName // public
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

var parseManifest = function (content) {
    try {
        var manifest = JSON.parse(content);
    } catch (error) {
        return nil;
    }
    return typeof(manifest) == "object" && typeof(manifest.libs) == "object" ? manifest : nil;
};

@implementation LibManager : Manager
{
    CodeManager codeManager;
    UseLibPanelController useLibPanelController;
    File manifestFile;
    BOOL isProcessing;
}

- (id)initWithCodeManager:(CodeManager)aCodeManager // public
{
    if (self = [super initWithApp:aCodeManager.app]) {
        codeManager = aCodeManager;
        useLibPanelController =
            [[UseLibPanelController alloc] initWithTarget:self action:@selector(useLib:)];
        [codeManager addChangeObserver:self selector:@selector(codeDidChange)];
    }
    return self;
}

- (CPString)name // public
{
    return "Libraries";
}

+ (CPString)imageName // public
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

- (void)codeDidChange // private
{
    var entry = [app.code childWithName:"manifest.json"];
    if (entry === manifestFile && app.libs)
        return;
    [manifestFile removeObserver:self forKeyPath:"savedContent"];
    if ([entry isKindOfClass:File]) {
        manifestFile = entry;
        [manifestFile addObserver:self forKeyPath:"savedContent"];
        if (manifestFile.savedContent) {
            [self readManifest];
        } else {
            [codeManager loadFile:manifestFile];
            isLoading = YES;
            [self notify];
        }
    } else {
        manifestFile = nil;
        [self setLibs:[]];
    }
}

- (void)setLibs:(CPArray)libs // private
{
    isLoading = NO;
    [app setLibs:libs];
    [self notify];
}

- (void)observeValueForKeyPath:(CPString)keyPath ofObject:(id)object change:(CPDictionary)change context:(id)context // private
{
    if (keyPath == "savedContent")
        [self readManifest];
}

- (void)readManifest // private
{
    var manifest = parseManifest(manifestFile.savedContent);
    if (!manifest) {
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

- (JSObject)parseCurrentManifestContent // private
{
    var manifest = parseManifest(manifestFile.currentContent);
    if (manifest)
        return manifest;
    [[[Alert alloc] initWithMessage:"The file \"manifest.json\" is incorrect."
                            comment:"Please fix the manifest file."]
        showPanel];
    return nil;
}

- (void)useLib:(Lib)lib // public
{
    if (isProcessing)
        return;
    var manifest;
    if (manifestFile) {
        manifest = [self parseCurrentManifestContent];
        if (!manifest) {
            [useLibPanelController close];
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
    } else {
        manifest = nil;
    }
    if (libCode.hasOwnProperty(lib.idenitifier)) {
        [self doUseLib:lib withManifest:manifest];
        return;
    }
    isProcessing = YES;
    [[useLibPanelController window] setTitle:"Processing..."];
    var request = [[HTTPRequest alloc] initWithMethod:"GET" URL:[lib URL] target:self action:@selector(didGetLibTree:context:)];
    [request setFinishAction:@selector(didLibTreeRequestFinished)];
    [request setErrorMessageAction:@selector(didEndLibTreeRequestErrorSheet:)];
    [request setWindow:[useLibPanelController window]];
    [request setContext:{lib: lib, manifest: manifest}];
    [request send];
}

- (void)doUseLib:(Lib)lib manifest:(JSObject)manifest // private
{
    isLoading = YES;
    [self notify];
    [useLibPanelController close];
    if (!manifest) {
        manifest = {libs: {}};
        manifestFile = [[File alloc] initWithName:"manifest.json" parentFolder:app.code];
        [manifestFile addObserver:self forKeyPath:"savedContent"];
        [codeManager insertItem:manifestFile];
        [codeManager notify];
    }
    manifest.libs[lib.name] = lib.identifier;
    [manifestFile setCurrentContent:JSON.stringify(manifest, null, "  ")];
    [codeManager saveFile:manifestFile];
}

- (void)didLibTreeRequestFinished // private
{
    isProcessing = NO;
    [[useLibPanelController window] setTitle:"Use Library"];
}

- (void)didGetLibTree:(JSObject)tree context:(JSObject)context // private
{
    libCode[context.lib.identifier] = [[Folder alloc] initWithTree:tree];
    [self doUseLib:context.lib manifest:context.manifest];
}

- (void)didEndLibTreeRequestErrorSheet:(Alert)sender // private
{
    [useLibPanelController didEndErrorSheet:sender];
}

- (void)renameItem:(Lib)lib to:(CPString)name // protected
{
    lib.manager = self;
    var manifest = [self parseCurrentManifestContent];
    if (!manifest)
        return;
    if (manifest.libs.hasOwnProperty(name)) {
        [[[Alert alloc] initWithMessage:"The alias \"" + name + "\" is already taken."
                                comment:"Please choose another alias."]
            showPanel];
        return;
    }
    manifest.libs[name] = lib.identifier;
    delete manifest.libs[lib.name];
    [manifestFile setCurrentContent:JSON.stringify(manifest, null, "  ")];
    [codeManager saveFile:manifestFile];
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
    var manifest = [self parseCurrentManifestContent];
    if (!manifest)
        return;
    libs.forEach(
        function (lib) {
            lib.isLoading = YES;
            delete manifest.libs[lib.name];
        });
    [manifestFile setCurrentContent:JSON.stringify(manifest, null, "  ")];
    [codeManager saveFile:manifestFile];
    [self notify];
}

@end
