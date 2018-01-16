//
//  AppDelegate.swift
//  imTest
//
//  Created by 吳永誌 on 2017/12/24.
//  Copyright © 2017年 1111. All rights reserved.
//

import UIKit
import UserNotifications
import PushKit
import InstantMessageService

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    static var mainController:MainController?
    var window: UIWindow?
    var isSavePushToken = false
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        
        //
        registerNotifications(application: application)
        
        //
        self.voipRegistration()
        
        //
        _ = ServiceHandler.roomData
        
        //
        ServiceHandler.setServiceDelegate(key: self.description, delegate: self)
        
        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
        serviceStop()
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
        serviceStart()
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }
    
    func application(_ application: UIApplication, didReceive notification: UILocalNotification) {
        receiveMessage(userInfo: notification.userInfo)
    }
    
    /// 登錄推播
    ///
    /// - Parameters:
    ///   - application:
    func registerNotifications(application: UIApplication) -> Void {
        // Register for remote notifications. This shows a permission dialog on first run, to
        // show the dialog at a more appropriate time move this registration accordingly.
        let settings: UIUserNotificationSettings = UIUserNotificationSettings(types: [.alert, .badge, .sound], categories: nil)
        application.registerUserNotificationSettings(settings)
        application.registerForRemoteNotifications()
    }
    
    func serviceStart(fn:(() -> Void)? = nil) {
        ServiceHandler.serviceStart {
            if(!self.isSavePushToken && ServiceHandler.roomData.pushToken != "") {
                let _deviceId:String = UIDevice.current.identifierForVendor?.uuidString ?? ""
                ServiceHandler.savePushToken(tokenId: ServiceHandler.roomData.pushToken, deviceId: _deviceId)
                self.isSavePushToken = true
            }
            
            if(fn != nil) {
                fn!()
            }
        }
    }
    
    func serviceStop() {
        ServiceHandler.serviceStop()
    }
    
    func receiveMessage(userInfo: [AnyHashable: Any]? = nil) {
        guard userInfo != nil else { return }
        
        /*
         參數標籤 說明 參數值 (範例)
         parameter 即時通訊固定使用 IM 的參數值 IM
         pushType 推播類型，0:訊息 1:通訊 2:視訊 0
         cId = "47072d1a-8a84-4d3f-8a6f-609cce507dcf";
         eNo = 80181043;
         empName = "\U4eba\U4e8b\U52a9\U7406 \U8acb\U52ff\U61c9\U5fb5";
         imgURL = "https://recruit.1111.com.tw/eChat/images/nopic_user.jpg";
         message = "<null>";
         oNo = 9565124;
         parameter = IM;
         pushType = 2;
         sender = "1111\U6e2c\U8a66\U5c08\U7528\U516c\U53f8(\U8acb\U52ff\U61c9\U5fb5)";
         tNo = 47012821;
         uNo = 20132852;
         uType = 1;
         */
        
        if let _aps = userInfo!["aps"] as? Dictionary<String, AnyObject> {
            //present a local notifcation to visually see when we are recieving a VoIP Notification
            let _parameter = _aps["parameter"] as? String ?? ""
            if(_parameter == "IM") {
                let pushType = _aps["pushType"]?.description ?? ""
                let message = _aps["message"]?.description ?? ""
                let empName = _aps["empName"]?.description ?? ""
                
                ServiceHandler.roomData.setInfo(userType: _aps["uType"]?.description ?? ""
                    , cid: _aps["cId"]?.description ?? ""
                    , oNo: _aps["oNo"]?.description ?? ""
                    , oImgUrl: _aps["imgURL"]?.description ?? ""
                    , uNo: _aps["uNo"]?.description ?? ""
                    , eNo: _aps["eNo"]?.description ?? ""
                    , eName: empName
                    , msg: message
                    , msgType: pushType
                )
                
                switch(pushType) {
                case "0": //文字
                    //createNotification(title: "", body: message, userInfo: _aps)
                    break
                    
                case "1", "2": //語音或視訊
                    let _fn = { (args:Any?) in
                        let obj = args as? Array<Any>
                        let _arg0 = obj![0] as? (Any?)->Void
                        if(ServiceHandler.isSignConnected) {
                            ServiceHandler.doCallPhone(isVideo: pushType == "2" ? true : false, action: "show")
                        }
                        else {
                            _ = utility.setTimeout(delay: 0.1, callbackArgs: [_arg0!], callback: _arg0!)
                        }
                    }
                    
                    _ = utility.setTimeout(delay: 0.1, callbackArgs: [_fn], callback: _fn)
                    break
                    
                default:
                    break
                }
            }
        }
    }
}

extension AppDelegate : PKPushRegistryDelegate {
    // Register for VoIP notifications
    func voipRegistration() -> Void {
        // Create a push registry object
        let voipRegistry: PKPushRegistry = PKPushRegistry(queue: DispatchQueue.main)
        
        // Set the registry's delegate to self
        voipRegistry.delegate = self
        
        // Set the push type to VoIP
        voipRegistry.desiredPushTypes = [PKPushType.voIP]
    }
    
    // Handle updated push credentials
    public func pushRegistry(_ registry: PKPushRegistry, didUpdate pushCredentials: PKPushCredentials, for type: PKPushType) {
        let token = pushCredentials.token.map { String(format: "%02.2hhx", $0) }.joined()
        print("=== PKPush token:\(token) ===")
        
        //
        ServiceHandler.roomData.setInfo(pushToken: token)
    }
    
    public func pushRegistry(_ registry: PKPushRegistry, didInvalidatePushTokenFor type: PKPushType) {
        print("=== token invalidated ===")
    }
    
    // Handle incoming pushes
    public func pushRegistry(_ registry: PKPushRegistry, didReceiveIncomingPushWith payload: PKPushPayload, for type: PKPushType, completion: @escaping () -> Swift.Void){
        print("=== didReceiveIncomingPushWith:\(payload.dictionaryPayload) ===")
        
        if let _aps = payload.dictionaryPayload["aps"] as? Dictionary<String, AnyObject> {
            //present a local notifcation to visually see when we are recieving a VoIP Notification
            var _dic:Dictionary<String, String> = [:]
            for (key, val) in _aps {
                _dic[key] = val.description ?? ""
            }
            
            let _parameter = _aps["parameter"] as? String ?? ""
            if(_parameter == "IM") {
                let pushType = _aps["pushType"]?.description ?? ""
                let sender = _aps["sender"]?.description ?? ""
                
                switch(pushType) {
                case "0": //文字
                    //createNotification(title: "", body: message, userInfo: _aps)
                    break
                    
                case "1", "2": //語音或視訊
                    if UIApplication.shared.applicationState == UIApplicationState.active {
                        //receiveMessage(userInfo: _dic)
                    }
                    else {
                        ServiceHandler.createNotification(title: "收到來電", body: "收到\(sender)來電,是否顯示？", userInfo: _dic)
                    }
                    break
                    
                default:
                    break
                }
            }
        }
    }
}

extension AppDelegate : IMServiceDelegate {
    @objc func onImPhoneShow(sender:IMService, isDial:Bool, isVideo:Bool) {
        DispatchQueue.main.async() {
            // your UI update code
            if let _mainController = AppDelegate.mainController {
                _mainController.performSegue(withIdentifier: "startCall", sender: _mainController)
            }
        }
    }
    
    @objc func onImPhoneAction(sender:IMService, isVideo:Bool, args:Array<AnyObject>) {
        DispatchQueue.main.async() {
            switch(args[0].description!) {
            case "changevideo":
                if(args[1].description! == "0") {
                    utility.showAlert(message: "對方要求開啟視訊，是否開啟？", resolve: { (_) in
                        ServiceHandler.video(enabled: true)
                    })
                }
                break
                
            default:
                break
            }
        }
    }
}

