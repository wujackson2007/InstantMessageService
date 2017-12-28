//
//  RtcView.m
//  rtcTest
//
//  Created by 吳永誌 on 2017/8/12.
//  Copyright © 2017年 1111. All rights reserved.
//
#import "RtcView.h"

@implementation RtcView {
    UIView<RTCVideoRenderer> *_videoView;
    RTCMTLVideoView *_mtlView;
    RTCEAGLVideoView *_eglView;
    UIImageView *_logoView;
    UIImage *_logoImg;
    UILabel *_logoTitle;
}

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        /*
#if defined(RTC_SUPPORTS_METAL)
        _videoView = _mtlView = [[RTCMTLVideoView alloc] initWithFrame:CGRectZero];
#else
        _videoView = _eglView = [[RTCEAGLVideoView alloc] initWithFrame:CGRectZero];
        _eglView.delegate = self;
#endif
         */
        
        //video
        _videoView = _eglView = [[RTCEAGLVideoView alloc] initWithFrame:frame];
        [_videoView setHidden:TRUE];
        [self addSubview:_videoView];
        
        //logo image
        _logoView = [[UIImageView alloc] initWithFrame:CGRectZero];
        [self addSubview:_logoView];
        
        //title
        _logoTitle = [[UILabel alloc] initWithFrame:CGRectZero];
        [_logoTitle setTextColor:[UIColor whiteColor]];
        [_logoTitle setBackgroundColor:[UIColor blueColor]];
        [_logoTitle setFont:[UIFont systemFontOfSize:20]];
        [_logoTitle setTextAlignment:NSTextAlignmentCenter];
        [_logoTitle setAlpha:0.7];
        [self addSubview:_logoTitle];
        
        //[self setBackgroundColor:[UIColor whiteColor]];
    }
    return self;
}

- (void) setFrame:(CGRect)frame
{
    // Call the parent class to move the view
    [super setFrame:frame];
    
    //video view
    _videoView.frame = frame;
    
    if(_logoImg != nil) {
        // Do your custom code here.
        CGRect bounds = frame;
        CGRect _size;
        
        //logo title
        [_logoTitle setFrame:CGRectMake(0, frame.size.height-40, frame.size.width, 40)];
        
        //logo image
        _size = [self resizeFrame:bounds target:_logoImg.size];
        [_logoView setFrame:CGRectInset(_size, 10.0f, 10.0f)];
        [_logoView setCenter:CGPointMake(CGRectGetMidX(bounds), CGRectGetMidY(bounds))];
    }
}

- (CGRect)resizeFrame:(CGRect)src target:(CGSize)dsc {
    CGRect o_val = AVMakeRectWithAspectRatioInsideRect(dsc, src);
    
    CGFloat ratioX = src.size.width / dsc.width;
    CGFloat ratioY = src.size.height / dsc.height;
    
    CGFloat ratio = MIN(ratioX, ratioY);
    if(ratio == 0)
        ratio = MAX(ratioX, ratioY);
    
    o_val.size.width = dsc.width * ratio;
    o_val.size.height = dsc.height * ratio;
    
    return o_val;
}

- (void)setLogo:(UIImage *)image title:(NSString *)title {
    _logoImg = image;
    [_logoView setImage:image];
    [_logoTitle setText:title];
}

- (void)showVideo:(BOOL)isShow {
    [_videoView setHidden:!isShow];
    
    if(isShow) {
        [_logoView setHidden:TRUE];
    } else {
        [_logoView setHidden:FALSE];
    }
}

- (void)layoutSubviews {
    [super layoutSubviews];
    //CGRectMake(0, 0, 100, 100)
}

#pragma mark - RTCVideoRenderer
- (void)setSize:(CGSize)size {
    [_videoView setSize:size];
    
    /*
    dispatch_async(dispatch_get_main_queue(), ^{
        [self resizeVideoView:size];
    });
    */
}

- (void)renderFrame:(nullable RTCVideoFrame *)frame {
    [_videoView renderFrame:frame];
}
@end
