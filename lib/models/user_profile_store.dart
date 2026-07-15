import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:LawyerOnline/models/lawyer/lawyer_profile_store.dart';
import 'package:LawyerOnline/models/user_model.dart';
import 'package:LawyerOnline/repositories/register_account_repository.dart';

// ══════════════════════════════════════════════════════════════════════
//  _SafeStorage
//  Wrapper ป้องกัน OperationError จาก flutter_secure_storage บน Web
//  (เกิดเมื่อ WebCrypto key เสีย หรือ serve บน http://)
//  บน Web ถ้า storage พัง จะ fallback ไปใช้ in-memory map แทน
//  ข้อมูลจะหายเมื่อปิด tab แต่แอปไม่ crash และ login ได้ปกติ
// ══════════════════════════════════════════════════════════════════════
class _SafeStorage {
  static const _delegate = FlutterSecureStorage();

  // in-memory fallback
  static final Map<String, String> _mem = {};
  static bool _useMem = false;

  Future<String?> read({required String key}) async {
    if (_useMem) return _mem[key];
    try {
      final val = await _delegate.read(key: key);
      if (val != null) _mem[key] = val; // mirror
      return val;
    } catch (e) {
      debugPrint('_SafeStorage.read error → fallback memory: $e');
      _useMem = true;
      return _mem[key];
    }
  }

  Future<void> write({required String key, required String value}) async {
    _mem[key] = value; // mirror ก่อนเสมอ
    if (_useMem) return;
    try {
      await _delegate.write(key: key, value: value);
    } catch (e) {
      debugPrint('_SafeStorage.write error → fallback memory: $e');
      _useMem = true;
    }
  }

  Future<void> delete({required String key}) async {
    _mem.remove(key);
    if (_useMem) return;
    try {
      await _delegate.delete(key: key);
    } catch (e) {
      debugPrint('_SafeStorage.delete error (ignored): $e');
      _useMem = true;
    }
  }
}

// ══════════════════════════════════════════════════════════════════════
//  UserProfileStore
// ══════════════════════════════════════════════════════════════════════
class UserProfileStore extends ChangeNotifier {
  UserProfileStore._();
  static final instance = UserProfileStore._();

  final _storage = _SafeStorage();

  // ── state ────────────────────────────────────────────────────────────
  UserModel? user;
  String typeLogin =
      'null'; // 'local' | 'google' | 'facebook' | 'line' | 'null'
  String authToken = '';
  bool _loaded = false;
  bool _lawyerApplyPending = false;

  // ── convenience getters ───────────────────────────────────────────────
  String get name => user?.fullName ?? '';
  String get imageUrl => user?.imageUrl ?? '';
  String get userType => user?.userType ?? '';
  String get code => user?.code ?? '';
  String get phone => user?.phone ?? '';
  String get email => user?.email ?? '';
  String get firstName => user?.firstName ?? '';
  String get lastName => user?.lastName ?? '';
  String get prefixName => user?.prefixName ?? '';
  String get token => authToken;
  bool get isLoggedIn => typeLogin != 'null';
  double get lastLat => user?.lastLat ?? 0.0;
  double get lastLong => user?.lastLong ?? 0.0;
  bool get isLawyerApplyPending =>
      _lawyerApplyPending || user?.lawyerApplyStatus == 'pending';

  // ── load จาก secure storage ──────────────────────────────────────────
  Future<void> load() async {
    if (_loaded) return;
    await _reload();
    _loaded = true;
  }

  Future<void> forceReload() async {
    _loaded = false;
    await load();
  }

  static double _parseStoredDouble(String? value) {
    if (value == null || value.isEmpty) return 0.0;
    return double.tryParse(value) ?? 0.0;
  }

  Future<void> _reload() async {
    try {
      typeLogin = await _storage.read(key: 'typeLogin') ?? 'null';
      authToken = await _storage.read(key: 'authToken') ?? '';
      _lawyerApplyPending =
          (await _storage.read(key: 'lawyerApplyPending')) == 'true';

      final code = await _storage.read(key: 'code') ?? '';
      if (code.isEmpty) {
        user = null;
        notifyListeners();
        return;
      }

      final fullName = await _storage.read(key: 'name') ?? '';
      String firstName = fullName;
      String lastName = '';
      if (fullName.contains(' ')) {
        final parts = fullName.split(' ');
        firstName = parts[0];
        lastName = parts.sublist(1).join(' ');
      }

      user = UserModel(
        code: code,
        userType: await _storage.read(key: 'userType') ?? '',
        firstName: firstName,
        lastName: lastName,
        email: await _storage.read(key: 'email') ?? '',
        phone: await _storage.read(key: 'phone') ?? '',
        imageUrl: await _storage.read(key: 'imageUrlSocial') ?? '',
        category: await _storage.read(key: 'category') ?? '',
        isActive: true,
        status: '',
        prefixName: await _storage.read(key: 'prefixName') ?? '',
        facebookID: '',
        googleID: '',
        lineID: '',
        line: '',
        sex: await _storage.read(key: 'sex') ?? '',
        address: await _storage.read(key: 'address') ?? '',
        idcard: await _storage.read(key: 'idcard') ?? '',
        lastLat: _parseStoredDouble(await _storage.read(key: 'lastLat')),
        lastLong: _parseStoredDouble(await _storage.read(key: 'lastLong')),
      );
    } catch (e) {
      debugPrint('UserProfileStore._reload() error: $e');
      user = null;
      typeLogin = 'null';
      authToken = '';
    }
    notifyListeners();
  }

  // ── setUser หลัง login / social login ────────────────────────────────
  Future<void> setUser(
    UserModel model, {
    required String typeLogin,
    String authToken = '',
  }) async {
    user = model;
    this.typeLogin = typeLogin;
    this.authToken = authToken;
    _lawyerApplyPending = model.lawyerApplyStatus == 'pending';
    _loaded = true;
    notifyListeners(); // แสดง UI ก่อน แล้วค่อย persist
    await _persistToStorage(
      model,
      typeLogin: typeLogin,
      authToken: authToken,
    );
    await _storage.write(
      key: 'lawyerApplyPending',
      value: _lawyerApplyPending ? 'true' : 'false',
    );
  }

  // ── updateFromProfile หลัง save profile form สำเร็จ ──────────────────
  Future<void> updateFromProfile({
    required String firstName,
    required String lastName,
    required String phone,
    required String email,
    String? imageUrl,
    String? userType,
    String? prefixName,
  }) async {
    if (user == null) return;

    user = user!.copyWith(
      firstName: firstName,
      lastName: lastName,
      phone: phone,
      email: email,
      imageUrl: imageUrl ?? user!.imageUrl,
      userType: userType ?? user!.userType,
      prefixName: prefixName ?? user!.prefixName,
    );

    final fullName = [firstName, lastName].where((s) => s.isNotEmpty).join(' ');
    await Future.wait([
      _storage.write(key: 'name', value: fullName),
      _storage.write(key: 'phone', value: phone),
      _storage.write(key: 'email', value: email),
      _storage.write(key: 'userType', value: userType ?? user!.userType),
      if (prefixName != null)
        _storage.write(key: 'prefixName', value: prefixName),
      if (imageUrl != null)
        _storage.write(key: 'imageUrlSocial', value: imageUrl),
    ]);

    notifyListeners();
  }

  Future<void> applyUserModel(UserModel model, {bool persist = true}) async {
    user = model;
    _lawyerApplyPending = model.lawyerApplyStatus == 'pending';
    notifyListeners();
    if (model.userType == 'lawyer') {
      await LawyerProfileStore.instance.syncFromUserModel(model);
    }
    if (persist) {
      await _persistToStorage(
        model,
        typeLogin: typeLogin,
        authToken: authToken,
      );
      await _storage.write(
        key: 'lawyerApplyPending',
        value: _lawyerApplyPending ? 'true' : 'false',
      );
    }
  }

  /// Reload current user from API (keeps session — no logout required).
  Future<bool> refreshFromApi() async {
    if (code.isEmpty) return false;

    try {
      const repo = ApiRegisterAccountRepository();
      final accounts = await repo.readAccounts(code: code);
      if (accounts.isEmpty) return false;

      final fresh = accounts.first;
      await applyUserModel(fresh);
      return true;
    } catch (e) {
      debugPrint('UserProfileStore.refreshFromApi() error: $e');
      return false;
    }
  }

  Future<void> setLawyerApplyPending(bool pending) async {
    _lawyerApplyPending = pending;
    await _storage.write(
      key: 'lawyerApplyPending',
      value: pending ? 'true' : 'false',
    );
    if (user != null && pending) {
      user = user!.copyWith(lawyerApplyStatus: 'pending');
    }
    notifyListeners();
  }

  // ── update location (จาก LocationService) ─────────────────────────────
  Future<void> updateLocation({
    required double lat,
    required double lng,
  }) async {
    if (user == null) return;
    user = user!.copyWith(lastLat: lat, lastLong: lng);
    await Future.wait([
      _storage.write(key: 'lastLat', value: lat.toString()),
      _storage.write(key: 'lastLong', value: lng.toString()),
    ]);
    notifyListeners();
  }

  // ── reset เมื่อ logout ────────────────────────────────────────────────
  void reset() {
    user = null;
    typeLogin = 'null';
    authToken = '';
    _loaded = false;
    notifyListeners();
  }

  Future<void> resetAndClear() async {
    user = null;
    typeLogin = 'null';
    authToken = '';
    _loaded = false;
    notifyListeners();

    await Future.wait([
      _storage.delete(key: 'typeLogin'),
      _storage.delete(key: 'authToken'),
      _storage.delete(key: 'code'),
      _storage.delete(key: 'userType'),
      _storage.delete(key: 'name'),
      _storage.delete(key: 'email'),
      _storage.delete(key: 'phone'),
      _storage.delete(key: 'imageUrlSocial'),
      _storage.delete(key: 'category'),
      _storage.delete(key: 'prefixName'),
      _storage.delete(key: 'sex'),
      _storage.delete(key: 'address'),
      _storage.delete(key: 'idcard'),
      _storage.delete(key: 'isOnline'),
      _storage.delete(key: 'lastLat'),
      _storage.delete(key: 'lastLong'),
      _storage.delete(key: 'lawyerApplyPending'),
    ]);
  }

  // ── persist ───────────────────────────────────────────────────────────
  Future<void> _persistToStorage(
    UserModel m, {
    required String typeLogin,
    required String authToken,
  }) async {
    final fullName =
        [m.firstName, m.lastName].where((s) => s.isNotEmpty).join(' ');
    await Future.wait([
      _storage.write(key: 'typeLogin', value: typeLogin),
      _storage.write(key: 'authToken', value: authToken),
      _storage.write(key: 'code', value: m.code),
      _storage.write(key: 'userType', value: m.userType),
      _storage.write(key: 'name', value: fullName),
      _storage.write(key: 'email', value: m.email),
      _storage.write(key: 'phone', value: m.phone),
      _storage.write(key: 'imageUrlSocial', value: m.imageUrl),
      _storage.write(key: 'category', value: m.category),
      _storage.write(key: 'prefixName', value: m.prefixName),
      _storage.write(key: 'sex', value: m.sex),
      _storage.write(key: 'address', value: m.address),
      _storage.write(key: 'idcard', value: m.idcard),
      _storage.write(key: 'lastLat', value: m.lastLat.toString()),
      _storage.write(key: 'lastLong', value: m.lastLong.toString()),
      _storage.write(key: 'isOnline', value: m.isOnline.toString()),
    ]);
  }
}
