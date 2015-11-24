#import <Foundation/Foundation.h>

extern NSString *const QBaseCordovaWatcherFileChangedNotification;

#define QBASE_DEBUG_ZIP_DOWNLOAD_URL [NSString stringWithFormat:@"%@/Documents/www.zip", NSHomeDirectory()]
#define QBASE_DEBUG_ZIP_UNZIP_PATH [NSString stringWithFormat:@"%@/Documents/www", NSHomeDirectory()]

#define QBASE_DEBUG_WWW_DIR_PATH [NSString stringWithFormat:@"%@/Documents/www", NSHomeDirectory()]

@interface QBaseCordovaWatcher : NSObject

/** 开始监听 */
+ (void)start;

@end
