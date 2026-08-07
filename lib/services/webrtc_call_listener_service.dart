import 'dart:async';

import 'package:LawyerOnline/main.dart';
import 'package:LawyerOnline/models/user_profile_store.dart';
import 'package:LawyerOnline/services/webrtc_hub_service.dart';
import 'package:LawyerOnline/shared/api_provider.dart';
import 'package:LawyerOnline/shared/notification_store.dart';
import 'package:LawyerOnline/webrtc_call_page.dart';
import 'package:LawyerOnline/widgets/incoming_call_dialog.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// รับสายวิดีโอเข้าผ่าน webrtcHub ทั่วแอพ (ไม่ต้องอยู่ในหน้าแชท)
class WebRtcCallListenerService {
  WebRtcCallListenerService._();
  static final WebRtcCallListenerService instance =
      WebRtcCallListenerService._();

  final _hub = WebRtcHubService.instance;
  String? _listeningRoom;
  String? _listeningCaseCode;
  bool _inCallPage = false;
  bool _dialogShowing = false;

  bool get inCallPage => _inCallPage;

  void setInCallPage(bool value) => _inCallPage = value;

  /// เรียกตอน login / เข้า Menu — join personal channel
  Future<void> startGlobal() async {
    final userId = UserProfileStore.instance.code;
    if (userId.isEmpty) return;

    _hub.onIncomingCall = _handleIncoming;
    _hub.onCallEnded = _handleCallEnded;
    await _hub.connect();
    await _hub.joinUser(userId);
  }

  Future<void> start() async {
    await startGlobal();
  }

  Future<void> stop() async {
    await leaveCurrentRoom();
    final userId = UserProfileStore.instance.code;
    if (userId.isNotEmpty) {
      await _hub.leaveUser(userId);
    }
    if (_hub.onIncomingCall == _handleIncoming) {
      _hub.onIncomingCall = null;
    }
    if (_hub.onCallEnded == _handleCallEnded) {
      _hub.onCallEnded = null;
    }
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

  /// จาก FCM / notification tap
  void handlePushPayload(Map<String, dynamic> data) {
    String pick(String key) => data[key]?.toString().trim() ?? '';
    final roomCode = [
      pick('roomCode'),
      pick('code'),
      pick('refCode'),
    ].firstWhere((e) => e.isNotEmpty, orElse: () => '');
    final from = pick('fromUserId');
    if (roomCode.isNotEmpty && from.isNotEmpty) {
      _hub.markInitiator(roomCode, from);
    }
    _handleIncoming({
      'roomCode': roomCode,
      'caseCode': pick('caseCode'),
      'fromUserId': from,
      'peerName': pick('peerName').isNotEmpty
          ? pick('peerName')
          : pick('title'),
      'peerImageUrl': pick('peerImageUrl'),
    });
  }

  void _handleIncoming(Map<String, dynamic> payload) {
    if (_inCallPage || _dialogShowing) return;

    final from = payload['fromUserId']?.toString() ?? '';
    final userId = UserProfileStore.instance.code;
    if (from.isNotEmpty && from == userId) return;

    final roomCode =
        payload['roomCode']?.toString() ?? _listeningRoom ?? '';
    final caseCode =
        payload['caseCode']?.toString() ?? _listeningCaseCode ?? '';
    var peerName = payload['peerName']?.toString() ?? '';
    var peerImageUrl = payload['peerImageUrl']?.toString() ?? '';
    if (roomCode.isEmpty) return;

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final ctx = navigatorKey.currentContext;
      if (ctx == null || !ctx.mounted) return;
      if (_inCallPage || _dialogShowing) return;

      if (from.isNotEmpty &&
          (peerName.trim().isEmpty || peerImageUrl.trim().isEmpty)) {
        final profile = await _fetchPeerProfile(from);
        if (peerName.trim().isEmpty) peerName = profile.$1;
        if (peerImageUrl.trim().isEmpty) peerImageUrl = profile.$2;
      }
      if (peerName.trim().isEmpty) {
        peerName = from.isNotEmpty ? from : 'incomingCall'.tr();
      }

      if (!ctx.mounted || _inCallPage || _dialogShowing) return;
      _dialogShowing = true;

      await showDialog<void>(
        context: ctx,
        barrierDismissible: false,
        barrierColor: Colors.transparent,
        builder: (dialogCtx) => IncomingCallDialog(
          peerName: peerName,
          peerImageUrl: peerImageUrl,
          onDecline: () {
            Navigator.pop(dialogCtx);
            _dialogShowing = false;
            unawaited(_sendCallReject(
              roomCode: roomCode,
              caseCode: caseCode,
              userId: userId,
            ));
          },
          onRingTimeout: () {
            if (!dialogCtx.mounted) return;
            Navigator.pop(dialogCtx);
            _dialogShowing = false;
          },
          onAccept: () {
            Navigator.pop(dialogCtx);
            _dialogShowing = false;
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
        ),
      ).whenComplete(() => _dialogShowing = false);
    });
  }

  void _handleCallEnded(Map<String, dynamic> payload) {
    if (_dialogShowing) {
      final ctx = navigatorKey.currentContext;
      if (ctx != null && ctx.mounted && Navigator.canPop(ctx)) {
        Navigator.pop(ctx);
      }
      _dialogShowing = false;
    }
    unawaited(NotificationStore.instance.refresh());
  }

  Future<void> _sendCallReject({
    required String roomCode,
    required String caseCode,
    required String userId,
  }) async {
    if (roomCode.isEmpty || userId.isEmpty) return;
    try {
      await _hub.connect();
      await _hub.joinRoom(
        roomCode: roomCode,
        userId: userId,
        caseCode: caseCode,
      );
      await _hub.sendSignal(
        roomCode: roomCode,
        fromUserId: userId,
        signal: {
          'action': 'reject',
          'from': userId,
        },
      );
      await _hub.leaveRoom(roomCode: roomCode, userId: userId);
    } catch (_) {}
  }

  Future<(String, String)> _fetchPeerProfile(String code) async {
    try {
      final res = await postDio('${server}/m/register/read', {'code': code});
      if (res == null || res['status'] != 'S') return ('', '');
      final raw = res['objectData'];
      Map<String, dynamic>? user;
      if (raw is List && raw.isNotEmpty && raw.first is Map) {
        user = Map<String, dynamic>.from(raw.first as Map);
      } else if (raw is Map) {
        user = Map<String, dynamic>.from(raw);
      }
      if (user == null) return ('', '');
      final first = user['firstName']?.toString() ?? '';
      final last = user['lastName']?.toString() ?? '';
      final name = '$first $last'.trim();
      final image = user['imageUrl']?.toString() ?? '';
      return (name, image);
    } catch (_) {
      return ('', '');
    }
  }
}
