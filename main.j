// (c) 2010-2011 by Anton Korenyushkin

@import <Foundation/Foundation.j>
@import <Foundation/CPDate.j>
@import <Foundation/CPTimer.j>
@import <AppKit/AppKit.j>
@import <AppKit/CPScrollView.j>
@import <AppKit/CPSegmentedControl.j>

@import "Globals.j";
@import "AppController.j"
@import "CPObject.j"
@import "CPPanel.j"
@import "CPMenu.j"
@import "CPMenuItem.j"
@import "CPOutlineView.j"
@import "CPImage.j"
@import "CPToolbar.j"
@import "CPString.j"

window.onbeforeunload = function () {
    if (!DATA.username) {
        setTimeout(function () { [[[CPApp delegate] signupPanelController] showWindow:nil]; }, 500);
        return "All your changes will be lost unless you sign up."
    }
    if (document.cookie) {
        var request = new XMLHttpRequest();
        request.open("PUT", "/config", false);
        request.setRequestHeader("X-Requested-With", "XMLHttpRequest");
        request.setRequestHeader("Content-Type", "application/json");
        request.send(JSON.stringify([DATA archive]));
    }
    var names = [];
    DATA.apps.forEach(
        function (app) {
            if (app.numberOfModifiedBuffers)
                names.push(app.name);
        });
    var prefix;
    switch (names.length) {
    case 0:
        return;
    case 1:
        prefix = "The app \"" + names[0] + "\" has";
        break;
    case 2:
        prefix = "The apps \"" + names[0] + "\" and \"" + names[1] + "\" have";
        break;
    default:
        prefix = "The apps \"" + names.join("\", \"") + "\" have";
    }
    return prefix + " unsaved files. Your changes will be lost if you don't save them.";
};

function main(args, namedArgs)
{
    CPApplicationMain(args, namedArgs);
}
