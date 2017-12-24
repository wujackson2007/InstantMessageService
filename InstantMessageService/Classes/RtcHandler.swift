//
//  rtcHelpers.swift
//  eChat
//
//  Created by wujackson on 2017/10/13.
//  Copyright © 2017年 wujackson. All rights reserved.
//
import WebRTC

class RtcHandler : NSObject {
    private var _factory:RTCPeerConnectionFactory?
    private var _connection:RTCPeerConnection?
    private var _connectionId:String = ""
    private final var _remoteCandidates:Array<RTCIceCandidate> = []
    final var _promiseConnected:Array<(RtcHandler)->Void> = []
    var _delegate:RtcHandlerDelegate?

    private var connectLogId : String {
        get { return _connectionId }
    }
    
    private var connection:RTCPeerConnection {
        get { return _connection! }
    }
    
    var connectionId : String {
        get { return _connectionId }
    }
    
    deinit {
        dispose()
    }
    
    init(factory:RTCPeerConnectionFactory, delegate:RtcHandlerDelegate, connectionId:String) {
        super.init()
        _factory = factory
        _delegate = delegate
        _connectionId = connectionId
        
        let rtcConfig = RTCConfiguration.init()
        rtcConfig.iceServers.append(RTCIceServer(urlStrings: ["stun:stun.l.google.com:19302"]))
        rtcConfig.iceServers.append(RTCIceServer(urlStrings: ["turn:stun.1111.com.tw:80"], username: "stun", credential: "1111"))
        
        /*
        _connection = rtcHandler.factory.peerConnection(with: rtcConfig
            , constraints: RTCMediaConstraints.init(mandatoryConstraints: nil, optionalConstraints: ["DtlsSrtpKeyAgreement" : "true"])
            , delegate: self)*/
        
        _connection = _factory!.peerConnection(with: rtcConfig
            , constraints: RTCMediaConstraints.init(mandatoryConstraints: nil, optionalConstraints: [:])
            , delegate: self)
    }
    
    func dispose() -> Void {
        connection.close()
    }
    
    ///新增遠端 ice candidate
    func add(candidate:Dictionary<String, Any>) -> Void {
        let _sdp = candidate["candidate"] as? String ?? ""
        let _sdpMid = candidate["sdpMid"] as? String ?? ""
        let _sdpMLineIndex = Int32(candidate["sdpMLineIndex"] as? String ?? "") ?? 0
        if(_sdp != "" && _sdpMid != "" ) {
            let _candidate:RTCIceCandidate = RTCIceCandidate.init(sdp: _sdp, sdpMLineIndex: _sdpMLineIndex, sdpMid: _sdpMid)
            if(connection.remoteDescription != nil) {
                connection.add(_candidate)
                print("=== [\(connectLogId)] addRemoteIceCandidate:\(_candidate) ===\r\n")
            }
            else {
                _remoteCandidates.append(_candidate)
            }
        }
    }
    
    ///新增遠端 sdp
    func add(sdp:Dictionary<String, Any>) -> Void {
        let _sdp = sdp["sdp"] as? String ?? ""
        let _type = sdp["type"] as? String ?? ""
        if(_sdp != "" && _type != "" ) {
            let remoteDesc:RTCSessionDescription = RTCSessionDescription.init(type: RTCSessionDescription.type(for: _type), sdp: _sdp)
            self.connection.setRemoteDescription(remoteDesc, completionHandler: { (error:Error?) in
                if(error == nil) {
                    let _size = self._remoteCandidates.count-1
                    if(_size > -1) {
                        for _ in 0..._size {
                            let _candidate:RTCIceCandidate = self._remoteCandidates.remove(at: 0)
                            self.connection.add(_candidate)
                            print("=== [\(self.connectLogId)] addRemoteIceCandidate:\(_candidate) ===\r\n")
                        }
                    }
                    
                    if(self._delegate != nil) {
                        self._delegate!.onRtcDescription(sender:self, type:"remote", sdp:remoteDesc)
                    }
                }
            })
        }
    }
    
    func createOffer(option:Dictionary<String,String>? = nil, onConnected:((RtcHandler)->Void)?) -> Void {
        self.createLocalDescription(type: "offer", option: option, onConnected: onConnected)
    }
    
    func createAnswer(option:Dictionary<String,String>? = nil) -> Void {
        self.createLocalDescription(type: "answer", option: option, onConnected: nil)
    }
    
    private func createLocalDescription(type:String
        , option:Dictionary<String,String>? = ["OfferToReceiveAudio" : "true", "OfferToReceiveVideo" : "true"]
        , onConnected:((RtcHandler)->Void)? = nil) {
        
        if(onConnected != nil) {
            self._promiseConnected.append(onConnected!)
        }
        
        let defaultOfferConstraints = RTCMediaConstraints.init(mandatoryConstraints: option, optionalConstraints: nil)
        let _fn = { (desc:RTCSessionDescription?, error:Error?) in
            guard (error == nil) else { return }
            self.connection.setLocalDescription(desc!, completionHandler: { (error:Error?) in
                guard (error == nil) else { return }
                if(self._delegate != nil) {
                    self._delegate!.onRtcDescription(sender:self, type:"local", sdp:desc!)
                }
            })
        }
        
        if(type == "offer") {
            self.connection.offer(for: defaultOfferConstraints, completionHandler:_fn)
        }
        else {
            self.connection.answer(for: defaultOfferConstraints, completionHandler:_fn)
        }
    }
}

/** ==============================================================================================
 * Protocol
 ============================================================================================== */
protocol RtcHandlerDelegate : NSObjectProtocol {
    /// 設定 sdp 後會觸發
    func onRtcDescription(sender:RtcHandler, type:String, sdp:RTCSessionDescription)
    /// 遠端 stream 新增或移除會觸發
    func onRtcStream(sender:RtcHandler, type:String, stream:RTCMediaStream)
    /// ice 連接狀態改變會觸發
    func onRtcIceConnectionChange(sender:RtcHandler, newState:RTCIceConnectionState)
    /// Candidate 新增或移除會觸發
    func onRtcCandidate(sender:RtcHandler, type:String, candidate:RTCIceCandidate)
}

//pragma mark - RTCPeerConnectionDelegate
extension RtcHandler : RTCPeerConnectionDelegate {
    @objc func peerConnectionShouldNegotiate(_ peerConnection: RTCPeerConnection) {}
    @objc func peerConnection(_ peerConnection: RTCPeerConnection, didOpen dataChannel: RTCDataChannel) {}
    @objc func peerConnection(_ peerConnection: RTCPeerConnection, didChange newState: RTCIceGatheringState) {}
    @objc func peerConnection(_ peerConnection: RTCPeerConnection, didChange stateChanged: RTCSignalingState) {}
    @objc func peerConnection(_ peerConnection: RTCPeerConnection, didRemove candidates: [RTCIceCandidate]) {}
    @objc func peerConnection(_ peerConnection: RTCPeerConnection, didGenerate candidate: RTCIceCandidate) {
        if(_delegate != nil) {
            _delegate!.onRtcCandidate(sender:self, type:"add", candidate:candidate)
        }
    }
    
    @objc func peerConnection(_ peerConnection: RTCPeerConnection, didAdd stream: RTCMediaStream) {
        if(_delegate != nil) {
            _delegate!.onRtcStream(sender:self, type:"add", stream:stream)
        }
    }
    
    @objc func peerConnection(_ peerConnection: RTCPeerConnection, didRemove stream: RTCMediaStream) {
        if(_delegate != nil) {
            _delegate!.onRtcStream(sender:self, type:"remove", stream:stream)
        }
    }
    
    @objc func peerConnection(_ peerConnection: RTCPeerConnection, didChange newState: RTCIceConnectionState) {
        switch newState {
        case RTCIceConnectionState.connected, RTCIceConnectionState.completed:
            let _size = self._promiseConnected.count-1
            if(_size > -1) {
                for _ in 0..._size {
                    self._promiseConnected.remove(at: 0)(self)
                }
            }
            break
            
        default:
            break
        }
        
        if(_delegate != nil) {
            _delegate!.onRtcIceConnectionChange(sender:self, newState:newState)
        }
    }
}

extension RtcHandler {
    static var factory:RTCPeerConnectionFactory {
        get { return RTCPeerConnectionFactory.init() }
    }
}
