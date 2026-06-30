import 'package:LawyerOnline/models/lawyer/lawyer_model.dart';
import 'package:LawyerOnline/models/user_model.dart';
import 'package:LawyerOnline/repositories/register_account_repository.dart';
import 'package:intl/intl.dart';

abstract class LawyerRepository {
  Future<List<LawyerModel>> searchLawyers({
    String topic = '',
    String subTopic = '',
    String province = '',
    String keyword = '',
    bool availableOnly = false,
  });
}

class ApiLawyerRepository implements LawyerRepository {
  const ApiLawyerRepository({
    RegisterAccountRepository accountRepository =
        const ApiRegisterAccountRepository(),
  }) : _accountRepository = accountRepository;

  final RegisterAccountRepository _accountRepository;

  @override
  Future<List<LawyerModel>> searchLawyers({
    String topic = '',
    String subTopic = '',
    String province = '',
    String keyword = '',
    bool availableOnly = false,
  }) async {
    final accounts = await _accountRepository.readAccounts(
      userType: 'lawyer',
      keySearch: keyword,
      limit: 100,
    );

    final normalizedKeyword = keyword.trim().toLowerCase();
    final normalizedProvince = province.trim().toLowerCase();
    return accounts
        .where((account) => account.code.trim().isNotEmpty)
        .map(_lawyerFromAccount)
        .where((lawyer) {
      if (availableOnly && !lawyer.isOnline) {
        return false;
      }
      if (normalizedProvince.isNotEmpty &&
          lawyer.province.toLowerCase() != normalizedProvince) {
        return false;
      }

      final searchText = [
        lawyer.name,
        lawyer.title,
        lawyer.specialty,
        lawyer.province,
      ].join(' ').toLowerCase();

      if (normalizedKeyword.isNotEmpty &&
          !searchText.contains(normalizedKeyword)) {
        return false;
      }
      return true;
    }).toList(growable: false);
  }

  LawyerModel _lawyerFromAccount(UserModel account) {
    final name = account.fullName.trim().isNotEmpty
        ? account.fullName.trim()
        : account.email.trim();
    final specialty =
        account.category.trim().isNotEmpty ? account.category.trim() : '-';
    final avatar = name.trim().isNotEmpty ? name.trim()[0] : 'L';
    final imageUrl = account.imageUrl.trim();

    return LawyerModel(
      code: account.code.trim(),
      name: name,
      title: 'Lawyer',
      specialty: specialty,
      experience: '-',
      experienceYears: 0,
      rating: 0,
      reviews: 0,
      price: 0,
      isOnline: account.isActive || account.status.trim().isEmpty,
      province: account.address.trim(),
      distance: '-',
      distanceKm: 0,
      eta: '-',
      office: account.address.trim(),
      avatar: avatar,
      color: 0xFF0262EC,
      imageUrl: imageUrl.startsWith('assets/')
          ? imageUrl
          : 'assets/images/lawyer-avatar-1.png',
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

  static Map<DateTime, List<dynamic>> eventMapFromAppointments(
    List<dynamic> appointments,
  ) {
    final result = <DateTime, List<dynamic>>{};
    
    if (appointments.isEmpty) {
      return result;
    }

    for (final appointment in appointments) {
      try {
        if (appointment is! Map) continue;

        final dateStr = appointment['appointmentDate']?.toString() ?? '';
        if (dateStr.isEmpty) continue;

        final date = parseAppointmentDate(dateStr);
        if (date == null) continue;

        final key = DateTime(date.year, date.month, date.day);
        result.putIfAbsent(key, () => []).add(appointment);
      } catch (e) {
        print('⚠️ Error mapping appointment: $e');
        continue;
      }
    }

    return result;
  }

  static List<dynamic> mergeAppointments(
    List<dynamic>? primary,
    List<dynamic>? secondary,
  ) {
    final result = <Map<String, dynamic>>[];
    final seen = <String>{};

    final allAppointments = [
      ...(primary ?? []),
      ...(secondary ?? []),
    ];

    for (final appointment in allAppointments) {
      if (appointment is! Map) continue;

      try {
        final key = _appointmentKey(appointment as Map<String, dynamic>);
        if (key.isNotEmpty && !seen.add(key)) continue;
        result.add(Map<String, dynamic>.from(appointment));
      } catch (e) {
        print('⚠️ Error merging appointment: $e');
        continue;
      }
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
    
    try {
      return DateTime.parse(raw);
    } catch (_) {
      return null;
    }
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