//
//  ViewController.m
//  downLoadProject
//
//  Created by 陈杭 on 2017/10/20.
//  Copyright © 2017年 陈杭. All rights reserved.
//

#import "ViewController.h"
#import "DownLoadManager.h"

@interface ViewController ()<DownLoadManagerDelegate>{
    NSString     * _downloadURLString ;
    CGFloat        _downLoadProgress;
}

@property (nonatomic , strong) UILabel    *  progressLabel;

@property (nonatomic , strong) UIButton   *  downLoadBtn;

@property (nonatomic , assign) DownloadState   downLoadState;

@property (nonatomic , strong) DownLoadManager   *  downLoadManager;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    _downLoadProgress = 0;
    _downloadURLString = @"http://39.106.38.135/thinkphp/public/api/company_video/20170929.zip";
    _downLoadManager = [DownLoadManager sharedInstance];
    _downLoadManager.downloadDelegate = self;
    [self.view addSubview:self.progressLabel];
    [self.view addSubview:self.downLoadBtn];
    
   //修改按钮文字
    [_downLoadManager downLoadStateOfUrl:_downloadURLString withStateBlcok:^(DownloadState state, CGFloat progress) {
        _downLoadProgress = progress;
        [self changeBtnTitle:state andProgress:progress];
    }];
    // Do any additional setup after loading the view, typically from a nib.
}

-(void)ceshiceshi{
    NSLog(@"这是一个测试");
    NSLog(@"这是合伙人的测试");
}

-(void)hahah{
    NSLog(@"这是主干的更新");
}

-(void)downloadRate:(float)rate withDownloadUrl:(NSString *)downloadUrl{
    _downLoadProgress = rate;
    _progressLabel.text = [NSString stringWithFormat:@"%.1f%%",rate];
}

-(void)downloadStateOfUrl:(NSString *)downloadUrl withState:(DownloadState)state{
    [self changeBtnTitle:state andProgress:_downLoadProgress];
}

-(void)changeBtnTitle:(DownloadState)state  andProgress:(CGFloat)progress{
    _downLoadState = state;
    switch (state) {
        case DownloadStateStart:{
            [_downLoadBtn setTitle:@"下载" forState:UIControlStateNormal];
        }
            break;
        case DownloadStatePause:{
            [_downLoadBtn setTitle:@"继续" forState:UIControlStateNormal];
            _progressLabel.text = [NSString stringWithFormat:@"%.1f%%",progress];
        }
            break;
        case DownloadStateRunning:{
            [_downLoadBtn setTitle:@"暂停" forState:UIControlStateNormal];
             _progressLabel.text = [NSString stringWithFormat:@"%.1f%%",progress];
        }
            break;
        case DownloadStateFinish:{
             [_downLoadBtn setTitle:@"完成" forState:UIControlStateNormal];
        }
            break;
        default:
            break;
    }
    _downLoadBtn.enabled = YES;
}

-(void)downLoad{
    
    if(_downLoadState == DownloadStateFinish){
        NSLog(@"该任务已下载完成");
        return;
    }
    if(_downLoadState == DownloadStateStart){
        [_downLoadManager startDownloadWithDownloadUrl:_downloadURLString];
        return;
    }
    if(_downLoadState == DownloadStateRunning){
        [_downLoadManager pauseDownloadWithDownloadUrl:_downloadURLString];
        return;
    }
    if(_downLoadState == DownloadStatePause){
        [_downLoadManager resumeDownloadWithDownloadUrl:_downloadURLString];
        return;
    }
}


-(UILabel *)progressLabel{
    if(!_progressLabel){
        _progressLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 150, 60)];
        _progressLabel.center = CGPointMake(self.view.frame.size.width /2 , self.view.frame.size.height /2- 80);
        _progressLabel.textColor = [UIColor whiteColor];
        _progressLabel.clipsToBounds  = YES;
        _progressLabel.backgroundColor = [UIColor blackColor];
        _progressLabel.layer.cornerRadius = 5.0;
        _progressLabel.font = [UIFont systemFontOfSize:14];
        _progressLabel.textAlignment = NSTextAlignmentCenter;
    }
    return _progressLabel;
}


-(UIButton *)downLoadBtn{
    if(!_downLoadBtn){
        _downLoadBtn = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 80, 40)];
        _downLoadBtn.center = CGPointMake(self.view.frame.size.width /2 , self.view.frame.size.height /2);        _downLoadBtn.layer.cornerRadius = 5.0;
        _downLoadBtn.backgroundColor = [UIColor grayColor];
        [_downLoadBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        _downLoadBtn.titleLabel.font = [UIFont systemFontOfSize:15];
        [_downLoadBtn addTarget:self action:@selector(downLoad) forControlEvents:UIControlEventTouchUpInside];
        _downLoadBtn.enabled = NO;
    }
    return _downLoadBtn;
}



- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
