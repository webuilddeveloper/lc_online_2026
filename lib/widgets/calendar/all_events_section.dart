// ─── all_events_section.dart ──────────────────────────────────────────────────
// รายการนัดหมายทั้งหมดแบบรายวัน — Mobile + Desktop variants
// ─────────────────────────────────────────────────────────────────────────────

import 'package:LawyerOnline/widgets/calendar/calendar_theme.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:table_calendar/table_calendar.dart';

// ═══════════════════════════════════════════════════════════════════════════════
//  All Appointments — Mobile (full screen)
// ═══════════════════════════════════════════════════════════════════════════════
class AllAppointmentsViewMobile extends StatelessWidget {
  final Map<DateTime, List<dynamic>> itemEvents;
  final ScrollController scrollController;
  final void Function(Map ev) onEventTap;

  const AllAppointmentsViewMobile({
    super.key,
    required this.itemEvents,
    required this.scrollController,
    required this.onEventTap,
  });

  @override
  Widget build(BuildContext context) {
    final sortedEntries = itemEvents.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    final totalEvents = sortedEntries.fold(0, (sum, e) => sum + e.value.length);

    return Container(
      key: const ValueKey('allView'),
      color: kBg,
      child: Column(
        children: [
          // ── header bar ────────────────────────────────────────────
          Container(
            color: kSurface,
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
            child: Row(
              children: [
                const Icon(Icons.calendar_month_rounded,
                    color: kPrimary, size: 18),
                const SizedBox(width: 8),
                Text('calendar.allAppt'.tr(),
                    style: GoogleFonts.prompt(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: kText)),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: kPrimary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text('$totalEvents ${'calendar.apptItems'.tr()}',
                      style: GoogleFonts.prompt(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: kPrimary)),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: kBorder),

          // ── list ──────────────────────────────────────────────────
          Expanded(
            child: sortedEntries.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.event_busy_rounded,
                            size: 52, color: kBorder),
                        const SizedBox(height: 12),
                        Text('calendar.noAppt'.tr(),
                            style:
                                GoogleFonts.prompt(color: kSub, fontSize: 14)),
                      ],
                    ),
                  )
                : ListView.builder(
                    controller: scrollController,
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    itemCount: sortedEntries.length,
                    itemBuilder: (_, i) {
                      final date = sortedEntries[i].key;
                      final events = sortedEntries[i].value;
                      final dayName = 'calendar.dayFull.${date.weekday}'.tr();
                      final dateLabel =
                          '${date.day} ${'calendar.monthFull.${date.month}'.tr()} ${calYearLabel(date.year)}';
                      final isToday = isSameDay(date, DateTime.now());

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // date header
                          Padding(
                            padding: const EdgeInsets.only(top: 16, bottom: 8),
                            child: Row(
                              children: [
                                Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: isToday ? kPrimary : kSurface,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  alignment: Alignment.center,
                                  child: Text('${date.day}',
                                      style: GoogleFonts.prompt(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w700,
                                        color: isToday ? Colors.white : kText,
                                      )),
                                ),
                                const SizedBox(width: 10),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('${'calendar.dayPrefix'.tr()}$dayName',
                                        style: GoogleFonts.prompt(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: isToday ? kPrimary : kSub)),
                                    Text(dateLabel,
                                        style: GoogleFonts.prompt(
                                            fontSize: 11, color: kSub)),
                                  ],
                                ),
                                const Spacer(),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: kSurface,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  // FIX: was hardcoded '${events.length} นัด'
                                  child: Text(
                                      '${events.length} ${'calendar.apptBadge'.tr()}',
                                      style: GoogleFonts.prompt(
                                          fontSize: 11, color: kSub)),
                                ),
                              ],
                            ),
                          ),
                          // event cards
                          ...events.map((entry) {
                            final ev = entry as Map;
                            final sh = (ev['startHour'] as int? ?? 9);
                            final color = periodColor(sh);
                            return GestureDetector(
                              onTap: () => onEventTap(ev),
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: color.withOpacity(0.06),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                      color: color.withOpacity(0.25), width: 1),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 4,
                                      height: 44,
                                      decoration: BoxDecoration(
                                          color: color,
                                          borderRadius:
                                              BorderRadius.circular(4)),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(ev['title'] ?? '',
                                              style: GoogleFonts.prompt(
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w600,
                                                  color: kText),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis),
                                          const SizedBox(height: 3),
                                          Row(children: [
                                            Icon(Icons.access_time_rounded,
                                                size: 12, color: kSub),
                                            const SizedBox(width: 4),
                                            Text(ev['appointmentTime'] ?? '',
                                                style: GoogleFonts.prompt(
                                                    fontSize: 11, color: kSub)),
                                            const SizedBox(width: 8),
                                            Icon(Icons.person_outline_rounded,
                                                size: 12, color: kSub),
                                            const SizedBox(width: 4),
                                            Expanded(
                                              child: Text(
                                                  ev['clientName'] ?? '',
                                                  style: GoogleFonts.prompt(
                                                      fontSize: 11,
                                                      color: kSub),
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis),
                                            ),
                                          ]),
                                        ],
                                      ),
                                    ),
                                    Icon(Icons.chevron_right_rounded,
                                        color: kBorder, size: 20),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                          if (i < sortedEntries.length - 1)
                            const Divider(height: 16, color: kBorder),
                        ],
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
//  All Appointments — Desktop (inside left panel)
// ═══════════════════════════════════════════════════════════════════════════════
class AllAppointmentsViewDesktop extends StatelessWidget {
  final Map<DateTime, List<dynamic>> itemEvents;
  final ScrollController scrollController;
  final void Function(Map ev) onEventTap;

  const AllAppointmentsViewDesktop({
    super.key,
    required this.itemEvents,
    required this.scrollController,
    required this.onEventTap,
  });

  @override
  Widget build(BuildContext context) {
    final sortedEntries = itemEvents.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    final totalEvents = sortedEntries.fold(0, (sum, e) => sum + e.value.length);

    return Container(
      decoration: BoxDecoration(
        color: kBg,
        border: Border.all(color: kBorder),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          // ── summary bar ───────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
            child: Row(
              children: [
                const Icon(Icons.calendar_month_rounded,
                    color: kPrimary, size: 16),
                const SizedBox(width: 6),
                Text('calendar.allAppt'.tr(),
                    style: GoogleFonts.prompt(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: kText)),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: kPrimary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text('$totalEvents ${'calendar.apptItems'.tr()}',
                      style: GoogleFonts.prompt(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: kPrimary)),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: kBorder),

          // ── list ──────────────────────────────────────────────────
          Expanded(
            child: sortedEntries.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.event_busy_rounded,
                            size: 40, color: kBorder),
                        const SizedBox(height: 8),
                        Text('calendar.noAppt'.tr(),
                            style:
                                GoogleFonts.prompt(color: kSub, fontSize: 13)),
                      ],
                    ),
                  )
                : ListView.builder(
                    controller: scrollController,
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
                    itemCount: sortedEntries.length,
                    itemBuilder: (_, i) {
                      final date = sortedEntries[i].key;
                      final events = sortedEntries[i].value;
                      final isToday = isSameDay(date, DateTime.now());
                      final dayName = 'calendar.dayFull.${date.weekday}'.tr();
                      final dateLabel =
                          '${date.day} ${'calendar.monthFull.${date.month}'.tr()}';

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // date header
                          Padding(
                            padding: const EdgeInsets.only(top: 12, bottom: 6),
                            child: Row(
                              children: [
                                Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    color: isToday ? kPrimary : kSurface,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  alignment: Alignment.center,
                                  child: Text('${date.day}',
                                      style: GoogleFonts.prompt(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700,
                                        color: isToday ? Colors.white : kText,
                                      )),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                          '${'calendar.dayPrefix'.tr()}$dayName',
                                          style: GoogleFonts.prompt(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600,
                                              color:
                                                  isToday ? kPrimary : kSub)),
                                      Text(dateLabel,
                                          style: GoogleFonts.prompt(
                                              fontSize: 10, color: kSub)),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 1),
                                  decoration: BoxDecoration(
                                    color: kSurface,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  // FIX: was hardcoded '${events.length} นัด'
                                  child: Text(
                                      '${events.length} ${'calendar.apptBadge'.tr()}',
                                      style: GoogleFonts.prompt(
                                          fontSize: 10, color: kSub)),
                                ),
                              ],
                            ),
                          ),
                          // event cards
                          ...events.map((entry) {
                            final ev = entry as Map;
                            final sh = (ev['startHour'] as int? ?? 9);
                            final color = periodColor(sh);
                            return GestureDetector(
                              onTap: () => onEventTap(ev),
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 6),
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: color.withOpacity(0.06),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                      color: color.withOpacity(0.25)),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 3,
                                      height: 36,
                                      decoration: BoxDecoration(
                                        color: color,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(ev['title'] ?? '',
                                              style: GoogleFonts.prompt(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w600,
                                                  color: kText),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis),
                                          Text(ev['appointmentTime'] ?? '',
                                              style: GoogleFonts.prompt(
                                                  fontSize: 10, color: kSub)),
                                        ],
                                      ),
                                    ),
                                    Icon(Icons.chevron_right_rounded,
                                        color: kBorder, size: 16),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                          if (i < sortedEntries.length - 1)
                            const Divider(height: 12, color: kBorder),
                        ],
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
