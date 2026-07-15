import 'package:LawyerOnline/shared/api_provider.dart';

class BookedSlot {
  const BookedSlot({
    required this.caseCode,
    required this.caseDate,
    required this.startTime,
    required this.endTime,
  });

  final String caseCode;
  final String caseDate;
  final String startTime;
  final String endTime;

  factory BookedSlot.fromJson(Map<String, dynamic> json) => BookedSlot(
        caseCode: json['caseCode']?.toString() ?? '',
        caseDate: json['caseDate']?.toString() ?? '',
        startTime: json['startTime']?.toString() ?? '',
        endTime: json['endTime']?.toString() ?? '',
      );
}

class AppointmentBookingService {
  AppointmentBookingService._();

  static Future<List<BookedSlot>> loadBookedSlots({
    required String lawyerCode,
    String? caseDate,
  }) async {
    final result = await postDio('${server}/m/appointment/booked-slots/read', {
      'lawyerCode': lawyerCode,
      if (caseDate != null && caseDate.isNotEmpty) 'caseDate': caseDate,
    });
    if (result['status'] != 'S' || result['objectData'] is! List) return [];
    return (result['objectData'] as List)
        .map((e) => BookedSlot.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  static Future<bool> reschedule({
    required String caseCode,
    required String caseDate,
    required String startTime,
    required String endTime,
    required String updateBy,
    String updateByName = '',
  }) async {
    final result = await postDio('${server}/m/appointment/reschedule', {
      'caseCode': caseCode,
      'caseDate': caseDate,
      'startTime': startTime,
      'endTime': endTime,
      'updateBy': updateBy,
      'updateByName': updateByName,
    });
    return result['status'] == 'S';
  }

  static Future<bool> markNoShow({
    required String caseCode,
    required String noShowBy,
    required String updateBy,
  }) async {
    final result = await postDio('${server}/m/appointment/no-show', {
      'caseCode': caseCode,
      'noShowBy': noShowBy,
      'updateBy': updateBy,
    });
    return result['status'] == 'S';
  }
}
