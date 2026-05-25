class UserCaseAdapter {
  const UserCaseAdapter._();

  static List<Map<String, dynamic>> fromJobs(List<Map<String, dynamic>> jobs) {
    return jobs.map(fromJob).toList();
  }

  static Map<String, dynamic> fromJob(Map<String, dynamic> job) {
    final jobStatus = job['status']?.toString() ?? 'pending';
    final jobSource = (job['jobSource'] ?? 'urgent').toString();
    final userStatus = _toUserStatus(jobStatus, jobSource);
    final lawyer = Map<String, dynamic>.from(
      (job['lawyerModel'] as Map?) ?? const <String, dynamic>{},
    );
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
