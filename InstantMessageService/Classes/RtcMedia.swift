//
//  RtcMedia.swift
//  InstantMessageService
//
//  Created by 吳永誌 on 2017/12/24.
//
import WebRTC

public class RtcMedia : NSObject {
    final var _factory:RTCPeerConnectionFactory?
    final var _capture:RtcCapture?
    final var _videoSource:RTCVideoSource?
    final var _audioSource:RTCAudioSource?
    var _videoTrack:RTCVideoTrack?
    var _audioTrack:RTCAudioTrack?
    var _isStartCapture:Bool = false
    
    var audioTrack:RTCAudioTrack {
        get {
            if(_audioTrack == nil) {
                _audioTrack = _factory!.audioTrack(with: _audioSource!, trackId: "\(UUID.init().uuidString)")
            }
            return _audioTrack!
        }
    }
    
    var videoTrack:RTCVideoTrack {
        get {
            if(_videoTrack == nil) {
                _videoTrack = _factory!.videoTrack(with: _videoSource!, trackId: "\(UUID.init().uuidString)")
            }
            return _videoTrack!
        }
    }
    
    init(factory:RTCPeerConnectionFactory) {
        super.init()
        _factory = factory
        _videoSource = _factory!.videoSource()
        _audioSource = _factory!.audioSource(with: RTCMediaConstraints.init(mandatoryConstraints: [:], optionalConstraints: [:]))
        
        if let capture = RtcCapture.init(capturer: RTCCameraVideoCapturer.init(delegate: _videoSource!), usingFrontCamera: true) {
            _capture = capture
        }
    }
    
    deinit {
        self.clearLocalStream()
    }
    
    public func clearLocalStream() -> Void {
        self.stopCapture()
        _videoTrack = nil
        _audioTrack = nil
    }
    
    /// 開啟或關閉音訊
    public func audio(enabled:Bool) -> Void {
         guard _audioTrack != nil else { return }
        _audioTrack!.isEnabled = enabled
    }
    
    /// 開啟或關閉視訊
    public func video(enabled:Bool) -> Void {
        guard _videoTrack != nil else { return }
        _videoTrack!.isEnabled = enabled
    }
    
    ///
    public func startCapture(videoWidth:Int32, videoHeight:Int32) -> Void {
        utility.synchronized(lock: self) {
            guard _capture != nil && !_isStartCapture else { return }
            _capture!.start(withWidth: videoWidth, height: videoHeight)
            _isStartCapture = true
        }
    }
    
    ///
    public func stopCapture() -> Void {
        utility.synchronized(lock: self) {
            guard _capture != nil && _isStartCapture else { return }
            _capture!.stop()
            _isStartCapture = false
        }
    }
    
    ///
    public func switchCamera() -> Void {
        utility.synchronized(lock: self) {
            guard _capture != nil else { return }
            _capture!.switchCamera()
        }
    }
}
