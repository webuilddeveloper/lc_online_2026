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

  bool _isAvailable = true;
  bool get isAvailable => _isAvailable;

  CurrentPlan _currentPlan = CurrentPlan.free;
  BillingCycle _billingCycle = BillingCycle.monthly;

  CurrentPlan get currentPlan => _currentPlan;
  BillingCycle get billingCycle => _billingCycle;
  bool get isPro => _currentPlan == CurrentPlan.pro;

  // ── Profile fields ────────────────────────────────────────────────
  String _title = '';
  String _experience = '';
  String _casesWon = '';
  String _clientReviews = '';
  String _bio = '';
  double _rating = 0.0;
  List<String> _skills = [];
  String _province = 'กรุงเทพมหานคร';

  String get title => _title;
  String get experience => _experience;
  String get casesWon => _casesWon;
  String get clientReviews => _clientReviews;
  String get bio => _bio;
  double get rating => _rating;
  List<String> get skills => List.unmodifiable(_skills);
  String get province => _province;

  // ── Social fields ─────────────────────────────────────────────────
  String _facebook = '';
  String _instagram = '';
  String _twitter = '';
  String _linkedin = '';

  String get facebook => _facebook;
  String get instagram => _instagram;
  String get twitter => _twitter;
  String get linkedin => _linkedin;

  // ── Load จาก storage ──────────────────────────────────────────────
  Future<void> load() async {
    try {
      final urgent   = await _storage.read(key: 'urgentCaseEnabled');
      final available = await _storage.read(key: 'isAvailable');
      final plan     = await _storage.read(key: 'currentPlan');
      final billing  = await _storage.read(key: 'billingCycle');

      // profile
      final title    = await _storage.read(key: 'lawyer_title');
      final exp      = await _storage.read(key: 'lawyer_experience');
      final cases    = await _storage.read(key: 'lawyer_casesWon');
      final reviews  = await _storage.read(key: 'lawyer_clientReviews');
      final bio      = await _storage.read(key: 'lawyer_bio');
      final rating   = await _storage.read(key: 'lawyer_rating');
      final skills   = await _storage.read(key: 'lawyer_skills');
      final province = await _storage.read(key: 'lawyer_province');

      // social
      final fb  = await _storage.read(key: 'lawyer_facebook');
      final ig  = await _storage.read(key: 'lawyer_instagram');
      final tw  = await _storage.read(key: 'lawyer_twitter');
      final li  = await _storage.read(key: 'lawyer_linkedin');

      _isUrgentCaseEnabled = urgent == 'true';
      _isAvailable = available != 'false'; // default true
      _currentPlan = plan == 'pro' ? CurrentPlan.pro : CurrentPlan.free;
      _billingCycle =
          billing == 'yearly' ? BillingCycle.yearly : BillingCycle.monthly;

      _title          = title ?? '';
      _experience     = exp ?? '';
      _casesWon       = cases ?? '';
      _clientReviews  = reviews ?? '';
      _bio            = bio ?? '';
      _rating         = double.tryParse(rating ?? '') ?? 0.0;
      _skills         = skills != null && skills.isNotEmpty
          ? skills.split('|').where((s) => s.isNotEmpty).toList()
          : [];
      _province       = province ?? 'กรุงเทพมหานคร';

      _facebook  = fb ?? '';
      _instagram = ig ?? '';
      _twitter   = tw ?? '';
      _linkedin  = li ?? '';
    } catch (e) {
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

  // ── Available ──────────────────────────────────────────────────────
  Future<void> setAvailable(bool value) async {
    if (_isAvailable == value) return;
    _isAvailable = value;
    notifyListeners();
    await _storage.write(key: 'isAvailable', value: value.toString());
  }

  // ── Update profile ────────────────────────────────────────────────
  Future<void> updateProfile({
    String? title,
    String? experience,
    String? casesWon,
    String? clientReviews,
    String? bio,
    double? rating,
    List<String>? skills,
    String? province,
    bool? isAvailable,
    bool? isUrgentCaseEnabled,
    // social
    String? facebook,
    String? instagram,
    String? twitter,
    String? linkedin,
  }) async {
    if (title != null) _title = title;
    if (experience != null) _experience = experience;
    if (casesWon != null) _casesWon = casesWon;
    if (clientReviews != null) _clientReviews = clientReviews;
    if (bio != null) _bio = bio;
    if (rating != null) _rating = rating;
    if (skills != null) _skills = skills;
    if (province != null) _province = province;
    if (isAvailable != null) _isAvailable = isAvailable;
    if (isUrgentCaseEnabled != null) _isUrgentCaseEnabled = isUrgentCaseEnabled;
    if (facebook != null) _facebook = facebook;
    if (instagram != null) _instagram = instagram;
    if (twitter != null) _twitter = twitter;
    if (linkedin != null) _linkedin = linkedin;

    notifyListeners();

    await Future.wait([
      if (title != null) _storage.write(key: 'lawyer_title', value: title),
      if (experience != null) _storage.write(key: 'lawyer_experience', value: experience),
      if (casesWon != null) _storage.write(key: 'lawyer_casesWon', value: casesWon),
      if (clientReviews != null) _storage.write(key: 'lawyer_clientReviews', value: clientReviews),
      if (bio != null) _storage.write(key: 'lawyer_bio', value: bio),
      if (rating != null) _storage.write(key: 'lawyer_rating', value: rating.toString()),
      if (skills != null) _storage.write(key: 'lawyer_skills', value: skills.join('|')),
      if (province != null) _storage.write(key: 'lawyer_province', value: province),
      if (isAvailable != null) _storage.write(key: 'isAvailable', value: isAvailable.toString()),
      if (isUrgentCaseEnabled != null) _storage.write(key: 'urgentCaseEnabled', value: isUrgentCaseEnabled.toString()),
      if (facebook != null) _storage.write(key: 'lawyer_facebook', value: facebook),
      if (instagram != null) _storage.write(key: 'lawyer_instagram', value: instagram),
      if (twitter != null) _storage.write(key: 'lawyer_twitter', value: twitter),
      if (linkedin != null) _storage.write(key: 'lawyer_linkedin', value: linkedin),
    ]);
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
    _isAvailable = true;
    _currentPlan = CurrentPlan.free;
    _billingCycle = BillingCycle.monthly;
    _title = '';
    _experience = '';
    _casesWon = '';
    _clientReviews = '';
    _bio = '';
    _rating = 0.0;
    _skills = [];
    _province = 'กรุงเทพมหานคร';
    _facebook = '';
    _instagram = '';
    _twitter = '';
    _linkedin = '';
    notifyListeners();
    await Future.wait([
      _storage.delete(key: 'urgentCaseEnabled'),
      _storage.delete(key: 'isAvailable'),
      _storage.delete(key: 'currentPlan'),
      _storage.delete(key: 'billingCycle'),
      _storage.delete(key: 'lawyer_title'),
      _storage.delete(key: 'lawyer_experience'),
      _storage.delete(key: 'lawyer_casesWon'),
      _storage.delete(key: 'lawyer_clientReviews'),
      _storage.delete(key: 'lawyer_bio'),
      _storage.delete(key: 'lawyer_rating'),
      _storage.delete(key: 'lawyer_skills'),
      _storage.delete(key: 'lawyer_province'),
      _storage.delete(key: 'lawyer_facebook'),
      _storage.delete(key: 'lawyer_instagram'),
      _storage.delete(key: 'lawyer_twitter'),
      _storage.delete(key: 'lawyer_linkedin'),
    ]);
  }
}