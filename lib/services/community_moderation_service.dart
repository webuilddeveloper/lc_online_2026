import 'package:LawyerOnline/shared/api_provider.dart';

class CommunityModerationService {
  CommunityModerationService._();

  static Future<bool> report({
    required String targetCode,
    required String reporterCode,
    String targetType = 'post',
    required String reason,
    String detail = '',
  }) async {
    final result = await postDio('${server}/m/community/report', {
      'targetCode': targetCode,
      'targetType': targetType,
      'reporterCode': reporterCode,
      'reason': reason,
      'detail': detail,
    });
    return result['status'] == 'S';
  }
}
