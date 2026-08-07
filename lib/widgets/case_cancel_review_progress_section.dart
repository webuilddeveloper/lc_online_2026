import 'package:LawyerOnline/services/case_cancel_review_helper.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// แสดงขั้นตอนการยกเลิกที่รอแอดมินพิจารณา
class CaseCancelReviewProgressSection extends StatelessWidget {
  const CaseCancelReviewProgressSection({
    super.key,
    required this.caseData,
    this.fallbackData,
    this.showRefundNote = false,
  });

  final Map<String, dynamic> caseData;
  final Map<String, dynamic>? fallbackData;
  final bool showRefundNote;

  Map<String, dynamic> get _data {
    final merged = <String, dynamic>{};
    if (fallbackData != null) merged.addAll(fallbackData!);
    merged.addAll(caseData);
    return merged;
  }

  @override
  Widget build(BuildContext context) {
    if (!CaseCancelReviewHelper.hasActiveReview(_data)) {
      return const SizedBox.shrink();
    }

    final status = CaseCancelReviewHelper.reviewStatus(_data);
    final isPaid = CaseCancelReviewHelper.isPaid(_data);
    final requestedByLawyer =
        (_data['cancelRequestedUserType']?.toString() ?? '') == 'lawyer';

    final stepSubmitted = true;
    final stepAdminActive = status == 'pending';
    final stepAdminDone = status == 'approved' || status == 'rejected';
    final stepDecisionDone = stepAdminDone;
    final stepRefundDone = status == 'approved' && isPaid;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7ED),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFDBA74)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.timeline_rounded,
                  size: 18, color: Color(0xFFC2410C)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'cancelReviewProgressTitle'.tr(),
                  style: GoogleFonts.prompt(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF9A3412),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _step(
            index: 1,
            title: 'cancelReviewStepSubmitted'.tr(),
            subtitle: _data['reasonCancel']?.toString().trim().isNotEmpty == true
                ? _data['reasonCancel'].toString().trim()
                : 'cancelReviewStepSubmittedDesc'.tr(),
            state: _StepState.done,
          ),
          _connector(done: stepSubmitted),
          _step(
            index: 2,
            title: 'cancelReviewStepAdmin'.tr(),
            subtitle: stepAdminActive
                ? 'cancelReviewStepAdminPending'.tr()
                : 'cancelReviewStepAdminDone'.tr(),
            state: stepAdminDone
                ? _StepState.done
                : (stepAdminActive ? _StepState.active : _StepState.todo),
          ),
          if (showRefundNote && isPaid && requestedByLawyer) ...[
            _connector(done: stepAdminDone),
            _step(
              index: 3,
              title: 'cancelReviewStepRefund'.tr(),
              subtitle: status == 'approved'
                  ? 'cancelReviewRefundApproved'.tr()
                  : (status == 'pending'
                      ? 'cancelReviewRefundPending'.tr()
                      : 'cancelReviewRefundRejected'.tr()),
              state: stepRefundDone
                  ? _StepState.done
                  : (status == 'pending' && stepAdminActive
                      ? _StepState.todo
                      : (status == 'approved'
                          ? _StepState.active
                          : _StepState.todo)),
            ),
          ] else ...[
            _connector(done: stepAdminDone),
            _step(
              index: 3,
              title: 'cancelReviewStepDecision'.tr(),
              subtitle: status == 'approved'
                  ? 'cancelReviewDecisionApproved'.tr()
                  : (status == 'rejected'
                      ? 'cancelReviewDecisionRejected'.tr()
                      : 'cancelReviewDecisionWaiting'.tr()),
              state: stepDecisionDone
                  ? _StepState.done
                  : (stepAdminActive ? _StepState.todo : _StepState.active),
            ),
          ],
          if (showRefundNote && isPaid && requestedByLawyer) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.info_outline_rounded,
                      size: 16, color: Color(0xFF0262EC)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'cancelReviewRefundNote24h'.tr(),
                      style: GoogleFonts.prompt(
                        fontSize: 12,
                        height: 1.45,
                        color: const Color(0xFF334155),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _connector({required bool done}) {
    return Padding(
      padding: const EdgeInsets.only(left: 15),
      child: Container(
        width: 2,
        height: 14,
        color: done ? const Color(0xFF059669) : const Color(0xFFE2E8F0),
      ),
    );
  }

  Widget _step({
    required int index,
    required String title,
    required String subtitle,
    required _StepState state,
  }) {
    final (Color bg, Color fg, IconData icon) = switch (state) {
      _StepState.done => (
          const Color(0xFFECFDF5),
          const Color(0xFF059669),
          Icons.check_circle_rounded
        ),
      _StepState.active => (
          const Color(0xFFEFF6FF),
          const Color(0xFF0262EC),
          Icons.radio_button_checked_rounded
        ),
      _StepState.todo => (
          const Color(0xFFF1F5F9),
          const Color(0xFF94A3B8),
          Icons.radio_button_unchecked_rounded
        ),
    };

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
          child: Icon(icon, size: 18, color: fg),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$index. $title',
                style: GoogleFonts.prompt(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: GoogleFonts.prompt(
                  fontSize: 12,
                  height: 1.4,
                  color: const Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

enum _StepState { todo, active, done }
