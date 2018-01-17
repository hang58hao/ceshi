//
//  DownLoadManager.h
//  downLoadProject
//
//  Created by 陈杭 on 2017/10/20.
//  Copyright © 2017年 陈杭. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SingleDownLoadModel.h"
#import "SingleDownLoad.h"

typedef void(^DownLoadStateBlcok)(DownloadState  state , CGFloat progress);

@protocol DownLoadManagerDelegate <NSObject>

@optional


/**
 * 文件下载状态
 */
- (void)downloadStateOfUrl:(NSString *)downloadUrl  withState:(DownloadState)state;

/**
 * 文件的下载进度
 */
- (void)downloadRate:(float)rate withDownloadUrl:(NSString *)downloadUrl;


@end;

@interface DownLoadManager : NSObject

@property (weak, nonatomic) id <DownLoadManagerDelegate> downloadDelegate;


+ (instancetype)sharedInstance;

/**
 * 拿到下载链接开始下载，要求传入文件名称和文件类型(mp4/3gp/mp3/doc/zip...)，isHand表示是否优先下载
 */
- (void)startDownloadWithDownloadUrl:(NSString *)downloadUrl;

/**
 * 暂停下载某一个
 */
- (void)pauseDownloadWithDownloadUrl:(NSString *)downloadUrl;

/**
 * 继续下载某一个
 */
- (void)resumeDownloadWithDownloadUrl:(NSString *)downloadUrl;

/**
 * 判断下载的状态
 */
-(void)downLoadStateOfUrl:(NSString *)downloadUrl
                      withStateBlcok:(DownLoadStateBlcok)returnBlock;

@end
