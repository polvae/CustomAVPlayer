//
//  CustomAVPlayer.h
//  自定义播放器
//
//  Created by KingoSoft on 17/3/3.
//  Copyright © 2017年 KingSoft. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef enum : NSInteger {
    notReachable = 0,
    reachableViaWiFi,
    reachableViaWWAN
} networkStatus;

@protocol moviePlayerManagerDelegate <NSObject>

@optional
- (void)moviePlayerManagerDidOldProgress:(CGFloat)progress time:(NSString *)time;
- (void)moviePlayerManagerDidProgress:(CGFloat)progress;
- (void)moviePlayerManagerDidFinish;
- (void)moviePlayerManagerDidClose;

@end

@interface CustomAVPlayer : UIView

@property (nonatomic,weak)id<moviePlayerManagerDelegate>delegate;
@property (nonatomic, strong)UIView *superView;
@property (nonatomic, assign)networkStatus netStatus;
@property (nonatomic, assign)BOOL isLockScreen; //是否锁定屏幕

- (void)resetToPlayNewVideoUrl:(NSString *)videoUrl andIsAutoPlayVideo:(BOOL)isAutoPlay;

@end
