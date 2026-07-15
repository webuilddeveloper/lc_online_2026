import 'package:LawyerOnline/shared/api_provider.dart';
import 'package:intl/intl.dart';

enum VideoCallJoinResult {
  allowed,
  tooEarly,
  tooLate,
}

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

  static bool canJoinNow(
    Map<String, dynamic> caseData, {
    int minutesBefore = 15,
    int minutesAfter = 15,
  }) =>
      checkJoinWindow(
        caseData,
        minutesBefore: minutesBefore,
        minutesAfter: minutesAfter,
      ) ==
      VideoCallJoinResult.allowed;

  /// แชท + วิดีโอคอล ใช้ได้เฉพาะในช่วงเวลานัด
  static bool canChatAndCall(
    Map<String, dynamic> caseData, {
    int minutesBefore = 15,
    int minutesAfter = 15,
  }) =>
      canJoinNow(
        caseData,
        minutesBefore: minutesBefore,
        minutesAfter: minutesAfter,
      );

  /// ตรวจช่วงเวลานัด (ก่อนนัด [minutesBefore] ถึงหลังจบ [minutesAfter])
  /// เคสด่วนใช้ caseDate + startTime + endTime/hour เช่นกัน
  /// ไม่มีกำหนดวันเวลาเลย → อนุญาต
  static VideoCallJoinResult checkJoinWindow(
    Map<String, dynamic> caseData, {
    int minutesBefore = 15,
    int minutesAfter = 15,
  }) {
    final status = _asInt(caseData['caseStatus'] ?? caseData['status']);
    if (status == 0 || status == 4) {
      return VideoCallJoinResult.tooLate;
    }

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
    final hourRaw = _first(caseData, const ['hour', 'durationHours']);
    final durationMinutes = _asInt(caseData['durationMinutes']);

    // ไม่มีกำหนดนัด → ไม่ล็อกด้วยเวลา
    if (dateStr.isEmpty && startStr.isEmpty && hourRaw.isEmpty && durationMinutes <= 0) {
      return VideoCallJoinResult.allowed;
    }

    final date = dateStr.isNotEmpty ? _parseDate(dateStr) : DateTime.now();
    if (date == null) return VideoCallJoinResult.allowed;

    final start = _parseTime(startStr.split(RegExp(r'\s*[-–—]\s*')).first);
    final endRaw = _first(caseData, const ['endTime', 'timeEnd']);
    final endParts = startStr.split(RegExp(r'\s*[-–—]\s*'));
    final end = _parseTime(
      endRaw.isNotEmpty
          ? endRaw
          : (endParts.length > 1 ? endParts.last : ''),
    );

    final startAt = DateTime(
      date.year,
      date.month,
      date.day,
      start?.hour ?? 0,
      start?.minute ?? 0,
    );

    DateTime endAt;
    if (end != null) {
      endAt = DateTime(date.year, date.month, date.day, end.hour, end.minute);
      // ข้ามคืน
      if (!endAt.isAfter(startAt)) {
        endAt = endAt.add(const Duration(days: 1));
      }
    } else if (durationMinutes > 0) {
      endAt = startAt.add(Duration(minutes: durationMinutes));
    } else {
      final hours = double.tryParse(hourRaw) ?? 0;
      if (hours > 0) {
        endAt = startAt.add(Duration(minutes: (hours * 60).round()));
      } else if (start != null) {
        endAt = startAt.add(const Duration(hours: 1));
      } else {
        endAt = DateTime(date.year, date.month, date.day, 23, 59);
      }
    }

    final now = DateTime.now();
    final caseType = _asInt(caseData['caseType']);
    final isUrgent = caseType == 2 || caseType == 0;
    // เคสด่วนเริ่มได้ทันทีหลังเปิดเคส ไม่ต้อง buffer ก่อนเริ่ม
    final before = isUrgent ? 0 : minutesBefore;
    final after = isUrgent ? 0 : minutesAfter;
    final windowStart = startAt.subtract(Duration(minutes: before));
    final windowEnd = endAt.add(Duration(minutes: after));

    if (now.isBefore(windowStart)) return VideoCallJoinResult.tooEarly;
    if (now.isAfter(windowEnd)) return VideoCallJoinResult.tooLate;
    return VideoCallJoinResult.allowed;
  }

  static String joinWindowMessage(Map<String, dynamic> caseData) {
    final dateStr = _first(caseData, const ['caseDate', 'appointmentDate']);
    final startStr = _first(caseData, const ['startTime', 'timeStart']);
    final endStr = _first(caseData, const ['endTime', 'timeEnd']);
    if (dateStr.isEmpty) return '';
    final time = endStr.isNotEmpty
        ? '$startStr - $endStr'
        : startStr;
    return '$dateStr ${time.trim()}'.trim();
  }

  static int _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? -1;
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
    final raw = value.trim();
    if (RegExp(r'^\d{8}(\d{6})?$').hasMatch(raw)) {
      final y = int.parse(raw.substring(0, 4));
      final m = int.parse(raw.substring(4, 6));
      final d = int.parse(raw.substring(6, 8));
      return DateTime(y, m, d);
    }
    for (final pattern in const ['dd/MM/yyyy', 'yyyy-MM-dd', 'dd-MM-yyyy']) {
      try {
        return DateFormat(pattern).parseStrict(raw);
      } catch (_) {}
    }
    try {
      return DateTime.parse(raw);
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
