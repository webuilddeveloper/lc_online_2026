import 'dart:async';
import 'dart:math';

import 'package:LawyerOnline/main.dart';
import 'package:LawyerOnline/models/lawyer/lawyer_jobs_store.dart';
import 'package:LawyerOnline/models/lawyer/lawyer_profile_store.dart';
import 'package:LawyerOnline/models/lawyer/lawyer_profile_store.dart';
import 'package:LawyerOnline/models/user_profile_store.dart';
import 'package:LawyerOnline/services/case_request_service.dart';
import 'package:LawyerOnline/widgets/lawyer/lawyer_case_popup.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

/// ฟัง ReceiveNewCaseRequest จาก CaseRequestHub แล้วโชว์ popup ให้ทนายกดรับ
class LawyerCaseBroadcastService {
  LawyerCaseBroadcastService._();
  static final instance = LawyerCaseBroadcastService._();

  final CaseRequestService _caseReqService = CaseRequestService();

  bool _starting = false;
  bool _dialogOpen = false;
  String? _activeRequestCode;
  Map<String, dynamic>? _activeCaseData;
  Timer? _dismissTimer;
  BuildContext? _dialogContext;

  Future<void> sync() async {
    await UserProfileStore.instance.load();
    await LawyerProfileStore.instance.load();

    final shouldListen = UserProfileStore.instance.isLoggedIn &&
        UserProfileStore.instance.userType == 'lawyer' &&
        LawyerProfileStore.instance.isUrgentCaseEnabled;

    if (shouldListen) {
      await start();
    } else {
      await stop();
    }
  }

  Future<void> start() async {
    if (_starting) return;
    if (_caseReqService.isConnected) return;

    _starting = true;
    try {
      _caseReqService.onNewCaseRequest = _onNewCaseRequest;
      _caseReqService.onCaseRequestTaken = _onCaseTakenByOther;
      _caseReqService.onRequestExpired = _onCaseExpired;

      await _caseReqService.connectAsLawyer();
      debugPrint('LawyerCaseBroadcastService connected');
    } catch (e) {
      debugPrint('LawyerCaseBroadcastService start error: $e');
      await stop();
    } finally {
      _starting = false;
    }
  }

  Future<void> stop() async {
    _dismissTimer?.cancel();
    _dismissTimer = null;
    _closeDialogIfOpen();
    await _caseReqService.disconnect();
    _activeRequestCode = null;
  }

  Future<void> _onNewCaseRequest(dynamic raw) async {
    var data = _normalizeCaseData(_unwrapPayload(_asMap(raw)));
    if (data.isEmpty) return;

    final requestCode = _readRequestCode(data);
    if (requestCode.isEmpty) return;

    final lawyerCode = UserProfileStore.instance.code;
    if (_isExcluded(data, lawyerCode)) return;
    if (!await _isWithinRadius(data)) return;
    if (!_matchesUrgentCaseScope(data)) return;

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
    if (caseSubTopic.isEmpty) return true;

    final store = LawyerProfileStore.instance;
    if (store.isPro && store.urgentCaseScope == 'all') return true;

    final expertise = UserProfileStore.instance.user?.expertiseList ?? store.skills;
    return expertise.contains(caseSubTopic);
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

  Future<bool> _isWithinRadius(Map<String, dynamic> data) async {
    final caseLat = _asDouble(data['lat']);
    final caseLng = _asDouble(data['lng']);
    if (caseLat == null || caseLng == null) return true;

    final radiusKm = _asDouble(data['radiusKm']) ?? 20;

    double? lawyerLat = UserProfileStore.instance.lastLat;
    double? lawyerLng = UserProfileStore.instance.lastLong;

    if (lawyerLat == 0 && lawyerLng == 0) {
      try {
        var perm = await Geolocator.checkPermission();
        if (perm == LocationPermission.denied) {
          perm = await Geolocator.requestPermission();
        }
        if (perm == LocationPermission.whileInUse ||
            perm == LocationPermission.always) {
          final pos = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.medium,
          ).timeout(const Duration(seconds: 5));
          lawyerLat = pos.latitude;
          lawyerLng = pos.longitude;
        }
      } catch (_) {}
    }

    if (lawyerLat == null ||
        lawyerLng == null ||
        (lawyerLat == 0 && lawyerLng == 0)) {
      return true;
    }

    final dist = _haversineKm(lawyerLat, lawyerLng, caseLat, caseLng);
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

    var data = await _caseReqService.getRequestDetail(requestCode);
    if (data.isEmpty) return;

    data = _normalizeCaseData({
      ...data,
      'code': requestCode,
      'requestCode': requestCode,
    });
    _activeCaseData = data;
    _showCasePopup(data);
  }

  Future<void> claimCase(String requestCode) async {
    await _caseReqService.claimCaseRequest(requestCode);
    _upsertClaimedJob(requestCode);
    await _refreshLawyerJobsFromApi();
    debugPrint('✅ Case claimed successfully');
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
      'requestCode': _pick(data, const ['requestCode', 'RequestCode', 'code', 'Code']),
      'userName': _pick(data, const [
        'userName',
        'UserName',
        'clientName',
        'ClientName',
        'name',
        'Name',
      ], 'ลูกความ'),
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

    _dismissTimer?.cancel();
    const seconds = CaseRequestService.broadcastTimeoutSeconds;
    _dismissTimer = Timer(const Duration(seconds: seconds), () {
      if (_activeRequestCode == requestCode) {
        _closeDialogIfOpen(message: 'หมดเวลารับเคส');
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

  void _closeDialogIfOpen({String? message}) {
    if (!_dialogOpen) return;

    _dialogOpen = false;
    _dismissTimer?.cancel();
    _dismissTimer = null;

    final ctx = _dialogContext ?? navigatorKey.currentContext;
    _dialogContext = null;

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
