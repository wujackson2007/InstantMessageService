//
//  AppDelegate.swift
//  imTest
//
//  Created by 吳永誌 on 2017/12/24.
//  Copyright © 2017年 1111. All rights reserved.
//

import UIKit
import InstantMessageService

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    static var mainController:MainController?
    var window: UIWindow?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        
        ///
        _ = ServiceHandler.roomData
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
        ServiceHandler.serviceStop()
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
        ServiceHandler.serviceStart {
            ServiceHandler.savePushToken(tokenId: "b1b7a31da53873c3ef47f1ef9c629fab350d22024e711fcde1a5b9055140ff83", deviceId: "3DE8B84B-AE76-4EC0-8AFC-5C0AB89199FE")
        }
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
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

