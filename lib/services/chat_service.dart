import 'package:LawyerOnline/shared/api_provider.dart';
import 'package:signalr_netcore/signalr_client.dart';

class ChatService {
  static final ChatService _instance = ChatService._internal();
  factory ChatService() => _instance;
  ChatService._internal();

  HubConnection? _connection; // ✅ เปลี่ยนเป็น nullable

  // Callbacks
  Function(Map<String, dynamic>)? onReceiveMessage;
  Function(List<dynamic>)? onLoadHistory;
  Function(String, bool)? onUserTyping;
  Function(Map<String, dynamic>)? onMessageRead;

  // ========== เชื่อมต่อ ==========
  Future<void> connect() async {
    try {
      // ✅ เช็ค null ก่อน แล้วค่อยเช็ค state
      if (_connection != null &&
          _connection!.state == HubConnectionState.Connected) return;

      _connection = HubConnectionBuilder()
          .withUrl("${server}/chatHub")
          .withAutomaticReconnect()
          .build();

      _connection!.off("ReceiveMessage");
      _connection!.off("UserTyping");
      _connection!.off("MessageRead");
      _connection!.off("LoadHistory");

      _registerListeners();

      await _connection!.start();

      print("=== SignalR State: ${_connection!.state} ===");
      print("=== SignalR Connected ===");
    } catch (e) {
      print("=== SignalR Connect Error: $e ===");
    }
  }

  void _registerListeners() {
    _connection!.on("ReceiveMessage", (data) {
      if (data != null && data.isNotEmpty) {
        onReceiveMessage?.call(data[0] as Map<String, dynamic>);
      }
    });

    _connection!.on("LoadHistory", (data) {
      if (data != null && data.isNotEmpty) {
        onLoadHistory?.call(data[0] as List<dynamic>);
      }
    });

    _connection!.on("UserTyping", (data) {
      if (data != null && data.isNotEmpty) {
        final d = data[0] as Map<String, dynamic>;
        onUserTyping?.call(d['userId'], d['isTyping']);
      }
    });

    _connection!.on("MessageRead", (data) {
      if (data != null && data.isNotEmpty) {
        onMessageRead?.call(data[0] as Map<String, dynamic>);
      }
    });
  }

  // ========== Methods ==========
  Future<void> joinRoom(String roomCode, String userId) async {
    try {
      print("=== Before JoinRoom ===");
      print("state: ${_connection?.state}");
      print("roomCode: $roomCode");
      print("userId: $userId");
      await _connection?.invoke("JoinRoom", args: [roomCode, userId]);
      print("=== JoinRoom Success ===");
    } catch (e) {
      print("=== JoinRoom Error: $e ===");
    }
  }

  Future<void> leaveRoom(String roomCode, String userId) async {
    try {
      await _connection?.invoke("LeaveRoom", args: [roomCode, userId]);
    } catch (e) {
      print("=== LeaveRoom Error: $e ===");
    }
  }

  Future<void> sendMessage(String roomCode, String senderId, String content) async {
    try {
      await _connection?.invoke("SendMessage", args: [roomCode, senderId, content]);
    } catch (e) {
      print("=== SendMessage Error: $e ===");
    }
  }

  Future<void> loadHistory(String roomCode, {int skip = 0, int limit = 20}) async {
    try {
      await _connection?.invoke("LoadHistory", args: [roomCode, skip, limit]);
    } catch (e) {
      print("=== LoadHistory Error: $e ===");
    }
  }

  Future<void> markAsRead(String roomCode, String userId) async {
    try {
      await _connection?.invoke("MarkAsRead", args: [roomCode, userId]);
    } catch (e) {
      print("=== MarkAsRead Error: $e ===");
    }
  }

  Future<void> typing(String roomCode, String userId, bool isTyping) async {
    try {
      await _connection?.invoke("Typing", args: [roomCode, userId, isTyping]);
    } catch (e) {
      print("=== Typing Error: $e ===");
    }
  }

  Future<void> disconnect() async {
    try {
      if (_connection == null) return; // ✅ ไม่ crash ถ้ายังไม่ได้ init
      await _connection!.stop();
      _connection = null; // ✅ reset ให้ connect ใหม่ได้สะอาด
      print("=== SignalR Disconnected ===");
    } catch (e) {
      print("=== Disconnect Error: $e ===");
    }
  }
}