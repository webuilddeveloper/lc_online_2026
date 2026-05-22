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

  // jobSource: 'urgent' = ลูกความส่งตรง (เคสด่วน), 'booking' = จองล่วงหน้า
  static final List<Map<String, dynamic>> mockSeedJobs = [
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
      'jobSource': 'urgent',
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
      'jobSource': 'urgent',
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
      'jobSource': 'urgent',
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
      'jobSource': 'urgent',
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
      'jobSource': 'urgent',
      'budget': 'ฟรี',
    },
  ];

  final List<Map<String, dynamic>> jobs = [];

  void loadMockSeedJobsForDev() {
    if (jobs.isNotEmpty) return;
    jobs.addAll(mockSeedJobs.map((job) => Map<String, dynamic>.from(job)));
    notifyListeners();
  }

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
            : '';
    if (lawyerCode.isEmpty) {
      throw ArgumentError('Selected lawyer is missing code');
    }
    normalizedLawyer['code'] = lawyerCode;

    final safeClientCode = clientCode.trim();
    if (safeClientCode.isEmpty) {
      throw ArgumentError('Logged-in user is missing code');
    }
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
      'jobSource': 'booking',
      'budget': safeBudget,
    };

    jobs.insert(0, job);
    notifyListeners();
    return job;
  }

  Map<String, dynamic> createFromUrgent({
    required Map<String, dynamic> lawyerModel,
    required String topic,
    required String subTopic,
    required String detail,
    required String clientCode,
    String? clientName,
    String? budget,
  }) {
    final normalizedLawyer = Map<String, dynamic>.from(lawyerModel);
    final lawyerCode =
        normalizedLawyer['code']?.toString().trim().isNotEmpty == true
            ? normalizedLawyer['code'].toString()
            : '';
    if (lawyerCode.isEmpty) {
      throw ArgumentError('Selected lawyer is missing code');
    }
    normalizedLawyer['code'] = lawyerCode;

    final safeClientCode = clientCode.trim();
    if (safeClientCode.isEmpty) {
      throw ArgumentError('Logged-in user is missing code');
    }
    final safeClientName = clientName?.trim().isNotEmpty == true
        ? clientName!.trim()
        : 'Client $safeClientCode';
    final safeBudget = budget?.trim().isNotEmpty == true
        ? budget!.trim()
        : (normalizedLawyer['cost']?.toString() ??
            normalizedLawyer['price']?.toString() ??
            'Free');
    final jobId = 'REQ-${DateTime.now().millisecondsSinceEpoch}';

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
      'detail': detail.trim().isNotEmpty ? detail.trim() : subTopic,
      'date': '',
      'time': '',
      'status': 'pending',
      'requestedAt': 'เน€เธกเธทเนเธญเธชเธฑเธเธเธฃเธนเน',
      'jobSource': 'urgent',
      'budget': safeBudget,
    };

    jobs.insert(0, job);
    notifyListeners();
    return job;
  }

  List<Map<String, dynamic>> jobsForLawyer(String lawyerCode) {
    final safeLawyerCode = lawyerCode.trim();
    if (safeLawyerCode.isEmpty) return [];
    return jobs.where((job) => job['lawyerCode'] == safeLawyerCode).toList();
  }

  List<Map<String, dynamic>> jobsForClient(String clientCode) {
    final safeClientCode = clientCode.trim();
    if (safeClientCode.isEmpty) return [];
    return jobs.where((job) => job['clientCode'] == safeClientCode).toList();
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

  // ยืนยันการจอง (booking) — ต่างจาก acceptJob ของ urgent
  void confirmBooking(String id) {
    HapticFeedback.mediumImpact();
    updateStatus(id, 'confirmed');
  }

  void rejectJob(String id) {
    HapticFeedback.lightImpact();
    updateStatus(id, 'rejected');
  }

  // เริ่ม session เมื่อถึงวันนัด
  void startSession(String id) {
    HapticFeedback.mediumImpact();
    updateStatus(id, 'in_session');
  }

  // ── Query helpers ────────────────────────────────────────

  // urgent jobs ที่ยังรอหรือกำลัง active (แสดงบน home ทนาย)
  List<Map<String, dynamic>> urgentJobsForLawyer(String lawyerCode) {
    return jobsForLawyer(lawyerCode)
        .where((j) => (j['jobSource'] ?? 'urgent') == 'urgent')
        .toList();
  }

  // booking jobs ทั้งหมดของทนาย
  List<Map<String, dynamic>> bookingJobsForLawyer(String lawyerCode) {
    return jobsForLawyer(lawyerCode)
        .where((j) => (j['jobSource'] ?? 'urgent') == 'booking')
        .toList();
  }

  // booking ที่ยืนยันแล้วและถึงวันนัดวันนี้ (สำหรับปุ่มเริ่มปรึกษา)
  List<Map<String, dynamic>> bookingsDueToday(String lawyerCode) {
    final today = DateTime.now();
    return bookingJobsForLawyer(lawyerCode).where((j) {
      if (j['status'] != 'confirmed') return false;
      final dateStr = j['date']?.toString() ?? '';
      if (dateStr.isEmpty) return false;
      // รองรับรูปแบบ dd/MM/yyyy และ dd MMM yyyy (ภาษาไทย)
      try {
        final parsed = _parseJobDate(dateStr);
        return parsed != null &&
            parsed.year == today.year &&
            parsed.month == today.month &&
            parsed.day == today.day;
      } catch (_) {
        return false;
      }
    }).toList();
  }

  List<Map<String, dynamic>> bookingAppointmentsForLawyer(String lawyerCode) {
    return bookingJobsForLawyer(lawyerCode)
        .where((j) =>
            j['status'] == 'confirmed' ||
            j['status'] == 'in_session' ||
            j['status'] == 'done')
        .map(bookingJobToAppointment)
        .toList();
  }

  static Map<String, dynamic> bookingJobToAppointment(
      Map<String, dynamic> job) {
    final parsedTime = _parseTimeWindow(job['time']?.toString() ?? '');
    final status = job['status']?.toString() ?? 'confirmed';
    return {
      'code': job['id']?.toString() ?? '',
      'jobId': job['id']?.toString() ?? '',
      'jobSource': 'booking',
      'jobStatus': status,
      'clientCode': job['clientCode'] ?? '',
      'lawyerCode': job['lawyerCode'] ?? '',
      'lawyerModel': job['lawyerModel'],
      'clientName': job['clientName'] ?? '',
      'clientAvatar': job['clientAvatar'] ?? '',
      'clientColor': job['clientColor'],
      'caseType': job['topic'] ?? '',
      'subCaseType': job['subTopic'] ?? '',
      'appointmentDate': job['date'] ?? '',
      'appointmentTime': job['time'] ?? '',
      'startHour': parsedTime.$1,
      'startMin': parsedTime.$2,
      'durationMin': parsedTime.$3,
      'title': job['subTopic'] ?? job['topic'] ?? '',
      'details': job['detail'] ?? '',
      'appointmentStatus': status == 'done' ? '3' : '2',
      'paymentStatus': '1',
      'colorIndex': 0,
    };
  }

  static (int, int, int) _parseTimeWindow(String raw) {
    final normalized = raw.replaceAll(':', '.').replaceAll('–', '-');
    final parts = normalized.split('-').map((p) => p.trim()).toList();
    if (parts.length != 2) return (9, 0, 60);

    (int, int)? parsePoint(String value) {
      final pieces = value.split('.');
      if (pieces.length < 2) return null;
      final hour = int.tryParse(pieces[0]);
      final minute = int.tryParse(pieces[1]);
      if (hour == null || minute == null) return null;
      return (hour, minute);
    }

    final start = parsePoint(parts[0]);
    final end = parsePoint(parts[1]);
    if (start == null || end == null) return (9, 0, 60);

    final startTotal = start.$1 * 60 + start.$2;
    final endTotal = end.$1 * 60 + end.$2;
    final duration = endTotal > startTotal ? endTotal - startTotal : 60;
    return (start.$1, start.$2, duration);
  }

  // แปลงวันที่จาก job['date'] — รองรับ dd/MM/yyyy เป็นหลัก
  static DateTime? _parseJobDate(String raw) {
    // dd/MM/yyyy
    final slashRe = RegExp(r'^(\d{1,2})/(\d{1,2})/(\d{4})$');
    final m = slashRe.firstMatch(raw.trim());
    if (m != null) {
      return DateTime(int.parse(m.group(3)!), int.parse(m.group(2)!),
          int.parse(m.group(1)!));
    }
    return null;
  }
}
