import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

class VerifiedLawyerBadge extends StatelessWidget {
  final bool isVerified;
  final bool isPro;
  final double size;

  const VerifiedLawyerBadge({
    super.key,
    this.isVerified = false,
    this.isPro = false,
    this.size = 16,
  });

  @override
  Widget build(BuildContext context) {
    if (!isVerified && !isPro) return const SizedBox.shrink();

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (isVerified)
          _chip(
            icon: Icons.verified_rounded,
            label: 'verifiedLawyer'.tr(),
            color: const Color(0xFF2E7D32),
          ),
        if (isVerified && isPro) const SizedBox(width: 4),
        if (isPro)
          _chip(
            icon: Icons.workspace_premium_rounded,
            label: 'Pro',
            color: const Color(0xFF0262EC),
          ),
      ],
    );
  }

  Widget _chip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: size, color: color),
          const SizedBox(width: 3),
          Text(
            label,
            style: TextStyle(
              fontSize: size - 3,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
