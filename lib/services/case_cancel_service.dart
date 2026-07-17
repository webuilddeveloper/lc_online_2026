import 'package:LawyerOnline/shared/api_provider.dart';

class CaseCancelService {
  /// ขอยกเลิกตอนกำลังปรึกษา (caseStatus=3) — รอแอดมินตรวจเหตุผล
  static Future<Map<String, dynamic>> requestCancel({
    required String caseCode,
    required String reasonCancel,
    required String requesterCode,
    required String userType,
  }) async {
    final res = await postDio('$server/m/case/cancel/request', {
      'code': caseCode,
      'reasonCancel': reasonCancel,
      'updateBy': requesterCode,
      'cancelRequestedBy': requesterCode,
      'userType': userType,
    });
    if (res == null) {
      return {'status': 'E', 'message': 'ไม่สามารถเชื่อมต่อเซิร์ฟเวอร์ได้'};
    }
    if (res is Map<String, dynamic>) return res;
    return Map<String, dynamic>.from(res as Map);
  }
}
