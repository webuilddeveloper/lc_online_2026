import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:LawyerOnline/models/user_model.dart';

class AuthService {
  static const String _baseUrl =
      'https://b7d2-125-25-100-59.ngrok-free.app';
  static const String _loginUrl = '$_baseUrl/m/register/login';
  static const String _registerUrl = '$_baseUrl/m/register/create';

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
      );

      debugPrint(
          '[AuthService.register] status=${response.statusCode} body=${response.body}');

      if (response.statusCode != 200) {
        throw Exception('Server error ${response.statusCode}');
      }

      final data = json.decode(response.body);
      if (data['status'] != 'S') {
        throw Exception(data['message']?.toString() ?? 'Registration failed');
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
}
