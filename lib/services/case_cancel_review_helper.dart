/// ช่วยตัดสินว่าเคสต้องส่งคำขอยกเลิกให้แอดมินหรือยกเลิกทันที
class CaseCancelReviewHelper {
  CaseCancelReviewHelper._();

  static int caseStatusInt(Map<String, dynamic> source) {
    final value = source['caseStatus'] ?? source['caseStatusInt'];
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? -1;
  }

  static int caseTypeInt(Map<String, dynamic> source) {
    final value = source['caseType'];
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 1;
  }

  static bool isUrgentCase(Map<String, dynamic> source) {
    final t = caseTypeInt(source);
    return t == 2 || t == 0;
  }

  static bool isPaid(Map<String, dynamic> source) {
    return source['isPay'] == true;
  }

  static String reviewStatus(Map<String, dynamic> source) =>
      source['cancelReviewStatus']?.toString().trim() ?? '';

  static bool isReviewPending(Map<String, dynamic> source) =>
      reviewStatus(source) == 'pending';

  static bool isReviewApproved(Map<String, dynamic> source) =>
      reviewStatus(source) == 'approved';

  static bool isReviewRejected(Map<String, dynamic> source) =>
      reviewStatus(source) == 'rejected';

  static bool hasActiveReview(Map<String, dynamic> source) {
    final s = reviewStatus(source);
    return s == 'pending' || s == 'approved' || s == 'rejected';
  }

  /// ทนายยกเลิกนัดล่วงหน้า (caseType=1) สถานะ 2/3 → รอแอดมิน
  /// ลูกความยกเลิกตอนกำลังปรึกษา (สถานะ 3) → รอแอดมิน (เดิม)
  static bool needsAdminCancelReview({
    required Map<String, dynamic> caseData,
    required String userType,
  }) {
    final status = caseStatusInt(caseData);
    if (userType == 'lawyer') {
      if (isUrgentCase(caseData)) return status == 3;
      return status == 2 || status == 3;
    }
    return status == 3;
  }
}
