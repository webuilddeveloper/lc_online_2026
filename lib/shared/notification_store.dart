import 'package:flutter/material.dart';

class NotificationStore extends ChangeNotifier {
  NotificationStore._internal();
  static final NotificationStore instance = NotificationStore._internal();

  int _unreadCount = 0;
  int get unreadCount => _unreadCount;

  void incrementUnread() {
    _unreadCount++;
    notifyListeners();
  }

  void clearUnread() {
    _unreadCount = 0;
    notifyListeners();
  }

  void setUnread(int count) {
    _unreadCount = count;
    notifyListeners();
  }
}