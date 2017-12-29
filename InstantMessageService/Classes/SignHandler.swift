//
//  signalR.swift
//  eChat
//
//  Created by 吳永誌 on 2017/10/15.
//  Copyright © 2017年 wujackson. All rights reserved.
//
import SignalR_ObjC

class SignHandler : NSObject {
    private var _delegate:SignHandlerDelegate?
    private var _connection:SRHubConnection?
    private var _proxy:SRHubProxyInterface?
    
    init(delegate:SignHandlerDelegate? = nil) {
        super.init()
        _delegate = delegate
    }
    
    deinit {
        stop()
    }
    
    var isConnected:Bool {
        get {
            if(_connection != nil) {
                if(_connection!.state == connected) {
                    return true
                }
            }
            
            return false
        }
    }
    
    func start(hubName:String, url:String, queryString:Dictionary<String,String>)  {
        if(_connection == nil && _proxy == nil) {
            _connection = SRHubConnection(urlString: url, queryString: queryString, useDefault: true)
            if(_connection != nil) {
                _proxy = _connection!.createHubProxy(hubName)
                _connection!.started = {
                    guard let _delegate = self._delegate else { return }
                    _delegate.onSignConnected(sender: self)
                }
                
                _connection!.closed = {
                    guard let _delegate = self._delegate else { return }
                    _delegate.onSignDisconnected(sender: self)
                }
                
                _connection!.received = { (message:Any) in
                    guard let _delegate = self._delegate else { return }
                    if let _data = message as? Dictionary<String, AnyObject> {
                        if let _method = _data["M"] as? String {
                            //var _args:Array<String> = []
                            var _argRaw:Array<AnyObject> = []
                            if let _arr:Array<AnyObject> = _data["A"] as? Array<AnyObject> {
                                for val in _arr {
                                    //_args.append(val.description)
                                    _argRaw.append(val)
                                }
                            }
                            _delegate.onSignReceived(sender: self, eventName: _method, args: _argRaw)
                        }
                    }
                }
                
                _connection!.start()
            }
        }
    }
    
    func stop() -> Void {
        if(_connection != nil) {
            _connection!.stop()
            _connection = nil
            _proxy = nil
        }
    }
    
    func invoke(_ method: String!, withArgs args: [Any]!, completionHandler block: ((Any?, Error?) -> Swift.Void)? = nil) -> Void {
        if(_proxy != nil) {
            _proxy!.invoke(method, withArgs: args, completionHandler: block)
        }
    }
}

/** ==============================================================================================
 * Protocol
 ============================================================================================== */
protocol SignHandlerDelegate : NSObjectProtocol {
    ///訊號連線觸發
    func onSignConnected(sender:SignHandler)
    ///訊號離線觸發
    func onSignDisconnected(sender:SignHandler)
    ///收到消息觸發
    func onSignReceived(sender:SignHandler, eventName:String, args:Array<AnyObject>)
}
