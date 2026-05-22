import 'package:signalr_netcore/signalr_client.dart';

class ChatService {
  static final ChatService _instance = ChatService._internal();
  factory ChatService() => _instance;
  ChatService._internal();

  late HubConnection _connection;
  bool _isConnected = false;

  // Callbacks
  Function(Map<String, dynamic>)? onReceiveMessage;
  Function(List<dynamic>)? onLoadHistory;
  Function(String, bool)? onUserTyping;
  Function(Map<String, dynamic>)? onMessageRead;

  // ========== เชื่อมต่อ ==========
  Future<void> connect() async {
    _connection = HubConnectionBuilder()
        .withUrl("https://yourserver.com/chatHub")
        .withAutomaticReconnect() // ✅ reconnect อัตโนมัติ
        .build();

    // ลงทะเบียน event listeners
    _registerListeners();

    try {
      await _connection.start();
      _isConnected = true;
      print("SignalR Connected");
    } catch (e) {
      print("SignalR Error: $e");
    }
  }

  void _registerListeners() {
    // รับ message ใหม่
    _connection.on("ReceiveMessage", (data) {
      if (data != null && data.isNotEmpty) {
        onReceiveMessage?.call(data[0] as Map<String, dynamic>);
      }
    });

    // รับประวัติแชท
    _connection.on("LoadHistory", (data) {
      if (data != null && data.isNotEmpty) {
        onLoadHistory?.call(data[0] as List<dynamic>);
      }
    });

    // รับสถานะกำลังพิมพ์
    _connection.on("UserTyping", (data) {
      if (data != null && data.isNotEmpty) {
        final d = data[0] as Map<String, dynamic>;
        onUserTyping?.call(d['userId'], d['isTyping']);
      }
    });

    // รับสถานะอ่านแล้ว
    _connection.on("MessageRead", (data) {
      if (data != null && data.isNotEmpty) {
        onMessageRead?.call(data[0] as Map<String, dynamic>);
      }
    });
  }

  // ========== Methods ==========

  Future<void> joinRoom(String roomId, String userId) async {
    await _connection.invoke("JoinRoom", args: [roomId, userId]);
  }

  Future<void> leaveRoom(String roomId, String userId) async {
    await _connection.invoke("LeaveRoom", args: [roomId, userId]);
  }

  Future<void> sendMessage(String roomId, String senderId, String content) async {
    await _connection.invoke("SendMessage", args: [roomId, senderId, content]);
  }

  Future<void> loadHistory(String roomId, {int skip = 0, int limit = 20}) async {
    await _connection.invoke("LoadHistory", args: [roomId, skip, limit]);
  }

  Future<void> markAsRead(String roomId, String userId) async {
    await _connection.invoke("MarkAsRead", args: [roomId, userId]);
  }

  Future<void> typing(String roomId, String userId, bool isTyping) async {
    await _connection.invoke("Typing", args: [roomId, userId, isTyping]);
  }

  Future<void> disconnect() async {
    await _connection.stop();
    _isConnected = false;
  }
}