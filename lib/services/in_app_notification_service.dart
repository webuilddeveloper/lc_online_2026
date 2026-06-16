import 'package:flutter/material.dart';
import 'package:LawyerOnline/widgets/top_notification_banner.dart';
import 'package:LawyerOnline/main.dart'; // เพื่อใช้ navigatorKey

class InAppNotificationService {
  static OverlayEntry? _entry;

  static void show({
    required String title,
    required String body,
    VoidCallback? onTap,
  }) {
    final overlay = navigatorKey.currentState?.overlay;
    if (overlay == null) return;

    // ถ้ามีแบนเนอร์เก่าอยู่ ให้เอาออกก่อน
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