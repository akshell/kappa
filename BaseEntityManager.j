// (c) 2010-2011 by Anton Korenyushkin

@import "BaseManager.j"
@import "HTTPRequest.j"
@import "EntityDeleting.j"

@implementation BaseEntityManager : BaseManager
{
    BOOL isLoading;
    id revealTarget @accessors;
    SEL revealAction @accessors;
}

- (void)load // public
{
    isLoading = YES;
    [[[HTTPRequest alloc] initWithMethod:"GET" URL:[self URL] target:self action:@selector(didReceiveRepr:)] send];
}

- (void)didReceiveRepr:(JSObject)repr // private
{
    isLoading = NO;
    [self processRepr:repr];
}

- (BOOL)isExpandable // public
{
    return YES;
}

- (void)revealItems:(CPArray)items // protected
{
    objj_msgSend(revealTarget, revealAction, items);
}

- (void)insertNewItem:(id)item // protected
{
    item.isEditable = YES;
    item.manager = self;
    [self insertItem:item];
    [self notify];
    [self revealItems:[item]];
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
    [self revealItems:[item]];
}

- (void)requestWithMethod:(CPString)method
                      URL:(CPString)url
                     data:(JSObject)data
                 selector:(SEL)selector
            errorSelector:(SEL)errorSelector
                     args:(JSObject)args // protected
{
    var request = [[HTTPRequest alloc] initWithMethod:method
                                                  URL:url
                                               target:self
                                               action:@selector(didReceiveResponse:withContext:)];
    [request setErrorAction:@selector(didReceiveError:withContext:)];
    [request setContext:{selector: selector, errorSelector: errorSelector, args: args}];
    [request send:data];
}

- (void)didReceiveResponse:(JSObject)data withContext:(JSObject)context // private
{
    objj_msgSend.apply(nil, [self, context.selector].concat(context.args));
}

- (void)didReceiveError:(JSObject)data withContext:(JSObject)context // private
{
    objj_msgSend.apply(nil, [self, context.errorSelector].concat(context.args));
}

- (void)createItem:(id)item byRequestWithMethod:(CPString)method URL:(CPString)url data:(JSObject)data // protected
{
    item.isLoading = YES;
    [self requestWithMethod:method
                        URL:url
                       data:data
                   selector:@selector(didCreateItem:)
              errorSelector:@selector(didFailToCreateItem:)
                       args:[item]];
}

- (void)didCreateItem:(id)item // protected
{
    delete item.isLoading;
    [self notify];
}

- (void)didFailToCreateItem:(id)item // private
{
    [self removeItem:item];
    [item noteDeleted];
    [self notify];
}

- (void)changeNameOfItem:(id)item to:(CPString)name // protected
{
    [item setName:name];
    [self removeItem:item];
    [self insertItem:item];
}

- (void)renameItem:(id)item
                to:(CPString)name
byRequestWithMethod:(CPString)method
               URL:(CPString)url
              data:(JSObject)data // protected
{
    item.isLoading = YES;
    item.oldName = item.name;
    [self changeNameOfItem:item to:name];
    [self requestWithMethod:method
                        URL:url
                       data:data
                   selector:@selector(didRenameItem:)
              errorSelector:@selector(didFailToRenameItem:)
                       args:[item]];
}

- (void)didRenameItem:(id)item // private
{
    delete item.isLoading;
    delete item.oldName;
    [self notify];
}

- (void)didFailToRenameItem:(id)item // private
{
    [self changeNameOfItem:item to:item.oldName];
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
                       args:[items]];
}

- (void)didDeleteItems:(CPArray)items // private
{
    items.forEach(
        function (item) {
            [self removeItem:item];
            [item noteDeleted];
        });
    [self notify];
}

- (void)didFailToDeleteItems:(CPArray)items // private
{
    items.forEach(function (item) { delete item.isLoading; });
    [self notify];
}

@end
