import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:LawyerOnline/component/appbar.dart';
import 'package:LawyerOnline/component/app_dropdown.dart';
import 'package:LawyerOnline/consult/consult_detail.dart';
import 'package:LawyerOnline/consult/consult_payment.dart';
import 'package:LawyerOnline/lawyer-online-details.dart';
import 'package:LawyerOnline/models/user_profile_store.dart';
import 'package:LawyerOnline/services/case_request_service.dart';
import 'package:LawyerOnline/shared/api_provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

enum _Phase { searching, found, error, idle }

class ConsultMapPage extends StatefulWidget {
  final String topic;
  final String topicTitle;
  final String subTopic;
  final String subTopicTitle;
  final String province;
  final String detail;
  final String demand;
  final List<File> images;
  final String? requestCode;
  final int caseType;

  const ConsultMapPage({
    super.key,
    required this.topic,
    required this.topicTitle,
    required this.subTopic,
    required this.subTopicTitle,
    required this.province,
    required this.detail,
    required this.demand,
    required this.images,
    this.requestCode,
    this.caseType = 2,
  });

  @override
  State<ConsultMapPage> createState() => _ConsultMapPageState();
}

class _ConsultMapPageState extends State<ConsultMapPage>
    with TickerProviderStateMixin {
  final CaseRequestService _caseReqService = CaseRequestService();

  int selectedIndex = 0;

  // ── Tab1 (broadcast) ──
  static const String _noLawyerFoundError = '__NO_LAWYER_FOUND__';

  bool _isSearching = false;
  bool _lawyerFound = false;
  bool _isReassigning = false;
  Map<String, dynamic>? _pendingLawyer;
  String? _errorMsg;

  // ── Tab2 (เลือกเอง) ──
  List<dynamic> _lawyers = [];
  bool _loadingLawyers = false;
  String? _lawyerLoadError;
  Position? _currentPosition;

  final MapController _mapController = MapController();
  LatLng _userLocation = const LatLng(13.7563, 100.5018);

  late AnimationController _p1, _p2, _p3;
  late Animation<double> _p1a, _p2a, _p3a;
  late AnimationController _slideAnim;
  late Animation<Offset> _slideOffset;
  late AnimationController _cardAnim;

  final List<String> _statusTexts = ['กำลังค้นหาทนายในพื้นที่...'];
  int _statusIdx = 0;
  Timer? _textTimer;
  Timer? _pollTimer;
  Timer? _broadcastTimer;

  int _lawyerDetailRetries = 0;
  Timer? _lawyerDetailRetryTimer;

  final List<double?> _radiusOptions = [5, 10, 20, null];
  double? _selectedRadius = 10;

  _Phase get _phase {
    if (_errorMsg != null) return _Phase.error;
    if (_lawyerFound && _pendingLawyer != null) return _Phase.found;
    if (_isSearching) return _Phase.searching;
    return _Phase.idle;
  }

  bool get _isNoLawyerError => _errorMsg == _noLawyerFoundError;

  @override
  void initState() {
    super.initState();
    selectedIndex = widget.requestCode != null ? 0 : 1;
    _initAnimations();
    _tryGps(); // ✅ เรียก GPS ก่อนอื่น
    unawaited(_loadLawyers());

    if (widget.requestCode != null) {
      _startBroadcastListening();
    }

    print('---------->>>>>>> ${widget.requestCode}');
  }

  Future<void> _startBroadcastListening() async {
    setState(() {
      _isSearching = true;
      _lawyerFound = false;
      _pendingLawyer = null;
      _errorMsg = null;
      _statusIdx = 0;
    });
    _slideAnim.reset();
    _cardAnim.reset();
    _startPulse();
    _startStatusTextCycle();

    _caseReqService.onLawyerWantsToTakeCase = (data) {
      print('--===---===---===--->>>>>>>> ${data}');
      if (!mounted || widget.requestCode == null) return;
      final event = _asMap(data);
      final eventCode =
          event['requestCode']?.toString() ?? event['code']?.toString() ?? '';
      if (eventCode.isNotEmpty && eventCode != widget.requestCode) return;
      unawaited(_handleLawyerClaim(event));
    };

    _caseReqService.onRequestExpired = (data) {
      if (!mounted || _lawyerFound) return;
      _stopSearchingWithNoLawyer();
    };

    _caseReqService.onSearchingAgain = (data) {
      if (!mounted) return;
      setState(() {
        _isSearching = true;
        _lawyerFound = false;
        _pendingLawyer = null;
        _errorMsg = null;
        _isReassigning = false;
        _statusIdx = 0;
      });
      _slideAnim.reset();
      _cardAnim.reset();
      _startPulse();
      _startStatusTextCycle();
      _startPolling();
      _startBroadcastTimeout();
    };

    try {
      await UserProfileStore.instance.load();
      await _caseReqService.connectAsClient();

      await _checkExistingClaim();
      _startPolling();
      _startBroadcastTimeout();
    } catch (e) {
      if (!mounted) return;
      _stopPulse();
      _textTimer?.cancel();
      setState(() {
        _isSearching = false;
        _errorMsg = 'เกิดข้อผิดพลาดในการเชื่อมต่อ: ${e.toString()}';
      });
    }
  }

  // ✅ แก้: ตรวจสอบและรับ GPS ก่อน + คำนวณ distance
  Future<void> _handleLawyerClaim(Map<String, dynamic> event) async {
    final quickLawyer = CaseRequestService.lawyerCardFromClaimEvent(event);
    if (!mounted) return;
    _onLawyerFound(quickLawyer);

    try {
      // ✅ ตรวจสอบ GPS ก่อน
      if (_currentPosition == null) {
        print('⚠️ _currentPosition is null, requesting GPS...');
        try {
          final pos = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.high,
          ).timeout(const Duration(seconds: 5));

          if (mounted) {
            setState(() => _currentPosition = pos);
            print('✅ GPS obtained: ${pos.latitude}, ${pos.longitude}');
          }
        } catch (e) {
          print('⚠️ GPS request failed: $e');
        }
      }

      // ✅ Retry logic: โหลดข้อมูลทนายถึง 3 ครั้ง ห่างกัน 500ms
      Map<String, dynamic> detail = {};
      _lawyerDetailRetries = 0;

      while (_lawyerDetailRetries < 3 && detail.isEmpty && mounted) {
        try {
          detail = await _caseReqService.getLawyerDetail(widget.requestCode!);
          if (detail.isNotEmpty) {
            print(
                '✅ Lawyer detail loaded (attempt ${_lawyerDetailRetries + 1})');
            break;
          }
        } catch (e) {
          print('⚠️ Attempt ${_lawyerDetailRetries + 1} failed: $e');
        }

        _lawyerDetailRetries++;
        if (_lawyerDetailRetries < 3 && detail.isEmpty) {
          await Future.delayed(const Duration(milliseconds: 500));
        }
      }

      if (!mounted || detail.isEmpty) {
        print(
            '❌ Failed to load lawyer detail after ${_lawyerDetailRetries} attempts');
        // ใช้ quick lawyer จากท event ก่อน
        if (mounted) {
          setState(() => _pendingLawyer = quickLawyer);
        }
        return;
      }

      print('📍 Lawyer detail keys: ${detail.keys.toList()}');
      print('📍 Lawyer detail: $detail');

      // ✅ คำนวณ distance
      if (_currentPosition != null) {
        final lat = _asDouble(detail['lastLat'] ??
            detail['lat'] ??
            detail['Lat'] ??
            event['lat']);
        final lng = _asDouble(detail['lastLng'] ??
            detail['lastLong'] ??
            detail['lng'] ??
            detail['Lng'] ??
            detail['Long'] ??
            event['lng']);

        print('🔍 Lawyer location: lat=$lat, lng=$lng');
        print(
            '📍 User location: ${_currentPosition!.latitude}, ${_currentPosition!.longitude}');

        if (lat != null && lng != null) {
          final dist = _haversineKm(
            _currentPosition!.latitude,
            _currentPosition!.longitude,
            lat,
            lng,
          );
          detail['distanceKm'] = dist;
          detail['_distanceKm'] = dist;
          print('✅ Distance calculated: $dist km');
        } else {
          print('❌ Cannot get lawyer location from detail or event');
          detail['distanceKm'] = null;
        }
      } else {
        print('❌ _currentPosition still null after retry');
        detail['distanceKm'] = null;
      }

      final enriched = CaseRequestService.lawyerCardFromClaimEvent(
        event,
        detail: Map<String, dynamic>.from(detail),
      );

      if (mounted) {
        setState(() {
          _pendingLawyer = enriched;
          _mergeLawyerIntoList(enriched);
        });
        print('✅ _pendingLawyer updated with full detail');
      }
    } catch (e) {
      print('❌ Error in _handleLawyerClaim: $e');
      // fallback: ใช้ quick lawyer
      if (mounted) {
        setState(() => _pendingLawyer = quickLawyer);
      }
    }
  }

  Future<void> _checkExistingClaim() async {
    if (widget.requestCode == null) return;
    try {
      final detail =
          await _caseReqService.getRequestDetail(widget.requestCode!);
      if (!mounted || detail.isEmpty) return;

      final statusNum = _parseRequestStatus(detail);
      final pendingLawyer = _pickStr(detail, const [
        'pendingLawyer',
        'PendingLawyer',
        'lawyerCode',
        'LawyerCode',
      ]);
      final pendingLawyerName = _pickStr(detail, const [
        'pendingLawyerName',
        'PendingLawyerName',
        'lawyerName',
        'LawyerName',
      ]);
      final lat = detail['lat'] ?? detail['Lat'];
      final lng = detail['lng'] ?? detail['Lng'];

      // มีทนายกดรับแล้ว (รอลูกความยืนยัน) → โชว์ panel ให้เลือกรับ
      if (statusNum == 2 &&
          (pendingLawyer.isNotEmpty || pendingLawyerName.isNotEmpty)) {
        await _handleLawyerClaim({
          'requestCode': widget.requestCode,
          'lawyerCode': pendingLawyer,
          'lawyerName': pendingLawyerName,
          'lat': lat,
          'lng': lng,
        });
      }
    } catch (e) {
      debugPrint('_checkExistingClaim error: $e');
    }
  }

  int? _parseRequestStatus(Map<String, dynamic> detail) {
    final raw = detail['status'] ??
        detail['requestStatus'] ??
        detail['Status'] ??
        detail['RequestStatus'];
    if (raw is int) return raw;
    if (raw is num) return raw.toInt();
    return int.tryParse(raw?.toString() ?? '');
  }

  String _pickStr(Map<String, dynamic> source, List<String> keys) {
    for (final key in keys) {
      final v = source[key];
      if (v != null && v.toString().trim().isNotEmpty) {
        return v.toString().trim();
      }
    }
    return '';
  }

  double? _getDistance(dynamic lawyer) {
    final userLat = _userLocation.latitude;
    final userLng = _userLocation.longitude;

    double? distanceKm = _asDouble(lawyer['_distanceKm']) ??
        _asDouble(lawyer['distanceKm']) ??
        _asDouble(lawyer['distance']);

    if (distanceKm == null) {
      final lat = _readLat(lawyer);
      final lng = _readLng(lawyer);
      if (lat != null && lng != null) {
        distanceKm = _haversineKm(userLat, userLng, lat, lng);
      }
    }

    return distanceKm;
  }

  void _startBroadcastTimeout() {
    _broadcastTimer?.cancel();
    _broadcastTimer = Timer(
      Duration(seconds: CaseRequestService.broadcastTimeoutSeconds),
      () {
        if (!mounted) return;
        if (_isSearching && !_lawyerFound) {
          _stopSearchingWithNoLawyer();
        }
      },
    );
  }

  void _stopSearchingWithNoLawyer() {
    _stopSearching(message: _noLawyerFoundError);
  }

  Future<void> _retryBroadcastSearch() async {
    if (widget.requestCode == null) return;

    try {
      final detail =
          await _caseReqService.getRequestDetail(widget.requestCode!);
      final statusNum = _parseRequestStatus(detail);

      // มีทนายรับไว้แล้ว → แค่เปิดฟังใหม่แล้วโชว์ panel ให้เลือกรับ
      if (statusNum == 2) {
        await _startBroadcastListening();
        return;
      }

      // ยังไม่มีคนรับ / หมดเวลาฝั่ง UI → broadcast หาทนายใหม่
      await _caseReqService.rebroadcastCaseRequest(widget.requestCode!);
    } catch (e) {
      debugPrint('_retryBroadcastSearch error: $e');
    }

    await _startBroadcastListening();
  }

  void _startPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 2), (_) async {
      if (!mounted || widget.requestCode == null) return;
      if (_lawyerFound && _pendingLawyer != null) return;
      await _checkExistingClaim();
    });
  }

  void _stopSearching({String? message}) {
    _stopPulse();
    _textTimer?.cancel();
    _pollTimer?.cancel();
    _broadcastTimer?.cancel();
    setState(() {
      _isSearching = false;
      if (message != null) {
        _lawyerFound = false;
        _pendingLawyer = null;
        _errorMsg = message;
      }
    });
    if (message == _noLawyerFoundError) {
      _slideAnim.forward(from: 0);
    }
  }

  Map<String, dynamic> _asMap(dynamic raw) {
    if (raw is Map<String, dynamic>) return raw;
    if (raw is Map) return Map<String, dynamic>.from(raw);
    return {};
  }

  void _onLawyerFound(Map<String, dynamic> lawyer) {
    if (_lawyerFound && _pendingLawyer != null) {
      if (mounted) setState(() => _pendingLawyer = lawyer);
      return;
    }

    _stopPulse();
    _textTimer?.cancel();
    _pollTimer?.cancel();
    _broadcastTimer?.cancel();
    if (!mounted) return;

    setState(() {
      _isSearching = false;
      _lawyerFound = true;
      _pendingLawyer = lawyer;
      _errorMsg = null;
      _statusIdx = _statusTexts.length - 1;
      _mergeLawyerIntoList(lawyer);
    });

    _slideAnim.value = 1.0;
    _cardAnim.forward(from: 0);

    final pos = _lawyerLatLng(lawyer);
    if (pos != null) {
      Future.delayed(const Duration(milliseconds: 400), () {
        if (mounted) _mapController.move(pos, 15);
      });
    }
  }

  Future<void> _selectLawyer() async {
    await _caseReqService.detachAfterMatch();
    if (widget.requestCode == null || _pendingLawyer == null) return;
    final result = await _caseReqService.selectLawyer(widget.requestCode!);
    if (!mounted) return;
    if (result['success'] == true) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => ConsultQrPage(
            amount: 500,
            lawyer: _pendingLawyer,
            topic: widget.topic,
            topicTitle: widget.topicTitle,
            subTopic: widget.subTopic,
            subTopicTitle: widget.subTopicTitle,
            province: widget.province,
            detail: widget.detail,
            demand: widget.demand,
            caseType: widget.caseType,
            requestCode: widget.requestCode,
            paymentInfo: result['payment'],
          ),
        ),
      );
    } else {
      _showError('เกิดข้อผิดพลาด กรุณาลองใหม่');
    }
  }

  Future<void> _onReassign() async {
    if (_isReassigning || widget.requestCode == null) return;

    setState(() => _isReassigning = true);
    _cardAnim.reverse();

    await Future.delayed(const Duration(milliseconds: 350));
    await _caseReqService.rejectLawyer(widget.requestCode!);

    if (!mounted) return;

    _caseReqService.onLawyerWantsToTakeCase = (data) {
      if (!mounted || widget.requestCode == null) return;
      final event = _asMap(data);
      final eventCode =
          event['requestCode']?.toString() ?? event['code']?.toString() ?? '';
      if (eventCode.isNotEmpty && eventCode != widget.requestCode) return;
      unawaited(_handleLawyerClaim(event));
    };

    setState(() {
      _isReassigning = false;
      _isSearching = true;
      _lawyerFound = false;
      _pendingLawyer = null;
      _statusIdx = 0;
    });
    _slideAnim.reset();
    _cardAnim.reset();
    _startPulse();
    _startStatusTextCycle();
    _startPolling();
    _startBroadcastTimeout();
  }

  Future<void> _loadLawyers() async {
    if (_loadingLawyers) return;

    setState(() {
      _loadingLawyers = true;
      _lawyerLoadError = null;
    });

    try {
      await _updateUserLocationFromGps();

      final lawyers = await _fetchLawyersFromApi();
      if (!mounted) return;

      setState(() {
        _lawyers = lawyers;
        _loadingLawyers = false;
        _lawyerLoadError = lawyers.isEmpty ? 'ไม่พบทนายความ' : null;
      });
    } catch (e, st) {
      debugPrint('❌ _loadLawyers error: $e\n$st');
      if (!mounted) return;
      setState(() {
        _loadingLawyers = false;
        _lawyerLoadError = 'ไม่พบทนายความ';
      });
    }
  }

  void _mergeLawyerIntoList(Map<String, dynamic> lawyer) {
    final code = lawyer['code']?.toString() ?? '';
    if (code.isEmpty) return;

    final normalized = _normalizeLawyerItem(lawyer);
    final exists = _lawyers.any(
      (item) => (item is Map ? item['code'] : null)?.toString() == code,
    );
    if (exists) return;

    _lawyers = [..._lawyers, normalized];
    _lawyerLoadError = null;
  }

  Future<List<dynamic>> _fetchLawyersFromApi() async {
    final filters = <String>[
      if (widget.subTopicTitle.trim().isNotEmpty) widget.subTopicTitle.trim(),
      if (widget.topicTitle.trim().isNotEmpty) widget.topicTitle.trim(),
      '',
    ];

    for (final filter in filters) {
      final lawyers = await _readLawyers(subTopic: filter);
      if (lawyers.isNotEmpty) return lawyers;
    }
    return const [];
  }

  Future<Map<String, dynamic>?> _postRegisterRead(
    Map<String, dynamic> criteria,
  ) async {
    final dioResult = await postDio('${server}/m/register/read', criteria);
    if (dioResult is Map) {
      return Map<String, dynamic>.from(dioResult);
    }

    const storage = FlutterSecureStorage();
    final profileCode = await storage.read(key: 'profileCode18');
    final payload = <String, dynamic>{
      ...criteria,
      if (profileCode != null && profileCode.isNotEmpty)
        'profileCode': profileCode,
    };

    final token = UserProfileStore.instance.token.trim();
    final response = await http.post(
      Uri.parse('${server}/m/register/read'),
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        if (token.isNotEmpty) 'Authorization': 'Bearer $token',
      },
      body: jsonEncode(payload),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      debugPrint('❌ register/read HTTP ${response.statusCode}');
      return null;
    }

    final decoded = jsonDecode(response.body);
    if (decoded is Map<String, dynamic>) return decoded;
    if (decoded is Map) return Map<String, dynamic>.from(decoded);
    return null;
  }

  Future<List<dynamic>> _readLawyers({String subTopic = ''}) async {
    final criteria = <String, dynamic>{
      'userType': 'lawyer',
      'limit': 100,
    };
    if (subTopic.isNotEmpty) {
      criteria['subTopic'] = subTopic;
    }

    final res = await _postRegisterRead(criteria);
    if (res == null) return [];

    final lawyers = _normalizeLawyerList(res['objectData']);
    debugPrint(
      '📥 register/read subTopic="$subTopic" -> ${lawyers.length} lawyers',
    );
    return lawyers;
  }

  List<dynamic> _normalizeLawyerList(dynamic objectData) {
    if (objectData is List) {
      return objectData
          .whereType<Map>()
          .map((item) => _normalizeLawyerItem(item))
          .toList();
    }
    if (objectData is Map) {
      return [_normalizeLawyerItem(objectData)];
    }
    return const [];
  }

  Map<String, dynamic> _normalizeLawyerItem(Map raw) {
    final map = raw is Map<String, dynamic>
        ? raw
        : Map<String, dynamic>.from(raw);
    final first = map['firstName']?.toString() ?? '';
    final last = map['lastName']?.toString() ?? '';
    final fullName = [first, last].where((s) => s.isNotEmpty).join(' ');

    return {
      ...map,
      'name': (map['name']?.toString().trim().isNotEmpty == true)
          ? map['name']
          : fullName,
      'lastLat': map['lastLat'] ?? map['lat'],
      'lastLng': map['lastLng'] ?? map['lastLong'] ?? map['lng'],
      'isOnline': map['isOnline'] ?? map['available'] ?? true,
    };
  }

  Future<void> _updateUserLocationFromGps() async {
    try {
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm != LocationPermission.whileInUse &&
          perm != LocationPermission.always) {
        return;
      }

      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
      ).timeout(const Duration(seconds: 5));

      if (!mounted) return;

      final loc = LatLng(pos.latitude, pos.longitude);
      setState(() {
        _currentPosition = pos;
        _userLocation = loc;
      });
      try {
        _mapController.move(loc, 14);
      } catch (e) {
        debugPrint('⚠️ MapController error: $e');
      }
    } catch (e) {
      debugPrint('⚠️ GPS skipped for lawyer list: $e');
    }
  }

  void _onLawyerTap(dynamic lawyer) {
    if (lawyer is! Map) return;
    final lawyerMap = _normalizeLawyerItem(lawyer);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ConsultDetailPage(
          lawyer: lawyerMap,
          topic: widget.topic,
          topicTitle: widget.topicTitle,
          subTopic: widget.subTopic,
          subTopicTitle: widget.subTopicTitle,
          province: widget.province,
          detail: widget.detail,
          demand: widget.demand,
          images: widget.images,
          caseType: 1,
        ),
      ),
    );
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.red),
    );
  }

  void _initAnimations() {
    _p1 = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );
    _p1a = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _p1, curve: Curves.easeOut),
    );

    _p2 = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );
    _p2a = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _p2, curve: Curves.easeOut),
    );

    _p3 = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );
    _p3a = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _p3, curve: Curves.easeOut),
    );

    _slideAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _slideOffset =
        Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero).animate(
      CurvedAnimation(parent: _slideAnim, curve: Curves.easeOutCubic),
    );

    _cardAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
  }

  void _startPulse() {
    if (!_p1.isAnimating) _p1.repeat();
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted && _isSearching) _p2.repeat();
    });
    Future.delayed(const Duration(milliseconds: 1000), () {
      if (mounted && _isSearching) _p3.repeat();
    });
  }

  void _stopPulse() {
    _p1.stop();
    _p2.stop();
    _p3.stop();
  }

  void _startStatusTextCycle() {
    _textTimer?.cancel();
    _textTimer = Timer(const Duration(seconds: 2), () {
      if (mounted && _isSearching) {
        final nextIdx = _statusIdx + 1;
        if (nextIdx < _statusTexts.length) {
          // ✅ ตรวจก่อนเซ็ต
          setState(() => _statusIdx = nextIdx);
        }
      }
    });
  }

  // ✅ แก้: ต้องเซ็ต _currentPosition
  void _tryGps() async {
    try {
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.whileInUse ||
          perm == LocationPermission.always) {
        try {
          final pos = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.high,
          ).timeout(const Duration(seconds: 4));
          if (mounted) {
            final loc = LatLng(pos.latitude, pos.longitude);
            setState(() {
              _userLocation = loc;
              _currentPosition = pos; // ✅ เซ็ต _currentPosition
            });
            _mapController.move(loc, 14);
            print('✅ GPS acquired: ${pos.latitude}, ${pos.longitude}');
          }
        } catch (e) {
          print('⚠️ GPS timeout: $e');
        }
      }
    } catch (e) {
      print('❌ GPS error: $e');
    }
  }

  double? _readLat(dynamic l) => _asDouble(l['lastLat']);
  double? _readLng(dynamic l) => _asDouble(l['lastLng'] ?? l['lastLong']);

  double? _asDouble(dynamic v) {
    if (v == null) return null;
    if (v is double) return v;
    if (v is int) return v.toDouble();
    if (v is String) return double.tryParse(v);
    return null;
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

  String _formatDistanceStr(double? km) {
    if (km == null) return 'ไม่ระบุระยะทาง';
    if (km < 1) return '${(km * 1000).round()} ม.';
    return '${km.toStringAsFixed(1)} กม.';
  }

  Color _lawyerColor(dynamic l) {
    final rating = _asDouble(l['rateAverage']) ?? 0.0;
    if (rating >= 5) return const Color(0xFF1565C0);
    if (rating >= 4) return const Color(0xFF02A8D1);
    if (rating >= 3) return const Color(0xFFFDD835);
    if (rating >= 2) return const Color(0xFFEF6C00);
    return const Color(0xFF0262EC);
  }

  String _lawyerName(dynamic l) => l['name'] as String? ?? '';
  String _lawyerTitle(dynamic l) {
    // // 1. ลอง title field ก่อน
    // var title = l['title'] as String?;
    // if (title != null && title.isNotEmpty) return title;

    // // 2. ลอง specialization
    // var specialty = l['specialization'] as String?;
    // if (specialty != null && specialty.isNotEmpty) return specialty;

    // // 3. ลอง rateAverage (แปลงเป็น string + emoji)
    // final rating = _asDouble(l['rateAverage']);
    // if (rating != null) return '${rating.toStringAsFixed(1)} ⭐';

    // 4. fallback
    return 'ทนายความ';
  }

  String _lawyerSpecialty(dynamic l) {
    final spec = l['specialization'] as String?;
    if (spec != null && spec.isNotEmpty) return spec;

    final category = l['category'] as String?;
    if (category != null && category.isNotEmpty) return category;

    final exp = _lawyerExperience(l);
    return exp;
  }

  String _lawyerExperience(dynamic l) {
    final exp = l['experienceYears'];
    if (exp == null) return 'ไม่ระบุ';
    final s = exp.toString();
    return s.contains('ปี') ? s : '$s ปี';
  }

  bool _isAvailable(dynamic l) =>
      l['isOnline'] as bool? ?? l['available'] as bool? ?? true;

  String _lawyerInitial(dynamic l) {
    final name = _lawyerName(l);
    if (name.isEmpty) return '?';
    return name.characters.first;
  }

  List<dynamic> get _filteredLawyersList {
    final userLat = _userLocation.latitude;
    final userLng = _userLocation.longitude;

    final availableOnly = _lawyers.where(_isAvailable);

    final withDistance = availableOnly.map((l) {
      final lat = _readLat(l);
      final lng = _readLng(l);
      double? distanceKm = _asDouble(l['distanceKm']);
      if (distanceKm == null && lat != null && lng != null) {
        distanceKm = _haversineKm(userLat, userLng, lat, lng);
      }
      final item = l is Map ? _normalizeLawyerItem(l) : <String, dynamic>{};
      return <String, dynamic>{...item, '_distanceKm': distanceKm};
    }).toList();

    void sortByDistance(List<dynamic> items) {
      items.sort((a, b) {
        final kmA = a['_distanceKm'] as double?;
        final kmB = b['_distanceKm'] as double?;
        if (kmA == null && kmB == null) return 0;
        if (kmA == null) return 1;
        if (kmB == null) return -1;
        return kmA.compareTo(kmB);
      });
    }

    if (_selectedRadius == null) {
      sortByDistance(withDistance);
      return withDistance;
    }

    final filtered = withDistance.where((l) {
      final km = l['_distanceKm'] as double?;
      return km == null || km <= _selectedRadius!;
    }).toList();
    sortByDistance(filtered);
    return filtered;
  }

  // เพิ่มหลัง _readLng()
  LatLng? _lawyerLatLng(dynamic l) {
    final lat = _asDouble(l['lastLat'] ?? l['lat'] ?? l['Lat']);
    final lng = _asDouble(
        l['lastLng'] ?? l['lastLong'] ?? l['lng'] ?? l['Lng'] ?? l['Long']);
    if (lat == null || lng == null) return null;
    return LatLng(lat, lng);
  }

  Widget _lawyerAvatar(dynamic l, Color color, {double size = 60}) {
    final url = l['imageUrl'] as String? ?? '';
    if (url.isNotEmpty) {
      if (url.startsWith('http')) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(size / 2),
          child: CachedNetworkImage(
            imageUrl: url,
            width: size,
            height: size,
            fit: BoxFit.cover,
            placeholder: (_, __) => CircleAvatar(
              radius: size / 2,
              backgroundColor: color.withOpacity(0.12),
              child: Text(
                _lawyerInitial(l),
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: size * 0.4,
                ),
              ),
            ),
            errorWidget: (_, __, ___) => CircleAvatar(
              radius: size / 2,
              backgroundColor: color.withOpacity(0.12),
              child: Text(
                _lawyerInitial(l),
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: size * 0.4,
                ),
              ),
            ),
          ),
        );
      }
      return ClipRRect(
        borderRadius: BorderRadius.circular(size / 2),
        child: Image.asset(
          url,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => CircleAvatar(
            radius: size / 2,
            backgroundColor: color.withOpacity(0.12),
            child: Text(
              _lawyerInitial(l),
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: size * 0.4,
              ),
            ),
          ),
        ),
      );
    }

    return CircleAvatar(
      radius: size / 2,
      backgroundColor: color.withOpacity(0.12),
      child: Text(
        l['avatar'] as String? ?? _lawyerInitial(l),
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: size * 0.4,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _caseReqService.disconnect();
    _p1.dispose();
    _p2.dispose();
    _p3.dispose();
    _slideAnim.dispose();
    _cardAnim.dispose();
    _textTimer?.cancel();
    _pollTimer?.cancel();
    _broadcastTimer?.cancel();
    // _mapController.dispose();
    _lawyerDetailRetryTimer?.cancel();
    super.dispose();
  }

  Future<void> CancelCaseRequest() async {
     await _caseReqService.detachAfterMatch();
    try {
      dynamic model = {"code": widget.requestCode, 'userCode': UserProfileStore.instance.code,};
      final param = await postDio("${server}/m/caseRequest/cancel", model);
      print('>>>>>>>>>>>>>>> ${param}');
      // if (param['status'] == 'S') {
        
      // }
      Navigator.pop(context);
    } catch (_) {
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEEF2F5),
      appBar: appBar(
        title: 'หมอความออนไลน์',
        backBtn: true,
        rightBtn: false,
        rightAction: () {},
        backAction: () async =>
            {
              CancelCaseRequest(),
            },
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Expanded(child: _tab('หาทนายให้ฉัน', 0)),
                const SizedBox(width: 12),
                Expanded(child: _tab('เลือกทนายเอง', 1)),
              ],
            ),
          ),
          Expanded(
            child: selectedIndex == 0 ? _mapView() : _listView(),
          ),
        ],
      ),
    );
  }

  Widget _tab(String t, int i) {
    final on = selectedIndex == i;
    return GestureDetector(
      onTap: () {
        setState(() => selectedIndex = i);
        if (i == 1 &&
            (_lawyers.isEmpty || _lawyerLoadError != null) &&
            !_loadingLawyers) {
          _loadLawyers();
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 45,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: on ? const Color(0xFF0262EC) : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: on ? const Color(0xFF0262EC) : const Color(0xFFDDE3EE),
          ),
        ),
        child: Text(
          t,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
            color: on ? Colors.white : Colors.grey[500],
          ),
        ),
      ),
    );
  }

  Widget _mapView() {
    // รวม lawyers จากทั้ง 2 tab
    final lawyerList = _lawyers.isNotEmpty ? _lawyers : <dynamic>[];
    final pendingCode = _pendingLawyer?['code']?.toString() ?? '';

    return Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: _userLocation,
            initialZoom: 14,
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'td.webuild.lawyer',
            ),
            MarkerLayer(
              markers: [
                // ── User marker ──
                Marker(
                  point: _userLocation,
                  width: 60,
                  height: 60,
                  child: _userMarker(),
                ),

                // ── Lawyer markers ──
                ...lawyerList
                    .map((l) {
                      final pos = _lawyerLatLng(l);
                      if (pos == null) return null;
                      final code = l['code']?.toString() ?? '';
                      final isHighlighted =
                          pendingCode.isNotEmpty && code == pendingCode;
                      return Marker(
                        point: pos,
                        width: isHighlighted ? 72 : 48,
                        height: isHighlighted ? 100 : 56,
                        child: GestureDetector(
                          onTap: () {
                            _mapController.move(pos, 15);
                            if (selectedIndex == 1) _onLawyerTap(l);
                          },
                          child: _lawyerMarker(l, isHighlighted: isHighlighted),
                        ),
                      );
                    })
                    .whereType<Marker>()
                    .toList(),

                // ── Pending lawyer marker (ถ้า _lawyers ว่าง แต่มี _pendingLawyer) ──
                if (_pendingLawyer != null && lawyerList.isEmpty)
                  ...() {
                    final pos = _lawyerLatLng(_pendingLawyer!);
                    if (pos == null) return <Marker>[];
                    return [
                      Marker(
                        point: pos,
                        width: 72,
                        height: 100,
                        child:
                            _lawyerMarker(_pendingLawyer!, isHighlighted: true),
                      ),
                    ];
                  }(),
              ],
            ),
          ],
        ),

        // overlays เดิม...
        if (widget.requestCode == null) _idleOverlay(),
        if (widget.requestCode != null && _phase == _Phase.searching)
          _searchingOverlay(),
        if (widget.requestCode != null &&
            _phase == _Phase.error &&
            !_isNoLawyerError)
          _errorOverlay(),
        if (widget.requestCode != null && _phase == _Phase.error && _isNoLawyerError) ...[
          Positioned.fill(
            child: IgnorePointer(
              child: Container(color: Colors.black.withOpacity(0.25)),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: SlideTransition(
              position: _slideOffset,
              child: _noLawyerPanel(),
            ),
          ),
        ],
        if (widget.requestCode != null && _phase == _Phase.found) ...[
          Positioned.fill(
            child: IgnorePointer(
              child: Container(color: Colors.black.withOpacity(0.25)),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: SlideTransition(
              position: _slideOffset,
              child: _acceptedPanel(),
            ),
          ),
        ],
      ],
    );
  }

  Widget _userMarker() => Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF0262EC).withOpacity(0.15),
            ),
          ),
          Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF0262EC),
              border: Border.all(color: Colors.white, width: 3),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF0262EC).withOpacity(0.5),
                  blurRadius: 8,
                ),
              ],
            ),
          ),
        ],
      );

  Widget _idleOverlay() => Container(
        color: Colors.black.withOpacity(0.38),
        child: Center(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 32),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.12),
                  blurRadius: 14,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.info_outline_rounded,
                    color: Color(0xFF0262EC), size: 36),
                const SizedBox(height: 12),
                const Text(
                  'ยังไม่ได้เริ่มค้นหาทนาย',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: Color(0xFF1A2340),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'กรุณายืนยันคำขอจากหน้าก่อนหน้า\nหรือเลือกแท็บ "เลือกทนายเอง"',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey[500], fontSize: 13),
                ),
              ],
            ),
          ),
        ),
      );

  Widget _searchingOverlay() => Container(
        color: Colors.black.withOpacity(0.38),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 200,
                height: 200,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    _ring(_p1a),
                    _ring(_p2a),
                    _ring(_p3a),
                    Container(
                      width: 62,
                      height: 62,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFF0262EC),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF0262EC).withOpacity(0.6),
                            blurRadius: 20,
                            spreadRadius: 4,
                          ),
                        ],
                      ),
                      child: const Icon(Icons.gavel_rounded,
                          color: Colors.white, size: 28),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 350),
                transitionBuilder: (child, anim) => FadeTransition(
                  opacity: anim,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0, 0.3),
                      end: Offset.zero,
                    ).animate(anim),
                    child: child,
                  ),
                ),
                child: Container(
                  key: ValueKey(_statusIdx),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.12),
                        blurRadius: 14,
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(
                        width: 15,
                        height: 15,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Color(0xFF0262EC),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        _statusTexts[
                            _statusIdx.clamp(0, _statusTexts.length - 1)],
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF0262EC),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );

  Widget _errorOverlay() => Container(
        color: Colors.black.withOpacity(0.38),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: _lawyerStatusPanel(
              icon: Icons.error_outline_rounded,
              title: 'ไม่สามารถกำหนดทนายได้',
              message: _errorMsg ?? 'เกิดข้อผิดพลาด',
              onRetry: _retryBroadcastSearch,
            ),
          ),
        ),
      );

  Widget _noLawyerPanel() {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Color(0x22000000),
            blurRadius: 20,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 10),
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFEBEE),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.person_search_outlined,
                    color: Color(0xFFC62828),
                    size: 18,
                  ),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'ไม่พบทนาย',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                          color: Color(0xFF1A2340),
                        ),
                      ),
                      Text(
                        'ไม่มีทนายรับเคสในเวลาที่กำหนด',
                        style: TextStyle(
                          color: Color(0xFF9E9E9E),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Divider(height: 1, color: Color(0xFFEEF2F5)),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
            child: GestureDetector(
              onTap: _retryBroadcastSearch,
              child: Container(
                height: 50,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF0262EC), Color(0xFF0485FF)],
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.refresh_rounded, color: Colors.white, size: 18),
                    SizedBox(width: 8),
                    Text(
                      'โหลดใหม่',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _ring(Animation<double> a) => AnimatedBuilder(
        animation: a,
        builder: (_, __) => Transform.scale(
          scale: a.value,
          child: Opacity(
            opacity: (1 - a.value).clamp(0.0, 1.0),
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF0262EC).withOpacity(0.3),
              ),
            ),
          ),
        ),
      );

  Widget _lawyerMarker(dynamic l, {bool isHighlighted = false}) {
    final color = _lawyerColor(l);
    final name = _lawyerName(l);
    final initial = name.isNotEmpty ? name.characters.first : '?';
    final url = l['imageUrl'] as String? ?? '';

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // ── วงแสง highlight ──
        AnimatedContainer(
          duration: const Duration(milliseconds: 350),
          width: isHighlighted ? 56 : 38,
          height: isHighlighted ? 56 : 38,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isHighlighted
                ? const Color(0xFF0262EC).withOpacity(0.18)
                : color.withOpacity(0.10),
            border: Border.all(
              color: isHighlighted
                  ? const Color(0xFF0262EC)
                  : color.withOpacity(0.4),
              width: isHighlighted ? 2.5 : 1.5,
            ),
            boxShadow: isHighlighted
                ? [
                    BoxShadow(
                      color: const Color(0xFF0262EC).withOpacity(0.45),
                      blurRadius: 14,
                      spreadRadius: 3,
                    ),
                  ]
                : [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.15),
                      blurRadius: 6,
                    ),
                  ],
          ),
          child: ClipOval(
            child: url.startsWith('http')
                ? CachedNetworkImage(
                    imageUrl: url,
                    fit: BoxFit.cover,
                    placeholder: (_, __) =>
                        _markerInitial(initial, color, isHighlighted),
                    errorWidget: (_, __, ___) =>
                        _markerInitial(initial, color, isHighlighted),
                  )
                : _markerInitial(initial, color, isHighlighted),
          ),
        ),

        // ── หางหมุด ──
        AnimatedContainer(
          duration: const Duration(milliseconds: 350),
          width: isHighlighted ? 3 : 2,
          height: isHighlighted ? 10 : 7,
          decoration: BoxDecoration(
            color: isHighlighted ? const Color(0xFF0262EC) : color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),

        // ── ชื่อ label (เฉพาะ highlight) ──
        if (isHighlighted)
          Container(
            margin: const EdgeInsets.only(top: 2),
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: const Color(0xFF0262EC),
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF0262EC).withOpacity(0.35),
                  blurRadius: 6,
                ),
              ],
            ),
            child: Text(
              name.split(' ').first, // ชื่อแรก
              style: const TextStyle(
                color: Colors.white,
                fontSize: 9,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
      ],
    );
  }

  Widget _markerInitial(String initial, Color color, bool isHighlighted) {
    return Container(
      color: isHighlighted
          ? const Color(0xFF0262EC).withOpacity(0.12)
          : color.withOpacity(0.12),
      child: Center(
        child: Text(
          initial,
          style: TextStyle(
            color: isHighlighted ? const Color(0xFF0262EC) : color,
            fontWeight: FontWeight.w700,
            fontSize: isHighlighted ? 20 : 14,
          ),
        ),
      ),
    );
  }

  Widget _acceptedPanel() {
    if (_pendingLawyer == null || _pendingLawyer!.isEmpty) {
      return _lawyerStatusPanel(
        icon: Icons.error_outline_rounded,
        title: 'ไม่สามารถกำหนดทนายได้',
        message: 'ไม่มีทนายความที่ว่างอยู่',
        onRetry: _startBroadcastListening,
      );
    }

    final l = _pendingLawyer!;
    final color = _lawyerColor(l);

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Color(0x22000000),
            blurRadius: 20,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 10),
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: _isReassigning
                          ? Colors.orange.withOpacity(0.1)
                          : const Color(0xFFE8F5E9),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      _isReassigning
                          ? Icons.search_outlined
                          : Icons.check_circle_outline,
                      color: _isReassigning
                          ? Colors.orange
                          : const Color(0xFF2E7D32),
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _isReassigning
                            ? 'กำลังหาทนายใหม่...'
                            : 'ทนายรับเคสของคุณแล้ว!',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                          color: Color(0xFF1A2340),
                        ),
                      ),
                      Text(
                        _isReassigning
                            ? 'โปรดรอสักครู่'
                            : 'กำลังเตรียมตัวเพื่อช่วยคุณ',
                        style: TextStyle(color: Colors.grey[400], fontSize: 12),
                      ),
                    ],
                  ),
                  const Spacer(),
                  if (!_isReassigning)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0F7FF),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.schedule_outlined,
                              size: 13, color: Color(0xFF0262EC)),
                          SizedBox(width: 4),
                          Text(
                            '~5 นาที',
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF0262EC),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Divider(
              height: 1,
              indent: 20,
              endIndent: 20,
              color: Color(0xFFEEF2F5),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
              child: Row(
                children: [
                  const Icon(Icons.location_on_outlined,
                      size: 16, color: Color(0xFF0262EC)),
                  const SizedBox(width: 6),
                  const Text(
                    'รัศมีค้นหา',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1A2340),
                    ),
                  ),
                  const Spacer(),
                  AppDropdownCompact<double?>(
                    value: _selectedRadius,
                    items: _radiusOptions
                        .map(
                          (r) => DropdownMenuItem<double?>(
                            value: r,
                            child: Text(
                              r == null ? 'ไม่จำกัด' : '$r กม.',
                              style: AppDropdownStyles.itemStyle(),
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (val) {
                      setState(() => _selectedRadius = val);
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 400),
              transitionBuilder: (child, anim) => FadeTransition(
                opacity: anim,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 0.15),
                    end: Offset.zero,
                  ).animate(anim),
                  child: child,
                ),
              ),
              child: _isReassigning
                  ? Padding(
                      key: const ValueKey('__searching__'),
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Container(
                        height: 110,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: Colors.orange.withOpacity(0.25),
                            width: 1.5,
                          ),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const SizedBox(
                              width: 28,
                              height: 28,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.orange,
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'กำลังส่งคำขอไปยังทนายคนอื่น...',
                              style: TextStyle(
                                color: Colors.orange[700],
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : _lawyerCardPanel(l, color),
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: _isReassigning ? null : _onReassign,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        height: 50,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: _isReassigning
                              ? Colors.grey[100]
                              : const Color(0xFFFFEBEE),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Text(
                          'เปลี่ยนทนาย',
                          style: TextStyle(
                            color: _isReassigning
                                ? Colors.grey[400]
                                : const Color(0xFFC62828),
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: GestureDetector(
                      onTap: _isReassigning ? null : _selectLawyer,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        height: 50,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          gradient: _isReassigning
                              ? null
                              : const LinearGradient(
                                  colors: [
                                    Color(0xFF0262EC),
                                    Color(0xFF0485FF),
                                  ],
                                ),
                          color: _isReassigning ? Colors.grey[200] : null,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Text(
                          'ยืนยันทนายคนนี้',
                          style: TextStyle(
                            color: _isReassigning
                                ? Colors.grey[400]
                                : Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),
          ],
        ),
      ),
    );
  }

  Widget _lawyerStatusPanel({
    required IconData icon,
    required String title,
    required String message,
    bool isLoading = false,
    VoidCallback? onRetry,
    String retryLabel = 'ลองใหม่',
  }) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 18, 24, 28),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Color(0x22000000),
            blurRadius: 20,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 22),
          if (isLoading)
            const SizedBox(
              width: 34,
              height: 34,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF0262EC)),
              ),
            )
          else
            Icon(icon, color: const Color(0xFFC62828), size: 36),
          const SizedBox(height: 14),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1A2340),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey[500], fontSize: 13),
          ),
          if (onRetry != null) ...[
            const SizedBox(height: 16),
            TextButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: Text(retryLabel),
            ),
          ],
        ],
      ),
    );
  }

  // ✅ แก้: ตรวจสอบและคำนวณ distance ให้ชัวร์
  _lawyerCardPanel(dynamic l, Color color) {
    final userLat = _userLocation.latitude;
    final userLng = _userLocation.longitude;

    double? distanceKm =
        _asDouble(l['distanceKm']) ?? _asDouble(l['_distanceKm']);

    if (distanceKm == null && _currentPosition != null) {
      final lat = _readLat(l);
      final lng = _readLng(l);

      if (lat != null && lng != null) {
        distanceKm = _haversineKm(userLat, userLng, lat, lng);
        print('  🔄 Calculated in panel: $distanceKm km');
      }
    }

    return GestureDetector(
      onTap: () {
        // LawyerOnlineDetails(code: list[i]['code'])
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => LawyerOnlineDetails(
              code: l['code'],
              isAppointmentBtn: false,
            ),
          ),
        );
      },
      child: Padding(
        key: ValueKey(_lawyerName(l)),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: color.withOpacity(0.04),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: color.withOpacity(0.2), width: 1.5),
          ),
          child: Row(
            children: [
              Stack(
                children: [
                  _lawyerAvatar(l, color),
                  Positioned(
                    right: 1,
                    bottom: 1,
                    child: Container(
                      width: 13,
                      height: 13,
                      decoration: BoxDecoration(
                        color: const Color(0xFF43A047),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _lawyerName(l),
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        color: Color(0xFF1A2340),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _lawyerTitle(l),
                      style: TextStyle(color: Colors.grey[400], fontSize: 12),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.star_rounded,
                            color: Color(0xFFFFC107), size: 14),
                        const SizedBox(width: 3),
                        Text(
                          l['rateAverage'].toString(),
                          // '${l['rateAverage'] ?? '-'}',
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                        Text(
                          ' · ${_lawyerExperience(l)}',
                          style:
                              TextStyle(color: Colors.grey[400], fontSize: 12),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.near_me_outlined, size: 12, color: color),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            _formatDistanceStr(distanceKm),
                            style: TextStyle(
                                color: Colors.grey[500], fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _iconBtn(IconData icon, Color color, VoidCallback onTap) =>
      GestureDetector(
        onTap: onTap,
        child: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 18),
        ),
      );

  Widget _listView() {
    if (_loadingLawyers) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF0262EC)),
        ),
      );
    }

    if (_lawyers.isEmpty) {
      return _lawyerListStatus();
    }

    final list = _filteredLawyersList;
    if (list.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.location_off_outlined,
                  color: Color(0xFFC62828), size: 36),
              const SizedBox(height: 12),
              Text(
                'ไม่พบทนายในรัศมี ${_selectedRadius ?? 'ไม่จำกัด'} กม.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey[700],
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              TextButton.icon(
                onPressed: () => setState(() => _selectedRadius = null),
                icon: const Icon(Icons.expand_rounded, size: 18),
                label: const Text('ขยายรัศมี'),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: Row(
            children: [
              const Icon(Icons.location_on_outlined,
                  size: 16, color: Color(0xFF0262EC)),
              const SizedBox(width: 6),
              const Text(
                'รัศมีค้นหา',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1A2340),
                ),
              ),
              const Spacer(),
              AppDropdownCompact<double?>(
                value: _selectedRadius,
                items: _radiusOptions
                    .map(
                      (r) => DropdownMenuItem<double?>(
                        value: r,
                        child: Text(
                          r == null ? 'ไม่จำกัด' : '$r กม.',
                          style: AppDropdownStyles.itemStyle(),
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (val) {
                  setState(() => _selectedRadius = val);
                },
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
            itemCount: list.length,
            itemBuilder: (_, i) => _lawyerCard(list[i]),
          ),
        ),
      ],
    );
  }

  Widget _lawyerListStatus() => Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline_rounded,
                  color: Color(0xFFC62828), size: 36),
              const SizedBox(height: 12),
              Text(
                _lawyerLoadError ?? 'ไม่พบบัญชีทนายความ',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey[700],
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              TextButton.icon(
                onPressed: _loadLawyers,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('ลองใหม่'),
              ),
            ],
          ),
        ),
      );

  Widget _lawyerCard(dynamic l) {
    final color = _lawyerColor(l);
    final isAvailable = _isAvailable(l);
    double? distanceKm = _getDistance(l);

    return GestureDetector(
      onTap: () => _onLawyerTap(l),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              children: [
                _lawyerAvatar(l, color),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              _lawyerName(l),
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                                color: Color(0xFF1A2340),
                              ),
                            ),
                          ),
                          _badge(isAvailable),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _lawyerTitle(l),
                        style: TextStyle(color: Colors.grey[400], fontSize: 12),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.star_rounded,
                              color: Color(0xFFFFC107), size: 14),
                          const SizedBox(width: 2),
                          Text(
                            '${l['rateAverage'] ?? '-'}',
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(height: 1, color: Color(0xFFEEF2F5)),
            const SizedBox(height: 12),
            Row(
              children: [
                _chip(Icons.gavel_outlined, _lawyerSpecialty(l)),
                const SizedBox(width: 8),
                _chip(Icons.near_me_outlined, _formatDistanceStr(distanceKm)),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Spacer(),
                GestureDetector(
                  onTap: isAvailable ? () => _onLawyerTap(l) : null,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      gradient: isAvailable
                          ? const LinearGradient(
                              colors: [
                                Color(0xFF0262EC),
                                Color(0xFF0485FF),
                              ],
                            )
                          : null,
                      color: isAvailable ? null : Colors.grey[200],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'นัดหมาย',
                      style: TextStyle(
                        color: isAvailable ? Colors.white : Colors.grey[400],
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _badge(bool ok) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: ok ? const Color(0xFFE8F5E9) : const Color(0xFFFFEBEE),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          ok ? 'ว่างอยู่' : 'ไม่ว่าง',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: ok ? const Color(0xFF2E7D32) : const Color(0xFFC62828),
          ),
        ),
      );

  Widget _chip(IconData icon, String label) => Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFFEEF2F5),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(icon, size: 13, color: const Color(0xFF0262EC)),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF1A2340),
                  ),
                ),
              ),
            ],
          ),
        ),
      );



}
