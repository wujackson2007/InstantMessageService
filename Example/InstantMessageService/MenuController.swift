//
//  MenuController.swift
//  eChat
//
//  Created by wujackson on 2017/10/16.
//  Copyright © 2017年 wujackson. All rights reserved.
//

import UIKit
import WebKit

class MenuController: UIViewController {
    var _web:String = ""
    var header: WKWebView!
    var body: WKWebView!
    @IBOutlet weak var _header: UIStackView!
    @IBOutlet weak var _body: UIStackView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        _web = ServiceHandler.apiHost
        let webConfiguration = WKWebViewConfiguration()
        header = WKWebView(frame: _header.frame, configuration: webConfiguration)
        header.navigationDelegate = self
        _header.addArrangedSubview(header)
        
        body = WKWebView(frame: _body.frame, configuration: webConfiguration)
        body.navigationDelegate = self
        _body.addArrangedSubview(body)
        
        ServiceHandler.loadHtmlPage(bundle: Bundle.main, target: header, page:"menuHeader.html")
        ServiceHandler.loadHtmlPage(bundle: Bundle.main, target: body, page:"menu.html")
        
        AppDelegate.mainController?.header.evaluateJavaScript("setNewMessage('0')")
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}

extension MenuController: WKNavigationDelegate {
    func webView(_ webView: WKWebView,
                 decidePolicyFor navigationAction: WKNavigationAction,
                 decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        
        if(navigationAction.request.url?.scheme == "invoke") {
            var path = ""
            if let url = navigationAction.request.url?.absoluteString {
                var args:String = ""
                var num:Int = 0
                
                path = url
                if let _args = url.substringByIndex(of: "?", num: &num) {
                    args = _args.decodeUrl()
                    if let _path = url.substring(location: 0, length: num) { path = _path }
                }
                
                switch path {
                case "invoke://showMessages":
                    self.dismiss(animated: true, completion: nil)
                    break
                    
                case "invoke://chatEnableUpd": //接收訊息開關
                    let _fn:() -> Void = {
                        if let _data = utility.getUrlData(url: "\(self._web)/Chact_Jobs/appApi.asp?actFun=chatEnable&\(LoginController.apiToken)") {
                            if let _info = _data.parseJson() {
                                var _chatEnable = ""
                                if (_info["chatEnable"] != nil) {
                                    _chatEnable = (_info["chatEnable"] as AnyObject).description
                                    webView.evaluateJavaScript("chatStatusSet('\(_chatEnable)')", completionHandler: nil)
                                }
                            }
                        }
                    }
                    
                    if(args == "1") {
                        utility.showAlert(message: "關閉將無法接收即時訊息跟來電！\r\n確定要關閉嗎？", resolve: { (_) in
                            _fn()
                        })
                    } else {
                        //AppDelegate.imService.signInvoke(method: "savePushToken", withArgs: [AppDelegate.PKPushToken, "", 8])
                        _fn()
                    }
                    break
                    
                case "invoke://logItemClick": //點選對話紀錄
                    //{\"aNo\":5952,\"empName\":\"0719 測試職缺 請勿應徵\",\"talentNo\":47012821,\"organNo\":9565124,\"eNo\":80057674,\"uNo\":42084,\"dateIn\":\"2017-10-13 09:19:50\",\"noReadCN\":0,\"organ\":\"1111測試專用公司(請勿應徵)\"}
                    if var dic = args.parseJson() {
                        ServiceHandler.roomData.setInfo(userType: "1"
                            , tNo: dic["talentNo"], tName: LoginController.tName
                            , oNo: dic["organNo"], oName: dic["organ"]
                            , uNo: dic["uNo"]
                            , eNo: dic["eNo"], eName: dic["empName"])
                        
                        ServiceHandler.serviceStart()
                        dismiss(animated: true, completion: nil)
                    }
                    break
                    
                default:
                    break
                }
            }
            
            decisionHandler(.cancel)
        } else {
            decisionHandler(.allow)
        }
    }
    
    func webView(_ webView: WKWebView,didFinish navigation: WKNavigation!)
    {
        var path = webView.url?.path ?? ""
        var num:Int = 0
        if let _path = path.substringByLastIndex(of: "/", num: &num) {
            path = _path
        }
        
        switch path {
        case "menu.html":
            //取得訊息開關
            if let _data = utility.getUrlData(url: "\(_web)/Chact_Jobs/appApi.asp?actFun=loginInfo&\(LoginController.apiToken)") {
                if let _info = _data.parseJson() {
                    let _chatEnable = _info["chatEnable"] as? String ?? ""
                    webView.evaluateJavaScript("chatStatusSet('\(_chatEnable)')", completionHandler: nil)
                }
            }
            
            //取得對話紀錄
            if let _data = utility.getUrlData(url: "\(_web)/Chact_Jobs/appApi.asp?actFun=getLog&\(LoginController.apiToken)") {
                webView.evaluateJavaScript("chatLogShow('\(_data.toString())','\(ServiceHandler.roomData.eNo)','\(ServiceHandler.roomData.uNo)')", completionHandler: nil)
            }
            break
            
        default:
            break
        }
    }
}
