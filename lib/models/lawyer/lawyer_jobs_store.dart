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

  // ใช้เฉพาะตอน mock/dev เท่านั้น ของจริงต้องมาจาก DB/session หลัง login
  // Mock seed identities for the shared in-memory case flow.
  // Production identities should come from the logged-in session/API.
  static const String mockSeedClientCode = '20260518113453-846-867';
  static const String mockSeedLawyerCode = '20260513101915-561-752';

  static const Map<String, dynamic> _primaryLawyerModel = {
    'code': mockSeedLawyerCode,
    'name': 'ศักดิ์สิทธิ์ พิพากษ์',
    'title': 'ทนายความอาวุโส',
    'scroll': 4.8,
    'rating': 4.8,
    'cost': 'Free',
    'costUnit': '/hr',
    'imageUrl': 'assets/images/lawyer-avatar-1.png',
    'experience': '11+ ปี',
    'price': 500,
    'skills': ['อาญาและอาชญากรรม', 'ครอบครัวและมรดก'],
  };

  final List<Map<String, dynamic>> jobs = [
    {
      'id': 'REQ-2026-001',
      'clientCode': mockSeedClientCode,
      'lawyerCode': mockSeedLawyerCode,
      'lawyerModel': _primaryLawyerModel,
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
      'clientCode': mockSeedClientCode,
      'lawyerCode': mockSeedLawyerCode,
      'lawyerModel': _primaryLawyerModel,
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
      'clientCode': mockSeedClientCode,
      'lawyerCode': mockSeedLawyerCode,
      'lawyerModel': _primaryLawyerModel,
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
      'clientCode': mockSeedClientCode,
      'lawyerCode': mockSeedLawyerCode,
      'lawyerModel': _primaryLawyerModel,
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
      'clientCode': mockSeedClientCode,
      'lawyerCode': mockSeedLawyerCode,
      'lawyerModel': _primaryLawyerModel,
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
  Map<String, dynamic> createFromBooking({
    required Map<String, dynamic> lawyerModel,
    required String topic,
    required String subTopic,
    required String appointmentDate,
    required String appointmentTime,
    required String clientCode,
    String? clientName,
    String? bookingCode,
    String? detail,
    String? budget,
  }) {
    final normalizedLawyer = Map<String, dynamic>.from(lawyerModel);
    final lawyerCode =
        normalizedLawyer['code']?.toString().trim().isNotEmpty == true
            ? normalizedLawyer['code'].toString()
            : mockSeedLawyerCode;
    normalizedLawyer['code'] = lawyerCode;

    final safeClientCode =
        clientCode.trim().isNotEmpty ? clientCode.trim() : mockSeedClientCode;
    final safeBookingCode = bookingCode?.trim().isNotEmpty == true
        ? bookingCode!.trim()
        : DateTime.now().millisecondsSinceEpoch.toString();
    final jobId = safeBookingCode.startsWith('REQ-')
        ? safeBookingCode
        : 'REQ-$safeBookingCode';

    final existingIndex = jobs.indexWhere((job) => job['id'] == jobId);
    if (existingIndex >= 0) return jobs[existingIndex];

    final safeClientName = clientName?.trim().isNotEmpty == true
        ? clientName!.trim()
        : 'Client $safeClientCode';
    final safeBudget = budget?.trim().isNotEmpty == true
        ? budget!.trim()
        : (normalizedLawyer['cost']?.toString() ?? 'Free');

    final job = {
      'id': jobId,
      'clientCode': safeClientCode,
      'lawyerCode': lawyerCode,
      'lawyerModel': normalizedLawyer,
      'clientName': safeClientName,
      'clientAvatar': safeClientName.isNotEmpty ? safeClientName[0] : 'U',
      'clientColor': 0xFF0262EC,
      'topic': topic,
      'subTopic': subTopic,
      'detail': detail?.trim().isNotEmpty == true ? detail!.trim() : subTopic,
      'date': appointmentDate,
      'time': appointmentTime,
      'status': 'pending',
      'requestedAt': 'เมื่อสักครู่',
      'type': 'video',
      'budget': safeBudget,
    };

    jobs.insert(0, job);
    notifyListeners();
    return job;
  }

  List<Map<String, dynamic>> jobsForLawyer(String lawyerCode) {
    final safeLawyerCode =
        lawyerCode.trim().isNotEmpty ? lawyerCode.trim() : mockSeedLawyerCode;
    final matched =
        jobs.where((job) => job['lawyerCode'] == safeLawyerCode).toList();
    if (matched.isNotEmpty) return matched;

    // Mock/dev fallback: ให้หน้า lawyer ยังมี seed data ใช้ทดสอบ flow ได้
    // แม้ login code จาก backend ยังไม่ตรงกับ mock seed ในเครื่องนี้
    return jobs
        .where((job) => job['lawyerCode'] == mockSeedLawyerCode)
        .toList();
  }

  List<Map<String, dynamic>> jobsForClient(String clientCode) {
    final safeClientCode =
        clientCode.trim().isNotEmpty ? clientCode.trim() : mockSeedClientCode;
    final matched =
        jobs.where((job) => job['clientCode'] == safeClientCode).toList();
    if (matched.isNotEmpty) return matched;
    return jobs
        .where((job) => job['clientCode'] == mockSeedClientCode)
        .toList();
  }

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
