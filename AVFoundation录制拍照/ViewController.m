//
//  ViewController.m
//  AVFoundation录制拍照
//
//  Created by ChenJiangLin on 2020/6/28.
//  Copyright © 2020 LoveToday. All rights reserved.
//

#import "ViewController.h"

#import "TakePhotoController.h"
#import "TakeVideoController.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

/// 拍照
- (IBAction)takePhotoAction:(id)sender {
    TakePhotoController *photoController = [[TakePhotoController alloc] init];
    [self presentViewController:photoController animated:YES completion:nil];
    
}
///  录制
- (IBAction)takeVideoAction:(id)sender {
    TakeVideoController *videoController = [[TakeVideoController alloc] init];
    [self presentViewController:videoController animated:YES completion:nil];
}


@end
