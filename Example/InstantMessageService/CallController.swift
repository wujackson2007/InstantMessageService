//
//  CallController.swift
//  eChat
//
//  Created by 吳永誌 on 2017/10/14.
//  Copyright © 2017年 wujackson. All rights reserved.
//
import UIKit
import InstantMessageService

class CallController: UIViewController {
    static var instance:CallController?
    var isShowRtcView = false
    var localView:RtcView = RtcView.init(frame: CGRect.init(x: 10, y: 37, width: 80, height: 80))
    var remoteView:RtcView = RtcView.init(frame: CGRect.init(x: 0, y: 0, width: 320, height: 240))
    
    @IBOutlet weak var txtTimer: UILabel!
    @IBOutlet weak var remoteVideoSpace: UIStackView!
    @IBOutlet weak var btnPickup: UIButton!
    @IBOutlet weak var btnHangup: UIButton!
    @IBOutlet weak var btnVideo: UIButton!
    @IBOutlet weak var btnVoice: UIButton!
    
    @IBAction func btnPickupClick(_ sender: UIButton) {
        ServiceHandler.doCallPhone(isVideo: ServiceHandler.roomData.isVideo, action: "pickup")
    }
    
    @IBAction func btnHangupClick(_ sender: UIButton) {
        ServiceHandler.doCallPhone(isVideo: ServiceHandler.roomData.isVideo, action: "hangup")
        self.destroy()
    }
    
    @IBAction func btnVoiceClick(_ sender: UIButton) {
        if let _id = sender.imageView?.image?.accessibilityIdentifier {
            let _enabled = _id == "icoVoiceOn" ? false : true
            self.setBtnStyle(target: "btnVoice", on: _enabled)
            ServiceHandler.audio(enabled: _enabled)
        }
    }
    
    @IBAction func btnVideoClick(_ sender: UIButton) {
        if let _id = sender.imageView?.image?.accessibilityIdentifier {
            let _enabled = _id == "icoVideoOn" ? false : true
            self.setBtnStyle(target: "btnVideo", on: _enabled)
            ServiceHandler.video(enabled: _enabled)
            
            //
            if(!ServiceHandler.roomData.isVideo) {
                ServiceHandler.doCallPhone(isVideo: ServiceHandler.roomData.isVideo, action: "changevideo")
            }
        }
    }
    
    func destroy() -> Void {
        self.localView.showVideo(false)
        self.remoteView.showVideo(false)
        CallController.instance = nil
        self.dismiss(animated: true, completion: nil)
    }
    
    func setBtnStyle(target:String, on:Bool) -> Void {
        var (_imgId, _color) = ("icoVideoOn", 0x4FC5F7)
        var _btn = btnVideo!
        
        switch target {
        case "btnVideo":
            (_imgId, _color) = on ? ("icoVideoOn", 0x4FC5F7) : ("icoVideoOff", 0x666666)
            _btn = btnVideo
            break
            
        case "btnVoice":
            (_imgId, _color) = on ? ("icoVoiceOn", 0x4FC5F7) : ("icoVoiceOff", 0x666666)
            _btn = btnVoice
            break
            
        default:
            break
        }
        
        if let _image = ServiceHandler.resource[_imgId] {
            _btn.setImage(_image, for: UIControlState.normal)
            _btn.backgroundColor = UIColor.init(hex: _color)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view, typically from a nib.
        if(CallController.instance == nil) {
            CallController.instance = self
        }
        else {
            self.destroy()
            return
        }
        
        //設定按鈕樣式
        for (fileName, btnIco) in [("icoPickup", btnPickup!), ("icoHangup", btnHangup!), ("icoVideoOn", btnVideo!), ("icoVoiceOn", btnVoice!)] {
            btnIco.layer.cornerRadius = 30.0
            if let imagePlay = ServiceHandler.resource[fileName] {
                btnIco.setImage(imagePlay, for: UIControlState.normal)
            }
        }
        
        self.setBtnStyle(target: "btnVideo", on: ServiceHandler.roomData.isVideo)
        
        //設定視訊
        remoteView.frame = remoteVideoSpace.frame
        remoteVideoSpace.addArrangedSubview(remoteView)
        self.view.addSubview(localView)
        ServiceHandler.setProxyRenderer(local: localView, remote: remoteView)
        
        //
        self.backgroundProcess(target: self)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func timeDiff(time:Int) -> String {
        let date1 = Date.init(timestamp: time)
        let date2 = Date.init()
        let diff = date2.timeIntervalSince(date1)
        
        return Date.init(timeIntervalSince1970: diff).format(spec: "HH:mm:ss")
    }
    
    func backgroundProcess(target:CallController) -> Void {
        _ = utility.setTimeout(delay: 0.1, callbackArgs: target) { (args:Any?) in
            if let _call = args as? CallController {
                var showBtnPickup:Bool = false
                var showBtnVideo:Bool = false
                var showBtnVoice:Bool = false
                
                var _status = ""
                if(ServiceHandler.roomData.phoneStopTime > 0) {
                    self.destroy()
                }
                else if(ServiceHandler.roomData.phonePickupTime > 0) {
                    //接聽中
                    if(!self.isShowRtcView) {
                        self.isShowRtcView = true
                        self.localView.showVideo(true)
                        self.remoteView.showVideo(true)
                    }
                    
                    showBtnVideo = true
                    showBtnVoice = true
                    _status = "接聽中：" + _call.timeDiff(time:ServiceHandler.roomData.phonePickupTime)
                }
                else {
                    //撥號中
                    if(ServiceHandler.roomData.isDial) {
                        //撥號方
                        _status = "撥號中：" + _call.timeDiff(time:ServiceHandler.roomData.phoneStartTime)
                    } else {
                        //接聽方
                        showBtnPickup = true
                        _status = "收到來電：" + _call.timeDiff(time:ServiceHandler.roomData.phoneStartTime)
                    }
                }
                
                //顯示計時器
                _call.txtTimer.text = _status
                
                self.btnPickup.isHidden = !showBtnPickup;
                self.btnVideo.isHidden = !showBtnVideo;
                self.btnVoice.isHidden = !showBtnVoice;
                _call.backgroundProcess(target:_call)
            }
        }
    }
}
