//
//  ZHIDCardInfo.h
//  ZHCardRecognition
//
//  Created by 李保征 on 2017/9/5.
//  Copyright © 2017年 李保征. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

typedef NS_ENUM(NSInteger, IDCardType) {
    IDCardTypeUnknown      = 0,
    IDCardTypeFront     = 1,
    IDCardTypeBehind      = 2,
};

@interface ZHIDCardInfo : NSObject

@property (nonatomic,assign) IDCardType idCardType; //1:正面  2:反面
@property (nonatomic,copy) NSString *num; //身份证号
@property (nonatomic,copy) NSString *name; //姓名
@property (nonatomic,copy) NSString *gender; //性别
@property (nonatomic,copy) NSString *nation; //民族
@property (nonatomic,copy) NSString *address; //地址
@property (nonatomic,copy) NSString *issue; //签发机关
@property (nonatomic,copy) NSString *valid; //有效期


@property (nonatomic,strong) UIImage *IDImage; //图像

@end
