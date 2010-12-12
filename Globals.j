// (c) 2010 by Anton Korenyushkin

@import "Data.j"

DATA = [Data new];
[DATA loadFromBasis:window.BASIS || {config: {}, appNames: []}]; // Hack for press

SystemFont = [CPFont systemFontOfSize:12];
BoldSystemFont = [CPFont boldSystemFontOfSize:12];

var MonospaceFontName = "Menlo, Consolas, Lucida Console, monospace";
MonospaceFont = [CPFont fontWithName:MonospaceFontName size:14];
BoldMonospaceFont = [CPFont boldFontWithName:MonospaceFontName size:14];

PanelBackgroundColor = [CPColor colorWithWhite:0.96 alpha:1];
PositiveColor = [CPColor colorWithHexString:"25bc24"];
NegativeColor = [CPColor colorWithHexString:"c23621"];
CommentColor = [CPColor colorWithHexString:"33bbc8"];

var host = window.location.host || "www.akshell.com"; // Hack for press
DomainSuffix = host.substring(host.indexOf("."));
