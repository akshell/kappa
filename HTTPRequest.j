// (c) 2010 by Anton Korenyushkin

@import "Alert.j"

@implementation HTTPRequest : CPObject
{
    JSObject request;
    CPWindow window;
}

- (void)initWithMethod:(CPString)method
                   URL:(CPString)url
                target:(id)target
         successAction:(SEL)successAction
           errorAction:(SEL)errorAction
{
    if (self = [super init]) {
        request = new XMLHttpRequest();
        request.open(method, url);
        request.onreadystatechange = function () {
            if (request.readyState != 4)
                return;
            var isJSON = request.getResponseHeader("Content-Type") == "application/json; charset=utf-8";
            var data = isJSON ? JSON.parse(request.responseText) : request.responseText;
            if (request.status == 200 || request.status == 201) {
                if (successAction)
                    objj_msgSend(target, successAction, data);
                return;
            }
            var message, comment;
            if (isJSON) {
                message = data.message;
                comment = data.comment;
            } else {
                message = data;
            }
            if (!errorAction)
                target = nil;
            var alert = [[Alert alloc] initWithMessage:message comment:comment target:target action:errorAction];
            if (window)
                [alert showSheetForWindow:window];
            else
                [alert showPanel];
        };
        [self setValue:"XMLHttpRequest" forHeader:"X-Requested-With"];
    }
    return self;
}

- (void)initWithMethod:(CPString)method URL:(CPString)url target:(id)target successAction:(SEL)successAction
{
    return [self initWithMethod:method URL:url target:target successAction:successAction errorAction:nil];
}

- (void)initWithMethod:(CPString)method URL:(CPString)url
{
    return [self initWithMethod:method URL:url target:nil successAction:nil errorAction:nil];
}

- (void)setWindow:(CPWindow)aWindow
{
    window = aWindow;
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
