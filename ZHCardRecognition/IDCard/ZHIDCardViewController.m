//
//  ZHIDCardViewController.m
//  ZHCardRecognition
//
//  Created by 李保征 on 2017/9/4.
//  Copyright © 2017年 李保征. All rights reserved.
//

#import "ZHIDCardViewController.h"
#import "ZHIDCardRecogntionVC.h"

@interface ZHIDCardViewController ()

@property (nonatomic,strong) UIImageView *iconImageView;
@property (nonatomic,strong) UIButton *recognizeFrontBtn;
@property (nonatomic,strong) UIButton *recognizeBehindBtn;

@end

@implementation ZHIDCardViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    
    [self.view addSubview:self.iconImageView];
    [self.view addSubview:self.recognizeFrontBtn];
    [self.view addSubview:self.recognizeBehindBtn];
}

#pragma mark - getter

- (UIImageView *)iconImageView{
    if (!_iconImageView) {
        CGFloat imageViewY = 100;
        CGFloat imageViewW = self.view.bounds.size.width;
        CGFloat imageViewH = imageViewW / 1.5;
        CGFloat imageViewX = 0;
        _iconImageView = [[UIImageView alloc] initWithFrame:CGRectMake(imageViewX, imageViewY, imageViewW, imageViewH)];
        _iconImageView.contentMode = UIViewContentModeScaleAspectFill;
        _iconImageView.clipsToBounds = YES;
        _iconImageView.backgroundColor = [UIColor clearColor];
        _iconImageView.image = [UIImage imageNamed:@"idcard_first"];
    }
    return _iconImageView;
}

- (UIButton *)recognizeFrontBtn{
    if (!_recognizeFrontBtn) {
        CGFloat btnX = 0;
        CGFloat btnY = CGRectGetMaxY(self.iconImageView.frame) + 100;
        CGFloat btnW = self.view.bounds.size.width;
        CGFloat btnH = 50;
        
        _recognizeFrontBtn = [[UIButton alloc] initWithFrame:CGRectMake(btnX, btnY, btnW, btnH)];
        _recognizeFrontBtn.backgroundColor = [UIColor orangeColor];
        
        [_recognizeFrontBtn setTitle:@"开始识别（正面）" forState:UIControlStateNormal];
        [_recognizeFrontBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        
        [_recognizeFrontBtn addTarget:self action:@selector(recognizeFrontBtnClick:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _recognizeFrontBtn;
}

- (UIButton *)recognizeBehindBtn{
    if (!_recognizeBehindBtn) {
        CGFloat btnX = 0;
        CGFloat btnY = CGRectGetMaxY(self.recognizeFrontBtn.frame) + 20;
        CGFloat btnW = self.view.bounds.size.width;
        CGFloat btnH = 50;
        
        _recognizeBehindBtn = [[UIButton alloc] initWithFrame:CGRectMake(btnX, btnY, btnW, btnH)];
        _recognizeBehindBtn.backgroundColor = [UIColor orangeColor];
        
        [_recognizeBehindBtn setTitle:@"开始识别（反面）" forState:UIControlStateNormal];
        [_recognizeBehindBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        
        [_recognizeBehindBtn addTarget:self action:@selector(recognizeBehindBtnClick:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _recognizeBehindBtn;
}

- (void)recognizeFrontBtnClick:(UIButton *)btn{
#if TARGET_IPHONE_SIMULATOR
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"提示" message:@"模拟器不能操作" delegate:nil cancelButtonTitle:@"确定" otherButtonTitles:nil];
    [alert show];
#else
    ZHIDCardRecogntionVC *vc = [[ZHIDCardRecogntionVC alloc] init];
    vc.recogntionType = RecogntionTypeFront;
    [self.navigationController pushViewController:vc animated:YES];
#endif
}

- (void)recognizeBehindBtnClick:(UIButton *)btn{
#if TARGET_IPHONE_SIMULATOR
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"提示" message:@"模拟器不能操作" delegate:nil cancelButtonTitle:@"确定" otherButtonTitles:nil];
    [alert show];
#else
    ZHIDCardRecogntionVC *vc = [[ZHIDCardRecogntionVC alloc] init];
    vc.recogntionType = RecogntionTypeBehind;
    [self.navigationController pushViewController:vc animated:YES];
#endif
}



@end
