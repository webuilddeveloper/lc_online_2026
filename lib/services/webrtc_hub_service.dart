import 'package:LawyerOnline/shared/api_provider.dart';
import 'package:signalr_netcore/signalr_client.dart';

typedef WebRtcHubSignalHandler = void Function(Map<String, dynamic> signal);
typedef WebRtcIncomingCallHandler = void Function(Map<String, dynamic> signal);

/// SignalR hub แยกจาก chatHub — relay-only ไม่บันทึก DB
class WebRtcHubService {
  WebRtcHubService._();
  static final WebRtcHubService instance = WebRtcHubService._();

  HubConnection? _connection;
  String? _joinedRoom;
  String? _joinedUserId;
  String? _joinedPersonalUserId;

  /// ผู้ที่กดเริ่มสายจริงของห้องนี้
  final Map<String, String> _roomInitiator = {};

  WebRtcHubSignalHandler? onReceiveSignal;
  WebRtcIncomingCallHandler? onIncomingCall;
  void Function(Map<String, dynamic>)? onCallEnded;
  void Function(Map<String, dynamic>)? onPeerJoined;
  void Function(Map<String, dynamic>)? onPeerLeft;

  bool get isConnected =>
      _connection?.state == HubConnectionState.Connected;

  String? initiatorOf(String roomCode) => _roomInitiator[roomCode];

  void markInitiator(String roomCode, String userId) {
    if (roomCode.isEmpty || userId.isEmpty) return;
    _roomInitiator.putIfAbsent(roomCode, () => userId);
  }

  void clearInitiator(String roomCode) {
    _roomInitiator.remove(roomCode);
  }

  Future<void> connect() async {
    if (isConnected) return;

    _connection = HubConnectionBuilder()
        .withUrl(webrtcHubUrl)
        .withAutomaticReconnect()
        .build();

    _connection!.off('ReceiveSignal');
    _connection!.off('IncomingCall');
    _connection!.off('CallEnded');
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
      final map = Map<String, dynamic>.from(raw);
      final room = map['roomCode']?.toString() ?? '';
      final from = map['fromUserId']?.toString() ?? '';
      if (room.isNotEmpty && from.isNotEmpty) {
        markInitiator(room, from);
      }
      onIncomingCall?.call(map);
    });

    _connection!.on('CallEnded', (data) {
      if (data == null || data.isEmpty) return;
      final raw = data[0];
      if (raw is! Map) return;
      onCallEnded?.call(Map<String, dynamic>.from(raw));
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

  /// Join personal channel เพื่อรับสายแม้ไม่อยู่ในหน้าแชท
  Future<void> joinUser(String userId) async {
    if (userId.isEmpty) return;
    await connect();
    _joinedPersonalUserId = userId;
    await _connection?.invoke('JoinUser', args: [userId]);
  }

  Future<void> leaveUser(String userId) async {
    if (userId.isEmpty || !isConnected) return;
    await _connection?.invoke('LeaveUser', args: [userId]);
    if (_joinedPersonalUserId == userId) _joinedPersonalUserId = null;
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
  /// [peerName]/[peerImageUrl] = ชื่อ/รูปของฝั่งที่กดโทร (โชว์ที่ฝั่งรับ)
  Future<void> startCall({
    required String roomCode,
    required String fromUserId,
    required String caseCode,
    String peerName = '',
    String peerImageUrl = '',
    String toUserId = '',
  }) async {
    await connect();
    markInitiator(roomCode, fromUserId);
    await _connection?.invoke('StartCall', args: [
      roomCode,
      fromUserId,
      caseCode,
      peerName,
      toUserId,
      peerImageUrl,
    ]);
  }

  /// แจ้งอีกฝั่งว่าวางสายแล้ว
  Future<void> endCall({
    required String roomCode,
    required String fromUserId,
    required String caseCode,
    String toUserId = '',
  }) async {
    if (roomCode.isEmpty || fromUserId.isEmpty) return;
    await connect();
    await _connection?.invoke('EndCall', args: [
      roomCode,
      fromUserId,
      caseCode,
      toUserId,
    ]);
  }

  Future<void> disconnect() async {
    if (_joinedPersonalUserId != null) {
      await leaveUser(_joinedPersonalUserId!);
    }
    if (_joinedRoom != null && _joinedUserId != null) {
      await leaveRoom(roomCode: _joinedRoom!, userId: _joinedUserId!);
    }
    await _connection?.stop();
    _connection = null;
    onReceiveSignal = null;
    onIncomingCall = null;
    onCallEnded = null;
    onPeerJoined = null;
    onPeerLeft = null;
  }
}
