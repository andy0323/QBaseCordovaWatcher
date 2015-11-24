#import "QBaseCordovaWatcher.h"
#import "AsyncUdpSocket.h"
#import "SSZipArchive.h"

NSString *const QBaseCordovaWatcherFileChangedNotification = @"QBaseCordovaWatcherFileChangedNotification";

@interface QBaseCordovaWatcher()<AsyncUdpSocketDelegate, UIAlertViewDelegate, NSURLConnectionDataDelegate>
{
    NSMutableData *_zipData;
    NSDictionary *_messageJson;
}
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
        _zipData = [[NSMutableData alloc] init];
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
    NSString *wwwDir = QBASE_DEBUG_WWW_DIR_PATH;
    
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
    _messageJson = messageJson;
    
    NSString *event = messageJson[@"event"];
    if ([event isEqualToString:@"update"]) {
        [self updateHandler:messageJson];
    }else if ([event isEqualToString:@"watch"]) {
        [self watcherHandler:messageJson];
    }
}

- (void)updateHandler:(NSDictionary *)messageJson
{
    UIAlertView *updateAlert = [[UIAlertView alloc] initWithTitle:@"版本更新" message:@"是否对客户端进行版本更新" delegate:self cancelButtonTitle:@"取消" otherButtonTitles:@"确认", nil];
    [updateAlert show];
}

- (void)watcherHandler:(NSDictionary *)messageJson
{
    BOOL isExists = [messageJson[@"exists"] boolValue];
    NSString *path = messageJson[@"path"];
    NSString *content = messageJson[@"content"];
    
    // 找到客户端指定的文件路径
    NSString *filePath = [NSString stringWithFormat:@"%@/%@", QBASE_DEBUG_WWW_DIR_PATH, path];
    
    // 如果远端已经删除该文件，客户端进行相应的移除
    if (!isExists) {
        [[NSFileManager defaultManager] removeItemAtPath:filePath
                                                   error:nil];
        return;
    }
    
    // 如果远端进行了更新操作，客户端进行相应的覆盖
    NSError *error;
    [content writeToFile:filePath
              atomically:NO
                encoding:NSUTF8StringEncoding
                   error:&error];
    
    // 更新完成，刷新页面
    if (!error) {
        [[NSNotificationCenter defaultCenter] postNotificationName:QBaseCordovaWatcherFileChangedNotification object:nil];
    }else {
        NSLog(@"Update error");
    }
}

#pragma mark -
#pragma mark UIAlertViewDelegate

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == 0) {
        return;
    }
    
    NSString *zipDownloadURL = _messageJson[@"url"];
    
    // 下载最新的源码包
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:zipDownloadURL]];
    NSURLConnection *connection = [NSURLConnection connectionWithRequest:request
                                                                delegate:self];
    [connection start];
}

#pragma mark -
#pragma mark NSURLConnectionDataDelegate

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
    _zipData.length = 0;
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    [_zipData appendData:data];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    NSFileManager *manager = [NSFileManager defaultManager];
    BOOL isExists = [manager fileExistsAtPath:QBASE_DEBUG_ZIP_DOWNLOAD_URL];
    if (isExists) {
        [manager removeItemAtPath:QBASE_DEBUG_ZIP_DOWNLOAD_URL error:nil];
        [manager removeItemAtPath:QBASE_DEBUG_WWW_DIR_PATH error:nil];
    }
    
    // 解压到指定的文件夹
    [_zipData writeToFile:QBASE_DEBUG_ZIP_DOWNLOAD_URL atomically:NO];
    
    // 压缩文件
    [SSZipArchive unzipFileAtPath:QBASE_DEBUG_ZIP_DOWNLOAD_URL
                    toDestination:QBASE_DEBUG_ZIP_UNZIP_PATH];
    
    // 更新页面
    [[NSNotificationCenter defaultCenter] postNotificationName:QBaseCordovaWatcherFileChangedNotification object:nil];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    UIAlertView *errorAlert = [[UIAlertView alloc] initWithTitle:@""
                                                         message:@"下载失败，请检查网络状态是否正常"
                                                        delegate:nil
                                               cancelButtonTitle:@"确认"
                                               otherButtonTitles:nil, nil];
    [errorAlert show];
}

@end
