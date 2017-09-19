//
//  ZHIDCardRecogntionVC.m
//  ZHCardRecognition
//
//  Created by 李保征 on 2017/9/4.
//  Copyright © 2017年 李保征. All rights reserved.
//

#import "ZHIDCardRecogntionVC.h"
#import <AVFoundation/AVFoundation.h>
#import <AssetsLibrary/AssetsLibrary.h>
#import "excards.h"
#import "ZHCustomScanView.h"
#import "ZHIDCardInfo.h"
#import "ZHRectManager.h"
#import "UIImage+ZHExtend.h"
#import "ZHIDCardInfoVC.h"

@interface ZHIDCardRecogntionVC ()<AVCaptureVideoDataOutputSampleBufferDelegate, AVCaptureMetadataOutputObjectsDelegate,UIAlertViewDelegate>

// 摄像头设备
@property (nonatomic,strong) AVCaptureDevice *device;
// AVCaptureSession对象来执行输入设备和输出设备之间的数据传递
@property (nonatomic,strong) AVCaptureSession *session;
// 输出格式
@property (nonatomic,strong) NSNumber *outPutSetting;
// 出流对象
@property (nonatomic,strong) AVCaptureVideoDataOutput *videoDataOutput;
// 元数据（用于人脸识别）
@property (nonatomic,strong) AVCaptureMetadataOutput *metadataOutput;
// 预览图层
@property (nonatomic,strong) AVCaptureVideoPreviewLayer *previewLayer;
// 人脸检测框区域
@property (nonatomic,assign) CGRect faceDetectionFrame;
// 队列
@property (nonatomic,strong) dispatch_queue_t queue;
// 是否打开手电筒
@property (nonatomic,assign,getter = isTorchOn) BOOL torchOn;

@property (nonatomic,strong) ZHCustomScanView *scanView;

@property (nonatomic,strong) UIButton *torchBtn;

@property (nonatomic,strong) UIButton *closeBtn;

@end

@implementation ZHIDCardRecogntionVC

#if TARGET_IPHONE_SIMULATOR

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor whiteColor];
    
    [self showErrorAlert];
}

#else

#pragma mark - ViewLoad

/** 
 // 设置人脸扫描区域
 
 为什么做人脸扫描？
 
 经实践证明，由于预览图层是全屏的，当用户有时没有将身份证对准拍摄框边缘时，也会成功读取身份证上的信息，即也会捕获到不完整的身份证图像。
 因此，为了截取到比较完整的身份证图像，在自定义扫描界面的合适位置上加了一个身份证头像框，让用户将该小框对准身份证上的头像，最终目的是使程序截取到完整的身份证图像。
 当该小框检测到人脸时，再对比人脸区域是否在这个小框内，若在，说明用户的确将身份证头像放在了这个框里，那么此时这一帧身份证图像大小正好合适且完整，接下来才捕获该帧，就获得了完整的身份证截图。（若不在，那么就不捕获此时的图像）
 
 理解：检测身份证上的人脸是为了获得证上的人脸区域，获得人脸区域是为了希望人脸区域能在小框内，这样的话，才截取到完整的身份证图像。
 
 个人认为：有了文字、拍摄区域的提示，99%的用户会主动将身份证和拍摄框边缘对齐，就能够获得完整的身份证图像，不做人脸区域的检测也可以。。。
 
 ps: 如果你不想加入人脸识别这一功能，你的app无需这么精细的话或者你又想读取到身份证反面的信息（签发机关，有效期），请这样做：
 
 1、请注释掉所有metadataOutput的代码及其下面的那个代理方法（-(void)captureOutput:(AVCaptureOutput *)captureOutput didOutputMetadataObjects:(NSArray *)metadataObjects fromConnection:(AVCaptureConnection *)connection）
 
 2、请在videoDataOutput的懒加载方法的if(_videoDataOutput == nil){}语句块中添加[_videoDataOutput setSampleBufferDelegate:self queue:self.queue];
 
 3、请注释掉AVCaptureVideoDataOutputSampleBufferDelegate下的那个代理方法中的
 if (self.videoDataOutput.sampleBufferDelegate) {
 [self.videoDataOutput setSampleBufferDelegate:nil queue:self.queue];
 }
 
 4、运行程序，身份证正反两面皆可被检测到，请查看打印的信息。
 
//    [[NSNotificationCenter defaultCenter] addObserverForName:AVCaptureInputPortFormatDescriptionDidChangeNotification object:nil queue:[NSOperationQueue currentQueue] usingBlock:^(NSNotification* _Nonnull note) {
//        __weak __typeof__(self) weakSelf = self;
//        self.metadataOutput.rectOfInterest = [self.previewLayer metadataOutputRectOfInterestForRect:IDCardScaningView.facePathRect];
//    }];
 */

- (void)viewDidLoad {
    [super viewDidLoad];
    
    //    self.navigationController.navigationBarHidden = YES;
    
    self.title = @"扫描";
    
    // 初始化rect
    const char *thePath = [[[NSBundle mainBundle] resourcePath] UTF8String];
    int ret = EXCARDS_Init(thePath);
    if (ret != 0) {
        NSLog(@"初始化失败：ret=%d", ret);
    }
    
    // 添加预览图层
    [self.view.layer addSublayer:self.previewLayer];
    
    if (self.recogntionType == RecogntionTypeBehind) {
        self.metadataOutput.rectOfInterest = [self.previewLayer metadataOutputRectOfInterestForRect:self.scanView.facePathRect];
    }
    
    [self.view addSubview:self.scanView];
    self.faceDetectionFrame = self.scanView.facePathRect;
    
    [self.view addSubview:self.closeBtn];
}

- (void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    [self checkCameraAuthorizationStatus];
    
    self.torchOn = NO;
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:self.torchBtn];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self stopSession];
}

#pragma mark - getter

- (AVCaptureDevice *)device {
    if (_device == nil) {
        _device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
        
        NSError *error = nil;
        if ([_device lockForConfiguration:&error]) {
            if ([_device isSmoothAutoFocusSupported]) {
                // 平滑对焦
                _device.smoothAutoFocusEnabled = YES;
            }
            if ([_device isFocusModeSupported:AVCaptureFocusModeContinuousAutoFocus]) {
                // 自动持续对焦
                _device.focusMode = AVCaptureFocusModeContinuousAutoFocus;
            }
            if ([_device isExposureModeSupported:AVCaptureExposureModeContinuousAutoExposure ]) {
                // 自动持续曝光
                _device.exposureMode = AVCaptureExposureModeContinuousAutoExposure;
            }
            if ([_device isWhiteBalanceModeSupported:AVCaptureWhiteBalanceModeContinuousAutoWhiteBalance]) {
                // 自动持续白平衡
                _device.whiteBalanceMode = AVCaptureWhiteBalanceModeContinuousAutoWhiteBalance;
            }
            [_device unlockForConfiguration];
        }
    }
    return _device;
}

- (NSNumber *)outPutSetting {
    if (_outPutSetting == nil) {
        _outPutSetting = @(kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange);
    }
    return _outPutSetting;
}

- (AVCaptureMetadataOutput *)metadataOutput {
    if (_metadataOutput == nil) {
        _metadataOutput = [[AVCaptureMetadataOutput alloc]init];
        if (self.recogntionType == RecogntionTypeFront) {
            //人脸识别扫描代理
            [_metadataOutput setMetadataObjectsDelegate:self queue:self.queue];
        }
    }
    return _metadataOutput;
}

- (AVCaptureVideoDataOutput *)videoDataOutput {
    if (_videoDataOutput == nil) {
        _videoDataOutput = [[AVCaptureVideoDataOutput alloc] init];
        _videoDataOutput.alwaysDiscardsLateVideoFrames = YES;
        _videoDataOutput.videoSettings = @{(id)kCVPixelBufferPixelFormatTypeKey:self.outPutSetting};
        [_videoDataOutput setSampleBufferDelegate:self queue:self.queue];
    }
    return _videoDataOutput;
}

- (AVCaptureSession *)session {
    if (_session == nil) {
        _session = [[AVCaptureSession alloc] init];
        
        _session.sessionPreset = AVCaptureSessionPresetHigh;
        
        // 2、设置输入：由于模拟器没有摄像头，因此最好做一个判断
        NSError *error = nil;
        AVCaptureDeviceInput *input = [AVCaptureDeviceInput deviceInputWithDevice:self.device error:&error];
        
        if (error) {
            [self showErrorAlert];
        }else {
            if ([_session canAddInput:input]) {
                [_session addInput:input];
            }
            
            if ([_session canAddOutput:self.videoDataOutput]) {
                [_session addOutput:self.videoDataOutput];
            }
            
            if ([_session canAddOutput:self.metadataOutput]) {
                [_session addOutput:self.metadataOutput];
                // 输出格式要放在addOutPut之后，否则奔溃
                self.metadataOutput.metadataObjectTypes = @[AVMetadataObjectTypeFace];
            }
        }
    }
    return _session;
}

- (AVCaptureVideoPreviewLayer *)previewLayer {
    if (_previewLayer == nil) {
        _previewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:self.session];
        _previewLayer.frame = self.view.frame;
        _previewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
    }
    return _previewLayer;
}

- (dispatch_queue_t)queue {
    if (_queue == nil) {
        _queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    }
    return _queue;
}

- (ZHCustomScanView *)scanView{
    if (!_scanView) {
        _scanView = [[ZHCustomScanView alloc] initWithFrame:self.view.frame];
        _scanView.isIDCardBehind = (self.recogntionType == RecogntionTypeBehind);
    }
    return _scanView;
}

- (UIButton *)closeBtn{
    if (!_closeBtn) {
        CGFloat btnW = 40;
        CGFloat btnH = btnW;
        CGFloat btnX = CGRectGetMaxX(self.view.frame) - btnW;
        CGFloat btnY = CGRectGetMaxY(self.view.frame) - btnH;
        
        _closeBtn = [[UIButton alloc] initWithFrame:CGRectMake(btnX, btnY, btnW, btnH)];
        _closeBtn.backgroundColor = [UIColor clearColor];
        [_closeBtn setImage:[UIImage imageNamed:@"idcard_back"] forState:UIControlStateNormal];
        [_closeBtn addTarget:self action:@selector(closeBtnClick:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _closeBtn;
}

- (UIButton *)torchBtn{
    if (!_torchBtn) {
        CGFloat btnW = 40;
        CGFloat btnH = btnW;
        
        _torchBtn = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, btnW, btnH)];
        _torchBtn.backgroundColor = [UIColor orangeColor];
        [_torchBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [_torchBtn setTitle:@"开灯" forState:UIControlStateNormal];
        [_torchBtn setTitle:@"关灯" forState:UIControlStateSelected];
        [_torchBtn addTarget:self action:@selector(torchBtnClick:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _torchBtn;
}

#pragma mark - action

- (void)closeBtnClick:(UIButton *)btn{
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)torchBtnClick:(UIButton *)btn{
    self.torchBtn.selected = !self.torchBtn.selected;
    self.torchOn = !self.torchOn;
    
    if ([self.device hasTorch]){
        // 判断是否有闪光灯
        [self.device lockForConfiguration:nil];// 请求独占访问硬件设备
        
        if (self.isTorchOn) {
            [self.device setTorchMode:AVCaptureTorchModeOn];
        } else {
            [self.device setTorchMode:AVCaptureTorchModeOff];
        }
        [self.device unlockForConfiguration];// 请求解除独占访问硬件设备
    }else {
        [self showTorchErrorAlert];
    }
}

#pragma mark - Camera

-(void)checkCameraAuthorizationStatus {
    AVAuthorizationStatus authorizationStatus = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
    
    switch (authorizationStatus) {
        case AVAuthorizationStatusNotDetermined:{
            // 用户尚未决定授权与否，那就请求授权
            __weak __typeof__(self) weakSelf = self;
            [AVCaptureDevice requestAccessForMediaType:AVMediaTypeVideo completionHandler:^(BOOL granted) {
                granted ? [weakSelf runSession]: [weakSelf showCameraAuthorizationDeniedAlert];
            }];
            break;
        }
        case AVAuthorizationStatusAuthorized:{
            // 用户已授权，那就立即使用
            [self runSession];
            break;
        }
        case AVAuthorizationStatusDenied:{
            // 用户明确地拒绝授权，那就展示提示
            [self showCameraAuthorizationDeniedAlert];
            break;
        }
        case AVAuthorizationStatusRestricted:{
            [self showErrorAlert];
            break;
        }
    }
}

#pragma mark - Session

- (void)runSession {
    if (![self.session isRunning]) {
        dispatch_async(self.queue, ^{
            [self.session startRunning];
        });
    }
}

-(void)stopSession {
    if ([self.session isRunning]) {
        dispatch_async(self.queue, ^{
            [self.session stopRunning];
        });
    }
}

#pragma mark - AVCaptureMetadataOutputObjectsDelegate
#pragma mark 从输出的元数据中捕捉人脸
// 检测人脸是为了获得“人脸区域”，做“人脸区域”与“身份证人像框”的区域对比，当前者在后者范围内的时候，才能截取到完整的身份证图像
-(void)captureOutput:(AVCaptureOutput *)captureOutput didOutputMetadataObjects:(NSArray *)metadataObjects fromConnection:(AVCaptureConnection *)connection{
    if (metadataObjects.count) {
        AVMetadataMachineReadableCodeObject *metadataObject = metadataObjects.firstObject;
        
        AVMetadataObject *transformedMetadataObject = [self.previewLayer transformedMetadataObjectForMetadataObject:metadataObject];
        CGRect faceRegion = transformedMetadataObject.bounds;
        
        if (metadataObject.type == AVMetadataObjectTypeFace) {
            NSLog(@"是否包含头像：%d, facePathRect: %@, faceRegion: %@",CGRectContainsRect(self.faceDetectionFrame, faceRegion),NSStringFromCGRect(self.faceDetectionFrame),NSStringFromCGRect(faceRegion));
            
            if (CGRectContainsRect(self.faceDetectionFrame, faceRegion)) {// 只有当人脸区域的确在小框内时，才再去做捕获此时的这一帧图像
                // 为videoDataOutput设置代理，程序就会自动调用下面的代理方法，捕获每一帧图像
                if (!self.videoDataOutput.sampleBufferDelegate) {
                    [self.videoDataOutput setSampleBufferDelegate:self queue:self.queue];
                }
            }
        }
    }
}

#pragma mark - AVCaptureVideoDataOutputSampleBufferDelegate
#pragma mark 从输出的数据流捕捉单一的图像帧
// AVCaptureVideoDataOutput获取实时图像，这个代理方法的回调频率很快，几乎与手机屏幕的刷新频率一样快
-(void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection {
    if ([self.outPutSetting isEqualToNumber:[NSNumber numberWithInt:kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange]] || [self.outPutSetting isEqualToNumber:[NSNumber numberWithInt:kCVPixelFormatType_420YpCbCr8BiPlanarFullRange]]) {
        
        CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
        
        if ([captureOutput isEqual:self.videoDataOutput]) {
            // 身份证信息识别
            BOOL isSuccess = [self IDCardRecognit:imageBuffer];
            
            if (isSuccess) {
                // 身份证信息识别完毕后，就将videoDataOutput的代理去掉，防止频繁调用AVCaptureVideoDataOutputSampleBufferDelegate方法而引起的“混乱”
                if (self.videoDataOutput.sampleBufferDelegate) {
                    [self.videoDataOutput setSampleBufferDelegate:nil queue:self.queue];
                }
            }
            
        }
    } else {
        NSLog(@"输出格式不支持");
    }
}

#pragma mark - 身份证信息识别
- (BOOL)IDCardRecognit:(CVImageBufferRef)imageBuffer {
    BOOL isSuccess = NO;
    
    CVBufferRetain(imageBuffer);
    
    // Lock the image buffer
    if (CVPixelBufferLockBaseAddress(imageBuffer, 0) == kCVReturnSuccess) {
        size_t width= CVPixelBufferGetWidth(imageBuffer);// 1920
        size_t height = CVPixelBufferGetHeight(imageBuffer);// 1080
        
        CVPlanarPixelBufferInfo_YCbCrBiPlanar *planar = CVPixelBufferGetBaseAddress(imageBuffer);
        size_t offset = NSSwapBigIntToHost(planar->componentInfoY.offset);
        size_t rowBytes = NSSwapBigIntToHost(planar->componentInfoY.rowBytes);
        unsigned char* baseAddress = (unsigned char *)CVPixelBufferGetBaseAddress(imageBuffer);
        unsigned char* pixelAddress = baseAddress + offset;
        
        static unsigned char *buffer = NULL;
        if (buffer == NULL) {
            buffer = (unsigned char *)malloc(sizeof(unsigned char) * width * height);
        }
        
        memcpy(buffer, pixelAddress, sizeof(unsigned char) * width * height);
        
        unsigned char pResult[1024];
        int ret = EXCARDS_RecoIDCardData(buffer, (int)width, (int)height, (int)rowBytes, (int)8, (char*)pResult, sizeof(pResult));
        
        
        if (ret <= 0) {
            NSLog(@"ret=[%d]", ret);
            isSuccess = NO;
        } else {
            NSLog(@"ret=[%d]", ret);
            
            // 播放一下“拍照”的声音，模拟拍照
            AudioServicesPlaySystemSound(1108);
            
            if ([self.session isRunning]) {
                [self.session stopRunning];
            }
            
            char ctype;
            char content[256];
            int xlen;
            int i = 0;
            
            ZHIDCardInfo *iDInfo = [[ZHIDCardInfo alloc] init];
            
            ctype = pResult[i++];
            
            //            iDInfo.type = ctype;
            while(i < ret){
                ctype = pResult[i++];
                for(xlen = 0; i < ret; ++i){
                    if(pResult[i] == ' ') { ++i; break; }
                    content[xlen++] = pResult[i];
                }
                
                content[xlen] = 0;
                
                if(xlen) {
                    NSStringEncoding gbkEncoding = CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingGB_18030_2000);
                    if(ctype == 0x21) {
                        iDInfo.num = [NSString stringWithCString:(char *)content encoding:gbkEncoding];
                    } else if(ctype == 0x22) {
                        iDInfo.name = [NSString stringWithCString:(char *)content encoding:gbkEncoding];
                    } else if(ctype == 0x23) {
                        iDInfo.gender = [NSString stringWithCString:(char *)content encoding:gbkEncoding];
                    } else if(ctype == 0x24) {
                        iDInfo.nation = [NSString stringWithCString:(char *)content encoding:gbkEncoding];
                    } else if(ctype == 0x25) {
                        iDInfo.address = [NSString stringWithCString:(char *)content encoding:gbkEncoding];
                    } else if(ctype == 0x26) {
                        iDInfo.issue = [NSString stringWithCString:(char *)content encoding:gbkEncoding];
                    } else if(ctype == 0x27) {
                        iDInfo.valid = [NSString stringWithCString:(char *)content encoding:gbkEncoding];
                    }
                }
            }
            
            if (iDInfo) {
                // 读取到身份证信息，实例化出IDInfo对象后，截取身份证的有效区域，获取到图像
                NSLog(@"\n姓名：%@\n性别：%@\n民族：%@\n住址：%@\n公民身份证号码：%@\n\n签发机关：%@\n有效期限：%@",iDInfo.name,iDInfo.gender,iDInfo.nation,iDInfo.address,iDInfo.num,iDInfo.issue,iDInfo.valid);
                
                //处理正反面
                if (iDInfo.num && iDInfo.name && iDInfo.gender && iDInfo.nation && iDInfo.address) {
                    iDInfo.idCardType = IDCardTypeFront;
                }else if (iDInfo.issue && iDInfo.valid) {
                    iDInfo.idCardType = IDCardTypeBehind;
                }else{
                    iDInfo.idCardType = IDCardTypeUnknown;
                }
                
                CGRect effectRect = [ZHRectManager getEffectImageRect:CGSizeMake(width, height)];
                CGRect rect = [ZHRectManager getGuideFrame:effectRect];
                
                UIImage *image = [UIImage getImageStream:imageBuffer];
                UIImage *subImage = [UIImage getSubImage:rect inImage:image];
                
                iDInfo.IDImage = subImage;
                
                // 推出IDInfoVC（展示身份证信息的控制器）
                ZHIDCardInfoVC *IDInfoVC = [[ZHIDCardInfoVC alloc] init];
                
                IDInfoVC.idCardInfo = iDInfo;// 身份证信息
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self.navigationController pushViewController:IDInfoVC animated:YES];
                });
            }
            
            isSuccess = YES;
        }
        
        CVPixelBufferUnlockBaseAddress(imageBuffer, 0);
    }
    
    CVBufferRelease(imageBuffer);
    
    return isSuccess;
}



#endif

#pragma mark - alert

- (void)showErrorAlert{
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"提示" message:@"模拟器不能操作 或者 没有摄像头设备" delegate:nil cancelButtonTitle:@"确定" otherButtonTitles:nil];
    [alert show];
}

- (void)showTorchErrorAlert{
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"提示" message:@"您的设备没有闪光设备，不能提供手电筒功能，请检查" delegate:nil cancelButtonTitle:@"确定" otherButtonTitles:nil];
    [alert show];
}

- (void)showCameraAuthorizationDeniedAlert{
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"相机未授权" message:@"请到系统的“设置-隐私-相机”中授权此应用使用您的相机" delegate:nil cancelButtonTitle:@"取消" otherButtonTitles:@"去设置",nil];
    alert.tag = 1000;
    [alert show];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex{
    if (alertView.tag == 1000) {
        if (buttonIndex == 1) {
            // 跳转到该应用的隐私设授权置界面
            [[UIApplication sharedApplication] openURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString]];
        }
    }
}


@end
