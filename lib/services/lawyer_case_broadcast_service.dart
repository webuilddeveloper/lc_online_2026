import 'dart:async';
import 'dart:math';

import 'package:LawyerOnline/main.dart';
import 'package:LawyerOnline/models/lawyer/lawyer_jobs_store.dart';
import 'package:LawyerOnline/models/lawyer/lawyer_profile_store.dart';
import 'package:LawyerOnline/models/user_profile_store.dart';
import 'package:LawyerOnline/services/case_request_service.dart';
import 'package:LawyerOnline/services/notification_service.dart';
import 'package:LawyerOnline/shared/notification_settings_store.dart';
import 'package:LawyerOnline/widgets/lawyer/lawyer_case_popup.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// ฟัง ReceiveNewCaseRequest จาก CaseRequestHub แล้วโชว์ popup ให้ทนายกดรับ
class LawyerCaseBroadcastService {
  LawyerCaseBroadcastService._();
  static final instance = LawyerCaseBroadcastService._();

  static const _skippedPrefsKey = 'urgent_case_skipped_codes';

  /// เคสที่ broadcast นานกว่านี้ไม่โชว์จาก polling (กันเด้งซ้ำตอนเปิดแอป)
  static const _maxPollAge = Duration(minutes: 2);

  final CaseRequestService _caseReqService = CaseRequestService();

  bool _starting = false;
  bool _dialogOpen = false;
  String? _activeRequestCode;
  Map<String, dynamic>? _activeCaseData;
  Timer? _dismissTimer;
  Timer? _pollTimer;
  BuildContext? _dialogContext;
  final Set<String> _skippedRequestCodes = {};
  bool _skippedLoaded = false;
  bool _listening = false;

  Future<void> sync() async {
    await UserProfileStore.instance.load();
    await LawyerProfileStore.instance.load();
    await _ensureSkippedLoaded();

    final shouldListen = UserProfileStore.instance.isLoggedIn &&
        UserProfileStore.instance.userType == 'lawyer' &&
        LawyerProfileStore.instance.isUrgentCaseEnabled;

    if (!shouldListen) {
      if (!_listening) return;
      await stop();
      return;
    }

    await start();
  }

  void _bindHandlers() {
    _caseReqService.onNewCaseRequest = _onNewCaseRequest;
    _caseReqService.onCaseRequestTaken = _onCaseTakenByOther;
    _caseReqService.onRequestExpired = _onCaseExpired;
  }

  Future<void> start() async {
    if (_starting) return;

    // ฟังอยู่แล้วและยังเชื่อมต่อ — ไม่ต้อง start ซ้ำ
    if (_listening && _caseReqService.isConnected && _pollTimer != null) {
      _bindHandlers();
      return;
    }

    _starting = true;
    try {
      await _ensureSkippedLoaded();
      _bindHandlers();

      // polling สำรอง — ไม่ยิงทันทีตอนเปิดแอป (กันโชว์เคสเก่าค้าง)
      _startPolling(immediate: false);

      final wasConnected = _caseReqService.isConnected;
      if (!wasConnected) {
        await _caseReqService.connectAsLawyer();
      }

      _listening = true;

      if (!wasConnected) {
        debugPrint('LawyerCaseBroadcastService connected (urgent listen on)');
      }
    } catch (e) {
      debugPrint('LawyerCaseBroadcastService start error: $e');
      _listening = true;
      _startPolling(immediate: false);
    } finally {
      _starting = false;
    }
  }

  Future<void> stop() async {
    if (!_listening && !_caseReqService.isConnected && _pollTimer == null) {
      return;
    }

    _dismissTimer?.cancel();
    _dismissTimer = null;
    _stopPolling();
    _closeDialogIfOpen(rememberSkip: false);
    await _caseReqService.disconnect();
    _activeRequestCode = null;
    // คง _skippedRequestCodes ไว้ใน memory + prefs — อย่าเคลียร์ตอน stop
    _listening = false;
  }

  Future<void> _ensureSkippedLoaded() async {
    if (_skippedLoaded) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getStringList(_skippedPrefsKey) ?? const [];
      _skippedRequestCodes.addAll(saved);
    } catch (_) {}
    _skippedLoaded = true;
  }

  Future<void> _rememberSkipped(String code) async {
    if (code.isEmpty) return;
    _skippedRequestCodes.add(code);
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = _skippedRequestCodes.toList();
      // เก็บไม่เกิน 100 รายการล่าสุด
      if (list.length > 100) {
        await prefs.setStringList(
            _skippedPrefsKey, list.sublist(list.length - 100));
      } else {
        await prefs.setStringList(_skippedPrefsKey, list);
      }
    } catch (_) {}
  }

  void _startPolling({bool immediate = true}) {
    if (_pollTimer != null) return;
    // สำรองถ้า SignalR/FCM พลาด — เช็คเคสเปิดทุก 8 วินาที
    _pollTimer = Timer.periodic(const Duration(seconds: 8), (_) {
      unawaited(_pollOpenCaseRequests());
    });
    if (immediate) {
      unawaited(_pollOpenCaseRequests());
    }
  }

  void _stopPolling() {
    _pollTimer?.cancel();
    _pollTimer = null;
  }

  Future<void> _pollOpenCaseRequests() async {
    if (_dialogOpen) return;
    if (!LawyerProfileStore.instance.isUrgentCaseEnabled) return;
    await _ensureSkippedLoaded();

    try {
      final list = await _caseReqService.getOpenCaseRequests();
      for (final raw in list) {
        final code = raw['code']?.toString() ?? '';
        if (code.isEmpty) continue;
        if (_skippedRequestCodes.contains(code)) continue;
        if (_dialogOpen) return;

        final data = _normalizeCaseData(_unwrapPayload(raw));

        // โชว์เฉพาะเคสที่ broadcast ใหม่จริงๆ — ไม่ดึงเคสเก่าค้างตอนเปิดแอป
        if (!_isFreshForPoll(data)) {
          _skippedRequestCodes.add(code);
          continue;
        }

        final lawyerCode = UserProfileStore.instance.code;
        if (_isExcluded(data, lawyerCode)) {
          await _rememberSkipped(code);
          continue;
        }
        if (!_isEligibleRecipient(data, lawyerCode)) {
          await _rememberSkipped(code);
          continue;
        }
        if (!_matchesUrgentCaseScope(data)) {
          await _rememberSkipped(code);
          continue;
        }
        if (!await _isWithinRadius(data)) {
          continue;
        }

        debugPrint('LawyerCaseBroadcastService poll hit: $code');
        _activeCaseData = data;
        _showCasePopup(data);
        return;
      }
    } catch (e) {
      debugPrint('LawyerCaseBroadcastService poll error: $e');
    }
  }

  /// เคสที่ยังอยู่ในช่วง broadcast เท่านั้น (จาก broadcastAt / createDate)
  bool _isFreshForPoll(Map<String, dynamic> data) {
    final at = _parseRequestTime(data);
    if (at == null) return false;
    final age = DateTime.now().difference(at);
    return !age.isNegative && age <= _maxPollAge;
  }

  DateTime? _parseRequestTime(Map<String, dynamic> data) {
    final broadcastRaw = data['broadcastAt'];
    final fromBroadcast = _tryParseDateTime(broadcastRaw);
    if (fromBroadcast != null) return fromBroadcast;

    final createDate = data['createDate']?.toString() ?? '';
    final createTime = data['createTime']?.toString() ?? '';
    if (createDate.isNotEmpty) {
      final combined = createTime.isNotEmpty
          ? '$createDate ${createTime.length >= 5 ? createTime.substring(0, 5) : createTime}'
          : createDate;
      final parsed =
          _tryParseDateTime(combined) ?? _tryParseDateTime(createDate);
      if (parsed != null) return parsed;
    }

    return _tryParseDateTime(data['docDate']);
  }

  DateTime? _tryParseDateTime(dynamic raw) {
    if (raw == null) return null;
    if (raw is DateTime) return raw;
    final s = raw.toString().trim();
    if (s.isEmpty) return null;
    try {
      return DateTime.parse(s);
    } catch (_) {}
    // yyyy-MM-dd HH:mm
    try {
      final parts = s.split(RegExp(r'[\sT]'));
      if (parts.length >= 2) {
        final d = parts[0].split('-');
        final t = parts[1].split(':');
        if (d.length == 3 && t.length >= 2) {
          return DateTime(
            int.parse(d[0]),
            int.parse(d[1]),
            int.parse(d[2]),
            int.parse(t[0]),
            int.parse(t[1]),
          );
        }
      }
    } catch (_) {}
    return null;
  }

  /// เคสด่วนใหม่จาก FCM ตอนแอป foreground (ไม่แสดง in-app banner)
  static bool isForegroundCaseRequest(Map<String, dynamic> data) {
    final type = data['type']?.toString() ?? '';
    final page = data['page']?.toString() ?? '';
    return type == 'new_case_request' ||
        (page == 'case_request_detail' && type == 'new_case_request');
  }

  Future<bool> handleForegroundCaseRequest(Map<String, dynamic> data) async {
    if (!isForegroundCaseRequest(data)) return false;

    await UserProfileStore.instance.load();
    await LawyerProfileStore.instance.load();

    if (!UserProfileStore.instance.isLoggedIn) return false;
    if (UserProfileStore.instance.userType != 'lawyer') return false;
    if (!LawyerProfileStore.instance.isUrgentCaseEnabled) return false;

    final requestCode = data['code']?.toString().trim() ??
        data['refCode']?.toString().trim() ??
        '';
    if (requestCode.isEmpty) return false;

    if (_dialogOpen && _activeRequestCode == requestCode) return true;

    if (!_caseReqService.isConnected) {
      await sync();
    }

    await presentCaseFromRequestCode(requestCode);
    return true;
  }

  Future<void> _onNewCaseRequest(dynamic raw) async {
    debugPrint('LawyerCaseBroadcastService _onNewCaseRequest: $raw');
    await _ensureSkippedLoaded();
    var data = _normalizeCaseData(_unwrapPayload(_asMap(raw)));
    if (data.isEmpty) {
      debugPrint('LawyerCaseBroadcastService: empty payload, skip');
      return;
    }

    final requestCode = _readRequestCode(data);
    if (requestCode.isEmpty) return;
    if (_skippedRequestCodes.contains(requestCode)) {
      debugPrint('LawyerCaseBroadcastService: skipped $requestCode');
      return;
    }

    final lawyerCode = UserProfileStore.instance.code;
    if (_isExcluded(data, lawyerCode)) {
      debugPrint('LawyerCaseBroadcastService: excluded $lawyerCode');
      await _rememberSkipped(requestCode);
      return;
    }
    if (!_isEligibleRecipient(data, lawyerCode)) {
      debugPrint('LawyerCaseBroadcastService: not eligible $lawyerCode');
      await _rememberSkipped(requestCode);
      return;
    }
    if (!_matchesUrgentCaseScope(data)) {
      debugPrint('LawyerCaseBroadcastService: scope mismatch for $requestCode');
      await _rememberSkipped(requestCode);
      return;
    }
    if (!await _isWithinRadius(data)) {
      debugPrint('LawyerCaseBroadcastService: out of radius for $requestCode');
      return;
    }

    if (_dialogOpen && _activeRequestCode == requestCode) return;

    if (_needsDetailEnrichment(data)) {
      try {
        final detail = await _caseReqService.getRequestDetail(requestCode);
        if (detail.isNotEmpty) {
          data = _normalizeCaseData({...data, ...detail});
        }
      } catch (e) {
        debugPrint('Case detail enrich error: $e');
      }
    }

    _activeCaseData = data;
    _showCasePopup(data);
  }

  bool _needsDetailEnrichment(Map<String, dynamic> data) {
    return _pick(data, const [
          'details',
          'Details',
          'topicTitle',
          'TopicTitle',
          'subTopicTitle',
          'SubTopicTitle',
        ]).isEmpty ||
        _pick(data, const ['userName', 'UserName', 'clientName']).isEmpty;
  }

  bool _matchesUrgentCaseScope(Map<String, dynamic> data) {
    final caseSubTopic = _pick(data, const ['subTopic', 'SubTopic']);
    final caseSubTopicTitle =
        _pick(data, const ['subTopicTitle', 'SubTopicTitle']);
    if (caseSubTopic.isEmpty && caseSubTopicTitle.isEmpty) return true;

    final store = LawyerProfileStore.instance;
    if (store.acceptsAllUrgentCases) return true;

    final expertise = <String>{
      ...?UserProfileStore.instance.user?.expertiseList,
      ...store.skills,
    }.map((e) => e.trim()).where((e) => e.isNotEmpty).toSet();

    // เปิดรับเคสด่วนแล้วแต่ยังไม่ได้ตั้งความเชี่ยวชาญ → แสดงทุกเคส
    if (expertise.isEmpty) return true;

    return expertise.contains(caseSubTopic) ||
        expertise.contains(caseSubTopicTitle);
  }

  String _pick(Map<String, dynamic> data, List<String> keys,
      [String fallback = '']) {
    for (final key in keys) {
      final value = data[key];
      if (value != null && value.toString().trim().isNotEmpty) {
        return value.toString().trim();
      }
    }
    return fallback;
  }

  bool _isExcluded(Map<String, dynamic> data, String lawyerCode) {
    final excluded = data['excludedLawyerCodes'];
    if (excluded is! List) return false;
    return excluded.map((e) => e.toString()).contains(lawyerCode);
  }

  bool _isEligibleRecipient(Map<String, dynamic> data, String lawyerCode) {
    final eligible = data['eligibleLawyerCodes'];
    if (eligible is! List || eligible.isEmpty) return true;
    return eligible.map((e) => e.toString()).contains(lawyerCode);
  }

  Future<bool> _isWithinRadius(Map<String, dynamic> data) async {
    final caseLat = _asDouble(data['lat']);
    final caseLng = _asDouble(data['lng']);
    if (caseLat == null || caseLng == null) return true;

    // อย่างน้อย 20km และใช้ค่าจาก broadcast ถ้าระบุมากกว่า
    final radiusKm = max(_asDouble(data['radiusKm']) ?? 20, 20);

    double? lawyerLat;
    double? lawyerLng;

    // ใช้พิกัดปัจจุบันก่อน แล้วค่อย fallback ไปพิกัดในโปรไฟล์
    try {
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.whileInUse ||
          perm == LocationPermission.always) {
        final pos = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.medium,
        ).timeout(const Duration(seconds: 4));
        lawyerLat = pos.latitude;
        lawyerLng = pos.longitude;
      }
    } catch (_) {}

    lawyerLat ??= UserProfileStore.instance.lastLat;
    lawyerLng ??= UserProfileStore.instance.lastLong;

    if (lawyerLat == null ||
        lawyerLng == null ||
        (lawyerLat == 0 && lawyerLng == 0)) {
      // ไม่มีพิกัดทนาย — ไม่บล็อค popup
      return true;
    }

    final dist = _haversineKm(lawyerLat, lawyerLng, caseLat, caseLng);
    debugPrint(
      'LawyerCaseBroadcastService distance=${dist.toStringAsFixed(1)}km radius=$radiusKm',
    );
    return dist <= radiusKm;
  }

  void _onCaseExpired(dynamic raw) {
    final data = _normalizeCaseData(_asMap(raw));
    final requestCode = _readRequestCode(data);
    if (requestCode.isNotEmpty &&
        _activeRequestCode != null &&
        requestCode != _activeRequestCode) {
      return;
    }
    _closeDialogIfOpen(message: 'เคสนี้หมดเวลาแล้ว');
  }

  void _onCaseTakenByOther(dynamic raw) {
    final data = _asMap(raw);
    final requestCode =
        data['requestCode']?.toString() ?? data['code']?.toString() ?? '';
    final takenBy = data['takenBy']?.toString() ?? '';
    final myCode = UserProfileStore.instance.code;

    // เรารับเอง — ไม่ต้องปิด popup
    if (takenBy.isNotEmpty && takenBy == myCode) return;

    if (_activeRequestCode != null &&
        requestCode.isNotEmpty &&
        requestCode != _activeRequestCode) {
      return;
    }
    _closeDialogIfOpen(message: 'มีทนายรายอื่นรับเคสนี้แล้ว');
  }

  /// เปิด popup รับเคสจากการกดแจ้งเตือน (new_case_request)
  Future<void> presentCaseFromRequestCode(String requestCode) async {
    if (requestCode.isEmpty) return;
    await _ensureSkippedLoaded();

    var data = await _caseReqService.getRequestDetail(requestCode);
    if (data.isEmpty) return;

    data = _normalizeCaseData({
      ...data,
      'code': requestCode,
      'requestCode': requestCode,
    });

    // แจ้งเตือนเก่า/เคสหมดอายุ — ไม่โชว์
    final status = data['status'] ?? data['requestStatus'];
    final statusInt =
        status is int ? status : int.tryParse(status?.toString() ?? '') ?? -1;
    if (statusInt != 1) {
      debugPrint('LawyerCaseBroadcastService: skip present, status=$statusInt');
      return;
    }
    if (!_isFreshForPoll(data)) {
      debugPrint(
          'LawyerCaseBroadcastService: skip present, stale request $requestCode');
      await _rememberSkipped(requestCode);
      return;
    }
    if (!_isEligibleRecipient(data, UserProfileStore.instance.code)) {
      debugPrint(
          'LawyerCaseBroadcastService: skip present, not in eligible lawyers');
      await _rememberSkipped(requestCode);
      return;
    }

    _activeCaseData = data;
    _showCasePopup(data);
  }

  Future<void> claimCase(String requestCode) async {
    try {
      if (!_caseReqService.isConnected) {
        debugPrint(
            'LawyerCaseBroadcastService: hub disconnected, reconnecting before claim');
        await _caseReqService.ensureLawyerConnected();
        _bindHandlers();
        _listening = true;
        _startPolling(immediate: false);
      }
      await _caseReqService.claimCaseRequest(requestCode);
      await _rememberSkipped(requestCode);
      _upsertClaimedJob(requestCode);
      await _refreshLawyerJobsFromApi();
      debugPrint('✅ Case claimed successfully');
    } catch (e) {
      debugPrint('LawyerCaseBroadcastService claimCase error: $e');
      rethrow;
    }
  }

  void _upsertClaimedJob(String requestCode) {
    final data = _activeCaseData ?? {};
    final req = {
      ...data,
      'code': requestCode,
      'requestCode': requestCode,
      'pendingLawyer': UserProfileStore.instance.code,
      'userName': data['userName'] ?? 'ลูกความ',
      'status': 2,
    };
    LawyerJobsStore.instance.upsertCaseRequestJob(
      CaseRequestService.jobFromCaseRequest(req),
    );
  }

  Future<void> _refreshLawyerJobsFromApi() async {
    try {
      final list = await _caseReqService.getLawyerPendingRequests();
      if (list.isEmpty) return;
      LawyerJobsStore.instance.replaceCaseRequestJobs(
        list.map(CaseRequestService.jobFromCaseRequest).toList(),
      );
    } catch (_) {}
  }

  Map<String, dynamic> _normalizeCaseData(Map<String, dynamic> data) {
    return {
      ...data,
      'requestCode':
          _pick(data, const ['requestCode', 'RequestCode', 'code', 'Code']),
      'userName': _pick(
          data,
          const [
            'userName',
            'UserName',
            'clientName',
            'ClientName',
            'name',
            'Name',
          ],
          'ลูกความ'),
      'topicTitle': _pick(data, const [
        'topicTitle',
        'TopicTitle',
        'topic',
        'Topic',
        'caseTypeTitle',
        'caseType',
      ]),
      'subTopicTitle': _pick(data, const [
        'subTopicTitle',
        'SubTopicTitle',
        'subTopic',
        'SubTopic',
        'subCaseType',
      ]),
      'provinceTitle': _pick(data, const [
        'provinceTitle',
        'ProvinceTitle',
        'province',
        'Province',
        'provinceCode',
        'ProvinceCode',
      ]),
      'province': _pick(data, const [
        'provinceTitle',
        'ProvinceTitle',
        'province',
        'Province',
        'provinceCode',
        'ProvinceCode',
      ]),
      'details': _pick(data, const [
        'details',
        'Details',
        'detail',
        'Detail',
        'description',
        'Description',
      ]),
      'requirement': _pick(data, const [
        'requirement',
        'Requirement',
        'demand',
        'Demand',
      ]),
    };
  }

  void _showCasePopup(Map<String, dynamic> data) {
    final nav = navigatorKey.currentState;
    if (nav == null) return;

    final requestCode = _readRequestCode(data);
    _activeRequestCode = requestCode;
    _dialogOpen = true;

    final settings = NotificationSettingsStore.instance;
    if (settings.shouldNotify({'type': 'new_case_request'})) {
      NotificationService.playForegroundAlert(
        sound: settings.shouldPlaySound,
        vibration: settings.shouldVibrate,
      );
    }

    _dismissTimer?.cancel();
    const seconds = CaseRequestService.broadcastTimeoutSeconds;
    _dismissTimer = Timer(const Duration(seconds: seconds), () {
      if (_activeRequestCode == requestCode) {
        _closeDialogIfOpen(message: 'หมดเวลารับเคส', rememberSkip: true);
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctx = navigatorKey.currentContext;
      if (ctx == null) {
        _dialogOpen = false;
        return;
      }

      showGeneralDialog(
        context: ctx,
        useRootNavigator: true,
        barrierDismissible: false,
        barrierLabel: 'lawyerCase',
        barrierColor: Colors.black.withOpacity(0.55),
        transitionDuration: const Duration(milliseconds: 280),
        pageBuilder: (dialogCtx, __, ___) {
          _dialogContext = dialogCtx;
          return LawyerCasePopup(
            caseData: data,
            expiresInSeconds: seconds,
            onAccept: () async {
              _dismissTimer?.cancel();
              await claimCase(requestCode);
            },
            onDismiss: () {
              _dismissTimer?.cancel();
              _dialogOpen = false;
              if (requestCode.isNotEmpty) {
                unawaited(_rememberSkipped(requestCode));
              }
              _activeRequestCode = null;
              if (Navigator.canPop(dialogCtx)) {
                Navigator.of(dialogCtx, rootNavigator: true).pop();
              }
            },
          );
        },
        transitionBuilder: (_, animation, __, child) {
          return Transform.scale(
            scale: Curves.easeOutBack.transform(animation.value),
            child: FadeTransition(opacity: animation, child: child),
          );
        },
      ).whenComplete(() {
        _dialogContext = null;
        _dialogOpen = false;
        _dismissTimer?.cancel();
      });
    });
  }

  void _closeDialogIfOpen({String? message, bool rememberSkip = true}) {
    if (!_dialogOpen) return;

    final codeToSkip = _activeRequestCode;
    _dialogOpen = false;
    _dismissTimer?.cancel();
    _dismissTimer = null;

    if (rememberSkip && codeToSkip != null && codeToSkip.isNotEmpty) {
      unawaited(_rememberSkipped(codeToSkip));
    }

    final ctx = _dialogContext ?? navigatorKey.currentContext;
    _dialogContext = null;
    _activeRequestCode = null;

    if (ctx != null) {
      try {
        // ✅ rootNavigator: true สำคัญมาก
        Navigator.of(ctx, rootNavigator: true).maybePop();
      } catch (e) {
        debugPrint('maybePop error: $e');
      }
    }

    if (message != null) {
      Future.delayed(const Duration(milliseconds: 300), () {
        final messengerCtx = navigatorKey.currentContext;
        if (messengerCtx != null) {
          try {
            ScaffoldMessenger.of(messengerCtx).showSnackBar(
              SnackBar(content: Text(message)),
            );
          } catch (_) {}
        }
      });
    }
  }

  double _haversineKm(double lat1, double lon1, double lat2, double lon2) {
    const r = 6371.0;
    final dLat = (lat2 - lat1) * pi / 180;
    final dLon = (lon2 - lon1) * pi / 180;
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1 * pi / 180) *
            cos(lat2 * pi / 180) *
            sin(dLon / 2) *
            sin(dLon / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return r * c;
  }

  Map<String, dynamic> _unwrapPayload(Map<String, dynamic> data) {
    for (final key in ['objectData', 'data', 'caseRequest', 'request']) {
      final nested = data[key];
      if (nested is Map) {
        return {...data, ...Map<String, dynamic>.from(nested)};
      }
    }
    return data;
  }

  Map<String, dynamic> _asMap(dynamic raw) {
    if (raw is Map<String, dynamic>) return raw;
    if (raw is Map) return Map<String, dynamic>.from(raw);
    return {};
  }

  String _readRequestCode(Map<String, dynamic> data) {
    return data['requestCode']?.toString() ?? data['code']?.toString() ?? '';
  }

  double? _asDouble(dynamic v) {
    if (v == null) return null;
    if (v is double) return v;
    if (v is int) return v.toDouble();
    if (v is String) return double.tryParse(v);
    return null;
  }
}
