import 'package:LawyerOnline/models/user_model.dart';

enum LawyerVerificationStatus {
  notApplied,
  pending,
  approved,
  rejected,
  resubmit,
}

class LawyerVerificationInfo {
  final LawyerVerificationStatus status;
  final String statusLabel;
  final String? rejectReason;
  final bool showVerifiedBadge;

  const LawyerVerificationInfo({
    required this.status,
    required this.statusLabel,
    this.rejectReason,
    this.showVerifiedBadge = false,
  });
}

class LawyerVerificationService {
  LawyerVerificationService._();

  static LawyerVerificationInfo fromUser(UserModel? user, String userType) {
    if (userType == 'lawyer') {
      return const LawyerVerificationInfo(
        status: LawyerVerificationStatus.approved,
        statusLabel: 'verified',
        showVerifiedBadge: true,
      );
    }

    final raw = user?.lawyerApplyStatus.trim().toLowerCase() ?? '';
    switch (raw) {
      case 'pending':
        return const LawyerVerificationInfo(
          status: LawyerVerificationStatus.pending,
          statusLabel: 'pending',
        );
      case 'rejected':
        return LawyerVerificationInfo(
          status: LawyerVerificationStatus.rejected,
          statusLabel: 'rejected',
          rejectReason: user?.status.trim().isNotEmpty == true
              ? user!.status
              : null,
        );
      case 'resubmit':
        return const LawyerVerificationInfo(
          status: LawyerVerificationStatus.resubmit,
          statusLabel: 'resubmit',
        );
      case 'approved':
        return const LawyerVerificationInfo(
          status: LawyerVerificationStatus.approved,
          statusLabel: 'approved',
          showVerifiedBadge: true,
        );
      default:
        return const LawyerVerificationInfo(
          status: LawyerVerificationStatus.notApplied,
          statusLabel: 'notApplied',
        );
    }
  }
}
