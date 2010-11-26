// (c) 2010 by Anton Korenyushkin

@import "Multiview.j"
@import "Data.j"
@import "Proxy.j"
@import "Confirm.j"
@import "SidebarController.j"
@import "AboutPanelController.j"
@import "KeyPanelController.j"
@import "SignupPanelController.j"
@import "LoginPanelController.j"
@import "ChangePasswordPanelController.j"
@import "ResetPasswordPanelController.j"
@import "NewAppPanelController.j"
@import "ContactPanelController.j"
@import "CodeFileController.j"
@import "LibFileController.j"

@implementation FileBuffer (AppController)

- (CPString)modeName // public
{
    return "Edit";
}

@end

@implementation CodeFileBuffer (AppController)

- (Class)presentationControllerClass // public
{
    return CodeFileController;
}

@end

@implementation LibFileBuffer (AppController)

- (Class)presentationControllerClass // public
{
    return LibFileController;
}

@end

@implementation GitBuffer (AppController)

- (CPString)modeName // public
{
    return "Git";
}

- (Class)presentationControllerClass // public
{
    return nil;
}

@end

@implementation EvalBuffer (AppController)

- (CPString)modeName // public
{
    return "Eval";
}

- (Class)presentationControllerClass // public
{
    return nil;
}

@end

BoundKeys = ["[", "]", "f", "g", "n", "s", "w"];
var DocsURL = "/docs/0.3/";

function setMenuItemsEnabled(menuItems, flag) {
    menuItems.forEach(function (menuItem) { [menuItem doSetEnabled:flag]; });
}

@implementation AppController : CPObject
{
    @outlet CPWindow mainWindow;
    @outlet CPView sidebarView;
    @outlet Multiview presentationMultiview;
    Proxy navigatorControllerProxy;
    Proxy workspaceControllerProxy;
    Proxy presentationControllerProxy;
    AboutPanelController aboutPanelController;
    KeyPanelController keyPanelController;
    ChangePasswordPanelController changePasswordPanelController;
    ResetPasswordPanelController resetPasswordPanelController;
    SignupPanelController signupPanelController;
    LoginPanelController loginPanelController;
    ContactPanelController contactPanelController;
    NewAppPanelController newAppPanelController;
    TabOpener helpTabOpener;
    CPMenuItem passwordMenuItem;
    CPMenuItem logOutMenuItem;
    CPMenu fileMenu;
    CPMenu appsMenu;
    CPMenuItem newFileMenuItem;
    CPMenuItem newFolderMenuItem;
    CPMenuItem openAppMenuItem;
    CPMenuItem uploadFileMenuItem;
    CPMenuItem closeMenuItem;
    CPMenuItem saveMenuItem;
    CPMenuItem saveAllMenuItem;
    CPMenuItem actionsMenuItem;
    CPMenuItem findMenuItem;
    CPMenuItem findNextMenuItem;
    CPMenuItem findPreviousMenuItem;
    CPMenuItem goToLineMenuItem;
    CPMenuItem modeMenuItem;
    CPMenuItem editMenuItem;
    CPMenuItem evalMenuItem;
    CPMenuItem gitMenuItem;
    CPMenuItem switchToPreviewMenuItem;
    CPMenuItem openEvalMenuItem;
    CPMenuItem openPreviewMenuItem;
    CPMenuItem newEnvMenuItem;
    CPMenuItem useLibMenuItem;
    CPMenuItem manageDomainsMenuItem;
    CPMenuItem publishAppMenuItem;
    CPMenuItem deleteAppMenuItem;
    CPPopUpButton appPopUpButton;
    JSObject toolbarItems;
    CPToolbar toolbar;
}

- (void)applicationDidFinishLaunching:(CPNotification)aNotification // private
{
    [mainWindow setAcceptsMouseMovedEvents:YES];
    [CPPlatformWindow preventCharacterKeysFromPropagating:BoundKeys];

    navigatorControllerProxy = [[Proxy alloc] initWithObject:DATA keyPath:"app.navigatorController"];
    workspaceControllerProxy = [[Proxy alloc] initWithObject:DATA keyPath:"app.workspaceController"];

    presentationControllerProxy = [[Proxy alloc] initWithObject:DATA keyPath:"app.buffer.presentationController"];
    aboutPanelController = [AboutPanelController new];
    keyPanelController = [KeyPanelController new];
    changePasswordPanelController = [ChangePasswordPanelController new];
    resetPasswordPanelController = [ResetPasswordPanelController new];
    signupPanelController = [SignupPanelController new];
    loginPanelController = [[LoginPanelController alloc] initWithResetPasswordPanelController:resetPasswordPanelController];
    contactPanelController = [ContactPanelController new];
    newAppPanelController = [[NewAppPanelController alloc] initWithTarget:self action:@selector(didCreateAppWithName:)];

    helpTabOpener = [TabOpener new];

    var mainMenu = [CPApp mainMenu];
    [mainMenu removeAllItems];

    var akshellMenu = [CPMenu new];
    [akshellMenu addItemWithTitle:"About Akshell" target:aboutPanelController action:@selector(showWindow:)];
    [akshellMenu addItem:[CPMenuItem separatorItem]];
    [akshellMenu addItemWithTitle:"SSH Public Key" target:keyPanelController action:@selector(showWindow:)];
    passwordMenuItem = [akshellMenu addItemWithTitle:"" target:nil action:@selector(showWindow:)];
    [akshellMenu addItem:[CPMenuItem separatorItem]];
    logOutMenuItem = [akshellMenu addItemWithTitle:"Log Out" target:self action:@selector(logOut)];
    [[mainMenu addItemWithTitle:"Akshell"] setSubmenu:akshellMenu];

    fileMenu = [CPMenu new];
    [[fileMenu addItemWithTitle:"New App…" target:newAppPanelController action:@selector(showWindow:) keyEquivalent:"n"]
        setKeyEquivalentModifierMask:CPAlternateKeyMask | CPPlatformActionKeyMask];
    newFileMenuItem = [fileMenu addItemWithTitle:"New File" target:navigatorControllerProxy action:@selector(showNewFile)];
    newFolderMenuItem = [fileMenu addItemWithTitle:"New Folder" target:navigatorControllerProxy action:@selector(showNewFolder)];
    appsMenu = [CPMenu new];
    openAppMenuItem = [fileMenu addItemWithTitle:"Open App"];
    [openAppMenuItem setSubmenu:appsMenu];
    [fileMenu addItem:[CPMenuItem separatorItem]];
    uploadFileMenuItem = [fileMenu addItemWithTitle:"Upload File…"];
    [uploadFileMenuItem setUploadTarget:navigatorControllerProxy action:@selector(uploadDOMFile:)];
    [fileMenu addItem:[CPMenuItem separatorItem]];
    closeMenuItem = [fileMenu addItemWithTitle:"Close"
                                        target:workspaceControllerProxy
                                        action:@selector(closeCurrentBuffer)
                                 keyEquivalent:"w"];
    saveMenuItem = [fileMenu addItemWithTitle:"Save" target:presentationControllerProxy action:@selector(save) keyEquivalent:"s"];
    saveAllMenuItem = [fileMenu addItemWithTitle:"Save All" target:self action:@selector(saveAll) keyEquivalent:"s"];
    [saveAllMenuItem setKeyEquivalentModifierMask:CPAlternateKeyMask | CPPlatformActionKeyMask];
    [fileMenu addItem:[CPMenuItem separatorItem]];
    actionsMenuItem = [fileMenu addItemWithTitle:"Actions"];
    [actionsMenuItem setSubmenu:[CPMenu new]];
    [[mainMenu addItemWithTitle:"File"] setSubmenu:fileMenu];

    if (navigator.userAgent.indexOf("Chrome") == -1) {
        [newFileMenuItem setKeyEquivalent:"n"];
        [newFolderMenuItem setKeyEquivalent:"N"];
    } else {
        [closeMenuItem setKeyEquivalentModifierMask:CPAlternateKeyMask | CPPlatformActionKeyMask];
    }

    var editMenu = [CPMenu new];
    findMenuItem = [editMenu addItemWithTitle:"Find…"
                                       target:presentationControllerProxy
                                       action:@selector(showFind)
                                keyEquivalent:"f"];
    findNextMenuItem = [editMenu addItemWithTitle:"Find Next"
                                           target:presentationControllerProxy
                                           action:@selector(findNext)
                                    keyEquivalent:"g"];
    findPreviousMenuItem = [editMenu addItemWithTitle:"Find Previous"
                                               target:presentationControllerProxy
                                               action:@selector(findPrevious)
                                        keyEquivalent:"G"];
    [editMenu addItem:[CPMenuItem separatorItem]];
    goToLineMenuItem = [editMenu addItemWithTitle:"Go to Line…"
                                           target:presentationControllerProxy
                                           action:@selector(showGoToLine)
                                    keyEquivalent:"L"];
    [[mainMenu addItemWithTitle:"Edit"] setSubmenu:editMenu];

    var goMenu = [CPMenu new];
    var modeMenu = [CPMenu new];
    editMenuItem = [modeMenu addItemWithTitle:"Edit" target:workspaceControllerProxy action:@selector(switchToEdit)];
    evalMenuItem = [modeMenu addItemWithTitle:"Eval" target:navigatorControllerProxy action:@selector(switchToEval)];
    gitMenuItem = [modeMenu addItemWithTitle:"Git" target:workspaceControllerProxy action:@selector(switchToGit)];
    modeMenuItem = [goMenu addItemWithTitle:"Mode"];
    [modeMenuItem setSubmenu:modeMenu];
    switchToPreviewMenuItem = [goMenu addItemWithTitle:"Switch to Preview"
                                                target:navigatorControllerProxy
                                                action:@selector(switchToPreview)];
    [goMenu addItemWithTitle:"Switch to Help" target:self action:@selector(switchToHelp)];
    [goMenu addItem:[CPMenuItem separatorItem]];
    previousMenuItem = [goMenu addItemWithTitle:"Previous"
                                         target:workspaceControllerProxy
                                         action:@selector(switchToPreviousBuffer)
                                  keyEquivalent:"↑"];
    [previousMenuItem setKeyEquivalentModifierMask:CPAlternateKeyMask];
    nextMenuItem = [goMenu addItemWithTitle:"Next"
                                     target:workspaceControllerProxy
                                     action:@selector(switchToNextBuffer)
                              keyEquivalent:"↓"];
    [nextMenuItem setKeyEquivalentModifierMask:CPAlternateKeyMask];
    [goMenu addItem:[CPMenuItem separatorItem]];
    openEvalMenuItem = [goMenu addItemWithTitle:"Open Eval"];
    [openEvalMenuItem setSubmenu:[CPMenu new]];
    openPreviewMenuItem = [goMenu addItemWithTitle:"Open Preview"];
    [openPreviewMenuItem setSubmenu:[CPMenu new]];
    [[mainMenu addItemWithTitle:"Go"] setSubmenu:goMenu];

    var appMenu = [CPMenu new];
    newEnvMenuItem = [appMenu addItemWithTitle:"New Environment" target:navigatorControllerProxy action:@selector(showNewEnv)];
    useLibMenuItem = [appMenu addItemWithTitle:"Use Library…" target:navigatorControllerProxy action:@selector(showUseLib)];
    [appMenu addItem:[CPMenuItem separatorItem]];
    [appMenu addItemWithTitle:"Diff…" target:nil action:nil keyEquivalent:"D"];
    [appMenu addItemWithTitle:"Commit…" target:nil action:nil keyEquivalent:"C"];
    [appMenu addItem:[CPMenuItem separatorItem]];
    manageDomainsMenuItem = [appMenu addItemWithTitle:"Manage Domains…"];
    publishAppMenuItem = [appMenu addItemWithTitle:"Publish App…"];
    deleteAppMenuItem = [appMenu addItemWithTitle:"Delete App…" target:self action:@selector(showDeleteApp)];
    [[mainMenu addItemWithTitle:"App"] setSubmenu:appMenu];

    var helpMenu = [CPMenu new];
    [helpMenu addItemWithTitle:"Getting Started" target:self action:@selector(openGettingStarted)];
    [helpMenu addItemWithTitle:"User Guide" target:self action:@selector(openUserGuide)];
    [helpMenu addItemWithTitle:"Reference" target:self action:@selector(openReference)];
    [helpMenu addItem:[CPMenuItem separatorItem]];
    [helpMenu addItemWithTitle:"Contact…" target:contactPanelController action:@selector(showWindow:)];
    [helpMenu addItemWithTitle:"Blog" target:self action:@selector(openBlog)];
    [helpMenu addItemWithTitle:"Twitter" target:self action:@selector(openTwitter)];
    [[mainMenu addItemWithTitle:"Help"] setSubmenu:helpMenu];

    [akshellMenu, fileMenu, editMenu, goMenu, appMenu, helpMenu].forEach(
        function (menu) { [menu setAutoenablesItems:NO]; });

    [mainMenu addItem:[CPMenuItem separatorItem]];

    toolbarItems = {};
    toolbar = [CPToolbar new];
    [toolbar setDelegate:self];
    [mainWindow setToolbar:toolbar];

    [
        "username", "apps", "app",
        "app.code", "app.envs", "app.libs", "app.buffers", "app.bufferIndex", "app.buffer",
        "app.buffer.name", "app.buffer.isModified", "app.buffer.isEditable",
        "app.numberOfModifiedBuffers"
    ].forEach(
        function (keyPath) {
            [DATA addObserver:self forKeyPath:keyPath options:CPKeyValueObservingOptionInitial context:keyPath];
        });
}

- (void)observeValueForKeyPath:(CPString)keyPath ofObject:(id)object change:(CPDictionary)change context:(id)context // private
{
    switch (context) {
    case "username":
        var mainMenu = [CPApp mainMenu];
        for (var index = [mainMenu numberOfItems]; ![[mainMenu itemAtIndex:--index] isSeparatorItem];)
            [mainMenu removeItemAtIndex:index];
        [logOutMenuItem doSetEnabled:DATA.username];
        if (DATA.username) {
            [passwordMenuItem setTitle:"Change Password…"];
            [passwordMenuItem setTarget:changePasswordPanelController];
            var image = [CPImage imageFromPath:"User16.png"];
            [image setSize:CGSizeMake(16, 16)];
            [[mainMenu addItemWithTitle:DATA.username] setImage:image];
        } else {
            [passwordMenuItem setTitle:"Reset Password…"];
            [passwordMenuItem setTarget:resetPasswordPanelController];
            [mainMenu addItemWithTitle:"Sign Up" target:signupPanelController action:@selector(showWindow:)];
            [mainMenu addItemWithTitle:"Log In" target:loginPanelController action:@selector(showWindow:)];
        }
        break;
    case "apps":
        [appsMenu removeAllItems];
        [appPopUpButton removeAllItems];
        [appsMenu, [appPopUpButton menu]].forEach(
            function (menu) {
                DATA.apps.forEach(function (app) { [menu addItemWithTitle:app.name target:self action:@selector(switchApp:)]; });
            });
        if (DATA.apps.length) {
            [[appsMenu itemAtIndex:DATA.appIndex] setState:CPOnState];
            if (DATA.appIndex)
                [appPopUpButton selectItemAtIndex:DATA.appIndex];
            else
                [[appPopUpButton itemAtIndex:0] setState:CPOnState];
        }
        break;
    case "app":
        [sidebarView setSubviews:[]];
        if (DATA.app) {
            if (!DATA.app.sidebarController)
                DATA.app.sidebarController = [[SidebarController alloc] initWithApp:DATA.app view:sidebarView];
            [DATA.app.sidebarController show];
            [
                [actionsMenuItem, @selector(actionsMenu)],
                [openEvalMenuItem, @selector(evalMenu)],
                [openPreviewMenuItem, @selector(previewMenu)]
            ].forEach(
                function (pair) {
                    [[pair[0] submenu] setSupermenu:nil];
                    [pair[0] setSubmenu:objj_msgSend(navigatorControllerProxy, pair[1])];
                });
        }
        setMenuItemsEnabled(
            [openAppMenuItem, actionsMenuItem, modeMenuItem, manageDomainsMenuItem, deleteAppMenuItem, publishAppMenuItem],
            DATA.app);
        [toolbarItems["App"] setEnabled:DATA.app]
        break;
    case "app.code":
        var code = DATA.app && DATA.app.code
        setMenuItemsEnabled([newFileMenuItem, newFolderMenuItem, uploadFileMenuItem], code);
        [toolbarItems["New"] setEnabled:code];
        break;
    case "app.envs":
        var envs = DATA.app && DATA.app.envs;
        setMenuItemsEnabled([switchToPreviewMenuItem, openPreviewMenuItem, newEnvMenuItem], envs);
        [toolbarItems["Preview"] setEnabled:envs];
        break;
    case "app.libs":
        [useLibMenuItem doSetEnabled:DATA.app && DATA.app.libs];
        break;
    case "app.buffers":
        var buffers = DATA.app && DATA.app.buffers;
        ["Edit", "Eval", "Git"].forEach(function (name) { [toolbarItems[name] setEnabled:buffers]; });
        setMenuItemsEnabled([editMenuItem, evalMenuItem, gitMenuItem, openEvalMenuItem], buffers);
        // FALL THROUGH
    case "app.bufferIndex":
        var bufferIndex = DATA.app && DATA.app.bufferIndex;
        [previousMenuItem doSetEnabled:bufferIndex];
        [nextMenuItem doSetEnabled:bufferIndex !== nil && bufferIndex < DATA.app.buffers.length - 1];
        break;
    case "app.buffer":
        [toolbar reloadChangedToolbarItems];
        var buffer = DATA.app && DATA.app.buffer;
        var modeName = [buffer modeName];
        [toolbar setSelectedItemIdentifier:modeName];
        [editMenuItem, evalMenuItem, gitMenuItem].forEach(
            function (menuItem) { [menuItem setState:[menuItem title] == modeName ? CPOnState : CPOffState]; });
        [closeMenuItem doSetEnabled:buffer];
        if (buffer) {
            if (!buffer.presentationController)
                buffer.presentationController = [[[buffer presentationControllerClass] alloc] initWithApp:DATA.app buffer:buffer];
            // TODO: When all presentation controllers are implemented, this condition should be removed
            if (buffer.presentationController) {
                [presentationMultiview showView:[buffer.presentationController view]];
                [buffer.presentationController focus];
                [toolbarItems["Save All"] setEnabled:DATA.app.numberOfModifiedBuffers];
            } else {
                [presentationMultiview showView:nil];
                window.focus();
            }
        } else {
            [presentationMultiview showView:nil];
            window.focus();
        }
        // FALL THROUGH
    case "app.buffer.name":
        var image;
        var title;
        if (DATA.app && DATA.app.buffer) {
            image = [CPImage imageFromPath:[DATA.app.buffer imageName] + "16.png"];
            title = /* HAIR SPACE */ " " + [DATA.app.buffer name];
        } else {
            image = nil;
            title = "";
        }
        [CPMenu setMenuBarIconImage:image];
        [CPMenu setMenuBarTitle:title];
        document.title = "Akshell";
        break;
    case "app.buffer.isModified":
        var isModified = DATA.app && DATA.app.buffer && DATA.app.buffer.isModified;
        [toolbarItems["Save"] setEnabled:isModified];
        [saveMenuItem doSetEnabled:isModified];
        break;
    case "app.buffer.isEditable":
        setMenuItemsEnabled([findMenuItem, findNextMenuItem, findPreviousMenuItem, goToLineMenuItem],
                            DATA.app && DATA.app.buffer && DATA.app.buffer.isEditable);
        break;
    case "app.numberOfModifiedBuffers":
        var numberOfModifiedBuffers = DATA.app && DATA.app.numberOfModifiedBuffers;
        [toolbarItems["Save All"] setEnabled:numberOfModifiedBuffers];
        [saveAllMenuItem doSetEnabled:numberOfModifiedBuffers];
        break;
    }
}

- (CPArray)toolbarDefaultItemIdentifiers:(CPToolbar)aToolbar // private
{
    return [
        "App", CPToolbarSpaceItemIdentifier,
        "New", "Save", "Save All", CPToolbarSpaceItemIdentifier,
        "Diff", "Commit", CPToolbarSpaceItemIdentifier,
        "Preview", "Help", CPToolbarFlexibleSpaceItemIdentifier,
        "Edit", "Eval", "Git"
    ];
}

- (CPToolbarItem)toolbar:(CPToolbar)aToolbar
   itemForItemIdentifier:(CPString)itemIdentifier
willBeInsertedIntoToolbar:(BOOL)flag // private
{
    var item = toolbarItems[itemIdentifier] = [[CPToolbarItem alloc] initWithItemIdentifier:itemIdentifier];
    [item setLabel:itemIdentifier];
    switch (itemIdentifier) {
    case "App":
        appPopUpButton = [[CPPopUpButton alloc] initWithFrame:CGRectMake(4, 8, 202, 24)];
        [appPopUpButton setAutoresizingMask:CPViewWidthSizable];
        if (DATA.apps.length)
            [appPopUpButton selectItemAtIndex:DATA.appIndex];
        var itemView = [[CPView alloc] initWithFrame:CGRectMake(0, 0, 206, 32)];
        [itemView addSubview:appPopUpButton];
        [item setView:itemView];
        var size = [itemView frameSize];
        [item setMinSize:size];
        [item setMaxSize:size];
        break;
    case "URL":
        var textField = [[CPTextField alloc] initWithFrame:CGRectMake(0, 4, 100, 30)];
        [textField setBordered:YES];
        [textField setBezeled:YES];
        [textField setEditable:YES];
        [textField setAutoresizingMask:CPViewWidthSizable];
        var itemView = [[CPView alloc] initWithFrame:CGRectMake(0, 0, 100, 32)];
        [itemView addSubview:textField];
        [item setView:itemView];
        [item setMinSize:[itemView frameSize]];
        [item setMaxSize:CGSizeMake(10000, 32)];
        break;
    default:
        var image = [CPImage imageFromPath:itemIdentifier.replace(" ", "") + "32.png"];
        [item setImage:image];
        [item setMinSize:CGSizeMake(32, 32)];
        var pair = {
            "New": [navigatorControllerProxy, @selector(showNewFile)],
            "Save": [presentationControllerProxy, @selector(save)],
            "Save All": [self, @selector(saveAll)],
            "Preview": [navigatorControllerProxy, @selector(switchToPreview)],
            "Help": [self, @selector(switchToHelp)],
            "Edit": [workspaceControllerProxy, @selector(switchToEdit)],
            "Eval": [navigatorControllerProxy, @selector(switchToEval)],
            "Git": [workspaceControllerProxy, @selector(switchToGit)],
        }[itemIdentifier];
        if (pair) {
            [item setTarget:pair[0]];
            [item setAction:pair[1]];
        }
    }
    return item;
}

- (unsigned)splitView:(CPSplitView)splitView constrainSplitPosition:(unsigned)position ofSubviewAt:(unsigned)index // private
{
    position = MIN(MAX(position, 150), [splitView frameSize].width - 600);
    var size = CGSizeMake(position - 35, 32);
    [toolbarItems["App"] setMinSize:size];
    [toolbarItems["App"] setMaxSize:size];
    return position;
}

- (void)logOut // private
{
    [[[HTTPRequest alloc] initWithMethod:"POST" URL:"/logout" target:self action:@selector(didLogOut)] send];
}

- (void)didLogOut // private
{
    [DATA setUsername:""];
    [DATA setEmail:""];
    [DATA loadFromBasis:{username: "", email: "", appNames: ["hello-world"], libNames: [], config: {}}];
}

- (void)switchApp:(CPMenuItem)sender // private
{
    var index = [[sender menu] indexOfItem:sender];
    if (index == DATA.appIndex)
        return;
    [[appsMenu itemAtIndex:DATA.appIndex] setState:CPOffState];
    [[appsMenu itemAtIndex:index] setState:CPOnState];
    [appPopUpButton selectItemAtIndex:index];
    [DATA setAppIndex:index];
}

- (void)didCreateAppWithName:(CPString)appName // private
{
    var appNameLower = appName.toLowerCase();
    for (var index = 0; index < DATA.apps.length; ++index)
        if (DATA.apps[index].name.toLowerCase() > appNameLower)
            break;
    var item = [[CPMenuItem alloc] initWithTitle:appName action:@selector(switchApp:) keyEquivalent:nil];
    [item setState:CPOnState];
    [[appPopUpButton menu] insertItem:item atIndex:index];
    if (DATA.apps.length) {
        if (index == DATA.appIndex)
            [[appPopUpButton itemAtIndex:index + 1] setState:CPOffState];
        else
            [appPopUpButton selectItemAtIndex:index];
        [[appsMenu itemAtIndex:DATA.appIndex] setState:CPOffState];
    }
    [appsMenu insertItem:[item copy] atIndex:index];
    DATA.apps.splice(index, 0, [[App alloc] initWithName:appName]);
    [DATA setAppIndex:index];
}

- (void)showDeleteApp // private
{
    [[[Confirm alloc] initWithMessage:"Are you sure you want to delete the app \"" + DATA.app.name + "\"?"
                              comment:"You cannot undo this action."
                               target:self
                               action:@selector(deleteApp)]
        showPanel];
}

- (void)deleteApp // private
{
    [[[HTTPRequest alloc] initWithMethod:"DELETE" URL:[DATA.app URL]] send];
    [appsMenu removeItemAtIndex:DATA.appIndex];
    [appPopUpButton removeItemAtIndex:DATA.appIndex];
    DATA.apps.splice(DATA.appIndex, 1);
    if (DATA.apps.length) {
        [[appsMenu itemAtIndex:0] setState:CPOnState];
        if (DATA.appIndex)
            [appPopUpButton selectItemAtIndex:0];
        else
            [[appPopUpButton itemAtIndex:0] setState:CPOnState];
    }
    [DATA setAppIndex:0];
}

- (void)saveAll // private
{
    DATA.app.buffers.forEach(function (buffer) { [buffer.presentationController save]; });
}

- (void)openGettingStarted // private
{
    [helpTabOpener openURL:DocsURL + "intro/"];
}

- (void)openUserGuide // private
{
    [helpTabOpener openURL:DocsURL + "guide/"];
}

- (void)openReference // private
{
    [helpTabOpener openURL:DocsURL + "ref/"];
}

- (void)switchToHelp // private
{
    if (![helpTabOpener switchToLastTab])
        [self openGettingStarted];
}

- (void)openBlog // private
{
    window.open("http://blog.akshell.com/");
}

- (void)openTwitter // private
{
    window.open("http://twitter.com/akshell_com/");
}

@end
