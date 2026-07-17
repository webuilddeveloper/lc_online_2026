import 'package:easy_localization/easy_localization.dart';

/// จัดรูปแบบ preview รายการแชท (ข้อความล่าสุด / unread / เวลา)
class ChatListPreviewService {
  ChatListPreviewService._();

  static int unreadCount(Map<String, dynamic> conv) {
    for (final key in [
      'unreadCount',
      'unReadCount',
      'countUnread',
      'newMessageCount',
    ]) {
      final value = conv[key];
      if (value != null) return _asInt(value);
    }
    final user2 = conv['user2Model'];
    if (user2 is Map) {
      for (final key in ['unreadCount', 'unReadCount']) {
        final value = user2[key];
        if (value != null) return _asInt(value);
      }
    }
    return 0;
  }

  static String lastMessageText(Map<String, dynamic> conv) {
    for (final key in ['lastMessage', 'lastChat', 'content', 'message']) {
      final value = conv[key];
      if (value != null && value.toString().trim().isNotEmpty) {
        return value.toString().trim();
      }
    }
    final user2 = conv['user2Model'];
    if (user2 is Map) {
      for (final key in ['lastMessage', 'lastChat']) {
        final value = user2[key];
        if (value != null && value.toString().trim().isNotEmpty) {
          return value.toString().trim();
        }
      }
    }
    return '';
  }

  static String lastSenderId(Map<String, dynamic> conv) {
    for (final key in [
      'lastSenderId',
      'lastSender',
      'lastMessageSender',
      'senderId',
      'createBy',
      'reference',
    ]) {
      final value = conv[key];
      if (value != null && value.toString().trim().isNotEmpty) {
        return value.toString().trim();
      }
    }
    return '';
  }

  static bool isLastMessageFromMe(
    Map<String, dynamic> conv,
    String myUserId,
  ) {
    final mine = myUserId.trim();
    if (mine.isEmpty) return false;

    final flag = conv['lastMessageIsMe'] ?? conv['isMe'];
    if (flag == true) return true;
    if (flag == false) return false;

    final sender = lastSenderId(conv);
    if (sender.isNotEmpty) return sender == mine;

    final userA = conv['userA']?.toString().trim() ?? '';
    final userB = conv['userB']?.toString().trim() ?? '';
    final lastByA = conv['lastMessageByA'] == true;
    final lastByB = conv['lastMessageByB'] == true;
    if (lastByA || lastByB) {
      if (mine == userA) return lastByA;
      if (mine == userB) return lastByB;
    }

    // ถ้ายังไม่อ่าน แปลว่าฝั่งตรงข้ามส่งมา
    if (unreadCount(conv) > 0) return false;

    return false;
  }

  static DateTime? lastMessageAt(Map<String, dynamic> conv) {
    for (final key in [
      'lastMessageTime',
      'lastMessageDate',
      'updateDate',
      'docDate',
      'createDate',
      'lastUpdate',
    ]) {
      final parsed = _parseDate(conv[key]);
      if (parsed != null) return parsed;
    }
    return null;
  }

  static String peerName(Map<String, dynamic> conv) {
    final user2 = conv['user2Model'];
    if (user2 is Map) {
      final first = user2['firstName']?.toString().trim() ?? '';
      final last = user2['lastName']?.toString().trim() ?? '';
      final full = '$first $last'.trim();
      if (full.isNotEmpty) return full;
      final name = user2['fullName']?.toString().trim() ?? '';
      if (name.isNotEmpty) return name;
    }
    return conv['name']?.toString() ?? '';
  }

  /// ข้อความบรรทัดล่างในรายการแชท
  static String subtitle(
    Map<String, dynamic> conv,
    String myUserId,
  ) {
    final unread = unreadCount(conv);
    final fromMe = isLastMessageFromMe(conv, myUserId);
    final timeLabel = relativeReceivedLabel(lastMessageAt(conv));

    if (fromMe) {
      return sentAgoLabel(lastMessageAt(conv));
    }

    if (unread > 1) {
      return 'chatNewMessages'.tr(args: ['$unread', timeLabel]);
    }

    if (unread == 1) {
      final text = lastMessageText(conv);
      return text.isNotEmpty ? text : 'chatNewMessage'.tr();
    }

    final text = lastMessageText(conv);
    return text.isNotEmpty ? text : '';
  }

  static bool isSubtitleBold(
    Map<String, dynamic> conv,
    String myUserId,
  ) {
    return !isLastMessageFromMe(conv, myUserId) && unreadCount(conv) == 1;
  }

  static bool isNameBold(Map<String, dynamic> conv) {
    return unreadCount(conv) > 0;
  }

  /// เวลาขวาบนของรายการ
  static String headerTimeLabel(Map<String, dynamic> conv) {
    final dt = lastMessageAt(conv);
    if (dt == null) {
      final raw = conv['lastMessageTime']?.toString() ?? '';
      return raw.length > 5 ? raw : '';
    }

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(dt.year, dt.month, dt.day);

    if (day == today) {
      return DateFormat('HH:mm').format(dt);
    }
    if (today.difference(day).inDays == 1) {
      return 'timeline.yesterday'.tr();
    }
    return DateFormat('dd/MM').format(dt);
  }

  static String relativeReceivedLabel(DateTime? dt) {
    if (dt == null) return '';
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'chatJustNow'.tr();
    if (diff.inMinutes < 60) {
      return 'chatMinutesAgo'.tr(args: ['${diff.inMinutes}']);
    }
    if (diff.inHours < 24) {
      return 'chatHoursAgo'.tr(args: ['${diff.inHours}']);
    }
    if (diff.inDays == 1) return 'timeline.yesterday'.tr();
    return DateFormat('dd/MM').format(dt);
  }

  static String sentAgoLabel(DateTime? dt) {
    if (dt == null) return 'chatSentJustNow'.tr();
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'chatSentJustNow'.tr();
    if (diff.inMinutes < 60) {
      return 'chatSentMinutesAgo'.tr(args: ['${diff.inMinutes}']);
    }
    if (diff.inHours < 24) {
      return 'chatSentHoursAgo'.tr(args: ['${diff.inHours}']);
    }
    if (diff.inDays == 1) return 'chatSentYesterday'.tr();
    return 'chatSentOnDate'.tr(
      args: [DateFormat('dd/MM').format(dt)],
    );
  }

  static int _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static DateTime? _parseDate(dynamic raw) {
    if (raw == null) return null;
    if (raw is DateTime) return raw.toLocal();
    if (raw is num) {
      final ms = raw > 9999999999 ? raw.toInt() : raw.toInt() * 1000;
      return DateTime.fromMillisecondsSinceEpoch(ms).toLocal();
    }
    if (raw is Map) {
      final inner = raw[r'$date'] ?? raw['date'];
      if (inner != null) return _parseDate(inner);
    }
    final text = raw.toString().trim();
    if (text.isEmpty) return null;

    if (text.length >= 14 && RegExp(r'^\d{14}$').hasMatch(text)) {
      try {
        return DateTime(
          int.parse(text.substring(0, 4)),
          int.parse(text.substring(4, 6)),
          int.parse(text.substring(6, 8)),
          int.parse(text.substring(8, 10)),
          int.parse(text.substring(10, 12)),
          int.parse(text.substring(12, 14)),
        );
      } catch (_) {}
    }

    if (text.length >= 8 && RegExp(r'^\d{8}').hasMatch(text)) {
      try {
        return DateTime(
          int.parse(text.substring(0, 4)),
          int.parse(text.substring(4, 6)),
          int.parse(text.substring(6, 8)),
        );
      } catch (_) {}
    }

    return DateTime.tryParse(text)?.toLocal();
  }
}
