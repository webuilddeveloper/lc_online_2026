import 'dart:convert';

import 'package:LawyerOnline/models/user_model.dart';
import 'package:LawyerOnline/models/user_profile_store.dart';
import 'package:LawyerOnline/shared/api_provider.dart';
import 'package:http/http.dart' as http;

abstract class RegisterAccountRepository {
  Future<List<UserModel>> readAccounts({
    String userType = '',
    String code = '',
    String keySearch = '',
    int skip = 0,
    int limit = 100,
  });
}

class RegisterAccountRepositoryException implements Exception {
  const RegisterAccountRepositoryException(this.message);

  final String message;

  @override
  String toString() => 'RegisterAccountRepositoryException: $message';
}

class ApiRegisterAccountRepository implements RegisterAccountRepository {
  const ApiRegisterAccountRepository({
    http.Client? client,
    String baseUrl = server,
  })  : _client = client,
        _baseUrl = baseUrl;

  final http.Client? _client;
  final String _baseUrl;

  @override
  Future<List<UserModel>> readAccounts({
    String userType = '',
    String code = '',
    String keySearch = '',
    int skip = 0,
    int limit = 100,
  }) async {
    final client = _client ?? http.Client();
    final closeClient = _client == null;

    try {
      final token = UserProfileStore.instance.token;
      final headers = <String, String>{
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        if (token.isNotEmpty) 'Authorization': 'Bearer $token',
      };

      final response = await client.post(
        Uri.parse('$_baseUrl/m/register/read'),
        headers: headers,
        body: jsonEncode({
          'userType': userType,
          'code': code,
          'keySearch': keySearch,
          'skip': skip,
          'limit': limit,
        }),
      );

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw RegisterAccountRepositoryException(
          'Register read failed with HTTP ${response.statusCode}',
        );
      }

      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) {
        throw const RegisterAccountRepositoryException(
          'Register read response is not an object',
        );
      }

      final status = decoded['status']?.toString() ?? '';
      if (status != 'S') {
        final message = decoded['message']?.toString();
        throw RegisterAccountRepositoryException(
          message?.isNotEmpty == true
              ? message!
              : 'Register read returned status $status',
        );
      }

      final objectData = decoded['objectData'];
      if (objectData == null) {
        return const [];
      }

      if (objectData is List) {
        return objectData.map(_parseAccount).toList(growable: false);
      }

      if (objectData is Map<String, dynamic>) {
        final nestedList =
            objectData['items'] ?? objectData['data'] ?? objectData['list'];
        if (nestedList is List) {
          return nestedList.map(_parseAccount).toList(growable: false);
        }
        return [UserModel.fromJson(objectData)];
      }

      throw const RegisterAccountRepositoryException(
        'Register read objectData has unsupported shape',
      );
    } on FormatException catch (error) {
      throw RegisterAccountRepositoryException(
        'Register read response is not valid JSON: ${error.message}',
      );
    } finally {
      if (closeClient) {
        client.close();
      }
    }
  }

  UserModel _parseAccount(Object? value) {
    if (value is Map<String, dynamic>) {
      return UserModel.fromJson(value);
    }
    if (value is Map) {
      return UserModel.fromJson(Map<String, dynamic>.from(value));
    }
    throw const RegisterAccountRepositoryException(
      'Register read item is not an object',
    );
  }
}
