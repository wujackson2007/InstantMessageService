//
//  utility.swift
//  eChat
//
//  Created by wujackson on 2017/10/17.
//  Copyright © 2017年 wujackson. All rights reserved.
//

import Foundation

class utility {
    static func getValue<T>(val:Any) -> T? {
        var o_val:T?
        
        if let _val:T = val as? T {
            o_val = _val
        }
        
        return o_val
    }
    
    static func convertToJson(of target:Any) -> String? {
        var o_val:String?
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: target, options:.prettyPrinted)
            o_val = jsonData.toString()
        }catch{}
        return o_val;
    }
    
    static func clearCached() {
        URLCache.shared.removeAllCachedResponses()
        URLCache.shared.diskCapacity = 0
        URLCache.shared.memoryCapacity = 0
        /*
         if let cookies = HTTPCookieStorage.shared.cookies {
         for cookie in cookies {
         HTTPCookieStorage.shared.deleteCookie(cookie)
         }
         }
         */
    }
    
    static func showAlert(title:String? = nil, message:String, resolve:@escaping((UIAlertAction) -> Void), reject:((UIAlertAction) -> Void)? = nil) {
        if let topController = UIApplication.topViewController() {
            let _alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.alert)
            _alert.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.default, handler: resolve))
            _alert.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.cancel, handler: reject))
            topController.present(_alert, animated: true, completion: nil)
        }
    }
    
    static func setTimeout(delay:TimeInterval, callbackArgs:Any? = nil, callback:@escaping (Any?)->Void) -> Timer {
        let _fn = { callback(callbackArgs) }
        return Timer.scheduledTimer(timeInterval: delay, target: BlockOperation(block: _fn), selector: #selector(Operation.main), userInfo: nil, repeats: false)
    }
    
    static func getUrlData(url:String, cookies:[HTTPCookie]? = nil, fn:((Data?, URLResponse?)->Void)? = nil) -> Data? {
        return utility.getUrlData(nsUrl: URL.init(string: url)!, cookies: cookies, fn: fn)
    }
    static func getUrlData(nsUrl:URL, cookies:[HTTPCookie]? = nil, fn:((Data?, URLResponse?)->Void)? = nil) -> Data? {
        var o_val:Data?
        var _request = URLRequest(url:nsUrl)
        _request.setValue("agent=app;", forHTTPHeaderField: "Cookie")
        _request.httpShouldHandleCookies = true
        
        if cookies != nil {
            if let _cookie:String = HTTPCookie.requestHeaderFields(with: cookies!)["Cookie"] {
                _request.setValue(_cookie, forHTTPHeaderField: "Cookie")
            }
        }
        
        let (_data, _response, _) = URLSession.shared.synchronousDataTask(urlrequest: _request)
        if (fn != nil) {
            fn!(_data, _response)
        }
        
        o_val = _data
        return o_val
    }
}

extension UIColor {
    convenience init(hex: Int, alpha: Double = 1.0) {
        self.init(red: CGFloat((hex>>16)&0xFF)/255.0, green:CGFloat((hex>>8)&0xFF)/255.0, blue: CGFloat((hex)&0xFF)/255.0, alpha:  CGFloat(255 * alpha) / 255)
    }
}

extension UIApplication {
    class func topViewController(controller: UIViewController? = UIApplication.shared.keyWindow?.rootViewController) -> UIViewController? {
        if let navigationController = controller as? UINavigationController {
            return topViewController(controller: navigationController.visibleViewController)
        }
        if let tabController = controller as? UITabBarController {
            if let selected = tabController.selectedViewController {
                return topViewController(controller: selected)
            }
        }
        if let presented = controller?.presentedViewController {
            return topViewController(controller: presented)
        }
        return controller
    }
}

extension Date {
    func format(spec:String) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.timeZone = TimeZone(secondsFromGMT: 8)
        dateFormatter.dateFormat = spec
        return dateFormatter.string(from: self)
    }
}

extension Data {
    func parseJson() -> Dictionary<String, Any>?
    {
        var o_val:Dictionary<String, Any>?
        do {
            o_val = try JSONSerialization.jsonObject(with: self, options: JSONSerialization.ReadingOptions.mutableLeaves) as? [String:Any]
        } catch {}
        return o_val
    }
    
    func toString(encoding:String.Encoding? = String.Encoding.utf8) -> String {
        return String.init(data: self, encoding: encoding!) ?? ""
    }
}

extension String {
    func index(of target: String) -> Int? {
        if let range = self.range(of: target) {
            return characters.distance(from: startIndex, to: range.lowerBound)
        } else {
            return nil
        }
    }
    
    func lastIndex(of target: String) -> Int? {
        if let range = self.range(of: target, options: .backwards) {
            return characters.distance(from: startIndex, to: range.lowerBound)
        } else {
            return nil
        }
    }
    
    func substring(location: Int, length: Int? = nil) -> String? {
        var len:Int?
        if(length == nil) {
            len = characters.count - location
        } else {
            len = length!
        }
        
        guard characters.count >= location + len! else { return nil }
        let start = index(startIndex, offsetBy: location)
        let end = index(startIndex, offsetBy: location + len!)
        return substring(with: start..<end)
    }
    
    func substringByIndex(of target: String, num: inout Int) -> String? {
        var o_val:String?
        
        num = -1
        if let _num = self.index(of: target) {
            if let _val = self.substring(location: _num + 1) {
                o_val = _val
                num = _num
            }
        }
        
        return o_val
    }
    
    func substringByLastIndex(of target: String, num: inout Int) -> String? {
        var o_val:String?
        
        num = -1
        if let _num = self.lastIndex(of: target) {
            if let _val = self.substring(location: _num + 1) {
                o_val = _val
                num = _num
            }
        }
        
        return o_val
    }
    
    func encodeUrl() -> String
    {
        return self.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed) ?? ""
    }
    
    func decodeUrl() -> String
    {
        return self.removingPercentEncoding ?? ""
    }
    
    func parseJson() -> Dictionary<String, Any>?
    {
        var o_val:Dictionary<String, Any>?
        
        if let _data:Data = self.data(using: String.Encoding.utf8) {
            o_val = _data.parseJson()
        }
        
        return o_val
    }
    
    func parseUrlQuery() -> Dictionary<String, String>
    {
        var o_val = [String:String]()
        
        if let components = URLComponents(string: self) {
            if let queryItems = components.queryItems {
                for item in queryItems {
                    o_val[item.name] = item.value ?? ""
                }
            }
        }
        
        return o_val
    }
}

extension URLSession {
    func synchronousDataTask(urlrequest: URLRequest) -> (Data?, URLResponse?, Error?) {
        var data: Data?
        var response: URLResponse?
        var error: Error?
        let semaphore = DispatchSemaphore(value: 0)
        let dataTask = self.dataTask(with: urlrequest) {
            data = $0
            response = $1
            error = $2
            semaphore.signal()
        }
        dataTask.resume()
        _ = semaphore.wait(timeout: .distantFuture)
        return (data, response, error)
    }
}
