// (c) 2010 by Anton Korenyushkin

@import "Data.j"

var NotificationName = "DeleteNotification";

@implementation Entity (EntityDeleting)

- (void)addDeleteObserver:(id)observer selector:(SEL)selector // public
{
    [[CPNotificationCenter defaultCenter] addObserver:observer selector:selector name:NotificationName object:self];
}

- (void)removeDeleteObserver:(id)observer // public
{
    [[CPNotificationCenter defaultCenter] removeObserver:observer name:NotificationName object:self];
}

- (void)noteDeleted // public
{
    [[CPNotificationCenter defaultCenter] postNotificationName:NotificationName object:self];
}

@end

@implementation Folder (EntityDeleting)

- (void)noteDeleted // public
{
    [super noteDeleted];
    folders.forEach(function (folder) { [folder noteDeleted]; });
    files.forEach(function (file) { [file noteDeleted]; });
}

@end
