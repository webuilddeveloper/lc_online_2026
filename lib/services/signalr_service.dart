// lib/services/signalr_service.dart
import 'package:signalr_netcore/signalr_client.dart';
import 'package:LawyerOnline/shared/api_provider.dart';

class SignalRService {
  SignalRService._();
  static final instance = SignalRService._();

  HubConnection? _connection;
  bool get isConnected => _connection?.state == HubConnectionState.Connected;

  final Map<String, List<Function(Map<String, dynamic>)>> _listeners = {};

  Future<void> connect() async {
    if (isConnected) return;

    _connection = HubConnectionBuilder()
        .withUrl('$server/chatHub')
        .withAutomaticReconnect()
        .build();

    await _connection!.start();
  }

  void on(String eventName, Function(Map<String, dynamic>) callback) {
    _listeners.putIfAbsent(eventName, () => []).add(callback);
    _connection?.on(eventName, (args) {
      if (args != null && args.isNotEmpty) {
        final data = Map<String, dynamic>.from(args[0] as Map);
        callback(data);
      }
    });
  }

  void off(String eventName) {
    _connection?.off(eventName);
    _listeners.remove(eventName);
  }

  Future<void> invoke(String methodName, List<Object> args) async {
    if (!isConnected) await connect();
    await _connection?.invoke(methodName, args: args);
  }

  Future<void> disconnect() async {
    await _connection?.stop();
    _connection = null;
  }
}