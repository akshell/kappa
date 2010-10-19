// (c) 2010 by Anton Korenyushkin

@import "Data.j"
@import "HTTPRequest.j"

var NotificationName = "ManagerNotification";

@implementation Manager : CPObject
{
    App app;
    BOOL isLoading;
    id revealTarget @accessors;
    SEL revealAction @accessors;
}

- (id)initWithApp:(App)anApp // public
{
    if (self = [super init]) {
        app = anApp;
        isLoading = YES;
        if ([self respondsToSelector:@selector(URL)]) {
            var request = [[HTTPRequest alloc] initWithMethod:"GET" URL:[self URL] target:self action:@selector(didReceiveRepr:)];
            [request setErrorAction:@selector(didFailToReceiveRepr)];
            [request send];
        }
    }
    return self;
}

- (void)addObserver:(id)observer selector:(SEL)selector // public
{
    [[CPNotificationCenter defaultCenter] addObserver:observer selector:selector name:NotificationName object:self];
}

- (void)notify // protected
{
    [[CPNotificationCenter defaultCenter] postNotificationName:NotificationName object:self];
}

- (BOOL)isExpandable // public
{
    return YES;
}

- (void)revealItem:(id)item // protected
{
    objj_msgSend(revealTarget, revealAction, item);
}

- (void)didReceiveRepr:(JSObject)repr // private
{
    [self processRepr:repr];
    isLoading = NO;
    [self notify];
}

- (void)didFailToReceiveRepr // private
{
    isLoading = NO;
    [self notify];
}

- (void)insertNewItem:(id)item // protected
{
    item.isEditable = YES;
    item.manager = self;
    [self insertItem:item];
    [self notify];
    [self revealItem:item];
}

- (void)markRenameItem:(id)item // public
{
    item.isEditable = YES;
    item.didExist = YES;
    item.manager = self;
}

- (void)submitItem:(id)item withName:(CPString)name // public
{
    delete item.isEditable;
    delete item.manager;
    if (item.didExist) {
        delete item.didExist;
        if (name && name != item.name)
            [self renameItem:item to:name];
    } else {
        [self createItem:item withName:name];
    }
    [self notify];
}

- (void)reinsertItem:(id)item // private
{
    [self removeItem:item];
    [self insertItem:item];
    [self notify];
    [self revealItem:item];
}

- (void)requestWithMethod:(CPString)method
                      URL:(CPString)url
                     data:(JSObject)data
                 selector:(SEL)selector
            errorSelector:(SEL)errorSelector
                 argument:(JSObject)argument // protected
{
    var request = [[HTTPRequest alloc] initWithMethod:method
                                                  URL:url
                                               target:self
                                               action:@selector(didReceiveResponse:withContext:)];
    [request setErrorAction:@selector(didReceiveError:withContext:)];
    [request setContext:{selector: selector, errorSelector: errorSelector, argument: argument}];
    [request send:data];
}

- (void)didReceiveResponse:(JSObject)data withContext:(JSObject)context // private
{
    objj_msgSend(self, context.selector, context.argument);
}

- (void)didReceiveError:(JSObject)data withContext:(JSObject)context // private
{
    objj_msgSend(self, context.errorSelector, context.argument);
}

- (void)createItem:(id)item byRequestWithMethod:(CPString)method URL:(CPString)url data:(JSObject)data // protected
{
    item.isLoading = YES;
    [self requestWithMethod:method
                        URL:url
                       data:data
                   selector:@selector(didCreateItem:)
              errorSelector:@selector(didFailToCreateItem:)
                   argument:item];
}

- (void)didCreateItem:(id)item // private
{
    delete item.isLoading;
    [self reinsertItem:item];
}

- (void)didFailToCreateItem:(id)item // private
{
    [self removeItem:item];
    [self notify];
}

- (void)renameItem:(id)item
                to:(CPString)name
byRequestWithMethod:(CPString)method
               URL:(CPString)url
              data:(JSObject)data // protected
{
    item.isLoading = YES;
    item.oldName = item.name;
    [item setName:name];
    [self requestWithMethod:method
                        URL:url
                       data:data
                   selector:@selector(didRenameItem:)
              errorSelector:@selector(didFailToRenameItem:)
                   argument:item];
}

- (void)didRenameItem:(id)item // private
{
    delete item.isLoading;
    delete item.oldName;
    [self reinsertItem:item];
}

- (void)didFailToRenameItem:(id)item // private
{
    [item setName:item.oldName];
    delete item.isLoading;
    delete item.oldName;
    [self notify];
}

- (void)deleteItems:(CPArray)items byRequestWithMethod:(CPString)method URL:(CPString)url data:(JSObject)data // protected
{
    items.forEach(function (item) { item.isLoading = YES; });
    [self requestWithMethod:method
                        URL:url
                       data:data
                   selector:@selector(didDeleteItems:)
              errorSelector:@selector(didFailToDeleteItems:)
                   argument:items];
}

- (void)didDeleteItems:(CPArray)items // private
{
    items.forEach(function (item) { [self removeItem:item]; });
    [self notify];
}

- (void)didFailToDeleteItems:(CPArray)items // private
{
    items.forEach(function (item) { delete item.isLoading; });
    [self notify];
}

@end
