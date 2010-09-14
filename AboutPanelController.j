// (c) 2010 by Anton Korenyushkin

@import <AppKit/CPWindowController.j>


@implementation AboutPanelController : CPWindowController
{
    @outlet CPTextField akshellLabel;
    @outlet CPTextField versionLabel;
    @outlet CPTextField copyrightLabel;
    @outlet CPTextField rightsLabel;
}

- (void)awakeFromCib
{
    [akshellLabel, versionLabel, copyrightLabel, rightsLabel].forEach(
        function (label) { [label setAlignment:CPCenterTextAlignment]; });
    [akshellLabel setFont:[CPFont boldSystemFontOfSize:14]];
}

@end
