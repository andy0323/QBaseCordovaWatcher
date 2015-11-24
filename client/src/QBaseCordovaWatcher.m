#import "QBaseCordovaWatcher.h"
#import "AsyncUdpSocket.h"

#import "AppDelegate.h"

NSString *const QBaseCordovaWatcherFileChangedNotification = @"QBaseCordovaWatcherFileChangedNotification";

@interface QBaseCordovaWatcher()<AsyncUdpSocketDelegate>
@property (nonatomic, strong) AsyncUdpSocket *socket;   // 套接字
@property (nonatomic, assign) NSInteger port;           // 监听端口
@end

@implementation QBaseCordovaWatcher

+ (instancetype)sharedInstance
{
    static QBaseCordovaWatcher *instance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[self alloc] init];
    });
    return instance;
}

- (instancetype)init
{
    if (self = [super init]) {
        self.port = 30012;
    }
    return self;
}

#pragma mark -
#pragma mark 公有方法

+ (void)start
{
    [[QBaseCordovaWatcher sharedInstance] initDocument];
    [[QBaseCordovaWatcher sharedInstance] start];
}

- (void)initDocument
{
    // 沙盒路径下的www
    NSString *wwwDir = QBASE_DEBUG_WWW_DIR;
    
    NSFileManager *manager = [NSFileManager defaultManager];
    BOOL exist = [manager fileExistsAtPath:wwwDir];
    if (!exist) {
        NSString *appDir = [[NSBundle mainBundle] pathForResource:@"www" ofType:@""];
        // 如果不存在.复制.App的www到Documents
        [manager copyItemAtPath:appDir
                         toPath:wwwDir
                          error:nil];
    }
}

- (void)start
{
    self.socket = [[AsyncUdpSocket alloc] initWithDelegate:self];
    [self.socket bindToPort:self.port error:nil];
    [self.socket receiveWithTimeout:-1 tag:100];
}

#pragma mark -
#pragma mark AsyncUdpSocketDelegate

- (BOOL)onUdpSocket:(AsyncUdpSocket *)sock didReceiveData:(NSData *)data withTag:(long)tag fromHost:(NSString *)host port:(UInt16)port
{
    [self messageHandler:data];
    [sock receiveWithTimeout:-1 tag:tag];
    return YES;
}

- (void)messageHandler:(NSData *)messageData
{
    NSDictionary *messageJson = [NSJSONSerialization JSONObjectWithData:messageData options:0 error:nil];
    
    NSString *path = messageJson[@"path"];
    NSString *content = messageJson[@"content"];
    
    // 找到客户端指定的文件路径
    NSString *filePath = [NSString stringWithFormat:@"%@/%@", QBASE_DEBUG_WWW_DIR, path];

    NSError *error;
    [content writeToFile:filePath
              atomically:NO
                encoding:NSUTF8StringEncoding
                   error:&error];

    if (!error) {
        [[NSNotificationCenter defaultCenter] postNotificationName:QBaseCordovaWatcherFileChangedNotification object:nil];
    }else {
        NSLog(@"Update error");
    }
}

@end
