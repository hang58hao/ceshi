//
//  SingleDownLoad.m
//  downLoadProject
//
//  Created by 陈杭 on 2017/10/20.
//  Copyright © 2017年 陈杭. All rights reserved.
//

#import "SingleDownLoad.h"
#import "SSZipArchive.h"

@interface SingleDownLoad()<NSURLSessionDelegate, NSURLSessionDownloadDelegate,SSZipArchiveDelegate>

//下载任务
@property (strong, nonatomic) NSURLSessionDownloadTask *downloadTask;

//下载设置
@property (weak, nonatomic) NSURLSession *downloadSession;

//文件管理器
@property (strong, nonatomic) NSFileManager *fileManager;

//标记是否开始下载
@property (assign, nonatomic) BOOL isBeginDownload;

//存储接续下载数据的路径
@property (copy, nonatomic) NSString *resumeDirectoryStr;

//存储未下载完成的数据的路径
@property (copy, nonatomic) NSString *unDownloadStr;

//系统存储未下载完成的数据对应的文件的路径
@property (copy, nonatomic) NSString *libraryUnDownloadStr;

//继续下载数据
@property (strong, nonatomic) NSData *resumeData;

//记录当前继续下载的数据
@property (strong, nonatomic) NSMutableString *resumeString;

//记录上一次下载的数据大小
@property (assign, nonatomic) int64_t lastDownloadSize;

//记录是否是让出线程而暂停
@property (assign, nonatomic) BOOL isConcede;

//记录tmp文件的范围
@property (assign, nonatomic) NSRange libraryFilenameRange;


@end

@implementation SingleDownLoad

-(instancetype)init{
    if(self = [super init]){
        self.isBeginDownload = NO;
        self.isExistInRealm = YES;
        self.downloadProgress = 0.0;
        self.downLoadState = DownloadStateUnStart;
//        [self.downloaderDelegate downloaderState:self.downloaderState andDownloaderUrl:self.downloadUrl];
//        self.isGetResumeData = NO;
        self.lastDownloadSize = 0;
//        self.isHand = NO;
//        self.isSendState = YES;
        self.isConcede = NO;
    }
    return self;
}

#pragma mark ----------------  私有方法  -------------------------

-(void)start{
    //有网络
    [self createDirectory];
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:self.downloadUrl]];
    self.downloadTask = [self.downloadSession downloadTaskWithRequest:request];
    [self.downloadTask resume];
}

-(void)pause{
    if (self.downLoadState != DownloadStateRunning) {
        NSLog(@"此状态不允许暂停");
        return;
    }
    self.isConcede = YES;
   // self.isHand = YES;
    [_downloadTask cancelByProducingResumeData:^(NSData * _Nullable resumeData) {
        
    }];
}

-(void)resume{
    //首先判断下载进度，已经下载完成的不执行继续下载
    if (self.downloadProgress >= 100.0) {
        //下载已经完成
        NSLog(@"此下载已经完成，无法继续下载");
        return;
    }
    
    if (self.downloadProgress == 0) {
        NSLog(@"此任务还没有开启，无法下载");
        return;
    }
    
    if (self.isConcede == YES) {
       //self.isHand = isHand;
        self.downLoadState = DownloadStatePause;
       // [self.downloaderDelegate downloaderState:self.downloaderState andDownloaderUrl:self.downloadUrl];
        self.downloadTask = [self.downloadSession downloadTaskWithResumeData:[self getCorrectResumeData:self.resumeData]];
        [self.downloadTask resume];
        self.isConcede = NO;
        return;
    }
    
    if (self.downloadTask == nil || [self.downloadTask isEqual:[NSNull null]]) {
        NSLog(@"这个任务还没有创建");
        //数据库里有数据但是任务还没有被创建，可以判定为是继续下载的任务，此时应该重新创建任务，获取继续下载此任务的信息
        //创建继续下载的任务
       // self.isHand = isHand;
        [self createResumeDownloadTask];
        
        return;
    }
}

//  创建存储数据的路径
- (void)createDirectory{
    BOOL isE = [self.fileManager fileExistsAtPath:self.resumeDirectoryStr];
    if (isE) {
    
    } else {
       
        BOOL isC = [self.fileManager createDirectoryAtPath:self.resumeDirectoryStr withIntermediateDirectories:YES attributes:nil error:nil];
        if (isC) {
            NSLog(@"成功创建路径 self.resumeDirectoryStr :%@",self.resumeDirectoryStr);
        } else {
            NSLog(@"失败创建路径 self.resumeDirectoryStr");
        }
    }
    BOOL isU = [self.fileManager fileExistsAtPath:self.unDownloadStr];
    if (isU) {
        
    } else {

        BOOL isC = [self.fileManager createDirectoryAtPath:self.unDownloadStr withIntermediateDirectories:YES attributes:nil error:nil];
        if (isC) {
             NSLog(@"成功创建路径 self.unDownloadStr :%@",self.unDownloadStr);
        } else {
            NSLog(@"失败创建路径 self.unDownloadStr");
        }
    }
}

#pragma mark - 创建继续下载的任务
- (void)createResumeDownloadTask {
    
    self.resumeData = [NSData dataWithContentsOfFile:self.resumeDirectoryStr];
    [self updateLocalResumeData];
    
//    if (self.downloadTask) {
//        self.downloadTask = nil;
//    }
//    self.resumeData = nil;
    
//    [_downloadSession invalidateAndCancel];
//    NSURLSessionConfiguration *sessionCon = [NSURLSessionConfiguration backgroundSessionConfigurationWithIdentifier:self.downloadUrl];
//    _downloadSession = [NSURLSession sessionWithConfiguration:sessionCon delegate:self delegateQueue:[NSOperationQueue mainQueue]];
    
    //如果是没有中断直接退出app,会自行调用err代理方法，获取到resumedata
//    __weak __typeof(self)(weakSelf) = self;
//    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
//        //检查resumeData
//        if (weakSelf.resumeData == nil) {
//            //没有获取到系统提供的resumeData
//            [weakSelf resumeAtNoResumeData];
//        }
//    });
}

// 获取首次继续下载的数据
- (void)getOriginalResumeData {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.downloadTask cancelByProducingResumeData:^(NSData * _Nullable resumeData) {
            //到代理中获取resumeData，此处获取的resumeData在iOS10和Xcode8中有可能无法使用，shit！
        }];
    });
  
}

#pragma mark - 在没有系统提供的继续下载数据的情况下继续下载
- (void)resumeAtNoResumeData {
//    [_downloadSession invalidateAndCancel];
//    _downloadSession = nil;
    //去本地读取继续下载数据
    self.resumeData = [NSData dataWithContentsOfFile:self.resumeDirectoryStr];
    
    //将继续下载的数据移动到对应的目录下
    NSError *error = nil;
    if ([self.fileManager fileExistsAtPath:self.libraryUnDownloadStr]) {
        BOOL isS = [self.fileManager removeItemAtPath:self.libraryUnDownloadStr error:&error];
        if (!isS) {
            //移除失败
            NSLog(@"移除library下的继续下载数据对应的文件失败:%@", error);
        }
    }
    
    BOOL isS = [self.fileManager copyItemAtPath:self.unDownloadStr toPath:self.libraryUnDownloadStr error:&error];
    if (!isS) {
        //拷贝失败
        NSLog(@"拷贝继续下载文件到library下失败:%@", error);
    } else {
        //拷贝成功后开启继续下载
        if ([[[UIDevice currentDevice] systemVersion] floatValue] < 9.0) {
            //创建下载任务，继续下载
            self.downloadTask = [self.downloadSession downloadTaskWithResumeData:self.resumeData];
        } else {
            NSData *newData = [self getCorrectResumeData:self.resumeData];
            //创建下载任务，继续下载
            self.downloadTask = [self.downloadSession downloadTaskWithResumeData:newData];
        }
        
        [self.downloadTask resume];
    }
}

// 更新沙盒目录缓存的继续下载数据
- (void)updateLocalResumeData {
//    if (self.downloaderState == ZYLDownloaderStateDeleted) {
//        return;
//    }
    
    if (self.resumeString == nil) {
        return;
    }
    
    //在这创建resumeData
    //首先取出沙盒目录下的缓存文件
    NSData *libraryData = [NSData dataWithContentsOfFile:self.unDownloadStr];
    NSInteger libraryLength = libraryData.length;
    
    //计算当期表示resumeData数据大小的range
    //记录tmp文件大小范围
    NSRange integerRange = [self.resumeString rangeOfString:@"NSURLSessionResumeBytesReceived"];
    NSString *integerStr = [self.resumeString substringFromIndex:integerRange.location + integerRange.length];
    NSRange oneIntegerRange = [integerStr rangeOfString:@"<integer>"];
    NSRange twonIntegerRange = [integerStr rangeOfString:@"</integer>"];
    self.libraryFilenameRange = NSMakeRange(oneIntegerRange.location + oneIntegerRange.length + integerRange.location + integerRange.length, twonIntegerRange.location - oneIntegerRange.location - oneIntegerRange.length);
    //用新的数据替换
    [self.resumeString replaceCharactersInRange:self.libraryFilenameRange withString:[NSString stringWithFormat:@"%ld", (long)libraryLength]];
    
    NSData *newResumeData = [self.resumeString dataUsingEncoding:NSUTF8StringEncoding];
    self.resumeData = newResumeData;
    
    //同时保存在本地一份
    //获取存储路径
    NSString *path = [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,NSUserDomainMask,YES) objectAtIndex:0] stringByAppendingPathComponent:@"ArResumeDownloads"];
    //获取文件名
    NSString *resumeFileName = [path stringByAppendingPathComponent:[@"resume_" stringByAppendingString:[self encodeFilename:self.downloadUrl]]];
    //存储数据
    BOOL isS = [self.resumeData writeToFile:resumeFileName atomically:NO];
    if (isS) {
        //继续存储数据成功
        NSLog(@"继续存储数据成功");
    } else {
        //继续存储数据失败
        NSLog(@"继续存储数据失败");
    }
}

// 分析继续下载数据
- (void)parseResumeData:(NSData *)resumeData {
    NSString *XMLStr = [[NSString alloc] initWithData:resumeData encoding:NSUTF8StringEncoding];
    self.resumeString = [NSMutableString stringWithFormat:@"%@", XMLStr];
    
    //判断系统，iOS8以前和以后
    if ([[[UIDevice currentDevice] systemVersion] floatValue] < 9.0) {
        //iOS8包含iOS8以前
        NSRange tmpRange = [XMLStr rangeOfString:@"NSURLSessionResumeInfoLocalPath"];
        NSString *tmpStr = [XMLStr substringFromIndex:tmpRange.location + tmpRange.length];
        NSRange oneStringRange = [tmpStr rangeOfString:@"CFNetworkDownload_"];
        NSRange twoStringRange = [tmpStr rangeOfString:@".tmp"];
        self.tmpFilename = [tmpStr substringWithRange:NSMakeRange(oneStringRange.location, twoStringRange.location + twoStringRange.length - oneStringRange.location)];
        
    } else {
        //iOS8以后
        NSRange tmpRange = [XMLStr rangeOfString:@"NSURLSessionResumeInfoTempFileName"];
        NSString *tmpStr = [XMLStr substringFromIndex:tmpRange.location + tmpRange.length];
        NSRange oneStringRange = [tmpStr rangeOfString:@"<string>"];
        NSRange twoStringRange = [tmpStr rangeOfString:@"</string>"];
        //记录tmp文件名
        self.tmpFilename = [tmpStr substringWithRange:NSMakeRange(oneStringRange.location + oneStringRange.length, twoStringRange.location - oneStringRange.location - oneStringRange.length)];
    }
    
    //有数据，保存到本地
    //存储数据
    BOOL isS = [resumeData writeToFile:self.resumeDirectoryStr atomically:NO];
    if (isS) {
        //继续存储数据成功
        NSLog(@"继续存储数据成功");
    } else {
        //继续存储数据失败
        NSLog(@"继续存储数据失败");
    }
}

#pragma mark - 获取正确的resumeData
- (NSData *)getCorrectResumeData:(NSData *)resumeData {
    NSData *newData = nil;
    NSString *kResumeCurrentRequest = @"NSURLSessionResumeCurrentRequest";
    NSString *kResumeOriginalRequest = @"NSURLSessionResumeOriginalRequest";
    //获取继续数据的字典
    NSMutableDictionary* resumeDictionary = [NSPropertyListSerialization propertyListWithData:resumeData options:NSPropertyListMutableContainers format:NULL error:nil];
    //重新编码原始请求和当前请求
    resumeDictionary[kResumeCurrentRequest] = [self correctRequestData:resumeDictionary[kResumeCurrentRequest]];
    resumeDictionary[kResumeOriginalRequest] = [self correctRequestData:resumeDictionary[kResumeOriginalRequest]];
    newData = [NSPropertyListSerialization dataWithPropertyList:resumeDictionary format:NSPropertyListBinaryFormat_v1_0 options:NSPropertyListMutableContainers error:nil];
    
    return newData;
}

#pragma mark - 编码继续请求字典中的当前请求数据和原始请求数据
- (NSData *)correctRequestData:(NSData *)data {
    NSData *resultData = nil;
    NSData *arData = [NSKeyedUnarchiver unarchiveObjectWithData:data];
    if (arData != nil) {
        return data;
    }
    
    NSMutableDictionary *archiveDict = [NSPropertyListSerialization propertyListWithData:data options:NSPropertyListMutableContainersAndLeaves format:nil error:nil];
    
    int k = 0;
    NSMutableDictionary *oneDict = [NSMutableDictionary dictionaryWithDictionary:archiveDict[@"$objects"][1]];
    while (oneDict[[NSString stringWithFormat:@"$%d", k]] != nil) {
        k += 1;
    }
    
    int i = 0;
    while (oneDict[[NSString stringWithFormat:@"__nsurlrequest_proto_prop_obj_%d", i]] != nil) {
        NSString *obj = oneDict[[NSString stringWithFormat:@"__nsurlrequest_proto_prop_obj_%d", i]];
        if (obj != nil) {
            [oneDict setObject:obj forKey:[NSString stringWithFormat:@"$%d", i + k]];
            [oneDict removeObjectForKey:obj];
            archiveDict[@"$objects"][1] = oneDict;
        }
        i += 1;
    }
    
    if (oneDict[@"__nsurlrequest_proto_props"] != nil) {
        NSString *obj = oneDict[@"__nsurlrequest_proto_props"];
        [oneDict setObject:obj forKey:[NSString stringWithFormat:@"$%d", i + k]];
        [oneDict removeObjectForKey:@"__nsurlrequest_proto_props"];
        archiveDict[@"$objects"][1] = oneDict;
    }
    
    NSMutableDictionary *twoDict = [NSMutableDictionary dictionaryWithDictionary:archiveDict[@"$top"]];
    if (twoDict[@"NSKeyedArchiveRootObjectKey"] != nil) {
        [twoDict setObject:twoDict[@"NSKeyedArchiveRootObjectKey"] forKey:[NSString stringWithFormat:@"%@", NSKeyedArchiveRootObjectKey]];
        [twoDict removeObjectForKey:@"NSKeyedArchiveRootObjectKey"];
        archiveDict[@"$top"] = twoDict;
    }
    
    resultData = [NSPropertyListSerialization dataWithPropertyList:archiveDict format:NSPropertyListBinaryFormat_v1_0 options:NSPropertyListMutableContainers error:nil];
    
    return resultData;
}


- (NSString *)encodeFilename:(NSString *)filename {
    NSData *data = [filename dataUsingEncoding:NSUTF8StringEncoding];
    NSString *encodeFilename = [data base64EncodedStringWithOptions:NSDataBase64Encoding64CharacterLineLength];
    
    return encodeFilename;
}

#pragma mark ----------------  代理方法  -------------------------

//正在下载
- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didWriteData:(int64_t)bytesWritten totalBytesWritten:(int64_t)totalBytesWritten totalBytesExpectedToWrite:(int64_t)totalBytesExpectedToWrite {
    
     self.downloadProgress = (float)totalBytesWritten / (float)totalBytesExpectedToWrite * 100;
    [self.delegate downloadRate:self.downloadProgress withDownloadUrl:self.downloadUrl];
    
    //返回状态，修改下载框文字
    if(self.downLoadState  != DownloadStateRunning){
        [self.delegate downloadStateOfUrl:self.downloadUrl withState:DownloadStateRunning];
        self.downLoadState = DownloadStateRunning;
    }
    
    //获取resumeData
    if (self.isBeginDownload == NO) {
        //还没有开始下载
        self.isBeginDownload = YES;
        [self.delegate downloadBeginWithDownload:self];
        
        self.resumeData = [NSData dataWithContentsOfFile:self.resumeDirectoryStr];
        //判断本地是否有继续下载的数据，只有在本地没有resumeData数据的时候才硬性获取继续下载的数据备用
        if (self.resumeData) {
            
            [self parseResumeData:self.resumeData];
        } else {
            //不存在
            //在这里取得继续下载的数据
            [self getOriginalResumeData];
        }
        
        //[self openSpeedTimer];
        
    } else {
        //已经开始下载了
        
    }
    
    //每下载1M的文件则迁移一次未下载完成的数据到Document
  
    CGFloat addSize = (totalBytesWritten - self.lastDownloadSize) / 1024.0;
    if (addSize >= 10) {
        //下载的量大于100kb,迁移
        NSError *error = nil;
        if ([self.fileManager fileExistsAtPath:self.unDownloadStr]) {
            //存在则删除
            [self.fileManager removeItemAtPath:self.unDownloadStr error:nil];
        }
//        NSLog(@"\nunDownloadStr        ======     %@\nlibraryUnDownloadStr ======     %@\ntmpFilename          ======     %@",self.unDownloadStr,self.libraryUnDownloadStr,self.tmpFilename);
        BOOL isS = [self.fileManager copyItemAtPath:self.libraryUnDownloadStr toPath:self.unDownloadStr error:&error];
        if (isS) {
            //移动成功，刷新数据库信息
            [self.delegate downloadRefreshInDataBase:self];
        } else {
            NSLog(@"移动失败%@", error);
        }
        
        self.lastDownloadSize = totalBytesWritten;
    }
}

//继续下载时的数据
- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didResumeAtOffset:(int64_t)fileOffset expectedTotalBytes:(int64_t)expectedTotalBytes {
    NSLog(@"继续下载已经下载的数据：%lld,数据总量：%lld", fileOffset, expectedTotalBytes);
}

//下载出错或者中断或者下载完成
-(void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error{
    
    if(error){
        
        if (self.isConcede == YES) {
           
            if ([error.userInfo objectForKey:NSURLSessionDownloadTaskResumeData]){
                self.resumeData = [error.userInfo objectForKey:NSURLSessionDownloadTaskResumeData];
                self.downLoadState = DownloadStatePause;
                [self.delegate downloadRefreshInDataBase:self];
                [self.delegate downloadStateOfUrl:self.downloadUrl withState:DownloadStatePause];
                [self parseResumeData:self.resumeData];
            }
            return;
        }

//        if (self.downloadTask == nil || [self.downloadTask isEqual:[NSNull null]]) {
//
//            //退出关闭app
//            if ([error.userInfo objectForKey:NSURLSessionDownloadTaskResumeData]) {
//                //有继续下载的数据
//                self.resumeData = [error.userInfo objectForKey:NSURLSessionDownloadTaskResumeData];
//                //判断系统版本
//                if ([[[UIDevice currentDevice] systemVersion] floatValue] < 9.0) {
//                    //创建下载任务，继续下载
//                    self.downloadTask = [self.downloadSession downloadTaskWithResumeData:self.resumeData];
//                } else {
//                    //获取正确的resumeData
//                    NSData *newData = [self getCorrectResumeData:self.resumeData];
//                    //创建下载任务，继续下载
//                    self.downloadTask = [self.downloadSession downloadTaskWithResumeData:newData];
//                }
//
//                [self.downloadTask resume];
//
//                //分析继续下载数据
//                [self parseResumeData:self.resumeData];
//            }
//
//            //网络故障导致的下载失败
//            else {
//
//                //没有继续下载的数据
////                if (self. != ZYLDownloaderStateDeleted) {
////                    self.downloaderState = ZYLDownloaderStateFail;
////                    self.isHand = YES;
////                    [self.downloaderDelegate downloaderState:self.downloaderState andDownloaderUrl:self.downloadUrl];
////                }
//                NSLog(@"没有继续下载的数据");
//                //更新本地继续下载数据
//                [self updateLocalResumeData];
//            }
//        }
//
        
        else {
            //由于主动取消下载导致的下载失败，在这里获取resumeData并保存在沙盒目录中
            
            if ([error.userInfo objectForKey:NSURLSessionDownloadTaskResumeData]) {
                //有继续下载的数据
                self.resumeData = [error.userInfo objectForKey:NSURLSessionDownloadTaskResumeData];
                
                if ([[[UIDevice currentDevice] systemVersion] floatValue] < 9.0) {
                    //创建下载任务，继续下载
                    self.downloadTask = [self.downloadSession downloadTaskWithResumeData:self.resumeData];
                } else {
                    //获取正确的resumeData
                    NSData *newData = [self getCorrectResumeData:self.resumeData];
                    //创建下载任务，继续下载
                    self.downloadTask = [self.downloadSession downloadTaskWithResumeData:newData];
                }
                
                [self.downloadTask resume];
                
                //分析继续下载的数据
                [self parseResumeData:self.resumeData];
                
            }
        }
//            } else {
//                //没有继续下载的数据
//                NSLog(@"没有继续下载的数据");
//                //更新本地继续下载数据
//                [self updateLocalResumeData];
//            }
    }
}

//下载完成
- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didFinishDownloadingToURL:(NSURL *)location {
    
    NSLog(@"文件下载完成");
    NSString *path = [NSString stringWithFormat:@"%@.%@", [[[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,NSUserDomainMask,YES) objectAtIndex:0] stringByAppendingPathComponent:@"ArDownloads"]stringByAppendingPathComponent:[self encodeFilename:self.downloadUrl]],self.fileType];
    NSLog(@"文件路径是:%@", path);
    
    NSString * cachesPath=NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES).firstObject;
    
    NSURL *documentsDirectoryURL = [NSURL fileURLWithPath:path isDirectory:NO];
    
    BOOL isS = [self.fileManager moveItemAtURL:location toURL:documentsDirectoryURL error:nil];
    if (isS) {
        //移动成功
        [SSZipArchive unzipFileAtPath:path toDestination:cachesPath delegate:self];
        NSLog(@"下载完成的文件已经成功移动到documents路径下");
    } else {
        //移动失败
        NSLog(@"下载完成的文件移动到documents路径下失败");
    }
}

- (void)zipArchiveDidUnzipArchiveAtPath:(NSString *)path zipInfo:(unz_global_info)zipInfo unzippedPath:(NSString *)unzippedPath{
    NSLog(@"解压前路径 : %@   \n解压后路径: %@/%@",path,unzippedPath,self.fileName);
    NSString * unArchivePath = [NSString stringWithFormat:@"%@/%@",path,self.fileName];
    //告知下载控制器已经系在完成
    if(![self.unArchiveDirectory isEqualToString:unArchivePath]){
        self.unArchiveDirectory = unArchivePath;
    }
    self.downLoadState = DownloadStateFinish;
    self.downloadProgress = 100.000000;
    [self.delegate downloadRate:self.downloadProgress withDownloadUrl:self.downloadUrl];
    [self.delegate downloadStateOfUrl:self.downloadUrl withState:DownloadStateFinish];
}

#pragma mark ----------------  懒加载  -------------------------

- (NSString *)unDownloadStr {
    if (!_unDownloadStr) {
       NSString * mainStr =   [[[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,NSUserDomainMask,YES) objectAtIndex:0] stringByAppendingPathComponent:@"ArDownload"] stringByAppendingPathComponent:@"UnDownloads"];
        _unDownloadStr = [mainStr stringByAppendingPathComponent:self.tmpFilename];
    }
    return _unDownloadStr;
}

- (NSString *)libraryUnDownloadStr {
    if (!_libraryUnDownloadStr) {
        _libraryUnDownloadStr = [[[[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) firstObject] stringByAppendingPathComponent:@"com.apple.nsurlsessiond/Downloads"] stringByAppendingPathComponent:[[NSBundle mainBundle] bundleIdentifier]] stringByAppendingPathComponent:self.tmpFilename];
    }
    return _libraryUnDownloadStr;
}

- (NSURLSession *)downloadSession {
    if (!_downloadSession) {
        NSURLSessionConfiguration *sessionCon = [NSURLSessionConfiguration backgroundSessionConfigurationWithIdentifier:self.downloadUrl];
        
        self.downloadSession = [NSURLSession sessionWithConfiguration:sessionCon delegate:self delegateQueue:[NSOperationQueue mainQueue]];
    }
    return _downloadSession;
}

- (NSString *)resumeDirectoryStr {
    if (!_resumeDirectoryStr) {
         NSString * mainStr =   [[[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,NSUserDomainMask,YES) objectAtIndex:0] stringByAppendingPathComponent:@"ArDownload"] stringByAppendingPathComponent:@"ArResumeDownloads"];
        _resumeDirectoryStr = [mainStr stringByAppendingPathComponent:[@"resume_" stringByAppendingString:[self encodeFilename:self.downloadUrl]]];
    }
    return _resumeDirectoryStr;
}

- (NSFileManager *)fileManager {
    if (_fileManager == nil) {
        _fileManager = [NSFileManager defaultManager];
    }
    return _fileManager;
}

-(NSString *)unArchiveDirectory{
    if (!_unArchiveDirectory) {
        NSString * cachesPath=NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES).firstObject;
        _unArchiveDirectory = [NSString stringWithFormat:@"%@/%@",cachesPath,self.fileName];
    }
    return _unArchiveDirectory;
}

@end
