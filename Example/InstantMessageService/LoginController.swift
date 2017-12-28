//
//  LoginController.swift
//  eChat
//
//  Created by 吳永誌 on 2017/10/15.
//  Copyright © 2017年 wujackson. All rights reserved.
//

import UIKit

class LoginController: UIViewController {
    @IBOutlet weak var txtUserId: UITextField!
    @IBOutlet weak var txtUserPass: UITextField!
    @IBAction func btnLogin(_ sender: UIButton) {
        let _uid = txtUserId.text ?? ""
        let _pass = txtUserPass.text ?? ""
        _ = LoginController.getLoginInfo(uid: _uid, pass: _pass)
        if(LoginController.isLogin) {
            let defaults = UserDefaults.standard
            defaults.set(_uid, forKey: "uid")
            defaults.set(_pass, forKey: "pass")
            self.dismiss(animated: true, completion: nil)
        }
    }
    
    static var tNo:String {
        get {
            if let loginInfo = UserDefaults.standard.value(forKey: "loginInfo") as? Dictionary<String, String> {
                return loginInfo["tNo"] ?? ""
            }
            return ""
        }
    }
    
    static var tName:String {
        get {
            if let loginInfo = UserDefaults.standard.value(forKey: "loginInfo") as? Dictionary<String, String> {
                return loginInfo["tName"] ?? ""
            }
            return ""
        }
    }
    
    ///檢核是否登入
    static var isLogin : Bool {
        get {
            var o_val:Bool = false
            if let loginInfo = UserDefaults.standard.value(forKey: "loginInfo") as? Dictionary<String, String> {
                let _token = loginInfo["Token"] ?? ""
                let _tNo:Int = Int(loginInfo["tNo"] ?? "") ?? 0
                if(_token != "" && _tNo > 0) {
                    o_val = true
                }
            }
            return o_val
        }
    }
    
    static var apiToken : String {
        get {
            if let loginInfo = UserDefaults.standard.value(forKey: "loginInfo") as? Dictionary<String, String> {
                let _tNo = loginInfo["tNo"] ?? ""
                let _token = loginInfo["Token"] ?? ""
                return "tNo=\(_tNo)&token=\(_token)"
            }
            return ""
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    static func getLoginInfo(uid:String? = "", pass:String? = "") -> Dictionary<String, String>? {
        var loginInfo:Dictionary<String, String>?
        let _web = "https://www.1111.com.tw"
        
        if let _loginInfo = UserDefaults.standard.value(forKey: "loginInfo") as? Dictionary<String, String> {
            loginInfo = _loginInfo
        }
        else {
            if(uid != "" && pass != "") {
                var _cookies:[HTTPCookie]?
                _ = utility.getUrlData(url: "\(_web)/talents/login.asp?id=\(uid!)&pass=\(pass!)", fn:{
                    (data:Data?, response:URLResponse?) in
                    if let _response = response as? HTTPURLResponse {
                        if let allHeaderFields = _response.allHeaderFields as? [String : String] {
                            _cookies = HTTPCookie.cookies(withResponseHeaderFields: allHeaderFields, for: _response.url!)
                        }
                    }
                })
                
                if(_cookies != nil) {
                    loginInfo = [:]
                    if let _data = utility.getUrlData(url:"\(_web)/Chact_Jobs/index.asp?actFun=getAppLoginInfo", cookies:_cookies) as Data? {
                        if let _parsedData = _data.parseJson() {
                            for(key, val) in _parsedData {
                                loginInfo![key] = (val as AnyObject).description
                            }
                            UserDefaults.standard.set(loginInfo, forKey: "loginInfo")
                        }
                    }
                }
            }
        }
        
        return loginInfo
    }
}
