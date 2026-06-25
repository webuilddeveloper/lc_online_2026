import 'package:flutter/material.dart';
import 'package:LawyerOnline/main.dart';
import 'package:LawyerOnline/services/notification_service.dart';
import 'package:LawyerOnline/widgets/top_notification_banner.dart';

class InAppNotificationService {
  static OverlayEntry? _entry;

  static Future<void> show({
    required String title,
    required String body,
    VoidCallback? onTap,
  }) async {
    await NotificationService.playForegroundAlert();

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
