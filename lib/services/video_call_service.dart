import 'package:LawyerOnline/shared/api_provider.dart';
import 'package:intl/intl.dart';

/// จัดการห้อง video call ต่อเคส — ไม่ใช้ room code คงที่
class VideoCallService {
  VideoCallService._();

  /// สร้าง room code จาก caseCode (sanitize สำหรับ WebRTC room)
  static String roomCodeFromCase(String caseCode) {
    final raw = caseCode.trim();
    if (raw.isEmpty) return 'lc-default-room';
    final sanitized =
        raw.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '').toLowerCase();
    if (sanitized.length >= 6) return 'lc-$sanitized';
    return 'lc-${sanitized.padRight(6, '0')}';
  }

  /// ลองขอ room จาก API ก่อน ถ้าไม่มีใช้ derived code
  static Future<String> resolveRoomCode({
    required String caseCode,
    String? messageRoomCode,
  }) async {
    final existing = messageRoomCode?.trim() ?? '';
    if (existing.isNotEmpty) return existing;

    try {
      final result = await postDio('${server}/m/video/room/resolve', {
        'caseCode': caseCode,
      });
      final code = result['objectData']?['roomCode']?.toString().trim() ?? '';
      if (result['status'] == 'S' && code.isNotEmpty) return code;
    } catch (_) {}

    return roomCodeFromCase(caseCode);
  }

  /// ตรวจว่าอยู่ในช่วงเวลานัดหรือไม่ (buffer ก่อน/หลัง)
  static bool canJoinNow(
    Map<String, dynamic> caseData, {
    int minutesBefore = 15,
    int minutesAfter = 60,
  }) {
    final dateStr = _first(caseData, const [
      'caseDate',
      'appointmentDate',
      'date',
    ]);
    final startStr = _first(caseData, const [
      'startTime',
      'timeStart',
      'appointmentTime',
    ]);
    if (dateStr.isEmpty) return true;

    final date = _parseDate(dateStr);
    if (date == null) return true;

    final start = _parseTime(startStr.split(' - ').first);
    final endRaw = _first(caseData, const ['endTime', 'timeEnd']);
    final end = _parseTime(
      endRaw.isNotEmpty ? endRaw : startStr.split(' - ').last,
    );

    final startAt = DateTime(
      date.year,
      date.month,
      date.day,
      start?.hour ?? 0,
      start?.minute ?? 0,
    );
    final endAt = DateTime(
      date.year,
      date.month,
      date.day,
      end?.hour ?? (start?.hour ?? 23),
      end?.minute ?? (start?.minute ?? 59),
    );

    final now = DateTime.now();
    final windowStart = startAt.subtract(Duration(minutes: minutesBefore));
    final windowEnd = endAt.add(Duration(minutes: minutesAfter));
    return !now.isBefore(windowStart) && !now.isAfter(windowEnd);
  }

  static String joinWindowMessage(Map<String, dynamic> caseData) {
    final dateStr = _first(caseData, const ['caseDate', 'appointmentDate']);
    final startStr = _first(caseData, const ['startTime', 'timeStart']);
    if (dateStr.isEmpty) return '';
    return '$dateStr ${startStr.isNotEmpty ? startStr : ''}'.trim();
  }

  static String _first(Map<String, dynamic> source, List<String> keys) {
    for (final key in keys) {
      final v = source[key];
      if (v != null && v.toString().trim().isNotEmpty) {
        return v.toString().trim();
      }
    }
    return '';
  }

  static DateTime? _parseDate(String value) {
    for (final pattern in const ['dd/MM/yyyy', 'yyyy-MM-dd', 'dd-MM-yyyy']) {
      try {
        return DateFormat(pattern).parseStrict(value.trim());
      } catch (_) {}
    }
    try {
      return DateTime.parse(value.trim());
    } catch (_) {
      return null;
    }
  }

  static _Clock? _parseTime(String value) {
    final raw = value.trim().replaceAll('.', ':');
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
