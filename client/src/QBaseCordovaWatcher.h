#import <Foundation/Foundation.h>

extern NSString *const QBaseCordovaWatcherFileChangedNotification;

#define QBASE_DEBUG_WWW_DIR [NSString stringWithFormat:@"%@/Documents/www", NSHomeDirectory()]

@interface QBaseCordovaWatcher : NSObject

/** 开始监听 */
+ (void)start;

@end
