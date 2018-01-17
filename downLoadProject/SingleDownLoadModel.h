//
//  SingleDownLoadModel.h
//  downLoadProject
//
//  Created by 陈杭 on 2017/10/20.
//  Copyright © 2017年 陈杭. All rights reserved.
//

#import <Realm/Realm.h>

@interface SingleDownLoadModel : RLMObject

@property NSString *downloadUrl;

@property float downloadProgress;

@property NSString *fileType;

@property NSString *fileName;

@end

RLM_ARRAY_TYPE(SingleDownLoadModel)
