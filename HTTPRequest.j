// (c) 2010 by Anton Korenyushkin

@implementation HTTPRequest : CPObject
{
    JSObject request;
}

- (void)initWithMethod:(CPString)method URL:(CPString)url target:(id)target action:(SEL)action
{
    if (self = [super init]) {
        request = new XMLHttpRequest();
        request.open(method, url);
        request.onreadystatechange = function () {
            if (request.readyState == 4)
                objj_msgSend(
                    target, action, request.status,
                    (request.getResponseHeader("Content-Type") == "application/json; charset=utf-8"
                     ? JSON.parse(request.responseText) : request.responseText));
        };
        [self setValue:"XMLHttpRequest" forHeader:"X-Requested-With"];
    }
    return self;
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
