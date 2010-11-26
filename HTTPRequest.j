// (c) 2010 by Anton Korenyushkin

@import "Alert.j"

@implementation HTTPRequest : CPObject
{
    JSObject request;
    SEL finishAction @accessors;
    SEL errorAction @accessors;
    SEL errorMessageAction @accessors;
    JSObject context @accessors;
    CPWindow window @accessors;
}

- (id)initWithMethod:(CPString)method URL:(CPString)url target:(id)target action:(SEL)action // public
{
    if (self = [super init]) {
        showsAlert = YES;
        request = new XMLHttpRequest();
        request.open(method, url);
        request.onreadystatechange = function () {
            if (request.readyState != 4)
                return;
            var isJSON = request.getResponseHeader("Content-Type") == "application/json; charset=utf-8";
            var data = isJSON ? JSON.parse(request.responseText) : request.responseText;
            if (finishAction)
                objj_msgSend(target, finishAction, data, context);
            if (request.status == 200 || request.status == 201) {
                if (action)
                    objj_msgSend(target, action, data, context);
                return;
            }
            if (errorAction && objj_msgSend(target, errorAction, data, context))
                return;
            var message, comment;
            if (isJSON) {
                message = data.message;
                comment = data.comment;
            } else {
                message = data;
            }
            var alert = [[Alert alloc] initWithMessage:message comment:comment];
            if (errorMessageAction) {
                [alert setTarget:target];
                [alert setAction:errorMessageAction];
            }
            if (window)
                [alert showSheetForWindow:window];
            else
                [alert showPanel];
        };
        [self setValue:"XMLHttpRequest" forHeader:"X-Requested-With"];
    }
    return self;
}

- (id)initWithMethod:(CPString)method URL:(CPString)url // public
{
    return [self initWithMethod:method URL:url target:nil action:nil];
}

- (void)setValue:(CPString)value forHeader:(CPString)header // public
{
    request.setRequestHeader(header, value);
}

- (void)send:(JSObject)data // public
{
    if (data !== nil && typeof(data) != "string" && !(data instanceof DOMFile)) {
        [self setValue:"application/json" forHeader:"Content-Type"];
        data = JSON.stringify(data);
    }
    request.send(data || nil);
}

- (void)send // public
{
    request.send(nil);
}

@end
