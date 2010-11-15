// (c) 2010 by Anton Korenyushkin

@import <Foundation/Foundation.j>
@import <AppKit/AppKit.j>
@import <AppKit/CPScrollView.j>

@import "AppController.j"
@import "Data.j";
@import "CPObject.j"
@import "CPPanel.j"
@import "CPMenu.j"
@import "CPMenuItem.j"
@import "CPOutlineView.j"
@import "CPImage.j"
@import "CPToolbar.j"

DATA = [Data new];

window.onbeforeunload = function () {
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
            if (!app.buffers)
                return;
            for (var i = 0; i < app.buffers.length; ++i) {
                if ([app.buffers[i] isModified]) {
                    names.push(app.name);
                    break;
                }
            }
        });
    if (!names.length)
        return;
    return ((names.length == 1
             ? "The app \"" + names[0] + "\" has"
             : names.length == 2
             ? "The apps \"" + names[0] + "\" and \"" + names[1] + "\" have"
             : "The apps \"" + names.join("\", \"") + "\" have") +
            " unsaved files. Your changes will be lost if you don't save them.");
};

function main(args, namedArgs)
{
    CPApplicationMain(args, namedArgs);
}
