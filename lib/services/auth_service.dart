import 'dart:convert';
import 'package:LawyerOnline/core/config/api_config.dart';
import 'package:LawyerOnline/models/auth_session.dart';
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
  static const String _baseUrl = ApiConfig.authBaseUrl;
  static const String _loginUrl = '$_baseUrl/m/register/login';
  static const String _registerUrl = '$_baseUrl/m/register/create';
  static const String _cancelUrl = '$_baseUrl/m/register/cancel';
  static const String _changePasswordUrl = '$_baseUrl/m/register/change';
  static const String _updateProfileUrl = '$_baseUrl/m/register/update';

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

  static Future<UserModel> register({
    required String firstName,
    required String lastName,
    required String userType,
    required String phone,
    required String email,
    required String password,
    required String confirmPassword,
    String imageUrl = '',
    String category = 'guest',
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
    required String reesonCancel,
    String? password,
  }) async {
    try {
      final Map<String, dynamic> bodyMap = {
        'email': email,
        'code': code,
        'reesonCancel': reesonCancel,
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

  /// อัปเดตโปรไฟล์
  static Future<void> updateProfile({
    required String code,
    required String email,
    required String firstName,
    required String lastName,
    required String phone,
    String imageUrl = '',
    String userType = 'user',
    String? password,
  }) async {
    try {
      final Map<String, dynamic> bodyMap = {
        'code': code,
        'email': email,
        'firstName': firstName,
        'lastName': lastName,
        'phone': phone,
        'imageUrl': imageUrl,
        'userType': userType,
      };
      if (password != null && password.isNotEmpty) {
        bodyMap['password'] = password;
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
}
