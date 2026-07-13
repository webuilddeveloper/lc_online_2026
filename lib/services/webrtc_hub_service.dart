import 'package:LawyerOnline/shared/api_provider.dart';
import 'package:signalr_netcore/signalr_client.dart';

typedef WebRtcHubSignalHandler = void Function(Map<String, dynamic> signal);
typedef WebRtcIncomingCallHandler = void Function(Map<String, dynamic> payload);

/// SignalR hub แยกจาก chatHub — relay-only ไม่บันทึก DB
class WebRtcHubService {
  WebRtcHubService._();
  static final WebRtcHubService instance = WebRtcHubService._();

  HubConnection? _connection;
  String? _joinedRoom;
  String? _joinedUserId;

  WebRtcHubSignalHandler? onReceiveSignal;
  WebRtcIncomingCallHandler? onIncomingCall;
  void Function(Map<String, dynamic>)? onPeerJoined;
  void Function(Map<String, dynamic>)? onPeerLeft;

  bool get isConnected =>
      _connection?.state == HubConnectionState.Connected;

  Future<void> connect() async {
    if (isConnected) return;

    _connection = HubConnectionBuilder()
        .withUrl(webrtcHubUrl)
        .withAutomaticReconnect()
        .build();

    _connection!.off('ReceiveSignal');
    _connection!.off('IncomingCall');
    _connection!.off('PeerJoined');
    _connection!.off('PeerLeft');

    _connection!.on('ReceiveSignal', (data) {
      if (data == null || data.isEmpty) return;
      final raw = data[0];
      if (raw is! Map) return;
      onReceiveSignal?.call(Map<String, dynamic>.from(raw));
    });

    _connection!.on('IncomingCall', (data) {
      if (data == null || data.isEmpty) return;
      final raw = data[0];
      if (raw is! Map) return;
      onIncomingCall?.call(Map<String, dynamic>.from(raw));
    });

    _connection!.on('PeerJoined', (data) {
      if (data == null || data.isEmpty) return;
      final raw = data[0];
      if (raw is! Map) return;
      onPeerJoined?.call(Map<String, dynamic>.from(raw));
    });

    _connection!.on('PeerLeft', (data) {
      if (data == null || data.isEmpty) return;
      final raw = data[0];
      if (raw is! Map) return;
      onPeerLeft?.call(Map<String, dynamic>.from(raw));
    });

    await _connection!.start();
  }

  Future<void> joinRoom({
    required String roomCode,
    required String userId,
    required String caseCode,
  }) async {
    await connect();
    _joinedRoom = roomCode;
    _joinedUserId = userId;
    await _connection?.invoke('JoinRoom', args: [roomCode, userId, caseCode]);
  }

  Future<void> leaveRoom({
    required String roomCode,
    required String userId,
  }) async {
    if (!isConnected) return;
    await _connection?.invoke('LeaveRoom', args: [roomCode, userId]);
    if (_joinedRoom == roomCode && _joinedUserId == userId) {
      _joinedRoom = null;
      _joinedUserId = null;
    }
  }

  Future<void> sendSignal({
    required String roomCode,
    required String fromUserId,
    required Map<String, dynamic> signal,
  }) async {
    await connect();
    await _connection?.invoke('SendSignal', args: [
      roomCode,
      fromUserId,
      signal,
    ]);
  }

  /// แจ้งคู่สนทนาว่ามีสายเข้า (ไม่บันทึก DB)
  Future<void> startCall({
    required String roomCode,
    required String fromUserId,
    required String caseCode,
    String peerName = '',
  }) async {
    await connect();
    await _connection?.invoke('StartCall', args: [
      roomCode,
      fromUserId,
      caseCode,
      peerName,
    ]);
  }

  Future<void> disconnect() async {
    if (_joinedRoom != null && _joinedUserId != null) {
      await leaveRoom(roomCode: _joinedRoom!, userId: _joinedUserId!);
    }
    await _connection?.stop();
    _connection = null;
    onReceiveSignal = null;
    onIncomingCall = null;
    onPeerJoined = null;
    onPeerLeft = null;
  }
}
