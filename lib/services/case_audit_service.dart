import 'package:LawyerOnline/shared/api_provider.dart';

class CaseAuditEvent {
  const CaseAuditEvent({
    required this.action,
    required this.actorCode,
    required this.actorName,
    required this.detail,
    required this.at,
  });

  final String action;
  final String actorCode;
  final String actorName;
  final String detail;
  final String at;

  factory CaseAuditEvent.fromJson(Map<String, dynamic> json) => CaseAuditEvent(
        action: json['action']?.toString() ?? '',
        actorCode: json['actorCode']?.toString() ?? '',
        actorName: json['actorName']?.toString() ?? '',
        detail: json['detail']?.toString() ?? '',
        at: '${json['createDate'] ?? ''} ${json['createTime'] ?? ''}'.trim(),
      );
}

class CaseAuditService {
  CaseAuditService._();

  static Future<List<CaseAuditEvent>> load(String caseCode) async {
    final result = await postDio('${server}/m/case/timeline/read', {
      'code': caseCode,
    });
    if (result['status'] != 'S' || result['objectData'] is! List) return [];
    return (result['objectData'] as List)
        .map((e) => CaseAuditEvent.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }
}
