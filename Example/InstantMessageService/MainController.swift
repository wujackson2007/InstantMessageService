//
//  ViewController.swift
//  InstantMessageService
//
//  Created by wujackson on 12/23/2017.
//  Copyright (c) 2017 wujackson. All rights reserved.
//
import UIKit
import WebKit
import InstantMessageService

class MainController: UIViewController {
    var header: WKWebView!
    var body: WKWebView!
    @IBOutlet weak var _header: UIStackView!
    @IBOutlet weak var _body: UIStackView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        AppDelegate.mainController = self
        
        let webConfiguration = WKWebViewConfiguration()
        header = WKWebView(frame: _header.frame, configuration: webConfiguration)
        header.navigationDelegate = self
        _header.addArrangedSubview(header)
        
        body = WKWebView(frame: _body.frame, configuration: webConfiguration)
        body.navigationDelegate = self
        _body.addArrangedSubview(body)
        
        ServiceHandler.loadHtmlPage(bundle: Bundle.main, target: header, page:"header.html")
        ServiceHandler.loadHtmlPage(bundle: Bundle.main, target: body, page:"index.html")
        
        //
        ServiceHandler.setServiceDelegate(key: self.description, delegate: self)
        ServiceHandler.roomData.setDelegate(key: self.description, delegate: self)
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardWillShow(sender:)), name: Notification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardWillHide(sender:)), name: Notification.Name.UIKeyboardWillHide, object: nil)
        
        //讀取圖片
        _ = ServiceHandler.resource
    }
    
    @objc
    func keyboardWillShow(sender: Notification) {
        DispatchQueue.main.async {
            if let rect = sender.userInfo?[AnyHashable("UIKeyboardFrameEndUserInfoKey")] as? CGRect {
                self.view.frame.origin.y = -1 * rect.height
            }
        }
    }
    
    @objc
    func keyboardWillHide(sender: Notification) {
        DispatchQueue.main.async {
            self.view.frame.origin.y = 0 // Move view to original position
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
        ServiceHandler.rmServiceDelegate(key: self.description)
        ServiceHandler.roomData.rmDelegate(key: self.description)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if (!LoginController.isLogin) {
            //顯示登入
            performSegue(withIdentifier: "startLogin", sender: self)
        }
        else {
            //假設無通知資訊,讓使用者選取通知清單
            if(ServiceHandler.roomData.eNo == "" &&
                ServiceHandler.roomData.uNo == "") {
                performSegue(withIdentifier: "startMenu", sender: self)
            }
        }
    }
    
    func chatMessageLoad(jsonData:String? = "", type:String? = "", clear:Bool? = false) {
        if(jsonData != "") {
            let isClear = clear! ? "1" : "0"
            body.evaluateJavaScript("chatMessageLoad([\(jsonData!)], '\(type!)', '\(isClear)')", completionHandler: nil)
        }
    }
}

extension MainController: WKNavigationDelegate {
    func webView(_ webView: WKWebView,
                 decidePolicyFor navigationAction: WKNavigationAction,
                 decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        
        if(navigationAction.request.url?.scheme == "invoke") {
            if var path = navigationAction.request.url?.absoluteString {
                var args:String = ""
                var num:Int = 0
                if let _args = path.substringByIndex(of: "?", num: &num) {
                    args = _args.decodeUrl()
                    if let _path = path.substring(location: 0, length: num) { path = _path }
                }
                
                DispatchQueue.main.async {
                    switch path {
                    case "invoke://consoleLog": //顯示瀏覽器log
                        //print(args)
                        break
                        
                    case "invoke://chatMessageLoadByDate": //讀取歷史訊息
                        //cid=&eNo=80057674&uNo=42084&actFun=getList&msgDate=2017%2F10%2F12
                        let (_eNo, _uNo) = (ServiceHandler.roomData.eNo, ServiceHandler.roomData.uNo)
                        if(_eNo != "" && _uNo != "" && args != "") {
                            if let _data = utility.getUrlData(url: "\(ServiceHandler.apiHost)/Chact_Jobs/appApi.asp?cid=&eNo=\(_eNo)&uNo=\(_uNo)&msgDate=\(args)&actFun=getList&\(LoginController.apiToken)") {
                                self.chatMessageLoad(jsonData: _data.toString(), type: "up",  clear: false)
                            }
                        }
                        break
                        
                    case "invoke://showCallVoice", "invoke://showCallVideo": //進行通話
                        ServiceHandler.doCallPhone(isVideo: path == "invoke://showCallVideo" ? true : false, action: "dial")
                        break
                        
                    case "invoke://showMenu": //顯示選單
                        self.performSegue(withIdentifier: "startMenu", sender: self)
                        break
                        
                    case "invoke://sendTextMessage": //傳送文字訊息
                        ServiceHandler.sendMessage(type: "0", message: args)
                        break
                        
                    default:
                        break
                    }
                }
            }
            
            decisionHandler(.cancel)
        } else {
            decisionHandler(.allow)
        }
    }
}

extension MainController: RoomInfoDelegate {
    @objc func onChange(sender:RoomInfo, fields:Array<String>) -> Void {
        guard (fields.contains("eNo") || fields.contains("uNo")) else { return }
        if let _data = utility.getUrlData(url: "\(ServiceHandler.apiHost)/Chact_Jobs/appApi.asp?cid=&eNo=\(sender.eNo)&uNo=\(sender.uNo)&actFun=getList&\(LoginController.apiToken)") {
            var imgUrl = ""
            if(sender.oImgUrl != "") {
                if let _imgData = utility.getUrlData(url: sender.oImgUrl) {
                    imgUrl = "data:image/jpg;base64," + _imgData.base64EncodedString()
                }
            }
            
            //設定抬頭資訊
            self.header.evaluateJavaScript("setUserInfo('\(sender.oName)','\(sender.eName)','\(imgUrl)')")
            
            //取得使用者狀態
            ServiceHandler.getUserStatus()
            
            //讀取訊息
            self.chatMessageLoad(jsonData: _data.toString(), clear: true)
        }
    }
}

extension MainController: IMServiceDelegate {
    @objc func onImMessage(sender:IMService, type:String, message:String) {
        if(message == "onOffLineMessage") {
            self.header.evaluateJavaScript("setNewMessage('1')")
        }
        else {
            self.chatMessageLoad(jsonData:"[\(message)]")
        }
    }
    
    /// 收到使用者狀態
    @objc func onImUserStatus(sender:IMService, args:Dictionary<String, AnyObject>) {
        let statuNote = args["OnlineTimeNote"]!.description!
        self.header.evaluateJavaScript("setStatusNote('\(statuNote)')")
    }
}
