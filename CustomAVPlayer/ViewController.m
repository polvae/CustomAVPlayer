//
//  ViewController.m
//  CustomAVPlayer
//
//  Created by KingSoft on 2017/5/16.
//  Copyright © 2017年 KingSoft. All rights reserved.
//

#import "ViewController.h"
#import "CustomAVPlayer.h"
#import "Masonry.h"
#import "WMDragView.h"
#import "Reachability.h"

#define KScreenWidth ( [UIScreen mainScreen].bounds.size.width)
#define KScreenHeight ( [UIScreen mainScreen].bounds.size.height)

@interface ViewController ()<moviePlayerManagerDelegate>
@property (nonatomic , strong) CustomAVPlayer *player;
@property (nonatomic, strong) WMDragView *superView;

@property (nonatomic) Reachability *internetReachability;
@property (nonatomic, assign)NetworkStatus netStatus;

@end

@implementation ViewController



-(WMDragView *)superView{
    if (!_superView) {
        _superView = [[WMDragView alloc]initWithFrame:CGRectMake(10, 40, KScreenWidth - 20, KScreenWidth /16 * 9)];
        _superView.layer.cornerRadius = 14;
        _superView.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0];
        [self.view addSubview:_superView];
        
    }
    return _superView;
}

-(CustomAVPlayer *)player{
    if (!_player) {
        _player = [[[NSBundle mainBundle]loadNibNamed:@"CustomAVPlayer" owner:nil options:nil]firstObject];
        _player.delegate = self;
        _player.superView = self.superView;
        
    }
    return _player;
}


- (void)viewDidLoad {
    [super viewDidLoad];
    [self abserveNetwork];
    
}

#pragma mark ---网络监控--
- (void)abserveNetwork{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reachabilityChanged:) name:kReachabilityChangedNotification object:nil];
    
    self.internetReachability = [Reachability reachabilityForInternetConnection] ;
    [self.internetReachability startNotifier];
    [self updateInterfaceWithReachability:self.internetReachability];
    
}

- (void)updateInterfaceWithReachability:(Reachability *)reachability{
    self.netStatus = [reachability currentReachabilityStatus];
    
    switch (_netStatus)
    {
        case NotReachable:        {
            _player.netStatus = 0;
            break;
        }
        case ReachableViaWWAN: {
            _player.netStatus = 2;
            break;
        }
        case ReachableViaWiFi:  {
            _player.netStatus = 1;
            NSLog(@"wifi");
            break;
        }
    }
}

- (void)reachabilityChanged:(NSNotification *)note{
    Reachability* reachability = [note object];
    [self updateInterfaceWithReachability:reachability];
}



- (IBAction)oneClick1:(id)sender {
    [self.player resetToPlayNewVideoUrl:@"http://baobab.wdjcdn.com/1454467934808B(9).mp4" andIsAutoPlayVideo:YES];
}
- (IBAction)twoClick2:(id)sender {
    [self.player resetToPlayNewVideoUrl:@"http://baobab.wdjcdn.com/1458389678814huanjieyaliBastaw_x264.mp4" andIsAutoPlayVideo:NO];
}
- (IBAction)threeClick3:(id)sender {
    [self.player resetToPlayNewVideoUrl:@"http://baobab.wdjcdn.com/1457978787439_5544_854x480.mp4" andIsAutoPlayVideo:YES];
}

- (void)moviePlayerManagerDidClose{
    [self.superView removeFromSuperview];
    self.player = nil;
    self.superView = nil;
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end

