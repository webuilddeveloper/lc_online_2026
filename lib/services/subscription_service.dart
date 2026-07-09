import 'package:LawyerOnline/shared/api_provider.dart';

class SubscriptionService {
  static Future<Map<String, dynamic>?> upgradePro({
    required String code,
    required String billingCycle,
  }) async {
    final res = await postDio('$server/m/register/pro/upgrade', {
      'code': code,
      'proBillingCycle': billingCycle,
    });
    if (res == null || res['status'] != 'S') return null;
    final data = res['objectData'];
    if (data is Map) return Map<String, dynamic>.from(data);
    return null;
  }

  static Future<Map<String, dynamic>?> cancelPro({
    required String code,
  }) async {
    final res = await postDio('$server/m/register/pro/cancel', {
      'code': code,
    });
    if (res == null || res['status'] != 'S') return null;
    final data = res['objectData'];
    if (data is Map) return Map<String, dynamic>.from(data);
    return null;
  }
}
