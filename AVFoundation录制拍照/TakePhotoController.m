//
//  TakePhotoController.m
//  AVFoundation录制拍照
//
//  Created by ChenJiangLin on 2020/6/28.
//  Copyright © 2020 LoveToday. All rights reserved.
//

#import "TakePhotoController.h"
#import <AssetsLibrary/AssetsLibrary.h>
#import <AVFoundation/AVFoundation.h>
#import "VFPreviewView.h"

@interface TakePhotoController ()<AVCapturePhotoCaptureDelegate>
//视频队列
@property (strong, nonatomic) dispatch_queue_t videoQueue;
// 捕捉会话
@property (strong, nonatomic) AVCaptureSession *captureSession;
//输入
@property (weak, nonatomic) AVCaptureDeviceInput *activeVideoInput;
@property (strong, nonatomic) AVCapturePhotoOutput *imageOutput;
@property (strong, nonatomic) NSURL *outputURL;
@property (strong, nonatomic) VFPreviewView *previewView;
@end

@implementation TakePhotoController

- (VFPreviewView *)previewView{
    if (_previewView == nil) {
        _previewView = [[VFPreviewView alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    }
    return _previewView;
}

- (BOOL)setupSession:(NSError **)error {

    
    //创建捕捉会话。AVCaptureSession 是捕捉场景的中心枢纽
    self.captureSession = [[AVCaptureSession alloc]init];
    
    /*
     AVCaptureSessionPresetHigh
     AVCaptureSessionPresetMedium
     AVCaptureSessionPresetLow
     AVCaptureSessionPreset640x480
     AVCaptureSessionPreset1280x720
     AVCaptureSessionPresetPhoto
     */
    //设置图像的分辨率
    self.captureSession.sessionPreset = AVCaptureSessionPresetHigh;
    
    //拿到默认视频捕捉设备 iOS系统返回后置摄像头
    AVCaptureDevice *videoDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    
    //将捕捉设备封装成AVCaptureDeviceInput
    //注意：为会话添加捕捉设备，必须将设备封装成AVCaptureDeviceInput对象
    AVCaptureDeviceInput *videoInput = [AVCaptureDeviceInput deviceInputWithDevice:videoDevice error:error];
    
    //判断videoInput是否有效
    if (videoInput)
    {
        //canAddInput：测试是否能被添加到会话中
        if ([self.captureSession canAddInput:videoInput])
        {
            //将videoInput 添加到 captureSession中
            [self.captureSession addInput:videoInput];
            self.activeVideoInput = videoInput;
        }
    }else
    {
        return NO;
    }
    


    //AVCaptureStillImageOutput 实例 从摄像头捕捉图片
    self.imageOutput = [[AVCapturePhotoOutput alloc]init];
    
    //输出连接 判断是否可用，可用则添加到输出连接中去
    if ([self.captureSession canAddOutput:self.imageOutput])
    {
        [self.captureSession addOutput:self.imageOutput];
        
    }
    
    self.videoQueue = dispatch_queue_create("test.VideoQueue", NULL);
    
    return YES;
}


- (void)startSession {

    //检查是否处于运行状态
    if (![self.captureSession isRunning])
    {
        //使用同步调用会损耗一定的时间，则用异步的方式处理
        dispatch_async(self.videoQueue, ^{
            [self.captureSession startRunning];
        });
        
    }
}

- (void)stopSession {
    
    //检查是否处于运行状态
    if ([self.captureSession isRunning])
    {
        //使用异步方式，停止运行
        dispatch_async(self.videoQueue, ^{
            [self.captureSession stopRunning];
        });
    }
    


}

- (void)loadView{
    self.view = self.previewView;
}



- (void)viewDidLoad {
    [super viewDidLoad];
    NSError *error;
    if ([self setupSession:&error]) {
        [(AVCaptureVideoPreviewLayer*)self.previewView.layer setSession:self.captureSession];
        [self startSession];
    }
    
    UIButton *takePhotoButton = [[UIButton alloc] initWithFrame:CGRectMake(0, [[UIScreen mainScreen] bounds].size.height - 100, 60, 60)];
    takePhotoButton.layer.cornerRadius = 30;
    takePhotoButton.layer.masksToBounds = YES;
    CGPoint center = takePhotoButton.center;
    center.x = [[UIScreen mainScreen] bounds].size.width/2.0;
    takePhotoButton.center = center;
    
    takePhotoButton.backgroundColor = [UIColor redColor];
    
    [takePhotoButton addTarget:self action:@selector(takePhotoButtonAction) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:takePhotoButton];
}

- (void)takePhotoButtonAction{
    [self captureStillImage];
}

#pragma mark - Image Capture Methods 拍摄静态图片
/*
    AVCaptureStillImageOutput 是AVCaptureOutput的子类。用于捕捉图片
 */
- (void)captureStillImage {
    
    //获取连接
    AVCaptureConnection *connection = [self.imageOutput connectionWithMediaType:AVMediaTypeVideo];
    
    //程序只支持纵向，但是如果用户横向拍照时，需要调整结果照片的方向
    //判断是否支持设置视频方向
    if (connection.isVideoOrientationSupported) {
        
        //获取方向值
        connection.videoOrientation = [self currentVideoOrientation];
    }
    
    //捕捉图片
    NSDictionary *setDic = @{AVVideoCodecKey:AVVideoCodecJPEG};
    [self.imageOutput capturePhotoWithSettings:[AVCapturePhotoSettings photoSettingsWithFormat:setDic] delegate:self];
    
}

//获取方向值
- (AVCaptureVideoOrientation)currentVideoOrientation {
    
    AVCaptureVideoOrientation orientation;
    
    //获取UIDevice 的 orientation
    switch ([UIDevice currentDevice].orientation) {
        case UIDeviceOrientationPortrait:
            orientation = AVCaptureVideoOrientationPortrait;
            break;
        case UIDeviceOrientationLandscapeRight:
            orientation = AVCaptureVideoOrientationLandscapeLeft;
            break;
        case UIDeviceOrientationPortraitUpsideDown:
            orientation = AVCaptureVideoOrientationPortraitUpsideDown;
            break;
        default:
            orientation = AVCaptureVideoOrientationLandscapeRight;
            break;
    }
    
    return orientation;

    return 0;
}

/*
    Assets Library 框架
 */

- (void)writeImageToAssetsLibrary:(UIImage *)image {

    //创建ALAssetsLibrary  实例
    ALAssetsLibrary *library = [[ALAssetsLibrary alloc]init];
    
    //参数1:图片（参数为CGImageRef 所以image.CGImage）
    //参数2:方向参数 转为NSUInteger
    //参数3:写入成功、失败处理
    [library writeImageToSavedPhotosAlbum:image.CGImage
                             orientation:(NSUInteger)image.imageOrientation
                         completionBlock:^(NSURL *assetURL, NSError *error) {
                             //成功后，发送捕捉图片通知。用于绘制程序的左下角的缩略图
                             if (!error)
                             {
                                 [self postThumbnailNotifification:image];
                             }else
                             {
                                 //失败打印错误信息
                                 id message = [error localizedDescription];
                                 NSLog(@"%@",message);
                             }
                         }];
}

//发送缩略图通知
- (void)postThumbnailNotifification:(UIImage *)image {
    
    
}


- (void)captureOutput:(AVCapturePhotoOutput *)captureOutput didFinishProcessingPhotoSampleBuffer:(nullable CMSampleBufferRef)photoSampleBuffer previewPhotoSampleBuffer:(nullable CMSampleBufferRef)previewPhotoSampleBuffer resolvedSettings:(AVCaptureResolvedPhotoSettings *)resolvedSettings bracketSettings:(nullable AVCaptureBracketedStillImageSettings *)bracketSettings error:(nullable NSError *)error {
    
    NSData *data = [AVCapturePhotoOutput JPEGPhotoDataRepresentationForJPEGSampleBuffer:photoSampleBuffer previewPhotoSampleBuffer:previewPhotoSampleBuffer];
    UIImage *image = [UIImage imageWithData:data];
    
    [self writeImageToAssetsLibrary:image];
}





@end
