import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class NotificationService {
  static final _messaging = FirebaseMessaging.instance;
  static final _localNotif = FlutterLocalNotificationsPlugin();

  // ✅ เรียกใน main() ก่อน runApp
  static Future<void> init() async {
    // 1. ขอ permission
    await _messaging.requestPermission(
      alert: true,
      sound: true,
      badge: true,
    );

    // 2. ตั้งค่า local notification
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings();
    await _localNotif.initialize(
      const InitializationSettings(android: android, iOS: ios),
    );

    // 3. สร้าง Android Notification Channel
    const channel = AndroidNotificationChannel(
      'incoming_call',
      'สายเรียกเข้า',
      importance: Importance.max,
      playSound: true,
    );
    await _localNotif.resolvePlatformSpecificImplementation;
    AndroidFlutterLocalNotificationsPlugin().createNotificationChannel(channel);

    // 4. ดึง FCM Token แล้วเก็บลง Firestore
    final token = await _messaging.getToken();
    if (token != null) await saveFcmToken(token);

    // Token อาจเปลี่ยนได้ — ฟัง update
    _messaging.onTokenRefresh.listen(saveFcmToken);

    // 5. ฟัง notification ขณะแอพเปิดอยู่ (Foreground)
    FirebaseMessaging.onMessage.listen((message) {
      final data = message.data;
      if (data['type'] == 'incoming_call') {
        showCallNotification(
          callerName: data['callerName'] ?? 'ไม่ทราบชื่อ',
          callId: data['callId'] ?? '',
        );
      }
    });
  }

  static Future<void> saveFcmToken(String token) async {
    const storage = FlutterSecureStorage();
    final userType = await storage.read(key: 'userType') ?? 'unknown';
    final name = await storage.read(key: 'name') ?? '';

    // ✅ เก็บ token โดยใช้ userType เป็น document id
    await FirebaseFirestore.instance
        .collection('devices')
        .doc(userType) // "lawyer" หรือ "user"
        .set({
      'fcmToken': token,
      'userType': userType,
      'name': name,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // ✅ แสดง notification สายเรียกเข้า
  static Future<void> showCallNotification({
    required String callerName,
    required String callId,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'incoming_call',
      'สายเรียกเข้า',
      importance: Importance.max,
      priority: Priority.high,
      fullScreenIntent: true, // แสดงแม้หน้าจอล็อค
      playSound: true,
      enableVibration: true,
      styleInformation: BigTextStyleInformation(''),
    );

    await _localNotif.show(
      callId.hashCode,
      '📞 สายเรียกเข้า',
      '$callerName กำลังโทรหาคุณ',
      const NotificationDetails(android: androidDetails),
    );
  }
}
