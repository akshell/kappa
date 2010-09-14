// (c) 2010 by Anton Korenyushkin

@import <Foundation/Foundation.j>
@import <AppKit/AppKit.j>

@import "AboutPanelController.j"


@implementation AppController : CPObject
{
    @outlet CPWindow mainWindow;
    CPPanel aboutPanel;
}

- (void)applicationDidFinishLaunching:(CPNotification)aNotification
{
    var mainMenu = [CPApp mainMenu];
    while ([mainMenu numberOfItems])
        [mainMenu removeItemAtIndex:0];

    var akshellSubmenu = [[CPMenu alloc] init];
    [akshellSubmenu addItemWithTitle:'About Akshell' action:@selector(orderFrontAboutPanel:) keyEquivalent:nil];
    [akshellSubmenu addItem:[CPMenuItem separatorItem]];
    [akshellSubmenu addItemWithTitle:'RSA Key' action:nil keyEquivalent:nil];
    [akshellSubmenu addItemWithTitle:'Change Password...' action:nil keyEquivalent:nil];
    [akshellSubmenu addItemWithTitle:'Log Out' action:nil keyEquivalent:nil];
    [[mainMenu addItemWithTitle:'Akshell' action:nil keyEquivalent:nil] setSubmenu:akshellSubmenu];

    var fileSubmenu = [[CPMenu alloc] init];
    [fileSubmenu addItemWithTitle:'New App...' action:nil keyEquivalent:nil];
    [fileSubmenu addItemWithTitle:'New File' action:nil keyEquivalent:nil];
    [fileSubmenu addItemWithTitle:'New Folder' action:nil keyEquivalent:nil];
    var openAppSubmenu = [[CPMenu alloc] init];
    [[fileSubmenu addItemWithTitle:'Open App' action:nil keyEquivalent:nil] setSubmenu:openAppSubmenu];
    [fileSubmenu addItem:[CPMenuItem separatorItem]];
    [fileSubmenu addItemWithTitle:'Close File "xxx"' action:nil keyEquivalent:nil];
    [fileSubmenu addItemWithTitle:'Save' action:nil keyEquivalent:nil];
    [fileSubmenu addItemWithTitle:'Save All' action:nil keyEquivalent:nil];
    var actionsSubmenu = [[CPMenu alloc] init];
    [actionsSubmenu addItemWithTitle:'Delete...' action:nil keyEquivalent:nil];
    [actionsSubmenu addItemWithTitle:'Move...' action:nil keyEquivalent:nil];
    [actionsSubmenu addItemWithTitle:'Duplicate' action:nil keyEquivalent:nil];
    [actionsSubmenu addItemWithTitle:'Rename' action:nil keyEquivalent:nil];
    [[fileSubmenu addItemWithTitle:'Actions' action:nil keyEquivalent:nil] setSubmenu:actionsSubmenu];
    [[mainMenu addItemWithTitle:'File' action:nil keyEquivalent:nil] setSubmenu:fileSubmenu];

    var appSubmenu = [[CPMenu alloc] init];
    [appSubmenu addItemWithTitle:'New Environment' action:nil keyEquivalent:nil];
    [appSubmenu addItemWithTitle:'Use Library...' action:nil keyEquivalent:nil];
    [appSubmenu addItem:[CPMenuItem separatorItem]];
    [appSubmenu addItemWithTitle:'Manage Domains...' action:nil keyEquivalent:nil];
    [appSubmenu addItemWithTitle:'Publish App...' action:nil keyEquivalent:nil];
    [appSubmenu addItemWithTitle:'Delete App...' action:nil keyEquivalent:nil];
    [[mainMenu addItemWithTitle:'App' action:nil keyEquivalent:nil] setSubmenu:appSubmenu];

    var helpSubmenu = [[CPMenu alloc] init];
    [helpSubmenu addItemWithTitle:'Getting Started' action:nil keyEquivalent:nil];
    [helpSubmenu addItemWithTitle:'User Guide' action:nil keyEquivalent:nil];
    [helpSubmenu addItemWithTitle:'Reference' action:nil keyEquivalent:nil];
    [helpSubmenu addItem:[CPMenuItem separatorItem]];
    [helpSubmenu addItemWithTitle:'Contact...' action:nil keyEquivalent:nil];
    [helpSubmenu addItemWithTitle:'Blog' action:nil keyEquivalent:nil];
    [helpSubmenu addItemWithTitle:'Twitter' action:nil keyEquivalent:nil];
    [[mainMenu addItemWithTitle:'Help' action:nil keyEquivalent:nil] setSubmenu:helpSubmenu];
}

- (void)awakeFromCib
{
}

- (void)orderFrontAboutPanel:(id)sender
{
    if (!aboutPanel) {
        aboutPanel = [[[AboutPanelController alloc] initWithWindowCibName:'AboutPanel'] window];
        [aboutPanel center];
    }
    [aboutPanel orderFront:self];
}

@end
