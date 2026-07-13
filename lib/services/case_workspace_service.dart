import 'dart:convert';

import 'package:LawyerOnline/shared/api_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CaseDocument {
  final String name;
  final String url;
  final String uploadedAt;

  const CaseDocument({
    required this.name,
    required this.url,
    required this.uploadedAt,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'url': url,
        'uploadedAt': uploadedAt,
      };

  factory CaseDocument.fromJson(Map<String, dynamic> json) => CaseDocument(
        name: json['name']?.toString() ?? '',
        url: json['url']?.toString() ?? '',
        uploadedAt: json['uploadedAt']?.toString() ?? '',
      );
}

class CaseTimelineEvent {
  final String title;
  final String subtitle;
  final String at;

  const CaseTimelineEvent({
    required this.title,
    required this.subtitle,
    required this.at,
  });
}

class CaseWorkspaceData {
  final Map<String, dynamic> caseData;
  final String summary;
  final List<CaseDocument> documents;
  final List<CaseTimelineEvent> timeline;

  const CaseWorkspaceData({
    required this.caseData,
    required this.summary,
    required this.documents,
    required this.timeline,
  });
}

/// พื้นที่ทำงานต่อเคส — เอกสาร, timeline, สรุป
class CaseWorkspaceService {
  CaseWorkspaceService._();

  static String _cacheKey(String caseCode) => 'case_workspace_$caseCode';

  static Future<CaseWorkspaceData> load(String caseCode) async {
    final result = await postDio('${server}/m/case/read', {'code': caseCode});
    Map<String, dynamic> caseData = {};
    if (result['status'] == 'S' &&
        result['objectData'] is List &&
        (result['objectData'] as List).isNotEmpty) {
      caseData = Map<String, dynamic>.from(
        (result['objectData'] as List).first as Map,
      );
    }

    final cached = await _readCache(caseCode);
    final summary = caseData['consultSummary']?.toString().trim().isNotEmpty ==
            true
        ? caseData['consultSummary'].toString()
        : cached['summary']?.toString() ?? '';

    final docsRaw = caseData['caseDocuments'] ?? cached['documents'];
    final documents = _parseDocuments(docsRaw);
    final timeline = _buildTimeline(caseData);

    return CaseWorkspaceData(
      caseData: caseData,
      summary: summary,
      documents: documents,
      timeline: timeline,
    );
  }

  static Future<void> saveSummary({
    required String caseCode,
    required String summary,
    required String userType,
  }) async {
    await _mergeCache(caseCode, {'summary': summary});
    await postDio('${server}/m/case/update', {
      'code': caseCode,
      'consultSummary': summary,
    });
  }

  static Future<void> addDocument({
    required String caseCode,
    required String name,
    required String url,
  }) async {
    final cached = await _readCache(caseCode);
    final docs = _parseDocuments(cached['documents']);
    docs.add(CaseDocument(
      name: name,
      url: url,
      uploadedAt: DateTime.now().toIso8601String(),
    ));
    final encoded = jsonEncode(docs.map((d) => d.toJson()).toList());
    await _mergeCache(caseCode, {'documents': encoded});
    await postDio('${server}/m/case/update', {
      'code': caseCode,
      'caseDocuments': encoded,
    });
  }

  static List<CaseTimelineEvent> _buildTimeline(Map<String, dynamic> caseData) {
    final events = <CaseTimelineEvent>[];
    final status = int.tryParse(caseData['caseStatus']?.toString() ?? '') ?? 0;
    final created = caseData['createDate']?.toString() ?? '';
    final date = caseData['caseDate']?.toString() ?? '';
    final isPay = caseData['isPay'] == true || caseData['isPay'] == 1;

    events.add(CaseTimelineEvent(
      title: 'เปิดเคส',
      subtitle: caseData['subTopicTitle']?.toString() ??
          caseData['topicTitle']?.toString() ??
          '-',
      at: created.isNotEmpty ? created : '-',
    ));

    if (isPay) {
      events.add(const CaseTimelineEvent(
        title: 'ชำระเงินแล้ว',
        subtitle: 'ยืนยันการชำระเงิน',
        at: '-',
      ));
    }

    if (status >= 2) {
      events.add(CaseTimelineEvent(
        title: 'ทนายรับเคส',
        subtitle: caseData['lawyerName']?.toString() ?? 'ทนายความ',
        at: date.isNotEmpty ? date : '-',
      ));
    }

    if (status >= 3) {
      events.add(const CaseTimelineEvent(
        title: 'กำลังปรึกษา',
        subtitle: 'เริ่มให้คำปรึกษา',
        at: '-',
      ));
    }

    if (status >= 4) {
      events.add(const CaseTimelineEvent(
        title: 'เสร็จสิ้น',
        subtitle: 'ปิดเคสแล้ว',
        at: '-',
      ));
    }

    if (caseData['isReview'] == true) {
      events.add(const CaseTimelineEvent(
        title: 'รีวิวแล้ว',
        subtitle: 'ลูกความให้คะแนนแล้ว',
        at: '-',
      ));
    }

    return events;
  }

  static List<CaseDocument> _parseDocuments(dynamic raw) {
    if (raw == null) return [];
    if (raw is List) {
      return raw
          .whereType<Map>()
          .map((e) => CaseDocument.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    }
    if (raw is String && raw.trim().isNotEmpty) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is List) {
          return decoded
              .whereType<Map>()
              .map((e) => CaseDocument.fromJson(Map<String, dynamic>.from(e)))
              .toList();
        }
      } catch (_) {}
    }
    return [];
  }

  static Future<Map<String, dynamic>> _readCache(String caseCode) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_cacheKey(caseCode));
    if (raw == null || raw.isEmpty) return {};
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map) return Map<String, dynamic>.from(decoded);
    } catch (_) {}
    return {};
  }

  static Future<void> _mergeCache(
    String caseCode,
    Map<String, dynamic> patch,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final current = await _readCache(caseCode);
    current.addAll(patch);
    await prefs.setString(_cacheKey(caseCode), jsonEncode(current));
  }
}
