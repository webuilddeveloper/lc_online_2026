class UserCaseAdapter {
  const UserCaseAdapter._();

  static List<Map<String, dynamic>> fromJobs(List<Map<String, dynamic>> jobs) {
    return jobs.map(fromJob).toList();
  }

  static Map<String, dynamic> fromJob(Map<String, dynamic> job) {
    final jobStatus = job['status']?.toString() ?? 'pending';
    final userStatus = _toUserStatus(jobStatus);
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
      'lawyerApprove': jobStatus == 'accepted' || jobStatus == 'done',
      'lawyerModel': lawyer,
      'jobStatus': jobStatus,
      'status': userStatus.$1,
      'statusText': userStatus.$2,
      'caseSuccess': jobStatus == 'done',
      'active': jobStatus == 'accepted',
    };
  }

  static (String, String) _toUserStatus(String jobStatus) {
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
