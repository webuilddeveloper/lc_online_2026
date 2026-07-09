import 'dart:convert';
import 'package:LawyerOnline/models/auth_session.dart';
import 'package:LawyerOnline/shared/api_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:LawyerOnline/models/user_model.dart';

/// อีเมลซ้ำ — server ส่งกลับมา
class EmailDuplicateException implements Exception {
  final String message;
  EmailDuplicateException([this.message = 'Email already exists']);
  @override
  String toString() => message;
}

/// เบอร์โทรซ้ำ — server ส่งกลับมา
class PhoneDuplicateException implements Exception {
  final String message;
  PhoneDuplicateException([this.message = 'Phone already exists']);
  @override
  String toString() => message;
}

/// รหัสผ่านไม่ถูกต้อง — server ส่งกลับมา
class PasswordIncorrectException implements Exception {
  final String message;
  PasswordIncorrectException([this.message = 'Password incorrect']);
  @override
  String toString() => message;
}

class AuthService {
  static const String _loginUrl = '$server/m/register/login';
  static const String _registerUrl = '$server/m/register/create';
  static const String _cancelUrl = '$server/m/register/cancel';
  static const String _changePasswordUrl = '$server/m/register/change';
  static const String _updateProfileUrl = '$server/m/register/update';
  static const String _applyLawyerUrl = '$server/m/register/applyLawyer';
  static const String _createCaseUrl = '$server/m/case/create';

  static const Map<String, String> _headers = {
    'Accept': 'application/json',
    'Content-Type': 'application/json',
  };

  static Future<UserModel> login(
    String email,
    String password,
    String category,
  ) async {
    final session = await loginSession(email, password, category);
    return session.user;
  }

  static Future<AuthSession> loginSession(
    String email,
    String password,
    String category,
  ) async {
    try {
      final body = json.encode({
        'email': email,
        'password': password,
        'category': category,
      });

      debugPrint('[AuthService.login] url=$_loginUrl');
      debugPrint('[AuthService.login] body=$body');

      final response = await http.post(
        Uri.parse(_loginUrl),
        body: body,
        headers: _headers,
      );

      debugPrint(
          '[AuthService.login] status=${response.statusCode} body=${response.body}');

      if (response.statusCode != 200) {
        throw Exception('Server error ${response.statusCode}');
      }

      final data = json.decode(response.body);
      if (data['status'] != 'S') {
        throw Exception(data['message']?.toString() ?? 'Login failed');
      }

      final objectData = data['objectData'];
      if (objectData == null || objectData is! Map<String, dynamic>) {
        throw Exception('Invalid login response');
      }

      debugPrint('[AuthService.login] success for email=$email');
      return AuthSession(
        user: UserModel.fromJson(objectData),
        token: data['jsonData']?.toString() ?? '',
      );
    } catch (e) {
      debugPrint('[AuthService.login] error: $e');
      rethrow;
    }
  }

  static Future<dynamic> register({
    required String firstName,
    required String lastName,
    required String userType,
    required String phone,
    required String email,
    required String password,
    required String confirmPassword,
    String imageUrl = '',
    String category = 'guest',
    List<String> expertiseList = const [],
    String idCard = '',
    String lawyerNo = '',
    String provinceCode = '',
    String provinceTitle = ''
  }) async {
    try {
      final body = json.encode({
        'userType': userType,
        'firstName': firstName,
        'lastName': lastName,
        'imageUrl': imageUrl,
        'phone': phone,
        'email': email,
        'password': password,
        'confirmPassword': confirmPassword,
        'category': category,
        'expertiseList': expertiseList,
        'idcard': idCard,
        'lawyerNo': lawyerNo,
        'provinceCode': provinceCode,
        'province': provinceTitle

      });

      debugPrint('[AuthService.register] url=$_registerUrl');
      debugPrint('[AuthService.register] body=$body');

      final response = await http.post(
        Uri.parse(_registerUrl),
        body: body,
        headers: _headers,
      );

      debugPrint(
          '[AuthService.register] status=${response.statusCode} body=${response.body}');

      if (response.statusCode != 200) {
        throw Exception('Server error ${response.statusCode}');
      }

      final data = json.decode(response.body);
      print('=-=-=-=-==-=-=-=-=-= ${data}');
      if (data['status'] != 'S') {
        
        final rawMsg = data['message']?.toString() ?? '';
        final msg = rawMsg.toLowerCase();
        if (msg.contains('email')) {
          throw EmailDuplicateException(
              rawMsg.isNotEmpty ? rawMsg : 'Email already exists');
        } else if (msg.contains('phone') || msg.contains('เบอร์')) {
          throw PhoneDuplicateException(
              rawMsg.isNotEmpty ? rawMsg : 'Phone already exists');
        }
        throw Exception(rawMsg.isNotEmpty ? rawMsg : 'Registration failed');
      }

      final objectData = data['objectData'];
      if (objectData == null || objectData is! Map<String, dynamic>) {
        throw Exception('Invalid registration response');
      }

      debugPrint('[AuthService.register] success for email=$email');
      return UserModel.fromJson(objectData);
    } on EmailDuplicateException {
      rethrow;
    } on PhoneDuplicateException {
      rethrow;
    } catch (e) {
      debugPrint('[AuthService.register] error: $e');
      rethrow;
    }
  }

  static Future<void> cancelAccount({
    required String email,
    required String code,
    required String reasonCancel,
    String? password,
  }) async {
    try {
      final Map<String, dynamic> bodyMap = {
        'email': email,
        'code': code,
        'reasonCancel': reasonCancel,
      };

      if (password != null && password.isNotEmpty) {
        bodyMap['password'] = password;
      }

      final body = json.encode(bodyMap);

      debugPrint('[AuthService.cancelAccount] url=$_cancelUrl');
      debugPrint('[AuthService.cancelAccount] body=$body');

      final response = await http.post(
        Uri.parse(_cancelUrl),
        body: body,
        headers: _headers,
      );

      debugPrint(
          '[AuthService.cancelAccount] status=${response.statusCode} body=${response.body}');

      if (response.statusCode != 200) {
        throw Exception('Server error ${response.statusCode}');
      }

      final data = json.decode(response.body);
      if (data['status'] != 'S') {
        throw Exception(data['message']?.toString() ?? 'Cancel account failed');
      }

      debugPrint('[AuthService.cancelAccount] success for email=$email');
    } catch (e) {
      debugPrint('[AuthService.cancelAccount] error: $e');
      rethrow;
    }
  }

  /// เปลี่ยนรหัสผ่าน
  static Future<void> changePassword({
    required String code,
    required String password,
    required String newPassword,
  }) async {
    try {
      final body = json.encode({
        'code': code,
        'password': password,
        'newPassword': newPassword,
      });

      debugPrint('[AuthService.changePassword] url=$_changePasswordUrl');
      debugPrint('[AuthService.changePassword] body=$body');

      final response = await http.post(
        Uri.parse(_changePasswordUrl),
        body: body,
        headers: _headers,
      );

      debugPrint(
          '[AuthService.changePassword] status=${response.statusCode} body=${response.body}');

      if (response.statusCode != 200) {
        throw Exception('Server error ${response.statusCode}');
      }

      final data = json.decode(response.body);
      if (data['status'] != 'S') {
        throw Exception(
            data['message']?.toString() ?? 'Change password failed');
      }

      debugPrint('[AuthService.changePassword] success for code=$code');
    } catch (e) {
      debugPrint('[AuthService.changePassword] error: $e');
      rethrow;
    }
  }

  /// อัปเดตโปรไฟล์ — คืนค่า user ล่าสุดจาก API (ถ้ามี)
  static Future<UserModel?> updateProfile({
    required String code,
    required String email,
    required String firstName,
    required String lastName,
    required String phone,
    String imageUrl = '',
    String userType = 'user',
    String? password,
    String prefixName = '',
    String title = '',
    String description = '',
    List<String>? expertiseList,
    String province = '',
    String provinceCode = '',
    double? experienceYears,
    String? isAvailable,
    bool? isAllowCase,
    String facebookID = '',
    String lv0 = '',
    String lv1 = '',
    String lv2 = '',
    String lv3 = '',
  }) async {
    try {
      final Map<String, dynamic> bodyMap = {
        'code': code,
        'updateBy': code,
        'email': email,
        'firstName': firstName,
        'lastName': lastName,
        'phone': phone,
        'imageUrl': imageUrl,
        'userType': userType,
        'prefixName': prefixName,
        'title': title,
        'description': description,
        'province': province,
        'provinceCode': provinceCode,
        'facebookID': facebookID,
        'lv0': lv0,
        'lv1': lv1,
        'lv2': lv2,
        'lv3': lv3,
      };
      if (password != null && password.isNotEmpty) {
        bodyMap['password'] = password;
      }
      if (expertiseList != null) {
        bodyMap['expertiseList'] = expertiseList;
      }
      if (experienceYears != null) {
        bodyMap['experienceYears'] = experienceYears;
      }
      if (isAvailable != null) {
        bodyMap['isAvailable'] = isAvailable;
      }
      if (isAllowCase != null) {
        bodyMap['isAllowCase'] = isAllowCase;
      }
      final body = json.encode(bodyMap);

      debugPrint('[AuthService.updateProfile] url=$_updateProfileUrl');
      debugPrint('[AuthService.updateProfile] body=$body');

      final response = await http.post(
        Uri.parse(_updateProfileUrl),
        body: body,
        headers: _headers,
      );

      debugPrint(
          '[AuthService.updateProfile] status=${response.statusCode} body=${response.body}');

      if (response.statusCode != 200) {
        throw Exception('Server error ${response.statusCode}');
      }

      final data = json.decode(response.body);
      if (data['status'] != 'S') {
        final rawMsg = data['message']?.toString() ?? '';
        final msg = rawMsg.toLowerCase();
        if (msg.contains('email')) {
          throw EmailDuplicateException(
              rawMsg.isNotEmpty ? rawMsg : 'Email already exists');
        } else if (msg.contains('phone') || msg.contains('เบอร์')) {
          throw PhoneDuplicateException(
              rawMsg.isNotEmpty ? rawMsg : 'Phone already exists');
        } else if (msg.contains('password') || msg.contains('รหัสผ่าน')) {
          throw PasswordIncorrectException(
              rawMsg.isNotEmpty ? rawMsg : 'รหัสผ่านไม่ถูกต้อง');
        }
        throw Exception(rawMsg.isNotEmpty ? rawMsg : 'Update profile failed');
      }

      debugPrint('[AuthService.updateProfile] success for code=$code');

      final objectData = data['objectData'];
      if (objectData is Map<String, dynamic>) {
        return UserModel.fromJson(objectData);
      }
      if (objectData is Map) {
        return UserModel.fromJson(Map<String, dynamic>.from(objectData));
      }
      return null;
    } on EmailDuplicateException {
      rethrow;
    } on PhoneDuplicateException {
      rethrow;
    } on PasswordIncorrectException {
      rethrow;
    } catch (e) {
      debugPrint('[AuthService.updateProfile] error: $e');
      rethrow;
    }
  }

  /// ส่งคำขอสมัครเป็นทนายความ (รอเจ้าหน้าที่อนุมัติ)
  static Future<void> applyLawyer({
    required String code,
    required String email,
    required String firstName,
    required String lastName,
    required String phone,
    required String lawyerNo,
    required List<String> expertiseList,
    required String provinceCode,
    required String provinceTitle,
    required List<String> documentList,
  }) async {
    try {
      final body = json.encode({
        'code': code,
        'email': email,
        'firstName': firstName,
        'lastName': lastName,
        'phone': phone,
        'lawyerNo': lawyerNo,
        'expertiseList': expertiseList,
        'provinceCode': provinceCode,
        'province': provinceTitle,
        'documentList': documentList,
      });

      debugPrint('[AuthService.applyLawyer] url=$_applyLawyerUrl');
      debugPrint('[AuthService.applyLawyer] body=$body');

      final response = await http.post(
        Uri.parse(_applyLawyerUrl),
        body: body,
        headers: _headers,
      );

      debugPrint(
          '[AuthService.applyLawyer] status=${response.statusCode} body=${response.body}');

      if (response.statusCode != 200) {
        throw Exception('Server error ${response.statusCode}');
      }

      final data = json.decode(response.body);
      if (data['status'] != 'S') {
        final rawMsg = data['message']?.toString() ?? '';
        throw Exception(rawMsg.isNotEmpty ? rawMsg : 'Lawyer application failed');
      }

      debugPrint('[AuthService.applyLawyer] success for code=$code');
    } catch (e) {
      debugPrint('[AuthService.applyLawyer] error: $e');
      rethrow;
    }
  }
//api case
  static Future<void> createCase(Map<String, dynamic> requestBody) async {
    try {
      final body = json.encode(requestBody);

      debugPrint('[AuthService.createCase] url=$_createCaseUrl');
      debugPrint('[AuthService.createCase] body=$body');

      final response = await http.post(
        Uri.parse(_createCaseUrl),
        body: body,
        headers: _headers,
      );

      debugPrint(
          '[AuthService.createCase] status=${response.statusCode} body=${response.body}');

      if (response.statusCode != 200) {
        throw Exception('Server error ${response.statusCode}');
      }

      final data = json.decode(response.body);
      if (data['status'] != 'S') {
        throw Exception(data['message']?.toString() ?? 'Create case failed');
      }

      debugPrint('[AuthService.createCase] success');
      return;
    } catch (e) {
      debugPrint('[AuthService.createCase] error: $e');
      rethrow;
    }
  }
}
