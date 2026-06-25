import 'dart:async';
import 'dart:convert';
import 'dart:ui';

import 'package:LawyerOnline/models/user_profile_store.dart';
import 'package:LawyerOnline/shared/api_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:signalr_netcore/signalr_client.dart';

/// SignalR + REST สำหรับ CaseRequest flow
/// สอดคล้องกับ backend CaseRequestController + CaseRequestHub
class CaseRequestService {
  HubConnection? _connection;
  String? _joinedUserCode;
  String? _joinedLawyerCode;

  void Function(dynamic data)? onLawyerWantsToTakeCase;
  void Function(dynamic data)? onRequestExpired;
  void Function(dynamic data)? onSearchingAgain;
  void Function(dynamic data)? onNewCaseRequest;
  void Function(dynamic data)? onCaseRequestTaken;

  bool get isConnected => _connection?.state == HubConnectionState.Connected;

  Future<void> connectAsClient() async {
    await UserProfileStore.instance.load();
    final userCode = UserProfileStore.instance.code;
    if (userCode.isEmpty) throw Exception('userCode is empty');

    await _connect();
    _registerClientEvents();
    _joinedUserCode = userCode;
    await _connection!.invoke('JoinUserChannel', args: [userCode]);
    debugPrint('CaseRequestService JoinUserChannel: $userCode');
  }

  Future<void> connect() => connectAsClient();

  Future<void> connectAsLawyer() async {
    await UserProfileStore.instance.load();
    final lawyerCode = UserProfileStore.instance.code;
    if (lawyerCode.isEmpty) throw Exception('lawyerCode is empty');

    await _connect();
    _registerLawyerEvents();
    _joinedLawyerCode = lawyerCode;
    await _connection!.invoke('JoinLawyerChannel', args: [lawyerCode]);
    debugPrint('CaseRequestService JoinLawyerChannel: $lawyerCode');
  }

  Future<void> _connect() async {
    if (_connection?.state == HubConnectionState.Connected) return;

    Object? lastError;
    for (final hubUrl in caseRequestHubCandidates) {
      try {
        await _connection?.stop();
        _connection = HubConnectionBuilder()
            .withUrl(hubUrl)
            .withAutomaticReconnect()
            .build();

        _connection!.onreconnected(({String? connectionId}) async {
          debugPrint('CaseRequestService reconnected: $connectionId');
          await _rejoinChannels();
        });

        await _connection!.start();
        debugPrint('CaseRequestService connected: $hubUrl');
        return;
      } catch (e) {
        lastError = e;
        debugPrint('CaseRequestService hub failed: $hubUrl → $e');
        _connection = null;
      }
    }

    throw lastError ?? Exception('CaseRequest hub not found (404)');
  }

  Future<void> _rejoinChannels() async {
    if (_connection?.state != HubConnectionState.Connected) return;
    try {
      if (_joinedUserCode != null && _joinedUserCode!.isNotEmpty) {
        _registerClientEvents();
        final userCode = _joinedUserCode!;
        await _connection!.invoke('JoinUserChannel', args: [userCode]);
        debugPrint('CaseRequestService re-JoinUserChannel: $userCode');
      }
      if (_joinedLawyerCode != null && _joinedLawyerCode!.isNotEmpty) {
        _registerLawyerEvents();
        final lawyerCode = _joinedLawyerCode!;
        await _connection!.invoke('JoinLawyerChannel', args: [lawyerCode]);
        debugPrint('CaseRequestService re-JoinLawyerChannel: $lawyerCode');
      }
    } catch (e) {
      debugPrint('CaseRequestService rejoin error: $e');
    }
  }

  void _registerClientEvents() {
    _connection!.off('LawyerWantsToTakeCase');
    _connection!.off('CaseRequestExpired');
    _connection!.off('SearchingAgain');

    _connection!.on('LawyerWantsToTakeCase', (args) {
      final data = _parseSignalRPayload(args);
      if (data.isEmpty) return;
      debugPrint('LawyerWantsToTakeCase: $data');
      onLawyerWantsToTakeCase?.call(data);
    });

    _connection!.on('CaseRequestExpired', (args) {
      final data = args != null && args.isNotEmpty
          ? _asMap(args[0])
          : <String, dynamic>{};
      onRequestExpired?.call(data);
    });

    _connection!.on('SearchingAgain', (args) {
      final data = args != null && args.isNotEmpty
          ? _asMap(args[0])
          : <String, dynamic>{};
      onSearchingAgain?.call(data);
    });
  }

  void _registerLawyerEvents() {
    _connection!.off('ReceiveNewCaseRequest');
    _connection!.on('ReceiveNewCaseRequest', (args) {
      if (args == null || args.isEmpty) return;
      onNewCaseRequest?.call(_asMap(args[0]));
    });

    _connection!.off('CaseRequestTaken');
    _connection!.on('CaseRequestTaken', (args) {
      final data = args != null && args.isNotEmpty
          ? _asMap(args[0])
          : <String, dynamic>{};
      onCaseRequestTaken?.call(data);
    });

    _connection!.off('CaseRequestExpired');
    _connection!.on('CaseRequestExpired', (args) {
      final data = args != null && args.isNotEmpty
          ? _asMap(args[0])
          : <String, dynamic>{};
      onRequestExpired?.call(data);
    });
  }

  Future<void> claimCaseRequest(String requestCode) async {
    if (_connection == null || !isConnected) {
      throw Exception('ยังไม่ได้เชื่อมต่อ CaseRequest hub');
    }

    await UserProfileStore.instance.load();
    final lawyerCode = UserProfileStore.instance.code;
    final lawyerName = UserProfileStore.instance.name;

    double? _toDouble(dynamic value) {
      if (value == null) return null;
      if (value is double) return value;
      if (value is int) return value.toDouble();
      if (value is String) return double.tryParse(value);
      return null;
    }

    final lat =
        _toDouble(UserProfileStore.instance.lastLat) ?? 0.0; // ✅ default 0
    final lng =
        _toDouble(UserProfileStore.instance.lastLong) ?? 0.0; // ✅ default 0

    // ✅ Validate
    if (lawyerCode.isEmpty || lawyerName.isEmpty) {
      throw Exception('ข้อมูลทนายความไม่สมบูรณ์');
    }

    debugPrint(
        'ClaimCaseRequest -> requestCode:$requestCode lawyerCode:$lawyerCode lawyerName:$lawyerName lat:$lat lng:$lng');

    // ✅ ส่งค่า default แทน null
    await _connection!.invoke('ClaimCaseRequest', args: [
      requestCode,
      lawyerCode,
      lawyerName,
      lat, // ✅ ส่งตัวเลข แทน string
      lng, // ✅ ส่งตัวเลข แทน string
    ]);
  }

  Map<String, dynamic> _asMap(dynamic raw) {
    if (raw is Map<String, dynamic>) return raw;
    if (raw is Map) return Map<String, dynamic>.from(raw);
    if (raw is String && raw.isNotEmpty) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is Map) return Map<String, dynamic>.from(decoded);
      } catch (_) {}
    }
    return {};
  }

  Map<String, dynamic> _parseSignalRPayload(List<Object?>? args) {
    if (args == null || args.isEmpty) return {};
    for (final item in args) {
      final map = _asMap(item);
      if (map.isNotEmpty) return map;
    }
    return {};
  }

  Future<void> disconnect() async {
    _joinedUserCode = null;
    _joinedLawyerCode = null;
    await _connection?.stop();
    _connection = null;
  }

  Future<dynamic> createCaseRequest({
    required String topic,
    required String topicTitle,
    required String subTopic,
    required String subTopicTitle,
    required String provinceCode,
    required String provinceTitle,
    required String details,
    required String requirement,
    required List<String> imageUrlList,
    required int caseType,
    double? lat,
    double? lng,
  }) async {
    await UserProfileStore.instance.load();
    final res = await postDio('$server/m/CaseRequest/create', {
      'topic': topic,
      'topicTitle': topicTitle,
      'subTopic': subTopic,
      'subTopicTitle': subTopicTitle,
      'provinceCode': provinceCode,
      'provinceTitle': provinceTitle,
      'details': details,
      'requirement': requirement,
      'imageUrlList': imageUrlList,
      'caseType': caseType,
      'lat': lat,
      'lng': lng,
      'userCode': UserProfileStore.instance.code,
      'userName': UserProfileStore.instance.name,
    });
    return res;
  }

  /// backend ใช้ field `code` ไม่ใช่ requestCode
  Future<Map<String, dynamic>> getLawyerDetail(String requestCode) async {
    final res = await postDio(
      '$server/m/caseRequest/lawyer-detail',
      {'code': requestCode},
    );
    print('============------->>>>> ${res}');
    if (res == null) return {};
    if (res['status'] == 'S') {
      final data = res['objectData'] ?? res['data'];
      if (data is Map) return Map<String, dynamic>.from(data);
    }
    return {};
  }

  Future<dynamic> selectLawyer(String requestCode) async {
    final res = await postDio('$server/m/CaseRequest/select', {
      'code': requestCode,
      'userCode': UserProfileStore.instance.code,
    });
    if (res == null) {
      return {'success': false, 'message': 'ไม่สามารถเชื่อมต่อเซิร์ฟเวอร์ได้'};
    }
    if (res['status'] == 'S') {
      return {
        'success': true,
        'payment': res['objectData']?['payment'] ?? res['payment'],
      };
    }
    return {'success': false, 'message': res['message'] ?? 'เกิดข้อผิดพลาด'};
  }

  Future<void> rejectLawyer(String requestCode) async {
    await postDio('$server/m/CaseRequest/reject', {
      'code': requestCode,
      'userCode': UserProfileStore.instance.code,
    });
  }

  /// ยืนยันชำระเงิน → สร้าง Case จริง + ลบ caseRequest
  Future<Map<String, dynamic>> confirmPayment({
    required String requestCode,
    bool isPaySuccess = true,
    String payType = 'promptpay',
    String price = '500',
  }) async {
    final res = await postDio('$server/m/CaseRequest/payment-callback', {
      'requestCode': requestCode,
      'isPay': true,
      'payType': payType,
      'price': price,
    });
    print('====-----==== ${res}');
    if (res == null) {
      return {'success': false, 'message': 'ไม่สามารถเชื่อมต่อเซิร์ฟเวอร์ได้'};
    }
    if (res['status'] == 'S') {
      final caseData = res['objectData'];
      return {
        'success': true,
        'case': caseData is Map ? Map<String, dynamic>.from(caseData) : {},
      };
    }
    return {
      'success': false,
      'message': res['message']?.toString() ?? 'ยืนยันการชำระเงินไม่สำเร็จ',
    };
  }

  /// ใช้ POST /m/CaseRequest/read (ไม่มี /detail)
  /// filter แค่ code เพื่อให้ polling ทำงานแม้ userCode ไม่ตรง
  Future<Map<String, dynamic>> getRequestDetail(String requestCode) async {
    final res = await postDio('$server/m/CaseRequest/read', {
      'code': requestCode,
      'limit': 1,
    });
    if (res == null) return {};

    final raw = res['objectData'];
    if (raw is List && raw.isNotEmpty) {
      return Map<String, dynamic>.from(raw.first as Map);
    }
    if (raw is Map) return Map<String, dynamic>.from(raw);
    return {};
  }

  /// ใช้ POST /m/CaseRequest/read + filter lawyer (pendingLawyer)
  Future<List<Map<String, dynamic>>> getLawyerPendingRequests() async {
    await UserProfileStore.instance.load();
    final res = await postDio('$server/m/CaseRequest/read', {
      'lawyer': UserProfileStore.instance.code,
      'limit': 50,
    });
    if (res == null || res['status'] != 'S') return [];

    final raw = res['objectData'] ?? [];
    if (raw is! List) return [];

    return raw
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .where((req) {
      final status = req['status'] ?? req['requestStatus'];
      return status == 2 || status == '2' || status == 3 || status == '3';
    }).toList();
  }

  static int? _requestStatus(Map<String, dynamic> req) {
    final v = req['status'] ?? req['requestStatus'];
    if (v is int) return v;
    if (v is String) return int.tryParse(v);
    return null;
  }

  static dynamic lawyerCardFromClaimEvent(
    dynamic event, {
    dynamic detail,
  }) {
    final lawyerCode =
        event['lawyerCode']?.toString() ?? detail?['code']?.toString() ?? '';

    final firstName = detail?['firstName']?.toString() ?? '';
    final lastName = detail?['lastName']?.toString() ?? '';
    final fullName = [firstName, lastName].where((s) => s.isNotEmpty).join(' ');

    final lawyerName = event['lawyerName']?.toString() ??
        (fullName.isNotEmpty ? fullName : null) ??
        detail?['name']?.toString() ??
        'ทนายความ';

    return {
      'code': lawyerCode,
      'name': lawyerName,
      'title': detail?['title']?.toString() ??
          detail?['specialization']?.toString() ??
          detail?['category']?.toString() ??
          'ทนายความ',
      'rateAverage': detail?['rateAverage'] ?? detail?['rating'] ?? '-',
      'experienceYears': detail?['experienceYears'] ?? detail?['experience'] ?? 'ไม่ระบุ', 
      'imageUrl': detail?['imageUrl']?.toString() ??
          detail?['imageUrlSocial']?.toString() ??
          '',
      'specialization': detail?['specialization']?.toString() ?? '',
      'provinceTitle': detail?['provinceTitle']?.toString() ?? '',
      'price': detail?['price'],
      'distanceKm': detail?['distanceKm'],
      '_distanceKm': detail?['_distanceKm'],
      'lastLat': detail?['lastLat'] ?? event['lat'],
      'lastLng': detail?['lastLng'] ?? detail?['lastLong'] ?? event['lng'],
    };
  }

  static Map<String, dynamic> jobFromCaseRequest(Map<String, dynamic> req) {
    final code = req['code']?.toString() ?? '';
    final lawyerCode =
        req['pendingLawyer']?.toString() ?? UserProfileStore.instance.code;
    final userName = req['userName']?.toString() ?? 'ลูกความ';
    final status = _requestStatus(req);

    return {
      'id': code,
      'caseCode': code,
      'lawyerCode': lawyerCode,
      'clientCode': req['userCode']?.toString() ?? '',
      'clientName': userName,
      'clientAvatar': userName.isNotEmpty ? userName[0] : 'ล',
      'clientColor': 0xFF0262EC,
      'topic': req['topicTitle']?.toString() ?? req['topic']?.toString() ?? '',
      'subTopic':
          req['subTopicTitle']?.toString() ?? req['subTopic']?.toString() ?? '',
      'detail': req['details']?.toString() ?? req['detail']?.toString() ?? '',
      'date': '',
      'time': '',
      'status': status == 3 ? 'accepted' : 'pending',
      'requestedAt': status == 3 ? 'รอชำระเงิน' : 'รอลูกความยืนยัน',
      'jobSource': 'urgent',
      'budget': '500',
      'isCaseRequest': true,
      'rawRequest': req,
    };
  }

  /// เรียกหลังทนายรับงานสำเร็จ (ทั้งฝั่ง lawyer และ client)
  Future<void> detachAfterMatch() async {
    // ลบ listeners ทั้งหมดก่อน แล้วค่อย stop
    _connection?.off('LawyerWantsToTakeCase');
    _connection?.off('CaseRequestExpired');
    _connection?.off('SearchingAgain');
    _connection?.off('ReceiveNewCaseRequest');
    _connection?.off('CaseRequestTaken');

    onLawyerWantsToTakeCase = null;
    onRequestExpired = null;
    onSearchingAgain = null;
    onNewCaseRequest = null;
    onCaseRequestTaken = null;

    _joinedUserCode = null;
    _joinedLawyerCode = null;

    await _connection?.stop();
    _connection = null;

    debugPrint('CaseRequestService: detached after match ✅');
  }
}
