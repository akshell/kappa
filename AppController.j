// (c) 2010 by Anton Korenyushkin

@import "Data.j"
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
    @outlet SidebarController sidebarController;
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
    CPPopUpButton appPopUpButton;
}

- (void)applicationDidFinishLaunching:(CPNotification)aNotification
{
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
    [[akshellMenu addItemWithTitle:"About Akshell" action:@selector(showWindow:) keyEquivalent:nil]
        setTarget:aboutPanelController];
    [akshellMenu addItem:[CPMenuItem separatorItem]];
    [[akshellMenu addItemWithTitle:"SSH Public Key" action:@selector(showWindow:) keyEquivalent:nil]
        setTarget:keyPanelController];
    passwordMenuItem = [akshellMenu addItemWithTitle:"" action:@selector(showWindow:) keyEquivalent:nil];
    [[mainMenu addItemWithTitle:"Akshell" action:nil keyEquivalent:nil] setSubmenu:akshellMenu];

    fileMenu = [CPMenu new];
    [[fileMenu addItemWithTitle:"New App…" action:@selector(showWindow:) keyEquivalent:nil]
        setTarget:newAppPanelController];
    [[fileMenu addItemWithTitle:"New File" action:@selector(showNewFile) keyEquivalent:nil]
        setTarget:sidebarController];
    [[fileMenu addItemWithTitle:"New Folder" action:@selector(showNewFolder) keyEquivalent:nil]
        setTarget:sidebarController];
    appsMenu = [CPMenu new];
    [[fileMenu addItemWithTitle:"Open App" action:nil keyEquivalent:nil] setSubmenu:appsMenu];
    [fileMenu addItem:[CPMenuItem separatorItem]];
    [fileMenu addItemWithTitle:"Close File \"xxx\"" action:nil keyEquivalent:nil];
    [fileMenu addItemWithTitle:"Save" action:nil keyEquivalent:nil];
    [fileMenu addItemWithTitle:"Save All" action:nil keyEquivalent:nil];
    var actionsMenu = [CPMenu new];
    [sidebarController setActionsMenu:actionsMenu];
    [[fileMenu addItemWithTitle:"Actions" action:nil keyEquivalent:nil] setSubmenu:actionsMenu];
    [[mainMenu addItemWithTitle:"File" action:nil keyEquivalent:nil] setSubmenu:fileMenu];

    var appMenu = [CPMenu new];
    [[appMenu addItemWithTitle:"New Environment" action:@selector(showNewEnv) keyEquivalent:nil]
        setTarget:sidebarController];
    [[appMenu addItemWithTitle:"Use Library…" action:@selector(showWindow:) keyEquivalent:nil]
        setTarget:sidebarController.useLibPanelController];
    [appMenu addItem:[CPMenuItem separatorItem]];
    [appMenu addItemWithTitle:"Diff…" action:nil keyEquivalent:nil];
    [appMenu addItemWithTitle:"Commit…" action:nil keyEquivalent:nil];
    [appMenu addItem:[CPMenuItem separatorItem]];
    [appMenu addItemWithTitle:"Manage Domains…" action:nil keyEquivalent:nil];
    [appMenu addItemWithTitle:"Publish App…" action:nil keyEquivalent:nil];
    [appMenu addItemWithTitle:"Delete App…" action:@selector(deleteApp) keyEquivalent:nil];
    [[mainMenu addItemWithTitle:"App" action:nil keyEquivalent:nil] setSubmenu:appMenu];

    var viewMenu = [CPMenu new];
    [[viewMenu addItemWithTitle:"Eval" action:nil keyEquivalent:nil] setSubmenu:[CPMenu new]];
    [[viewMenu addItemWithTitle:"Preview" action:nil keyEquivalent:nil] setSubmenu:[CPMenu new]];
    [viewMenu addItemWithTitle:"Git" action:nil keyEquivalent:nil];
    [[mainMenu addItemWithTitle:"View" action:nil keyEquivalent:nil] setSubmenu:viewMenu];

    var helpMenu = [CPMenu new];
    [helpMenu addItemWithTitle:"Getting Started" action:nil keyEquivalent:nil];
    [helpMenu addItemWithTitle:"User Guide" action:nil keyEquivalent:nil];
    [helpMenu addItemWithTitle:"Reference" action:nil keyEquivalent:nil];
    [helpMenu addItem:[CPMenuItem separatorItem]];
    [[helpMenu addItemWithTitle:"Contact…" action:@selector(showWindow:) keyEquivalent:nil]
        setTarget:contactPanelController];
    [helpMenu addItemWithTitle:"Blog" action:nil keyEquivalent:nil];
    [helpMenu addItemWithTitle:"Twitter" action:nil keyEquivalent:nil];
    [[mainMenu addItemWithTitle:"Help" action:nil keyEquivalent:nil] setSubmenu:helpMenu];

    [akshellMenu, fileMenu, appMenu, helpMenu].forEach(
        function (menu) { [menu setAutoenablesItems:NO]; });

    [mainMenu addItem:[CPMenuItem separatorItem]];
    [self addUserMenus];

    var toolbar = [CPToolbar new];
    [toolbar setDelegate:self];
    [mainWindow setToolbar:toolbar];
    [self fillAppMenus];

    [DATA addObserver:self forKeyPath:"username" options:CPKeyValueObservingOptionNew context:nil];
    [DATA addObserver:self forKeyPath:"apps" options:CPKeyValueObservingOptionNew context:nil];
}

- (CPPopUpButton)appPopUpButton
{
    return [[[[mainWindow toolbar] items][0] view] subviews][0];
}

- (void)addUserMenus
{
    var mainMenu = [CPApp mainMenu];
    if (DATA.username) {
        [passwordMenuItem setTitle:"Change Password…"];
        [passwordMenuItem setTarget:changePasswordPanelController];
        [mainMenu addItemWithTitle:"Log Out (" + DATA.username + ")" action:@selector(logOut) keyEquivalent:nil];
    } else {
        [passwordMenuItem setTitle:"Reset Password…"];
        [passwordMenuItem setTarget:resetPasswordPanelController];
        [[mainMenu addItemWithTitle:"Sign Up" action:@selector(showWindow:) keyEquivalent:nil]
                setTarget:signupPanelController];
        [[mainMenu addItemWithTitle:"Log In" action:@selector(showWindow:) keyEquivalent:nil]
                setTarget:loginPanelController];
    }
}

- (void)fillAppMenus
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
    [self setAppItemsEnabled:DATA.apps.length];
}

- (void)observeValueForKeyPath:(CPString)keyPath ofObject:(id)object change:(CPDictionary)change context:(id)context
{
    switch (keyPath) {
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
        break
    }
}

- (void)setAppItemsEnabled:(BOOL)enabled
{
    var mainMenu = [CPApp mainMenu];
    [[mainMenu itemAtIndex:2] setEnabled:enabled];
    [[mainMenu itemAtIndex:3] setEnabled:enabled];
    [fileMenu _highlightItemAtIndex:CPNotFound];
    for (var i = 1; i < 9; ++i)
        [[fileMenu itemAtIndex:i] setEnabled:enabled];
    [[mainWindow toolbar] items].forEach(
        function (item) { [item setEnabled:enabled]; });
}

@end

@implementation AppController (MenuDelegate)

- (void)logOut
{
    [[[HTTPRequest alloc] initWithMethod:"POST" URL:"/logout" target:self action:@selector(didLogOut)] send];
}

- (void)didLogOut
{
    [DATA setUsername:""];
    [DATA setEmail:""];
    [DATA setAppNames:["hello-world"] config:{}];
}

- (void)switchApp:(CPMenuItem)sender
{
    if ([sender title] == DATA.app.name)
        return;
    [[appsMenu itemAtIndex:DATA.appIndex] setState:CPOffState];
    var index = [[sender menu] indexOfItem:sender];
    [[appsMenu itemAtIndex:index] setState:CPOnState];
    [[self appPopUpButton] selectItemAtIndex:index];
    [DATA setAppIndex:index];
}

- (void)didCreateAppWithName:(CPString)appName
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
    } else {
        [self setAppItemsEnabled:YES];
    }
    [appsMenu insertItem:[item copy] atIndex:index];
    DATA.apps.splice(index, 0, [[App alloc] initWithName:appName]);
    [DATA setAppIndex:index];
}

- (void)deleteApp
{
    [[[Confirm alloc] initWithMessage:"Are you sure want to delete the app \"" + DATA.app.name + "\"?"
                              comment:"You cannot undo this action."
                               target:self
                               action:@selector(doDeleteApp)]
        showPanel];
}

- (void)doDeleteApp
{
    [[[HTTPRequest alloc] initWithMethod:"DELETE" URL:[DATA.app url]] send];
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
    } else {
        [self setAppItemsEnabled:NO];
    }
    [DATA setAppIndex:0];
}

@end

@implementation AppController (ToolbarDelegate)

- (CPArray)toolbarAllowedItemIdentifiers:(CPToolbar)toolbar
{
    return [CPToolbarSpaceItemIdentifier, "App", "New", "Save", "Save All", "Eval", "Preview", "Git", "Diff", "Commit"];
}

- (CPArray)toolbarDefaultItemIdentifiers:(CPToolbar)toolbar
{
    return [
        "App", CPToolbarSpaceItemIdentifier,
        "New", "Save", "Save All", CPToolbarSpaceItemIdentifier,
        "Eval", "Preview", "Git", CPToolbarSpaceItemIdentifier,
        "Diff", "Commit"
    ];
}

- (CPToolbarItem)toolbar:(CPToolbar)toolbar itemForItemIdentifier:(CPString)itemIdentifier willBeInsertedIntoToolbar:(BOOL)flag
{
    var item = [[CPToolbarItem alloc] initWithItemIdentifier:itemIdentifier];
    [item setLabel:itemIdentifier];
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
        var image = [[CPImage alloc] initWithContentsOfFile:[[CPBundle mainBundle] pathForResource:itemIdentifier + ".png"]];
        [item setImage:image];
        [item setMinSize:CGSizeMake(32, 32)];
        switch (itemIdentifier) {
        case "New":
            [item setTarget:sidebarController];
            [item setAction:@selector(showNewFile)];
            break;
        }
    }
    return item;
}

@end

@implementation AppController (SplitViewDelegate)

- (unsigned)splitView:(CPSplitView)splitView constrainSplitPosition:(unsigned)position ofSubviewAt:(unsigned)index
{
    position = MIN(MAX(position, 150), [splitView frameSize].width - 500);
    [[[mainWindow toolbar] items][0] setMinSize:CGSizeMake(position - 35, 32)];
    return position;
}

@end
