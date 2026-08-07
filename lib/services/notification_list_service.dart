import 'package:LawyerOnline/models/user_profile_store.dart';
import 'package:LawyerOnline/shared/api_provider.dart';
import 'package:LawyerOnline/shared/notification_store.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:intl/intl.dart';

/// โหลดและจัดรูปแบบรายการแจ้งเตือนจาก API (ใช้ร่วม mobile + desktop)
class NotificationListService {
  NotificationListService._();

  /// แชทข้อความ / สายเรียกเข้า ไม่แสดงในหน้ารายการแจ้งเตือน
  /// แต่แจ้งเตือนนัด/เริ่มปรึกษา (session_start ฯลฯ) ต้องแสดงแม้ page เดิมเป็น chat
  static const _listVisibleTypes = {
    'session_start',
    'session_end',
    'appointment_reminder',
    'payment_confirmed',
    'case_payment_confirmed',
    'cancel_review_approved',
    'cancel_review_rejected',
    'cancel_review_pending',
    'cancel_review_submitted',
    'call_ended',
  };

  static bool _shouldShow(Map<String, dynamic> item) {
    final type = item['type']?.toString().toLowerCase() ?? '';
    final page = item['page']?.toString().toLowerCase() ?? '';

    if (_listVisibleTypes.contains(type)) return true;

    // ข้อความแชท
    if (type == 'chat_message' || type == 'chat') return false;
    // วิดีโอคอล / สายเรียกเข้า
    if (type.contains('video_call') || page.contains('video_call')) {
      return false;
    }
    if (type == 'call' ||
        type == 'incoming_call' ||
        page == 'incoming_call' ||
        page.contains('call')) {
      return false;
    }
    // แจ้งเตือนแชททั่วไป (ไม่รวม session ที่ whitelist แล้ว)
    if (page == 'chat') return false;

    return true;
  }

  static Future<List<Map<String, dynamic>>> load({
    int skip = 0,
    int limit = 50,
  }) async {
    final code = UserProfileStore.instance.code;
    if (code.isEmpty) return [];

    try {
      final result = await postDio('$server/m/notification/read', {
        'code': code,
        'skip': skip,
        'limit': limit,
      });

      final raw = result['objectData'];
      final list = raw is List
          ? raw
              .whereType<Map>()
              .map((e) => normalize(Map<String, dynamic>.from(e)))
              .toList()
          : <Map<String, dynamic>>[];

      final filtered = list.where(_shouldShow).toList(growable: false);

      filtered.sort(_compareNotification);

      // unread badge ให้สอดคล้องกับรายการที่ “แสดงจริง”
      final unread = filtered.where((n) => n['isRead'] != true).length;
      NotificationStore.instance.setUnread(unread);

      return filtered;
    } catch (_) {
      return [];
    }
  }

  static Map<String, dynamic> normalize(Map<String, dynamic> item) {
    final dt = _parseDate(item);
    final group = _dateGroup(dt);
    return {
      ...item,
      'type': item['type'] ?? item['page'] ?? 'system',
      'title': item['title']?.toString() ?? '',
      'detail': item['body']?.toString() ?? '',
      'body': item['body']?.toString() ?? '',
      'time': _formatTime(item, dt),
      'date': group,
      'fullDetail': item['body']?.toString() ?? '',
      'page': item['page']?.toString() ?? '',
      'refCode': item['refCode']?.toString() ?? '',
      'isRead': item['isRead'] == true,
    };
  }

  static Map<String, dynamic> toDetailData(Map<String, dynamic> item) {
    return {
      'type': item['type'] ?? item['page'] ?? 'system',
      'title': item['title']?.toString() ?? '',
      'detail': item['body']?.toString() ?? item['detail']?.toString() ?? '',
      'body': item['body']?.toString() ?? '',
      'time': item['time']?.toString() ?? '',
      'fullDetail':
          item['fullDetail']?.toString() ?? item['body']?.toString() ?? '',
      'page': item['page']?.toString() ?? '',
      'refCode': item['refCode']?.toString() ?? '',
    };
  }

  static Future<void> markOneRead(Map<String, dynamic> item) async {
    item['isRead'] = true;
    final code = item['code']?.toString();
    if (code == null || code.isEmpty) return;
    try {
      await postDio('$server/m/notification/markRead', {'code': code});
      await NotificationStore.instance.refresh();
    } catch (_) {}
  }

  static Future<void> markAllRead(List<Map<String, dynamic>> items) async {
    for (final n in items) {
      n['isRead'] = true;
    }
    await NotificationStore.instance.markAllRead();
    await NotificationStore.instance.refresh();
  }

  static int _compareNotification(
    Map<String, dynamic> a,
    Map<String, dynamic> b,
  ) {
    final aRead = a['isRead'] == true;
    final bRead = b['isRead'] == true;
    if (aRead != bRead) return aRead ? 1 : -1;

    final aDt = _parseDate(a);
    final bDt = _parseDate(b);
    if (aDt != null && bDt != null) return bDt.compareTo(aDt);
    if (aDt != null) return -1;
    if (bDt != null) return 1;
    return 0;
  }

  static (int, int) _parseTimeParts(dynamic raw) {
    final value = raw?.toString().trim() ?? '';
    if (value.isEmpty) return (0, 0);
    if (value.contains(':')) {
      final parts = value.split(':');
      return (
        int.tryParse(parts[0]) ?? 0,
        parts.length > 1 ? (int.tryParse(parts[1]) ?? 0) : 0,
      );
    }
    if (value.length >= 4) {
      return (
        int.tryParse(value.substring(0, 2)) ?? 0,
        int.tryParse(value.substring(2, 4)) ?? 0,
      );
    }
    return (0, 0);
  }

  static DateTime? _parseDocDate(dynamic raw) {
    if (raw == null) return null;
    if (raw is DateTime) return raw.toLocal();
    if (raw is num) {
      return DateTime.fromMillisecondsSinceEpoch(raw.toInt()).toLocal();
    }
    if (raw is Map) {
      final inner = raw[r'$date'] ?? raw['date'];
      if (inner is num) {
        return DateTime.fromMillisecondsSinceEpoch(inner.toInt()).toLocal();
      }
      if (inner != null) {
        return DateTime.tryParse(inner.toString())?.toLocal();
      }
    }
    if (raw is String && raw.isNotEmpty) {
      return DateTime.tryParse(raw)?.toLocal();
    }
    return null;
  }

  static DateTime? _parseDate(Map<String, dynamic> item) {
    final createDate = item['createDate']?.toString().trim() ?? '';
    if (createDate.length >= 14) {
      try {
        return DateTime(
          int.parse(createDate.substring(0, 4)),
          int.parse(createDate.substring(4, 6)),
          int.parse(createDate.substring(6, 8)),
          int.parse(createDate.substring(8, 10)),
          int.parse(createDate.substring(10, 12)),
          int.parse(createDate.substring(12, 14)),
        );
      } catch (_) {}
    }
    if (createDate.length >= 8) {
      try {
        final (h, m) = _parseTimeParts(
          item['createTime'] ?? item['docTime'] ?? '',
        );
        return DateTime(
          int.parse(createDate.substring(0, 4)),
          int.parse(createDate.substring(4, 6)),
          int.parse(createDate.substring(6, 8)),
          h,
          m,
        );
      } catch (_) {}
    }
    final docDate = _parseDocDate(item['docDate']);
    if (docDate != null) {
      final (h, m) = _parseTimeParts(item['docTime'] ?? item['createTime']);
      if (h != 0 || m != 0) {
        return DateTime(docDate.year, docDate.month, docDate.day, h, m);
      }
      return docDate;
    }
    return null;
  }

  static String _dateGroup(DateTime? dt) {
    if (dt == null) return 'earlier';
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final itemDay = DateTime(dt.year, dt.month, dt.day);
    final diff = today.difference(itemDay).inDays;
    if (diff == 0) return 'today';
    if (diff == 1) return 'yesterday';
    return 'earlier';
  }

  static String _formatTime(Map<String, dynamic> item, DateTime? dt) {
    if (dt != null) return DateFormat('HH:mm').format(dt);
    final (h, m) = _parseTimeParts(item['createTime'] ?? item['docTime']);
    if (h != 0 || m != 0) {
      return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';
    }
    return '';
  }
}
