// (c) 2010 by Anton Korenyushkin

@import "Data.j"
@import "ContentController.j"
@import "NavigatorController.j"
@import "AboutPanelController.j"
@import "KeyPanelController.j"
@import "SignupPanelController.j"
@import "LoginPanelController.j"
@import "ChangePasswordPanelController.j"
@import "ResetPasswordPanelController.j"
@import "NewAppPanelController.j"
@import "ContactPanelController.j"
@import "Confirm.j"

@implementation NavigatorControllerProxy : CPObject

- (CPMethodSignature)methodSignatureForSelector:(SEL)selector // protected
{
    return YES;
}

- (void)forwardInvocation:(CPInvocation)invocation // protected
{
    [invocation setTarget:[DATA.app.contentController navigatorController]];
    [invocation invoke];
}

@end

@implementation AppController : CPObject
{
    @outlet CPWindow mainWindow;
    @outlet CPView sidebarView;
    @outlet CPView presentationView;
    NavigatorControllerProxy navigatorControllerProxy;
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
    CPPopUpButton appPopUpButton;
}

- (void)applicationDidFinishLaunching:(CPNotification)aNotification // private
{
    navigatorControllerProxy = [NavigatorControllerProxy new];
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
    [[fileMenu addItemWithTitle:"Open App"] setSubmenu:appsMenu];
    [fileMenu addItem:[CPMenuItem separatorItem]];
    [fileMenu addItemWithTitle:"Close File \"xxx\""];
    [fileMenu addItemWithTitle:"Save"];
    [fileMenu addItemWithTitle:"Save All"];
    actionsMenuItem = [fileMenu addItemWithTitle:"Actions"];
    [actionsMenuItem setSubmenu:[CPMenu new]];
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
    [appMenu addItemWithTitle:"Delete App…" target:self action:@selector(showDeleteApp)];
    [[mainMenu addItemWithTitle:"App"] setSubmenu:appMenu];

    var viewMenu = [CPMenu new];
    [[viewMenu addItemWithTitle:"Eval"] setSubmenu:[CPMenu new]];
    [[viewMenu addItemWithTitle:"Preview"] setSubmenu:[CPMenu new]];
    [viewMenu addItemWithTitle:"Git"];
    [[mainMenu addItemWithTitle:"View"] setSubmenu:viewMenu];

    var helpMenu = [CPMenu new];
    [helpMenu addItemWithTitle:"Getting Started"];
    [helpMenu addItemWithTitle:"User Guide"];
    [helpMenu addItemWithTitle:"Reference"];
    [helpMenu addItem:[CPMenuItem separatorItem]];
    [helpMenu addItemWithTitle:"Contact…" target:contactPanelController action:@selector(showWindow:)];
    [helpMenu addItemWithTitle:"Blog"];
    [helpMenu addItemWithTitle:"Twitter"];
    [[mainMenu addItemWithTitle:"Help"] setSubmenu:helpMenu];

    [akshellMenu, fileMenu, appMenu, helpMenu].forEach(
        function (menu) { [menu setAutoenablesItems:NO]; });

    [newFileMenuItem, newFolderMenuItem, newEnvMenuItem, useLibMenuItem].forEach(
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
    [DATA addObserver:self forKeyPath:"app.code" context:"app.code"];
    [DATA addObserver:self forKeyPath:"app.envs" context:"app.envs"];
    [DATA addObserver:self forKeyPath:"app.libs" context:"app.libs"];
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
            if (!DATA.app.contentController)
                DATA.app.contentController = [[ContentController alloc] initWithApp:DATA.app
                                                                        sidebarView:sidebarView
                                                                   presentationView:presentationView];
            [DATA.app.contentController show];
            [[actionsMenuItem submenu] setSupermenu:nil];
            [actionsMenuItem setSubmenu:[navigatorControllerProxy actionsMenu]];
        }
        var mainMenu = [CPApp mainMenu];
        for (var i = 2; i < 5; ++i)
            [[mainMenu itemAtIndex:i] setEnabled:DATA.app];
        for (var i = 3; i < 9; ++i)
            [[fileMenu itemAtIndex:i] doSetEnabled:DATA.app];
        var toolbarItems = [[mainWindow toolbar] items];
        [0, 3, 4, 6, 7, 8, 10, 11].forEach(function (i) { [toolbarItems[i] setEnabled:DATA.app] });
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
        switch (itemIdentifier) {
        case "New":
            [item setTarget:navigatorControllerProxy];
            [item setAction:@selector(showNewFile)];
            break;
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
