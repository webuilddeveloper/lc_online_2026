import 'package:LawyerOnline/models/user_profile_store.dart';
import 'package:LawyerOnline/services/webrtc_hub_service.dart';

typedef WebRtcSignalHandler = void Function(WebRtcSignal signal);

/// Signaling แยกผ่าน webrtcHub (ไม่ผ่าน chat)
class WebRtcSignalingService {
  WebRtcSignalingService({
    required this.roomCode,
    required this.userId,
    required this.caseCode,
    this.peerName = '',
    this.toUserId = '',
    this.isInitiator = false,
  });

  final String roomCode;
  final String userId;
  final String caseCode;
  final String peerName;
  final String toUserId;
  final bool isInitiator;

  final _hub = WebRtcHubService.instance;
  WebRtcSignalHandler? onSignal;
  bool _started = false;

  Future<void> start() async {
    if (_started) return;
    _started = true;

    _hub.onReceiveSignal = _handleRaw;
    await _hub.joinRoom(
      roomCode: roomCode,
      userId: userId,
      caseCode: caseCode,
    );

    // เฉพาะฝั่งที่กดโทรเท่านั้นที่ StartCall — ส่งชื่อ/รูปของฝั่งโทรให้ฝั่งรับ
    if (isInitiator) {
      final me = UserProfileStore.instance;
      await _hub.startCall(
        roomCode: roomCode,
        fromUserId: userId,
        caseCode: caseCode,
        peerName: me.name,
        peerImageUrl: me.imageUrl,
        toUserId: toUserId,
      );
    }
  }

  Future<void> stop() async {
    if (!_started) return;
    _started = false;
    if (_hub.onReceiveSignal == _handleRaw) {
      _hub.onReceiveSignal = null;
    }
  }

  Future<void> send(WebRtcSignal signal) async {
    await _hub.sendSignal(
      roomCode: roomCode,
      fromUserId: userId,
      signal: signal.toJson(),
    );
  }

  void _handleRaw(Map<String, dynamic> raw) {
    final from = raw['from']?.toString() ?? '';
    if (from.isEmpty || from == userId) return;

    final signal = WebRtcSignal.fromJson(raw, from: from);
    if (signal.action.isEmpty) return;
    onSignal?.call(signal);
  }
}

class WebRtcSignal {
  final String action;
  final String from;
  final String? sdp;
  final Map<String, dynamic>? candidate;

  const WebRtcSignal({
    required this.action,
    required this.from,
    this.sdp,
    this.candidate,
  });

  Map<String, dynamic> toJson() => {
        'action': action,
        'from': from,
        if (sdp != null) 'sdp': sdp,
        if (candidate != null) 'candidate': candidate,
      };

  factory WebRtcSignal.fromJson(Map<String, dynamic> json, {String? from}) {
    return WebRtcSignal(
      action: json['action']?.toString() ?? '',
      from: from ?? json['from']?.toString() ?? '',
      sdp: json['sdp']?.toString(),
      candidate: json['candidate'] is Map
          ? Map<String, dynamic>.from(json['candidate'] as Map)
          : null,
    );
  }
}
