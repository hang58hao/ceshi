//
//  SingleDownLoadModel.m
//  downLoadProject
//
//  Created by 陈杭 on 2017/10/20.
//  Copyright © 2017年 陈杭. All rights reserved.
//

#import "SingleDownLoadModel.h"

@implementation SingleDownLoadModel

//将downloadUrl设置为主key
+ (NSString *)primaryKey {
    return @"downloadUrl";
}

@end
