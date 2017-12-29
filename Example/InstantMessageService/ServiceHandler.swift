//
//  params.swift
//  imTest
//
//  Created by wujackson on 2017/12/21.
//  Copyright © 2017年 wujackson. All rights reserved.
//

import WebKit
import InstantMessageService

class ServiceHandler {
    private static var _resource:Dictionary<String, UIImage> = [:]
    private static var _params:Dictionary<String, String> = ["web": "https://www.1111.com.tw"]
    private static var _imService:IMService?
    
    static var apiHost:String {
        get {
            return _params["web"] ?? ""
        }
    }
    
    static func loadHtmlPage(bundle:Bundle, target:WKWebView, page:String) {
        let arr = page.components(separatedBy: ".")
        let htmlPath:String = bundle.path(forResource: "html", ofType: "bundle")!
        let htmlBundle:Bundle? = Bundle(path: htmlPath)
        let url:URL = URL(fileURLWithPath: htmlBundle!.path(forResource: arr[0], ofType: arr[1])!)
        target.load(URLRequest(url: url))
    }
    
    static var resource:Dictionary<String, UIImage> {
        get {
            if(_resource.count == 0) {
                for fileName in ["icoPickup", "icoHangup", "icoVideoOn", "icoVideoOff", "icoVoiceOn", "icoVoiceOff"] {
                    if let _path = Bundle.main.path(forResource: fileName, ofType: "png", inDirectory: "html.bundle/images/ico") {
                        if let _data = utility.getUrlData(nsUrl: URL.init(fileURLWithPath: _path)) {
                            if let imagePlay = UIImage.init(data: _data) {
                                imagePlay.accessibilityIdentifier = fileName
                                _resource[fileName] = imagePlay
                            }
                        }
                    }
                }
            }
            return _resource
        }
    }
    
    private static var imService:IMService {
        get {
            if(_imService == nil) {
                _imService = IMService.init()
            }
            
            return _imService!
        }
    }
    
    static var roomData:RoomInfo {
        get {
            return imService.roomData
        }
    }
    
    /// 服務啟動
    static func serviceStart(fn:(() -> Void)? = nil) {
        if let loginInfo = LoginController.getLoginInfo() {
            let tNo:String = loginInfo["tNo"] ?? ""
            let tName:String = loginInfo["tName"] ?? ""
            let toKen:String = loginInfo["Token"] ?? ""
            guard (tNo != "" && tName != "" && toKen != "") else { return }
            if(roomData.tName == "") {
                roomData.setInfo(userType: "1", tNo: tNo, tName: tName)
            }
            
            imService.start(hubName: "echathub", url: "\(apiHost)/eChatHub", queryString: ["tNo": tNo, "Token": toKen, "Chat": "1"], onStart: fn)
        }
    }
    
    /// 服務關閉
    static func serviceStop() {
        imService.stop()
    }
    
    /// 開啟或關閉音訊
    static func audio(enabled:Bool) -> Void {
        imService.rtcMedia.audio(enabled: enabled)
    }
    
    /// 開啟或關閉視訊
    static func video(enabled:Bool) -> Void {
        imService.rtcMedia.video(enabled: enabled)
    }
    
    static func setServiceDelegate(key:String, delegate:IMServiceDelegate) -> Void {
        imService.setDelegate(key: key, delegate: delegate)
    }
    
    static func rmServiceDelegate(key:String) -> Void {
        imService.rmDelegate(key: key)
    }
    
    /// 傳送訊息
    static func sendMessage(type:String, message:String?) {
        imService.sendMessage(type: type, message: message)
    }
    
    /// 撥打電話
    static func doCallPhone(isVideo:Bool, action:String) -> Void {
        imService.doCallPhone(isVideo: isVideo, action: action)
    }
    
    ///
    static func setProxyRenderer(local:RtcView?, remote:RtcView?) -> Void {
        imService.setProxyRenderer(local: local, remote: remote)
    }
    
    /// 取得使用者狀態
    static func getUserStatus() -> Void {
        imService.getUserStatus()
    }
    
    ///
    static func savePushToken(tokenId:String, deviceId:String) -> Void {
        imService.savePushToken(tokenId: tokenId, deviceId: deviceId)
    }
}
