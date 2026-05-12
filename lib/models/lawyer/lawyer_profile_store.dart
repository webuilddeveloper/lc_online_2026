// ══════════════════════════════════════════════════════════════════════
//  lawyer_profile_store.dart
//  Single source of truth สำหรับ state ของ lawyer ข้ามทุกหน้า
//
//  เพิ่ม: subscription plan state + billing cycle
//
//  วิธีใช้:
//  await LawyerProfileStore.instance.load();
//  LawyerProfileStore.instance.currentPlan          // CurrentPlan.free / .pro
//  LawyerProfileStore.instance.billingCycle         // BillingCycle.monthly / .yearly
//  await LawyerProfileStore.instance.upgradeToPro(BillingCycle.yearly)
//  await LawyerProfileStore.instance.downgradToFree()
// ══════════════════════════════════════════════════════════════════════

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:LawyerOnline/subscribe/subscribe_theme.dart';

class LawyerProfileStore extends ChangeNotifier {
  LawyerProfileStore._();
  static final LawyerProfileStore instance = LawyerProfileStore._();

  static const _storage = FlutterSecureStorage();

  // ── State ──────────────────────────────────────────────────────────
  bool _isUrgentCaseEnabled = false;
  bool get isUrgentCaseEnabled => _isUrgentCaseEnabled;

  CurrentPlan  _currentPlan  = CurrentPlan.free;
  BillingCycle _billingCycle = BillingCycle.monthly;

  CurrentPlan  get currentPlan  => _currentPlan;
  BillingCycle get billingCycle => _billingCycle;
  bool         get isPro        => _currentPlan == CurrentPlan.pro;

  // ── Load จาก storage ──────────────────────────────────────────────
  Future<void> load() async {
    try {
      final urgent  = await _storage.read(key: 'urgentCaseEnabled');
      final plan    = await _storage.read(key: 'currentPlan');
      final billing = await _storage.read(key: 'billingCycle');

      _isUrgentCaseEnabled = urgent == 'true';
      _currentPlan  = plan    == 'pro'    ? CurrentPlan.pro    : CurrentPlan.free;
      _billingCycle = billing == 'yearly' ? BillingCycle.yearly : BillingCycle.monthly;
    } catch (e) {
      _isUrgentCaseEnabled = false;
      _currentPlan  = CurrentPlan.free;
      _billingCycle = BillingCycle.monthly;
      debugPrint('LawyerProfileStore.load() error: $e');
    }
    notifyListeners();
  }

  // ── Urgent case ────────────────────────────────────────────────────
  Future<void> setUrgentCase(bool value) async {
    if (_isUrgentCaseEnabled == value) return;
    _isUrgentCaseEnabled = value;
    notifyListeners();
    await _storage.write(key: 'urgentCaseEnabled', value: value.toString());
  }

  // ── Subscription ───────────────────────────────────────────────────
  /// เรียกหลัง payment สำเร็จ
  Future<void> upgradeToPro(BillingCycle cycle) async {
    _currentPlan  = CurrentPlan.pro;
    _billingCycle = cycle;
    notifyListeners();
    await Future.wait([
      _storage.write(key: 'currentPlan',  value: 'pro'),
      _storage.write(key: 'billingCycle', value: cycle.isYearly ? 'yearly' : 'monthly'),
    ]);
  }

  /// เรียกหลัง downgrade ยืนยัน
  Future<void> downgradeToFree() async {
    _currentPlan  = CurrentPlan.free;
    _billingCycle = BillingCycle.monthly;
    notifyListeners();
    await Future.wait([
      _storage.write(key: 'currentPlan',  value: 'free'),
      _storage.write(key: 'billingCycle', value: 'monthly'),
    ]);
  }
}