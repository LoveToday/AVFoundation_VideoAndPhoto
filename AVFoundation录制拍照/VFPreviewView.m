//
//  VFPreviewView.m
//  AVFoundation录制拍照
//
//  Created by ChenJiangLin on 2020/6/28.
//  Copyright © 2020 LoveToday. All rights reserved.
//

#import "VFPreviewView.h"
#import <AVFoundation/AVFoundation.h>

@implementation VFPreviewView

+ (Class)layerClass{
    return [AVCaptureVideoPreviewLayer class];
}



@end
