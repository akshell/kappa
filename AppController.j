// (c) 2010 by Anton Korenyushkin

@import "Data.j"
@import "Proxy.j"
@import "SidebarController.j"
@import "AboutPanelController.j"
@import "KeyPanelController.j"
@import "SignupPanelController.j"
@import "LoginPanelController.j"
@import "ChangePasswordPanelController.j"
@import "ResetPasswordPanelController.j"
@import "NewAppPanelController.j"
@import "ContactPanelController.j"
@import "Confirm.j"

@implementation AppController : CPObject
{
    @outlet CPWindow mainWindow;
    @outlet CPView sidebarView;
    @outlet CPView presentationView;
    Proxy navigatorControllerProxy;
    Proxy workspaceControllerProxy;
    AboutPanelController aboutPanelController;
    KeyPanelController keyPanelController;
    ChangePasswordPanelController changePasswordPanelController;
    ResetPasswordPanelController resetPasswordPanelController;
    SignupPanelController signupPanelController;
    LoginPanelController loginPanelController;
    ContactPanelController contactPanelController;
    NewAppPanelController newAppPanelController;
    CPMenuItem passwordMenuItem;
    CPMenu fileMenu;
    CPMenu appsMenu;
    CPMenuItem newFileMenuItem;
    CPMenuItem newFolderMenuItem;
    CPMenuItem actionsMenuItem;
    CPMenuItem newEnvMenuItem;
    CPMenuItem useLibMenuItem;
    CPMenuItem evalMenuItem;
    CPMenuItem previewMenuItem;
    CPArray appMenuItems;
    CPArray bufferMenuItems;
    CPPopUpButton appPopUpButton;
}

- (void)applicationDidFinishLaunching:(CPNotification)aNotification // private
{
    [mainWindow setAcceptsMouseMovedEvents:YES];

    navigatorControllerProxy = [[Proxy alloc] initWithObject:DATA keyPath:"app.navigatorController"];
    workspaceControllerProxy = [[Proxy alloc] initWithObject:DATA keyPath:"app.workspaceController"];
    aboutPanelController = [AboutPanelController new];
    keyPanelController = [KeyPanelController new];
    changePasswordPanelController = [ChangePasswordPanelController new];
    resetPasswordPanelController = [ResetPasswordPanelController new];
    signupPanelController = [SignupPanelController new];
    loginPanelController = [[LoginPanelController alloc] initWithResetPasswordPanelController:resetPasswordPanelController];
    contactPanelController = [ContactPanelController new];
    newAppPanelController = [[NewAppPanelController alloc] initWithTarget:self action:@selector(didCreateAppWithName:)];

    var mainMenu = [CPApp mainMenu];
    [mainMenu removeAllItems];

    appMenuItems = [];
    bufferMenuItems = [];

    var akshellMenu = [CPMenu new];
    [akshellMenu addItemWithTitle:"About Akshell" target:aboutPanelController action:@selector(showWindow:)];
    [akshellMenu addItem:[CPMenuItem separatorItem]];
    [akshellMenu addItemWithTitle:"SSH Public Key" target:keyPanelController action:@selector(showWindow:)];
    passwordMenuItem = [akshellMenu addItemWithTitle:"" action:@selector(showWindow:) keyEquivalent:nil];
    [[mainMenu addItemWithTitle:"Akshell"] setSubmenu:akshellMenu];

    fileMenu = [CPMenu new];
    [fileMenu addItemWithTitle:"New App…" target:newAppPanelController action:@selector(showWindow:)];
    newFileMenuItem = [fileMenu addItemWithTitle:"New File" target:navigatorControllerProxy action:@selector(showNewFile)];
    newFolderMenuItem = [fileMenu addItemWithTitle:"New Folder" target:navigatorControllerProxy action:@selector(showNewFolder)];
    appsMenu = [CPMenu new];
    var appsMenuItem = [fileMenu addItemWithTitle:"Open App"];
    [appsMenuItem setSubmenu:appsMenu];
    [fileMenu addItem:[CPMenuItem separatorItem]];
    [fileMenu addItemWithTitle:"Close File \"xxx\""];
    [fileMenu addItemWithTitle:"Save"];
    [fileMenu addItemWithTitle:"Save All"];
    actionsMenuItem = [fileMenu addItemWithTitle:"Actions"];
    [actionsMenuItem setSubmenu:[CPMenu new]];
    appMenuItems.push(appsMenuItem, actionsMenuItem);
    [[mainMenu addItemWithTitle:"File"] setSubmenu:fileMenu];

    var appMenu = [CPMenu new];
    newEnvMenuItem = [appMenu addItemWithTitle:"New Environment" target:navigatorControllerProxy action:@selector(showNewEnv)];
    useLibMenuItem = [appMenu addItemWithTitle:"Use Library…" target:navigatorControllerProxy action:@selector(showUseLib)];
    [appMenu addItem:[CPMenuItem separatorItem]];
    [appMenu addItemWithTitle:"Diff…"];
    [appMenu addItemWithTitle:"Commit…"];
    [appMenu addItem:[CPMenuItem separatorItem]];
    [appMenu addItemWithTitle:"Manage Domains…"];
    [appMenu addItemWithTitle:"Publish App…"];
    appMenuItems.push([appMenu addItemWithTitle:"Delete App…" target:self action:@selector(showDeleteApp)]);
    [[mainMenu addItemWithTitle:"App"] setSubmenu:appMenu];

    var viewMenu = [CPMenu new];
    evalMenuItem = [viewMenu addItemWithTitle:"Eval"];
    [evalMenuItem setSubmenu:[CPMenu new]];
    previewMenuItem = [viewMenu addItemWithTitle:"Preview"];
    [previewMenuItem setSubmenu:[CPMenu new]];
    bufferMenuItems.push(
        evalMenuItem, previewMenuItem,
        [viewMenu addItemWithTitle:"Git" target:workspaceControllerProxy action:@selector(openGit)]);
    [[mainMenu addItemWithTitle:"View"] setSubmenu:viewMenu];

    var helpMenu = [CPMenu new];
    bufferMenuItems.push(
        [helpMenu addItemWithTitle:"Getting Started" target:workspaceControllerProxy action:@selector(openGettingStarted)],
        [helpMenu addItemWithTitle:"User Guide" target:workspaceControllerProxy action:@selector(openUserGuide)],
        [helpMenu addItemWithTitle:"Reference" target:workspaceControllerProxy action:@selector(openReference)]);
    [helpMenu addItem:[CPMenuItem separatorItem]];
    [helpMenu addItemWithTitle:"Contact…" target:contactPanelController action:@selector(showWindow:)];
    [helpMenu addItemWithTitle:"Blog"];
    [helpMenu addItemWithTitle:"Twitter"];
    [[mainMenu addItemWithTitle:"Help"] setSubmenu:helpMenu];

    [akshellMenu, fileMenu, appMenu, viewMenu, helpMenu].forEach(
        function (menu) { [menu setAutoenablesItems:NO]; });

    appMenuItems.concat(bufferMenuItems, newFileMenuItem, newFolderMenuItem, newEnvMenuItem, useLibMenuItem).forEach(
        function (menuItem) { [menuItem setEnabled:NO]; });

    [mainMenu addItem:[CPMenuItem separatorItem]];
    [self addUserMenus];

    var toolbar = [CPToolbar new];
    [toolbar setDelegate:self];
    [mainWindow setToolbar:toolbar];
    [self fillAppMenus];

    [DATA addObserver:self forKeyPath:"username"];
    [DATA addObserver:self forKeyPath:"apps"];
    [DATA addObserver:self forKeyPath:"app" options:CPKeyValueObservingOptionInitial context:"app"];
    ["app.code", "app.envs", "app.libs", "app.buffers", "app.buffer", "app.buffer.name"].forEach(
        function (keyPath) { [DATA addObserver:self forKeyPath:keyPath context:keyPath]; });
}

- (CPPopUpButton)appPopUpButton // private
{
    return [[[[mainWindow toolbar] items][0] view] subviews][0];
}

- (void)addUserMenus // private
{
    var mainMenu = [CPApp mainMenu];
    if (DATA.username) {
        [passwordMenuItem setTitle:"Change Password…"];
        [passwordMenuItem setTarget:changePasswordPanelController];
        [mainMenu addItemWithTitle:"Log Out (" + DATA.username + ")" target:self action:@selector(logOut)];
    } else {
        [passwordMenuItem setTitle:"Reset Password…"];
        [passwordMenuItem setTarget:resetPasswordPanelController];
        [mainMenu addItemWithTitle:"Sign Up" target:signupPanelController action:@selector(showWindow:)];
        [mainMenu addItemWithTitle:"Log In" target:loginPanelController action:@selector(showWindow:)];
    }
}

- (void)fillAppMenus // private
{
    var appPopUpButton = [self appPopUpButton];
    DATA.apps.forEach(
        function (app) {
            var item = [[CPMenuItem alloc] initWithTitle:app.name action:@selector(switchApp:) keyEquivalent:nil];
            [appsMenu addItem:[item copy]];
            [appPopUpButton addItem:item];
        });
    if (DATA.apps.length) {
        [[appsMenu itemAtIndex:DATA.appIndex] setState:CPOnState];
        if (DATA.appIndex)
            [appPopUpButton selectItemAtIndex:DATA.appIndex];
        else
            [[appPopUpButton itemAtIndex:0] setState:CPOnState];
    }
}

- (void)observeValueForKeyPath:(CPString)keyPath ofObject:(id)object change:(CPDictionary)change context:(id)context // private
{
    switch (context || keyPath) {
    case "username":
        var mainMenu = [CPApp mainMenu];
        for (var index = [mainMenu numberOfItems]; ![[mainMenu itemAtIndex:--index] isSeparatorItem];)
            [mainMenu removeItemAtIndex:index];
        [self addUserMenus];
        break;
    case "apps":
        [appsMenu removeAllItems];
        [[self appPopUpButton] removeAllItems];
        [self fillAppMenus];
        break;
    case "app":
        [sidebarView setSubviews:[]];
        if (DATA.app) {
            if (!DATA.app.sidebarController)
                DATA.app.sidebarController = [[SidebarController alloc] initWithApp:DATA.app view:sidebarView];
            [DATA.app.sidebarController show];
            [
                [actionsMenuItem, @selector(actionsMenu)],
                [evalMenuItem, @selector(evalMenu)],
                [previewMenuItem, @selector(previewMenu)]
            ].forEach(
                function (pair) {
                    [[pair[0] submenu] setSupermenu:nil];
                    [pair[0] setSubmenu:objj_msgSend(navigatorControllerProxy, pair[1])];
                });
        }
        appMenuItems.forEach(function (menuItem) { [menuItem doSetEnabled:DATA.app]; });
        [[[mainWindow toolbar] items][0] setEnabled:DATA.app];
        break;
    case "app.code":
        var isEnabled = DATA.app && DATA.app.code;
        [newFileMenuItem doSetEnabled:isEnabled];
        [newFolderMenuItem doSetEnabled:isEnabled];
        [[[mainWindow toolbar] items][2] setEnabled:isEnabled];
        break;
    case "app.envs":
        [newEnvMenuItem doSetEnabled:DATA.app && DATA.app.envs];
        break;
    case "app.libs":
        [useLibMenuItem doSetEnabled:DATA.app && DATA.app.libs];
        break;
    case "app.buffers":
        var isEnabled = DATA.app && DATA.app.buffers;
        var toolbarItems = [[mainWindow toolbar] items];
        [6, 7, 8].forEach(function (i) { [toolbarItems[i] setEnabled:isEnabled] });
        bufferMenuItems.forEach(function (menuItem) { [menuItem doSetEnabled:isEnabled]; });
        break;
    case "app.buffer":
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
    }
}

- (CPArray)toolbarAllowedItemIdentifiers:(CPToolbar)toolbar // private
{
    return [CPToolbarSpaceItemIdentifier, "App", "New", "Save", "Save All", "Eval", "Preview", "Git", "Diff", "Commit"];
}

- (CPArray)toolbarDefaultItemIdentifiers:(CPToolbar)toolbar // private
{
    return [
        "App", CPToolbarSpaceItemIdentifier,
        "New", "Save", "Save All", CPToolbarSpaceItemIdentifier,
        "Eval", "Preview", "Git", CPToolbarSpaceItemIdentifier,
        "Diff", "Commit"
    ];
}

- (CPToolbarItem)toolbar:(CPToolbar)toolbar
   itemForItemIdentifier:(CPString)itemIdentifier
willBeInsertedIntoToolbar:(BOOL)flag // private
{
    var item = [[CPToolbarItem alloc] initWithItemIdentifier:itemIdentifier];
    [item setLabel:itemIdentifier];
    [item setEnabled:NO];
    if (itemIdentifier == "App") {
        var popUpButton = [[CPPopUpButton alloc] initWithFrame:CGRectMake(4, 8, 202, 24)];
        [popUpButton setAutoresizingMask:CPViewWidthSizable];
        [popUpButton setMenu:[appsMenu copy]];
        if (DATA.apps.length)
            [popUpButton selectItemAtIndex:DATA.appIndex];
        var itemView = [[CPView alloc] initWithFrame:CGRectMake(0, 0, 206, 32)];
        [itemView addSubview:popUpButton];
        [item setView:itemView];
        [item setMinSize:[itemView frameSize]];
    } else {
        var image = [CPImage imageFromPath:itemIdentifier.replace(" ", "") + "32.png"];
        [item setImage:image];
        [item setMinSize:CGSizeMake(32, 32)];
        var pair = {
            New: [navigatorControllerProxy, @selector(showNewFile)],
            Eval: [navigatorControllerProxy, @selector(openEval)],
            Preview: [navigatorControllerProxy, @selector(openPreview)],
            Git: [workspaceControllerProxy, @selector(openGit)]
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
    position = MIN(MAX(position, 150), [splitView frameSize].width - 500);
    [[[mainWindow toolbar] items][0] setMinSize:CGSizeMake(position - 35, 32)];
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
    [DATA setAppNames:["hello-world"] config:{}];
}

- (void)switchApp:(CPMenuItem)sender // private
{
    var index = [[sender menu] indexOfItem:sender];
    if (index == DATA.appIndex)
        return;
    [[appsMenu itemAtIndex:DATA.appIndex] setState:CPOffState];
    [[appsMenu itemAtIndex:index] setState:CPOnState];
    [[self appPopUpButton] selectItemAtIndex:index];
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
    var appPopUpButton = [self appPopUpButton];
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
    [[[Confirm alloc] initWithMessage:"Are you sure want to delete the app \"" + DATA.app.name + "\"?"
                              comment:"You cannot undo this action."
                               target:self
                               action:@selector(deleteApp)]
        showPanel];
}

- (void)deleteApp // private
{
    [[[HTTPRequest alloc] initWithMethod:"DELETE" URL:[DATA.app URL]] send];
    [appsMenu removeItemAtIndex:DATA.appIndex];
    var appPopUpButton = [self appPopUpButton];
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

@end
