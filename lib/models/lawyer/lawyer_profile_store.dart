import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

// ══════════════════════════════════════════════════════════
//  LawyerProfileStore — Single source of truth
//  สำหรับ state ของ lawyer ที่ใช้ข้ามหลายหน้า
//
//  ตอนนี้เก็บ:
//  - isUrgentCaseEnabled → รับเคสด่วน
//
//  วิธีใช้:
//  await LawyerProfileStore.instance.load(); // โหลดตอนเริ่ม app
//  LawyerProfileStore.instance.isUrgentCaseEnabled // อ่านค่า
//  await LawyerProfileStore.instance.setUrgentCase(true) // เซ็ตค่า
// ══════════════════════════════════════════════════════════

class LawyerProfileStore extends ChangeNotifier {
  LawyerProfileStore._();
  static final LawyerProfileStore instance = LawyerProfileStore._();

  static const _storage = FlutterSecureStorage();

  // ── State ──────────────────────────────────────────────
  bool _isUrgentCaseEnabled = false;
  bool get isUrgentCaseEnabled => _isUrgentCaseEnabled;

  // ── Load จาก storage (เรียกตอน initState) ─────────────
  Future<void> load() async {
    try {
      final val = await _storage.read(key: 'urgentCaseEnabled');
      _isUrgentCaseEnabled = val == 'true';
    } catch (e) {
      // อ่านไม่ได้ → ใช้ค่า default false ไปก่อน ไม่ให้แอป crash
      _isUrgentCaseEnabled = false;
      debugPrint('LawyerProfileStore.load() error: $e');
    }
    notifyListeners();
  }

  // ── อัปเดต + บันทึก ────────────────────────────────────
  Future<void> setUrgentCase(bool value) async {
    if (_isUrgentCaseEnabled == value) return;
    _isUrgentCaseEnabled = value;
    notifyListeners();
    await _storage.write(
      key: 'urgentCaseEnabled',
      value: value.toString(),
    );
  }
}
