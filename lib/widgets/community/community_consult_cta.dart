import 'package:LawyerOnline/law_type_all_page.dart';
import 'package:LawyerOnline/lawyer-online-list.dart';
import 'package:LawyerOnline/shared/app_typography.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// ปุ่ม CTA จาก community → ค้นหาทนาย / เปิดเคส
class CommunityConsultCta extends StatelessWidget {
  final String? subTopicCode;
  final String? subTopicTitle;

  const CommunityConsultCta({
    super.key,
    this.subTopicCode,
    this.subTopicTitle,
  });

  static const _primary = Color(0xFF0262EC);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF2F6FF),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _primary.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.gavel_rounded, color: _primary, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'communityCtaTitle'.tr(),
                  style: AppTypography.prompt(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: const Color(0xFF1A2340),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text('communityCtaSubtitle'.tr(), style: AppTypography.hint()),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => LawyerOnlineList(
                          subTopic: subTopicCode,
                        ),
                      ),
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _primary,
                    side: const BorderSide(color: _primary),
                  ),
                  child: Text(
                    'communityCtaFindLawyer'.tr(),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const LawTypeAllPage(),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primary,
                  ),
                  child: Text(
                    'openCase'.tr(),
                    style: AppTypography.prompt(
                      fontSize: 14,
                      color:  Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
