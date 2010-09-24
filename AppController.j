// (c) 2010 by Anton Korenyushkin

@import "AboutPanelController.j"
@import "KeyPanelController.j"
@import "SignupPanelController.j"
@import "LoginPanelController.j"
@import "ChangePasswordPanelController.j"
@import "ResetPasswordPanelController.j"
@import "HTTPRequest.j"

@implementation AppController : CPObject
{
    @outlet CPWindow mainWindow;
    CPPanel aboutPanel;
    CPPanel keyPanel;
    CPPanel signupPanel;
    CPPanel loginPanel;
    CPPanel passwordPanel;
    CPMenuItem passwordMenuItem;
}

- (void)setUsername:(CPString)username
{
    USERNAME = username;
    [keyPanel, signupPanel, loginPanel, passwordPanel].forEach(
        function (panel) { [panel close]; });
    [KeyPanelController resetKeyValue];
    [passwordMenuItem setTitle:username ? "Change Password…" : "Reset Password…"];
    var mainMenu = [CPApp mainMenu];
    for (var index = [mainMenu numberOfItems]; ![[mainMenu itemAtIndex:--index] isSeparatorItem];)
        [mainMenu removeItemAtIndex:index];

    if (username) {
        [mainMenu addItemWithTitle:"Log Out (" + username + ")" action:@selector(logOut) keyEquivalent:nil];
    } else {
        [mainMenu addItemWithTitle:"Sign Up" action:@selector(displaySignupPanel) keyEquivalent:nil];
        [mainMenu addItemWithTitle:"Log In" action:@selector(displayLoginPanel) keyEquivalent:nil];
    }
}

- (void)applicationDidFinishLaunching:(CPNotification)aNotification
{
    var mainMenu = [CPApp mainMenu];
    while ([mainMenu numberOfItems])
        [mainMenu removeItemAtIndex:0];

    var akshellSubmenu = [CPMenu new];
    [akshellSubmenu addItemWithTitle:"About Akshell" action:@selector(displayAboutPanel) keyEquivalent:nil];
    [akshellSubmenu addItem:[CPMenuItem separatorItem]];
    [akshellSubmenu addItemWithTitle:"SSH Public Key" action:@selector(displayKeyPanel) keyEquivalent:nil];
    passwordMenuItem = [akshellSubmenu addItemWithTitle:"" action:@selector(displayPasswordPanel) keyEquivalent:nil];
    [[mainMenu addItemWithTitle:"Akshell" action:nil keyEquivalent:nil] setSubmenu:akshellSubmenu];

    var fileSubmenu = [CPMenu new];
    [fileSubmenu addItemWithTitle:"New App…" action:nil keyEquivalent:nil];
    [fileSubmenu addItemWithTitle:"New File" action:nil keyEquivalent:nil];
    [fileSubmenu addItemWithTitle:"New Folder" action:nil keyEquivalent:nil];
    var openAppSubmenu = [CPMenu new];
    [[fileSubmenu addItemWithTitle:"Open App" action:nil keyEquivalent:nil] setSubmenu:openAppSubmenu];
    [fileSubmenu addItem:[CPMenuItem separatorItem]];
    [fileSubmenu addItemWithTitle:"Close File \"xxx\"" action:nil keyEquivalent:nil];
    [fileSubmenu addItemWithTitle:"Save" action:nil keyEquivalent:nil];
    [fileSubmenu addItemWithTitle:"Save All" action:nil keyEquivalent:nil];
    var actionsSubmenu = [CPMenu new];
    [actionsSubmenu addItemWithTitle:"Delete…" action:nil keyEquivalent:nil];
    [actionsSubmenu addItemWithTitle:"Move…" action:nil keyEquivalent:nil];
    [actionsSubmenu addItemWithTitle:"Duplicate" action:nil keyEquivalent:nil];
    [actionsSubmenu addItemWithTitle:"Rename" action:nil keyEquivalent:nil];
    [[fileSubmenu addItemWithTitle:"Actions" action:nil keyEquivalent:nil] setSubmenu:actionsSubmenu];
    [[mainMenu addItemWithTitle:"File" action:nil keyEquivalent:nil] setSubmenu:fileSubmenu];

    var appSubmenu = [CPMenu new];
    [appSubmenu addItemWithTitle:"New Environment" action:nil keyEquivalent:nil];
    [appSubmenu addItemWithTitle:"Use Library…" action:nil keyEquivalent:nil];
    [appSubmenu addItem:[CPMenuItem separatorItem]];
    [appSubmenu addItemWithTitle:"Manage Domains…" action:nil keyEquivalent:nil];
    [appSubmenu addItemWithTitle:"Publish App…" action:nil keyEquivalent:nil];
    [appSubmenu addItemWithTitle:"Delete App…" action:nil keyEquivalent:nil];
    [[mainMenu addItemWithTitle:"App" action:nil keyEquivalent:nil] setSubmenu:appSubmenu];

    var helpSubmenu = [CPMenu new];
    [helpSubmenu addItemWithTitle:"Getting Started" action:nil keyEquivalent:nil];
    [helpSubmenu addItemWithTitle:"User Guide" action:nil keyEquivalent:nil];
    [helpSubmenu addItemWithTitle:"Reference" action:nil keyEquivalent:nil];
    [helpSubmenu addItem:[CPMenuItem separatorItem]];
    [helpSubmenu addItemWithTitle:"Contact…" action:nil keyEquivalent:nil];
    [helpSubmenu addItemWithTitle:"Blog" action:nil keyEquivalent:nil];
    [helpSubmenu addItemWithTitle:"Twitter" action:nil keyEquivalent:nil];
    [[mainMenu addItemWithTitle:"Help" action:nil keyEquivalent:nil] setSubmenu:helpSubmenu];

    [akshellSubmenu, fileSubmenu, actionsSubmenu, appSubmenu, helpSubmenu].forEach(
        function (submenu) { [submenu setAutoenablesItems:NO]; });

    [mainMenu addItem:[CPMenuItem separatorItem]];

    [self setUsername:USERNAME];
}

- (void)displayPanel:(CPString)name
{
    if ([self[name] isVisible])
        return;
    var controllerClass = {
        aboutPanel: AboutPanelController,
        keyPanel: KeyPanelController,
        signupPanel: SignupPanelController,
        loginPanel: LoginPanelController,
        passwordPanel: USERNAME ? ChangePasswordPanelController : ResetPasswordPanelController
    }[name];
    self[name] = [[controllerClass new] window];
    [self[name] center];
    [self[name] orderFront:nil];
    [self[name] makeKeyWindow];
}

- (void)displayAboutPanel
{
    [self displayPanel:"aboutPanel"];
}

- (void)displayKeyPanel
{
    [self displayPanel:"keyPanel"];
}

- (void)displaySignupPanel
{
    [self displayPanel:"signupPanel"];
}

- (void)displayLoginPanel
{
    [self displayPanel:"loginPanel"];
}

- (void)displayPasswordPanel
{
    [self displayPanel:"passwordPanel"];
}

- (void)logOut
{
    [[[HTTPRequest alloc] initWithMethod:"POST" URL:"/logout" target:self action:@selector(didLogOut)] send];
}

- (void)didLogOut
{
    [self setUsername:nil];
}

@end
