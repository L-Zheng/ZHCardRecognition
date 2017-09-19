//
//  ZHCustomScanView.m
//  ZHCardRecognition
//
//  Created by 李保征 on 2017/9/4.
//  Copyright © 2017年 李保征. All rights reserved.
//

#import "ZHCustomScanView.h"

// iPhone5/5c/5s/SE 4英寸 屏幕宽高：320*568点 屏幕模式：2x 分辨率：1136*640像素
#define iPhone5or5cor5sorSE ([UIScreen mainScreen].bounds.size.height == 568.0)

// iPhone6/6s/7 4.7英寸 屏幕宽高：375*667点 屏幕模式：2x 分辨率：1334*750像素
#define iPhone6or6sor7 ([UIScreen mainScreen].bounds.size.height == 667.0)

// iPhone6 Plus/6s Plus/7 Plus 5.5英寸 屏幕宽高：414*736点 屏幕模式：3x 分辨率：1920*1080像素
#define iPhone6Plusor6sPlusor7Plus ([UIScreen mainScreen].bounds.size.height == 736.0)

@interface ZHCustomScanView ()

/** 分割线 */
@property (nonatomic,strong) CAShapeLayer *separateLineLayer;
/** 填充外围区域 */
@property (nonatomic,strong) CAShapeLayer *fillLayer;
/** 头像 */
@property (nonatomic,strong) UIImageView *headImageView;
@property (nonatomic,strong) UILabel *tipLabel;
@property (nonatomic,strong) NSTimer *timer;

@end

@implementation ZHCustomScanView

- (instancetype)initWithFrame:(CGRect)frame{
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
        
        [self.layer addSublayer:self.separateLineLayer];
        [self.layer addSublayer:self.fillLayer];
        [self addSubview:self.headImageView];
        [self addSubview:self.tipLabel];
        
        self.isIDCardBehind = NO;
        
        [self addTimer];
    }
    return self;
}

#pragma mark - getter

- (CAShapeLayer *)separateLineLayer{
    if (!_separateLineLayer) {
        _separateLineLayer = [CAShapeLayer layer];
        _separateLineLayer.position = self.layer.position;
        CGFloat width = iPhone5or5cor5sorSE ? 240: (iPhone6or6sor7 ? 270: 300);
        _separateLineLayer.bounds = (CGRect){CGPointZero, {width, width * 1.574}};
        _separateLineLayer.cornerRadius = 15;
        _separateLineLayer.borderColor = [UIColor whiteColor].CGColor;
        _separateLineLayer.borderWidth = 1.5;
    }
    return _separateLineLayer;
}

- (CAShapeLayer *)fillLayer{
    if (!_fillLayer) {
        UIBezierPath *transparentRoundedRectPath = [UIBezierPath bezierPathWithRoundedRect:self.separateLineLayer.frame cornerRadius:self.separateLineLayer.cornerRadius];
        
        UIBezierPath *path = [UIBezierPath bezierPathWithRect:self.frame];
        [path appendPath:transparentRoundedRectPath];
        [path setUsesEvenOddFillRule:YES];
        
        _fillLayer = [CAShapeLayer layer];
        _fillLayer.path = path.CGPath;
        _fillLayer.fillRule = kCAFillRuleEvenOdd;
        _fillLayer.fillColor = [UIColor blackColor].CGColor;
        _fillLayer.opacity = 0.6;
    }
    return _fillLayer;
}

- (UIImageView *)headImageView{
    if (!_headImageView) {
        CGFloat facePathWidth = iPhone5or5cor5sorSE? 125: (iPhone6or6sor7? 150: 180);
        CGFloat facePathHeight = facePathWidth * 0.812;
        CGRect rect = self.separateLineLayer.frame;
        self.facePathRect = (CGRect){CGRectGetMaxX(rect) - facePathWidth - 35,CGRectGetMaxY(rect) - facePathHeight - 25,facePathWidth,facePathHeight};
        
        _headImageView = [[UIImageView alloc] initWithFrame:self.facePathRect];
        _headImageView.contentMode = UIViewContentModeScaleAspectFill;
        _headImageView.clipsToBounds = YES;
        _headImageView.backgroundColor = [UIColor clearColor];
        _headImageView.image = [UIImage imageNamed:@"idcard_first_head_5"];
        _headImageView.transform = CGAffineTransformMakeRotation(M_PI * 0.5);
    }
    return _headImageView;
}

- (UILabel *)tipLabel {
    if (!_tipLabel) {
        
        CGPoint center = self.center;
        center.x = CGRectGetMaxX(self.separateLineLayer.frame) + 20;

        _tipLabel = [[UILabel alloc] init];
        _tipLabel.font = [UIFont systemFontOfSize:15];
        _tipLabel.textAlignment = NSTextAlignmentCenter;
        _tipLabel.textColor = [UIColor whiteColor];
        _tipLabel.backgroundColor = [UIColor clearColor];
        _tipLabel.transform = CGAffineTransformMakeRotation(M_PI * 0.5);
        _tipLabel.center = center;
        _tipLabel.text = @"将身份证人像面置于此区域内，头像对准，扫描";
        [_tipLabel sizeToFit];
    }
    return _tipLabel;
}

- (NSTimer *)timer{
    if (!_timer) {
        _timer = [NSTimer scheduledTimerWithTimeInterval:0.02 target:self selector:@selector(timerAction:) userInfo:nil repeats:YES];
    }
    return _timer;
}

#pragma mark - setter

- (void)setIsIDCardBehind:(BOOL)isIDCardBehind{
    _isIDCardBehind = isIDCardBehind;
    
    self.tipLabel.text = isIDCardBehind ? @"将身份证国徽面置于此区域内，头像对准，扫描" : @"将身份证人像面置于此区域内，头像对准，扫描";
    [self.tipLabel sizeToFit];
    
    if (isIDCardBehind) {
        CGFloat facePathWidth = iPhone5or5cor5sorSE? 60: (iPhone6or6sor7? 80: 120);
        CGFloat facePathHeight = facePathWidth;
        CGRect rect = self.separateLineLayer.frame;
        self.facePathRect = (CGRect){CGRectGetMaxX(rect) - facePathWidth - 35,CGRectGetMinY(rect) + 25,facePathWidth,facePathHeight};
    }else{
        CGFloat facePathWidth = iPhone5or5cor5sorSE? 125: (iPhone6or6sor7? 150: 180);
        CGFloat facePathHeight = facePathWidth * 0.812;
        CGRect rect = self.separateLineLayer.frame;
        self.facePathRect = (CGRect){CGRectGetMaxX(rect) - facePathWidth - 35,CGRectGetMaxY(rect) - facePathHeight - 25,facePathWidth,facePathHeight};
    }
    
    self.headImageView.image = [UIImage imageNamed:isIDCardBehind ? @"Emblem" : @"idcard_first_head_5"];
    self.headImageView.frame = self.facePathRect;
    
}

#pragma mark - timer

-(void)addTimer {
    if (!self.timer.isValid) {
        [self.timer fire];
    }
}

-(void)timerAction:(id)notice {
    [self setNeedsDisplay];
}

#pragma mark - draw
- (void)drawRect:(CGRect)rect {
    
    rect = self.separateLineLayer.frame;
    
    // 人像提示框
    UIBezierPath *facePath = [UIBezierPath bezierPathWithRect:self.facePathRect];
    facePath.lineWidth = 1.5;
    [[UIColor whiteColor] set];
    [facePath stroke];
    
    // 水平扫描线
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    static CGFloat moveX = 0;
    static CGFloat distanceX = 0;
    
    CGContextBeginPath(context);
    CGContextSetLineWidth(context, 2);
    CGContextSetRGBStrokeColor(context,0.3,0.8,0.3,0.8);
    CGPoint p1, p2;// p1, p2 连成水平扫描线;
    
    moveX += distanceX;
    if (moveX >= CGRectGetWidth(rect) - 2) {
        distanceX = -2;
    } else if (moveX <= 2){
        distanceX = 2;
    }
    
    p1 = CGPointMake(CGRectGetMaxX(rect) - moveX, rect.origin.y);
    p2 = CGPointMake(CGRectGetMaxX(rect) - moveX, rect.origin.y + rect.size.height);
    
    CGContextMoveToPoint(context,p1.x, p1.y);
    CGContextAddLineToPoint(context, p2.x, p2.y);
    
    /*
     // 竖直扫描线
     static CGFloat moveY = 0;
     static CGFloat distanceY = 0;
     CGPoint p3, p4;// p3, p4连成竖直扫描线
     
     moveY += distanceY;
     if (moveY >= CGRectGetHeight(rect) - 2) {
     distanceY = -2;
     } else if (moveY <= 2) {
     distanceY = 2;
     }
     p3 = CGPointMake(rect.origin.x, rect.origin.y + moveY);
     p4 = CGPointMake(rect.origin.x + rect.size.width, rect.origin.y + moveY);
     
     CGContextMoveToPoint(context,p3.x, p3.y);
     CGContextAddLineToPoint(context, p4.x, p4.y);
     */
    
    CGContextStrokePath(context);
}

#pragma mark - dealloc

- (void)dealloc{
    [self.timer invalidate];
}

@end
