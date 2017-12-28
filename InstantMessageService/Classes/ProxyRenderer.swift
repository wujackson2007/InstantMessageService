//
//  ProxyRenderer.swift
//  AFNetworking
//
//  Created by wujackson on 2017/12/25.
//
import WebRTC

class ProxyRenderer : NSObject, RTCVideoRenderer {
    private var _target:RTCVideoRenderer?
    private var _track:RTCVideoTrack?
    
    func set(track:RTCVideoTrack?) -> Void {
        utility.synchronized(lock: self) {
            if(_track != nil) {
                _track!.remove(_:self)
            }
            
            _track = track
            if(_track != nil) {
                _track!.add(_:self)
            }
        }
    }
    
    func set(target:RTCVideoRenderer?) -> Void {
        utility.synchronized(lock: self) {
            _target = target
        }
    }
    
    /** The size of the frame. */
    @objc func setSize(_ size:CGSize) -> Void {
        utility.synchronized(lock: self) {
            guard _target != nil else { return }
            _target!.setSize(size)
        }
    }
    
    /** The frame to be displayed. */
    @objc func renderFrame(_ frame:RTCVideoFrame?) -> Void {
        utility.synchronized(lock: self) {
            guard _target != nil else { return }
            _target!.renderFrame(frame)
        }
    }
}


