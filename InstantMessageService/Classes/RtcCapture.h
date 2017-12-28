//
//  rtcCaptureController.h
//  rtcTest
//
//  Created by 吳永誌 on 2017/8/12.
//  Copyright © 2017年 1111. All rights reserved.
//
#import <UIKit/UIKit.h>
#include <WebRTC/RTCCameraVideoCapturer.h>
#include <WebRTC/RTCVideoFrameBuffer.h>

// Controls the camera. Handles starting the capture, switching cameras etc.
@interface RtcCapture : NSObject

@property(nonatomic, readonly) RTCCameraVideoCapturer *capturer;
- (instancetype)initWithCapturer:(RTCCameraVideoCapturer *)capturer usingFrontCamera:(BOOL)usingFrontCamera;
- (void)startCaptureWithWidth:(int)width height:(int)height;
- (void)stopCapture;
- (void)switchCamera;
+ (RTCVideoFrame*)videoFrameFrom:(UIImage *)image;
+ (CVPixelBufferRef)pixelBufferCopy:(CVPixelBufferRef)target;
@end
