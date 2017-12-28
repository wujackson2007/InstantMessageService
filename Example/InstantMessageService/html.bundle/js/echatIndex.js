var $ToolChact = undefined,
    $videobox = undefined,
    $facebox = undefined,
    $faceself = undefined,
	$chactbox = undefined,
    $control = undefined,
    $sidebar = undefined,
    $setico = undefined,
	$callStatus = undefined,
	$callTime = undefined,
	$soundtool = undefined,
	$callBox = undefined,
	$messageBox = undefined,
	$btnSend = undefined,
	$btnMenuShow = undefined,
	$btnCallMessage = undefined,
	$btnCallVoice = undefined,
	$btnCallVideo = undefined,
	$btnVideo = undefined,
	$btnChangeVideo = undefined,
	$btnAudio = undefined,
	$btnVoiceCtrl = undefined,
	$btnPickup = undefined,
	$btnHangup = undefined,
	$userStatus = undefined,
	$chactler = undefined,
	$msgInput = undefined,
	localVideo = undefined,
	remoteVideo = undefined,
	remoteLogo = undefined,
    aa = undefined
;

var _apiHandler = getChatApiHandler();
var audioCtx = new (window.AudioContext || window.webkitAudioContext)();
var ringtoneSource;
var messageLoop = [];
var chatLoop = {};
var _chatBoxOnScroll = false;
var _inviteTimeOut = 30;
var connectMessage = {
    Invite: '<span class="notice">正在邀請對方進行即時交談...</span>'
	, InviteTimeOut: '<span class="notice">邀請逾時</span>，您可以傳送【離線訊息】。'
	, OnInvite: '<span class="notice">收到對方邀請進行即時交談...</span>'
	, TalkEnter: '<span class="notice">對方【<label style="color:green">已上線</label>】</span>，您可以傳送【即時訊息】。'
	, TalkLeave: '<span class="notice">對方【已離線】</span>，您可以傳送【離線訊息】。'
};

$(document).ready(function () {
    _apiHandler.notifyArgs = _notifyArgs;

    initBase();

    _apiHandler.signInit().then(function (eChatHub) {
        getFcmHandler().then(function (handler) {
            _apiHandler.fcmHandler = handler;
            handler.savePushToken = function (fcmToken) {
                eChatHub.server.savePushToken(fcmToken, "");
            };
        });

        _apiHandler.srGetUserStatus();

        if (_apiHandler.notifyArgs.id != '') {
            _apiHandler.onSrNotifyUser(_apiHandler.notifyArgs.id
				, _apiHandler.notifyArgs.tNo
				, _apiHandler.notifyArgs.oNo
				, _apiHandler.notifyArgs.uNo
				, _apiHandler.notifyArgs.eNo
				, _apiHandler.notifyArgs.empName);
        }
    });

    if (_apiHandler.notifyArgs.eNo == '' || _apiHandler.notifyArgs.uNo == '' || _apiHandler.notifyArgs.tNo == '') {
        $('[data-cmd="btnCallMessage"],[data-cmd="btnCallVoice"],[data-cmd="btnCallVideo"],[data-cmd="btnSend"]').hide();
        $('[data-cmd="btnMenuShow"]').trigger('click');
        chatLogShow();
    }
    else {
        $('.message-box').show();

        if (_apiHandler.notifyArgs.empName != '') {
            $('#user-status').show();
        }

        //讀取離線訊息
        $.ajax({
            type: "get",
            url: location.href,
            data: "actFun=getList",
            success: function (data) {
                chatMsgShow(data);
                chatLogShow();
                //connectMessageShow(connectMessage.TalkLeave);
            }
        });
    }
});

function initBase() {
    $ToolChact = $('#ToolChact');
    $videobox = $('.videobox');
    $facebox = $('.facebox');
    $faceself = $('.faceself');
    $chactbox = $('.chactbox');
    $control = $('.control');
    $sidebar = $('#sidebar');
    $callStatus = $('.call-status');
    $callTime = $('.call-time');
    $setico = $('.setico');
    $soundtool = $('.soundtool'); //音訊控制器
    $callBox = $('.call-box');
    $messageBox = $('.message-box');
    localVideo = $('#localVideo')[0];
    remoteVideo = $('#remoteVideo')[0];
    remoteLogo = $('#remoteLogo')[0];
    $btnCallMessage = $('[data-cmd="btnCallMessage"]');
    $btnCallVoice = $('[data-cmd="btnCallVoice"]');
    $btnCallVideo = $('[data-cmd="btnCallVideo"]');
    $btnVideo = $('[data-cmd="btnVideo"]');
    $btnChangeVideo = $('[data-cmd="btnChangeVideo"]');
    $btnAudio = $('[data-cmd="btnAudio"]');
    $btnVoiceCtrl = $('[data-cmd="btnVoiceCtrl"]');
    $btnPickup = $('[data-cmd="btnPickup"]');
    $btnHangup = $('[data-cmd="btnHangup"]');
    $userStatus = $('#user-status');
    $chactler = $('.chactler');
    $msgInput = $('#msgInput');
    $btnMenuShow = $('[data-cmd="btnMenuShow"]');
    $btnSend = $('[data-cmd="btnSend"]');

    //檢查遠端視訊狀態
    //remoteVideo.addEventListener("loadeddata", checkRemoteVideo);

    $(window).resize(function () {
        chatResize();
    }).resize();

    $sidebar.find('.list > li > a').on('click', function () {
        $(this).parents('li:eq(0)').find('ul:eq(0)').toggleClass('toggle');
    });

    $('#bkOrgan').autocomplete({
        serviceUrl: 'organList.asp?limit=10',
        paramName: 'query',
        transformResult: function (response) {
            var data = jQuery.parseJSON(response);
            return {
                suggestions: $.map(data, function (dataItem) {
                    return { value: dataItem.val, data: dataItem.key };
                })
            };
        },
        onSelect: function (data) {
            $(this).parent().find('#bkOrganNo').val(data.data);
        }
    });

    $('[data-cmd]').on('click', function (ev) {
        var _target = ev.currentTarget;
        var _cmd = $(_target).attr('data-cmd');
        var _tag, _fn;
        switch (_cmd) {
            case "btnPickup": //接聽
                _apiHandler.srDoCallUser(_apiHandler.getCallStatus().isVideo ? "1" : "0", 'pickup');
                break;

            case "btnHangup": //掛斷
                callHangup();
                _apiHandler.srDoCallUser(_apiHandler.getCallStatus().isVideo ? "1" : "0", 'hangup');
                break;

            case "btnVoiceCtrl": //音量調整
                $soundtool.slideToggle(10);
                break;

            case "btnMenuShow": //對話紀錄展開
                $btnMenuShow.find('span').hide();
                $sidebar.animate({ left: 0, display: 'block' }, 100, function () { });
                break;

            case "btnMenuHide": //對話紀錄關閉
                $sidebar.animate({ left: -1 * $sidebar.width(), display: 'block' }, 100, function () { });
                break;

            case "btnSend": //訊息按鈕
                $msgInput.each(function () {
                    var msg = $(this).val();
                    if (msg != '') {
                        chatMsgShow([{ msgType: 0, whoTalk: 1, msgLog: msg, dateIn: $.format.date(new Date(), "yyyy-MM-dd HH:mm:ss") }]);
                        _apiHandler.srChatSend(_apiHandler.connection, msg);
                        $(this).val('');
                    }
                });
                break;

            case "btnCallMessage": //即時訊息
            case "btnCallVideo": //視訊通話
            case "btnCallVoice": //語音通話				
                if (_cmd == "btnCallMessage") {
                    messageBoxShow();
                }
                else {
                    if (_apiHandler.getCallStatus().isHangup) {
                        _apiHandler.getLocalStream(_apiHandler.mediaConstraints).then(function (stream) {
                            _apiHandler.callStatus = { status: _cmd == "btnCallVideo" ? 3 : 2, startTime: new Date(), pickupTime: undefined, hangupTime: undefined };

                            if (_apiHandler.rtcConnected) {
                                _apiHandler.srDoCallUser(_cmd == "btnCallVideo" ? "1" : "0", 'dial');
                            }
                            else {
                                _apiHandler.srNotifyUser().then(function () {
                                    _apiHandler.srDoCallUser(_cmd == "btnCallVideo" ? "1" : "0", 'dial');
                                });
                            }

                        }).catch(function (error) { checkMediaError(error); });
                    }
                    callBoxShow();
                }
                break;

            case "btnChangeVideo": //視訊切換
                _apiHandler.srDoCallUser(_apiHandler.getCallStatus().isVideo ? "1" : "0", 'changevideo');
                break;

            case "btnVideo": //視訊開啟/關閉
            case "btnAudio": //音訊開啟/關閉
                _tag = _cmd == "btnVideo" ? "video" : "audio";
                $(_target).toggleClass('bgDisabled');
                $(_target).find('.' + _tag).toggleClass(_tag + '-disabled');

                for (var k in _apiHandler.connection) {
                    _apiHandler.getConnection(k).then(function (conn) {
                        _apiHandler.mediaTracksChange(conn, true, _tag, $(_target).hasClass('bgDisabled') ? false : true);
                    });
                }
                break;
        }
    });

    _apiHandler.onEvent.push(function (type, args) {
        switch (type) {
            case "onTextMessage":
                //id, tNo, oNo, uNo, eNo, MsgLog
                if (_apiHandler.notifyArgs.tNo == args[1] &&
					_apiHandler.notifyArgs.oNo == args[2] &&
					_apiHandler.notifyArgs.uNo == args[3] &&
					_apiHandler.notifyArgs.eNo == args[4]) {
                    chatMsgShow([{
                        msgType: 0
						, whoTalk: 0
						, msgLog: args[5]
						, dateIn: $.format.date(new Date(), "yyyy-MM-dd HH:mm:ss")
						, duringTime: 0
                    }]);
                }
                break;

            case "onChatMessage": //收到即時訊息
                var data = JSON.parse(args[0].data);
                chatMsgShow([{
                    msgType: data.MsgType
					, whoTalk: 0
					, msgLog: data.userData
					, dateIn: data.dateIn
					, duringTime: data.DuringTime
                }]);
                break;

            case "onUserStatus":
                if (_apiHandler.notifyArgs.tNo == args[0].tNo &&
					_apiHandler.notifyArgs.oNo == args[0].oNo &&
					_apiHandler.notifyArgs.uNo == args[0].uNo) {

                    if (args[0].Status == 1)
                        $userStatus.attr('class', 'online');
                    else
                        $userStatus.attr('class', 'leaveline');
                }
                break;

            case "onUserOnline":
                if (_apiHandler.notifyArgs.oNo == args[0] &&
					_apiHandler.notifyArgs.uNo == args[1]) {
                    $userStatus.attr('class', 'online');
                }
                break;

            case "onUserOffline":
                if (_apiHandler.notifyArgs.oNo == args[0] &&
					_apiHandler.notifyArgs.uNo == args[1]) {
                    $userStatus.attr('class', 'leaveline');
                }
                break;

            case "onOffLineMessage":
                chatLogShow();
                $btnMenuShow.find('span').show();
                break;

            case "onNotifyUser": //收到邀請
                if (_apiHandler.notifyArgs.eNo == args[4] && _apiHandler.notifyArgs.uNo == args[3]) {
                    //connectMessageShow(connectMessage.OnInvite);
                    _apiHandler.notifyArgs.id = args[0];
                    _apiHandler.notifyArgs.tNo = args[1];
                    _apiHandler.notifyArgs.oNo = args[2];
                    _apiHandler.notifyArgs.uNo = args[3];
                    _apiHandler.notifyArgs.eNo = args[4];
                    _apiHandler.notifyArgs.empName = args[5];
                    _apiHandler.hub.server.doRTCConnection(_apiHandler.notifyArgs.id);
                    setTimeout(function () {
                        if (!_apiHandler.rtcConnected || !_apiHandler.isTalkEnter) {
                            //onSrTalkLeave(_apiHandler.notifyArgs.id, true);
                            //connectMessageShow(connectMessage.InviteTimeOut);
                        }
                    }, 1000 * _inviteTimeOut);
                }
                else {
                    messageLoop.push({
                        message: '<a style="color:#fff" href="javascript:void(0)" data-href="/Chact_Jobs/index.asp?cid={0}&eNo={1}&uNo={2}" onclick="inviteOpen(this)">收到邀請：{3}</a>'.format(args[0], args[4], args[3], args[5])
						, time: 5000
                    });
                }
                break;

            case "onLockControl":
                alert("連線超過上限！");
                break;

            case "onTalkEnter": //進入會議室
                _apiHandler.isTalkEnter = true;
                /*
				$userStatus.attr('class', 'online');
				if($messageBox.css('display') == 'block')
					$btnCallMessage.css("visibility", "hidden");
				
				connectMessageShow(connectMessage.TalkEnter);
				*/
                break;

            case "onTalkLeave": //離開會議室
                _apiHandler.isTalkEnter = false;
                /*
				$userStatus.attr('class', 'leaveline');
				if($messageBox.css('display') == 'block')
					$btnCallMessage.css("visibility", "visible");
				
				if(args[1] == undefined)
					connectMessageShow(connectMessage.TalkLeave);
				*/
                break;

            case "ontrack":
            case "onaddstream":
                _apiHandler.remoteStream = args[0].stream;
                break;

            case "onPhoneCall": //語音通話事件
            case "onVideoCall": //視訊通話事件
                switch (args[0]) {
                    case "dial": //撥號
                        _apiHandler.getLocalStream(_apiHandler.mediaConstraints).then(function (stream) {
                            for (var k in _apiHandler.connection) {
                                _apiHandler.getConnection(k).then(function (conn) {
                                    conn.addStream(stream);
                                    if (!_apiHandler.getCallStatus().isVideo)
                                        _apiHandler.mediaTracksChange(conn, true, "video", false);
                                });
                            }
                        }).catch(function (error) { checkMediaError(error); });
                        break;

                    case "show": //來電
                        _apiHandler.callStatus = { status: (type == "onVideoCall" ? 1 : 0), startTime: new Date(), pickupTime: undefined, hangupTime: undefined };
                        callBoxShow();
                        break;

                    case "pickup": //接聽
                        callPickup();
                        break;

                    case "hangup": //掛斷
                        callHangup();
                        break;

                    case "changevideo":
                        if (args[1] != 0 || (args[1] == 0 && confirm("對方要求開啟視訊，是否開啟？"))) {
                            _apiHandler.callStatus.status |= 1;
                            _apiHandler.getLocalStream(_apiHandler.mediaConstraints).then(function (stream) {
                                localVideo.srcObject = stream;
                                for (var k in _apiHandler.connection) {
                                    _apiHandler.getConnection(k).then(function (conn) {
                                        _apiHandler.mediaTracksChange(conn, true, "video", true);
                                    });
                                }
                                checkRemoteVideo(false);
                            }).catch(function (error) { checkMediaError(error); });
                        }
                        else {
                            checkRemoteVideo(true);
                        }
                        break;
                }
                break;
        }
    });

    $chactbox.on('scroll', function (ev) {
        if (!_chatBoxOnScroll && this.scrollTop == 0) {
            _chatBoxOnScroll = true;
            if ($chactbox.data('end') != '1') {
                var $oSCROLLMSG = $('<li class="scrollMsg"><img src="images/loading.gif" style="margin:0 auto;width:40px;height:40px;" /></li>');
                $chactbox.prepend($oSCROLLMSG);

                setTimeout(function () {
                    var msgDate = $chactbox.find('.dateline:eq(0)').data('date');
                    $.ajax({
                        type: "get",
                        url: location.href,
                        data: { actFun: "getList", msgDate: msgDate },
                        complete: function () { _chatBoxOnScroll = false; },
                        success: function (data) {
                            if (data.length > 0) {
                                $chactbox.prop("scrollTop", 10);
                                chatMsgShow(data, 'up');
                            } else {
                                $chactbox.data('end', "1");
                            }

                            $oSCROLLMSG.remove();
                        }
                    });
                }, 1000);
            }
        }
    });

    $("body").everyTime('1s', 'backgroundProcess', backgroundProcess, 0);

    $msgInput.keypress(function (e) {
        code = (e.keyCode ? e.keyCode : e.which);
        if (code == 13) {
            if (!e.shiftKey) {
                e.preventDefault();
                $btnSend.trigger("click");
            }
        }
    });

    //取封鎖清單
    jsChatOrganHideUpd($('#bkOrganAdd'));

    //顯示訊息駐列
    messageLoopShow();

    getRingtoneSource();

    //
    chatResize();
}

function getRingtoneSource() {
    ringtoneSource = audioCtx.createBufferSource();
    var request = new XMLHttpRequest();
    request.open('GET', 'images/ringtone.mp3', true);
    request.responseType = 'arraybuffer';
    request.onload = function () {
        var audioData = request.response;
        audioCtx.decodeAudioData(audioData, function (buffer) {
            audioCtx.suspend();
            ringtoneSource.buffer = buffer;
            ringtoneSource.connect(audioCtx.destination);
            ringtoneSource.loop = true;
            ringtoneSource.start(0);
        }, function (e) { console.log("Error with decoding audio data" + e.err); });
    }

    request.send();
}

function chatResize() {
    //sidebar 側邊欄等高
    setTimeout(function () {
        var numHeight;

        //767以下設定
        if (IsMobile) {
            $ToolChact.height($(window).height());
            numHeight = $(window).height() - 60;
            $chactler.addClass('cfixed');
        } else {
            numHeight = $ToolChact.height() - 60;
        }

        $callBox.css('height', numHeight);
        $messageBox.css('height', numHeight);
        $chactbox.css('height', numHeight - 65);

        $videobox.css('height', numHeight);
        $sidebar.find('.list').css('height', numHeight);
    }, 1000);
}

function callPickup() {
    if (!_apiHandler.getCallStatus().isPickup) {
        _apiHandler.callStatus.pickupTime = new Date();

        _apiHandler.getLocalStream(_apiHandler.mediaConstraints).then(function (stream) {
            var _callStatus = _apiHandler.getCallStatus();
            for (var k in _apiHandler.connection) {
                _apiHandler.getConnection(k).then(function (conn) {
                    if (_callStatus.isDial) {
                        return new Promise(function (resolve, reject) { resolve(conn); });
                    } else {
                        //接電話
                        conn.addStream(stream);

                        //非視訊的話關閉影像
                        if (!_callStatus.isVideo)
                            _apiHandler.mediaTracksChange(conn, true, "video", false);

                        return _apiHandler.offerCreate(conn, { offerToReceiveAudio: 1, offerToReceiveVideo: 1, iceRestart: true });
                    }
                }).then(function (conn) {
                    if (_callStatus.isVideo)
                        localVideo.srcObject = stream;
                });
            }
        }).catch(function (error) { checkMediaError(error); });
    }
}

function callHangup() {
    if (_apiHandler.callStatus.hangupTime == undefined) {
        _apiHandler.callStatus.hangupTime = new Date();

        //撥號方須傳送撥號資訊
        var _callStatus = _apiHandler.getCallStatus();
        if (_callStatus.isDial) {
            _apiHandler.srChatSend(_apiHandler.connection, _apiHandler.callStatus);
            chatMsgShow([{
                msgType: _callStatus.isVideo ? 2 : 1
				, whoTalk: _callStatus.isDial ? 1 : 0
				, msgLog: ""
				, duringTime: _callStatus.isPickup ? _apiHandler.getDiffTime("seconds", _apiHandler.callStatus.pickupTime, _apiHandler.callStatus.hangupTime) : 0
				, dateIn: $.format.date(new Date(), "yyyy-MM-dd HH:mm:ss")
            }]);
        }

        localVideo.srcObject = remoteVideo.srcObject = null;
        checkRemoteVideo(true);
        _apiHandler.remoteStream = undefined;
        for (var k in _apiHandler.connection) {
            _apiHandler.getConnection(k).then(function (conn) {
                _apiHandler.mediaTracksRemove(conn);
            });
        }

        //
        messageBoxShow();
    }
}

function backgroundProcess() {
    var _callStatus = _apiHandler.getCallStatus();

    //鈴聲處理
    if (_callStatus.isPickup || _callStatus.isHangup) {
        if (audioCtx.state != "suspended")
            audioCtx.suspend();
    }
    else {
        if (audioCtx.state != "running")
            audioCtx.resume();
    }

    if ($callBox.css('display') == 'block') {
        var i, numFill = 0;
        if (_callStatus.isPickup) {
            //接聽中
            $btnAudio.show();
            $btnVoiceCtrl.show();
            $btnPickup.hide();

            if (_callStatus.isVideo) {
                $btnVideo.show();
                $btnChangeVideo.hide();
            }
            else {
                $btnVideo.hide();
                $btnChangeVideo.show();
            }

            if (localVideo.srcObject == null)
                $(localVideo).parent().hide();
            else
                $(localVideo).parent().show();

            if (remoteVideo.srcObject == null && _apiHandler.remoteStream != undefined) {
                remoteVideo.srcObject = _apiHandler.remoteStream;
                checkRemoteVideo(!_callStatus.isVideo);
            }

            $callStatus.html("");

            if (_apiHandler.callStatus.pickupTime != undefined)
                $callTime.html(timeDiff(_apiHandler.callStatus.pickupTime));
        }
        else {
            //撥號中
            $btnVideo.hide();
            $btnAudio.hide();
            $btnVoiceCtrl.hide();
            $btnChangeVideo.hide();
            $(localVideo).parent().hide();
            if (_callStatus.isDial) {
                $btnPickup.hide();
                $callStatus.html(_callStatus.isVideo ? '視訊撥號中' : '語音撥號中');
            } else {
                $btnPickup.show();
                $callStatus.html(_callStatus.isVideo ? '視訊來電' : '語音來電');
            }

            if (_apiHandler.callStatus.startTime != undefined)
                $callTime.html(timeDiff(_apiHandler.callStatus.startTime));
        }
    }
}

function timeDiff(time) {
    var date1 = new Date(time);
    var date2 = new Date();

    var diff = date2.getTime() - date1.getTime();
    var days = Math.floor(diff / (1000 * 60 * 60 * 24));
    diff -= days * (1000 * 60 * 60 * 24);

    var hours = Math.floor(diff / (1000 * 60 * 60));
    diff -= hours * (1000 * 60 * 60);

    var mins = Math.floor(diff / (1000 * 60));
    diff -= mins * (1000 * 60);

    var seconds = Math.floor(diff / (1000));
    diff -= seconds * (1000);

    return ('00' + hours).right(2) + ':' + ('00' + mins).right(2) + ':' + ('00' + seconds).right(2);
}

function checkRemoteVideo(disabled) {
    if (!disabled) {
        $(remoteLogo).hide();
        $(remoteVideo).show();
    }
    else {
        $(remoteLogo).show();
        $(remoteVideo).hide();
    }
    /*
	var _v = {
		disabled: remoteVideo.srcObject != null ? false : true
		, tracks: remoteVideo.srcObject != null ? remoteVideo.srcObject.getVideoTracks() : undefined
		, i:0
		, j:0
		, canvas: document.createElement('canvas')
		, ctx: undefined
		, data: undefined
		, imageData: undefined
		, show:function(disabled) {
			if(!disabled) {
				$(remoteLogo).hide();
				$(remoteVideo).show();
			}
			else {
				$(remoteLogo).show();
				$(remoteVideo).hide();
			}
		}
	};
	
	if(!_v.disabled) {
		_v.disabled = true;
		var imageCapture = new ImageCapture(_v.tracks[0]);
		imageCapture.grabFrame().then(function(imageBitmap) {
			_v.ctx = _v.canvas.getContext('2d');
			_v.canvas.width = imageBitmap.width;
			_v.canvas.height = imageBitmap.height;
			_v.ctx.drawImage(imageBitmap, 0, 0);
			_v.imageData = _v.ctx.getImageData(0, 0, _v.canvas.width, _v.canvas.height);
			_v.data = _v.imageData.data;
			for (_v.j = 0; _v.j < _v.data.length; _v.j += 4) {
				if(!(_v.data[_v.j] == 0 && _v.data[_v.j+1] == 0 && _v.data[_v.j+2] == 0)) {
					_v.disabled = false;
					break;
				}
			}
			
			_v.show(_v.disabled);
		});
	}
	else {
		_v.show(_v.disabled);
	}
	*/
}

function checkMediaError(error) {
    switch (error.name) {
        case "ConstraintNotSatisfiedError":
            infoBox('視訊格式不支援！');
            break;

        case "NotAllowedError":
        case "PermissionDeniedError":
            infoBox('未允許視訊或是音訊裝置，無法進行功能！');
            break;

        case "NotFoundError":
            infoBox('未偵測到視訊或是音訊裝置，無法進行功能！');
            break;

        default:
            infoBox('視訊或是音訊裝置，無法進行功能！');
            break;
    }
}

function messageBoxShow() {
    var _callStatus = _apiHandler.getCallStatus();

    //上方按鈕狀態
    $btnCallMessage.css("visibility", "hidden");
    if (_callStatus.isHangup) {
        $btnCallVoice.css("visibility", "visible");
        $btnCallVideo.css("visibility", "visible");
    }
    else {
        if (_callStatus.isVideo) {
            $btnCallVoice.css("visibility", "hidden");
            $btnCallVideo.css("visibility", "visible");
        }
        else {
            $btnCallVoice.css("visibility", "visible");
            $btnCallVideo.css("visibility", "hidden");
        }
    }

    $soundtool.hide();
    if (IsMobile) {
        $callBox.removeClass('w37');
        $messageBox.addClass('fullW');
        $callBox.hide();
        $messageBox.show();
    }
    else {
        if (_apiHandler.getCallStatus().isHangup) {
            $callBox.removeClass('w37');
            $messageBox.addClass('fullW');
            $callBox.hide();
            $messageBox.show();
        }
        else {
            $callBox.addClass('w37');
            $messageBox.removeClass('fullW');
            $messageBox.show();
        }
    }
}

function callBoxShow() {
    return new Promise(function (resolve, reject) {
        _apiHandler.getLocalStream(_apiHandler.mediaConstraints).then(function (stream) {
            $callBox.removeClass('w37');
            $messageBox.addClass('fullW');

            //上方按鈕狀態
            $btnCallMessage.css("visibility", "visible");
            $btnCallVoice.css("visibility", "hidden");
            $btnCallVideo.css("visibility", "hidden");

            $messageBox.hide();
            $callBox.show();
            backgroundProcess();
            resolve(stream);
        }).catch(function (error) {
            checkMediaError(error);
            reject(error);
        });
    });
}

function messageLoopShow() {
    if (messageLoop.length > 0) {
        var obj = messageLoop.shift();
        infoBox(obj.message, obj.time).then(function () {
            messageLoopShow();
        });
    }
    else {
        setTimeout(function () {
            messageLoopShow();
        }, 5000);
    }
}

function inviteOpen(obj) {
    var isGo = true;
    if (_apiHandler.rtcConnected) {
        isGo = window.confirm("前往新的邀請將會中斷目前的交談，確定嗎？");
        srDoLeaveRoom();
    }

    if (isGo)
        location.href = $(obj).data('href');
}

function infoBox(message, time) {
    return new Promise(function (resolve, reject) {
        var numY = 70;
        var numX = ($(window).width() / 2) - ($(window).width() / 4);
        var oBOX = $('<span class="infoBox" style="left:' + numX + 'px;top:' + numY + 'px">' + message + '</span>');
        $('body').append(oBOX);

        if (time == undefined)
            time = 4000;

        $(oBOX).oneTime(time, function () {
            $(this).animate({ opacity: 'toggle' }, "slow", "swing", function () {
                $(this).remove();
                resolve();
            });
        });
    });
}

function connectMessageShow(message) {
    $('.leavechact').remove();
    $chactbox.append('<li class="leavechact"><p>' + message + '</p></li>');
    scrollBottom();
}

function scrollBottom() {
    _chatBoxOnScroll = true;
    setTimeout(function () {
        $chactbox.prop('scrollTop', $chactbox.prop('scrollHeight'));
        _chatBoxOnScroll = false;
    }, 1000);
}

function chatMsgShow(rs, type) {
    var i, j, dateIn, html = "";
    var oRoot = $chactbox;
    if (rs == null)
        return;

    for (i = 0; i < rs.length; i++) {
        var r = rs[i];
        var numDate = r["dateIn"].left(10).replace(/-/g, "").replace(/\//g, "");
        var msgDate = r["dateIn"].left(10).replace(/-/g, "/");
        var msgTime = r["dateIn"].right(8);
        var duringTime;

        if (chatLoop[numDate] == undefined) {
            chatLoop[numDate] = [];
            html += '<li class="dateline" data-date="{0}"><p>{0}</p><span class="line"></span></li>'.format(msgDate);
        }

        chatLoop[numDate].push(r);

        //訊息類型：0-文字; 1-通話; 2-視訊; 3-圖片; 4-檔案
        switch (r["msgType"]) {
            case 0:
                if (r["whoTalk"] == 1)
                    html += '<li class="tright"><div class="time">{0}</div><p>{1}</p></li>'.format(msgTime, r["msgLog"].replace(/[\r\n]/g, "<br/>"));
                else
                    html += '<li class="tleft"><p>{0}</p><div class="time">{1}</div></li>'.format(r["msgLog"].replace(/[\r\n]/g, "<br/>"), msgTime);
                break;

            case 1:
                duringTime = r["duringTime"] > 0 ? ("語音通話：" + _apiHandler.getPrettyTime(r["duringTime"] * 1000)) : (r["whoTalk"] == 1 ? "取消" : "無回應");
                if (r["whoTalk"] == 1)
                    html += '<li class="tright"><div class="time">{0}</div><p class="radiusR15"><span class="tel_del"></span>{1}</p></li>'.format(msgTime, duringTime);
                else
                    html += '<li class="tleft"><p class="radiusL15"><span class="tel_del"></span>{0}</p><div class="time">{1}</div></li>'.format(duringTime, msgTime);
                break;

            case 2:
                duringTime = r["duringTime"] > 0 ? ("視訊通話：" + _apiHandler.getPrettyTime(r["duringTime"] * 1000)) : (r["whoTalk"] == 1 ? "取消" : "無回應");
                if (r["whoTalk"] == 1)
                    html += '<li class="tright"><div class="time">{0}</div><p class="radiusR15"><span class="video_del"></span>{1}</p></li>'.format(msgTime, duringTime);
                else
                    html += '<li class="tleft"><p class="radiusL15"><span class="video_del"></span>{0}</p><div class="time">{1}</div></li>'.format(duringTime, msgTime);
                break;

            case 3:
                if (r["whoTalk"] == 1)
                    html += '<li class="tright"><div class="time">{0}</div><p class="radiusR15"><span class="sendimgs"><img src="images/pic03.jpg"></span></p></li>'.format(msgTime);
                else
                    html += '<li class="tleft"><p class="radiusL15"><span class="sendimgs"><img src="images/pic03.jpg"></span></p><div class="time">{0}</div></li>'.format(msgTime);
                break;

            case 4:
                if (r["whoTalk"] == 1)
                    html += '<li class="tright"><div class="time">{0}</div><p class="sendfiles radiusR15"><a href="" class="files"><span class="filesico"></span></a><span class="filename">{1}</span><span class="loadfiles"><span class="load"></span></span><a href="" class="delete"></a></p></li>'.format(msgTime, r["fileName"]);
                else
                    html += '<li class="tleft"><p class="sendfiles radiusL15"><a href="" class="files"><span class="filesico"></span></a><span class="filename">{0}</span><span class="loadfiles"><span class="load"></span></span><a href="" class="delete"></a></p><div class="time">{1}</div></li>'.format(r["fileName"], msgTime);
                break;
        }
    }

    if (html != "") {
        if (type == 'up') {
            $(oRoot).prepend(html);
        }
        else {
            $(oRoot).append(html);
            scrollBottom();
        }
    }
}

function chatLogShow() {
    $.ajax({
        type: "get",
        url: location.href,
        data: "actFun=getLog",
        success: function (data) {
            var HTML = "";
            for (i = 0; i < data.length; i++) {
                var rs = data[i];
                var url = "index.asp?cid=&eNo=" + rs["eNo"] + "&uNo=" + rs["uNo"];
                var clsName = "";

                if (_apiHandler.notifyArgs.eNo == rs["eNo"] && _apiHandler.notifyArgs.uNo == rs["uNo"])
                    clsName = "active";

                HTML += "<li class='" + clsName + "'>";
                HTML += "	<h6><a href='" + url + "' title='" + rs["organ"] + "'>" + rs["organ"] + "</a></h6>";
                HTML += "	<p class='date'>" + rs["dateIn"].left(10).replace(/-/g, ".") + "</p>";
                HTML += "	<div class='clearfix'></div>";
                HTML += "	<div class='jobs'><a href='" + url + "' title='" + rs["empName"] + "'>";

                if (rs["noReadCN"] > 0)
                    HTML += "<span style='color:red !important;'>(未讀:" + rs["noReadCN"] + ")</span>";

                HTML += rs["empName"] + "</a></div>"
                HTML += "</li>";
            }
            $('.talkLog').html(HTML);
        }
    });
}

function jsChatEnable(obj) {
    var isUpdate = true;
    if ($(obj).find('.fa-toggle-on').length > 0) {
        isUpdate = window.confirm("關閉將無法接收即時訊息跟來電！\r\n確定要關閉嗎？");
    }

    if (isUpdate) {
        localStorage.removeItem('talentNotify');
        localStorage.removeItem('talentFcmToken');

        $.ajax({
            type: "get",
            url: location.href,
            data: "actFun=chatEnable",
            success: function (data) {
                if (data.chatEnable == 1) {
                    $(obj).html('接收訊息狀態：<span class="fa fa-toggle-on"></span> 已開啟');

                    var _chkNotification = function (permission) {
                        switch (permission) {
                            case "default":
                                if (confirm("請求使用通知功能！\r\n收到訊息可以主動通知您喔！")) {
                                    Notification.requestPermission(function (_permission) {
                                        _chkNotification(_permission);
                                    });
                                }
                                else
                                    alert("通知功能【未開啟】！如果需要使用時記得打開喔！");
                                break;

                            case "denied":
                                alert("通知功能【已封鎖】！如果需要使用時記得解除封鎖喔！");
                                break;

                            case "granted":
                                _apiHandler.fcmHandler.fcmGetToken().then(function (token) {
                                    return new Promise(function (resolve, reject) {
                                        if (token != "") {
                                            resolve(token);
                                        }
                                        else {
                                            handler.fcmRequestPermission().then(function (token) {
                                                if (token != "")
                                                    resolve(token);
                                                else
                                                    reject();
                                            });
                                        }
                                    });
                                }).then(function (token) {
                                    localStorage.setItem('talentNotify', '1');
                                    alert("通知功能【已開啟】！訊息將不漏接囉 ^^");
                                }).catch(function () {
                                    alert("通知功能【未開啟】！伺服器忙線中，請稍後再試！");
                                });
                                break;
                        }
                    };

                    if (!("Notification" in window))
                        alert("您的瀏覽器不支援通知！\r\n通知功能可以在收到訊息時主動通知您！\r\n要不要試試看 firefox 或是 google chrome 瀏覽器呢？");
                    else
                        _chkNotification(Notification.permission);
                }
                else {
                    $(obj).html('接收訊息狀態：<span class="fa fa-toggle-off"></span> 已關閉');
                }
            }
        });
    }
}

function jsChatOrganHideUpd(obj) {
    $.ajax({
        type: "get",
        url: location.href,
        data: "actFun=chatOrganHideUpd&" + $(obj).parent().find(':input').serialize(),
        success: function (data) {
            var i = 0;
            var oROOT = $('.bkOrganList');
            var html = '';
            for (i = 0; i < data.length; i++)
                html += '<li data-key="' + data[i].key + '">' + data[i].val
					+ '<span class="fa fa-times" style="padding-left:.5em;color:red;" onclick="jsChatOrganHideUpd(this)"><input type="hidden" name="bkOrganNoDel" value="' + data[i].key + '" /></span>'
					+ '</li>';

            $(oROOT).html(html);
        }
    });
}

function volumeChange(obj) {
    remoteVideo.volume = $(obj).val();
}
