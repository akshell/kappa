// (c) 2010-2011 by Anton Korenyushkin

@import "PanelController.j"

@implementation AboutPanelController : PanelController
{
    @outlet CPTextField akshellLabel;
    @outlet CPTextField versionLabel;
    @outlet CPTextField copyrightLabel;
    @outlet CPTextField rightsLabel;
}

- (id)init // public
{
    return [super initWithWindowCibName:"AboutPanel"];
}

- (void)awakeFromCib // private
{
    [akshellLabel, versionLabel, copyrightLabel, rightsLabel].forEach(
        function (label) { [label setAlignment:CPCenterTextAlignment]; });
    [akshellLabel setFont:[CPFont boldSystemFontOfSize:14]];
}

@end
