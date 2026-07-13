import 'dart:async';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// แจ้งเตือนก่อนนัดหมาย (local notification)
class AppointmentReminderService {
  AppointmentReminderService._();

  static final _plugin = FlutterLocalNotificationsPlugin();
  static bool _initialized = false;
  static final _timers = <String, Timer>{};

  static Future<void> init() async {
    if (_initialized) return;
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings();
    await _plugin.initialize(
      const InitializationSettings(android: android, iOS: ios),
    );
    _initialized = true;
  }

  static Future<void> scheduleForCase(Map<String, dynamic> caseData) async {
    await init();
    final code = caseData['code']?.toString() ?? '';
    if (code.isEmpty) return;

    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool('reminder_scheduled_$code') == true) return;

    final dateStr = caseData['caseDate']?.toString() ?? '';
    final startStr = (caseData['startTime']?.toString() ?? '')
        .split(' - ')
        .first
        .trim();
    if (dateStr.isEmpty) return;

    final date = _parseDate(dateStr);
    final time = _parseTime(startStr);
    if (date == null || time == null) return;

    final appointmentAt = DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );
    if (appointmentAt.isBefore(DateTime.now())) return;

    _scheduleTimer(
      caseCode: code,
      when: appointmentAt.subtract(const Duration(hours: 24)),
      suffix: '24h',
      message: 'คุณมีนัดปรึกษาทนายในอีก 24 ชั่วโมง',
    );
    _scheduleTimer(
      caseCode: code,
      when: appointmentAt.subtract(const Duration(hours: 1)),
      suffix: '1h',
      message: 'คุณมีนัดปรึกษาทนายในอีก 1 ชั่วโมง',
    );

    await prefs.setBool('reminder_scheduled_$code', true);
  }

  static void _scheduleTimer({
    required String caseCode,
    required DateTime when,
    required String suffix,
    required String message,
  }) {
    final delay = when.difference(DateTime.now());
    if (delay.isNegative) return;
    final key = '${caseCode}_$suffix';
    _timers[key]?.cancel();
    _timers[key] = Timer(delay, () async {
      await _plugin.show(
        key.hashCode,
        'เตือนนัดหมาย',
        message,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'appointment_reminders',
            'Appointment Reminders',
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(),
        ),
      );
    });
  }

  static Future<void> cancelForCase(String caseCode) async {
    for (final suffix in ['24h', '1h']) {
      final key = '${caseCode}_$suffix';
      _timers[key]?.cancel();
      _timers.remove(key);
      await _plugin.cancel(key.hashCode);
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('reminder_scheduled_$caseCode');
  }

  static DateTime? _parseDate(String value) {
    for (final pattern in const ['dd/MM/yyyy', 'yyyy-MM-dd']) {
      try {
        return DateFormat(pattern).parseStrict(value.trim());
      } catch (_) {}
    }
    return null;
  }

  static _Clock? _parseTime(String value) {
    final raw = value.replaceAll('.', ':').trim();
    if (raw.isEmpty) return null;
    final parts = raw.split(':');
    if (parts.length < 2) return null;
    final h = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    if (h == null || m == null) return null;
    return _Clock(h, m);
  }
}

class _Clock {
  const _Clock(this.hour, this.minute);
  final int hour;
  final int minute;
}
