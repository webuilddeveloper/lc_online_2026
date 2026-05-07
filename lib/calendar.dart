import 'dart:collection';

import 'package:LawyerOnline/appointment-details-lawyer.dart';
import 'package:LawyerOnline/component/appbar.dart';
import 'package:LawyerOnline/shared/extension.dart';
import 'package:LawyerOnline/shared/responsive/app_layout.dart';
import 'package:LawyerOnline/shared/responsive/res_layout.dart';
import 'package:LawyerOnline/shared/responsive/responsive_values.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:LawyerOnline/models/lawyer/appointment_store.dart';

// ─── Palette ──────────────────────────────────────────────────────────────
const _kBg = Color(0xFFFFFFFF);
const _kSurface = Color(0xFFEEF2F5);
const _kBorder = Color(0xFFE0E6ED);
const _kPrimary = Color(0xFF0262EC);
const _kText = Color(0xFF0D1B2A);
const _kSub = Color(0xFF6B7A99);

// ─── Event colors pool ────────────────────────────────────────────────────
const List<Color> _kEventColors = [
  Color(0xFF4A8CFF),
  Color(0xFF34A853),
  Color(0xFF9B59B6),
  Color(0xFFE67E22),
  Color(0xFF1ABC9C),
  Color(0xFFE74C3C),
];

const _kTimelineColor = Color(0xFF0262EC);

// ─── Thai locale data ─────────────────────────────────────────────────────
const List<String> kThaiMonthsShort = [
  '',
  'ม.ค.',
  'ก.พ.',
  'มี.ค.',
  'เม.ย.',
  'พ.ค.',
  'มิ.ย.',
  'ก.ค.',
  'ส.ค.',
  'ก.ย.',
  'ต.ค.',
  'พ.ย.',
  'ธ.ค.',
];

const List<String> kThaiMonthsFull = [
  '',
  'มกราคม',
  'กุมภาพันธ์',
  'มีนาคม',
  'เมษายน',
  'พฤษภาคม',
  'มิถุนายน',
  'กรกฎาคม',
  'สิงหาคม',
  'กันยายน',
  'ตุลาคม',
  'พฤศจิกายน',
  'ธันวาคม',
];

const List<String> kThaiDaysFull = [
  '',
  'จันทร์',
  'อังคาร',
  'พุธ',
  'พฤหัสบดี',
  'ศุกร์',
  'เสาร์',
  'อาทิตย์',
];

Color _periodColor(int startHour) {
  if (startHour >= 8 && startHour < 12) return const Color(0xFF34A853);
  if (startHour >= 12 && startHour < 18) return const Color(0xFFE67E22);
  return const Color(0xFF4A8CFF);
}

String _periodLabel(int startHour) {
  if (startHour >= 8 && startHour < 12) return 'เช้า';
  if (startHour >= 12 && startHour < 18) return 'บ่าย';
  return 'ค่ำ';
}

class CalendarPage extends StatefulWidget {
  const CalendarPage({super.key});

  @override
  _CalendarPageState createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage>
    with TickerProviderStateMixin {
  final storage = FlutterSecureStorage();

  bool _showMonthCalendar = false;
  bool _showAllView = false;

  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();

  // ── ดึง eventMap จาก AppointmentStore แทน hardcode ─────────
  Map<DateTime, List<dynamic>> get itemEvents =>
      AppointmentStore.instance.eventMap;

  AnimationController? _fadeCtrl;
  Animation<double>? _fadeAnim;
  AnimationController? _calPanelCtrl;

  final ScrollController _timelineScroll = ScrollController();
  final ScrollController _allViewScroll = ScrollController();

  static const double _hourHeight = 64.0;
  static const double _timeAxisWidth = 62.0;
  static const int _startHour = 8;
  static const int _endHour = 21;
  static const int _totalHours = _endHour - _startHour + 1;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 450));
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl!, curve: Curves.easeOut);
    _fadeCtrl!.forward();
    _calPanelCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 300));
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToCurrentHour());
    storage.read(key: 'calendarShowAllView').then((val) {
      if (val == 'true' && mounted) setState(() => _showAllView = true);
    });
  }

  @override
  void dispose() {
    _fadeCtrl?.dispose();
    _calPanelCtrl?.dispose();
    _timelineScroll.dispose();
    _allViewScroll.dispose();
    super.dispose();
  }

  void _scrollToCurrentHour() {
    final now = DateTime.now();
    final offset = ((now.hour - _startHour) - 1) * _hourHeight;
    if (_timelineScroll.hasClients) {
      _timelineScroll.animateTo(
        offset.clamp(0.0, _timelineScroll.position.maxScrollExtent),
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeOut,
      );
    }
  }

  void _scrollAllViewToToday() {
    final sortedKeys = itemEvents.keys.toList()..sort();
    if (sortedKeys.isEmpty) return;
    final today = DateTime.now();
    final todayKey = DateTime(today.year, today.month, today.day);
    int targetIndex = 0;
    bool hasToday = false;
    for (int i = 0; i < sortedKeys.length; i++) {
      if (isSameDay(sortedKeys[i], todayKey)) {
        targetIndex = i;
        hasToday = true;
        break;
      }
      if (sortedKeys[i].isAfter(todayKey)) {
        targetIndex = i;
        break;
      }
      targetIndex = i;
    }
    double offset = 8.0;
    for (int i = 0; i < targetIndex; i++) {
      final evCount = itemEvents[sortedKeys[i]]?.length ?? 0;
      offset += 72 + (evCount * 88) + 16;
    }
    if (_allViewScroll.hasClients) {
      _allViewScroll.animateTo(
        offset.clamp(0.0, _allViewScroll.position.maxScrollExtent),
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeOut,
      );
    }
    if (!hasToday) {
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('วันนี้ไม่มีนัด',
            style: GoogleFonts.prompt(fontSize: 13, color: Colors.white)),
        backgroundColor: _kPrimary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        duration: const Duration(seconds: 2),
      ));
    }
  }

  void _toggleCalendarPanel() {
    final closing = _showMonthCalendar;
    setState(() {
      _showMonthCalendar = !_showMonthCalendar;
      if (closing) _focusedDay = _selectedDay;
    });
    if (_showMonthCalendar) {
      _calPanelCtrl?.forward();
    } else {
      _calPanelCtrl?.reverse();
    }
  }

  // ── _loadEvents ถูกลบออกแล้ว ข้อมูลอยู่ที่ AppointmentStore ──

  List<dynamic> _getEventsForDay(DateTime day) =>
      AppointmentStore.instance.getEventsForDay(day);

  int getHashCode(DateTime key) {
    return key.day * 1000000 + key.month * 10000 + key.year;
  }

  // ═══════════════════════════════════════════════════════════════════
  //  BUILD
  // ═══════════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    final isDesktop = ResponsiveLayout.isDesktop(context);

    return Scaffold(
      backgroundColor: _kBg,
      // desktop → ไม่มี appBar ตรงนี้ เพราะ TopNav อยู่ใน menu.dart แล้ว
      // mobile/tablet → appBar เดิม
      appBar: isDesktop ? null : _buildAppBar(),
      body: isDesktop ? _buildDesktopBody() : _buildMobileBody(),
    );
  }

  // ══════════════════════════════════════════════════════════════════
  //  DESKTOP BODY: Row → LEFT panel | RIGHT timeline
  // ══════════════════════════════════════════════════════════════════
  Widget _buildDesktopBody() {
    final hPad = RV.pagePadding(context);

    return FadeTransition(
      opacity: _fadeAnim ?? const AlwaysStoppedAnimation(1.0),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: hPad, vertical: 24),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── LEFT: calendar panel ─────────────────────────────
            SizedBox(
              width: 500,
              child: Column(
                children: [
                  _buildDesktopCalendarHeader(),
                  const SizedBox(height: 12),
                  Expanded(
                    child: _showAllView
                        ? _buildAllAppointmentsViewDesktop()
                        : _buildDesktopLeftPanel(),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 24),

            // ── RIGHT: day events + timeline ──────────────────────
            Expanded(
              child: Column(
                children: [
                  // ── header bar (month label + actions) ──────────
                  _buildDesktopRightHeader(),
                  const SizedBox(height: 12),
                  // ── timeline ─────────────────────────────────────
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        decoration: BoxDecoration(
                          color: _kBg,
                          border: Border.all(color: _kBorder),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: _buildTimeline(),
                      ),
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

  // ── Desktop: header ซ้าย (month label + toggle all view) ──────────
  Widget _buildDesktopCalendarHeader() {
    final monthLabel =
        '${kThaiMonthsShort[_focusedDay.month]} ${_focusedDay.year + 543}';

    return Row(
      children: [
        Text(
          monthLabel,
          style: GoogleFonts.prompt(
            color: _kText,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        const Spacer(),
        _iconBtn(
          _showAllView
              ? Icons.calendar_today_rounded
              : Icons.format_list_bulleted_rounded,
          () {
            final next = !_showAllView;
            setState(() => _showAllView = next);
            storage.write(key: 'calendarShowAllView', value: next.toString());
          },
          active: _showAllView,
        ),
        const SizedBox(width: 8),
        _iconBtn(Icons.today_rounded, () {
          if (_showAllView) {
            _scrollAllViewToToday();
          } else {
            setState(() {
              _selectedDay = DateTime.now();
              _focusedDay = DateTime.now();
            });
            WidgetsBinding.instance
                .addPostFrameCallback((_) => _scrollToCurrentHour());
          }
        }),
      ],
    );
  }

  // ── Desktop: month label + date บน right panel ────────────────────
  Widget _buildDesktopRightHeader() {
    final isToday = isSameDay(_selectedDay, DateTime.now());
    final dayLabel =
        'วัน${kThaiDaysFull[_selectedDay.weekday]} ${_selectedDay.day} '
        '${kThaiMonthsFull[_selectedDay.month]} ${_selectedDay.year + 543}';

    final events = _getEventsForDay(_selectedDay);

    return Row(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              dayLabel,
              style: GoogleFonts.prompt(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: isToday ? _kPrimary : _kText,
              ),
            ),
            if (events.isNotEmpty)
              Text(
                '${events.length} นัดหมาย',
                style: GoogleFonts.prompt(fontSize: 12, color: _kSub),
              ),
          ],
        ),
        const Spacer(),
        // week nav
        _iconBtn(Icons.chevron_left_rounded, () {
          setState(() {
            _selectedDay = _selectedDay.subtract(const Duration(days: 1));
            _focusedDay = _selectedDay;
          });
        }),
        const SizedBox(width: 6),
        _iconBtn(Icons.chevron_right_rounded, () {
          setState(() {
            _selectedDay = _selectedDay.add(const Duration(days: 1));
            _focusedDay = _selectedDay;
          });
        }),
      ],
    );
  }

  // ── Desktop LEFT panel: week strip + month calendar ────────────────
  Widget _buildDesktopLeftPanel() {
    return Container(
      decoration: BoxDecoration(
        color: _kBg,
        border: Border.all(color: _kBorder),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // month calendar full (desktop ไม่ต้องซ่อน/แสดง toggle)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: _buildMonthCalendar(),
          ),
          const Divider(height: 1, color: _kBorder),
          // day event list ของวันที่เลือก
          _buildDayEventListDesktop(),
        ],
      ),
    );
  }

  // ── Desktop: upcoming events mini list ใต้ calendar ──────────────
  // ── Desktop: Day event list แนวตั้ง ────────────────────────────────
  Widget _buildDayEventListDesktop() {
    final events = _getEventsForDay(_selectedDay);
    if (events.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: BoxDecoration(
        color: _kSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _kBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'นัดหมายวันนี้ (${events.length} รายการ)',
            style: GoogleFonts.prompt(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: _kSub,
            ),
          ),
          const SizedBox(height: 10),
          // grid 2 col
          for (int i = 0; i < events.length; i += 2) ...[
            if (i > 0) const SizedBox(height: 8),
            Row(
              children: [
                Expanded(child: _buildDayEventCardDesktop(events[i] as Map)),
                const SizedBox(width: 10),
                Expanded(
                  child: i + 1 < events.length
                      ? _buildDayEventCardDesktop(events[i + 1] as Map)
                      : const SizedBox.shrink(),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDayEventCardDesktop(Map ev) {
    final startHour = (ev['startHour'] as int? ?? 9);
    final color = _periodColor(startHour);
    final label = _periodLabel(startHour);

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => AppointmentDetailsLawyer(model: ev)),
      ),
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
                color: color,
                borderRadius: BorderRadius.circular(4),
              ),
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
                      color: color,
                    ),
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
                          style: GoogleFonts.prompt(fontSize: 10, color: _kSub),
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

  // ── Desktop: All appointments view (ใน LEFT panel) ────────────────
  Widget _buildAllAppointmentsViewDesktop() {
    final sortedEntries = itemEvents.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    final totalEvents = sortedEntries.fold(0, (sum, e) => sum + e.value.length);

    return Container(
      decoration: BoxDecoration(
        color: _kBg,
        border: Border.all(color: _kBorder),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          // summary bar
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
            child: Row(
              children: [
                const Icon(Icons.calendar_month_rounded,
                    color: _kPrimary, size: 16),
                const SizedBox(width: 6),
                Text('นัดหมายทั้งหมด',
                    style: GoogleFonts.prompt(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: _kText)),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: _kPrimary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text('$totalEvents รายการ',
                      style: GoogleFonts.prompt(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: _kPrimary)),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: _kBorder),
          Expanded(
            child: sortedEntries.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.event_busy_rounded,
                            size: 40, color: _kBorder),
                        const SizedBox(height: 8),
                        Text('ไม่มีนัดหมาย',
                            style:
                                GoogleFonts.prompt(color: _kSub, fontSize: 13)),
                      ],
                    ),
                  )
                : ListView.builder(
                    controller: _allViewScroll,
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
                    itemCount: sortedEntries.length,
                    itemBuilder: (_, i) {
                      final date = sortedEntries[i].key;
                      final events = sortedEntries[i].value;
                      final isToday = isSameDay(date, DateTime.now());
                      final dayName = kThaiDaysFull[date.weekday];
                      final dateLabel =
                          '${date.day} ${kThaiMonthsFull[date.month]}';

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(top: 12, bottom: 6),
                            child: Row(
                              children: [
                                Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    color: isToday ? _kPrimary : _kSurface,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  alignment: Alignment.center,
                                  child: Text('${date.day}',
                                      style: GoogleFonts.prompt(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700,
                                        color: isToday ? Colors.white : _kText,
                                      )),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text('วัน$dayName',
                                          style: GoogleFonts.prompt(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600,
                                              color:
                                                  isToday ? _kPrimary : _kSub)),
                                      Text(dateLabel,
                                          style: GoogleFonts.prompt(
                                              fontSize: 10, color: _kSub)),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 1),
                                  decoration: BoxDecoration(
                                    color: _kSurface,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text('${events.length} นัด',
                                      style: GoogleFonts.prompt(
                                          fontSize: 10, color: _kSub)),
                                ),
                              ],
                            ),
                          ),
                          ...events.map((entry) {
                            final ev = entry as Map;
                            final startHour = (ev['startHour'] as int? ?? 9);
                            final color = _periodColor(startHour);
                            return GestureDetector(
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      AppointmentDetailsLawyer(model: ev),
                                ),
                              ),
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
                                                  color: _kText),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis),
                                          Text(ev['appointmentTime'] ?? '',
                                              style: GoogleFonts.prompt(
                                                  fontSize: 10, color: _kSub)),
                                        ],
                                      ),
                                    ),
                                    Icon(Icons.chevron_right_rounded,
                                        color: _kBorder, size: 16),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                          if (i < sortedEntries.length - 1)
                            const Divider(height: 12, color: _kBorder),
                        ],
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════
  //  MOBILE BODY: เดิมทุกอย่าง ไม่เปลี่ยน
  // ══════════════════════════════════════════════════════════════════
  Widget _buildMobileBody() {
    return IndexedStack(
      index: _showAllView ? 1 : 0,
      children: [
        FadeTransition(
          opacity: _fadeAnim ?? const AlwaysStoppedAnimation(1.0),
          child: Column(
            children: [
              AnimatedSize(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                child: _showMonthCalendar
                    ? _buildMonthCalendar()
                    : _buildWeekStrip(),
              ),
              _buildToggleArrow(),
              _buildDayEventList(),
              Expanded(child: _buildTimeline()),
            ],
          ),
        ),
        _buildAllAppointmentsView(),
      ],
    );
  }

  // ─── AppBar (mobile only) ─────────────────────────────────────────
  PreferredSizeWidget _buildAppBar() {
    final monthLabel =
        '${kThaiMonthsShort[_focusedDay.month]} ${_focusedDay.year + 543}';

    return AppBar(
      backgroundColor: _kBg,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      automaticallyImplyLeading: false,
      titleSpacing: 0,
      iconTheme: const IconThemeData(color: _kText),
      title: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            const SizedBox(width: 12),
            Text(
              monthLabel,
              style: GoogleFonts.prompt(
                  color: _kText, fontSize: 17, fontWeight: FontWeight.w600),
            ),
            const Spacer(),
            _iconBtn(
              _showAllView
                  ? Icons.calendar_today_rounded
                  : Icons.format_list_bulleted_rounded,
              () {
                final next = !_showAllView;
                setState(() => _showAllView = next);
                storage.write(
                    key: 'calendarShowAllView', value: next.toString());
              },
              active: _showAllView,
            ),
            const SizedBox(width: 6),
            _iconBtn(Icons.today_rounded, () {
              if (_showAllView) {
                _scrollAllViewToToday();
              } else {
                setState(() {
                  _selectedDay = DateTime.now();
                  _focusedDay = DateTime.now();
                });
                WidgetsBinding.instance
                    .addPostFrameCallback((_) => _scrollToCurrentHour());
              }
            }),
            const SizedBox(width: 6),
          ],
        ),
      ),
    );
  }

  Widget _iconBtn(IconData icon, VoidCallback onTap, {bool active = false}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: active ? _kPrimary : _kSurface,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: active ? Colors.white : _kSub, size: 18),
      ),
    );
  }

  // ─── Week Strip (mobile) ──────────────────────────────────────────
  Widget _buildWeekStrip() {
    final startOfWeek =
        _focusedDay.subtract(Duration(days: _focusedDay.weekday - 1));
    final days = List.generate(7, (i) => startOfWeek.add(Duration(days: i)));
    final thaiDays = ['จ', 'อ', 'พ', 'พฤ', 'ศ', 'ส', 'อา'];
    final today = DateTime.now();

    return Container(
      color: _kBg,
      padding: const EdgeInsets.fromLTRB(8, 6, 8, 8),
      child: Row(
        children: days.asMap().entries.map((e) {
          final i = e.key;
          final d = e.value;
          final isSelected = isSameDay(d, _selectedDay);
          final isToday = isSameDay(d, today);
          final dayEvents = _getEventsForDay(d);

          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() {
                _selectedDay = d;
                _focusedDay = d;
              }),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(thaiDays[i],
                      style: GoogleFonts.prompt(
                          fontSize: 11,
                          color: isToday ? _kPrimary : _kSub,
                          fontWeight: FontWeight.w500)),
                  const SizedBox(height: 4),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: isSelected ? _kPrimary : Colors.transparent,
                      shape: BoxShape.circle,
                      border: isToday && !isSelected
                          ? Border.all(color: _kPrimary, width: 1.5)
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
                                  ? _kPrimary
                                  : _kText,
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
                                    : _kPrimary,
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

  // ─── Month Calendar ───────────────────────────────────────────────
  Widget _buildMonthCalendar() {
    return Container(
      color: _kBg,
      padding: const EdgeInsets.only(bottom: 4),
      child: TableCalendar<dynamic>(
        locale: 'th_TH',
        firstDay: DateTime.utc(DateTime.now().year - 1, 1, 1),
        lastDay: DateTime.utc(DateTime.now().year + 1, 12, 31),
        focusedDay: _focusedDay,
        calendarFormat: CalendarFormat.month,
        availableGestures: AvailableGestures.all,
        eventLoader: _getEventsForDay,
        startingDayOfWeek: StartingDayOfWeek.monday,
        selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
        onDaySelected: (selectedDay, focusedDay) {
          setState(() {
            _selectedDay = selectedDay;
            _focusedDay = selectedDay;
          });
        },
        onPageChanged: (focusedDay) {
          setState(() => _focusedDay = focusedDay);
        },
        headerStyle: HeaderStyle(
          formatButtonVisible: false,
          leftChevronIcon: const Icon(Icons.arrow_back_ios_rounded,
              size: 14, color: _kPrimary),
          rightChevronIcon: const Icon(Icons.arrow_forward_ios_rounded,
              size: 14, color: _kPrimary),
          titleTextStyle: GoogleFonts.prompt(
              color: _kText, fontSize: 14, fontWeight: FontWeight.w600),
          titleCentered: true,
          headerPadding:
              const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          decoration: const BoxDecoration(color: Colors.transparent),
        ),
        daysOfWeekStyle: DaysOfWeekStyle(
          weekdayStyle: GoogleFonts.prompt(
              fontSize: 11, color: _kSub, fontWeight: FontWeight.w500),
          weekendStyle: GoogleFonts.prompt(
              fontSize: 11, color: _kSub, fontWeight: FontWeight.w500),
        ),
        calendarStyle: CalendarStyle(
          outsideDaysVisible: false,
          cellMargin: const EdgeInsets.all(4),
          selectedDecoration:
              const BoxDecoration(color: _kPrimary, shape: BoxShape.circle),
          selectedTextStyle: GoogleFonts.prompt(
              color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
          todayDecoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: _kPrimary, width: 1.5),
            color: Colors.transparent,
          ),
          todayTextStyle: GoogleFonts.prompt(color: _kPrimary, fontSize: 13),
          defaultTextStyle: GoogleFonts.prompt(color: _kText, fontSize: 13),
          weekendTextStyle: GoogleFonts.prompt(color: _kText, fontSize: 13),
          markerDecoration:
              const BoxDecoration(color: _kPrimary, shape: BoxShape.circle),
          markersMaxCount: 3,
          markerSize: 5,
          markerMargin: const EdgeInsets.symmetric(horizontal: 1),
        ),
        calendarBuilders: CalendarBuilders(
          selectedBuilder: (context, date, _) => Container(
            margin: const EdgeInsets.all(5),
            alignment: Alignment.center,
            decoration:
                const BoxDecoration(shape: BoxShape.circle, color: _kPrimary),
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
              border: Border.all(color: _kPrimary, width: 1.5),
            ),
            child: Text('${date.day}',
                style: GoogleFonts.prompt(
                    fontSize: 14,
                    color: _kPrimary,
                    fontWeight: FontWeight.w500)),
          ),
          defaultBuilder: (context, date, _) => Container(
            margin: const EdgeInsets.all(5),
            alignment: Alignment.center,
            child: Text('${date.day}',
                style: GoogleFonts.prompt(fontSize: 14, color: _kText)),
          ),
          markerBuilder: (context, day, events) {
            if (events.isEmpty) return const SizedBox.shrink();
            final isSelected = isSameDay(day, _selectedDay);
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
                              color: _kPrimary, shape: BoxShape.circle),
                        ))
                    .toList(),
              ),
            );
          },
        ),
      ),
    );
  }

  // ─── Toggle Arrow (mobile only) ───────────────────────────────────
  Widget _buildToggleArrow() {
    return GestureDetector(
      onTap: _toggleCalendarPanel,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: double.infinity,
        height: 28,
        color: _kBg,
        alignment: Alignment.center,
        child: AnimatedRotation(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          turns: _showMonthCalendar ? 0.5 : 0.0,
          child: Container(
            width: 40,
            height: 20,
            decoration: BoxDecoration(
              color: _kSurface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _kBorder, width: 1),
            ),
            child: const Icon(Icons.keyboard_arrow_down_rounded,
                size: 18, color: _kSub),
          ),
        ),
      ),
    );
  }

  // ─── Day Event List (mobile horizontal scroll — เดิม) ─────────────
  Widget _buildDayEventList() {
    final events = _getEventsForDay(_selectedDay);
    if (events.isEmpty) return const SizedBox.shrink();

    return Container(
      color: _kSurface,
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 8),
            child: Text(
              'นัดหมายวันนี้ (${events.length} รายการ)',
              style: GoogleFonts.prompt(
                  fontSize: 11, fontWeight: FontWeight.w600, color: _kSub),
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
                  final ev = entry as Map;
                  final startHour = (ev['startHour'] as int? ?? 9);
                  final color = _periodColor(startHour);
                  final label = _periodLabel(startHour);

                  return Container(
                    margin: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) =>
                                AppointmentDetailsLawyer(model: ev)),
                      ),
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
                                          fontSize: 10, color: _kSub)),
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

  // ─── Timeline (shared mobile + desktop) ───────────────────────────
  Widget _buildTimeline() {
    final events = _getEventsForDay(_selectedDay);
    final now = DateTime.now();
    final isToday = isSameDay(_selectedDay, now);
    final totalHeight = _totalHours * _hourHeight;

    return Container(
      color: _kBg,
      child: SingleChildScrollView(
        controller: _timelineScroll,
        physics: const BouncingScrollPhysics(),
        child: SizedBox(
          height: totalHeight,
          child: Stack(
            children: [
              ..._buildHourGrid(),
              if (isToday) _buildNowLine(now),
              ...events.map((ev) => _buildEventBlock(ev)),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildHourGrid() {
    return List.generate(_totalHours, (i) {
      final h = _startHour + i;
      final label = '${h.toString().padLeft(2, '0')}:00 น.';
      return Positioned(
        top: i * _hourHeight,
        left: 0,
        right: 0,
        child: SizedBox(
          height: _hourHeight,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: _timeAxisWidth,
                child: Padding(
                  padding: const EdgeInsets.only(left: 8, right: 6),
                  child: Text(label,
                      style: GoogleFonts.prompt(
                          fontSize: 10, color: _kSub, height: 1),
                      textAlign: TextAlign.right),
                ),
              ),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    border: Border(
                      top: BorderSide(color: _kBorder, width: i == 0 ? 0 : 0.5),
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
    if (now.hour < _startHour || now.hour > _endHour)
      return const SizedBox.shrink();
    final topOffset =
        (now.hour - _startHour) * _hourHeight + now.minute * _hourHeight / 60;
    return Positioned(
      top: topOffset - 6,
      left: _timeAxisWidth - 6,
      right: 0,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
              width: 12,
              height: 12,
              decoration: const BoxDecoration(
                  color: Color(0xFFFF4444), shape: BoxShape.circle)),
          Expanded(child: Container(height: 2, color: const Color(0xFFFF4444))),
        ],
      ),
    );
  }

  Widget _buildEventBlock(Map ev) {
    final startHour = (ev['startHour'] as int? ?? 9);
    final startMin = (ev['startMin'] as int? ?? 0);
    final durationMin = (ev['durationMin'] as int? ?? 60);
    const color = _kTimelineColor;
    final topOffset =
        (startHour - _startHour) * _hourHeight + startMin * _hourHeight / 60;
    final blockHeight = (durationMin * _hourHeight / 60).clamp(28.0, 9999.0);
    final endTotalMin = startHour * 60 + startMin + durationMin;
    final timeLabel =
        '${startHour.toString().padLeft(2, '0')}:${startMin.toString().padLeft(2, '0')} – '
        '${(endTotalMin ~/ 60).toString().padLeft(2, '0')}:'
        '${(endTotalMin % 60).toString().padLeft(2, '0')} น.';

    return Positioned(
      top: topOffset + 2,
      left: _timeAxisWidth + 4,
      right: 8,
      height: blockHeight - 4,
      child: GestureDetector(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => AppointmentDetailsLawyer(model: ev)),
        ),
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
                        color: _kText,
                        height: 1.2),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis),
                if (blockHeight > 28) ...[
                  const SizedBox(height: 2),
                  Row(children: [
                    Icon(Icons.access_time_rounded, size: 10, color: color),
                    const SizedBox(width: 3),
                    Text(timeLabel,
                        style: GoogleFonts.prompt(
                            fontSize: 10, color: color, height: 1.2)),
                  ]),
                ],
                if (ev['clientName'] != null) ...[
                  const SizedBox(height: 2),
                  Row(children: [
                    Icon(Icons.person_outline_rounded, size: 10, color: _kSub),
                    const SizedBox(width: 3),
                    Expanded(
                      child: Text(ev['clientName'] ?? '',
                          style: GoogleFonts.prompt(
                              fontSize: 10, color: _kSub, height: 1.2),
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

  // ─── All Appointments Full View (mobile) ──────────────────────────
  Widget _buildAllAppointmentsView() {
    final sortedEntries = itemEvents.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    final totalEvents = sortedEntries.fold(0, (sum, e) => sum + e.value.length);

    return Container(
      key: const ValueKey('allView'),
      color: _kBg,
      child: Column(
        children: [
          Container(
            color: _kSurface,
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
            child: Row(
              children: [
                const Icon(Icons.calendar_month_rounded,
                    color: _kPrimary, size: 18),
                const SizedBox(width: 8),
                Text('นัดหมายทั้งหมด',
                    style: GoogleFonts.prompt(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: _kText)),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: _kPrimary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text('$totalEvents รายการ',
                      style: GoogleFonts.prompt(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: _kPrimary)),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: _kBorder),
          Expanded(
            child: sortedEntries.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.event_busy_rounded,
                            size: 52, color: _kBorder),
                        const SizedBox(height: 12),
                        Text('ไม่มีนัดหมาย',
                            style:
                                GoogleFonts.prompt(color: _kSub, fontSize: 14)),
                      ],
                    ),
                  )
                : ListView.builder(
                    controller: _allViewScroll,
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    itemCount: sortedEntries.length,
                    itemBuilder: (_, i) {
                      final date = sortedEntries[i].key;
                      final events = sortedEntries[i].value;
                      final dayName = kThaiDaysFull[date.weekday];
                      final dateLabel =
                          '${date.day} ${kThaiMonthsFull[date.month]} ${date.year + 543}';
                      final isToday = isSameDay(date, DateTime.now());

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(top: 16, bottom: 8),
                            child: Row(
                              children: [
                                Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: isToday ? _kPrimary : _kSurface,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  alignment: Alignment.center,
                                  child: Text('${date.day}',
                                      style: GoogleFonts.prompt(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w700,
                                        color: isToday ? Colors.white : _kText,
                                      )),
                                ),
                                const SizedBox(width: 10),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('วัน$dayName',
                                        style: GoogleFonts.prompt(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color:
                                                isToday ? _kPrimary : _kSub)),
                                    Text(dateLabel,
                                        style: GoogleFonts.prompt(
                                            fontSize: 11, color: _kSub)),
                                  ],
                                ),
                                const Spacer(),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: _kSurface,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text('${events.length} นัด',
                                      style: GoogleFonts.prompt(
                                          fontSize: 11, color: _kSub)),
                                ),
                              ],
                            ),
                          ),
                          ...events.map((entry) {
                            final ev = entry as Map;
                            final startHour = (ev['startHour'] as int? ?? 9);
                            final color = _periodColor(startHour);
                            return GestureDetector(
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      AppointmentDetailsLawyer(model: ev),
                                ),
                              ),
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
                                                  color: _kText),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis),
                                          const SizedBox(height: 3),
                                          Row(children: [
                                            Icon(Icons.access_time_rounded,
                                                size: 12, color: _kSub),
                                            const SizedBox(width: 4),
                                            Text(ev['appointmentTime'] ?? '',
                                                style: GoogleFonts.prompt(
                                                    fontSize: 11,
                                                    color: _kSub)),
                                            const SizedBox(width: 8),
                                            Icon(Icons.person_outline_rounded,
                                                size: 12, color: _kSub),
                                            const SizedBox(width: 4),
                                            Expanded(
                                              child: Text(
                                                  ev['clientName'] ?? '',
                                                  style: GoogleFonts.prompt(
                                                      fontSize: 11,
                                                      color: _kSub),
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis),
                                            ),
                                          ]),
                                        ],
                                      ),
                                    ),
                                    Icon(Icons.chevron_right_rounded,
                                        color: _kBorder, size: 20),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                          if (i < sortedEntries.length - 1)
                            const Divider(height: 16, color: _kBorder),
                        ],
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  void goBack() async {
    Navigator.pop(context, false);
  }
}
