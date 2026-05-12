// ══════════════════════════════════════════════════════════════════════
//  subscribe_theme.dart
//  Shared palette + enums สำหรับทุกหน้าใน subscribe flow
//  Import ไฟล์เดียวแทนการ copy const ซ้ำทุกไฟล์
// ══════════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ─── Palette ─────────────────────────────────────────────────────────
const kPrimary      = Color(0xFF185FA5);
const kPrimaryLight = Color(0xFFE6F1FB);
const kPrimaryDark  = Color(0xFF0C447C);
const kGold         = Color(0xFFBA7517);
const kGoldLight    = Color(0xFFFAEEDA);
const kGreen        = Color(0xFF3B6D11);
const kGreenLight   = Color(0xFFEAF3DE);
const kSurface      = Color(0xFFF4F6FB);
const kCard         = Colors.white;
const kText         = Color(0xFF0D1B2A);
const kSub          = Color(0xFF6B7A99);
const kBorder       = Color(0xFFE2EAF4);
const kError        = Color(0xFFDC2626);

// ─── Subscription state ───────────────────────────────────────────────
/// แผนที่ user ใช้งานอยู่จริง — ดึงจาก backend/store
enum CurrentPlan { free, pro }

/// billing cycle
enum BillingCycle { monthly, yearly }

extension BillingCycleExt on BillingCycle {
  bool get isYearly  => this == BillingCycle.yearly;
  String get label   => isYearly ? 'รายปี' : 'รายเดือน';
  String get price   => isYearly ? '฿472'  : '฿590';
  String get yearly  => isYearly ? '฿5,664/ปี' : '';
  String get saving  => isYearly ? '−20%'  : '';
}
// ─── Pro Badge (reusable across all pages) ───────────────────────────
class ProBadge extends StatelessWidget {
  final double fontSize;
  const ProBadge({super.key, this.fontSize = 9});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [kPrimary, kPrimaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: kPrimary.withOpacity(0.35),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.workspace_premium_rounded,
              size: 9, color: Colors.white),
          const SizedBox(width: 3),
          Text(
            'PRO',
            style: GoogleFonts.prompt(
              fontSize: fontSize,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}