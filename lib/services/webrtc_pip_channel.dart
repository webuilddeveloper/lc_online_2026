import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Android system Picture-in-Picture via MainActivity MethodChannel.
class WebRtcPipChannel {
  WebRtcPipChannel._();

  static const _channel = MethodChannel('lc_online/pip');
  static VoidCallback? onUserLeaveHint;
  static ValueChanged<bool>? onPipModeChanged;
  static bool _bound = false;

  static void bind() {
    if (_bound || kIsWeb) return;
    _bound = true;
    _channel.setMethodCallHandler((call) async {
      switch (call.method) {
        case 'onUserLeaveHint':
          onUserLeaveHint?.call();
          break;
        case 'onPipModeChanged':
          onPipModeChanged?.call(call.arguments == true);
          break;
      }
    });
  }

  static Future<bool> isSupported() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      return false;
    }
    try {
      final result = await _channel.invokeMethod<bool>('isPipSupported');
      return result == true;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> enterPip() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      return false;
    }
    try {
      final result = await _channel.invokeMethod<bool>('enterPip');
      return result == true;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> isInPip() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      return false;
    }
    try {
      final result = await _channel.invokeMethod<bool>('isInPip');
      return result == true;
    } catch (_) {
      return false;
    }
  }
}
