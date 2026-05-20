import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';

// ══════════════════════════════════════════════════════════
//  LawyerJobsStore — Single source of truth สำหรับ job requests
//  ทุกหน้าที่ต้องการข้อมูลให้ import ไฟล์นี้
// ══════════════════════════════════════════════════════════

class LawyerJobsStore extends ChangeNotifier {
  // Singleton
  LawyerJobsStore._();
  static final LawyerJobsStore instance = LawyerJobsStore._();

  final List<Map<String, dynamic>> jobs = [
    {
      'id': 'REQ-2026-001',
      'clientName': 'สมชาย ใจดี',
      'clientAvatar': 'ส',
      'clientColor': 0xFF0262EC,
      'topic': 'ครอบครัวและมรดก',
      'subTopic': 'ฟ้องหย่า / แบ่งสินสมรส',
      'detail':
          'ต้องการปรึกษาเรื่องการฟ้องหย่าและการแบ่งทรัพย์สินสมรส มีบ้านและที่ดิน 2 แปลง ต้องการคำแนะนำเบื้องต้น',
      'date': '28 มี.ค. 2569',
      'time': '10:00 - 11:00',
      'status': 'pending',
      'requestedAt': '2 ชั่วโมงที่แล้ว',
      'type': 'video',
      'budget': 'ฟรี',
    },
    {
      'id': 'REQ-2026-002',
      'clientName': 'วิภา รักสงบ',
      'clientAvatar': 'ว',
      'clientColor': 0xFFE11D48,
      'topic': 'หนี้สินและการเงิน',
      'subTopic': 'หนี้กู้ยืมเงิน / ดอกเบี้ย',
      'detail':
          'โดนเพื่อนยืมเงิน 200,000 บาท ไม่คืน มีสัญญากู้ยืมเงิน อยากดำเนินคดีเพื่อเรียกคืน',
      'date': '30 มี.ค. 2569',
      'time': '14:00 - 15:00',
      'status': 'pending',
      'requestedAt': '5 ชั่วโมงที่แล้ว',
      'type': 'video',
      'budget': '500 บาท',
    },
    {
      'id': 'REQ-2026-003',
      'clientName': 'ประสิทธิ์ มั่งมี',
      'clientAvatar': 'ป',
      'clientColor': 0xFF059669,
      'topic': 'ธุรกิจและบริษัท',
      'subTopic': 'ตรวจร่างสัญญา',
      'detail':
          'ต้องการให้ตรวจสอบสัญญาซื้อขายกิจการ มูลค่า 5 ล้านบาท กังวลเรื่องเงื่อนไขการรับประกัน',
      'date': '02 เม.ย. 2569',
      'time': '09:00 - 10:00',
      'status': 'accepted',
      'requestedAt': '1 วันที่แล้ว',
      'type': 'video',
      'budget': '1,000 บาท',
    },
    {
      'id': 'REQ-2026-004',
      'clientName': 'นงลักษณ์ สุขสม',
      'clientAvatar': 'น',
      'clientColor': 0xFF7C3AED,
      'topic': 'ทรัพย์สินและที่ดิน',
      'subTopic': 'เช่าบ้าน / ขับไล่ผู้เช่า',
      'detail':
          'ผู้เช่าค้างค่าเช่า 3 เดือน ไม่ยอมออก ต้องการดำเนินการทางกฎหมาย',
      'date': '15 มี.ค. 2569',
      'time': '11:00 - 12:00',
      'status': 'done',
      'requestedAt': '2 สัปดาห์ที่แล้ว',
      'type': 'video',
      'budget': '800 บาท',
    },
    {
      'id': 'REQ-2026-005',
      'clientName': 'อนันต์ ชัยชนะ',
      'clientAvatar': 'อ',
      'clientColor': 0xFFD97706,
      'topic': 'อาญาและอาชญากรรม',
      'subTopic': 'หมิ่นประมาท',
      'detail':
          'ถูกโพสต์หมิ่นประมาทบน Facebook ทำให้เสียชื่อเสียง ต้องการฟ้องร้อง',
      'date': '',
      'time': '',
      'status': 'rejected',
      'requestedAt': '3 วันที่แล้ว',
      'type': 'video',
      'budget': 'ฟรี',
    },
  ];

  // อัปเดต status — notifyListeners() ทำให้ทุก ListenableBuilder rebuild อัตโนมัติ
  void updateStatus(String id, String newStatus) {
    final job = jobs.firstWhere((j) => j['id'] == id, orElse: () => {});
    if (job.isNotEmpty) {
      job['status'] = newStatus;
      notifyListeners();
    }
  }

  void acceptJob(String id) {
    HapticFeedback.mediumImpact();
    updateStatus(id, 'accepted');
  }

  void rejectJob(String id) {
    HapticFeedback.lightImpact();
    updateStatus(id, 'rejected');
  }
}
