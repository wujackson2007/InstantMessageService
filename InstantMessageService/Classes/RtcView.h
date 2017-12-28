//
//  rtcView.h
//  rtcTest
//
//  Created by 吳永誌 on 2017/8/12.
//  Copyright © 2017年 1111. All rights reserved.
//
#import <UIKit/UIKit.h>
@import WebRTC;

@interface RtcView : UIView<RTCVideoRenderer>
@property(nonatomic, readonly) CVPixelBufferRef pixelBuffer;
- (void)setLogo:(UIImage *)image title:(NSString *)title;
- (void)showVideo:(BOOL)isShow;
@end
