import 'package:LawyerOnline/component/appbar.dart';
import 'package:LawyerOnline/lawyer_apply_page.dart';
import 'package:LawyerOnline/models/user_profile_store.dart';
import 'package:LawyerOnline/services/lawyer_verification_service.dart';
import 'package:LawyerOnline/shared/app_typography.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

class LawyerApplyStatusPage extends StatelessWidget {
  const LawyerApplyStatusPage({super.key});

  @override
  Widget build(BuildContext context) {
    final store = UserProfileStore.instance;
    final info = LawyerVerificationService.fromUser(
      store.user,
      store.userType,
    );

    return Scaffold(
      backgroundColor: const Color(0xFFEEF2F5),
      appBar: appBar(
        title: 'lawyerApplyStatusTitle'.tr(),
        backBtn: true,
        rightBtn: false,
        backAction: () => Navigator.pop(context),
        rightAction: () {},
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _statusIcon(info.status),
            const SizedBox(height: 16),
            Text(
              _statusTitle(info.status),
              style: AppTypography.prompt(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF1A2340),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              _statusMessage(info),
              style: AppTypography.hint(),
              textAlign: TextAlign.center,
            ),
            if (info.rejectReason != null) ...[
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFEBEE),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  info.rejectReason!,
                  style: AppTypography.prompt(
                    fontSize: 13,
                    color: const Color(0xFFC62828),
                  ),
                ),
              ),
            ],
            const Spacer(),
            if (info.status == LawyerVerificationStatus.rejected ||
                info.status == LawyerVerificationStatus.resubmit ||
                info.status == LawyerVerificationStatus.notApplied)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const LawyerApplyPage(),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0262EC),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'lawyerApplyResubmit'.tr(),
                    style: AppTypography.button(),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _statusIcon(LawyerVerificationStatus status) {
    final (icon, color) = switch (status) {
      LawyerVerificationStatus.approved => (
          Icons.verified_rounded,
          const Color(0xFF2E7D32)
        ),
      LawyerVerificationStatus.pending => (
          Icons.hourglass_top_rounded,
          const Color(0xFFF5A623)
        ),
      LawyerVerificationStatus.rejected => (
          Icons.cancel_rounded,
          const Color(0xFFD32F2F)
        ),
      LawyerVerificationStatus.resubmit => (
          Icons.upload_file_rounded,
          const Color(0xFF0262EC)
        ),
      LawyerVerificationStatus.notApplied => (
          Icons.person_add_alt_1_rounded,
          const Color(0xFF8593A8)
        ),
    };

    return Container(
      width: 88,
      height: 88,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: color, size: 42),
    );
  }

  String _statusTitle(LawyerVerificationStatus status) => switch (status) {
        LawyerVerificationStatus.approved => 'lawyerApplyApprovedTitle'.tr(),
        LawyerVerificationStatus.pending => 'lawyerApplyPendingTitle'.tr(),
        LawyerVerificationStatus.rejected => 'lawyerApplyRejectedTitle'.tr(),
        LawyerVerificationStatus.resubmit => 'lawyerApplyResubmitTitle'.tr(),
        LawyerVerificationStatus.notApplied => 'applyAsLawyer'.tr(),
      };

  String _statusMessage(LawyerVerificationInfo info) => switch (info.status) {
        LawyerVerificationStatus.approved => 'lawyerApplyApprovedMessage'.tr(),
        LawyerVerificationStatus.pending => 'lawyerApplyPendingMessage'.tr(),
        LawyerVerificationStatus.rejected => 'lawyerApplyRejectedMessage'.tr(),
        LawyerVerificationStatus.resubmit => 'lawyerApplyResubmitMessage'.tr(),
        LawyerVerificationStatus.notApplied => 'lawyerApplyDescription'.tr(),
      };
}
