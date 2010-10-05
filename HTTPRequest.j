// (c) 2010 by Anton Korenyushkin

@import "Alert.j"

@implementation HTTPRequest : CPObject
{
    JSObject request;
    SEL errorAction @accessors;
    SEL errorMessageAction @accessors;
    JSObject context @accessors;
    CPWindow window @accessors;
}

- (id)initWithMethod:(CPString)method URL:(CPString)url target:(id)target action:(SEL)action
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
            if (request.status == 200 || request.status == 201) {
                if (action)
                    objj_msgSend(target, action, data, context);
                return;
            }
            if (errorAction)
                objj_msgSend(target, errorAction, data, context);
            var message, comment;
            if (isJSON) {
                message = data.message;
                comment = data.comment;
            } else {
                message = data;
            }
            var alert = [[Alert alloc] initWithMessage:message comment:comment target:target action:errorMessageAction];
            if (window)
                [alert showSheetForWindow:window];
            else
                [alert showPanel];
        };
        [self setValue:"XMLHttpRequest" forHeader:"X-Requested-With"];
    }
    return self;
}

- (id)initWithMethod:(CPString)method URL:(CPString)url
{
    return [self initWithMethod:method URL:url target:nil action:nil];
}

- (void)setValue:(CPString)value forHeader:(CPString)header
{
    request.setRequestHeader(header, value);
}

- (void)send:(JSObject)data
{
    if (data && typeof(data) != "string") {
        [self setValue:"application/json" forHeader:"Content-Type"];
        data = JSON.stringify(data);
    }
    request.send(data || null);
}

- (void)send
{
    request.send(null);
}

@end
