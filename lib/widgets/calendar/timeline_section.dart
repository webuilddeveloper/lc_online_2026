// ─── timeline_section.dart ────────────────────────────────────────────────────
// ปฏิทินรายเดือน / Week Strip / Toggle Arrow / DayEventList
// + Timeline grid 8-21 น. + Event blocks
// ─────────────────────────────────────────────────────────────────────────────

import 'package:LawyerOnline/appointment-details-lawyer.dart';
import 'package:LawyerOnline/widgets/calendar/calendar_theme.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:table_calendar/table_calendar.dart';

// ═══════════════════════════════════════════════════════════════════════════════
//  Week Strip  (mobile)
// ═══════════════════════════════════════════════════════════════════════════════
class WeekStrip extends StatelessWidget {
  final DateTime focusedDay;
  final DateTime selectedDay;
  final List<dynamic> Function(DateTime) getEventsForDay;
  final void Function(DateTime) onDaySelected;

  const WeekStrip({
    super.key,
    required this.focusedDay,
    required this.selectedDay,
    required this.getEventsForDay,
    required this.onDaySelected,
  });

  @override
  Widget build(BuildContext context) {
    final startOfWeek =
        focusedDay.subtract(Duration(days: focusedDay.weekday - 1));
    final days = List.generate(7, (i) => startOfWeek.add(Duration(days: i)));
    final dayLabels = List.generate(7, (i) => 'calendar.dayShort.$i'.tr());
    final today = DateTime.now();

    return Container(
      color: kBg,
      padding: const EdgeInsets.fromLTRB(8, 6, 8, 8),
      child: Row(
        children: days.asMap().entries.map((e) {
          final i = e.key;
          final d = e.value;
          final isSelected = isSameDay(d, selectedDay);
          final isToday    = isSameDay(d, today);
          final dayEvents  = getEventsForDay(d);

          return Expanded(
            child: GestureDetector(
              onTap: () => onDaySelected(d),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(dayLabels[i],
                      style: GoogleFonts.prompt(
                          fontSize: 11,
                          color: isToday ? kPrimary : kSub,
                          fontWeight: FontWeight.w500)),
                  const SizedBox(height: 4),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: isSelected ? kPrimary : Colors.transparent,
                      shape: BoxShape.circle,
                      border: isToday && !isSelected
                          ? Border.all(color: kPrimary, width: 1.5)
                          : null,
                    ),
                    alignment: Alignment.center,
                    child: Text('${d.day}',
                        style: GoogleFonts.prompt(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: isSelected
                              ? Colors.white
                              : isToday
                                  ? kPrimary
                                  : kText,
                        )),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: dayEvents
                        .take(3)
                        .map((_) => Container(
                              width: 5,
                              height: 5,
                              margin: const EdgeInsets.symmetric(horizontal: 1),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isSelected
                                    ? Colors.white.withOpacity(0.8)
                                    : kPrimary,
                              ),
                            ))
                        .toList(),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
//  Month Calendar  (shared mobile + desktop)
// ═══════════════════════════════════════════════════════════════════════════════
class MonthCalendarPanel extends StatelessWidget {
  final DateTime focusedDay;
  final DateTime selectedDay;
  final List<dynamic> Function(DateTime) getEventsForDay;
  final void Function(DateTime selected, DateTime focused) onDaySelected;
  final void Function(DateTime) onPageChanged;

  const MonthCalendarPanel({
    super.key,
    required this.focusedDay,
    required this.selectedDay,
    required this.getEventsForDay,
    required this.onDaySelected,
    required this.onPageChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: kBg,
      padding: const EdgeInsets.only(bottom: 4),
      child: TableCalendar<dynamic>(
        locale: context.locale.languageCode == 'th' ? 'th_TH' : 'en_US',
        firstDay: DateTime.utc(DateTime.now().year - 1, 1, 1),
        lastDay: DateTime.utc(DateTime.now().year + 1, 12, 31),
        focusedDay: focusedDay,
        calendarFormat: CalendarFormat.month,
        availableGestures: AvailableGestures.all,
        eventLoader: getEventsForDay,
        startingDayOfWeek: StartingDayOfWeek.monday,
        selectedDayPredicate: (day) => isSameDay(selectedDay, day),
        onDaySelected: onDaySelected,
        onPageChanged: onPageChanged,
        headerStyle: HeaderStyle(
          formatButtonVisible: false,
          leftChevronIcon: const Icon(Icons.arrow_back_ios_rounded,
              size: 14, color: kPrimary),
          rightChevronIcon: const Icon(Icons.arrow_forward_ios_rounded,
              size: 14, color: kPrimary),
          titleCentered: true,
          headerPadding:
              const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          decoration: const BoxDecoration(color: Colors.transparent),
        ),
        daysOfWeekStyle: DaysOfWeekStyle(
          weekdayStyle: GoogleFonts.prompt(
              fontSize: 11, color: kSub, fontWeight: FontWeight.w500),
          weekendStyle: GoogleFonts.prompt(
              fontSize: 11, color: kSub, fontWeight: FontWeight.w500),
        ),
        calendarStyle: CalendarStyle(
          outsideDaysVisible: false,
          cellMargin: const EdgeInsets.all(4),
          selectedDecoration:
              const BoxDecoration(color: kPrimary, shape: BoxShape.circle),
          selectedTextStyle: GoogleFonts.prompt(
              color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
          todayDecoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: kPrimary, width: 1.5),
            color: Colors.transparent,
          ),
          todayTextStyle: GoogleFonts.prompt(color: kPrimary, fontSize: 13),
          defaultTextStyle: GoogleFonts.prompt(color: kText, fontSize: 13),
          weekendTextStyle: GoogleFonts.prompt(color: kText, fontSize: 13),
          markerDecoration:
              const BoxDecoration(color: kPrimary, shape: BoxShape.circle),
          markersMaxCount: 3,
          markerSize: 5,
          markerMargin: const EdgeInsets.symmetric(horizontal: 1),
        ),
        calendarBuilders: CalendarBuilders(
          headerTitleBuilder: (context, day) => Center(
            child: Text(
              '${'calendar.monthFull.${day.month}'.tr()} ${calYearLabel(day.year)}',
              style: GoogleFonts.prompt(
                  color: kText, fontSize: 14, fontWeight: FontWeight.w600),
            ),
          ),
          selectedBuilder: (context, date, _) => Container(
            margin: const EdgeInsets.all(5),
            alignment: Alignment.center,
            decoration:
                const BoxDecoration(shape: BoxShape.circle, color: kPrimary),
            child: Text('${date.day}',
                style: GoogleFonts.prompt(
                    fontSize: 14,
                    color: Colors.white,
                    fontWeight: FontWeight.w600)),
          ),
          todayBuilder: (context, date, _) => Container(
            margin: const EdgeInsets.all(5),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: kPrimary, width: 1.5),
            ),
            child: Text('${date.day}',
                style: GoogleFonts.prompt(
                    fontSize: 14,
                    color: kPrimary,
                    fontWeight: FontWeight.w500)),
          ),
          defaultBuilder: (context, date, _) => Container(
            margin: const EdgeInsets.all(5),
            alignment: Alignment.center,
            child: Text('${date.day}',
                style: GoogleFonts.prompt(fontSize: 14, color: kText)),
          ),
          markerBuilder: (context, day, events) {
            if (events.isEmpty) return const SizedBox.shrink();
            final isSelected = isSameDay(day, selectedDay);
            if (isSelected) return const SizedBox.shrink();
            return Positioned(
              bottom: 4,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: events
                    .take(3)
                    .map((e) => Container(
                          width: 5,
                          height: 5,
                          margin: const EdgeInsets.symmetric(horizontal: 1),
                          decoration: const BoxDecoration(
                              color: kPrimary, shape: BoxShape.circle),
                        ))
                    .toList(),
              ),
            );
          },
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
//  Toggle Arrow  (mobile only)
// ═══════════════════════════════════════════════════════════════════════════════
class ToggleArrow extends StatelessWidget {
  final bool showMonthCalendar;
  final VoidCallback onTap;

  const ToggleArrow({
    super.key,
    required this.showMonthCalendar,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: double.infinity,
        height: 28,
        color: kBg,
        alignment: Alignment.center,
        child: AnimatedRotation(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          turns: showMonthCalendar ? 0.5 : 0.0,
          child: Container(
            width: 40,
            height: 20,
            decoration: BoxDecoration(
              color: kSurface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: kBorder, width: 1),
            ),
            child: const Icon(Icons.keyboard_arrow_down_rounded,
                size: 18, color: kSub),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
//  Day Event List  — Mobile (horizontal scroll)
// ═══════════════════════════════════════════════════════════════════════════════
class DayEventListMobile extends StatelessWidget {
  final List<dynamic> events;
  final void Function(Map ev) onEventTap;

  const DayEventListMobile({
    super.key,
    required this.events,
    required this.onEventTap,
  });

  @override
  Widget build(BuildContext context) {
    if (events.isEmpty) return const SizedBox.shrink();

    return Container(
      color: kSurface,
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 8),
            child: Text(
              '${'calendar.apptToday'.tr()} (${events.length} ${'calendar.apptItems'.tr()})',
              style: GoogleFonts.prompt(
                  fontSize: 11, fontWeight: FontWeight.w600, color: kSub),
            ),
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: events.map((entry) {
                  final ev    = entry as Map;
                  final sh    = (ev['startHour'] as int? ?? 9);
                  final color = periodColor(sh);
                  final label = periodLabel(sh);

                  return Container(
                    margin: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      onTap: () => onEventTap(ev),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                              color: color.withOpacity(0.35), width: 1),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 4,
                              height: 32,
                              decoration: BoxDecoration(
                                  color: color,
                                  borderRadius: BorderRadius.circular(4)),
                            ),
                            const SizedBox(width: 10),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(ev['title'] ?? '',
                                    style: GoogleFonts.prompt(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: color),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis),
                                const SizedBox(height: 2),
                                Row(children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 6, vertical: 1),
                                    decoration: BoxDecoration(
                                      color: color.withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(label,
                                        style: GoogleFonts.prompt(
                                            fontSize: 9,
                                            fontWeight: FontWeight.w600,
                                            color: color)),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(ev['appointmentTime'] ?? '',
                                      style: GoogleFonts.prompt(
                                          fontSize: 10, color: kSub)),
                                ]),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
//  Day Event List  — Desktop (2-column grid)
// ═══════════════════════════════════════════════════════════════════════════════
class DayEventListDesktop extends StatelessWidget {
  final List<dynamic> events;
  final void Function(Map ev) onEventTap;

  const DayEventListDesktop({
    super.key,
    required this.events,
    required this.onEventTap,
  });

  @override
  Widget build(BuildContext context) {
    if (events.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: BoxDecoration(
        color: kSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: kBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${'calendar.apptToday'.tr()} (${events.length} ${'calendar.apptItems'.tr()})',
            style: GoogleFonts.prompt(
                fontSize: 11, fontWeight: FontWeight.w600, color: kSub),
          ),
          const SizedBox(height: 10),
          for (int i = 0; i < events.length; i += 2) ...[
            if (i > 0) const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                    child: _DayEventCardDesktop(
                        ev: events[i] as Map, onTap: onEventTap)),
                const SizedBox(width: 10),
                Expanded(
                  child: i + 1 < events.length
                      ? _DayEventCardDesktop(
                          ev: events[i + 1] as Map, onTap: onEventTap)
                      : const SizedBox.shrink(),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _DayEventCardDesktop extends StatelessWidget {
  final Map ev;
  final void Function(Map) onTap;

  const _DayEventCardDesktop({required this.ev, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final sh    = (ev['startHour'] as int? ?? 9);
    final color = periodColor(sh);
    final label = periodLabel(sh);

    return GestureDetector(
      onTap: () => onTap(ev),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.07),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(0.3), width: 1),
        ),
        child: Row(
          children: [
            Container(
              width: 4,
              height: 36,
              decoration: BoxDecoration(
                  color: color, borderRadius: BorderRadius.circular(4)),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    ev['title'] ?? '',
                    style: GoogleFonts.prompt(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: color),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 5, vertical: 1),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(label,
                            style: GoogleFonts.prompt(
                                fontSize: 9,
                                fontWeight: FontWeight.w600,
                                color: color)),
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          ev['appointmentTime'] ?? '',
                          style: GoogleFonts.prompt(fontSize: 10, color: kSub),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
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

// ═══════════════════════════════════════════════════════════════════════════════
//  Timeline  (shared mobile + desktop)
// ═══════════════════════════════════════════════════════════════════════════════
class TimelineView extends StatelessWidget {
  final DateTime selectedDay;
  final List<dynamic> events;
  final ScrollController scrollController;
  final void Function(Map ev) onEventTap;

  const TimelineView({
    super.key,
    required this.selectedDay,
    required this.events,
    required this.scrollController,
    required this.onEventTap,
  });

  @override
  Widget build(BuildContext context) {
    final now     = DateTime.now();
    final isToday = isSameDay(selectedDay, now);
    const total   = kTotalHours * kHourHeight;

    return Container(
      color: kBg,
      child: SingleChildScrollView(
        controller: scrollController,
        physics: const BouncingScrollPhysics(),
        child: SizedBox(
          height: total,
          child: Stack(
            children: [
              ..._buildHourGrid(),
              if (isToday) _buildNowLine(now),
              ...events.map((ev) => _buildEventBlock(ev, onEventTap)),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildHourGrid() {
    return List.generate(kTotalHours, (i) {
      final h     = kStartHour + i;
      final tUnit = 'calendar.timeUnit'.tr();
      final label = '${h.toString().padLeft(2, '0')}:00${tUnit.isNotEmpty ? ' $tUnit' : ''}';
      return Positioned(
        top: i * kHourHeight,
        left: 0,
        right: 0,
        child: SizedBox(
          height: kHourHeight,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: kTimeAxisWidth,
                child: Padding(
                  padding: const EdgeInsets.only(left: 8, right: 6),
                  child: Text(label,
                      style: GoogleFonts.prompt(
                          fontSize: 10, color: kSub, height: 1),
                      textAlign: TextAlign.right),
                ),
              ),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    border: Border(
                      top: BorderSide(
                          color: kBorder, width: i == 0 ? 0 : 0.5),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildNowLine(DateTime now) {
    if (now.hour < kStartHour || now.hour > kEndHour) {
      return const SizedBox.shrink();
    }
    final top =
        (now.hour - kStartHour) * kHourHeight + now.minute * kHourHeight / 60;
    return Positioned(
      top: top - 6,
      left: kTimeAxisWidth - 6,
      right: 0,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
              width: 12,
              height: 12,
              decoration: const BoxDecoration(
                  color: Color(0xFFFF4444), shape: BoxShape.circle)),
          Expanded(
              child: Container(height: 2, color: const Color(0xFFFF4444))),
        ],
      ),
    );
  }

  Widget _buildEventBlock(dynamic entry, void Function(Map) onTap) {
    final ev         = entry as Map;
    final startHour  = (ev['startHour'] as int? ?? 9);
    final startMin   = (ev['startMin'] as int? ?? 0);
    final durMin     = (ev['durationMin'] as int? ?? 60);
    const color      = kTimelineColor;
    final topOffset  =
        (startHour - kStartHour) * kHourHeight + startMin * kHourHeight / 60;
    final blockH     = (durMin * kHourHeight / 60).clamp(28.0, 9999.0);
    final endTotal   = startHour * 60 + startMin + durMin;
    final timeLabel  =
        '${startHour.toString().padLeft(2, '0')}:${startMin.toString().padLeft(2, '0')} – '
        '${(endTotal ~/ 60).toString().padLeft(2, '0')}:'
        '${(endTotal % 60).toString().padLeft(2, '0')}${'calendar.timeUnit'.tr().isNotEmpty ? ' ${'calendar.timeUnit'.tr()}' : ''}';

    return Positioned(
      top: topOffset + 2,
      left: kTimeAxisWidth + 4,
      right: 8,
      height: blockH - 4,
      child: GestureDetector(
        onTap: () => onTap(ev),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Container(
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(8),
              border: const Border(left: BorderSide(color: color, width: 3)),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(ev['title'] ?? '',
                    style: GoogleFonts.prompt(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: kText,
                        height: 1.2),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis),
                if (blockH > 28) ...[
                  const SizedBox(height: 2),
                  Row(children: [
                    const Icon(Icons.access_time_rounded,
                        size: 10, color: color),
                    const SizedBox(width: 3),
                    Text(timeLabel,
                        style: GoogleFonts.prompt(
                            fontSize: 10, color: color, height: 1.2)),
                  ]),
                ],
                if (ev['clientName'] != null) ...[
                  const SizedBox(height: 2),
                  Row(children: [
                    const Icon(Icons.person_outline_rounded,
                        size: 10, color: kSub),
                    const SizedBox(width: 3),
                    Expanded(
                      child: Text(ev['clientName'] ?? '',
                          style: GoogleFonts.prompt(
                              fontSize: 10, color: kSub, height: 1.2),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                    ),
                  ]),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}