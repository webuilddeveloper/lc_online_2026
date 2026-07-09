import 'package:LawyerOnline/shared/api_provider.dart';

class UrgentCaseService {
  static Future<Map<String, dynamic>?> updateSettings({
    required String code,
    bool? isAllowCase,
    String? urgentCaseScope,
  }) async {
    final body = <String, dynamic>{'code': code};
    if (isAllowCase != null) body['isAllowCase'] = isAllowCase;
    if (urgentCaseScope != null) body['urgentCaseScope'] = urgentCaseScope;

    final res = await postDio('$server/m/register/urgentCase/settings', body);
    if (res == null || res['status'] != 'S') return null;
    final data = res['objectData'];
    if (data is Map) return Map<String, dynamic>.from(data);
    return null;
  }
}
