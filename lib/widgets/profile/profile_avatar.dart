import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:LawyerOnline/subscribe/subscribe_theme.dart';
import 'package:easy_localization/easy_localization.dart';

const _kPrimary = Color(0xFF0262EC);
const _kGreen = Color(0xFF059669);
const _kGold = Color(0xFFF5A623);

class ProfileAvatar extends StatelessWidget {
  final String imageUrl;
  final String typeLogin;
  final bool isOnline;
  final double size;
  final VoidCallback? onProfileTap;

  const ProfileAvatar({
    super.key,
    required this.imageUrl,
    required this.typeLogin,
    this.isOnline = false,
    this.size = 46,
    this.onProfileTap,
  });

  @override
  Widget build(BuildContext context) {
    final innerSize = size - 4;
    return MouseRegion(
      cursor: onProfileTap != null
          ? SystemMouseCursors.click
          : SystemMouseCursors.basic,
      child: GestureDetector(
        onTap: onProfileTap,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isOnline ? _kGreen : _kPrimary,
                  width: isOnline ? 2.5 : 1,
                ),
                boxShadow: isOnline
                    ? [
                        BoxShadow(
                          color: _kGreen.withOpacity(0.4),
                          blurRadius: 6,
                          spreadRadius: 1,
                        )
                      ]
                    : [],
              ),
              child: Center(
                child: SizedBox(
                  width: innerSize,
                  height: innerSize,
                  child: ClipOval(
                    child: imageUrl.isNotEmpty
                        ? (imageUrl.startsWith('http') || imageUrl.startsWith('https'))
                            ? Image.network(imageUrl, fit: BoxFit.cover)
                            : Image.asset(imageUrl, fit: BoxFit.cover)
                        : Padding(
                            padding: const EdgeInsets.all(3.0),
                            child: Image.asset(
                              'assets/icons/profile.png',
                              fit: BoxFit.cover,
                            ),
                          ),
                  ),
                ),
              ),
            ),
            if (isOnline)
              Positioned(
                bottom: -4,
                right: -4,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: _kGreen,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 1.5),
                  ),
                  child: const Icon(
                    Icons.balance_rounded,
                    color: Colors.white,
                    size: 14,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class ProfileMemberBadge extends StatelessWidget {
  final String userType;
  final bool isPro;

  const ProfileMemberBadge({
    super.key,
    required this.userType,
    this.isPro = false,
  });

  @override
  Widget build(BuildContext context) {
    final label = userType == 'lawyer' ? 'role.lawyer'.tr() : 'role.client'.tr();
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _kGold),
          ),
          child: Text(
            label,
            style: GoogleFonts.prompt(
              color: _kGold,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        if (isPro) ...[
          const SizedBox(width: 6),
          const ProBadge(),
        ],
      ],
    );
  }
}
