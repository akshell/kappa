// (c) 2010 by Anton Korenyushkin

@import "Manager.j"

@implementation Env (EnvManager)

- (CPString)imageName // public
{
    return "Env";
}

- (BOOL)isExpandable // public
{
    return NO;
}

@end

@implementation App (EnvManager)

- (BOOL)hasEnvWithName:(CPString)aName // public
{
    var env = [self envWithName:aName];
    if (env)
        [[[Alert alloc] initWithMessage:"The environment \"" + env.name + "\" already exists."
                                comment:"Environment name must be case-insensitively unique."]
            showPanel];
    return !!env;
}

@end

@implementation EnvManager : Manager

- (CPString)name // public
{
    return "Environments";
}

- (CPString)imageName // public
{
    return "Envs";
}

- (unsigned)numberOfChildren // public
{
    return app.envs ? app.envs.length : 0;
}

- (Env)childAtIndex:(unsigned)index // public
{
    return app.envs[index];
}

- (CPString)URL // protected
{
    return [app URL] + "envs/";
}

- (void)processRepr:(CPArray)envNames // protected
{
    [app setEnvs:[[[Env alloc] initWithName:"release"]].concat(
            envNames.map(function (name) { return [[Env alloc] initWithName:name]; }))];
}

- (void)insertItem:(Env)env // protected
{
    var nameLower = env.name.toLowerCase();
    for (var i = 1; i < app.envs.length; ++i)
        if (app.envs[i].name.toLowerCase() > nameLower)
            break;
    app.envs.splice(i, 0, env);
}

- (void)removeItem:(Env)env // protected
{
    [app.envs removeObject:env];
}

- (Env)newEnv // public
{
    var name = "untitled-env";
    if ([app envWithName:name]) {
        var baseName = name + "-";
        for (var i = 2;; ++i) {
            name = baseName + i;
            if (![app envWithName:name])
                break;
        }
    }
    var env = [[Env alloc] initWithName:name];
    [self insertNewItem:env];
    return env;
}

- (void)createItem:(Env)env withName:(CPString)name // protected
{
    if (name && name != env.name && ![app hasEnvWithName:name])
        [env setName:name];
    [self createItem:env byRequestWithMethod:"POST" URL:[self URL] data:{name: env.name}]
}

- (void)renameItem:(Env)env to:(CPString)name // protected
{
    if (![app hasEnvWithName:name])
        [self renameItem:env to:name byRequestWithMethod:"POST" URL:[self URL] + env.name data:{action: "rename", name: name}];
}

- (CPString)descriptionOfItems:(CPArray)envs // public
{
    return envs.length == 1 ? "environment \"" + envs[0].name + "\"" : "selected " + envs.length + " environments";
}

- (void)deleteItems:(CPArray)envs // public
{
    envs.forEach(
        function (env) {
            [self deleteItems:[env] byRequestWithMethod:"DELETE" URL:[self URL] + env.name data:nil];
        });
    [self notify];
}

@end
