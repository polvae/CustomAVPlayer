//
//  CustomSlider.m
//  自定义滑竿
//
//  Created by KingoSoft on 17/3/7.
//  Copyright © 2017年 KingSoft. All rights reserved.
//

#import "CustomSlider.h"

#define KMaximumValue  (1.0)

@interface CustomSlider ()

@property (nonatomic, strong) UITapGestureRecognizer *tap;
@property (nonatomic, assign)CGFloat nextSolidValue;//向前

@end

@implementation CustomSlider

-(void)awakeFromNib{
    [super awakeFromNib];
    [self setUp];
}

-(instancetype)initWithFrame:(CGRect)frame{
    self  = [super initWithFrame:frame];
    if (self) {
        [self setUp];
    }
    return self;
}


- (void)setUp{
    //左右轨的图片
//    UIImage *stetchLeftTrack= [UIImage imageNamed:@"brightness_bar.png"];
    
//    UIImage *stetchRightTrack = [UIImage imageNamed:@"brightness_bar.png"];
    //滑块图片
    UIImage *thumbImage = [UIImage imageNamed:@"ZFPlayer_slider"];
    
//    UISlider *self=[[UISlider alloc]initWithFrame:CGRectMake(30, 320, 257, 7)];
    self.backgroundColor = [UIColor clearColor];
    self.value=0;
    self.minimumValue=0;
    self.maximumValue = KMaximumValue;
    self.backgroundColor = [[UIColor whiteColor] colorWithAlphaComponent:0];
    self.minimumTrackTintColor = [UIColor redColor];
    self.maximumTrackTintColor = [[UIColor blackColor] colorWithAlphaComponent:0];
//    [self setMinimumTrackImage:stetchLeftTrack forState:UIControlStateNormal];
//    [self setMaximumTrackImage:stetchRightTrack forState:UIControlStateNormal];
    //注意这里要加UIControlStateHightlighted的状态，否则当拖动滑块时滑块将变成原生的控件
    [self setThumbImage:thumbImage forState:UIControlStateHighlighted];
    [self setThumbImage:thumbImage forState:UIControlStateNormal];
    //滑块拖动时的事件
    [self addTarget:self action:@selector(sliderValueChanged:) forControlEvents:UIControlEventValueChanged];
    //滑动拖动后的事件
    [self addTarget:self action:@selector(sliderDragUp:) forControlEvents:UIControlEventTouchCancel];
    [self addTarget:self action:@selector(sliderDragUp:) forControlEvents:UIControlEventTouchUpInside];

    _tap = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(changeValue:)];
    [self addGestureRecognizer:_tap];

}

- (void)sliderValueChanged:(UISlider *)slider{
    //    NSLog(@"%f",slider.value);
    [self removeGestureRecognizer:_tap];
    BOOL isForword = slider.value - _nextSolidValue > 0 ? YES : NO;

    if (self.progressBlock) {
        self.progressBlock(slider.value,isForword);
        NSLog(@"%f",slider.value);
    }
    if (_slideState) {
        _slideState(chageSlide);
    }
    _nextSolidValue = slider.value;

}

- (void)sliderDragUp:(UISlider *)slider{
    [self addGestureRecognizer:_tap];
    if (_slideState) {
        _slideState(StopSlide);
    }
}

- (void)changeValue:(UITapGestureRecognizer *)tap{
    CGPoint stoptappoint;
    if (tap.state == UIGestureRecognizerStateEnded){
        stoptappoint = [tap locationInView:self];
    }
    CGRect frame = tap.view.frame;
    self.value = stoptappoint.x/ frame.size.width * KMaximumValue;
    NSLog(@"%f",stoptappoint.x/ frame.size.width);
    if (self.progressBlock) {
        self.progressBlock(self.value,NO);
    }
}



@end
