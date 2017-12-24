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
    final var _delegates:Dictionary<String, IMServiceDelegate> = [:]
    final var _promiseConnected:Array<() -> Void> = []
    final var _roomInfo:RoomInfo = RoomInfo()
    var _isServiceStart:Bool = false
    var _isSignConnected:Bool = false
    var _isIceConnected:Bool = false
    
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
    
    public func setDelegate(key:String, delegate:IMServiceDelegate) -> Void {
        guard _delegates[key] == nil else { return }
        _delegates[key] = delegate
    }
    
    public func rmDelegate(key:String) -> Void {
        guard _delegates[key] != nil else { return }
        _delegates.removeValue(forKey: key)
    }
    
    /// 服務啟動
    public func start(hubName:String, url:String, queryString:Dictionary<String,String>) -> Void {
        guard !_isServiceStart else { return }
        _isServiceStart = true
        _signHandler?.start(hubName: hubName, url: url, queryString: queryString)
    }
    
    /// 服務停止
    public func stop() -> Void {
        guard _isServiceStart else { return }
        _signHandler?.stop()
        _isServiceStart = false
    }
    
    public func notifyUser() -> Void {
        signInvoke(method: "notifyUser", withArgs: [roomData.userType == "1" ? 2 : 1
            , roomData.tNo
            , roomData.oNo
            , roomData.eNo
            , roomData.uNo
            , roomData.eName])
    }
    
    /// 傳送訊息
    public func sendMessage(type:String, message:String? = "") {
        guard (_roomInfo.oNo != "" && _roomInfo.tNo != "" && _roomInfo.uNo != "" && _roomInfo.eNo != "") else { return }
        
        var talkJson:String = ""
        let fileJson:String = ""
        var timeStart:String = ""
        var timeEnd:String = ""
        var _message:String = message!
        var _isSend = false
        
        switch type {
        case "0":
            guard (_message != "") else { return }
            _isSend = true
            break
            
        case "1", "2":
            // Ex: {"start":"2017/01/01 11:11:11","end":"2017/01/01 11:11:31","duringTime":20}
            if(_roomInfo.pickupTime > 0 && _roomInfo.hungUpTime > 0) {
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
                timeStart = dateFormatter.string(from: Date.init(timeIntervalSince1970: _roomInfo.pickupTime))
                timeEnd = dateFormatter.string(from: Date.init(timeIntervalSince1970: _roomInfo.hungUpTime))
            }
            else {
                _message = "取消"
            }
            
            talkJson = "{\"start\":\"\(timeStart)\",\"end\":\"\(timeEnd))\",\"duringTime\":0}"
            _isSend = true
            break
            
        default:
            break
        }
        
        guard (_isSend) else { return }
        signInvoke(method: "sendMsgLog", withArgs: [_message,
                                                    type,
                                                    _roomInfo.oNo,
                                                    _roomInfo.tNo,
                                                    _roomInfo.uNo,
                                                    _roomInfo.eNo,
                                                    talkJson,
                                                    fileJson])
    }
    
    ///
    public func signInvoke(method: String!, withArgs args: [Any]!) -> Void {
        _signHandler!.invoke(method, withArgs: args)
    }
    
    func invokeDelegate(name:String, args:Array<Any>) -> Void {
        for (_, owner) in _delegates {
            switch name {
            case "onImMessage":
                if(owner.onImMessage != nil) {
                    owner.onImMessage!(sender: self, type: args[0] as! String, message: args[1] as! String)
                }
                break
                
            case "onImPhoneAction":
                if(owner.onImPhoneAction != nil) {
                    owner.onImPhoneAction!(sender: self, isVideo:args[0] as! Bool, action:args[1] as! String)
                }
                break
                
            case "onImPhoneShow":
                if(owner.onImPhoneShow != nil) {
                    owner.onImPhoneShow!(sender: self, isDial: args[0] as! Bool, isVideo: args[1] as! Bool)
                }
                break
                
            default:
                break
            }
        }
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
    
    /**
     電話處理.
     
     - Parameter isVideo: 是否為影像電話.
     - Parameter action:
        dial = 撥出, show = 來電, pickup = 接聽, hangup = 掛斷, changevideo = 切換為視訊).
     */
    public func doCallPhone(isVideo:Bool, action:String) -> Void {
        let isDial = action == "dial" ? true : false
        let arg0:String = isVideo ? "doVideoCall" : "doPhoneCall";
        let arg1:String = roomData.roomId
        let arg2:String = "{\"act\":\"\(action)\"}";
        let _fn = {
            self.phoneViewOpen(isDial: isDial, isVideo: isVideo)
            if(isDial) {
                self.signInvoke(method: arg0, withArgs: [arg1, arg2])
            }
        }
        
        switch (action) {
        case "dial", "show":
            if(_isIceConnected) {
                _fn()
            } else {
                _promiseConnected.append({
                    _fn()
                })
                
                notifyUser()
            }
            break
            
        default:
            signInvoke(method: arg0, withArgs: [arg1, arg2])
            break
        }
    }
    
    func phoneViewOpen(isDial:Bool, isVideo:Bool) {
        roomData.setInfo(msgType: isVideo ? "2" : "1", pickupTime: 0.0, hungUpTime: 0.0, isDial: isDial)
        invokeDelegate(name: "onImPhoneShow", args: [isDial, isVideo])
    }
}
/** ==============================================================================================
 * Protocol
 ============================================================================================== */
@objc public protocol IMServiceDelegate : NSObjectProtocol {
    /// 取得訊息
    @objc optional func onImMessage(sender:IMService, type:String, message:String)
 
    /// 收到電話訊號觸發
    @objc optional func onImPhoneShow(sender:IMService, isDial:Bool, isVideo:Bool)
    
    /// 收到電話訊號觸發
    @objc optional func onImPhoneAction(sender:IMService, isVideo:Bool, action:String)
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
            guard ("\(_roomInfo.tNo)_\(_roomInfo.oNo)_\(_roomInfo.uNo)_\(_roomInfo.eNo)" == "\(args[1])_\(args[2])_\(args[3])_\(args[4])") else { return }
            invokeDelegate(name: "onImMessage", args: ["0", args[5]])
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
            switch(args[0]) {
            case "dial":
                break
            case "show":
                break
            case "pickup":
                roomData.setInfo(pickupTime: Date.init().timeIntervalSince1970)
                break
            case "hangup":
                if(roomData.pickupTime > 0) {
                    roomData.setInfo(hungUpTime: Date.init().timeIntervalSince1970)
                }
                
                //撥號方須傳送撥號資訊
                if(roomData.isDial) {
                    sendMessage(type: roomData.msgType)
                }
                break
            case "changevideo":
                break
            default:
                break
            }
            invokeDelegate(name: "onImPhoneAction", args: [eventName == "onVideoCall" ? true : false , args[0]])
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
            let _size = self._promiseConnected.count-1
            if(_size > -1) {
                for _ in 0..._size {
                    self._promiseConnected.remove(at: 0)()
                }
            }
            break
            
        default:
            _isIceConnected = false
            break
        }
    }
    
    /// Candidate 新增或移除會觸發
    func onRtcCandidate(sender:RtcHandler, type:String, candidate:RTCIceCandidate) {
        if(type == "add") {
            var _candidate = Dictionary<String, String>()
            _candidate["candidate"] = candidate.sdp
            _candidate["sdpMid"] = candidate.sdpMid
            _candidate["sdpMid"] = "\(candidate.sdpMLineIndex)"
            guard let _json = utility.convertToJson(of: ["candidate":_candidate]) else { return }
            signInvoke(method: "rtcSend", withArgs: [sender.connectionId, _json])
        }
    }
}
