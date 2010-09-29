// (c) 2010 by Anton Korenyushkin

@implementation SidebarController : CPObject
{
    @outlet CPButtonBar buttonBar;
}

- (void)awakeFromCib
{
    var plusButton = [CPButtonBar plusButton];
    var minusButton = [CPButtonBar minusButton];
    var actionPopupButton = [CPButtonBar actionPopupButton];
    var actionMenu = [actionPopupButton menu];
    [actionMenu addItemWithTitle:"New File" action:nil keyEquivalent:nil];
    [actionMenu addItemWithTitle:"New Folder" action:nil keyEquivalent:nil];
    [actionMenu addItemWithTitle:"New Environment" action:nil keyEquivalent:nil];
    [actionMenu addItemWithTitle:"Use Library…" action:nil keyEquivalent:nil];
    [actionMenu addItem:[CPMenuItem separatorItem]];
    [actionMenu addItemWithTitle:"Delete…" action:nil keyEquivalent:nil];
    [actionMenu addItemWithTitle:"Move…" action:nil keyEquivalent:nil];
    [actionMenu addItemWithTitle:"Duplicate" action:nil keyEquivalent:nil];
    [actionMenu addItemWithTitle:"Rename" action:nil keyEquivalent:nil];
    [buttonBar setButtons:[plusButton, minusButton, actionPopupButton]];
}

@end
