import 'package:LawyerOnline/shared/api_provider.dart';

class ConsultationSummaryService {
  ConsultationSummaryService._();

  static Future<String?> generate(String caseCode, {String updateBy = ''}) async {
    final result = await postDio('${server}/m/case/summary/generate', {
      'code': caseCode,
      'updateBy': updateBy,
    });
    if (result['status'] != 'S') return null;
    return result['objectData']?['aiConsultSummary']?.toString();
  }
}
