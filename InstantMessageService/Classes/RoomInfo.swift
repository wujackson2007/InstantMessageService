//
//  roomInfo.swift
//  eChat
//
//  Created by wujackson on 2017/12/20.
//  Copyright © 2017年 wujackson. All rights reserved.
//
import Foundation

public class RoomInfo : NSObject {
    private var _delegates:Dictionary<String, RoomInfoDelegate> = [:]
    private var _userType:String = ""
    private var _cid:String = ""
    private var _tNo:String = ""
    private var _tName:String = ""
    private var _oNo:String = ""
    private var _oName:String = ""
    private var _uNo:String = ""
    private var _uName:String = ""
    private var _eNo:String = ""
    private var _eName:String = ""
    private var _msg:String = ""
    private var _msgType:String = ""
    private var _phoneStartTime:Int = 0
    private var _phoneStopTime:Int = 0
    private var _phonePickupTime:Int = 0
    private var _phoneHungUpTime:Int = 0
    private var _isDial:Bool = false
    
    ///使用者類型: 1_求職者, 2_公司廠商
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
    ///廠商使用者名稱
    public var uName:String { get { return _uName } }
    ///職缺編號
    public var eNo:String { get { return _eNo } }
    ///職缺名稱
    public var eName:String { get { return _eName } }
    
    ///
    public var roomId:String { get { return "\(_oNo)_\(_tNo)_\(_uNo)" } }
    
    // 使用於訊息
    public var msg:String { get { return _msg } }
    /// 訊息類型 0_文字, 1_聲音, 2_影像
    public var msgType:String { get { return _msgType } }
    
    //通話相關
    /// 是否為撥打
    public var isDial:Bool { get { return _isDial } }
    /// 是否為視訊
    public var isVideo:Bool { get { return _msgType == "2" ? true : false } }
    /// 來電開始時間
    public var phoneStartTime:Int { get { return _phoneStartTime } }
    /// 來電結束時間
    public var phoneStopTime:Int { get { return _phoneStopTime } }
    /// 接聽時間
    public var phonePickupTime:Int { get { return _phonePickupTime } }
    /// 掛斷時間
    public var phoneHungUpTime:Int { get { return _phoneHungUpTime } }
    
    /// 設定當資料變動時通知
    public func setDelegate(key:String, delegate:RoomInfoDelegate) -> Void {
        guard _delegates[key] == nil else { return }
        _delegates[key] = delegate
    }
    
    public func rmDelegate(key:String) -> Void {
        guard _delegates[key] != nil else { return }
        _delegates.removeValue(forKey: key)
    }
    
    public func setInfo(userType:Any? = nil, cid:Any? = nil
        , tNo:Any? = nil, tName:Any? = nil
        , oNo:Any? = nil, oName:Any? = nil
        , uNo:Any? = nil, uName:Any? = nil
        , eNo:Any? = nil, eName:Any? = nil
        , msg:Any? = nil, msgType:Any? = nil, isDial:Any? = nil, phoneStartTime:Any? = nil, phoneStopTime:Any? = nil, phonePickupTime:Any? = nil, phoneHungUpTime:Any? = nil)
    {
        utility.synchronized(lock: self) {
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
            
            if(uName != nil) {
                _uName = (uName as AnyObject).description
                _fields.append("uName")
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
            
            if(phoneStartTime != nil) {
                _phoneStartTime = phoneStartTime as! Int
                _fields.append("phoneStartTime")
            }
            
            if(phoneStopTime != nil) {
                _phoneStopTime = phoneStopTime as! Int
                _fields.append("phoneStopTime")
            }
            
            if(phonePickupTime != nil) {
                _phonePickupTime = phonePickupTime as! Int
                _fields.append("phonePickupTime")
            }
            
            if(phoneHungUpTime != nil) {
                _phoneHungUpTime = phoneHungUpTime as! Int
                _fields.append("phoneHungUpTime")
            }
            
            if(isDial != nil) {
                _isDial = isDial as! Bool
                _fields.append("isDial")
            }
            
            if(_fields.count > 0) {
                for (_, _delegate) in _delegates {
                    _delegate.onChange(sender:self, fields:_fields)
                }
            }
        }
    }
}

@objc public protocol RoomInfoDelegate : NSObjectProtocol {
    @objc func onChange(sender:RoomInfo, fields:Array<String>) -> Void
}
