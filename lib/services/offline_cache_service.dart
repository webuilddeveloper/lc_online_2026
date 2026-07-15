import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Cache เคสและ workspace สำหรับดูแบบ offline บางส่วน
class OfflineCacheService {
  OfflineCacheService._();

  static const _casesKey = 'offline_cases_cache';
  static const _workspacePrefix = 'offline_workspace_';

  static Future<void> cacheCases(List<Map<String, dynamic>> cases) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_casesKey, jsonEncode(cases));
  }

  static Future<List<Map<String, dynamic>>> loadCachedCases() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_casesKey);
    if (raw == null || raw.isEmpty) return [];
    try {
      final list = jsonDecode(raw) as List;
      return list
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> cacheWorkspace(
    String caseCode,
    Map<String, dynamic> data,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('$_workspacePrefix$caseCode', jsonEncode(data));
  }

  static Future<Map<String, dynamic>?> loadCachedWorkspace(String caseCode) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('$_workspacePrefix$caseCode');
    if (raw == null || raw.isEmpty) return null;
    try {
      return Map<String, dynamic>.from(jsonDecode(raw) as Map);
    } catch (_) {
      return null;
    }
  }
}
