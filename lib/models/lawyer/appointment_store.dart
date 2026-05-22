// ══════════════════════════════════════════════════════════
//  AppointmentStore — Single source of truth สำหรับนัดหมาย
//
//  รวม appointmentList (home.dart) และ itemEvents (calendar.dart)
//  เข้าด้วยกัน ทุกหน้าให้ import ไฟล์นี้แทน
//
//  Schema ของแต่ละ appointment:
//    code            String   — รหัส
//    clientName      String   — ชื่อลูกค้า
//    caseType        String   — ประเภทคดี
//    subCaseType     String   — ประเภทย่อย
//    appointmentDate String   — "dd/MM/yyyy"
//    appointmentTime String   — "HH.mm - HH.mm"
//    startHour       int      — ชั่วโมงเริ่ม (ใช้ใน timeline)
//    startMin        int      — นาทีเริ่ม
//    durationMin     int      — ความยาว (นาที)
//    title           String   — ชื่อนัด
//    details         String   — รายละเอียด
//    paymentStatus   String   — "1" = ชำระแล้ว, "2" = ยังไม่ชำระ
//    colorIndex      int      — index สีใน _kEventColors
// ══════════════════════════════════════════════════════════

import 'package:LawyerOnline/models/lawyer/lawyer_jobs_store.dart';

class AppointmentStore {
  // Singleton
  AppointmentStore._();
  static final AppointmentStore instance = AppointmentStore._();

  // ─── Raw list ──────────────────────────────────────────
  final List<Map<String, dynamic>> appointments = [
    {
      "code": "0",
      "clientName": "อนงค์ ดำเนิน",
      "caseType": "คดีมรดกทุกประเภท",
      "subCaseType": "ฟ้องร้องมรดก",
      "appointmentDate": "10/05/2026",
      "appointmentTime": "09.00 - 10.00",
      "startHour": 9,
      "startMin": 0,
      "durationMin": 60,
      "title": "ขอฟ้องร้องมรดกพี่น้อง",
      "details": "ต้องการฟ้องร้องพี่น้องที่โกงเงินมรดก",
      "paymentStatus": "1",
      "colorIndex": 0,
    },
    {
      "code": "1",
      "clientName": "อนงค์ ดำเนิน",
      "caseType": "คดีครอบครัว",
      "subCaseType": "ฟ้องร้องการหย่าร้าง",
      "appointmentDate": "10/05/2026",
      "appointmentTime": "11.00 - 13.00",
      "startHour": 11,
      "startMin": 0,
      "durationMin": 120,
      "title": "ขอฟ้องร้องหย่าร้าง",
      "details": "ต้องการฟ้องร้องหย่าร้างกับสามีคนปัจจุบัน",
      "paymentStatus": "1",
      "colorIndex": 2,
    },
    {
      "code": "2",
      "clientName": "สมชาย ใจดี",
      "caseType": "คดีมรดกทุกประเภท",
      "subCaseType": "ฟ้องร้องมรดก",
      "appointmentDate": "20/05/2026",
      "appointmentTime": "10.00 - 11.30",
      "startHour": 10,
      "startMin": 0,
      "durationMin": 90,
      "title": "ขอฟ้องร้องมรดกพี่น้อง ครั้งที่ 2",
      "details": "ต้องการฟ้องร้องพี่น้องที่โกงเงินมรดก",
      "paymentStatus": "2",
      "colorIndex": 1,
    },
    {
      "code": "3",
      "clientName": "วรรณา สุขสม",
      "caseType": "คดีแรงงาน",
      "subCaseType": "เรียกค่าชดเชย",
      "appointmentDate": "22/05/2026",
      "appointmentTime": "09.00 - 10.00",
      "startHour": 9,
      "startMin": 0,
      "durationMin": 60,
      "title": "คดีแรงงาน เรียกค่าชดเชย",
      "details": "ถูกเลิกจ้างโดยไม่มีสาเหตุ ต้องการเรียกค่าชดเชย",
      "paymentStatus": "1",
      "colorIndex": 3,
    },
    {
      "code": "4",
      "clientName": "ประสิทธิ์ มั่งมี",
      "caseType": "ธุรกิจและบริษัท",
      "subCaseType": "ตรวจร่างสัญญา",
      "appointmentDate": "22/05/2026",
      "appointmentTime": "14.00 - 15.30",
      "startHour": 14,
      "startMin": 0,
      "durationMin": 90,
      "title": "ตรวจร่างสัญญาซื้อขายกิจการ",
      "details": "ตรวจสอบสัญญาซื้อขายกิจการ มูลค่า 5 ล้านบาท",
      "paymentStatus": "2",
      "colorIndex": 4,
    },
    {
      "code": "5",
      "clientName": "อนงค์ ดำเนิน",
      "caseType": "คดีมรดกทุกประเภท",
      "subCaseType": "ฟ้องร้องมรดก",
      "appointmentDate": "25/05/2026",
      "appointmentTime": "13.00 - 14.00",
      "startHour": 13,
      "startMin": 0,
      "durationMin": 60,
      "title": "ขอฟ้องร้องมรดกพี่น้อง",
      "details": "ต้องการฟ้องร้องพี่น้องที่โกงเงินมรดก",
      "paymentStatus": "2",
      "colorIndex": 5,
    },
    {
      "code": "6",
      "clientName": "อนงค์ ดำเนิน",
      "caseType": "คดีมรดกทุกประเภท",
      "subCaseType": "ฟ้องร้องมรดก",
      "appointmentDate": "28/05/2026",
      "appointmentTime": "11.20 - 13.00",
      "startHour": 11,
      "startMin": 20,
      "durationMin": 100,
      "title": "ขอฟ้องร้องมรดกพี่น้อง",
      "details": "ต้องการฟ้องร้องพี่น้องที่โกงเงินมรดก",
      "paymentStatus": "1",
      "colorIndex": 0,
    },
    {
      "code": "7",
      "clientName": "อนงค์ ดำเนิน",
      "caseType": "คดีมรดกทุกประเภท",
      "subCaseType": "ฟ้องร้องมรดก",
      "appointmentDate": "29/05/2026",
      "appointmentTime": "11.00 - 14.00",
      "startHour": 11,
      "startMin": 0,
      "durationMin": 180,
      "title": "ขอฟ้องร้องมรดกผู้ปกครอง",
      "details": "ต้องการฟ้องร้องพี่น้องที่โกงเงินมรดก",
      "paymentStatus": "1",
      "colorIndex": 1,
    },
  ];

  // ─── Helper: แปลง "dd/MM/yyyy" → DateTime key ──────────
  static DateTime _parseDate(String dateStr) {
    final parts = dateStr.split('/');
    return DateTime(
      int.parse(parts[2]),
      int.parse(parts[1]),
      int.parse(parts[0]),
    );
  }

  // ─── ดึงเป็น flat list (ใช้ใน home.dart / HomeLawyerSection) ──
  List<Map<String, dynamic>> get list => appointments;

  List<Map<String, dynamic>> listForLawyer(String lawyerCode) {
    return [
      ...appointments,
      ...LawyerJobsStore.instance.bookingAppointmentsForLawyer(lawyerCode),
    ];
  }

  // ─── ดึงเป็น Map<DateTime, List> (ใช้ใน calendar.dart) ──────
  Map<DateTime, List<dynamic>> get eventMap {
    final Map<DateTime, List<dynamic>> result = {};
    for (final appt in appointments) {
      final key = _parseDate(appt['appointmentDate'] as String);
      result.putIfAbsent(key, () => []).add(appt);
    }
    return result;
  }

  Map<DateTime, List<dynamic>> eventMapForLawyer(String lawyerCode) {
    final Map<DateTime, List<dynamic>> result = {};
    for (final appt in listForLawyer(lawyerCode)) {
      final dateStr = appt['appointmentDate'] as String? ?? '';
      if (dateStr.isEmpty) continue;
      try {
        final key = _parseDate(dateStr);
        result.putIfAbsent(key, () => []).add(appt);
      } catch (_) {
        continue;
      }
    }
    return result;
  }

  // ─── ดึงนัดของวันที่ระบุ ───────────────────────────────────
  List<dynamic> getEventsForDay(DateTime day) {
    final key = DateTime(day.year, day.month, day.day);
    return eventMap[key] ?? [];
  }

  // ─── เช็คว่ามีนัดชนใน windowMinutes ──────────────────────
  bool hasConflictingAppointment({int windowMinutes = 60}) {
    return _hasConflictingAppointmentIn(appointments,
        windowMinutes: windowMinutes);
  }

  bool hasConflictingAppointmentForLawyer(String lawyerCode,
      {int windowMinutes = 60}) {
    return _hasConflictingAppointmentIn(listForLawyer(lawyerCode),
        windowMinutes: windowMinutes);
  }

  bool _hasConflictingAppointmentIn(List<Map<String, dynamic>> source,
      {int windowMinutes = 60}) {
    final now = DateTime.now();
    for (final appt in source) {
      final dateStr = appt['appointmentDate'] as String? ?? '';
      final timeStr = appt['appointmentTime'] as String? ?? '';
      if (dateStr.isEmpty || timeStr.isEmpty) continue;

      final date = _parseDate(dateStr);
      if (now.year != date.year ||
          now.month != date.month ||
          now.day != date.day) continue;

      final timeParts = timeStr.split(' - ');
      if (timeParts.length != 2) continue;

      final startParts = timeParts[0].replaceAll(':', '.').split('.');
      final endParts = timeParts[1].replaceAll(':', '.').split('.');

      final startTime = DateTime(date.year, date.month, date.day,
          int.parse(startParts[0]), int.parse(startParts[1]));
      final endTime = DateTime(date.year, date.month, date.day,
          int.parse(endParts[0]), int.parse(endParts[1]));

      final minutesToStart = startTime.difference(now).inMinutes;
      final minutesToEnd = endTime.difference(now).inMinutes;

      if (minutesToStart <= windowMinutes && minutesToEnd > 0) return true;
    }
    return false;
  }
}
