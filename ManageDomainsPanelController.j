// (c) 2010 by Anton Korenyushkin

@import "SignupPanelController.j"

@implementation ManageDomainsPanelController : RequestPanelController
{
    @outlet CPTextField freeDomainNameField;
    @outlet CPTableView tableView;
    @outlet CPImageView spinnerImageView;
    @outlet CPSegmentedControl segmentedControl;
    @outlet CPButton saveButton;
    App app;
    SignupPanelController signupPanelController;
    CPString freeDomainName;
    CPArray customDomains;
    CPArray newCustomDomains;
}

- (id)initWithApp:(App)anApp signupPanelController:(SignupPanelController)aSignupPanelController // public
{
    if (self = [super initWithWindowCibName:"ManageDomainsPanel"]) {
        app = anApp;
        signupPanelController = aSignupPanelController;
        freeDomainName = "";
        customDomains = [];
    }
    return self;
}

- (void)awakeFromCib // private
{
    [[tableView superview] setBackgroundColor:[CPColor whiteColor]];
    [tableView setColumnAutoresizingStyle:CPTableViewLastColumnOnlyAutoresizingStyle];
    [tableView setSelectionHighlightStyle:CPTableViewSelectionHighlightStyleSourceList];
    [tableView setHeaderView:nil];
    [tableView setCornerView:nil];
    [tableView addTableColumn:[CPTableColumn new]];
    [tableView sizeLastColumnToFit];

    [segmentedControl setTarget:self];
    [segmentedControl setAction:@selector(didClickOnSegmentedControl)];
    [segmentedControl setTrackingMode:CPSegmentSwitchTrackingMomentary];
    [segmentedControl setFrameSize:CGSizeMake(0, 24)];
    [segmentedControl setSegmentCount:2];
    var plusImagePath = [[CPBundle bundleForClass:[CPButtonBar class]] pathForResource:@"plus_button.png"];
    [segmentedControl setImage:[[CPImage alloc] initWithContentsOfFile:plusImagePath] forSegment:0];
    [segmentedControl setWidth:33 forSegment:0];
    var minusImagePath = [[CPBundle bundleForClass:[CPButtonBar class]] pathForResource:@"minus_button.png"];
    [segmentedControl setImage:[[CPImage alloc] initWithContentsOfFile:minusImagePath] forSegment:1];
    [segmentedControl setWidth:34 forSegment:1];
    [segmentedControl setEnabled:NO forSegment:1];

    if (DATA.username) {
        [freeDomainNameField setEnabled:NO];
        [segmentedControl setEnabled:NO forSegment:0];
        [saveButton setEnabled:NO];
        [self requestWithMethod:"GET" URL:[app URL] + "domains" data:nil context:nil selector:@selector(didGetDomains:)];
    } else {
        [self populate];
    }
}

- (void)didGetDomains:(CPArray)domains // private
{
    domains.forEach(
        function (domain) {
            var index = domain.length - DomainSuffix.length;
            if (!freeDomainName && domain.substring(index) == DomainSuffix)
                freeDomainName = domain.substring(0, index);
            else
                customDomains.push(domain);
        });
    [freeDomainNameField setEnabled:YES];
    [segmentedControl setEnabled:YES forSegment:0];
    [saveButton setEnabled:YES];
    [self populate];
}

- (void)populate // private
{
    var window = [self window];
    [window setTitle:"Manage Domains"];
    [freeDomainNameField setStringValue:freeDomainName];
    [spinnerImageView removeFromSuperview];
    newCustomDomains = customDomains.slice();
    [tableView setDataSource:self];
    [tableView setDelegate:self];
    [window makeFirstResponder:freeDomainNameField];
}

- (unsigned)numberOfRowsInTableView:(CPTableView)aTableView // private
{
    return newCustomDomains.length;
}

- (id)tableView:(CPTableView)aTableView objectValueForTableColumn:(unsigned)column row:(unsigned)row // private
{
    return newCustomDomains[row];
}

- (void)tableViewSelectionDidChange:(id)sender // private
{
    setTimeout(
        function () {
            var row = [tableView selectedRow];
            [segmentedControl setEnabled:row != CPNotFound && row < newCustomDomains.length forSegment:1];
        },
        0);
}

- (void)didClickOnSegmentedControl // private
{
    if ([segmentedControl selectedSegment] == 0) {
        var row = newCustomDomains.length;
        newCustomDomains.push("");
        [tableView reloadData];
        var frame = [tableView frameOfDataViewAtColumn:0 row:row];
        [tableView scrollRectToVisible:frame];
        var textField = [[CPTextField alloc] initWithFrame:CGRectMake(-2, CGRectGetMinY(frame) - 5, 262, 30)];
        [textField setDelegate:self];
        [textField setTarget:self];
        [textField setAction:@selector(addCustomDomainFromTextField:)];
        [textField setBordered:YES];
        [textField setBezeled:YES];
        [textField setEditable:YES];
        [tableView addSubview:textField];
        [[self window] makeFirstResponder:textField];
    } else {
        newCustomDomains.splice([tableView selectedRow], 1);
        [tableView reloadData];
    }
}

- (void)controlTextDidBlur:(CPNotification)notification // private
{
    [self addCustomDomainFromTextField:[notification object]];
}

- (void)addCustomDomainFromTextField:(CPTextField)textField // private
{
    [textField setDelegate:nil];
    [textField removeFromSuperview];
    var domain = [textField stringValue].trim();
    if (domain)
        newCustomDomains[newCustomDomains.length - 1] = domain;
    else
        newCustomDomains.splice(newCustomDomains.length - 1, 1);
    [tableView reloadData];
}

- (@action)submit:(id)sender // private
{
    if (DATA.username) {
        [self doSubmit];
    } else {
        [signupPanelController setTarget:self];
        [signupPanelController setAction:@selector(doSubmit)];
        [signupPanelController showWindow:nil];
    }
}

- (void)doSubmit // private
{
    var newFreeDomainName = [freeDomainNameField stringValue];
    [self requestWithMethod:"PUT"
                        URL:[app URL] + "domains"
                       data:newFreeDomainName ? newCustomDomains.concat(newFreeDomainName + DomainSuffix) : newCustomDomains
                    context:{freeDomainName: newFreeDomainName, customDomains: newCustomDomains.slice()}
                   selector:@selector(didPutDomains:withContext:)];
}

- (void)didPutDomains:(JSObject)data withContext:(JSObject)context // private
{
    freeDomainName = context.freeDomainName;
    customDomains = context.customDomains;
    [self close];
}

- (void)windowWillClose:(id)sender // private
{
    if (!newCustomDomains)
        return;
    [freeDomainNameField setStringValue:freeDomainName];
    newCustomDomains = customDomains.slice();
    [tableView reloadData];
}

@end
