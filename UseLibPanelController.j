// (c) 2010 by Anton Korenyushkin

@import "RequestPanelController.j"
@import "Data.j"
@import "NodeItems.j"

@implementation UseLibPanelController : RequestPanelController
{
    @outlet CPTextField authorLabel;
    @outlet CPTextField authorField;
    @outlet CPTextField nameLabel;
    @outlet CPTextField nameField;
    @outlet CPTextField versionLabel;
    @outlet CPTextField versionField;
    @outlet CPTextField aliasLabel;
    @outlet CPTextField aliasField;
    @outlet CPButton useButton;
}

- (id)init
{
    if (self = [super initWithWindowCibName:"UseLibPanel"])
        [DATA addObserver:self forKeyPath:"app" options:CPKeyValueObservingOptionNew context:nil];
    return self;
}

- (void)awakeFromCib
{
    [authorLabel, nameLabel, versionLabel, aliasLabel].forEach(
        function (label) { [label setAlignment:CPRightTextAlignment]; });
    [authorField selectAll:nil];
    [useButton setEnabled:NO];
    [useButton setKeyEquivalent:CPCarriageReturnCharacter];
}

- (void)showWindow:(id)sender
{
    [DATA.app.libsItem load];
    [super showWindow:sender];
}

- (void)observeValueForKeyPath:(CPString)keyPath ofObject:(id)object change:(CPDictionary)change context:(id)context
{
    if (keyPath == "app")
        [self close];
}

- (void)controlTextDidChange:(id)sender
{
    [useButton setEnabled:([authorField stringValue] &&
                           [nameField stringValue] &&
                           [versionField stringValue] &&
                           [aliasField stringValue])];
}

- (void)controlTextDidFocus:(CPNotification)notification
{
    if ([notification object] === aliasField && ![aliasField stringValue]) {
        [aliasField setStringValue:[nameField stringValue]];
        [aliasField selectAll:nil];
        [self controlTextDidChange:nil];
    }
}

- (@action)submit:(id)sender
{
    [DATA.app.libsItem loadWithTarget:self action:@selector(doSubmit)];
}

- (void)doSubmit
{
    var alias = [aliasField stringValue];
    if ([DATA.app libWithName:alias]) {
        [[[Alert alloc] initWithMessage:"The alias \"" + alias + "\" is already taken."
                                comment:"Please choose another alias."
                                 target:self
                                 action:@selector(didEndAliasErrorSheet)]
            showSheetForWindow:[self window]];
        return;
    }
    [self requestWithMethod:"GET"
                        URL:("/libs/" +
                             [authorField stringValue] + "/" +
                             [nameField stringValue] + "/" +
                             [versionField stringValue] + "/")];
}

- (void)didEndAliasErrorSheet
{
    [[self window] makeFirstResponder:aliasField];
}

- (void)didEndRequestErrorSheet:(Alert)sender
{
    if (sender.message.indexOf("version") != -1)
        [[self window] makeFirstResponder:versionField];
    else if (sender.message.indexOf("library") != -1)
        [[self window] makeFirstResponder:nameField];
    else if (sender.message.indexOf("author") != -1)
        [[self window] makeFirstResponder:authorField];
}

- (void)showManifestErrorPanelWithMessage:(CPString)message
{
    [self close];
    [[[Alert alloc] initWithMessage:message
                            comment:"Please fix the manifest file before adding libraries to the app."]
        showPanel];
}

- (void)didReceiveResponse:(JSObject)data
{
    var identifier = [LibItem identifierForAuthorName:[authorField stringValue]
                                              appName:[nameField stringValue]
                                              version:[versionField stringValue]];
    DATA.libs[identifier] = [[Folder alloc] initWithTree:data];
    var file = [DATA.app.code fileWithName:"manifest.json"];
    var manifest;
    if (file) {
        try {
            manifest = JSON.parse(file.content);
        } catch (error) {
            [self showManifestErrorPanelWithMessage:"The file \"manifest.json\" contains incorrect JSON data."];
            return;
        }
        if (typeof(manifest) != "object") {
            [self showManifestErrorPanelWithMessage:"The file \"manifest.json\" must contain a JSON object."];
            return;
        }
        if (!manifest.libs) {
            manifest.libs = {};
        } else if (typeof(manifest.libs) != "object") {
            [self showManifestErrorPanelWithMessage:"The \"libs\" manifest property must be an object."];
            return;
        }
    } else {
        manifest = {libs:{}};
        file = [[File alloc] initWithName:"manifest.json"];
        [DATA.app.code addFile:file];
        [DATA.app.outlineView reloadItem:DATA.app.code reloadChildren:YES];
    }
    manifest.libs[[aliasField stringValue]] = identifier;
    [file setContent:JSON.stringify(manifest, null, "  ")];
    var request = [[HTTPRequest alloc] initWithMethod:"PUT"
                                                  URL:[DATA.app url] + "code/manifest.json"
                                               target:self
                                               action:@selector(didPutManifest)];
    [request setWindow:[self window]];
    [request setValue:"application/json" forHeader:"Content-Type"];
    [request send:file.content];
}

- (void)didPutManifest
{
    var libItem = [[LibItem alloc] initWithApp:DATA.app
                                          name:[aliasField stringValue]
                                    authorName:[authorField stringValue]
                                       appName:[nameField stringValue]
                                       version:[versionField stringValue]];
    [DATA.app addLib:libItem];
    [DATA.app.outlineView revealChildItem:libItem ofItem:DATA.app.libsItem];
    [self close];
}

@end
