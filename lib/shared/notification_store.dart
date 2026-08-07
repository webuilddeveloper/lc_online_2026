import 'package:flutter/material.dart';
import 'package:LawyerOnline/models/user_profile_store.dart';
import 'package:LawyerOnline/shared/api_provider.dart';

class NotificationStore extends ChangeNotifier {
  NotificationStore._internal();
  static final NotificationStore instance = NotificationStore._internal();

  int _unreadCount = 0;
  int _chatBadgeCount = 0;
  int _communityBadgeCount = 0;
  int _appointmentBadgeCount = 0;
  bool _isLoading = false;

  int get unreadCount => _unreadCount;
  int get chatBadgeCount => _chatBadgeCount;
  int get communityBadgeCount => _communityBadgeCount;
  int get appointmentBadgeCount => _appointmentBadgeCount;
  bool get isLoading => _isLoading;

  int badgeCountForNavIndex(int index) {
    switch (index) {
      case 1:
        return _chatBadgeCount;
      case 2:
        return _communityBadgeCount;
      case 3:
        return _appointmentBadgeCount;
      default:
        return 0;
    }
  }

  bool shouldShowNavBadge(int index, {required bool enabled}) {
    if (!enabled) return false;
    return badgeCountForNavIndex(index) > 0;
  }

  Future<void> refresh() async {
    if (UserProfileStore.instance.typeLogin == 'null') {
      _resetCounts();
      return;
    }

    final userCode = UserProfileStore.instance.code;
    if (userCode.isEmpty) return;

    _isLoading = true;
    notifyListeners();

    try {
      final result = await postDio('$server/m/notification/unreadSummary', {
        'code': userCode,
      });

      if (result['status'] != 'S') return;

      final data = result['objectData'];
      if (data is Map) {
        _unreadCount = _readInt(data['total'], fallback: result['totalData']);
        _chatBadgeCount = _readInt(data['chat']);
        _appointmentBadgeCount = _readInt(data['appointment']);
        _communityBadgeCount = _readInt(data['community']);
      } else {
        _unreadCount = _readInt(result['totalData']);
      }
    } catch (e) {
      debugPrint('NotificationStore.refresh error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> markAllRead() async {
    final userCode = UserProfileStore.instance.code;
    if (userCode.isEmpty) return;

    try {
      await postDio('$server/m/notification/markRead', {
        'userCode': userCode,
      });
      _resetCounts();
    } catch (e) {
      debugPrint('NotificationStore.markAllRead error: $e');
    }
  }

  Future<void> markChatPageRead() async {
    final userCode = UserProfileStore.instance.code;
    if (userCode.isEmpty) return;

    try {
      await postDio('$server/m/notification/markPageRead', {
        'userCode': userCode,
        'page': 'chat',
      });
      _chatBadgeCount = 0;
      notifyListeners();
    } catch (e) {
      debugPrint('NotificationStore.markChatPageRead error: $e');
    }
  }

  void incrementUnread() {
    _unreadCount++;
    notifyListeners();
  }

  void clearUnread() {
    _resetCounts();
  }

  void setUnread(int count) {
    _unreadCount = count;
    notifyListeners();
  }

  void _resetCounts() {
    _unreadCount = 0;
    _chatBadgeCount = 0;
    _communityBadgeCount = 0;
    _appointmentBadgeCount = 0;
    notifyListeners();
  }

  int _readInt(dynamic value, {dynamic fallback}) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    final parsed = int.tryParse(value?.toString() ?? '');
    if (parsed != null) return parsed;
    if (fallback != null) return _readInt(fallback);
    return 0;
  }
}
