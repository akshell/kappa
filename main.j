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
    if (!document.cookie)
        return;
    var request = new XMLHttpRequest();
    request.open("PUT", "/config", false);
    request.setRequestHeader("X-Requested-With", "XMLHttpRequest");
    request.setRequestHeader("Content-Type", "application/json");
    request.send(JSON.stringify([DATA archive]));
};

function main(args, namedArgs)
{
    CPApplicationMain(args, namedArgs);
}
