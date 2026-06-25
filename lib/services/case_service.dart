// lib/services/case_service.dart
import 'package:LawyerOnline/shared/api_provider.dart';
import 'package:LawyerOnline/models/user_profile_store.dart';

class CaseService {
  // ── สร้างเคสบอร์ดแคส (caseType=2) ตอนเข้าหน้า map ─────────────────────
  static Future<String> createBroadcastCase({
    required String topic,          // code หมวดหลัก
    required String topicTitle,     // ชื่อหมวดหลัก
    required String subTopic,       // code หมวดย่อย
    required String subTopicTitle,  // ชื่อหมวดย่อย
    required String province,       // ชื่อจังหวัด
    required String detail,         // สรุปเหตุการณ์
    required String demand,         // ข้อเรียกร้อง
    required double lat,
    required double lng,
  }) async {
    final profile = UserProfileStore.instance;
    final result = await postDio('$server/m/case/create', {
      'caseType': 2,
      'caseStatus': 1,
      'userCode': profile.code,
      'userName': profile.name,
      'topic': topic,
      'topicTitle': topicTitle,
      'subTopic': subTopic,
      'subTopicTitle': subTopicTitle,
      'province': province,
      'story': detail,
      'requirement': demand,
      'lat': lat,
      'lng': lng,
      'searchRadiusKm': 5,
      'durationMinutes': 30,
    });
    if (result['status'] != 'S') {
      throw Exception(result['message'] ?? 'สร้างเคสไม่สำเร็จ');
    }
    return result['objectData']['code'] as String;
  }

  // ── สร้างเคสนัดหมายล่วงหน้า (caseType=1) ตอนจ่ายเงินสำเร็จ ────────────
  static Future<String> createAppointmentCase({
    required String lawyerCode,
    required String topic,
    required String topicTitle,
    required String subTopic,
    required String subTopicTitle,
    required String province,
    required String detail,
    required String demand,
    int caseType = 1,
    int caseStatus = 1,
  }) async {
    final profile = UserProfileStore.instance;
    final result = await postDio('$server/m/case/create', {
      'caseType': caseType,
      'caseStatus': caseStatus,
      'userCode': profile.code,
      'userName': profile.name,
      'lawyer': lawyerCode,
      'topic': topic,
      'topicTitle': topicTitle,
      'subTopic': subTopic,
      'subTopicTitle': subTopicTitle,
      'province': province,
      'story': detail,
      'requirement': demand,
    });
    if (result['status'] != 'S') {
      throw Exception(result['message'] ?? 'สร้างเคสไม่สำเร็จ');
    }
    return result['objectData']['code'] as String;
  }

  // ── ลบเคสที่ยังไม่สมบูรณ์ (best-effort) ────────────────────────────────
  static Future<void> deleteCase(String code) async {
    try {
      await postDio('$server/m/case/delete', {'code': code});
    } catch (_) {}
  }
}