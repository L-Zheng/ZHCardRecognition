//
//  ZHIDCardInfoVC.m
//  ZHCardRecognition
//
//  Created by 李保征 on 2017/9/5.
//  Copyright © 2017年 李保征. All rights reserved.
//

#import "ZHIDCardInfoVC.h"

@interface ZHIDCardInfoVC ()
@property (nonatomic,strong) UIImageView *idCardImageView;
@property (nonatomic,strong) UILabel *infoLabel;

@end

@implementation ZHIDCardInfoVC

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    
    [self.view addSubview:self.idCardImageView];
    [self.view addSubview:self.infoLabel];
    
    self.idCardImageView.image = self.idCardInfo.IDImage;
    
    self.infoLabel.text = [NSString stringWithFormat:@"\n正反面：%@\n姓名：%@\n性别：%@\n民族：%@\n住址：%@\n公民身份证号码：%@\n\n签发机关：%@\n有效期限：%@",(self.idCardInfo.idCardType == IDCardTypeFront ? @"正面" : @"反面"),self.idCardInfo.name,self.idCardInfo.gender,self.idCardInfo.nation,self.idCardInfo.address,self.idCardInfo.num,self.idCardInfo.issue,self.idCardInfo.valid];
}

- (UIImageView *)idCardImageView{
    if (!_idCardImageView) {
        CGFloat imageViewY = 30;
        CGFloat imageViewH = 400;
        CGFloat imageViewX = 0;
        CGFloat imageViewW = self.view.bounds.size.width;
        _idCardImageView = [[UIImageView alloc] initWithFrame:CGRectMake(imageViewX, imageViewY, imageViewW, imageViewH)];
        _idCardImageView.contentMode = UIViewContentModeScaleAspectFit;
        _idCardImageView.clipsToBounds = YES;
        _idCardImageView.layer.masksToBounds = YES;
        _idCardImageView.layer.cornerRadius = 8;
        _idCardImageView.backgroundColor = [UIColor orangeColor];
    }
    return _idCardImageView;
}

- (UILabel *)infoLabel {
    if (!_infoLabel) {
        CGFloat labelY = CGRectGetMaxY(self.idCardImageView.frame) + 10;
        CGFloat labelH = 100;
        CGFloat labelX = 0;
        CGFloat labelW = self.view.bounds.size.width;
        
        _infoLabel = [[UILabel alloc] initWithFrame:CGRectMake(labelX, labelY , labelW, labelH)];
        _infoLabel.font = [UIFont systemFontOfSize:16.0f];
        _infoLabel.textAlignment = NSTextAlignmentCenter;
        _infoLabel.numberOfLines = 0;
        _infoLabel.textColor = [UIColor blackColor];
        _infoLabel.backgroundColor = [UIColor clearColor];
        _infoLabel.adjustsFontSizeToFitWidth = YES;
        //        _infoLabel.userInteractionEnabled = YES;
    }
    return _infoLabel;
}

@end
