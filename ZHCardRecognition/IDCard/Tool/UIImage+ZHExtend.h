//
//  UIImage+ZHExtend.h
//  ZHCardRecognition
//
//  Created by 李保征 on 2017/9/5.
//  Copyright © 2017年 李保征. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

@interface UIImage (ZHExtend)

+ (UIImage *)imageFromSampleBuffer:(CMSampleBufferRef)sampleBuffer;
+ (UIImage *)getImageStream:(CVImageBufferRef)imageBuffer;
+ (UIImage *)getSubImage:(CGRect)rect inImage:(UIImage*)image;

-(UIImage *)originalImage;

@end
