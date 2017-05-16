//
//  CustomAVPlayer.m
//  自定义播放器
//
//  Created by KingoSoft on 17/3/3.
//  Copyright © 2017年 KingSoft. All rights reserved.
//

#import "CustomAVPlayer.h"
#import <AVFoundation/AVFoundation.h>
#import <MediaPlayer/MediaPlayer.h>
#import "Masonry.h"
#import "CustomSlider.h"
#import "MMMaterialDesignSpinner.h"

#define KScreenWidth ( [UIScreen mainScreen].bounds.size.width)
#define KScreenHeight ( [UIScreen mainScreen].bounds.size.height)

@interface CustomAVPlayer ()<UIGestureRecognizerDelegate>

@property (weak, nonatomic) IBOutlet UIView *topBgView;
@property (weak, nonatomic) IBOutlet UIView *bottomBgView;
@property (weak, nonatomic) IBOutlet UIButton *playBtn;
@property (weak, nonatomic) IBOutlet UIButton *closeBtn;
@property (weak, nonatomic) IBOutlet UIButton *attentionBtn;
@property (weak, nonatomic) IBOutlet UILabel *starTimerLB;
@property (weak, nonatomic) IBOutlet UILabel *totalTimerLB;
@property (weak, nonatomic) IBOutlet UIView *fastBgView;
@property (weak, nonatomic) IBOutlet UIImageView *fastImageView;
@property (weak, nonatomic) IBOutlet UILabel *fastTimeLB;
@property (weak, nonatomic) IBOutlet UIButton *lockScreenBtn;

@property (nonatomic,strong) AVPlayer *player;//播放器对象
@property (nonatomic,strong) AVPlayerItem *playerItem; // 播放属性
@property (nonatomic,assign)CGFloat totalTime;//总时长
@property (weak, nonatomic) IBOutlet UIProgressView *progressView;
@property (weak, nonatomic) IBOutlet CustomSlider *slideView;
/** 系统菊花 */
@property (nonatomic, strong) MMMaterialDesignSpinner *activity;
@property (weak, nonatomic) IBOutlet UIButton *fullScreenBtn;
@property (nonatomic,assign) CGFloat progress;//进度
@property (nonatomic,assign) CGFloat oldProgress;//已经播放的进度
@property (nonatomic, strong)AVPlayerLayer *playerLayer;
@property (nonatomic, assign ) UIDeviceOrientation lastOrientation;//上一次屏幕方向
@property (nonatomic, strong)NSTimer *timer;

@property (nonatomic , copy)NSString *videoUrl;


@property (nonatomic, assign)BOOL isAutoPlay;//是否自动播放
@property (nonatomic, assign)BOOL isPlaying;//是否正在播放
@property (nonatomic, assign)BOOL isHided;//状态栏是否隐藏

@property (nonatomic, assign)UIInterfaceOrientation nextinterfaceOrientation;
@property (nonatomic, assign)BOOL isFirstEnter;//是否第一次进入；

@end

@implementation CustomAVPlayer

#pragma mark ---点击事件

//关闭
- (IBAction)closeAction:(UIButton *)sender {
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(playerHideControlView) object:nil];
    sender.selected = !sender.selected;
    if (sender.selected) {
        [self.timer invalidate];
        self.timer = nil;
        [self.player.currentItem cancelPendingSeeks];
        [self.player.currentItem.asset cancelLoading];
        [self removeFromSuperview];

        if (self.delegate && [_delegate respondsToSelector:@selector(moviePlayerManagerDidClose)]) {
            [self.delegate moviePlayerManagerDidClose];
        }
    }else{
        if (self.isLockScreen) {
            sender.selected = YES;

            return;
        }
        [self toOrientation:UIInterfaceOrientationPortrait];

    }
}

//播放、暂停
- (IBAction)playAction:(UIButton *)sender {
    if (sender.selected) {
        [self pause];
        _isPlaying = NO;
    }else{
        [self start];
        _isPlaying = YES;

    }
    sender.selected = !sender.selected;

}
//全屏切换
- (IBAction)changeFullScreenAction:(UIButton *)sender {
    if (self.isLockScreen) {
        return;
    }
    sender.selected = !sender.selected;
    
    if(sender.selected == YES){
        self.nextinterfaceOrientation = UIInterfaceOrientationLandscapeLeft;
         [self toOrientation:self.nextinterfaceOrientation];
       
    }else{
        self.nextinterfaceOrientation = UIInterfaceOrientationPortrait;
        [self toOrientation:self.nextinterfaceOrientation];
        
    }
    
}

//锁屏切换
- (IBAction)lockScreenAction:(UIButton *)sender {
    sender.selected = !sender.selected;
    if (sender.selected) {
        self.isLockScreen = YES;
    }else{
        self.isLockScreen = NO;
    }
}


//重试
- (IBAction)attentionAction:(UIButton *)sender {
    if (self.netStatus == notReachable) {
        return;
    }else  if(self.netStatus == reachableViaWWAN){
        
    }else if(self.netStatus == reachableViaWiFi){
        if (_isFirstEnter) {
            [self configPlayer];
        }
    }

}

-(void)setNetStatus:(networkStatus)netStatus{
    _netStatus = netStatus;
    if (netStatus == notReachable) {
        [self.attentionBtn setTitle:@"无网络,请检查网络连接" forState:UIControlStateNormal];
        self.attentionBtn.hidden = NO;
        if (!_isFirstEnter) {
            self.attentionBtn.alpha = 0.3;
        }else{
            self.attentionBtn.alpha = 1;

        }
        return;
    }else  if(netStatus == reachableViaWWAN){
        [self.attentionBtn setTitle:@"当前为移动网络,是否继续播放" forState:UIControlStateNormal];        self.attentionBtn.alpha = 0.3;

    }else if(netStatus == reachableViaWiFi){
        if (!_isFirstEnter) {
            self.attentionBtn.hidden = YES;
        }
    }

}

//初始化
- (void)awakeFromNib{
    [super awakeFromNib];
    //控制栏
    [self playerShowControlView];
    //添加手势
    [self addGestureRecognizerAction];
    self.isFirstEnter = YES;
    self.netStatus = 1;
}

-(void)layoutSubviews{
    CGRect frame = CGRectMake(0, 0, self.bounds.size.width, self.bounds.size.height);
    self.playerLayer.frame = frame;
  }

-(void)setSuperView:(UIView *)superView{
    _superView = superView;
    [superView addSubview:self];
    [self mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.mas_equalTo(superView);
        make.left.mas_equalTo(superView);
        make.right.mas_equalTo(superView);
        make.height.mas_equalTo(superView);
    }];

}

- (MMMaterialDesignSpinner *)activity {
    if (!_activity) {
        _activity = [[MMMaterialDesignSpinner alloc] init];
        _activity.lineWidth = 1;
        _activity.duration  = 1;
        _activity.tintColor = [[UIColor whiteColor] colorWithAlphaComponent:0.9];
    }
    return _activity;
}

/**
 *  设置Player相关参数
 */
- (void)configPlayer{
    // 创建AVPlayer
//    http://dlhls.cdn.zhanqi.tv/zqlive/18278_FW5pl.m3u8
    self.playerItem = [AVPlayerItem playerItemWithURL:[NSURL URLWithString:self.videoUrl]];
    self.player = [AVPlayer playerWithPlayerItem:self.playerItem];
    
    //创建播放视图
    AVPlayerLayer *playerLayer=[AVPlayerLayer playerLayerWithPlayer:self.player];
    playerLayer.frame = CGRectMake(0, 0, self.bounds.size.width, self.bounds.size.height);
    self.playerLayer = playerLayer;
    playerLayer.videoGravity=AVLayerVideoGravityResizeAspect;//视频填充模式
    [self.layer addSublayer:playerLayer];
    [self addNotification];
    //添加进度
    self.timer = [NSTimer scheduledTimerWithTimeInterval:1.f target:self selector:@selector(Stack) userInfo:nil repeats:YES];
    NSRunLoop *runRoop= [NSRunLoop currentRunLoop];
    [runRoop addTimer: _timer forMode: NSRunLoopCommonModes];
    
    
    [self.playerItem addObserver:self forKeyPath:@"loadedTimeRanges" options:NSKeyValueObservingOptionNew context:nil];// 监听loadedTimeRanges属性
    [self.playerItem addObserver:self forKeyPath:@"status" options:NSKeyValueObservingOptionNew context:nil];
    [self.playerItem addObserver:self forKeyPath:@"playbackBufferEmpty" options:NSKeyValueObservingOptionNew context:nil];
    [self.playerItem addObserver:self forKeyPath:@"playbackLikelyToKeepUp" options:NSKeyValueObservingOptionNew context:nil];
    
    [self bringSubviewToFront:self.playBtn];
    
    self.lastOrientation = UIDeviceOrientationPortrait;
    
    [self bringSubviewToFront:self.topBgView];
    [self bringSubviewToFront:self.bottomBgView];
    [self bringSubviewToFront:self.attentionBtn];
    [self bringSubviewToFront:self.fastBgView];
    [self bringSubviewToFront:self.lockScreenBtn];
    self.fastBgView.hidden = YES;
    
    //添加菊花
    [self addSubview:self.activity];

    [self.activity mas_makeConstraints:^(MASConstraintMaker *make) {
        make.center.equalTo(self);
        make.width.with.height.mas_equalTo(45);
    }];
    
    //进度跳转回调
    __weak __typeof(self)weakSelf = self;
    self.slideView.progressBlock = ^(CGFloat value,BOOL isForword){
        if (weakSelf.playerItem.status != AVPlayerItemStatusReadyToPlay) {
            return ;
        }
        [weakSelf pause];
        
        if (weakSelf.isPlaying) {
            [weakSelf.activity startAnimating];
        }
        CGFloat panTotime = value  *  weakSelf.totalTime;
        int intpanToTime = floorf(panTotime);
        [weakSelf seekToplayTime:intpanToTime];
        
        weakSelf.fastTimeLB.text = [NSString stringWithFormat:@"%@/%@",weakSelf.starTimerLB.text,weakSelf.totalTimerLB.text];
        if (isForword) {
            [weakSelf.fastImageView setImage:[UIImage imageNamed:@"ZFPlayer_fast_forward"]];
            
        }else{
            [weakSelf.fastImageView setImage:[UIImage imageNamed:@"ZFPlayer_fast_backward"]];

        }

    };
    
    self.slideView.slideState = ^(SlideState state){
        if (state == chageSlide) {
              [NSObject cancelPreviousPerformRequestsWithTarget:weakSelf selector:@selector(playerHideControlView) object:nil];
            weakSelf.fastBgView.hidden = NO;
        }else if(state == StopSlide){
            [weakSelf playerShowControlView];
            weakSelf.fastBgView.hidden = YES;

        }
    };
    
    
    if(_isAutoPlay){
        [self start];
        [self.activity startAnimating];

        self.playBtn.selected = YES;
        self.isPlaying = YES;
    }
    
    self.attentionBtn.hidden = YES;
}


#pragma mark 公共方法
- (void)resetToPlayNewVideoUrl:(NSString *)videoUrl andIsAutoPlayVideo:(BOOL)isAutoPlay{

    if ([self.videoUrl isEqualToString:videoUrl]) {
        return;
    }
    self.isFirstEnter = YES;
    self.isPlaying = NO;
    self.isAutoPlay = isAutoPlay;
    self.videoUrl = videoUrl;
    [self pause];
    [self.activity stopAnimating];
    [self removeNotification];
    [self.playerLayer removeFromSuperlayer];
    self.playerItem = nil;
    [self.player replaceCurrentItemWithPlayerItem:nil];
    self.player = nil;
    [self.timer invalidate];
    self.timer = nil;
    self.playBtn.selected = NO;
    [self configPlayer];

}

- (void)start {
    [self.player play];
}

- (void)pause {
    [self.player pause];
    [self.activity stopAnimating];

}


#pragma mark - 私有方法
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSString *,id> *)change context:(void *)context
{
    
    AVPlayerItem *playerItem = (AVPlayerItem *)object;
    if (_isPlaying) {
        [self.activity startAnimating];

    }

    if ([keyPath isEqualToString:@"status"]) {
        [self.activity stopAnimating];

        if ([playerItem status] == AVPlayerStatusReadyToPlay) {
            //status 点进去看 有三种状态

            CGFloat duration = playerItem.duration.value / playerItem.duration.timescale; //视频总时间
            NSLog(@"准备好播放了，总时间：%.2f", duration);//还可以获得播放的进度，这里可以给播放进度条赋值了
            _totalTime = duration;
            self.isFirstEnter = NO;
        } else if ([playerItem status] == AVPlayerStatusFailed || [playerItem status] == AVPlayerStatusUnknown) {
            [self pause];
            NSLog(@"加载失败");
            _isPlaying = NO;
            self.attentionBtn.hidden = NO;
        }
        
    } else if ([keyPath isEqualToString:@"loadedTimeRanges"]) {  //监听播放器的下载进度
        [self.activity stopAnimating];
     
            NSTimeInterval timeInterval = [self availableDuration];// 计算缓冲进度
            CMTime duration = self.playerItem.duration;
            CGFloat totalDuration = CMTimeGetSeconds(duration);
            //缓存进度－－－－－－－－－－－－
            self.progressView.progress = timeInterval / totalDuration;
            
            if (self.delegate && [self respondsToSelector:@selector(moviePlayerManagerDidProgress:)]) {
                [self.delegate moviePlayerManagerDidProgress:self.progress];
            }
        
    } else if ([keyPath isEqualToString:@"playbackBufferEmpty"]) { //监听播放器在缓冲数据的状态
        
        NSLog(@"缓冲不足暂停了");
        [self.activity startAnimating];
        
    } else if ([keyPath isEqualToString:@"playbackLikelyToKeepUp"]) {
//        [self.activity stopAnimating];
        NSLog(@"缓冲达到可播放程度了");
    }
    

}

//获取缓存时间
- (NSTimeInterval)availableDuration {
    NSArray *loadedTimeRanges = [[_player currentItem] loadedTimeRanges];
    CMTimeRange timeRange = [loadedTimeRanges.firstObject CMTimeRangeValue];// 获取缓冲区域
    float startSeconds = CMTimeGetSeconds(timeRange.start);
    float durationSeconds = CMTimeGetSeconds(timeRange.duration);
    NSTimeInterval result = startSeconds + durationSeconds;// 计算缓冲总进度
    return result;
}

//秒转化为时间
- (NSString *)secondToTime :(int)second{
    NSDate *d = [NSDate dateWithTimeIntervalSince1970:second];
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:8]];
//    if (second/3600 >= 1) {
        [formatter setDateFormat:@"HH:mm:ss"];
//    }
//    else
//    {
//        [formatter setDateFormat:@"mm:ss"];
//    }
    NSString *showtimeNew = [formatter stringFromDate:d];
    return showtimeNew;
}


/**
 //跳转到某个时间点

 @param second 秒数
 */
- (void)seekToplayTime:(int)second{
    //秒数转换为时间
    NSString * showtimeNew =  [self secondToTime:second];
    
    //转换成CMTime才能给player来控制播放进度
    CMTime dragedCMTime = CMTimeMake(second, 1);
    
    // seekTime:completionHandler:不能精确定位
    // 如果需要精确定位，可以使用seekToTime:toleranceBefore:toleranceAfter:completionHandler:
    [self.player  seekToTime:dragedCMTime toleranceBefore:CMTimeMake(1,1) toleranceAfter:CMTimeMake(1,1) completionHandler:^(BOOL finished) {
        [self.activity stopAnimating];
        if (_isPlaying && finished) {
            [self.player play];
        }
        self.starTimerLB.text = showtimeNew;
    }];
    
//    [self.player seekToTime:dragedCMTime completionHandler:
//     ^(BOOL finish)
//     {
//         [self.activity stopAnimating];
//         if (_isPlaying && finish) {
//             [self.player play];
//         }
//         self.starTimerLB.text = showtimeNew;
//     }];
}

#pragma mark - 添加手势
- (void)addGestureRecognizerAction{
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(tapAction:)];
    self.bottomBgView.userInteractionEnabled = YES;
    self.topBgView.userInteractionEnabled = YES;
    self.userInteractionEnabled = YES;
    [self addGestureRecognizer:tap];
//    tap.delegate = self;

    
    //隔断手势
    UIPanGestureRecognizer *tap1 = [[UIPanGestureRecognizer alloc]initWithTarget:self action:@selector(emptyAction)];
    UIPanGestureRecognizer *tap2 = [[UIPanGestureRecognizer alloc]initWithTarget:self action:@selector(emptyAction)];
    [self.bottomBgView addGestureRecognizer:tap1];
    [self.topBgView addGestureRecognizer:tap2];
}

- (void)emptyAction{
    
}



#pragma mark - 添加通知
/**
 *  添加播放器通知
 */
-(void)addNotification{
    //给AVPlayerItem添加播放完成通知
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playbackFinished:) name:AVPlayerItemDidPlayToEndTimeNotification object:self.player.currentItem];
    
    // 监测设备方向
    [[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(onDeviceOrientationChange)
                                                 name:UIDeviceOrientationDidChangeNotification
                                               object:nil];
    // app退到后台
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appDidEnterBackground) name:UIApplicationWillResignActiveNotification object:nil];
    // app进入前台
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appDidEnterPlayground) name:UIApplicationDidBecomeActiveNotification object:nil];
    
    // 监听耳机插入和拔掉通知
    [[AVAudioSession sharedInstance] setActive:YES error:nil];//创建单例对象并且使其设置为活跃状态.
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(audioRouteChangeListenerCallback:) name:AVAudioSessionRouteChangeNotification object:nil];
    
}

#pragma mark --屏幕旋转处理
/**
 *  屏幕方向发生变化会调用这里
 */
- (void)onDeviceOrientationChange {
    if (self.isLockScreen) {
        return;
    }
    UIDeviceOrientation orientation = [UIDevice currentDevice].orientation;
    UIInterfaceOrientation interfaceOrientation = (UIInterfaceOrientation)orientation;
    if (orientation == UIDeviceOrientationFaceUp || orientation == UIDeviceOrientationFaceDown || orientation == UIDeviceOrientationUnknown ) { return; }

    switch (interfaceOrientation) {
        case UIInterfaceOrientationPortraitUpsideDown:{
        }
            break;
        case UIInterfaceOrientationPortrait:{
                [self toOrientation:UIInterfaceOrientationPortrait];

        }
            break;
        case UIInterfaceOrientationLandscapeLeft:{
                [self toOrientation:UIInterfaceOrientationLandscapeLeft];
                _nextinterfaceOrientation = interfaceOrientation;

        }
            break;
        case UIInterfaceOrientationLandscapeRight:{
                [self toOrientation:UIInterfaceOrientationLandscapeRight];
                _nextinterfaceOrientation = interfaceOrientation;

        }
            break;
        default:
            break;
    }
}

- (void)toOrientation:(UIInterfaceOrientation)orientation {
    if (self.isLockScreen) {
        return;
    }
    // 获取到当前状态条的方向
    UIInterfaceOrientation currentOrientation = [UIApplication sharedApplication].statusBarOrientation;
    // 判断如果当前方向和要旋转的方向一致,那么不做任何操作
    if (currentOrientation == orientation) { return; }
    
    // 根据要旋转的方向,使用Masonry重新修改限制
    if (orientation != UIInterfaceOrientationPortrait) {
        self.closeBtn.selected = YES;
        self.fullScreenBtn.selected = YES;
        [[UIApplication sharedApplication] setStatusBarHidden:YES];
        // 这个地方加判断是为了从全屏的一侧,直接到全屏的另一侧不用修改限制,否则会出错;
        if (currentOrientation == UIInterfaceOrientationPortrait) {
            [self removeFromSuperview];
            UIWindow *window =   [UIApplication sharedApplication].keyWindow;
            [window.rootViewController.view addSubview:self];
            [self bringSubviewToFront:self.bottomBgView];
//            [window insertSubview:self belowSubview:self.bottomBgView];
            [self mas_remakeConstraints:^(MASConstraintMaker *make) {
                make.width.equalTo(@(KScreenHeight));
                make.height.equalTo(@(KScreenWidth));
                make.center.equalTo([UIApplication sharedApplication].keyWindow);
            }];
        }
    }else{
        self.closeBtn.selected = NO;
        self.fullScreenBtn.selected = NO;
        [[UIApplication sharedApplication] setStatusBarHidden:NO];
        [self removeFromSuperview];
        [self.superView addSubview:self];
        [self mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.top.mas_equalTo(self.superView);
            make.left.mas_equalTo(self.superView);
            make.right.mas_equalTo(self.superView);
            make.height.mas_equalTo(self.superView);
        }];

    }
    // iOS6.0之后,设置状态条的方法能使用的前提是shouldAutorotate为NO,也就是说这个视图控制器内,旋转要关掉;
    // 也就是说在实现这个方法的时候-(BOOL)shouldAutorotate返回值要为NO
    [[UIApplication sharedApplication] setStatusBarOrientation:orientation animated:NO];
    // 获取旋转状态条需要的时间:
    [UIView beginAnimations:nil context:nil];
    [UIView setAnimationDuration:0.3];
    // 更改了状态条的方向,但是设备方向UIInterfaceOrientation还是正方向的,这就要设置给你播放视频的视图的方向设置旋转
    // 给你的播放视频的view视图设置旋转
    self.transform = CGAffineTransformIdentity;
    self.transform = [self getTransformRotationAngle];
    // 开始旋转
    [UIView commitAnimations];

}

/**
 * 获取变换的旋转角度
 *
 * @return 角度
 */
- (CGAffineTransform)getTransformRotationAngle {
    // 状态条的方向已经设置过,所以这个就是你想要旋转的方向
    UIInterfaceOrientation orientation = [UIApplication sharedApplication].statusBarOrientation;
    // 根据要进行旋转的方向来计算旋转的角度
    if (orientation == UIInterfaceOrientationPortrait) {
        return CGAffineTransformIdentity;
    } else if (orientation == UIInterfaceOrientationLandscapeLeft){
        return CGAffineTransformMakeRotation(-M_PI_2);
    } else if(orientation == UIInterfaceOrientationLandscapeRight){
        return CGAffineTransformMakeRotation(M_PI_2);
    }
    return CGAffineTransformIdentity;
}

/**
 *  播放完成通知
 *
 *  @param notification 通知对象
 */
-(void)playbackFinished:(NSNotification *)notification{
    NSLog(@"视频播放完成.");
    [self seekToplayTime:0];
    self.playBtn.selected = NO;
    [self pause];
    _isPlaying = NO;

    if (self.delegate && [_delegate respondsToSelector:@selector(moviePlayerManagerDidFinish)]) {
        [self.delegate moviePlayerManagerDidFinish];
    }
}

/**
 *  应用退到后台
 */
- (void)appDidEnterBackground {
    [self pause];
    self.playBtn.selected = NO;
    [self toOrientation:UIInterfaceOrientationPortrait];

}

/**
 *  应用进入前台
 */
- (void)appDidEnterPlayground {
    if (_isPlaying) {
        [self start];
        self.playBtn.selected = YES;

    }
//    if (self.nextinterfaceOrientation == UIInterfaceOrientationLandscapeLeft || self.nextinterfaceOrientation == UIInterfaceOrientationLandscapeRight) {
//        self.fullScreenBtn.selected = YES;
//
//    }
//        [self toOrientation:self.nextinterfaceOrientation];
}

/**
 *  耳机插入、拔出事件
 */
- (void)audioRouteChangeListenerCallback:(NSNotification*)notification {
    NSDictionary *interuptionDict = notification.userInfo;
    
    NSInteger routeChangeReason = [[interuptionDict valueForKey:AVAudioSessionRouteChangeReasonKey] integerValue];
    
    switch (routeChangeReason) {
            
        case AVAudioSessionRouteChangeReasonNewDeviceAvailable:
            // 耳机插入
            break;
            
        case AVAudioSessionRouteChangeReasonOldDeviceUnavailable:
        {
            // 耳机拔掉
            // 拔掉耳机继续播放
            if(_isPlaying){
                [self start];
            }
        }
            break;
            
        case AVAudioSessionRouteChangeReasonCategoryChange:
            // called at start - also when other audio wants to play
            NSLog(@"AVAudioSessionRouteChangeReasonCategoryChange");
            break;
    }
}


#pragma mark - timer事件

- (void)Stack {
    if (_playerItem.duration.timescale != 0) {
//        [self.activity stopAnimating];
        self.oldProgress = CMTimeGetSeconds([_playerItem currentTime]) / (_playerItem.duration.value / _playerItem.duration.timescale);
        
        //当前时长进度progress
        NSInteger proHour = (NSInteger)CMTimeGetSeconds([_player currentTime]) / 3600;//当前小时
        NSInteger proMin = (NSInteger)CMTimeGetSeconds([_player currentTime]) / 60;//当前秒
        NSInteger proSec = (NSInteger)CMTimeGetSeconds([_player currentTime]) % 60;//当前分钟
        //    NSLog(@"%d",_playerItem.duration.timescale);
        //    NSLog(@"%lld",_playerItem.duration.value/1000 / 60);
        
        //duration 总时长
        NSInteger durHour = (NSInteger)_playerItem.duration.value / _playerItem.duration.timescale / 3600;//总小时
        NSInteger durMin = (NSInteger)_playerItem.duration.value / _playerItem.duration.timescale / 60;//总秒
        NSInteger durSec = (NSInteger)_playerItem.duration.value / _playerItem.duration.timescale % 60;//总分钟
        NSString *str = [NSString stringWithFormat:@"%02ld:%02ld / %02ld:%02ld", proMin, proSec, durMin, durSec];
            self.slideView.value = _oldProgress;
//        self.progressView.progress = _oldProgress;
        self.starTimerLB.text = [NSString stringWithFormat:@"%02ld:%02ld:%02ld",proHour,proMin,proSec];
        self.totalTimerLB.text = [NSString stringWithFormat:@"%02ld:%02ld:%02ld",durHour,durMin,durSec];
        
//        NSLog(@"===%f=====",_oldProgress);
        if (self.delegate && [self respondsToSelector:@selector(moviePlayerManagerDidOldProgress:time:)]) {
            [self.delegate moviePlayerManagerDidOldProgress:self.oldProgress time:str];
        }
    }
    if (_player.status == AVPlayerStatusReadyToPlay) {
        //        [_activity stopAnimating];
    } else {
        //        [_activity startAnimating];
    }
    
}

#pragma mark - 手势事件
- (void)tapAction:(UITapGestureRecognizer *)tap{
    if (_isHided) {
        [self playerShowControlView];
    }else{
        [self playerHideControlView];
    }
}


//- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch
//{
//    // tianyi memo:
//    // 点击在tableView上时，因为tableView自己不响应tap，所以会交给它的父视图self来响应，也就是响应_onTap:,但这不是我们想要的
//    // 我们需要点击tableView上面时，响应tableView的didSelectRowAtIndexPath方法.点击其他空白地方相应_onTap:
//    // 返回NO表示，tap手势不会根据响应者链传递了，当前的touch对象会被忽略，也就是丢弃这个手势，
//    // 丢弃手势之后，相当于手势识别失败，然后就会走默认的touch系列回调方法,我猜测在这个时候UITableView执行了自己默认的选择cell的流程.
//    if ([touch.view isDescendantOfView:self.topBgView] || [touch.view isDescendantOfView:self.bottomBgView] ) {
//        return NO;
//    }
//    return YES;
//}

#pragma mark --隐藏或者显示控制栏

/**
 *  显示控制层
 */
- (void)playerShowControlView {

    [UIView animateWithDuration:0 animations:^{
        [self showControlView];
    } completion:^(BOOL finished) {
        self.isHided = NO;
        [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(playerHideControlView) object:nil];
           [self performSelector:@selector(playerHideControlView) withObject:nil afterDelay:5.0];
    }];
}

/**
 *  隐藏控制层
 */
- (void)playerHideControlView {

    [UIView animateWithDuration:0.35 animations:^{
        [self hideControlView];
    }completion:^(BOOL finished) {
        self.isHided = YES;
    }];
}

- (void)showControlView {
    self.topBgView.alpha = 1;
    self.bottomBgView.alpha = 1;
    self.lockScreenBtn.alpha = 1;
    self.topBgView.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.3];
    self.bottomBgView.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.3];
//    [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationFade];
}

- (void)hideControlView {
    self.topBgView.alpha = 0;
    self.bottomBgView.alpha = 0;
    self.lockScreenBtn.alpha = 0;
}



//移除所有通知监听
-(void)removeNotification{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self.playerItem removeObserver:self forKeyPath:@"loadedTimeRanges"];
    [self.playerItem removeObserver:self forKeyPath:@"status"];
    [self.playerItem removeObserver:self forKeyPath:@"playbackBufferEmpty"];
    [self.playerItem removeObserver:self forKeyPath:@"playbackLikelyToKeepUp"];
    
//    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIDeviceOrientationDidChangeNotification object:self];
}

- (void)dealloc
{
    [self removeNotification];
    [self.playerLayer removeFromSuperlayer];
    self.playerItem = nil;
    self.player  = nil;
    self.playerLayer = nil;
    self.delegate = nil;
}

@end
