//
//  DownLoadManager.m
//  downLoadProject
//
//  Created by 陈杭 on 2017/10/20.
//  Copyright © 2017年 陈杭. All rights reserved.
//

#import "DownLoadManager.h"


@interface DownLoadManager()<SingleDownLoadDelegate>

//存储下载数据的路径
@property (copy, nonatomic) NSString *directoryStr;

//存储接续下载数据的路径
@property (copy, nonatomic) NSString *resumeDirectoryStr;

//存储未下载完成的数据的路径
@property (copy, nonatomic) NSString *unDownloadStr;

//系统存储未下载完成的数据对应的文件的路径
@property (copy, nonatomic) NSString *libraryUnDownloadStr;

//文件管理器
@property (strong, nonatomic) NSFileManager *fileManager;

//用于存储下载器所有的子下载器
@property (strong, nonatomic) NSMutableArray *singleDownloadArray;

//用于存储原始的从数据库中读取的下载信息
@property (strong, nonatomic) RLMResults <SingleDownLoadModel *> *allModels;

@end


@implementation DownLoadManager

+ (instancetype)sharedInstance{
    static dispatch_once_t once;
    static id __singleton__;
    dispatch_once( &once, ^{
        __singleton__ = [[self alloc] init];
        
    } );
    return __singleton__;
}

-(instancetype)init{
    self = [super init];
    if (self) {
        //创建存储路径
        [self createDirectory];
    }
    return self;
}




#pragma mark -------------   代理方法  -------------------
/**
 * 文件的下载进度
 */
- (void)downloadRate:(float)rate withDownloadUrl:(NSString *)downloadUrl{
    [self.downloadDelegate downloadRate:rate withDownloadUrl:downloadUrl];
}

/**
 * 文件下载状态
 */
- (void)downloadStateOfUrl:(NSString *)downloadUrl  withState:(DownloadState)state{
     [self.downloadDelegate downloadStateOfUrl:downloadUrl withState:state];
}

/**
 * 文件开始下载
 */
- (void)downloadBeginWithDownload:(SingleDownLoad *)download{
    //开始下载后存储或者更新下载数据
    if (download.isExistInRealm == NO) {
        //这个下载器并没有存储在这个数据库中,将其存储到数据库
        [self saveDownloaderInfoWithSingleDownloader:download];
        download.isExistInRealm = YES;
    }
    
    if ([self.downloadDelegate respondsToSelector:@selector(downloadStateOfUrl:withState:)]) {
        [self.downloadDelegate downloadStateOfUrl:download.downloadUrl withState:DownloadStateRunning];
    }
}

/**
 * 文件数据库更新进度
 */
- (void)downloadRefreshInDataBase:(SingleDownLoad *)download{
    [self saveDownloaderInfoWithSingleDownloader:download];
}



#pragma mark -------------   私有方法  -------------------

//  创建存储数据的路径
- (void)createDirectory {
    //创建存储已经下载成功的数据路径
    //首先检查文件路径是否存在
    BOOL isE = [self.fileManager fileExistsAtPath:self.directoryStr];
    if (isE) {
        //存在这个路径，不创建
        NSLog(@"要创建的下载文件路径存在");
    } else {
        //不存在这个路径，创建
        NSLog(@"下载路径不存在");
        BOOL isC = [self.fileManager createDirectoryAtPath:self.directoryStr withIntermediateDirectories:YES attributes:nil error:nil];
        if (isC) {
            //路径创建成功
            NSLog(@"下载路径创建成功");
        } else {
            //路径创建失败
            NSLog(@"下载路径创建失败");
        }
    }
    
    //创建存储resumeData的路径
    BOOL isRE = [self.fileManager fileExistsAtPath:self.resumeDirectoryStr];
    if (isRE) {
        //存在这个路径，不创建
        NSLog(@"要创建的继续下载文件路径存在");
    } else {
        //不存在这个路径，创建
        NSLog(@"继续下载路径不存在");
        BOOL isC = [self.fileManager createDirectoryAtPath:self.resumeDirectoryStr withIntermediateDirectories:YES attributes:nil error:nil];
        if (isC) {
            //路径创建成功
            NSLog(@"继续下载路径创建成功");
        } else {
            //路径创建失败
            NSLog(@"继续下载路径创建失败");
        }
    }
    //创建存储为下载完成的数据的路径
    BOOL isU = [self.fileManager fileExistsAtPath:self.unDownloadStr];
    if (isU) {
        //存在这个路径，不创建
        NSLog(@"要创建的未完成下载文件路径存在");
        NSLog(@"项目路径：%@", self.directoryStr);
    } else {
        //不存在这个路径，创建
        NSLog(@"继续下载路径不存在");
        BOOL isC = [self.fileManager createDirectoryAtPath:self.unDownloadStr withIntermediateDirectories:YES attributes:nil error:nil];
        if (isC) {
            //路径创建成功
            NSLog(@"未完成下载路径创建成功");
            NSLog(@"项目路径：%@", self.directoryStr);
        } else {
            //路径创建失败
            NSLog(@"未完成下载路径创建失败");
        }
    }
}


-(void)startDownloadWithDownloadUrl:(NSString *)downloadUrl{
    if(!downloadUrl && downloadUrl.length == 0){
        return;
    }
    __block BOOL isExist = NO;
     __weak __typeof(self)(weakSelf) = self;
    [self.singleDownloaderArray enumerateObjectsUsingBlock:^(SingleDownLoad *  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([obj.downloadUrl isEqualToString:downloadUrl]) {
            isExist = YES;
            [weakSelf resumeDownloadWithDownloadUrl:downloadUrl];
            return;
        }
    }];
    if(!isExist){
        //不存在这个下载器
        NSArray  * nameArr = [downloadUrl componentsSeparatedByString:@"/"];
        NSString * fileType  = [nameArr lastObject];
        NSArray  * nameArr1 = [fileType componentsSeparatedByString:@"."];
        if(nameArr.count > 0){
            SingleDownLoad *singleDownload = [[SingleDownLoad alloc] init];
            singleDownload.isExistInRealm = NO;
            singleDownload.fileType = [nameArr1 lastObject];
            singleDownload.fileName = [nameArr1 firstObject];
            singleDownload.downloadUrl = downloadUrl;
            singleDownload.delegate = self;
            [self.singleDownloaderArray addObject:singleDownload];
            [singleDownload start];
        }
    }
}


-(void)pauseDownloadWithDownloadUrl:(NSString *)downloadUrl{
    [self.singleDownloaderArray enumerateObjectsUsingBlock:^(SingleDownLoad  *_Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([obj.downloadUrl isEqualToString:downloadUrl]) {
            NSLog(@"找到需要暂停下载的任务");
            [obj pause];
             *stop = YES;
        }
    }];
}


-(void)resumeDownloadWithDownloadUrl:(NSString *)downloadUrl{
    __weak __typeof(self)(weakSelf) = self;
    [self.singleDownloaderArray enumerateObjectsUsingBlock:^(SingleDownLoad  *_Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([obj.downloadUrl isEqualToString:downloadUrl]) {
            NSLog(@"找到需要继续下载的任务");
            if (obj.delegate == nil) {
                obj.delegate = weakSelf;
            }
            [obj resume];
            *stop = YES;
        }
    }];
}


//获取下载状态和进度
-(void)downLoadStateOfUrl:(NSString *)downloadUrl
                      withStateBlcok:(DownLoadStateBlcok)returnBlock{
    __block DownloadState  state = DownloadStateStart;
    __block CGFloat progress = 0;
    [self.singleDownloaderArray enumerateObjectsUsingBlock:^(SingleDownLoad *  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([obj.downloadUrl isEqualToString:downloadUrl]) {
            if(obj.downloadProgress > 0){
                state = DownloadStatePause;
                progress = obj.downloadProgress;
                 *stop = YES;
            }
        }
    }];
    returnBlock(state,progress);
}

// 将数据存储到数据库
- (void)saveDownloaderInfoWithSingleDownloader:(SingleDownLoad *)singleDownloader {
    //创建存储对象
    SingleDownLoadModel *model = [[SingleDownLoadModel alloc] init];
    model.downloadUrl = singleDownloader.downloadUrl;
    model.fileType = singleDownloader.fileType;
    model.fileName = singleDownloader.fileName;
    model.downloadProgress = singleDownloader.downloadProgress;
    //存储到数据库
    RLMRealm *realm = [RLMRealm defaultRealm];
    [realm beginWriteTransaction];
    [realm addOrUpdateObject:model];
    [realm commitWriteTransaction];
}

// 读取数据库中的内容
- (NSArray *)readDownloadFromRealm {
    self.allModels = [SingleDownLoadModel allObjects];
    _singleDownloadArray = [[NSMutableArray alloc] init];
    if (self.allModels.count > 0) {
        //数据库有数据
        for (SingleDownLoadModel *model in self.allModels) {
            SingleDownLoad *singDownloader = [[SingleDownLoad alloc] init];
            singDownloader.downloadUrl = model.downloadUrl;
            singDownloader.fileType = model.fileType;
            singDownloader.fileName = model.fileName;
            singDownloader.downloadProgress = model.downloadProgress;
            [_singleDownloadArray addObject:singDownloader];
        }
    } else {
        //数据库无数据
        NSLog(@"数据库没有数据");
    }
    
    return _singleDownloadArray;
}

// 更新数据库中的某条数据
- (void)updateDownloaderInfoWithDownloderUrl:(SingleDownLoad *)download{
    //判断数据源中是否有此数据
    __block BOOL isExist = NO;
    __block SingleDownLoad *downloaderModel = nil;
    [self.singleDownloaderArray enumerateObjectsUsingBlock:^(SingleDownLoad *  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([obj.downloadUrl isEqualToString:download.downloadUrl]) {
            isExist = YES;
            downloaderModel = download;
             *stop = YES;
        }
    }];
    
    if (isExist) {
        //存在
        //判断在数据库中是否存在
        if (downloaderModel.isExistInRealm) {
            //存在
            //更新数据库
            [self saveDownloaderInfoWithSingleDownloader:downloaderModel];
            
            
        } else {
            //不存在
        }
        
    } else {
        //不存在
        NSLog(@"不存在这个下载器，无法更新数据");
    }
}


- (NSString *)directoryStr {
    if (_directoryStr == nil) {
        _directoryStr = [[[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,NSUserDomainMask,YES) objectAtIndex:0] stringByAppendingPathComponent:@"ArDownload"] stringByAppendingPathComponent:@"DownloadsZip"];
    }
    return _directoryStr;
}

- (NSString *)resumeDirectoryStr {
    if (_resumeDirectoryStr == nil) {
        _resumeDirectoryStr = [[[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,NSUserDomainMask,YES) objectAtIndex:0] stringByAppendingPathComponent:@"ArDownload"] stringByAppendingPathComponent:@"ResumeDownloads"];
    }
    return _resumeDirectoryStr;
}

- (NSString *)unDownloadStr {
    if (_unDownloadStr == nil) {
        _unDownloadStr = [[[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,NSUserDomainMask,YES) objectAtIndex:0] stringByAppendingPathComponent:@"ArDownload"] stringByAppendingPathComponent:@"UnDownloads"];
    }
    return _unDownloadStr;
}

- (NSString *)libraryUnDownloadStr {
    if (_libraryUnDownloadStr == nil) {
        _libraryUnDownloadStr = [[[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) firstObject] stringByAppendingPathComponent:@"com.apple.nsurlsessiond/Downloads"] stringByAppendingPathComponent:[[NSBundle mainBundle] bundleIdentifier]];
    }
    return _libraryUnDownloadStr;
}

- (NSFileManager *)fileManager {
    if (_fileManager == nil) {
        _fileManager = [NSFileManager defaultManager];
    }
    return _fileManager;
}

-(NSMutableArray *)singleDownloaderArray{
    if(!_singleDownloadArray){
        
        _singleDownloadArray = [NSMutableArray arrayWithArray:[self readDownloadFromRealm]];
        
    }
    return _singleDownloadArray;
}



@end
