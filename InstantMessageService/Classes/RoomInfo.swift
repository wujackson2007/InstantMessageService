//
//  roomInfo.swift
//  eChat
//
//  Created by wujackson on 2017/12/20.
//  Copyright © 2017年 wujackson. All rights reserved.
//
import Foundation

public class RoomInfo : NSObject {
    private var _delegates:Array<RoomInfoDelegate> = []
    private var _userType:String = ""
    private var _cid:String = ""
    private var _tNo:String = ""
    private var _tName:String = ""
    private var _oNo:String = ""
    private var _oName:String = ""
    private var _uNo:String = ""
    private var _eNo:String = ""
    private var _eName:String = ""
    private var _msg:String = ""
    private var _msgType:String = ""
    private var _pickupTime:CLongLong = 0
    private var _hungUpTime:CLongLong = 0
    
    ///使用者類型: 1_公司廠商, 2_求職者
    public var userType:String { get { return _userType } }
    ///
    public var cid:String { get { return _cid } }
    ///求職者編號
    public var tNo:String { get { return _tNo } }
    ///求職者名稱
    public var tName:String { get { return _tName } }
    ///廠商編號
    public var oNo:String { get { return _oNo } }
    ///廠商名稱
    public var oName:String { get { return _oName } }
    ///廠商使用者編號
    public var uNo:String { get { return _uNo } }
    ///職缺編號
    public var eNo:String { get { return _eNo } }
    ///職缺名稱
    public var eName:String { get { return _eName } }
    
    // 使用於訊息
    public var msg:String { get { return _msg } }
    /// 訊息類型 0_文字, 1_聲音, 2_影像
    public var msgType:String { get { return _msgType } }
    /// 接聽時間
    public var pickupTime:CLongLong { get { return _pickupTime } }
    /// 掛斷時間
    public var hungUpTime:CLongLong { get { return _hungUpTime } }
    
    /// 設定當資料變動時通知
    public func setDelegate(delegate:RoomInfoDelegate) {
        _delegates.append(delegate)
    }
    
    public func setInfo(userType:Any? = nil, cid:Any? = nil, tNo:Any? = nil, tName:Any? = nil, oNo:Any? = nil, oName:Any? = nil, uNo:Any? = nil, eNo:Any? = nil, eName:Any? = nil
        , msg:Any? = nil, msgType:Any? = nil, pickupTime:Any? = nil, hungUpTime:Any? = nil)
    {
        var _fields:Array<String> = []
        if(userType != nil) {
            _userType = (userType as AnyObject).description
            _fields.append("userType")
        }
        
        if(cid != nil) {
            _cid = (cid as AnyObject).description
            _fields.append("cid")
        }
        
        if(tNo != nil) {
            _tNo = (tNo as AnyObject).description
            _fields.append("tNo")
        }
        
        if(tName != nil) {
            _tName = (tName as AnyObject).description
            _fields.append("tName")
        }
        
        if(oNo != nil) {
            _oNo = (oNo as AnyObject).description
            _fields.append("oNo")
        }
        
        if(oName != nil) {
            _oName = (oName as AnyObject).description
            _fields.append("oName")
        }
        
        if(uNo != nil) {
            _uNo = (uNo as AnyObject).description
            _fields.append("uNo")
        }
        
        if(eNo != nil) {
            _eNo = (eNo as AnyObject).description
            _fields.append("eNo")
        }
        
        if(eName != nil) {
            _eName = (eName as AnyObject).description
            _fields.append("empName")
        }
        
        if(msg != nil) {
            _msg = (msg as AnyObject).description
            _fields.append("msg")
        }
        
        if(msgType != nil) {
            _msgType = (msgType as AnyObject).description
            _fields.append("msgType")
        }
        
        if(_fields.count > 0) {
            for _delegate in _delegates {
                _delegate.onChange(sender:self, fields:_fields)
            }
        }
    }
}

public protocol RoomInfoDelegate : NSObjectProtocol {
    func onChange(sender:RoomInfo, fields:Array<String>) -> Void
}
