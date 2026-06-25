import 'package:LawyerOnline/repositories/booking_case_repository.dart';
import 'package:LawyerOnline/shared/api_provider.dart';
import 'package:intl/intl.dart';

abstract class LawyerAppointmentRepository {
  Future<List<Map<String, dynamic>>> readAppointmentsForLawyer(
    String lawyerCode,
  );

  Future<LawyerScheduleSnapshot> readScheduleForLawyer(String lawyerCode);
}

class LawyerScheduleSnapshot {
  const LawyerScheduleSnapshot({
    required this.appointments,
    required this.bookingJobs,
  });

  final List<Map<String, dynamic>> appointments;
  final List<Map<String, dynamic>> bookingJobs;
}

class ApiLawyerAppointmentRepository implements LawyerAppointmentRepository {
  const ApiLawyerAppointmentRepository({
    BookingCaseRepository caseRepository = const ApiBookingCaseRepository(),
  }) : _caseRepository = caseRepository;

  final BookingCaseRepository _caseRepository;

  @override
  Future<List<Map<String, dynamic>>> readAppointmentsForLawyer(
    String lawyerCode,
  ) async {
    final snapshot = await readScheduleForLawyer(lawyerCode);
    return snapshot.appointments;
  }

  @override
  Future<LawyerScheduleSnapshot> readScheduleForLawyer(
      String lawyerCode) async {
    final code = lawyerCode.trim();
    if (code.isEmpty) {
      return const LawyerScheduleSnapshot(
        appointments: [],
        bookingJobs: [],
      );
    }
    final cases = await _caseRepository.readCases(lawyerCode: code);
    return LawyerScheduleSnapshot(
      appointments: [
        for (var i = 0; i < cases.length; i++)
          CaseAppointmentMapper.fromCase(cases[i], colorIndex: i % 6),
      ],
      bookingJobs: [
        for (final item in cases)
          item['caseType'] == 2
              ? CaseAppointmentMapper.bookingJobFromCase(item)
              : null,
      ],
    );
  }
}

class CaseAppointmentMapper {
  static Map<String, dynamic> fromCase(
    Map<String, dynamic> source, {
    int colorIndex = 0,
  }) {
    final start = _timeString(_first(source, const [
      'startTime',
      'start_time',
      'timeStart',
    ]));
    final end = _timeString(_first(source, const [
      'endTime',
      'end_time',
      'timeEnd',
    ]));
    final parsedStart = _parseTime(start);
    final parsedEnd = _parseTime(end);
    final date = _dateString(_first(source, const [
      'caseDate',
      'case_date',
      'appointmentDate',
      'date',
    ]));

    final topicTitle = _string(_first(source, const [
      'topicTitle',
      'topic',
      'caseTypeTitle',
      'caseType',
    ]));
    final subTopicTitle = _string(_first(source, const [
      'subTopicTitle',
      'subTopic',
      'subCaseType',
      'title',
    ]));
    final title = subTopicTitle.isNotEmpty ? subTopicTitle : topicTitle;

    return {
      'code': _string(_first(source, const ['code', 'id', '_id'])),
      'clientName': _string(_first(source, const ['clientName', 'name'])),
      'caseType': topicTitle,
      'subCaseType': subTopicTitle,
      'appointmentDate': date,
      'appointmentTime': _appointmentTime(start, end),
      'startHour': parsedStart?.hour ?? 9,
      'startMin': parsedStart?.minute ?? 0,
      'durationMin': _durationMinutes(parsedStart, parsedEnd),
      'title': title,
      'details': _string(_first(source, const ['details', 'requirement'])),
      'paymentStatus': _isPaid(source['isPay']) ? '1' : '2',
      'appointmentStatus': _appointmentStatus(source['caseStatus']),
      'colorIndex': colorIndex,
      'rawCase': source,
    };
  }

  static dynamic bookingJobFromCase(dynamic source) async {
    final appointment = fromCase(source);
    final code = _caseIdentity(source);
    final rawCode = _string(_first(source, const [
      'code',
      'id',
      '_id',
      'messageRef',
    ]));
    final lawyerCode = _string(_first(source, const ['lawyerCode']));
    final lawyerName = _string(_first(source, const ['lawyerName']));
    String userName = "";
    String userImage = "";

    await postDio("${server}/m/register/read", {'userCode': source['userCode']})
        .then((res) {
      userName = res['objectData'][0]['firstName'] ?? '';
      userImage = res['objectData'][0]['imageUrl'] ?? '';
      return {
        'id': code,
        'caseCode': rawCode,
        'clientCode': _string(_first(source, const ['clientCode'])),
        'lawyerCode': lawyerCode,
        'lawyerModel': {
          'code': lawyerCode,
          'name': lawyerName,
          'imageUrl': 'assets/images/lawyer-avatar-1.png',
        },
        'clientName': userName,
        'clientAvatar': userImage,
        'clientColor': 0xFF0262EC,
        'topic': appointment['caseType'] ?? '',
        'subTopic': appointment['subCaseType'] ?? '',
        'detail': appointment['details'] ?? '',
        'date': appointment['appointmentDate'] ?? '',
        'time': appointment['appointmentTime'] ?? '',
        'status': _jobStatus(source['caseStatus']),
        'requestedAt': '',
        'jobSource': 'booking',
        'budget': _string(_first(source, const ['price', 'budget'])),
        'rawCase': source,
        'isApiCase': true,
        'apiCaseCode': rawCode,
      };
    });
  }

  static Map<DateTime, List<dynamic>> eventMapFromAppointments(
    List<dynamic> appointments,
  ) {
    final result = <DateTime, List<dynamic>>{};
    for (final appointment in appointments) {
      final date = parseAppointmentDate(
        appointment['appointmentDate']?.toString() ?? '',
      );
      if (date == null) continue;
      final key = DateTime(date.year, date.month, date.day);
      result.putIfAbsent(key, () => []).add(appointment);
    }
    return result;
  }

  static List<dynamic> mergeAppointments(
    List<dynamic> primary,
    List<Map<String, dynamic>> secondary,
  ) {
    final result = <Map<String, dynamic>>[];
    final seen = <String>{};

    for (final appointment in [...primary, ...secondary]) {
      final key = _appointmentKey(appointment);
      if (key.isNotEmpty && !seen.add(key)) continue;
      result.add(Map<String, dynamic>.from(appointment));
    }
    return result;
  }

  static bool hasConflictingAppointment(
    List<Map<String, dynamic>> appointments, {
    int windowMinutes = 60,
  }) {
    final now = DateTime.now();
    for (final appointment in appointments) {
      final date = parseAppointmentDate(
        appointment['appointmentDate']?.toString() ?? '',
      );
      final start = _parseTime(
          appointment['appointmentTime']?.toString().split(' - ').firstOrNull ??
              '');
      if (date == null || start == null) continue;
      if (now.year != date.year ||
          now.month != date.month ||
          now.day != date.day) {
        continue;
      }
      final startAt = DateTime(
        date.year,
        date.month,
        date.day,
        start.hour,
        start.minute,
      );
      final minutesToStart = startAt.difference(now).inMinutes;
      if (minutesToStart >= 0 && minutesToStart <= windowMinutes) {
        return true;
      }
    }
    return false;
  }

  static DateTime? parseAppointmentDate(String value) {
    final raw = value.trim();
    if (raw.isEmpty) return null;

    for (final pattern in const ['dd/MM/yyyy', 'yyyy-MM-dd', 'dd-MM-yyyy']) {
      try {
        return DateFormat(pattern).parseStrict(raw);
      } catch (_) {
        continue;
      }
    }
    return DateTime.tryParse(raw);
  }

  static dynamic _first(Map<String, dynamic> source, List<String> keys) {
    for (final key in keys) {
      if (source.containsKey(key) && source[key] != null) return source[key];
    }
    return '';
  }

  static String _appointmentKey(Map<String, dynamic> appointment) {
    final rawCase = appointment['rawCase'];
    final candidates = [
      appointment['jobId'],
      appointment['code'],
      if (rawCase is Map) rawCase['jobId'],
      if (rawCase is Map) rawCase['code'],
      if (rawCase is Map) rawCase['id'],
      if (rawCase is Map) rawCase['_id'],
      if (rawCase is Map) rawCase['messageRef'],
    ];
    for (final candidate in candidates) {
      final value = candidate?.toString().trim() ?? '';
      if (value.isNotEmpty) return value;
    }
    return '';
  }

  static String _caseIdentity(Map<String, dynamic> source) {
    final direct = _string(_first(source, const [
      'code',
      'id',
      '_id',
      'messageRef',
    ]));
    if (direct.isNotEmpty) return direct;
    return [
      _string(_first(source, const ['clientCode'])),
      _string(_first(source, const ['lawyerCode'])),
      _dateString(_first(source, const ['caseDate', 'appointmentDate'])),
      _timeString(_first(source, const ['startTime'])),
      _timeString(_first(source, const ['endTime'])),
    ].where((part) => part.isNotEmpty).join('|');
  }

  static String _string(dynamic value) => value?.toString().trim() ?? '';

  static String _dateString(dynamic value) {
    final raw = _string(value);
    final parsed = parseAppointmentDate(raw);
    if (parsed == null) return raw;
    return DateFormat('dd/MM/yyyy').format(parsed);
  }

  static String _timeString(dynamic value) {
    final raw = _string(value).replaceAll('.', ':');
    final parsed = _parseTime(raw);
    if (parsed == null) return raw;
    return '${parsed.hour.toString().padLeft(2, '0')}:${parsed.minute.toString().padLeft(2, '0')}';
  }

  static _ClockTime? _parseTime(String value) {
    final raw = value.trim().replaceAll('.', ':');
    if (raw.isEmpty) return null;
    final parts = raw.split(':');
    if (parts.length < 2) return null;
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) return null;
    if (hour < 0 || hour > 23 || minute < 0 || minute > 59) return null;
    return _ClockTime(hour, minute);
  }

  static String _appointmentTime(String start, String end) {
    if (start.isEmpty && end.isEmpty) return '';
    if (end.isEmpty) return start.replaceAll(':', '.');
    return '${start.replaceAll(':', '.')} - ${end.replaceAll(':', '.')}';
  }

  static int _durationMinutes(_ClockTime? start, _ClockTime? end) {
    if (start == null || end == null) return 60;
    final startMinutes = start.hour * 60 + start.minute;
    final endMinutes = end.hour * 60 + end.minute;
    if (endMinutes <= startMinutes) return 60;
    return endMinutes - startMinutes;
  }

  static bool _isPaid(dynamic value) {
    if (value is bool) return value;
    final raw = value?.toString().trim().toLowerCase() ?? '';
    return raw == 'true' || raw == '1' || raw == 'paid';
  }

  static String _appointmentStatus(dynamic value) {
    final raw = value?.toString().trim() ?? '';
    if (raw == '3' || raw.toLowerCase() == 'done') return '3';
    return '2';
  }

  static String _jobStatus(dynamic value) {
    final raw = value?.toString().trim().toLowerCase() ?? '';
    if (raw == '1' || raw == 'pending') return 'pending';
    if (raw == '2' || raw == 'confirmed' || raw == 'accepted') {
      return 'confirmed';
    }
    if (raw == '3' || raw == 'in_session') return 'in_session';
    if (raw == '4' || raw == 'done' || raw == 'success') return 'done';
    if (raw == '5' || raw == 'rejected' || raw == 'cancelled') {
      return 'rejected';
    }
    return 'pending';
  }
}

class _ClockTime {
  const _ClockTime(this.hour, this.minute);

  final int hour;
  final int minute;
}
