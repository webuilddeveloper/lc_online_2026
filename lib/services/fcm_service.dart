import 'package:flutter/foundation.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:LawyerOnline/shared/api_provider.dart';
import 'package:LawyerOnline/models/user_profile_store.dart';

class FcmService {
  static Future<void> registerFcmToken(String code) async {
    try {
      final fcm = FirebaseMessaging.instance;
      await fcm.requestPermission();

      if (defaultTargetPlatform == TargetPlatform.iOS) {
        String? apnsToken = await fcm.getAPNSToken();
        int retries = 0;
        while (apnsToken == null && retries < 20) {
          await Future.delayed(const Duration(milliseconds: 500));
          apnsToken = await fcm.getAPNSToken();
          retries++;
        }
        if (apnsToken == null) {
          debugPrint('APNS token still null, skip FCM registration');
          return;
        }
      }

      final token = await fcm.getToken();
      print('============== ${token}');
      debugPrint('FCM TOKEN: $token');

      if (token != null) {
        await postDio('$server/m/register/updateFcmToken', {
          'code': code,
          'fcmToken': token,
        });
      }

      fcm.onTokenRefresh.listen((newToken) {
        postDio('$server/m/register/updateFcmToken', {
          'code': UserProfileStore.instance.code,
          'fcmToken': newToken,
        });
      });
    } catch (e) {
      debugPrint('registerFcmToken error: $e');
    }
  }
}