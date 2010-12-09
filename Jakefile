// (c) 2010 by Anton Korenyushkin

var jake = require("jake");
var task = jake.task;
var FileList = jake.FileList;
var app = require("cappuccino/jake").app;
var system = require("os").system;
var frameworksPath = "../../../cappuccino/Build/Release";

function build(task, name, compilerFlags) {
    task.setBuildIntermediatesPath("Build/Intermediate/" + name);
    task.setBuildPath("Build");
    task.setSources((new FileList("**/*.j")).exclude("Build/**"));
    task.setResources(new FileList("Resources/**"));
    task.setInfoPlistPath("Info.plist");
    task.setCompilerFlags(compilerFlags);
}

app("Debug", function (task)
{
    build(task, "Debug", "-DDEBUG -g");
});

app("Release", function (task)
{
    build(task, "Release", "-O");
});

task("Pressed", ["Release"], function ()
{
    system(["press", "-f", "-F", frameworksPath, "Build/Release", "Build/Pressed"]);
});

task("Flattened", ["Pressed"], function ()
{
    system(["flatten", "-f", "-s", "4", "-c", "closure-compiler", "-F", frameworksPath, "Build/Pressed", "Build/Flattened"]);
});
