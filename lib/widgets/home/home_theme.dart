import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Design tokens หน้า Home — สไตล์ Aurora Bento
/// มุมโค้งแยกตามชั้น: sheet > card > inner > chip
abstract final class HomeTheme {
  // ── Colors ──────────────────────────────────────────────
  static const primary = Color(0xFF1D4ED8);
  static const primaryLight = Color(0xFF3B82F6);
  static const accent = Color(0xFF06B6D4);
  static const violet = Color(0xFF7C3AED);
  static const ink = Color(0xFF0F172A);
  static const slate = Color(0xFF64748B);
  static const muted = Color(0xFF94A3B8);
  static const line = Color(0xFFE2E8F0);
  static const surface = Color(0xFFF8FAFC);
  static const card = Colors.white;

  static const pageBgTop = Color(0xFFDBEAFE);
  static const pageBgMid = Color(0xFFE0F2FE);
  static const pageBgBottom = Color(0xFFF1F5F9);

  // ── Radius scale (เก็บรายละเอียดมุมแต่ละชั้น) ─────────
  /// sheet หลักที่โค้งด้านบน
  static const radiusSheet = 28.0;
  /// การ์ดใหญ่: action, เคส, ทนาย, banner
  static const radiusCardLg = 20.0;
  /// การ์ดกลาง: welcome, scope selector
  static const radiusCardMd = 16.0;
  /// tile เล็ก: หมวดกฎหมาย, icon box
  static const radiusCardSm = 12.0;
  /// chip / badge / ปุ่มมน
  static const radiusChip = 10.0;
  static const radiusPill = 999.0;

  // legacy aliases
  static const radiusLg = radiusSheet;
  static const radiusMd = radiusCardLg;
  static const radiusSm = radiusCardSm;

  static BorderRadius get brSheet =>
      const BorderRadius.vertical(top: Radius.circular(radiusSheet));
  static BorderRadius get brCardLg => BorderRadius.circular(radiusCardLg);
  static BorderRadius get brCardMd => BorderRadius.circular(radiusCardMd);
  static BorderRadius get brCardSm => BorderRadius.circular(radiusCardSm);
  static BorderRadius get brChip => BorderRadius.circular(radiusChip);

  // ── Shadows ─────────────────────────────────────────────
  static List<BoxShadow> softShadow({Color? tint, double y = 10}) => [
        BoxShadow(
          color: (tint ?? primary).withValues(alpha: 0.10),
          blurRadius: 24,
          offset: Offset(0, y),
        ),
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.04),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ];

  static List<BoxShadow> cardShadow({Color? color, double blur = 18}) =>
      softShadow(tint: color, y: 8);

  static List<BoxShadow> glowShadow(Color color) => [
        BoxShadow(
          color: color.withValues(alpha: 0.35),
          blurRadius: 20,
          offset: const Offset(0, 8),
        ),
      ];

  // ── Card decorations ────────────────────────────────────
  static BoxDecoration cardDecoration({
    Color? color,
    Gradient? gradient,
    double radius = radiusCardLg,
    Color? borderColor,
    double borderWidth = 1,
    List<BoxShadow>? shadows,
    Color? shadowTint,
  }) {
    return BoxDecoration(
      color: gradient == null ? (color ?? card) : null,
      gradient: gradient,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(
        color: borderColor ?? line.withValues(alpha: 0.9),
        width: borderWidth,
      ),
      boxShadow: shadows ?? softShadow(tint: shadowTint),
    );
  }

  static BoxDecoration frostedCard({
    double radius = radiusCardLg,
    Color? borderColor,
  }) =>
      cardDecoration(
        color: card.withValues(alpha: 0.96),
        radius: radius,
        borderColor: borderColor ?? Colors.white.withValues(alpha: 0.8),
        shadows: [
          BoxShadow(
            color: primary.withValues(alpha: 0.06),
            blurRadius: 30,
            offset: const Offset(0, 12),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      );

  static BoxDecoration pageBackground() => const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [pageBgTop, pageBgMid, pageBgBottom],
          stops: [0.0, 0.45, 1.0],
        ),
      );

  static BoxDecoration contentSheet() => BoxDecoration(
        color: surface.withValues(alpha: 0.55),
        borderRadius: brSheet,
        border: Border(
          top: BorderSide(color: Colors.white.withValues(alpha: 0.85)),
        ),
        boxShadow: [
          BoxShadow(
            color: primary.withValues(alpha: 0.08),
            blurRadius: 40,
            offset: const Offset(0, -10),
          ),
        ],
      );

  static const categoryTints = [
    Color(0xFFFEE2E2),
    Color(0xFFDBEAFE),
    Color(0xFFD1FAE5),
    Color(0xFFFEF3C7),
  ];
  static const categoryIconColors = [
    Color(0xFFDC2626),
    Color(0xFF2563EB),
    Color(0xFF059669),
    Color(0xFFD97706),
  ];
}

/// การ์ดมาตรฐาน — ใช้ radius/shadow เดียวกันทั้งหน้า
class HomeCard extends StatelessWidget {
  const HomeCard({
    super.key,
    required this.child,
    this.onTap,
    this.radius = HomeTheme.radiusCardLg,
    this.padding,
    this.gradient,
    this.color,
    this.borderColor,
    this.shadowTint,
    this.margin,
  });

  final Widget child;
  final VoidCallback? onTap;
  final double radius;
  final EdgeInsetsGeometry? padding;
  final Gradient? gradient;
  final Color? color;
  final Color? borderColor;
  final Color? shadowTint;
  final EdgeInsetsGeometry? margin;

  @override
  Widget build(BuildContext context) {
    final content = Container(
      margin: margin,
      padding: padding,
      decoration: HomeTheme.cardDecoration(
        radius: radius,
        gradient: gradient,
        color: color,
        borderColor: borderColor,
        shadowTint: shadowTint,
      ),
      child: child,
    );

    if (onTap == null) return content;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(radius),
        child: content,
      ),
    );
  }
}

/// หัวข้อ section
class HomeSectionHeader extends StatelessWidget {
  const HomeSectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.onMore,
    this.padding = const EdgeInsets.fromLTRB(18, 0, 18, 12),
    this.icon,
    this.accentColor,
  });

  final String title;
  final String? subtitle;
  final VoidCallback? onMore;
  final EdgeInsets padding;
  final IconData? icon;
  final Color? accentColor;

  @override
  Widget build(BuildContext context) {
    final accent = accentColor ?? HomeTheme.primary;

    return Padding(
      padding: padding,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 4,
            height: 28,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [accent, HomeTheme.accent],
              ),
              borderRadius: HomeTheme.brChip,
            ),
          ),
          const SizedBox(width: 10),
          if (icon != null) ...[
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.1),
                borderRadius: HomeTheme.brCardSm,
                border: Border.all(color: accent.withValues(alpha: 0.12)),
              ),
              child: Icon(icon, size: 17, color: accent),
            ),
            const SizedBox(width: 10),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.prompt(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: HomeTheme.ink,
                    letterSpacing: -0.3,
                  ),
                ),
                if (subtitle != null && subtitle!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    style: GoogleFonts.prompt(
                      fontSize: 12,
                      color: HomeTheme.slate,
                      height: 1.35,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (onMore != null)
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onMore,
                borderRadius: BorderRadius.circular(HomeTheme.radiusPill),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(HomeTheme.radiusPill),
                    border: Border.all(color: accent.withValues(alpha: 0.14)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'viewAll'.tr(),
                        style: GoogleFonts.prompt(
                          fontSize: 12,
                          color: accent,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(width: 3),
                      Icon(Icons.arrow_forward_rounded, size: 14, color: accent),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// แถบต้อนรับ — gradient card
class HomeWelcomeStrip extends StatelessWidget {
  const HomeWelcomeStrip({
    super.key,
    required this.isGuest,
    required this.name,
    required this.userType,
  });

  final bool isGuest;
  final String name;
  final String userType;

  @override
  Widget build(BuildContext context) {
    final greeting = isGuest
        ? 'homeWelcomeGuest'.tr()
        : 'homeWelcomeUser'
            .tr(args: [name.isNotEmpty ? name : 'defaultUser'.tr()]);
    final hint = isGuest
        ? 'homeWelcomeGuestHint'.tr()
        : (userType == 'lawyer'
            ? 'homeWelcomeLawyerHint'.tr()
            : 'homeWelcomeUserHint'.tr());

    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 2, 18, 14),
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF1E3A8A), Color(0xFF1D4ED8), Color(0xFF2563EB)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: HomeTheme.brCardMd,
          boxShadow: HomeTheme.glowShadow(HomeTheme.primary),
        ),
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: HomeTheme.brCardSm,
                border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
              ),
              child: Icon(
                isGuest
                    ? Icons.handshake_rounded
                    : (userType == 'lawyer'
                        ? Icons.gavel_rounded
                        : Icons.verified_user_rounded),
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    greeting,
                    style: GoogleFonts.prompt(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    hint,
                    style: GoogleFonts.prompt(
                      fontSize: 12,
                      color: Colors.white.withValues(alpha: 0.82),
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// พื้นหลัง aurora สำหรับหน้า home
class HomeAuroraBackground extends StatelessWidget {
  const HomeAuroraBackground({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(decoration: HomeTheme.pageBackground()),
        Positioned(
          top: -60,
          right: -40,
          child: Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: HomeTheme.accent.withValues(alpha: 0.18),
            ),
          ),
        ),
        Positioned(
          top: 80,
          left: -50,
          child: Container(
            width: 160,
            height: 160,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: HomeTheme.violet.withValues(alpha: 0.10),
            ),
          ),
        ),
        child,
      ],
    );
  }
}
