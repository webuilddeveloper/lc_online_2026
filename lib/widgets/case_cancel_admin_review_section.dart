import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// ข้อมูลผลพิจารณาการยกเลิกจากแอดมิน (อ่านจาก case document)
class CaseCancelReviewData {
  CaseCancelReviewData({
    required this.reviewStatus,
    this.isReasonable,
    this.remark = '',
    this.reviewedDate = '',
    this.reviewedTime = '',
    this.requestedBy = '',
  });

  final String reviewStatus;
  final bool? isReasonable;
  final String remark;
  final String reviewedDate;
  final String reviewedTime;
  final String requestedBy;

  bool get hasAdminDecision => reviewStatus == 'approved';

  bool get hasScorePenalty => hasAdminDecision && isReasonable == false;

  static CaseCancelReviewData? fromMaps(
    Map<String, dynamic> primary, [
    Map<String, dynamic>? fallback,
  ]) {
    final merged = <String, dynamic>{};
    if (fallback != null) merged.addAll(fallback);
    merged.addAll(primary);
    return fromMap(merged);
  }

  static CaseCancelReviewData? fromMap(Map<String, dynamic> map) {
    final status = map['cancelReviewStatus']?.toString().trim() ?? '';
    if (status != 'approved') return null;

    bool? reasonable;
    final rawReasonable = map['cancelReasonIsReasonable'];
    if (rawReasonable is bool) {
      reasonable = rawReasonable;
    } else if (rawReasonable != null) {
      final text = rawReasonable.toString().toLowerCase();
      if (text == 'true') reasonable = true;
      if (text == 'false') reasonable = false;
    }

    return CaseCancelReviewData(
      reviewStatus: status,
      isReasonable: reasonable,
      remark: map['cancelReviewRemark']?.toString().trim() ?? '',
      reviewedDate: map['cancelReviewedDate']?.toString().trim() ?? '',
      reviewedTime: map['cancelReviewedTime']?.toString().trim() ?? '',
      requestedBy: map['cancelRequestedBy']?.toString().trim() ?? '',
    );
  }

  String approveLabel() => 'cancelAdminApproved'.tr();

  String reasonableLabel() {
    if (isReasonable == true) return 'cancelAdminReasonableYes'.tr();
    if (isReasonable == false) return 'cancelAdminReasonableNo'.tr();
    return '-';
  }

  String scoreImpactLabel({String? viewerUserCode}) {
    if (!hasScorePenalty) return 'cancelAdminNoPenalty'.tr();
    if (viewerUserCode != null &&
        viewerUserCode.isNotEmpty &&
        requestedBy == viewerUserCode) {
      return 'cancelAdminPenaltyYou'.tr();
    }
    return 'cancelAdminPenaltyOther'.tr();
  }

  Color reasonableColor() {
    if (isReasonable == true) return const Color(0xFF059669);
    if (isReasonable == false) return const Color(0xFFDC2626);
    return const Color(0xFF64748B);
  }

  Color scoreImpactColor() {
    if (!hasScorePenalty) return const Color(0xFF059669);
    if (hasScorePenalty) return const Color(0xFFDC2626);
    return const Color(0xFF64748B);
  }

  String reviewedAtLabel() {
    if (reviewedDate.isEmpty && reviewedTime.isEmpty) return '-';
    if (reviewedDate.isNotEmpty && reviewedTime.isNotEmpty) {
      return '$reviewedDate $reviewedTime';
    }
    return reviewedDate.isNotEmpty ? reviewedDate : reviewedTime;
  }
}

enum CaseCancelReviewLayout { client, lawyer, compact }

/// แสดงผลการพิจารณาจากแอดมินในหน้ารายละเอียดการยกเลิก
class CaseCancelAdminReviewSection extends StatelessWidget {
  const CaseCancelAdminReviewSection({
    super.key,
    required this.caseData,
    this.fallbackData,
    this.viewerUserCode,
    this.layout = CaseCancelReviewLayout.client,
  });

  final Map<String, dynamic> caseData;
  final Map<String, dynamic>? fallbackData;
  final String? viewerUserCode;
  final CaseCancelReviewLayout layout;

  @override
  Widget build(BuildContext context) {
    final review = CaseCancelReviewData.fromMaps(caseData, fallbackData);
    if (review == null) return const SizedBox.shrink();

    final children = <Widget>[
      _sectionHeader(),
      const SizedBox(height: 12),
      _row(
        label: 'cancelAdminApprove'.tr(),
        value: review.approveLabel(),
        valueColor: const Color(0xFF059669),
      ),
      _divider(),
      _row(
        label: 'cancelAdminReasonable'.tr(),
        value: review.reasonableLabel(),
        valueColor: review.reasonableColor(),
      ),
      _divider(),
      _row(
        label: 'cancelAdminScoreImpact'.tr(),
        value: review.scoreImpactLabel(viewerUserCode: viewerUserCode),
        valueColor: review.scoreImpactColor(),
      ),
      if (review.remark.isNotEmpty) ...[
        _divider(),
        _multiline(
          label: 'cancelAdminRemark'.tr(),
          value: review.remark,
        ),
      ],
      if (review.reviewedAtLabel() != '-') ...[
        _divider(),
        _row(
          label: 'cancelAdminReviewedAt'.tr(),
          value: review.reviewedAtLabel(),
        ),
      ],
    ];

    if (layout == CaseCancelReviewLayout.compact) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      );
    }

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  Widget _sectionHeader() {
    return Row(
      children: [
        Icon(
          Icons.admin_panel_settings_outlined,
          size: 16,
          color: layout == CaseCancelReviewLayout.lawyer
              ? const Color(0xFF0262EC)
              : const Color(0xFF475569),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            'cancelAdminReviewTitle'.tr(),
            style: TextStyle(
              fontSize: layout == CaseCancelReviewLayout.compact ? 12 : 13,
              fontWeight: FontWeight.w700,
              color: layout == CaseCancelReviewLayout.lawyer
                  ? const Color(0xFF1A2340)
                  : const Color(0xFF334155),
            ),
          ),
        ),
      ],
    );
  }

  Widget _row({
    required String label,
    required String value,
    Color? valueColor,
  }) {
    final labelStyle = TextStyle(
      fontSize: layout == CaseCancelReviewLayout.compact ? 11 : 12,
      color: Colors.grey[500],
      fontWeight: FontWeight.w500,
    );
    final valueStyle = TextStyle(
      fontSize: layout == CaseCancelReviewLayout.compact ? 12 : 13,
      fontWeight: FontWeight.w600,
      color: valueColor ??
          (layout == CaseCancelReviewLayout.lawyer
              ? const Color(0xFF1A2340)
              : const Color(0xFF0F172A)),
    );

    if (layout == CaseCancelReviewLayout.lawyer) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(Icons.circle, size: 6, color: Colors.grey[400]),
            const SizedBox(width: 10),
            SizedBox(width: 110, child: Text(label, style: labelStyle)),
            Expanded(
              child: Text(
                value,
                textAlign: TextAlign.end,
                style: valueStyle,
              ),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          SizedBox(width: 110, child: Text(label, style: labelStyle)),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: valueStyle,
            ),
          ),
        ],
      ),
    );
  }

  Widget _multiline({required String label, required String value}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: layout == CaseCancelReviewLayout.compact ? 11 : 12,
              color: Colors.grey[500],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Text(
              value,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[700],
                height: 1.6,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _divider() => const Divider(
        height: 1,
        thickness: 1,
        color: Color(0xFFE2E8F0),
      );
}
