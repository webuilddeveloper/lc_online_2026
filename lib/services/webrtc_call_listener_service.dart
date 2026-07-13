import 'package:LawyerOnline/main.dart';
import 'package:LawyerOnline/models/user_profile_store.dart';
import 'package:LawyerOnline/services/webrtc_hub_service.dart';
import 'package:LawyerOnline/webrtc_call_page.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// รับสายวิดีโอเข้าผ่าน webrtcHub ขณะอยู่ในห้องแชท
class WebRtcCallListenerService {
  WebRtcCallListenerService._();
  static final WebRtcCallListenerService instance =
      WebRtcCallListenerService._();

  final _hub = WebRtcHubService.instance;
  String? _listeningRoom;
  String? _listeningCaseCode;
  bool _inCallPage = false;
  bool _started = false;

  void setInCallPage(bool value) => _inCallPage = value;

  Future<void> start() async {
    if (_started) return;
    _started = true;
    _hub.onIncomingCall = _handleIncoming;
    await _hub.connect();
  }

  Future<void> stop() async {
    await leaveCurrentRoom();
    if (_hub.onIncomingCall == _handleIncoming) {
      _hub.onIncomingCall = null;
    }
    _started = false;
  }

  Future<void> joinRoomForChat({
    required String roomCode,
    required String caseCode,
  }) async {
    if (roomCode.isEmpty) return;
    await start();

    final userId = UserProfileStore.instance.code;
    if (userId.isEmpty) return;

    if (_listeningRoom != null && _listeningRoom != roomCode) {
      await _hub.leaveRoom(roomCode: _listeningRoom!, userId: userId);
    }

    _listeningRoom = roomCode;
    _listeningCaseCode = caseCode;
    await _hub.joinRoom(
      roomCode: roomCode,
      userId: userId,
      caseCode: caseCode,
    );
  }

  Future<void> leaveCurrentRoom() async {
    final userId = UserProfileStore.instance.code;
    if (_listeningRoom == null || userId.isEmpty) return;
    await _hub.leaveRoom(roomCode: _listeningRoom!, userId: userId);
    _listeningRoom = null;
    _listeningCaseCode = null;
  }

  void _handleIncoming(Map<String, dynamic> payload) {
    if (_inCallPage) return;

    final from = payload['fromUserId']?.toString() ?? '';
    final userId = UserProfileStore.instance.code;
    if (from.isEmpty || from == userId) return;

    final roomCode =
        payload['roomCode']?.toString() ?? _listeningRoom ?? '';
    final caseCode =
        payload['caseCode']?.toString() ?? _listeningCaseCode ?? '';
    final peerName = payload['peerName']?.toString() ?? from;
    if (roomCode.isEmpty) return;

    final ctx = navigatorKey.currentContext;
    if (ctx == null || !ctx.mounted) return;

    showDialog<void>(
      context: ctx,
      barrierDismissible: false,
      builder: (dialogCtx) => AlertDialog(
        title: Text('incomingCall'.tr()),
        content: Text(peerName),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: Text('cancel'.tr()),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogCtx);
              Navigator.push(
                ctx,
                MaterialPageRoute<void>(
                  builder: (_) => WebRtcCallPage(
                    roomCode: roomCode,
                    caseCode: caseCode,
                    userId: userId,
                    peerName: peerName,
                    isInitiator: false,
                  ),
                ),
              );
            },
            child: Text('accept'.tr()),
          ),
        ],
      ),
    );
  }
}
