import 'package:LawyerOnline/shared/responsive/res_layout.dart';
import 'package:flutter/material.dart';

// ══════════════════════════════════════════════════════════
//  RV (ResponsiveValues) — ค่า UI ที่เปลี่ยนตาม breakpoint
//  ใช้งาน: RV.pagePadding(context), RV.cardColumns(context)
//  Breakpoints (จาก res_layout.dart):
//    Mobile  < 600px
//    Tablet  600–1099px
//    Desktop ≥ 1100px
// ══════════════════════════════════════════════════════════

class RV {
  RV._();

  // ── Spacing ───────────────────────────────────────────
  /// padding แนวนอนหลักของทุกหน้า
  static double pagePadding(BuildContext context) {
    if (ResponsiveLayout.isDesktop(context)) return 48;
    if (ResponsiveLayout.isTablet(context)) return 32;
    return 18;
  }

  /// gap ระหว่าง card
  static double cardGap(BuildContext context) {
    if (ResponsiveLayout.isDesktop(context)) return 20;
    if (ResponsiveLayout.isTablet(context)) return 16;
    return 12;
  }

  /// padding ภายใน card
  static EdgeInsets cardPadding(BuildContext context) {
    if (ResponsiveLayout.isDesktop(context)) {
      return const EdgeInsets.symmetric(horizontal: 24, vertical: 20);
    }
    if (ResponsiveLayout.isTablet(context)) {
      return const EdgeInsets.symmetric(horizontal: 18, vertical: 16);
    }
    return const EdgeInsets.symmetric(horizontal: 14, vertical: 12);
  }

  // ── Layout ────────────────────────────────────────────
  /// จำนวน column ของ grid card
  static int cardColumns(BuildContext context) {
    if (ResponsiveLayout.isDesktop(context)) return 3;
    if (ResponsiveLayout.isTablet(context)) return 2;
    return 1;
  }

  /// ความกว้าง content สูงสุด (desktop จำกัดไม่ให้กว้างเกิน)
  static double maxContentWidth(BuildContext context) {
    if (ResponsiveLayout.isDesktop(context)) return 1200;
    if (ResponsiveLayout.isTablet(context)) return double.infinity;
    return double.infinity;
  }

  /// ความกว้าง sidebar บน desktop
  static double sidebarWidth(BuildContext context) {
    if (ResponsiveLayout.isDesktop(context)) return 220;
    return 0;
  }

  // ── Typography ────────────────────────────────────────
  static double titleSize(BuildContext context) {
    if (ResponsiveLayout.isDesktop(context)) return 22;
    if (ResponsiveLayout.isTablet(context)) return 19;
    return 16;
  }

  static double subtitleSize(BuildContext context) {
    if (ResponsiveLayout.isDesktop(context)) return 15;
    if (ResponsiveLayout.isTablet(context)) return 13;
    return 12;
  }

  static double bodySize(BuildContext context) {
    if (ResponsiveLayout.isDesktop(context)) return 15;
    if (ResponsiveLayout.isTablet(context)) return 14;
    return 13;
  }

  // ── AppBar ────────────────────────────────────────────
  static double appBarHeight(BuildContext context) {
    if (ResponsiveLayout.isDesktop(context)) return 72;
    if (ResponsiveLayout.isTablet(context)) return 72;
    return 80;
  }

  // ── Banner ────────────────────────────────────────────
  static double bannerHeight(BuildContext context) {
    if (ResponsiveLayout.isDesktop(context)) return 200;
    if (ResponsiveLayout.isTablet(context)) return 170;
    return 140;
  }

  // ── Helper: แสดง TopBar หรือ BottomNav ───────────────
  static bool showTopNav(BuildContext context) =>
      ResponsiveLayout.isDesktop(context);

  static bool showBottomNav(BuildContext context) =>
      !ResponsiveLayout.isDesktop(context);
}