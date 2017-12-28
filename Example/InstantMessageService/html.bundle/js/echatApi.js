String.prototype.trim = function () { return this.replace(/^\s\s*/, '').replace(/\s\s*$/, ''); };
String.prototype.ltrim = function () { return this.replace(/^\s+/, ''); };
String.prototype.rtrim = function () { return this.replace(/\s+$/, ''); };
String.prototype.left = function (n) { return this.substr(0, n); };
String.prototype.right = function (n) { return this.substr(this.length - n, n); };
String.prototype.format = function () {
    var O_VAL = this;

    for (var i = 0; i < arguments.length; i++) {
        var re = new RegExp("\\{" + i + "\\}", "g");
        O_VAL = O_VAL.replace(re, arguments[i]);
    }

    return O_VAL;
};

function trace(arg) {
    var now = (window.performance.now() / 1000).toFixed(3);
    console.log(now + ': ', arg);
}

function getChatApiHandler() {
    var _Handler = {
        hub: $.connection.eChatHub
		, fcmHandler: undefined
		, backgroundStream: undefined
		, rtcConnected:false
		, isTalkEnter:false
		, onLockControl:false
		, notifyArgs: {id:'', tNo:0, oNo:0, uNo:0, eNo:0, empName:''}
		, callStatus: {status:0, startTime:undefined, pickupTime:undefined, hangupTime:new Date()} //status:1_視訊,2_撥號
		, configuration: {
		    "iceServers": [
				{
				    "urls": [
						"turn:stun.1111.com.tw:3478"
						, "turn:stun.1111.com.tw:5349"
				    ],
				    "username": "stun",
				    "credential": "1111"
				}
		    ]
		}
		, mediaConstraints: {
		    video: { width: { exact: 320 }, height: { exact: 240 } },
		    audio: true
		}
		, offerOptions: { offerToReceiveAudio: 1, offerToReceiveVideo: 1 }
		, localStream: undefined
		, remoteStream: undefined
		, videoTracks: []
		, connection: {}
		, callbacks: []
		, onEvent: []
    };
	
    _Handler.invokeCallBacks = function (arr, param) {
        var i, obj;
        for (i=0; i<arr.length; i++) {
            try {
                arr[i].apply(arr[i], param);
            } catch (err) { }
        }
		
        for(i=_Handler.callbacks.length-1; i>-1; i--) {
            try {
                obj = _Handler.callbacks[i];
                if(obj.fn(param)) {
                    _Handler.callbacks.splice(i, 1);
                    obj.resolve(param);
                }
            } catch (err) { }
        }
    };
	
    _Handler.logOut = function (conn, message) {
        if (conn != null || conn != undefined) {
            var localID = "" + _Handler.hub.connection.id;
            var remoteID = "" + conn.signalId;
            console.log('['
				+ (localID.length > 8 ? localID.substring(0, 8) : "")
				+ '-'
				+ (remoteID.length > 8 ? remoteID.substring(0, 8) : "")
				+ ']'
				+ message);
        } else {
            console.log(message);
        }
    };
	
    _Handler.registerHub = function (eChatHub) {
        //廠商邀請使用者進會議室
        eChatHub.client.onNotifyUser = function (id, tNo, oNo, uNo, eNo, empName) {
            _Handler.invokeCallBacks(_Handler.onEvent, ['onNotifyUser', arguments]);
        };
		
        //收到消息
        eChatHub.client.onRTCMessage = function (id, data) {
            _Handler.getConnection(id).then(function(conn){
                var message = JSON.parse(data);
				
                // An SDP message contains connection and media information, and is either an 'offer' or an 'answer'
                if (message.candidate) {
                    if(message.candidate != null) {
                        //conn.addIceCandidate(new RTCIceCandidate(message.candidate));
                        conn.addIceCandidate(message.candidate);
                        _Handler.logOut(conn, 'adding ice candidate...');
                    }
                }
                else if (message.sdp) {
                    trace('onMessage \n' + message.sdp.sdp);
                    conn.setRemoteDescription(new RTCSessionDescription(message.sdp)).then(function () {
                        if (conn.remoteDescription.type == 'offer') {
                            _Handler.logOut(conn, 'received offer, sending answer...');

                            // Create an SDP response
                            setTimeout(function () {
                                _Handler.answerCreate(conn);
                            }, 2 * 1000);
							
                        } else if (conn.remoteDescription.type == 'answer') {
                            _Handler.logOut(conn, 'got an answer');
                        }
                    });
                }
            });
        };
		
        //Hub傳文字訊息給對方
        eChatHub.client.onTextMessage = function(id, tNo, oNo, uNo, eNo, MsgLog){
            _Handler.invokeCallBacks(_Handler.onEvent, ['onTextMessage', arguments]);
        }; 
		
        //離線訊息
        eChatHub.client.onOffLineMessage = function() {
            _Handler.invokeCallBacks(_Handler.onEvent, ['onOffLineMessage', arguments]);
        }
		
        //
        eChatHub.client.onRTCConnecting = function (id, roomId) {
            if(id != "") {
                _Handler.getConnection(id).then(function(conn) {
                    _Handler.offerCreate(conn).then(function(conn) {
                        //連接完成傳送
                        _Handler.hub.server.onRTCConnected(roomId);
                        _Handler.invokeCallBacks(_Handler.onEvent, ['onTalkEnter', [conn]]);
                    });
                });
            }
        };
		
        //上線
        eChatHub.client.onUserOnline = function(oNo, uNo) {
            _Handler.invokeCallBacks(_Handler.onEvent, ['onUserOnline', arguments]);
        }
		
        //離線
        eChatHub.client.onUserOffline = function(oNo, uNo) {
            _Handler.invokeCallBacks(_Handler.onEvent, ['onUserOffline', arguments]);
        }
		
        //已送出邀請 status:(0_不在線上, )
        eChatHub.client.onAskUser = function(status, roomId) {
        };
		
        eChatHub.client.onLockControl = function() {
            _Handler.onLockControl = true;
            $.connection.eChatHub.connection.stop();
            _Handler.invokeCallBacks(_Handler.onEvent, ['onLockControl', arguments]);
        }
		
        //進入會議室
        eChatHub.client.onTalkEnter = function(id, userName) {			
            _Handler.invokeCallBacks(_Handler.onEvent, ['onTalkEnter', arguments]);
        };
			
        //離開會議室
        eChatHub.client.onTalkLeave = function (id, isForce) {
            try {
                _Handler.invokeCallBacks(_Handler.onEvent, ['onTalkLeave', arguments]);
                var conn = _Handler.connection[id];	
                for (var s in conn.dataChannel)
                    try { conn.dataChannel[s].close(); } catch (err) { }
                conn.close();
            } catch (err) { }
            delete _Handler.connection[id];
            _Handler.logOut(undefined, '==========[onTalkLeave:' + id.substring(0, 8) + ']==========');
        };
		
        eChatHub.client.onUserStatus = function(jsonObj) {
            _Handler.invokeCallBacks(_Handler.onEvent, ['onUserStatus', arguments]);
        };
		
        //收到視訊通話
        eChatHub.client.onVideoCall = function(actMsg, Self) {
            _Handler.invokeCallBacks(_Handler.onEvent, ['onVideoCall', arguments]);
        }
		
        eChatHub.client.onPhoneCall = function(actMsg, Self) {
            _Handler.invokeCallBacks(_Handler.onEvent, ['onPhoneCall', arguments]);
        }
		
        eChatHub.client.debug = function (msg) {
            alert(msg);
        };
		
        eChatHub.client.onEcho = function (msg) {
            alert(msg);
        };
    };
	
    _Handler.signInit = function (fn) {
        return new Promise(function (resolve, reject) {
            $.ajax({
                type: "get",
                url: "/eChatHub/Login.ashx?u=1&msg=0",
                success: function(data) {
                    if(data.Token != undefined && data.Token.length > 0) {
                        var _hub = $.connection.eChatHub;
                        var _connection = _hub.connection;
						
                        //set query param
                        _connection.qs = {
                            "tNo": userInfo.tNo,
                            'Token': data.Token,
                            'Chat': 1
                        };
						
                        _Handler.registerHub(_hub);
						
                        _connection.start().done(function () {
                            console.log('connected to signal server[' + _hub.connection.id.substring(0, 8) + ']');
                            _hub.server.settUser(userInfo.tName);
                            resolve(_hub);
							
                        }).fail(function () {
                            console.log("Could not connect!");
                        });

                        _connection.disconnected(function () {
                            if(!_Handler.onLockControl) {
                                _connection.stop();
                                setTimeout(function () {
                                    _connection.start().done(function () {});
                                }, 5000); // Restart connection after 5 seconds.
                            }
                        });
						
                        if(fn != undefined)
                            fn(_hub);
                    }
                }
            });
        });
    };

    _Handler.initDataChannel = function (conn, channel) {
        if (conn.dataChannel[channel.label] == undefined)
            conn.dataChannel[channel.label] = channel;
		
        channel.onmessage = function (evMsg) {
            var obj, file;
            switch (evMsg.target.label) {
                case 'message':
                    _Handler.invokeCallBacks(_Handler.onEvent, ['onChatMessage', arguments]);
                    break;
            }
        };
    };

    _Handler.getConnectionId = function () {
        return _Handler.hub.connection.id;
    };

    _Handler.getPrettyTime = function (ticks) {
        var o_val = "";
        var diff = ticks;
        var days = Math.floor(diff / (1000 * 60 * 60 * 24));
        diff -=  days * (1000 * 60 * 60 * 24);
        var hours = Math.floor(diff / (1000 * 60 * 60));
        diff -= hours * (1000 * 60 * 60);
        var mins = Math.floor(diff / (1000 * 60));
        diff -= mins * (1000 * 60);
        var seconds = Math.floor(diff / (1000));
        diff -= seconds * (1000);
		
        if(hours > 0)
            o_val += hours + '時';

        if(mins > 0)
            o_val += mins + '分';	

        if(seconds > 0)
            o_val += seconds + '秒';	
		
        return o_val;
    };

    _Handler.getDiffTime = function (type, startTime, endTime) {
        var val;
        var diff = endTime.getTime() - startTime.getTime();
        switch(type) {
            case "days":
                val = Math.floor(diff / (1000 * 60 * 60 * 24));
                break;
				
            case "hours":
                val = Math.floor(diff / (1000 * 60 * 60));
                break;
				
            case "mins":
                val = Math.floor(diff / (1000 * 60));
                break;
				
            case "seconds":
                val = Math.floor(diff / (1000));
                break;
        }
        return val;
    }
	
    _Handler.getLocalStream	= function (constraints) {
        return new Promise(function (resolve, reject) {
            if(_Handler.localStream != undefined) {
                resolve(_Handler.localStream);
            }
            else {
                navigator.mediaDevices.getUserMedia(constraints).then(function (stream) {
                    _Handler.localStream = stream;
                    resolve(stream);
                }).catch(function (error) {
                    reject(error);
                });
            }
        });
    };

    _Handler.getConnection = function (id) {
        return new Promise(function (resolve, reject) {
            if(_Handler.connection[id] != undefined) {
                resolve(_Handler.connection[id]);
            } else {
                try {
                    // Create a new PeerConnection
                    var conn = new RTCPeerConnection(_Handler.configuration); // null = no ICE servers
                    conn.signalId = id;
                    conn.dataChannel = {};
                    conn.iceConnect = 0;
                    conn.trigger = 0;
                    _Handler.logOut(conn, 'creating RTCPeerConnection...');

                    conn.oniceconnectionstatechange = function(event) {
                        switch(event.currentTarget.iceConnectionState) {
                            case "checking":
                                event.currentTarget.iceConnect |= 1;
                                _Handler.rtcConnected = false;
                                _Handler.isTalkEnter = false;
                                break;
								
                            case "connected":
                                event.currentTarget.iceConnect |= 2;
                                _Handler.rtcConnected = true;
                                break;
								
                            case "completed":
                                event.currentTarget.iceConnect |= 4;
                                _Handler.rtcConnected = true;
                                break;
								
                            default:
                                event.currentTarget.iceConnect = 0;
                                _Handler.rtcConnected = false;
                                _Handler.isTalkEnter = false;
                                break;
                        }					
                        _Handler.logOut(event.currentTarget, "ICE state[" + event.currentTarget.iceConnect + "]" + event.currentTarget.iceConnectionState)
                    };
					
                    // send any ice candidates to the other peer
                    conn.onicecandidate = function (event) {
                        if(event.candidate != null)
                            _Handler.hub.server.rtcSend(event.currentTarget.signalId, JSON.stringify({ "candidate": event.candidate }));
                    };

                    // once remote stream arrives, show it in the remote video element
                    if(conn.ontrack != undefined) {
                        conn.ontrack = function (event) {
                            _Handler.invokeCallBacks(_Handler.onEvent, ['ontrack', [event]]);
                        };
                    } else {
                        conn.onaddstream = function (event) {
                            _Handler.invokeCallBacks(_Handler.onEvent, ['onaddstream', [event]]);
                        };
                    }

                    //收到遠端請求
                    conn.ondatachannel = function (event) {
                        _Handler.initDataChannel(conn, event.channel);
                    };
					
                    _Handler.connection[id] = conn;
                    resolve(_Handler.connection[id]);
                } catch (err) {
                    reject(err);
                }
            }
        });
    };

    _Handler.getRoomId = function () {
        return "{0}_{1}_{2}".format(_Handler.notifyArgs.oNo, _Handler.notifyArgs.tNo, _Handler.notifyArgs.uNo);
    };

    _Handler.getCallStatus = function () {
        return {
            isVideo: (_Handler.callStatus.status & 1) > 0
			, isDial: (_Handler.callStatus.status & 2) > 0
			, isPickup: _Handler.callStatus.pickupTime != undefined
			, isHangup:  _Handler.callStatus.hangupTime != undefined
        };
    };
	
    _Handler.offerCheck = function (conn, resolve, reject) {		
        setTimeout(function () {
            if(conn.trigger++ < 5){
                if((conn.iceConnect & 2) > 0)
                    resolve(conn);
                else
                    _Handler.offerCheck(conn, resolve, reject);
            }
        }, 2 * 1000);
    };
	
    _Handler.offerCreate = function (conn, options, fn) {
        return new Promise(function (resolve, reject) {
            if (conn != undefined) {
                _Handler.logOut(conn, 'start createOffer...');

                if (conn.dataChannel['message'] == undefined)
                    _Handler.initDataChannel(conn, conn.createDataChannel('message', null));
				
                // Create an offer to send our peer
                conn.createOffer(options != undefined ? options : _Handler.offerOptions).then(function (desc) {
                    if (fn != undefined)
                        fn(conn, desc);
						
                    // Set the generated SDP to be our local session description
                    conn.setLocalDescription(desc).then(function () {
                        // And send it to our peer, where it will become their RemoteDescription
                        conn.trigger = 0;
                        //conn.iceConnect = 0;
                        _Handler.hub.server.rtcSend(conn.signalId, JSON.stringify({ "sdp": desc }));
                        _Handler.offerCheck(conn, resolve, reject);
                    });
                }, function (error) { 
                    reject(error); 
                });
            }
        });
    };
	
    _Handler.answerCreate = function (conn) {
        if (conn != undefined) {
            // Create an SDP response
            conn.createAnswer().then(function (desc) {
                // Which becomes our local session description
                conn.setLocalDescription(desc).then(function () {
                    // And send it to the originator, where it will become their RemoteDescription
                    _Handler.hub.server.rtcSend(conn.signalId, JSON.stringify({ 'sdp': conn.localDescription }));
                });
            }, function (error) { 
                reject(error); 
            });
        }
    };
	
    _Handler.mediaTracksChange = function (conn, isLocal, type, enabled) {
        _Handler.mediaTracksGet(conn, isLocal).forEach(function(t) {
            if(t.kind == type)
                t.enabled = enabled;
        });
    };

    _Handler.mediaTracksGet	= function (conn, isLocal) {
        var o_val = [];
        if (typeof window === 'object' && window.RTCPeerConnection && ('getSenders' in window.RTCPeerConnection.prototype)) {
            var i;
            var arrObj = isLocal ? conn.getSenders() : conn.getReceivers();
            for (i=0; i<arrObj.length; i++) 
                o_val.push(arrObj[i].track);
        }
        else {
            var _stream, _track;
            for (_stream of isLocal ? conn.getLocalStreams() : conn.getRemoteStreams()) {
                for (_track of _stream.getTracks()) 
					o_val.push(_track);
                }
        }
        return o_val;
    };

    _Handler.mediaTracksRemove = function (conn) {	
        if (typeof window === 'object' && window.RTCPeerConnection && ('getSenders' in window.RTCPeerConnection.prototype)) {
            var i, j, arrRtp, Rtp;
            var arrObj = [conn.getSenders(), conn.getReceivers()];
            for (i=0; i<arrObj.length; i++) {
                arrRtp = arrObj[i];
                for (j=0; j<arrRtp.length; j++) {
                    Rtp = arrRtp[j];
                    Rtp.track.stop();
                    if(i == 0)
                        conn.removeTrack(Rtp);
                }
            }
        }
        else {
            var arrStream, stream, track;
            for (arrStream of [conn.getLocalStreams(), conn.getRemoteStreams()]) {
				for (stream of arrStream) {
					for (track of stream.getTracks()) { 
						track.stop();
            }
        conn.removeStream(stream);
    }
}
}
_Handler.localStream = undefined;
};
	
_Handler.srChatSend = function (arrId, val) {
    var obj, isSend = true;
    if(val instanceof Object) {
        var _callStatus = _Handler.getCallStatus();
        obj = {
            userId: _Handler.getConnectionId()
            , MsgType: _callStatus.isVideo ? 2 : 1
            , userData: ""
            , dateIn: $.format.date(new Date(), "yyyy-MM-dd HH:mm:ss")
            , DuringTime: _callStatus.isPickup ? _Handler.getDiffTime("seconds", val.pickupTime, val.hangupTime) : 0
        };
			
    } else {
        obj = {
            userId: _Handler.getConnectionId()
            , MsgType:0
            , userData: val.trim()
            , dateIn: $.format.date(new Date(), "yyyy-MM-dd HH:mm:ss")
        };
			
        if(obj.userData == '')
            isSend = false;
    }
		
    if(isSend) {
        //傳送到SERVER
        _Handler.srSendMsgLog(val);

        //傳送到用戶端
        if(obj.MsgType != 0) {
            var id;
            var sendData = JSON.stringify(obj);
            for(id in arrId) {
                _Handler.getConnection(id).then(function (conn) {
                    var channel = conn.dataChannel["message"];
                    if(channel != undefined && channel.readyState == "open")
                        channel.send(sendData);
                });
            }
        }
    }
};

_Handler.srSendMsgLog = function (val) {
    var MsgType = 0, TalkJSON = "", FileJSON = "";
    if(val instanceof Object) {
        var _callStatus = _Handler.getCallStatus();
        MsgType = _callStatus.isVideo ? 2 : 1
        TalkJSON = JSON.stringify({
            'start': $.format.date(_callStatus.isPickup ? val.pickupTime : val.startTime, "yyyy/MM/dd HH:mm:ss")
            ,'end': $.format.date(_callStatus.isPickup ? val.hangupTime : val.startTime, "yyyy/MM/dd HH:mm:ss")
            ,'duringTime':0
        });
			
        val = "";
    }
		
    _Handler.hub.server.sendMsgLog(val
        , MsgType
        , _Handler.notifyArgs.oNo
        , _Handler.notifyArgs.tNo
        , _Handler.notifyArgs.uNo
        , _Handler.notifyArgs.eNo
        , TalkJSON
        , FileJSON);
};

_Handler.srDoCallUser = function (type, ActMsg) {
    if(type == "1")
        _Handler.hub.server.doVideoCall(_Handler.getRoomId(), JSON.stringify({ act: ActMsg }));
    else
        _Handler.hub.server.doPhoneCall(_Handler.getRoomId(), JSON.stringify({ act: ActMsg }));
};
	
_Handler.srNotifyUser = function (fn) {
    return new Promise(function (resolve, reject) {
        _Handler.callbacks.push({resolve:resolve, reject:reject, fn:function(args) {
            if(_Handler.rtcConnected && _Handler.isTalkEnter)
                return true;
		
            return false;
        }});
			
        _Handler.hub.server.notifyUser(2
            , _Handler.notifyArgs.tNo
            , _Handler.notifyArgs.oNo
            , _Handler.notifyArgs.eNo
            , _Handler.notifyArgs.uNo
            , _Handler.notifyArgs.empName);
    });
};
	
_Handler.srGetUserStatus = function () {
    _Handler.hub.server.getUserStatus(2, _Handler.notifyArgs.oNo, _Handler.notifyArgs.uNo, _Handler.notifyArgs.tNo, 0);
};
	
_Handler.onSrNotifyUser = function (id, tNo, oNo, uNo, eNo, empName) {
    _Handler.invokeCallBacks(_Handler.onEvent, ['onNotifyUser', arguments]);
};

return _Handler;
}