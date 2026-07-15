import 'dart:async';

import 'package:LawyerOnline/consult/consult_status.dart';
import 'package:LawyerOnline/main.dart';
import 'package:LawyerOnline/services/consultation_summary_service.dart';
import 'package:LawyerOnline/services/video_call_log_service.dart';
import 'package:LawyerOnline/services/webrtc_call_listener_service.dart';
import 'package:LawyerOnline/services/webrtc_config.dart';
import 'package:LawyerOnline/services/webrtc_hub_service.dart';
import 'package:LawyerOnline/services/webrtc_peer_service.dart';
import 'package:LawyerOnline/widgets/webrtc_call_pip_bubble.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

/// Keeps an active WebRTC call alive across page pops (in-app PiP).
class WebRtcCallSession {
  WebRtcCallSession._();
  static final WebRtcCallSession instance = WebRtcCallSession._();

  WebRtcPeerService? _peer;
  final RTCVideoRenderer localRenderer = RTCVideoRenderer();
  final RTCVideoRenderer remoteRenderer = RTCVideoRenderer();
  final ValueNotifier<WebRtcCallState> state =
      ValueNotifier(WebRtcCallState.idle);
  final ValueNotifier<WebRtcQualityInfo> quality = ValueNotifier(
    const WebRtcQualityInfo(
      quality: WebRtcCallQuality.unknown,
      rttMs: 0,
      packetsLost: 0,
    ),
  );
  final ValueNotifier<bool> hasRemote = ValueNotifier(false);
  final ValueNotifier<bool> hasLocal = ValueNotifier(false);
  final ValueNotifier<bool> muted = ValueNotifier(false);
  final ValueNotifier<bool> cameraOff = ValueNotifier(false);
  final ValueNotifier<bool> screenSharing = ValueNotifier(false);
  final ValueNotifier<bool> isMinimized = ValueNotifier(false);
  final ValueNotifier<bool> isSystemPip = ValueNotifier(false);

  String roomCode = '';
  String caseCode = '';
  String userId = '';
  String peerName = '';
  String toUserId = '';
  bool isInitiator = false;

  bool _renderersReady = false;
  bool _logged = false;
  bool _ending = false;
  bool _fullScreenOpen = false;
  DateTime? connectedAt;
  Timer? _noAnswerTimer;
  String? endReason;

  bool get isActive => _peer != null && !_ending;
  bool get isFullScreenOpen => _fullScreenOpen;
  WebRtcPeerService? get peer => _peer;
  bool get renderersReady => _renderersReady;

  Future<void> ensureRenderers() async {
    if (_renderersReady) return;
    await localRenderer.initialize();
    await remoteRenderer.initialize();
    _renderersReady = true;
  }

  Future<void> start({
    required String roomCode,
    required String caseCode,
    required String userId,
    String peerName = '',
    String toUserId = '',
    bool isInitiator = false,
  }) async {
    if (isActive && this.roomCode == roomCode) {
      return;
    }
    if (isActive) {
      await endCall(popFullScreen: false);
    }

    this.roomCode = roomCode;
    this.caseCode = caseCode;
    this.userId = userId;
    this.peerName = peerName;
    this.toUserId = toUserId;
    this.isInitiator = isInitiator;
    _logged = false;
    _ending = false;
    connectedAt = null;
    endReason = null;
    hasRemote.value = false;
    hasLocal.value = false;
    muted.value = false;
    cameraOff.value = false;
    screenSharing.value = false;
    isMinimized.value = false;
    isSystemPip.value = false;
    state.value = WebRtcCallState.connecting;

    await ensureRenderers();
    WebRtcCallListenerService.instance.setInCallPage(true);

    _peer = WebRtcPeerService(
      roomCode: roomCode,
      userId: userId,
      caseCode: caseCode,
      peerName: peerName,
      toUserId: toUserId,
      isInitiator: isInitiator,
      onStateChanged: (s) {
        if (s == WebRtcCallState.connected && connectedAt == null) {
          connectedAt = DateTime.now();
          _noAnswerTimer?.cancel();
        }
        state.value = s;
        if (s == WebRtcCallState.ended) {
          unawaited(endCall());
        }
      },
      onRemoteStream: attachRemote,
      onQualityChanged: (q) {
        if (quality.value != q) quality.value = q;
      },
      onRemoteEnded: (reason) {
        endReason = reason;
      },
    );

    if (isInitiator) {
      _noAnswerTimer = Timer(const Duration(minutes: 2), () {
        if (connectedAt != null || _ending) return;
        endReason = 'no_answer';
        unawaited(_peer?.hangUp());
      });
    }

    await _peer!.start();
    final local = _peer!.localStream;
    if (local != null) attachLocal(local);
  }

  void attachRemote(MediaStream stream) {
    if (remoteRenderer.srcObject?.id != stream.id) {
      remoteRenderer.srcObject = stream;
    } else if (remoteRenderer.srcObject == null) {
      remoteRenderer.srcObject = stream;
    }
    if (!hasRemote.value) hasRemote.value = true;
  }

  void attachLocal(MediaStream stream) {
    if (localRenderer.srcObject?.id != stream.id) {
      localRenderer.srcObject = stream;
    } else if (localRenderer.srcObject == null) {
      localRenderer.srcObject = stream;
    }
    if (!hasLocal.value) hasLocal.value = true;
  }

  void setFullScreenOpen(bool open) {
    _fullScreenOpen = open;
    if (open) {
      isMinimized.value = false;
      WebRtcCallPipBubble.hide();
    }
  }

  /// Back / minimize → keep call, show floating bubble.
  Future<void> minimizeToBubble() async {
    if (!isActive || isMinimized.value) return;
    isMinimized.value = true;
    _fullScreenOpen = false;
    final nav = navigatorKey.currentState;
    if (nav != null && nav.canPop()) {
      nav.pop();
    }
    WebRtcCallPipBubble.show();
  }

  /// Tap bubble → reopen full call page (caller provides route).
  void prepareExpand() {
    if (!isActive) return;
    isMinimized.value = false;
    WebRtcCallPipBubble.hide();
  }

  void markFullScreenOpening() {
    _fullScreenOpen = true;
  }

  Future<void> hangUp() async {
    await _peer?.hangUp();
  }

  Future<void> endCall({bool popFullScreen = true}) async {
    if (_ending) return;
    _ending = true;
    _noAnswerTimer?.cancel();
    WebRtcCallPipBubble.hide();
    isMinimized.value = false;
    isSystemPip.value = false;

    final reason = endReason;
    await _saveCallLog();

    final peer = _peer;
    _peer = null;
    await peer?.dispose();

    localRenderer.srcObject = null;
    remoteRenderer.srcObject = null;
    hasRemote.value = false;
    hasLocal.value = false;
    screenSharing.value = false;
    WebRtcCallListenerService.instance.setInCallPage(false);

    final nav = navigatorKey.currentState;
    final ctx = nav?.context;
    if (popFullScreen && _fullScreenOpen && nav != null && nav.canPop()) {
      nav.pop();
    }
    _fullScreenOpen = false;

    if (ctx != null && reason != null && reason.isNotEmpty) {
      final message = switch (reason) {
        'reject' => 'callPeerDeclined'.tr(),
        'no_answer' => 'callNoAnswer'.tr(),
        _ => '',
      };
      if (message.isNotEmpty) {
        ScaffoldMessenger.maybeOf(ctx)
            ?.showSnackBar(SnackBar(content: Text(message)));
      }
    }

    // Reset for next call
    state.value = WebRtcCallState.idle;
    roomCode = '';
    _ending = false;
  }

  Future<void> _saveCallLog() async {
    if (_logged || !isInitiator) return;

    final hubInitiator = WebRtcHubService.instance.initiatorOf(roomCode);
    if (hubInitiator != null && hubInitiator != userId) return;

    _logged = true;
    final seconds = connectedAt == null
        ? 0
        : DateTime.now().difference(connectedAt!).inSeconds;
    final initiatedBy = hubInitiator ?? userId;

    await VideoCallLogService.logCall(
      roomCode: roomCode,
      initiatedBy: initiatedBy,
      durationSeconds: seconds,
    );
    WebRtcHubService.instance.clearInitiator(roomCode);

    if (seconds > 0 && caseCode.isNotEmpty) {
      await ConsultationSummaryService.generate(
        caseCode,
        updateBy: userId,
      );
    }
  }

  /// Fallback navigation when call page can't pop.
  void openConsultStatusIfNeeded() {
    final nav = navigatorKey.currentState;
    if (nav == null || caseCode.isEmpty) return;
    nav.pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => ConsultStatusPage(caseCode: caseCode),
      ),
      (route) => route.isFirst,
    );
  }
}
