//
//  RtcView.swift
//  InstantMessageService
//
//  Created by 吳永誌 on 2017/12/24.
//
import WebRTC

class RtcView : UIView {
    var _eglView:UIView?
    var _logoView:UIImageView?
    var _logoImg:UIImage?
    var _logoTitle:UILabel?
    
    /*
     - (instancetype)initWithFrame:(CGRect)frame {
         if (self = [super initWithFrame:frame]) {
             //video
             _videoView = _eglView = [[RTCEAGLVideoView alloc] initWithFrame:CGRectZero];
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
     */
    
    func start() {
        //video
        _eglView = RTCEAGLVideoView.init(frame: CGRect.zero) as? UIView
        _eglView!.isHidden = true
        self.addSubview(_eglView!)
        
        
    }
}

extension RtcView : RTCVideoRenderer {
    func setSize(_ size: CGSize) {
    }
    
    func renderFrame(_ frame: RTCVideoFrame?) {
    }
}
