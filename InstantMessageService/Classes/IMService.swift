//
//  InstantMessageService.swift
//  eChat
//
//  Created by wujackson on 2017/12/20.
//  Copyright © 2017年 wujackson. All rights reserved.
//

import WebRTC

public class IMService : NSObject {
    var _factory:RTCPeerConnectionFactory?
    var _signHandler:SignHandler?
    final var _rtcHandlers:Dictionary<String, RtcHandler> = [:]
    var _isServiceStart:Bool = false
    var _isSignConnected:Bool = false
    var _isIceConnected:Bool = false
    var _roomInfo:RoomInfo = RoomInfo()
    
    /// 回傳聊天室資料
    public var roomData:RoomInfo {
        get {
            return _roomInfo
        }
    }
    
    public override init() {
        super.init()
        _factory = RtcHandler.factory
        _signHandler = SignHandler.init(delegate: self)
    }
    
    deinit {
        stop()
    }
    
    ///服務啟動
    func start(hubName:String, url:String, queryString:Dictionary<String,String>) -> Void {
        guard !_isServiceStart else { return }
        _signHandler?.start(hubName: hubName, url: url, queryString: queryString)
        _isServiceStart = true
    }
    
    ///服務停止
    func stop() -> Void {
        guard _isServiceStart else { return }
        _signHandler?.stop()
        _isServiceStart = false
    }
    
    ///
    func signInvoke(method: String!, withArgs args: [Any]!) -> Void {
        _signHandler!.invoke(method, withArgs: args)
    }
    
    ///
    func getRtcHandler(id:Any?, fn:((RtcHandler) -> Void)? = nil) -> Void {
        var _rtcHandler:RtcHandler?
        let _id = (id as AnyObject).description ?? ""
        if(_rtcHandlers.keys.contains(_id)) {
            _rtcHandler = _rtcHandlers[_id]
        }
        else {
            _rtcHandler = RtcHandler.init(factory: self._factory!, delegate: self, connectionId: _id)
            _rtcHandlers[_id] = _rtcHandler
        }
        
        if(_rtcHandler != nil && fn != nil) {
            fn!(_rtcHandler!)
        }
    }
}
/** ==============================================================================================
 * signHandlerDelegate
 ============================================================================================== */
extension IMService : SignHandlerDelegate {
    ///訊號連線觸發
    func onSignConnected(sender:SignHandler) {
        _isSignConnected = true
        
        // 回傳使用者名稱
        let _userName = _roomInfo.userType == "1" ? _roomInfo.tName : _roomInfo.oName
        sender.invoke("settUser", withArgs: [_userName])
    }
    
    ///訊號離線觸發
    func onSignDisconnected(sender:SignHandler) {
        _isSignConnected = false
    }
    
    ///收到消息觸發
    func onSignReceived(sender:SignHandler, eventName:String, args:Array<String>) {
        switch eventName {
        case "onTextMessage":
            break
            
        case "onNotifyUser":
            //function(id, tNo, oNo, uNo, eNo, empName)
            if(_roomInfo.tNo == args[1] && _roomInfo.eNo == args[4] && _roomInfo.uNo == args[3]) {
                _roomInfo.setInfo(cid:args[0])
                sender.invoke("doRTCConnection", withArgs:[args[0]])
            }
            break
            
        case "onRTCConnecting":
            //等RTC連線後傳送 doRTCConnected 訊號
            getRtcHandler(id:args[0], fn: { (_rtcHandler) in
                _rtcHandler.createOffer(onConnected: { (_rtcHandler) in
                    sender.invoke("doRTCConnected", withArgs:[args[1]]);
                })
            })
            break
            
        case "onRTCMessage": //收到 RTC 協議訊息
            getRtcHandler(id:args[0], fn: { (_rtcHandler) in
                if let _dic = args[1].parseJson() {
                    if let _candidate = _dic["candidate"] as? Dictionary<String, AnyObject> {
                        _rtcHandler.add(candidate: _candidate)
                    }
                    else if let _sdp = _dic["sdp"] as? Dictionary<String, AnyObject> {
                        _rtcHandler.add(sdp: _sdp)
                    }
                }
            })
            break
            
        case "onTalkLeave":
            if let _handler = _rtcHandlers.removeValue(forKey: args[0]) {
                _handler.dispose()
            }
            break
            
        case "onPhoneCall", "onVideoCall":
            break
            
        default:
            break
        }
    }
}
/** ==============================================================================================
 * rtcHandlerDelegate
 ============================================================================================== */
extension IMService : RtcHandlerDelegate {
    ///設定 sdp 後會觸發
    func onRtcDescription(sender:RtcHandler, type:String, sdp:RTCSessionDescription) {
        if(type == "local") {
            var _sdp = Dictionary<String, String>()
            _sdp["sdp"] = sdp.sdp
            _sdp["type"] = RTCSessionDescription.string(for: sdp.type)
            guard let _json = utility.convertToJson(of: ["sdp":_sdp]) else { return }
            signInvoke(method: "rtcSend", withArgs: [sender.connectionId, _json])
        }
        else {
            if(sdp.type == RTCSdpType.offer) {
                sender.createAnswer()
            }
        }
    }
    
    ///遠端 stream 新增或移除會觸發
    func onRtcStream(sender:RtcHandler, type:String, stream:RTCMediaStream) {
    }
    
    ///ice 連接狀態改變會觸發
    func onRtcIceConnectionChange(sender:RtcHandler, newState:RTCIceConnectionState) {
        switch newState {
        case RTCIceConnectionState.connected, RTCIceConnectionState.completed:
            _isIceConnected = true
            break
            
        default:
            _isIceConnected = false
            break
        }
    }
}
