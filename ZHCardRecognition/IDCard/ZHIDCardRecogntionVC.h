//
//  ZHIDCardRecogntionVC.h
//  ZHCardRecognition
//
//  Created by 李保征 on 2017/9/4.
//  Copyright © 2017年 李保征. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSInteger, RecogntionType) {
    RecogntionTypeFront     = 0,
    RecogntionTypeBehind    = 1,
};

@interface ZHIDCardRecogntionVC : UIViewController

@property (nonatomic,assign) RecogntionType recogntionType;

@end
