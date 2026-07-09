import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';

typedef NotificationTapHandler = void Function(String? payload);

class NotificationService {
  NotificationService._();

  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static const _channelId = 'high_importance_channel';
  static const _channelName = 'การแจ้งเตือน';
  static final _vibrationPattern = Int64List.fromList([0, 300, 200, 300]);

  static NotificationTapHandler? onNotificationTap;
  static bool _initialized = false;

  static Future<void> init({NotificationTapHandler? onTap}) async {
    if (_initialized) return;
    onNotificationTap = onTap;

    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      await Permission.notification.request();
    }

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    await _plugin.initialize(
      const InitializationSettings(android: androidSettings, iOS: iosSettings),
      onDidReceiveNotificationResponse: (response) {
        onNotificationTap?.call(response.payload);
      },
    );

    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(
          AndroidNotificationChannel(
            _channelId,
            _channelName,
            description: 'แจ้งเตือนทั่วไปของแอป',
            importance: Importance.max,
            playSound: true,
            enableVibration: true,
            vibrationPattern: _vibrationPattern,
          ),
        );

    _initialized = true;
  }

  /// ใช้ใน background isolate (data-only message)
  static Future<void> initForBackground() async {
    if (_initialized) return;

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings();

    await _plugin.initialize(
      const InitializationSettings(android: androidSettings, iOS: iosSettings),
    );

    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(
          AndroidNotificationChannel(
            _channelId,
            _channelName,
            importance: Importance.max,
            playSound: true,
            enableVibration: true,
            vibrationPattern: _vibrationPattern,
          ),
        );

    _initialized = true;
  }

  /// เสียง + สั่น ตอนแอปเปิดอยู่ (ใช้คู่กับ in-app popup)
  static Future<void> playForegroundAlert({
    bool sound = true,
    bool vibration = true,
  }) async {
    if (vibration) {
      await HapticFeedback.heavyImpact();
    }
    if (sound) {
      SystemSound.play(SystemSoundType.alert);
    }
  }

  /// แจ้งเตือนระบบ — ใช้ตอนแอป background / data-only message
  static Future<void> showSystemNotification({
    required String title,
    required String body,
    String? payload,
    bool sound = true,
    bool vibration = true,
  }) async {
    final androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: 'แจ้งเตือนทั่วไปของแอป',
      importance: Importance.max,
      priority: Priority.high,
      playSound: sound,
      enableVibration: vibration,
      vibrationPattern: vibration ? _vibrationPattern : null,
      icon: '@mipmap/ic_launcher',
    );

    final iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: sound,
    );

    await _plugin.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      NotificationDetails(android: androidDetails, iOS: iosDetails),
      payload: payload,
    );
  }
}
