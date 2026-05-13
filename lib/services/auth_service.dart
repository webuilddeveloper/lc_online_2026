import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:LawyerOnline/models/user_model.dart';

class AuthService {
  static const String _baseUrl =
      'https://b7d2-125-25-100-59.ngrok-free.app';
  static const String _loginUrl = '$_baseUrl/m/register/login';
  static const String _registerUrl = '$_baseUrl/m/register/create';
  static const String _cancelUrl = '$_baseUrl/m/register/cancel';
  static const String _changePasswordUrl = '$_baseUrl/m/register/change';
  static const String _updateProfileUrl = '$_baseUrl/m/register/update';

  static const Duration _timeout = Duration(seconds: 15);

  static const Map<String, String> _headers = {
    'Accept': 'application/json',
    'Content-Type': 'application/json',
  };

  static Future<UserModel> login(
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
      ).timeout(
        _timeout,
        onTimeout: () => throw Exception('หมดเวลาเชื่อมต่อ กรุณาลองใหม่อีกครั้ง'),
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
      return UserModel.fromJson(objectData);
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
      ).timeout(
        _timeout,
        onTimeout: () => throw Exception('หมดเวลาเชื่อมต่อ กรุณาลองใหม่อีกครั้ง'),
      );

      debugPrint(
          '[AuthService.register] status=${response.statusCode} body=${response.body}');

      if (response.statusCode != 200) {
        throw Exception('Server error ${response.statusCode}');
      }

      final data = json.decode(response.body);
      if (data['status'] != 'S') {
        final message = data['message']?.toString() ?? 'Registration failed';

        debugPrint('[AuthService.register] server message: $message');

        final msg = message.toLowerCase();
        final isEmailDuplicate = msg.contains('email') ||
            msg.contains('อีเมล') ||
            msg.contains('already') ||
            msg.contains('exist') ||
            msg.contains('duplicate') ||
            msg.contains('ซ้ำ') ||
            msg.contains('มีผู้ใช้') ||
            msg.contains('ถูกใช้');
        final isPhoneDuplicate = msg.contains('phone') ||
            msg.contains('เบอร์') ||
            msg.contains('โทร') ||
            msg.contains('mobile');

        if (isEmailDuplicate) {
          throw EmailDuplicateException(message);
        }
        if (isPhoneDuplicate) {
          throw PhoneDuplicateException(message);
        }

        throw Exception(message);
      }

      final objectData = data['objectData'];
      if (objectData == null || objectData is! Map<String, dynamic>) {
        throw Exception('Invalid registration response');
      }

      debugPrint('[AuthService.register] success for email=$email');
      return UserModel.fromJson(objectData);
    } catch (e) {
      debugPrint('[AuthService.register] error: $e');
      rethrow;
    }
  }

  static Future<void> cancelAccount({
    required String email,
    required String code,
    required String reesonCancel,
  }) async {
    try {
      final body = json.encode({
        'email': email,
        'code': code,
        'reesonCancel': reesonCancel,
      });

      debugPrint('[AuthService.cancelAccount] url=$_cancelUrl');
      debugPrint('[AuthService.cancelAccount] body=$body');

      final response = await http.post(
        Uri.parse(_cancelUrl),
        body: body,
        headers: _headers,
      ).timeout(
        _timeout,
        onTimeout: () => throw Exception('หมดเวลาเชื่อมต่อ กรุณาลองใหม่อีกครั้ง'),
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
      ).timeout(
        _timeout,
        onTimeout: () => throw Exception('หมดเวลาเชื่อมต่อ กรุณาลองใหม่อีกครั้ง'),
      );

      debugPrint(
          '[AuthService.changePassword] status=${response.statusCode} body=${response.body}');

      if (response.statusCode != 200) {
        throw Exception('Server error ${response.statusCode}');
      }

      final data = json.decode(response.body);
      if (data['status'] != 'S') {
        throw Exception(data['message']?.toString() ?? 'Change password failed');
      }

      debugPrint('[AuthService.changePassword] success for code=$code');
    } catch (e) {
      debugPrint('[AuthService.changePassword] error: $e');
      rethrow;
    }
  }

  // ── updateProfile ──────────────────────────────────────────────────────────
  // throw EmailDuplicateException เมื่อ server แจ้งว่า email ซ้ำ
  // ทำให้ profile-form ไม่ต้อง guess keyword จาก message string
  static Future<void> updateProfile({
    required String code,
    required String email,
    required String firstName,
    String lastName = '',
    String phone = '',
    String imageUrl = '',
    String userType = '',
  }) async {
    try {
      final body = json.encode({
        'code': code,
        'email': email,
        'firstName': firstName,
        'lastName': lastName,
        'phone': phone,
        'imageUrl': imageUrl,
        'userType': userType,
      });

      debugPrint('[AuthService.updateProfile] url=$_updateProfileUrl');
      debugPrint('[AuthService.updateProfile] body=$body');

      final response = await http.post(
        Uri.parse(_updateProfileUrl),
        body: body,
        headers: _headers,
      ).timeout(
        _timeout,
        onTimeout: () => throw Exception('หมดเวลาเชื่อมต่อ กรุณาลองใหม่อีกครั้ง'),
      );

      debugPrint(
          '[AuthService.updateProfile] status=${response.statusCode} body=${response.body}');

      if (response.statusCode != 200) {
        throw Exception('Server error ${response.statusCode}');
      }

      final data = json.decode(response.body);
      if (data['status'] != 'S') {
        final message = data['message']?.toString() ?? 'Update profile failed';

        debugPrint('[AuthService.updateProfile] server message: $message');

        final msg = message.toLowerCase();
        final isEmailDuplicate = msg.contains('email') ||
            msg.contains('อีเมล') ||
            msg.contains('already') ||
            msg.contains('exist') ||
            msg.contains('duplicate') ||
            msg.contains('ซ้ำ') ||
            msg.contains('มีผู้ใช้') ||
            msg.contains('ถูกใช้');
        final isPhoneDuplicate = msg.contains('phone') ||
            msg.contains('เบอร์') ||
            msg.contains('โทร') ||
            msg.contains('mobile');

        if (isEmailDuplicate) {
          throw EmailDuplicateException(message);
        }
        if (isPhoneDuplicate) {
          throw PhoneDuplicateException(message);
        }

        throw Exception(message);
      }

      debugPrint('[AuthService.updateProfile] success for code=$code');
    } catch (e) {
      debugPrint('[AuthService.updateProfile] error: $e');
      rethrow;
    }
  }
}

// ── Custom Exceptions ─────────────────────────────────────────────────────────
class EmailDuplicateException implements Exception {
  final String message;
  const EmailDuplicateException(this.message);
  @override
  String toString() => message;
}

class PhoneDuplicateException implements Exception {
  final String message;
  const PhoneDuplicateException(this.message);
  @override
  String toString() => message;
}