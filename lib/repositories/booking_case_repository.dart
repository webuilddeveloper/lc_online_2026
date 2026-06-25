import 'dart:convert';

import 'package:LawyerOnline/models/user_profile_store.dart';
import 'package:LawyerOnline/shared/api_provider.dart';
import 'package:http/http.dart' as http;

class BookingCaseRepositoryException implements Exception {
  const BookingCaseRepositoryException(this.message);

  final String message;

  @override
  String toString() => message;
}

class BookingCaseDraft {
  const BookingCaseDraft({
    required this.clientCode,
    required this.clientName,
    required this.lawyerCode,
    required this.lawyerName,
    required this.topicTitle,
    required this.subTopicTitle,
    required this.caseDate,
    required this.startTime,
    required this.endTime,
    this.topicCode = '',
    this.subTopicCode = '',
    this.serviceType = 'video',
    this.price = '',
    this.caseType = 1,
    this.provinceCode = '',
    this.provinceTitle = '',
    this.details = '',
    this.requirement = '',
    this.imageUrlList = const [],
  });

  final String clientCode;
  final String clientName;
  final String lawyerCode;
  final String lawyerName;
  final String topicCode;
  final String topicTitle;
  final String subTopicCode;
  final String subTopicTitle;
  final String caseDate;
  final String startTime;
  final String endTime;
  final String serviceType;
  final String price;
  final int caseType;
  final String provinceCode;
  final String provinceTitle;
  final String details;
  final String requirement;
  final List<String> imageUrlList;

  Map<String, dynamic> toJson() {
    final hour = _durationHour(startTime, endTime);
    return {
      'clientCode': clientCode,
      'clientName': clientName,
      'lawyerCode': lawyerCode,
      'lawyerName': lawyerName,
      'topicCode': topicCode,
      'topicTitle': topicTitle,
      'subTopicCode': subTopicCode,
      'subTopicTitle': subTopicTitle,
      'caseDate': caseDate,
      'startTime': startTime,
      'endTime': endTime,
      'hour': hour,
      'serviceType': serviceType,
      'price': price,
      'isPay': true,
      'payType': '',
      'payDate': '',
      'caseStatus': 1,
      'messageRef': '',
      'caseType': caseType,
      'provinceCode': provinceCode,
      'provinceTitle': provinceTitle,
      'details': details,
      'requirement': requirement,
      'reasonCancel': '',
      'imageUrlList': imageUrlList,
    };
  }

  static String _durationHour(String start, String end) {
    final startParts = start.split(':');
    final endParts = end.split(':');
    if (startParts.length < 2 || endParts.length < 2) return '';
    final startHour = int.tryParse(startParts[0]);
    final endHour = int.tryParse(endParts[0]);
    if (startHour == null || endHour == null || endHour <= startHour) {
      return '';
    }
    return (endHour - startHour).toString();
  }
}

abstract class BookingCaseRepository {
  Future<Map<String, dynamic>> createCase(BookingCaseDraft draft);

  Future<List<Map<String, dynamic>>> readCases({
    String code = '',
    String keySearch = '',
    String clientCode = '',
    String lawyerCode = '',
  });

  Future<Map<String, dynamic>> updateCase(Map<String, dynamic> payload);
}

class ApiBookingCaseRepository implements BookingCaseRepository {
  const ApiBookingCaseRepository({http.Client? client}) : _client = client;

  final http.Client? _client;

  @override
  Future<Map<String, dynamic>> createCase(BookingCaseDraft draft) {
    return _post('$server/m/case/create', draft.toJson());
  }

  @override
  Future<List<Map<String, dynamic>>> readCases({
    String code = '',
    String keySearch = '',
    String clientCode = '',
    String lawyerCode = '',
  }) async {
    final response = await _post('$server/m/case/read', {
      'code': code,
      'keySearch': keySearch,
      'userCode': clientCode,
      'lawyer': lawyerCode,
    });
    final objectData = response['objectData'];
    if (objectData is! List) return const [];
    return objectData
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  @override
  Future<Map<String, dynamic>> updateCase(Map<String, dynamic> payload) {
    return _post('$server/m/case/update', payload);
  }

  Future<Map<String, dynamic>> _post(
    String url,
    Map<String, dynamic> payload,
  ) async {
    final client = _client ?? http.Client();
    final response = await client.post(
      Uri.parse(url),
      headers: _headers(),
      body: jsonEncode(payload),
    );

    if (response.statusCode != 200) {
      throw BookingCaseRepositoryException(
        'Case API failed with status ${response.statusCode}',
      );
    }

    final data = jsonDecode(response.body);
    if (data is! Map<String, dynamic>) {
      throw const BookingCaseRepositoryException('Invalid case API response');
    }
    if (data['status'] != 'S') {
      throw BookingCaseRepositoryException(
        data['message']?.toString() ?? 'Case API request failed',
      );
    }
    return data;
  }

  Map<String, String> _headers() {
    final token = UserProfileStore.instance.token.trim();
    return {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
      if (token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }
}
