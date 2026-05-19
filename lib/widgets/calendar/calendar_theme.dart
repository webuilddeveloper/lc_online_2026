// ─── calendar_theme.dart ──────────────────────────────────────────────────────
// สี + ค่าคงที่ + helpers (locale-aware ผ่าน tr())
// ─────────────────────────────────────────────────────────────────────────────

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

// ─── Palette ──────────────────────────────────────────────────────────────────
const kBg = Color(0xFFFFFFFF);
const kSurface = Color(0xFFEEF2F5);
const kBorder = Color(0xFFE0E6ED);
const kPrimary = Color(0xFF0262EC);
const kText = Color(0xFF0D1B2A);
const kSub = Color(0xFF6B7A99);

// ─── Event colors pool ────────────────────────────────────────────────────────
const List<Color> kEventColors = [
  Color(0xFF4A8CFF),
  Color(0xFF34A853),
  Color(0xFF9B59B6),
  Color(0xFFE67E22),
  Color(0xFF1ABC9C),
  Color(0xFFE74C3C),
];

const kTimelineColor = Color(0xFF0262EC);

// ─── Timeline layout constants ────────────────────────────────────────────────
const double kHourHeight = 64.0;
const double kTimeAxisWidth = 62.0;
const int kStartHour = 8;
const int kEndHour = 21;
const int kTotalHours = kEndHour - kStartHour + 1;

// ─── Year helper ──────────────────────────────────────────────────────────────
/// ปีที่แสดงพร้อม prefix: ไทย = "พ.ศ. 2569", EN = "2026"
String calYearLabel(int year) {
  final offset = int.tryParse('calendar.yearOffset'.tr()) ?? 0;
  final suffix = 'calendar.yearSuffix'.tr();
  final y = year + offset;
  return suffix.isEmpty ? '$y' : '$suffix $y';
}

// ─── Period helpers ───────────────────────────────────────────────────────────
Color periodColor(int startHour) {
  if (startHour >= 8 && startHour < 12) return const Color(0xFF34A853);
  if (startHour >= 12 && startHour < 18) return const Color(0xFFE67E22);
  return const Color(0xFF4A8CFF);
}

String periodLabel(int startHour) {
  if (startHour >= 8 && startHour < 12) return 'calendar.periodMorning'.tr();
  if (startHour >= 12 && startHour < 18) return 'calendar.periodAfternoon'.tr();
  return 'calendar.periodEvening'.tr();
}
