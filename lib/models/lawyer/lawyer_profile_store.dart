import 'package:LawyerOnline/models/user_model.dart';
import 'package:LawyerOnline/models/user_profile_store.dart';
import 'package:LawyerOnline/services/subscription_service.dart';
import 'package:LawyerOnline/services/urgent_case_service.dart';
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
  DateTime? _proTrialEndDate;
  String _urgentCaseScope = 'expertise';

  CurrentPlan get currentPlan => _currentPlan;
  BillingCycle get billingCycle => _billingCycle;
  DateTime? get proTrialEndDate => _proTrialEndDate;
  String get urgentCaseScope => _urgentCaseScope;
  bool get acceptsAllUrgentCases => isPro && _urgentCaseScope == 'all';
  bool get isPro => _currentPlan == CurrentPlan.pro;

  /// วันทดลองใช้คงเหลือ (null = ไม่ได้อยู่ในช่วงทดลอง)
  int? get trialDaysRemaining {
    if (_currentPlan != CurrentPlan.pro || _proTrialEndDate == null) return null;
    final now = DateTime.now();
    if (now.isAfter(_proTrialEndDate!)) return 0;
    final diff = _proTrialEndDate!.difference(now).inHours;
    return (diff / 24).ceil().clamp(0, 7);
  }

  bool get isOnTrial =>
      isPro && trialDaysRemaining != null && trialDaysRemaining! > 0;

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
      final urgent = await _storage.read(key: 'urgentCaseEnabled');
      final available = await _storage.read(key: 'isAvailable');
      final plan = await _storage.read(key: 'currentPlan');
      final billing = await _storage.read(key: 'billingCycle');
      final trialEnd = await _storage.read(key: 'proTrialEndDate');
      final scope = await _storage.read(key: 'urgentCaseScope');

      // profile
      final title = await _storage.read(key: 'lawyer_title');
      final exp = await _storage.read(key: 'lawyer_experience');
      final cases = await _storage.read(key: 'lawyer_casesWon');
      final reviews = await _storage.read(key: 'lawyer_clientReviews');
      final bio = await _storage.read(key: 'lawyer_bio');
      final rating = await _storage.read(key: 'lawyer_rating');
      final skills = await _storage.read(key: 'lawyer_skills');
      final province = await _storage.read(key: 'lawyer_province');

      // social
      final fb = await _storage.read(key: 'lawyer_facebook');
      final ig = await _storage.read(key: 'lawyer_instagram');
      final tw = await _storage.read(key: 'lawyer_twitter');
      final li = await _storage.read(key: 'lawyer_linkedin');

      _isUrgentCaseEnabled = urgent == 'true';
      _isAvailable = available != 'false'; // default true
      _currentPlan = plan == 'pro' ? CurrentPlan.pro : CurrentPlan.free;
      _billingCycle =
          billing == 'yearly' ? BillingCycle.yearly : BillingCycle.monthly;
      _proTrialEndDate = trialEnd != null && trialEnd.isNotEmpty
          ? DateTime.tryParse(trialEnd)
          : null;
      _urgentCaseScope = scope == 'all' ? 'all' : 'expertise';

      _title = title ?? '';
      _experience = exp ?? '';
      _casesWon = cases ?? '';
      _clientReviews = reviews ?? '';
      _bio = bio ?? '';
      _rating = double.tryParse(rating ?? '') ?? 0.0;
      _skills = skills != null && skills.isNotEmpty
          ? skills.split('|').where((s) => s.isNotEmpty).toList()
          : [];
      _province = province ?? 'กรุงเทพมหานคร';

      _facebook = fb ?? '';
      _instagram = ig ?? '';
      _twitter = tw ?? '';
      _linkedin = li ?? '';
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

    final code = UserProfileStore.instance.code;
    if (code.isEmpty) return;

    final result = await UrgentCaseService.updateSettings(
      code: code,
      isAllowCase: value,
      urgentCaseScope: _urgentCaseScope,
    );
    if (result != null) {
      _applyUrgentSettingsFromApi(result);
      notifyListeners();
      await _syncUserUrgentFields();
    }
  }

  Future<void> setUrgentCaseScope(String scope) async {
    if (!isPro) return;
    final normalized = scope == 'all' ? 'all' : 'expertise';
    if (_urgentCaseScope == normalized) return;

    _urgentCaseScope = normalized;
    notifyListeners();
    await _storage.write(key: 'urgentCaseScope', value: normalized);

    final code = UserProfileStore.instance.code;
    if (code.isEmpty) return;

    final result = await UrgentCaseService.updateSettings(
      code: code,
      isAllowCase: _isUrgentCaseEnabled,
      urgentCaseScope: normalized,
    );
    if (result != null) {
      _applyUrgentSettingsFromApi(result);
      notifyListeners();
      await _syncUserUrgentFields();
    }
  }

  void _applyUrgentSettingsFromApi(Map<String, dynamic> data) {
    _isUrgentCaseEnabled =
        data['isAllowCase'] == true || data['isAllowCase']?.toString() == 'true';
    final scope = data['urgentCaseScope']?.toString() ?? 'expertise';
    _urgentCaseScope = scope == 'all' ? 'all' : 'expertise';
  }

  Future<void> _syncUserUrgentFields() async {
    final user = UserProfileStore.instance.user;
    if (user == null) return;
    await UserProfileStore.instance.applyUserModel(
      user.copyWith(
        isAllowCase: _isUrgentCaseEnabled,
        urgentCaseScope: _urgentCaseScope,
      ),
      persist: true,
    );
  }

  // ── Available ──────────────────────────────────────────────────────
  Future<void> setAvailable(bool value) async {
    if (_isAvailable == value) return;
    _isAvailable = value;
    notifyListeners();
    await _storage.write(key: 'isAvailable', value: value.toString());
  }

  // ── Sync จาก API ────────────────────────────────────────────────────
  Future<void> syncFromUserModel(UserModel model) async {
    _title = model.title.isNotEmpty ? model.title : 'ทนายความ';
    _experience = model.experienceYears > 0
        ? model.experienceYears.toStringAsFixed(
            model.experienceYears % 1 == 0 ? 0 : 1,
          )
        : '';
    _casesWon = model.lv3;
    _bio = model.description;
    _skills = List<String>.from(model.expertiseList);
    _province = model.province.isNotEmpty
        ? model.province
        : 'กรุงเทพมหานคร';
    _isAvailable = model.isAvailable != 'F';
    _isUrgentCaseEnabled = model.isAllowCase;
    _urgentCaseScope = model.urgentCaseScope == 'all' ? 'all' : 'expertise';
    _facebook = model.facebookID;
    _instagram = model.lv0;
    _twitter = model.lv1;
    _linkedin = model.lv2;
    _applySubscriptionFromUser(model);

    notifyListeners();

    await Future.wait([
      _storage.write(key: 'lawyer_title', value: _title),
      _storage.write(key: 'lawyer_experience', value: _experience),
      _storage.write(key: 'lawyer_casesWon', value: _casesWon),
      _storage.write(key: 'lawyer_bio', value: _bio),
      _storage.write(key: 'lawyer_skills', value: _skills.join('|')),
      _storage.write(key: 'lawyer_province', value: _province),
      _storage.write(key: 'isAvailable', value: _isAvailable.toString()),
      _storage.write(
          key: 'urgentCaseEnabled', value: _isUrgentCaseEnabled.toString()),
      _storage.write(key: 'urgentCaseScope', value: _urgentCaseScope),
      _storage.write(key: 'lawyer_instagram', value: _instagram),
      _storage.write(key: 'lawyer_twitter', value: _twitter),
      _storage.write(key: 'lawyer_linkedin', value: _linkedin),
      _persistSubscription(),
    ]);
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
      if (experience != null)
        _storage.write(key: 'lawyer_experience', value: experience),
      if (casesWon != null)
        _storage.write(key: 'lawyer_casesWon', value: casesWon),
      if (clientReviews != null)
        _storage.write(key: 'lawyer_clientReviews', value: clientReviews),
      if (bio != null) _storage.write(key: 'lawyer_bio', value: bio),
      if (rating != null)
        _storage.write(key: 'lawyer_rating', value: rating.toString()),
      if (skills != null)
        _storage.write(key: 'lawyer_skills', value: skills.join('|')),
      if (province != null)
        _storage.write(key: 'lawyer_province', value: province),
      if (isAvailable != null)
        _storage.write(key: 'isAvailable', value: isAvailable.toString()),
      if (isUrgentCaseEnabled != null)
        _storage.write(
            key: 'urgentCaseEnabled', value: isUrgentCaseEnabled.toString()),
      if (facebook != null)
        _storage.write(key: 'lawyer_facebook', value: facebook),
      if (instagram != null)
        _storage.write(key: 'lawyer_instagram', value: instagram),
      if (twitter != null)
        _storage.write(key: 'lawyer_twitter', value: twitter),
      if (linkedin != null)
        _storage.write(key: 'lawyer_linkedin', value: linkedin),
    ]);
  }

  void _applySubscriptionFromUser(UserModel model) {
    _currentPlan = model.isPro ? CurrentPlan.pro : CurrentPlan.free;
    _billingCycle = model.proBillingCycle == 'yearly'
        ? BillingCycle.yearly
        : BillingCycle.monthly;
    _proTrialEndDate = model.proTrialEndDate;
  }

  void _applySubscriptionFromApi(Map<String, dynamic> data) {
    final isProFlag =
        data['isPro'] == true || data['isPro']?.toString() == 'true';
    _currentPlan = isProFlag ? CurrentPlan.pro : CurrentPlan.free;
    _billingCycle = data['proBillingCycle']?.toString() == 'yearly'
        ? BillingCycle.yearly
        : BillingCycle.monthly;
    final rawEnd = data['proTrialEndDate'];
    _proTrialEndDate = rawEnd == null
        ? null
        : DateTime.tryParse(rawEnd.toString());
  }

  Future<void> _persistSubscription() => Future.wait([
        _storage.write(
          key: 'currentPlan',
          value: _currentPlan == CurrentPlan.pro ? 'pro' : 'free',
        ),
        _storage.write(
          key: 'billingCycle',
          value: _billingCycle.isYearly ? 'yearly' : 'monthly',
        ),
        if (_proTrialEndDate != null)
          _storage.write(
            key: 'proTrialEndDate',
            value: _proTrialEndDate!.toIso8601String(),
          )
        else
          _storage.delete(key: 'proTrialEndDate'),
      ]);

  // ── Subscription ───────────────────────────────────────────────────
  Future<bool> upgradeToPro(BillingCycle cycle) async {
    final code = UserProfileStore.instance.code;
    if (code.isEmpty) return false;

    final result = await SubscriptionService.upgradePro(
      code: code,
      billingCycle: cycle.isYearly ? 'yearly' : 'monthly',
    );
    if (result == null) return false;

    _applySubscriptionFromApi(result);
    notifyListeners();
    await _persistSubscription();

    final user = UserProfileStore.instance.user;
    if (user != null) {
      await UserProfileStore.instance.applyUserModel(
        user.copyWith(
          isPro: _currentPlan == CurrentPlan.pro,
          proTrialEndDate: _proTrialEndDate,
          proBillingCycle: cycle.isYearly ? 'yearly' : 'monthly',
        ),
        persist: true,
      );
    }
    return true;
  }

  Future<bool> cancelPro() async {
    final code = UserProfileStore.instance.code;
    if (code.isEmpty) return false;

    final result = await SubscriptionService.cancelPro(code: code);
    if (result == null) return false;

    _applySubscriptionFromApi(result);
    notifyListeners();
    await _persistSubscription();

    final user = UserProfileStore.instance.user;
    if (user != null) {
      await UserProfileStore.instance.applyUserModel(
        user.copyWith(
          isPro: false,
          proTrialEndDate: null,
          proBillingCycle: '',
        ),
        persist: true,
      );
    }
    return true;
  }

  Future<void> downgradeToFree() async {
    await cancelPro();
  }

  // ── reset เมื่อ logout ────────────────────────────────────────────────
  Future<void> reset() async {
    _isUrgentCaseEnabled = false;
    _isAvailable = true;
    _currentPlan = CurrentPlan.free;
    _billingCycle = BillingCycle.monthly;
    _proTrialEndDate = null;
    _urgentCaseScope = 'expertise';
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
      _storage.delete(key: 'proTrialEndDate'),
      _storage.delete(key: 'urgentCaseScope'),
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
