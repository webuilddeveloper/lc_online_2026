class UserCaseAdapter {
  const UserCaseAdapter._();

  /// แปลงข้อมูลเคสจาก API / home ให้ใช้กับ [AppointmentDetails] ได้
  static Map<String, dynamic> forAppointmentDetails(
    Map<String, dynamic> raw,
  ) {
    final data = Map<String, dynamic>.from(raw);
    final caseStatus = _asInt(data['caseStatus'] ?? data['status'], fallback: 1);
    data['caseStatus'] = caseStatus;
    data['status'] = caseStatus;

    if ((data['lawyer'] ?? '').toString().isEmpty) {
      data['lawyer'] = data['lawyerCode'] ??
          (data['lawyerModel'] is Map
              ? (data['lawyerModel'] as Map)['code']
              : null) ??
          '';
    }

    final lawyerName = data['lawyerName']?.toString() ?? '';
    data['lawyerAvatar'] ??=
        lawyerName.isNotEmpty ? lawyerName.substring(0, 1) : 'ท';

    data['caseDate'] ??= data['appointmentDate'] ?? data['caseDate'] ?? '';
    final timeRange = data['appointmentTime']?.toString() ?? '';
    if ((data['startTime'] ?? '').toString().isEmpty && timeRange.contains('-')) {
      final parts = timeRange.split('-');
      data['startTime'] = parts.first.trim();
      data['endTime'] = parts.length > 1 ? parts.last.trim() : '';
    }
    data['startTime'] ??= '';
    data['endTime'] ??= '';

    return data;
  }

  static int _asInt(dynamic value, {required int fallback}) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? fallback;
    return fallback;
  }

  static List<dynamic> fromJobs(List<dynamic> jobs) {
    return jobs.map(fromJob).toList();
  }

  static dynamic fromJob(dynamic job) {
    final jobStatus = job['status']?.toString() ?? 'pending';
    final jobSource = (job['jobSource'] ?? 'urgent').toString();
    final userStatus = _toUserStatus(jobStatus, jobSource);
    final lawyer = job['lawyerModel'];
    final lawyerCode =
        job['lawyerCode']?.toString() ?? lawyer['code']?.toString() ?? '';
    if (lawyerCode.isNotEmpty) lawyer['code'] = lawyerCode;

    return {
      'id': job['id'],
      'jobId': job['id'],
      'code': job['id'],
      'clientCode': job['clientCode'] ?? '',
      'lawyerCode': lawyerCode,
      'name': lawyer['name'] ?? '',
      'category': job['topic'] ?? '',
      'subTopic': job['subTopic'] ?? '',
      'story': job['detail'] ?? '',
      'createDate': job['requestedAt'] ?? '',
      'appointmentDate': job['date'] ?? '',
      'appointmentTime': job['time'] ?? '',
      'budget': job['budget'] ?? '',
      'jobSource': jobSource,
      'lawyerApprove': jobStatus == 'confirmed' ||
          jobStatus == 'accepted' ||
          jobStatus == 'in_session' ||
          jobStatus == 'done',
      'lawyerModel': lawyer,
      'jobStatus': jobStatus,
      'status': userStatus.$1,
      'statusText': userStatus.$2,
      'caseSuccess': jobStatus == 'done',
      // active = สามารถเปิดแชท์และพูดคุยได้ เฉพาะ in_session/accepted (urgent) เท่านั้น
      'active': jobStatus == 'in_session' || jobStatus == 'accepted',
      // chatLocked = เห็นห้องแชท์ได้แต่ยังพิมพ์ไม่ได้ (รอถึงวันนัด)
      'chatLocked': jobStatus == 'confirmed',
    };
  }

  static (String, String) _toUserStatus(String jobStatus, String jobSource) {
    if (jobSource == 'booking') {
      switch (jobStatus) {
        case 'pending':
          return ('1', 'รอทนายยืนยันนัด');
        case 'confirmed':
          return ('2', 'ยืนยันนัดแล้ว');
        case 'in_session':
          return ('3', 'กำลังปรึกษา');
        case 'done':
          return ('4', 'เสร็จสิ้น');
        case 'rejected':
          return ('5', 'ถูกปฏิเสธ');
        default:
          return ('1', 'รอทนายยืนยันนัด');
      }
    }
    // urgent
    switch (jobStatus) {
      case 'pending':
        return ('1', 'รอทนายรับเรื่อง');
      case 'accepted':
        return ('3', 'กำลังปรึกษา');
      case 'rejected':
        return ('5', 'ถูกปฏิเสธ');
      case 'done':
        return ('4', 'เสร็จสิ้น');
      default:
        return ('1', 'รอทนายรับเรื่อง');
    }
  }
}
