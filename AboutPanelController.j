// (c) 2010 by Anton Korenyushkin

@implementation AboutPanelController : CPWindowController
{
    @outlet CPTextField akshellLabel;
    @outlet CPTextField versionLabel;
    @outlet CPTextField copyrightLabel;
    @outlet CPTextField rightsLabel;
}

- (id)init
{
    return [super initWithWindowCibName:"AboutPanel"];
}

- (void)awakeFromCib
{
    [akshellLabel, versionLabel, copyrightLabel, rightsLabel].forEach(
        function (label) { [label setAlignment:CPCenterTextAlignment]; });
    [akshellLabel setFont:[CPFont boldSystemFontOfSize:14]];
}

@end
