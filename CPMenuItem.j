// (c) 2010 by Anton Korenyushkin

var uploadInput;

@implementation UploadMenuItemView : _CPMenuItemView

- (void)highlight:(BOOL)shouldHighlight // public
{
    [super highlight:shouldHighlight];
    if (!shouldHighlight) {
        if (uploadInput)
            uploadInput.style.zIndex = -1000;
        return;
    }
    if (!uploadInput) {
        uploadInput = document.createElement("input");
        uploadInput.type = "file";
        uploadInput.style.position = "absolute";
        uploadInput.style.right = "0px";
        uploadInput.style.top = "0px";
        if (CPBrowserIsEngine(CPGeckoBrowserEngine)) {
            uploadInput.style.cssFloat = "right";
            uploadInput.style.fontSize = "1000px";
        } else {
            uploadInput.style.width = "100%";
            uploadInput.style.height = "100%";
        }
        uploadInput.style.opacity = "0";
        uploadInput.style.filter = "alpha(opacity=0)";
        uploadInput.onclick = function () {
            uploadInput.style.zIndex = -1000;
        };
        document.body.appendChild(uploadInput);
    }
    uploadInput.style.zIndex = 1000;
    uploadInput.onchange = function () {
        var menuItem = [self menuItem];
        objj_msgSend(menuItem.uploadTarget, menuItem.uploadAction, uploadInput.files[0]);
        document.body.removeChild(uploadInput);
        uploadInput = nil;
    };
}

@end

@implementation CPMenuItem (Utils)

// FIXME: Dirty hack
- (void)doSetEnabled:(BOOL)flag // public
{
    if (_isEnabled == !!flag)
        return;
    if (flag) {
        _isEnabled = YES;
        [_menuItemView highlight:YES];
        [_menuItemView highlight:NO];
    } else {
        [_menuItemView highlight:NO];
        _isEnabled = NO;
    }
}

- (void)setUploadTarget:(id)uploadTarget action:(SEL)uploadAction // public
{
    self.uploadTarget = uploadTarget;
    self.uploadAction = uploadAction;
    [self _menuItemView].isa = UploadMenuItemView
}

@end
