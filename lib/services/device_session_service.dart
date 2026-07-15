import 'dart:io';

import 'package:LawyerOnline/shared/api_provider.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';

class DeviceSession {
  const DeviceSession({
    required this.token,
    required this.deviceName,
    required this.platform,
    required this.createDate,
    required this.createTime,
    required this.isCurrent,
  });

  final String token;
  final String deviceName;
  final String platform;
  final String createDate;
  final String createTime;
  final bool isCurrent;

  factory DeviceSession.fromJson(Map<String, dynamic> json) => DeviceSession(
        token: json['token']?.toString() ?? '',
        deviceName: json['deviceName']?.toString() ?? '',
        platform: json['platform']?.toString() ?? '',
        createDate: json['createDate']?.toString() ?? '',
        createTime: json['createTime']?.toString() ?? '',
        isCurrent: json['isCurrent'] == true,
      );
}

class DeviceSessionService {
  DeviceSessionService._();

  static Future<List<DeviceSession>> loadSessions({
    required String userCode,
    String? currentToken,
  }) async {
    final result = await postDio('${server}/m/register/sessions/read', {
      'userCode': userCode,
      'currentToken': currentToken ?? '',
    });
    if (result['status'] != 'S' || result['objectData'] is! List) return [];
    return (result['objectData'] as List)
        .map((e) => DeviceSession.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  static Future<bool> revoke({
    required String userCode,
    required String token,
  }) async {
    final result = await postDio('${server}/m/register/sessions/revoke', {
      'userCode': userCode,
      'token': token,
    });
    return result['status'] == 'S';
  }

  static Future<void> registerCurrentDevice({
    required String userCode,
    required String token,
  }) async {
    final info = DeviceInfoPlugin();
    String deviceName = 'Unknown device';
    String platform = 'unknown';

    if (kIsWeb) {
      platform = 'web';
      deviceName = 'Web Browser';
    } else if (Platform.isAndroid) {
      final android = await info.androidInfo;
      platform = 'android';
      deviceName = '${android.brand} ${android.model}';
    } else if (Platform.isIOS) {
      final ios = await info.iosInfo;
      platform = 'ios';
      deviceName = ios.name;
    }

    await postDio('${server}/m/register/sessions/register-device', {
      'userCode': userCode,
      'token': token,
      'deviceName': deviceName,
      'platform': platform,
    });
  }
}
