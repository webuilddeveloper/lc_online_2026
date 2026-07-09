import 'package:LawyerOnline/shared/notification_settings_store.dart';
import 'package:flutter/material.dart';
import 'package:LawyerOnline/main.dart';
import 'package:LawyerOnline/services/notification_service.dart';
import 'package:LawyerOnline/widgets/top_notification_banner.dart';

class InAppNotificationService {
  static OverlayEntry? _entry;

  static Future<void> show({
    required String title,
    required String body,
    Map<String, dynamic>? data,
    VoidCallback? onTap,
  }) async {
    final settings = NotificationSettingsStore.instance;
    if (data != null && !settings.shouldNotify(data)) return;

    await NotificationService.playForegroundAlert(
      sound: settings.shouldPlaySound,
      vibration: settings.shouldVibrate,
    );

    final overlay = navigatorKey.currentState?.overlay;
    if (overlay == null) return;

    _entry?.remove();
    _entry = null;

    _entry = OverlayEntry(
      builder: (context) => TopNotificationBanner(
        title: title,
        body: body,
        onTap: onTap,
        onDismiss: () {
          _entry?.remove();
          _entry = null;
        },
      ),
    );

    overlay.insert(_entry!);
  }
}
