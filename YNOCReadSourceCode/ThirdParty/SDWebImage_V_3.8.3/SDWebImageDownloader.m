/*
 * This file is part of the SDWebImage package.
 * (c) Olivier Poitrey <rs@dailymotion.com>
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */

#import "SDWebImageDownloader.h"
#import "SDWebImageDownloaderOperation.h"
#import <ImageIO/ImageIO.h>

static NSString *const kProgressCallbackKey = @"progress";
static NSString *const kCompletedCallbackKey = @"completed";

@interface SDWebImageDownloader () <NSURLSessionTaskDelegate, NSURLSessionDataDelegate>
// 下载操作队列
@property (strong, nonatomic) NSOperationQueue *downloadQueue;
// 上一个添加的操作队列/weak/用了判断队列依赖顺序
@property (weak, nonatomic) NSOperation *lastAddedOperation;
// 图片下载类
@property (assign, nonatomic) Class operationClass;
// URL 回调字典
// key 是图片的 URL
// value 是一个数组，包含每个图片的回调信息
@property (strong, nonatomic) NSMutableDictionary *URLCallbacks;
// HTTP 头信息
@property (strong, nonatomic) NSMutableDictionary *HTTPHeaders;
// This queue is used to serialize the handling of the network responses of all the download operation in a single queue
// 栅栏拦截异步线程
// 并行的处理所有下载操作的网络响应
// 实现网络序列化的实例
// 对于 URLCallbacks 的所有修改，都需要放在 barrierQueue 中，并通过 dispatch_barrier_sync 形式
// 用于保证线程安全性
@property (SDDispatchQueueSetterSementics, nonatomic) dispatch_queue_t barrierQueue;

// The session in which data tasks will run
@property (strong, nonatomic) NSURLSession *session;

@end

@implementation SDWebImageDownloader

+ (void)initialize {
    // Bind SDNetworkActivityIndicator if available (download it here: http://github.com/rs/SDNetworkActivityIndicator )
    // To use it, just add #import "SDNetworkActivityIndicator.h" in addition to the SDWebImage import
    if (NSClassFromString(@"SDNetworkActivityIndicator")) {

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
        id activityIndicator = [NSClassFromString(@"SDNetworkActivityIndicator") performSelector:NSSelectorFromString(@"sharedActivityIndicator")];
#pragma clang diagnostic pop

        // Remove observer in case it was previously added.
        [[NSNotificationCenter defaultCenter] removeObserver:activityIndicator name:SDWebImageDownloadStartNotification object:nil];
        [[NSNotificationCenter defaultCenter] removeObserver:activityIndicator name:SDWebImageDownloadStopNotification object:nil];

        [[NSNotificationCenter defaultCenter] addObserver:activityIndicator
                                                 selector:NSSelectorFromString(@"startActivity")
                                                     name:SDWebImageDownloadStartNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:activityIndicator
                                                 selector:NSSelectorFromString(@"stopActivity")
                                                     name:SDWebImageDownloadStopNotification object:nil];
    }
}
/// sharedDownloader 单例
+ (SDWebImageDownloader *)sharedDownloader {
    static dispatch_once_t once;
    static id instance;
    dispatch_once(&once, ^{
        instance = [self new];
    });
    return instance;
}

- (id)init {
    if ((self = [super init])) {
        _operationClass = [SDWebImageDownloaderOperation class];
        _shouldDecompressImages = YES;
        _executionOrder = SDWebImageDownloaderFIFOExecutionOrder;
        /// 下载操作队列
        _downloadQueue = [NSOperationQueue new];
        /// 最大下载线程并发数
        _downloadQueue.maxConcurrentOperationCount = 6;
        _URLCallbacks = [NSMutableDictionary new];
        /// 默认不支持Webp 需要自行配置宏，配置请求头信息
#ifdef SD_WEBP
        _HTTPHeaders = [@{@"Accept": @"image/webp,image/*;q=0.8"} mutableCopy];
#else
        _HTTPHeaders = [@{@"Accept": @"image/*;q=0.8"} mutableCopy];
#endif
        /// dispatch 栅栏 barrier
        _barrierQueue = dispatch_queue_create("com.hackemist.SDWebImageDownloaderBarrierQueue", DISPATCH_QUEUE_CONCURRENT);
        /// 超时时间 15.0
        _downloadTimeout = 15.0;
        /// NSURLSession 配置信息
        NSURLSessionConfiguration *sessionConfig = [NSURLSessionConfiguration defaultSessionConfiguration];
        sessionConfig.timeoutIntervalForRequest = _downloadTimeout;

        /**
         *  Create the session for this task
         *  We send nil as delegate queue so that the session creates a serial operation queue for performing all delegate
         *  method calls and completion handler calls.
         */
        self.session = [NSURLSession sessionWithConfiguration:sessionConfig
                                                     delegate:self
                                                delegateQueue:nil];
    }
    return self;
}

- (void)dealloc {
    /// 调用了取消 invalidateAndCancel 释放 session
    [self.session invalidateAndCancel];
    self.session = nil;

    [self.downloadQueue cancelAllOperations];
    SDDispatchQueueRelease(_barrierQueue);
}
/// 设置请求头信息
- (void)setValue:(NSString *)value forHTTPHeaderField:(NSString *)field {
    if (value) {
        self.HTTPHeaders[field] = value;
    }
    else {
        [self.HTTPHeaders removeObjectForKey:field];
    }
}
/// 取请求头信息
- (NSString *)valueForHTTPHeaderField:(NSString *)field {
    return self.HTTPHeaders[field];
}
/// 请求异步线程最大并发数量
- (void)setMaxConcurrentDownloads:(NSInteger)maxConcurrentDownloads {
    _downloadQueue.maxConcurrentOperationCount = maxConcurrentDownloads;
}

- (NSUInteger)currentDownloadCount {
    return _downloadQueue.operationCount;
}

- (NSInteger)maxConcurrentDownloads {
    return _downloadQueue.maxConcurrentOperationCount;
}

- (void)setOperationClass:(Class)operationClass {
    _operationClass = operationClass ?: [SDWebImageDownloaderOperation class];
}
/// 核心下载图片方法
- (id <SDWebImageOperation>)downloadImageWithURL:(NSURL *)url options:(SDWebImageDownloaderOptions)options progress:(SDWebImageDownloaderProgressBlock)progressBlock completed:(SDWebImageDownloaderCompletedBlock)completedBlock {
    /// 下载操作队列
    __block SDWebImageDownloaderOperation *operation;
    // 解除引用环
    __weak __typeof(self)wself = self;

    [self addProgressCallback:progressBlock completedBlock:completedBlock forURL:url createCallback:^{
        /// 这边只会 首次 来到， 设置超时时间
        NSTimeInterval timeoutInterval = wself.downloadTimeout;
        if (timeoutInterval == 0.0) {
            timeoutInterval = 15.0;
        }

        // In order to prevent from potential duplicate caching (NSURLCache + SDImageCache) we disable the cache for image requests if told otherwise
        // 为了防止有可能出现的重复缓存问题，如果没有显式声明需要缓存管理，则不启用图片请求的缓存操作
        NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:url cachePolicy:(options & SDWebImageDownloaderUseNSURLCache ? NSURLRequestUseProtocolCachePolicy : NSURLRequestReloadIgnoringLocalCacheData) timeoutInterval:timeoutInterval];
        // 是否处理 cookie
        request.HTTPShouldHandleCookies = (options & SDWebImageDownloaderHandleCookies);
        // 是否需要传输数据
        // 返回在接到上一个请求的响应之前，是否需要传输数据
        request.HTTPShouldUsePipelining = YES;
        // 设置请求头，需要根据需要过滤指定 URL
        if (wself.headersFilter) {
            request.allHTTPHeaderFields = wself.headersFilter(url, [wself.HTTPHeaders copy]);
        }
        else {
            request.allHTTPHeaderFields = wself.HTTPHeaders;
        }
        /// 创建下载请求队列
        operation = [[wself.operationClass alloc] initWithRequest:request
                                                        inSession:self.session
                                                          options:options
                                                         progress:^(NSInteger receivedSize, NSInteger expectedSize) {
                                                             // strongly self，保证生命周期，防止释放
                                                             SDWebImageDownloader *sself = wself;
                                                             if (!sself) return;
                                                             // URL 回调数组，以 URL 为 key 存储回调 callback
                                                             __block NSArray *callbacksForURL;
                                                             dispatch_sync(sself.barrierQueue, ^{
                                                                 /// 取出从之前存入的callback
                                                                 callbacksForURL = [sself.URLCallbacks[url] copy];
                                                             });
                                                             /// 遍历回调进度callback
                                                             for (NSDictionary *callbacks in callbacksForURL) {
                                                                 dispatch_async(dispatch_get_main_queue(), ^{
                                                                     SDWebImageDownloaderProgressBlock callback = callbacks[kProgressCallbackKey];
                                                                     if (callback) callback(receivedSize, expectedSize);
                                                                 });
                                                             }
                                                         }
                                                        completed:^(UIImage *image, NSData *data, NSError *error, BOOL finished) {
                                                            // strongly self，保证生命周期，防止释放
                                                            SDWebImageDownloader *sself = wself;
                                                            if (!sself) return;
                                                            __block NSArray *callbacksForURL;
                                                            dispatch_barrier_sync(sself.barrierQueue, ^{
                                                                callbacksForURL = [sself.URLCallbacks[url] copy];
                                                                if (finished) {
                                                                    [sself.URLCallbacks removeObjectForKey:url];
                                                                }
                                                            });
                                                            // 回调完成callback
                                                            for (NSDictionary *callbacks in callbacksForURL) {
                                                                SDWebImageDownloaderCompletedBlock callback = callbacks[kCompletedCallbackKey];
                                                                if (callback) callback(image, data, error, finished);
                                                            }
                                                        }
                                                        cancelled:^{
                                                            SDWebImageDownloader *sself = wself;
                                                            if (!sself) return;
                                                            /// cancelled 就移除 callback
                                                            dispatch_barrier_async(sself.barrierQueue, ^{
                                                                [sself.URLCallbacks removeObjectForKey:url];
                                                            });
                                                        }];
        /// shouldDecompressImages 是否需要对图片进行压缩处理
        operation.shouldDecompressImages = wself.shouldDecompressImages;
        /// 设置认证信息
        if (wself.urlCredential) {
            operation.credential = wself.urlCredential;
        } else if (wself.username && wself.password) {
            operation.credential = [NSURLCredential credentialWithUser:wself.username password:wself.password persistence:NSURLCredentialPersistenceForSession];
        }
        /// 设置队列级别
        if (options & SDWebImageDownloaderHighPriority) {
            operation.queuePriority = NSOperationQueuePriorityHigh;
        } else if (options & SDWebImageDownloaderLowPriority) {
            operation.queuePriority = NSOperationQueuePriorityLow;
        }
        /// 添加队列  先进先出
        [wself.downloadQueue addOperation:operation];
        if (wself.executionOrder == SDWebImageDownloaderLIFOExecutionOrder) {
            // Emulate LIFO execution order by systematically adding new operations as last operation's dependency
            /// 队列依赖后进先出 栈
            [wself.lastAddedOperation addDependency:operation];
            wself.lastAddedOperation = operation;
        }
    }];

    return operation;
}

- (void)addProgressCallback:(SDWebImageDownloaderProgressBlock)progressBlock completedBlock:(SDWebImageDownloaderCompletedBlock)completedBlock forURL:(NSURL *)url createCallback:(SDWebImageNoParamsBlock)createCallback {
    // The URL will be used as the key to the callbacks dictionary so it cannot be nil. If it is nil immediately call the completed block with no image or data.
    /// 判空
    if (url == nil) {
        if (completedBlock != nil) {
            completedBlock(nil, nil, nil, NO);
        }
        return;
    }
    /// 异步栅栏 ，异步线程得等待此回调完成才可以执行
    dispatch_barrier_sync(self.barrierQueue, ^{
        BOOL first = NO;
        if (!self.URLCallbacks[url]) {
            self.URLCallbacks[url] = [NSMutableArray new];
            first = YES;
        }
        
        // Handle single download of simultaneous download request for the same URL
        // key 是 url， callbacksForURL 回调字典
        NSMutableArray *callbacksForURL = self.URLCallbacks[url];
        /// 字典
        NSMutableDictionary *callbacks = [NSMutableDictionary new];
        if (progressBlock) callbacks[kProgressCallbackKey] = [progressBlock copy];
        if (completedBlock) callbacks[kCompletedCallbackKey] = [completedBlock copy];
        
        [callbacksForURL addObject:callbacks];
        /// 保存progressBlock 和 completedBlock 回调
        self.URLCallbacks[url] = callbacksForURL;
        if (first) {
            createCallback();
        }
    });
}

- (void)setSuspended:(BOOL)suspended {
    [self.downloadQueue setSuspended:suspended];
}

- (void)cancelAllDownloads {
    [self.downloadQueue cancelAllOperations];
}

#pragma mark Helper methods

- (SDWebImageDownloaderOperation *)operationWithTask:(NSURLSessionTask *)task {
    SDWebImageDownloaderOperation *returnOperation = nil;
    for (SDWebImageDownloaderOperation *operation in self.downloadQueue.operations) {
        if (operation.dataTask.taskIdentifier == task.taskIdentifier) {
            returnOperation = operation;
            break;
        }
    }
    return returnOperation;
}

#pragma mark NSURLSessionDataDelegate

- (void)URLSession:(NSURLSession *)session
          dataTask:(NSURLSessionDataTask *)dataTask
didReceiveResponse:(NSURLResponse *)response
 completionHandler:(void (^)(NSURLSessionResponseDisposition disposition))completionHandler {

    // Identify the operation that runs this task and pass it the delegate method
    SDWebImageDownloaderOperation *dataOperation = [self operationWithTask:dataTask];

    [dataOperation URLSession:session dataTask:dataTask didReceiveResponse:response completionHandler:completionHandler];
}

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveData:(NSData *)data {

    // Identify the operation that runs this task and pass it the delegate method
    SDWebImageDownloaderOperation *dataOperation = [self operationWithTask:dataTask];

    [dataOperation URLSession:session dataTask:dataTask didReceiveData:data];
}

- (void)URLSession:(NSURLSession *)session
          dataTask:(NSURLSessionDataTask *)dataTask
 willCacheResponse:(NSCachedURLResponse *)proposedResponse
 completionHandler:(void (^)(NSCachedURLResponse *cachedResponse))completionHandler {

    // Identify the operation that runs this task and pass it the delegate method
    SDWebImageDownloaderOperation *dataOperation = [self operationWithTask:dataTask];

    [dataOperation URLSession:session dataTask:dataTask willCacheResponse:proposedResponse completionHandler:completionHandler];
}

#pragma mark NSURLSessionTaskDelegate

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error {
    // Identify the operation that runs this task and pass it the delegate method
    SDWebImageDownloaderOperation *dataOperation = [self operationWithTask:task];

    [dataOperation URLSession:session task:task didCompleteWithError:error];
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didReceiveChallenge:(NSURLAuthenticationChallenge *)challenge completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition disposition, NSURLCredential *credential))completionHandler {

    // Identify the operation that runs this task and pass it the delegate method
    SDWebImageDownloaderOperation *dataOperation = [self operationWithTask:task];

    [dataOperation URLSession:session task:task didReceiveChallenge:challenge completionHandler:completionHandler];
}

@end
