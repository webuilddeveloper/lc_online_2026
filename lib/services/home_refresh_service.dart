import 'dart:async';

import 'package:flutter/foundation.dart';

/// สัญญาณให้หน้าแรกโหลดข้อมูลใหม่ (หลังจอง / ยกเลิก / กลับมาแท็บ home)
class HomeRefreshService extends ChangeNotifier {
  HomeRefreshService._();

  static final HomeRefreshService instance = HomeRefreshService._();

  Timer? _debounce;
  DateTime? _lastNotifyAt;

  /// กันยิง refresh ถี่เกินไป (เช่น listener ซ้อน / FCM ซ้ำ)
  void requestRefresh() {
    final now = DateTime.now();
    if (_lastNotifyAt != null &&
        now.difference(_lastNotifyAt!) < const Duration(milliseconds: 800)) {
      return;
    }
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 250), () {
      _lastNotifyAt = DateTime.now();
      notifyListeners();
    });
  }
}
