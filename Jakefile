// (c) 2010 by Anton Korenyushkin

var ENV = require("system").env,
    FILE = require("file"),
    JAKE = require("jake"),
    task = JAKE.task,
    FileList = JAKE.FileList,
    app = require("cappuccino/jake").app,
    configuration = ENV["CONFIG"] || ENV["CONFIGURATION"] || ENV["c"] || "Debug",
    OS = require("os");

app ("Akshell", function(task)
{
    task.setBuildIntermediatesPath(FILE.join("Build", "Akshell.build", configuration));
    task.setBuildPath(FILE.join("Build", configuration));

    task.setProductName("Akshell");
    task.setIdentifier("com.akshell");
    task.setVersion("0.3");
    task.setAuthor("Anton Korenyushkin");
    task.setEmail("support @nospam@ akshell.com");
    task.setSummary("Akshell");
    task.setSources((new FileList("**/*.j")).exclude(FILE.join("Build", "**")));
    task.setResources(new FileList("Resources/**"));
    task.setInfoPlistPath("Info.plist");

    if (configuration === "Debug")
        task.setCompilerFlags("-DDEBUG -g");
    else
        task.setCompilerFlags("-O");
});

function printResults(configuration)
{
    print("----------------------------");
    print(configuration+" app built at path: "+FILE.join("Build", configuration, "Akshell"));
    print("----------------------------");
}

task ("default", ["Akshell"], function()
{
    printResults(configuration);
});

task ("build", ["default"]);

task ("debug", function()
{
    ENV["CONFIGURATION"] = "Debug";
    JAKE.subjake(["."], "build", ENV);
});

task ("release", function()
{
    ENV["CONFIGURATION"] = "Release";
    JAKE.subjake(["."], "build", ENV);
});

task ("run", ["debug"], function()
{
    OS.system(["open", FILE.join("Build", "Debug", "Akshell", "index.html")]);
});

task ("run-release", ["release"], function()
{
    OS.system(["open", FILE.join("Build", "Release", "Akshell", "index.html")]);
});

task ("deploy", ["release"], function()
{
    FILE.mkdirs(FILE.join("Build", "Deployment", "Akshell"));
    OS.system(["press", "-f", FILE.join("Build", "Release", "Akshell"), FILE.join("Build", "Deployment", "Akshell")]);
    printResults("Deployment");
});
