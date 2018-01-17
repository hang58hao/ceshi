//
//  SingleDownLoad.h
//  downLoadProject
//
//  Created by 陈杭 on 2017/10/20.
//  Copyright © 2017年 陈杭. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

typedef NS_ENUM(NSUInteger, DownloadState) {
    DownloadStateUnStart = 0,
    DownloadStateStart,
    DownloadStateRunning,
    DownloadStatePause,
    DownloadStateFinish,
};


@class SingleDownLoad;
@protocol SingleDownLoadDelegate <NSObject>

@optional


/**
 * 文件开始下载
 */
- (void)downloadBeginWithDownload:(SingleDownLoad *)download;

/**
 * 文件的下载进度
 */
- (void)downloadRate:(float)rate withDownloadUrl:(NSString *)downloadUrl;

/**
 * 文件下载状态
 */
- (void)downloadStateOfUrl:(NSString *)downloadUrl  withState:(DownloadState)state;

/**
 * 文件数据库更新进度
 */
- (void)downloadRefreshInDataBase:(SingleDownLoad *)download;

@end

@interface SingleDownLoad : NSObject

/**
 * 下载链接
 */
@property (copy, nonatomic) NSString *downloadUrl;


/**
 * 文件格式
 */
@property (copy, nonatomic) NSString *fileName;

/**
 * 文件格式
 */
@property (copy, nonatomic) NSString *fileType;

/**
 * 下载进度
 */
@property (assign, nonatomic) float downloadProgress;

/**
 * 记录下载器是否已经存储到数据库
 */
@property (assign, nonatomic) BOOL isExistInRealm;

/**
 * 记录下载器状态
 */
@property (assign, nonatomic) DownloadState   downLoadState;

/**
 * 记录存储在tmp路径的文件名
 */
@property (copy, nonatomic) NSString * tmpFilename;

/**
 * 解压移动后路径
 */
@property (copy, nonatomic) NSString * unArchiveDirectory;


@property (nonatomic , weak)id <SingleDownLoadDelegate> delegate;

-(void)start;

-(void)pause;

-(void)resume;

@end












