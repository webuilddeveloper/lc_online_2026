import 'package:flutter/services.dart';

/// Restores system UI after full-screen WebRTC call pages.
class WebRtcSystemUi {
  WebRtcSystemUi._();

  static Future<void> restoreAfterCall() async {
    await SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: SystemUiOverlay.values,
    );
    await SystemChrome.setPreferredOrientations(DeviceOrientation.values);
  }
}
