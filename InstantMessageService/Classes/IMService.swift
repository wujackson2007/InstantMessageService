//
//  InstantMessageService.swift
//  eChat
//
//  Created by wujackson on 2017/12/20.
//  Copyright © 2017年 wujackson. All rights reserved.
//
import UIKit
import WebRTC

public class IMService : NSObject {
    final var _factory:RTCPeerConnectionFactory?
    final var _signHandler:SignHandler?
    final var _rtcMedia:RtcMedia?
    final var _rtcHandlers:Dictionary<String, RtcHandler> = [:]
    final var _delegates:Dictionary<String, IMServiceDelegate> = [:]
    final var _promiseSignConnected:Array<() -> Void> = []
    final var _promiseRtcConnected:Array<() -> Void> = []
    final var _roomInfo:RoomInfo = RoomInfo()
    final var _localProxy:ProxyRenderer = ProxyRenderer()
    final var _remoteProxy:ProxyRenderer = ProxyRenderer()
    
    public var rtcMedia:RtcMedia { get { return _rtcMedia! } }
    var _isServiceStart:Bool = false
    var _isSignConnected:Bool = false
    var _isIceConnected:Bool = false
    
    /// 服務是否啟動
    public var isServiceStart:Bool { get { return _isServiceStart } }
    
    /// 訊號是否已連線
    public var isSignConnected:Bool { get { return _isSignConnected } }
    
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
        _rtcMedia = RtcMedia.init(factory:_factory!)
        
        //使用手動控制
        let session:RTCAudioSession = RTCAudioSession.sharedInstance()
        session.useManualAudio = true
        session.isAudioEnabled = false
    }
    
    deinit {
        _localProxy.set(target:nil)
        _remoteProxy.set(target:nil)
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
    public func start(hubName:String, url:String, queryString:Dictionary<String,String>, onStart:(() -> Void)? = nil) -> Void {
        if(onStart != nil) {
            if(_isSignConnected) {
                onStart!()
            }
            else {
                _promiseSignConnected.append(onStart!)
            }
        }
        
        guard !_isServiceStart else { return }
        _isServiceStart = true
        _signHandler!.start(hubName: hubName, url: url, queryString: queryString)
    }
    
    /// 服務停止
    public func stop() -> Void {
        guard _isServiceStart else { return }
        _signHandler!.stop()
        _isServiceStart = false
        
        //清除RTC連線
        for(_, val) in _rtcHandlers {
            val.dispose()
        }
        _rtcHandlers.removeAll()
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
            invokeDelegate(name: "onImMessage", args: [type, self.getUserMsgLog(msgType: type, msg: _message, whoTalk: "1")])
            break
            
        case "1", "2":
            // Ex: {"start":"2017/01/01 11:11:11","end":"2017/01/01 11:11:31","duringTime":20}
            if(_roomInfo.phonePickupTime > 0 && _roomInfo.phoneHungUpTime > 0) {
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
                timeStart = dateFormatter.string(from: Date.init(timestamp: _roomInfo.phonePickupTime))
                timeEnd = dateFormatter.string(from: Date.init(timestamp: _roomInfo.phoneHungUpTime))
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
    
    /// 產生使用者介面顯示訊息
    func getUserMsgLog(msgType:String, msg:String, whoTalk:String? = "0", duringTime:Int? = 0) -> String {
        var o_val = ""
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        if let jsonData = utility.convertToJson(of: ["msgType": Int(msgType)!
            , "whoTalk": Int(whoTalk!)!
            , "msgLog":msg
            , "dateIn":dateFormatter.string(from: Date.init())
            , "duringTime":duringTime!])
        {
            o_val = jsonData
        }
        
        return o_val
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
                    owner.onImPhoneAction!(sender: self, isVideo:args[0] as! Bool, args:args[1] as! Array<AnyObject>)
                }
                break
                
            case "onImPhoneShow":
                if(owner.onImPhoneShow != nil) {
                    owner.onImPhoneShow!(sender: self, isDial: args[0] as! Bool, isVideo: args[1] as! Bool)
                }
                break
    
            case "onImUserStatus":
                if(owner.onImUserStatus != nil) {
                    owner.onImUserStatus!(sender: self, args: args[0] as! Dictionary<String, AnyObject>)
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
    
    func setLocalStream(isVideo:Bool, isDial:Bool) -> Void {
        self.rtcMedia.videoTrack.isEnabled = isVideo
        self._localProxy.set(track:self.rtcMedia.videoTrack)
        self.rtcMedia.startCapture(videoWidth: 320, videoHeight: 240)
        
        for(_, _handler) in _rtcHandlers {
            _handler.add(videoTrack: self.rtcMedia.videoTrack, audioTrack: self.rtcMedia.audioTrack)
            if(!isDial) {
                _handler.createOffer()
            }
        }
    }
    
    func phoneViewOpen(isDial:Bool, isVideo:Bool) {
        roomData.setInfo(msgType: isVideo ? "2" : "1"
            , isDial: isDial
            , phoneStartTime: Date.init().timestamp
            , phoneStopTime: 0
            , phonePickupTime: 0
            , phoneHungUpTime: 0)
        
        invokeDelegate(name: "onImPhoneShow", args: [isDial, isVideo])
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
            self.setLocalStream(isVideo:isVideo, isDial: isDial)
            self.signInvoke(method: arg0, withArgs: [arg1, arg2])
        }
        
        switch (action) {
        case "dial":
            self.phoneViewOpen(isDial: isDial, isVideo: isVideo)
            if(_isIceConnected) {
                _fn()
            } else {
                _promiseRtcConnected.append({
                    _fn()
                })
                notifyUser()
            }
            break
            
        case "show":
            if(_isIceConnected) {
                self.phoneViewOpen(isDial: isDial, isVideo: isVideo)
            } else {
                _promiseRtcConnected.append({
                    self.phoneViewOpen(isDial: isDial, isVideo: isVideo)
                })
                notifyUser()
            }
            break
            
        case "pickup":
            if(!isDial) {
                self.setLocalStream(isVideo:isVideo, isDial: isDial)
            }
            signInvoke(method: arg0, withArgs: [arg1, arg2])
            break
            
        default:
            signInvoke(method: arg0, withArgs: [arg1, arg2])
            break
        }
    }
    
    public func setProxyRenderer(local:RtcView?, remote:RtcView?) -> Void {
        _localProxy.set(target:local)
        _remoteProxy.set(target:remote)
    }
    
    public func getUserStatus() -> Void {
        signInvoke(method: "getUserStatus", withArgs: [
            _roomInfo.userType == "1" ? 2 : 1
            , _roomInfo.oNo, _roomInfo.uNo, _roomInfo.tNo, 0])
    }
    
    public func savePushToken(tokenId:String, deviceId:String) -> Void {
        signInvoke(method: "savePushToken", withArgs: [tokenId, deviceId, 8])
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
    @objc optional func onImPhoneAction(sender:IMService, isVideo:Bool, args:Array<AnyObject>)
    
    /// 收到使用者狀態
    @objc optional func onImUserStatus(sender:IMService, args:Dictionary<String, AnyObject>)
}

/** ==============================================================================================
 * signHandlerDelegate
 ============================================================================================== */
extension IMService : SignHandlerDelegate {
    ///訊號連線觸發
    func onSignConnected(sender:SignHandler) {
        _isSignConnected = true
        
        if(_roomInfo.userType == "1") {
            //求職
            sender.invoke("settUser", withArgs: [_roomInfo.tName])
        }
        else {
            //求才
            sender.invoke("setoUser", withArgs: [_roomInfo.oName, _roomInfo.uName])
        }
        
        //
        let _size = self._promiseSignConnected.count-1
        if(_size > -1) {
            for _ in 0..._size {
                self._promiseSignConnected.remove(at: 0)()
            }
        }
    }
    
    ///訊號離線觸發
    func onSignDisconnected(sender:SignHandler) {
        _isSignConnected = false
    }
    
    ///收到消息觸發
    func onSignReceived(sender:SignHandler, eventName:String, args:Array<AnyObject>) {
        switch eventName {
        case "onTextMessage":
            guard ("\(_roomInfo.tNo)_\(_roomInfo.oNo)_\(_roomInfo.uNo)_\(_roomInfo.eNo)" ==
                "\(args[1].description!)_\(args[2].description!)_\(args[3].description!)_\(args[4].description!)") else { return }
            
            if(args[5].description != "") {
                invokeDelegate(name: "onImMessage", args: ["0", self.getUserMsgLog(msgType: "0", msg: args[5].description)])
            }
            break
            
        case "onOffLineMessage":
            guard ("\(_roomInfo.tNo)_\(_roomInfo.oNo)_\(_roomInfo.uNo)_\(_roomInfo.eNo)" !=
                "\(args[1].description!)_\(args[2].description!)_\(args[3].description!)_\(args[4].description!)") else { return }
            
            invokeDelegate(name: "onImMessage", args: ["0", "onOffLineMessage"])
            break
            
        case "onUserStatus":
            //{"Status":1,"Text":"上線中","tNo":47012821,"oNo":9565124,"uNo":20132852,"ContextID":"","OnlineTime":0,"OnlineTimeNote":"剛剛上線"}
            if let _args0 = args[0] as? Dictionary<String, AnyObject> {
                guard ("\(_roomInfo.tNo)_\(_roomInfo.oNo)_\(_roomInfo.uNo)" ==
                    "\(_args0["tNo"]!.description!)_\(_args0["oNo"]!.description!)_\(_args0["uNo"]!.description!)") else { return }
                
                invokeDelegate(name: "onImUserStatus", args: [_args0])
            }
            break
            
        case "onNotifyUser":
            guard ( "\(_roomInfo.uNo)_\(_roomInfo.eNo)" ==
                    "\(args[3].description!)_\(args[4].description!)") else { return }
            
            _roomInfo.setInfo(cid:args[0].description)
            sender.invoke("doRTCConnection", withArgs:[args[0].description])
            break
            
        case "onRTCConnecting":
            //等RTC連線後傳送 doRTCConnected 訊號
            getRtcHandler(id:args[0], fn: { (_rtcHandler) in
                _rtcHandler.createOffer(onConnected: { (_rtcHandler) in
                    sender.invoke("doRTCConnected", withArgs:[args[1].description]);
                })
            })
            break
            
        case "onRTCMessage": //收到 RTC 協議訊息
            getRtcHandler(id:args[0].description!, fn: { (_rtcHandler) in
                if let _dic = args[1].description!.parseJson() {
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
            if let _handler = _rtcHandlers.removeValue(forKey: args[0].description) {
                _handler.dispose()
            }
            break
            
        case "onPhoneCall", "onVideoCall":
            let _isVideo = eventName == "onVideoCall" ? true : false
            let _msgType = _isVideo ? "2" : "1"
            let _phoneTime = Date.init().timestamp
            var _duringTime = 0
            
            switch(args[0].description) {
            case "dial":
                break
                
            case "show":
                self.doCallPhone(isVideo: _isVideo, action: args[0].description)
                break
                
            case "pickup":
                RTCAudioSession.sharedInstance().isAudioEnabled = true
                roomData.setInfo(phonePickupTime: _phoneTime)
                break
                
            case "hangup":
                RTCAudioSession.sharedInstance().isAudioEnabled = false
                
                //清除使用資源
                self.setProxyRenderer(local: nil, remote: nil)
                rtcMedia.clearLocalStream()
                for(_, _handler) in _rtcHandlers {
                    _handler.clearStream()
                }
                
                //設定通話資訊
                roomData.setInfo(phoneStopTime: _phoneTime)
                if(roomData.phonePickupTime > 0) {
                    roomData.setInfo(phoneHungUpTime: _phoneTime)
                    _duringTime = roomData.phoneHungUpTime - roomData.phonePickupTime
                    _duringTime = Int(Double.init(_duringTime) / 1000.0)
                }
                
                //撥號方須傳送撥號資訊
                if(roomData.isDial) {
                    sendMessage(type: roomData.msgType)
                }
                
                //將訊息送給使用者介面
                invokeDelegate(name: "onImMessage", args: [_msgType
                    , self.getUserMsgLog(msgType: _msgType
                        , msg: ""
                        , whoTalk: roomData.isDial ? "1" : "0"
                        , duringTime: _duringTime
                    )])
                break
                
            case "changevideo":
                roomData.setInfo(msgType: "2")
                break
                
            default:
                break
            }
            invokeDelegate(name: "onImPhoneAction", args: [_isVideo , args])
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
        if(type == "add") {
            if(stream.videoTracks.count > 0) {
                self._remoteProxy.set(track:stream.videoTracks[0])
            }
        }
    }
    
    ///ice 連接狀態改變會觸發
    func onRtcIceConnectionChange(sender:RtcHandler, newState:RTCIceConnectionState) {
        switch newState {
        case RTCIceConnectionState.connected, RTCIceConnectionState.completed:
            _isIceConnected = true
            let _size = self._promiseRtcConnected.count-1
            if(_size > -1) {
                for _ in 0..._size {
                    self._promiseRtcConnected.remove(at: 0)()
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
            _candidate["sdpMLineIndex"] = "\(candidate.sdpMLineIndex)"
            guard let _json = utility.convertToJson(of: ["candidate":_candidate]) else { return }
            signInvoke(method: "rtcSend", withArgs: [sender.connectionId, _json])
        }
    }
}
