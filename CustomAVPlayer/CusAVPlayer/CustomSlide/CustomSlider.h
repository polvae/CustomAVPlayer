//
//  CustomSlider.h
//  自定义滑竿
//
//  Created by KingoSoft on 17/3/7.
//  Copyright © 2017年 KingSoft. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef enum : NSUInteger {
    BeginSlide,
    chageSlide,
    StopSlide,
} SlideState;

typedef void(^passProgressBlock)(CGFloat, BOOL);

typedef void(^passStateBlock)(SlideState );


@interface CustomSlider : UISlider

@property (nonatomic, copy)passProgressBlock progressBlock;

@property (nonatomic, copy)passStateBlock slideState;

@end
