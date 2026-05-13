import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:LawyerOnline/subscribe/subscribe_theme.dart';

// ── Safe storage wrapper (เหมือน user_profile_store) ──────────────────
class _SafeStorage {
  static const _delegate = FlutterSecureStorage();
  static final Map<String, String> _mem = {};
  static bool _useMem = false;

  Future<String?> read({required String key}) async {
    if (_useMem) return _mem[key];
    try {
      final val = await _delegate.read(key: key);
      if (val != null) _mem[key] = val;
      return val;
    } catch (e) {
      debugPrint('LawyerStore._SafeStorage.read error → fallback: $e');
      _useMem = true;
      return _mem[key];
    }
  }

  Future<void> write({required String key, required String value}) async {
    _mem[key] = value;
    if (_useMem) return;
    try {
      await _delegate.write(key: key, value: value);
    } catch (e) {
      debugPrint('LawyerStore._SafeStorage.write error → fallback: $e');
      _useMem = true;
    }
  }

  Future<void> delete({required String key}) async {
    _mem.remove(key);
    if (_useMem) return;
    try {
      await _delegate.delete(key: key);
    } catch (e) {
      debugPrint('LawyerStore._SafeStorage.delete error (ignored): $e');
      _useMem = true;
    }
  }
}

class LawyerProfileStore extends ChangeNotifier {
  LawyerProfileStore._();
  static final LawyerProfileStore instance = LawyerProfileStore._();

  final _storage = _SafeStorage();

  // ── State ──────────────────────────────────────────────────────────
  bool _isUrgentCaseEnabled = false;
  bool get isUrgentCaseEnabled => _isUrgentCaseEnabled;

  CurrentPlan _currentPlan = CurrentPlan.free;
  BillingCycle _billingCycle = BillingCycle.monthly;

  CurrentPlan get currentPlan => _currentPlan;
  BillingCycle get billingCycle => _billingCycle;
  bool get isPro => _currentPlan == CurrentPlan.pro;

  // ── Load จาก storage ──────────────────────────────────────────────
  Future<void> load() async {
    try {
      final urgent = await _storage.read(key: 'urgentCaseEnabled');
      final plan = await _storage.read(key: 'currentPlan');
      final billing = await _storage.read(key: 'billingCycle');

      _isUrgentCaseEnabled = urgent == 'true';
      _currentPlan = plan == 'pro' ? CurrentPlan.pro : CurrentPlan.free;
      _billingCycle =
          billing == 'yearly' ? BillingCycle.yearly : BillingCycle.monthly;
    } catch (e) {
      _isUrgentCaseEnabled = false;
      _currentPlan = CurrentPlan.free;
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
  Future<void> upgradeToPro(BillingCycle cycle) async {
    _currentPlan = CurrentPlan.pro;
    _billingCycle = cycle;
    notifyListeners();
    await Future.wait([
      _storage.write(key: 'currentPlan', value: 'pro'),
      _storage.write(
          key: 'billingCycle', value: cycle.isYearly ? 'yearly' : 'monthly'),
    ]);
  }

  Future<void> downgradeToFree() async {
    _currentPlan = CurrentPlan.free;
    _billingCycle = BillingCycle.monthly;
    notifyListeners();
    await Future.wait([
      _storage.write(key: 'currentPlan', value: 'free'),
      _storage.write(key: 'billingCycle', value: 'monthly'),
    ]);
  }

  // ── reset เมื่อ logout ────────────────────────────────────────────────
  Future<void> reset() async {
    _isUrgentCaseEnabled = false;
    _currentPlan = CurrentPlan.free;
    _billingCycle = BillingCycle.monthly;
    notifyListeners();
    await Future.wait([
      _storage.delete(key: 'urgentCaseEnabled'),
      _storage.delete(key: 'currentPlan'),
      _storage.delete(key: 'billingCycle'),
    ]);
  }
}