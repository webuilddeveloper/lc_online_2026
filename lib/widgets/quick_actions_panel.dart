import 'package:LawyerOnline/calendar.dart';
import 'package:LawyerOnline/message.dart';
import 'package:LawyerOnline/referral_page.dart';
import 'package:LawyerOnline/shared/app_typography.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// Quick actions ในแอพ (ทางลัดไปฟีเจอร์หลัก)
class QuickActionsPanel extends StatelessWidget {
  const QuickActionsPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final items = [
      _QuickAction(
        icon: Icons.chat_bubble_outline_rounded,
        label: 'quickActionChat'.tr(),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const MessagePage()),
        ),
      ),
      _QuickAction(
        icon: Icons.calendar_month_outlined,
        label: 'quickActionCalendar'.tr(),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => CalendarPage()),
        ),
      ),
      _QuickAction(
        icon: Icons.card_giftcard_outlined,
        label: 'quickActionReferral'.tr(),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ReferralPage()),
        ),
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: Text(
            'quickActionsTitle'.tr(),
            style: AppTypography.prompt(
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        SizedBox(
          height: 96,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (_, i) => items[i],
          ),
        ),
      ],
    );
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: 108,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE8EDF3)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: const Color(0xFF0262EC)),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.prompt(fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }
}
