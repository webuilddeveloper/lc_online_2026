import 'dart:collection';

import 'package:LawyerOnline/appointment-details-lawyer.dart';
import 'package:LawyerOnline/component/appbar.dart';
import 'package:LawyerOnline/shared/extension.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/date_symbol_data_local.dart';

// ─── Palette ──────────────────────────────────────────────────────────────
const _kBg = Color(0xFFFFFFFF);
const _kSurface = Color(0xFFEEF2F5);
const _kBorder = Color(0xFFE0E6ED);
const _kPrimary = Color(0xFF0262EC);
const _kText = Color(0xFF0D1B2A);
const _kSub = Color(0xFF6B7A99);

// ─── Event colors pool ────────────────────────────────────────────────────
const List<Color> _kEventColors = [
  Color(0xFF4A8CFF), // blue
  Color(0xFF34A853), // green
  Color(0xFF9B59B6), // purple
  Color(0xFFE67E22), // orange
  Color(0xFF1ABC9C), // teal
  Color(0xFFE74C3C), // red
];

// ─── Timeline event: สีน้ำเงินเดียว ─────────────────────────────────────
const _kTimelineColor = Color(0xFF0262EC);

// ─── Day event list: สีตามช่วงเวลา ──────────────────────────────────────
// เช้า 08-11 → เขียว | บ่าย 12-17 → ส้ม | ค่ำ 18-21 → ฟ้า
Color _periodColor(int startHour) {
  if (startHour >= 8 && startHour < 12) return const Color(0xFF34A853); // เขียว
  if (startHour >= 12 && startHour < 18) return const Color(0xFFE67E22); // ส้ม
  return const Color(0xFF4A8CFF); // ฟ้า
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

  // ─── view mode: false = week strip, true = month calendar ─────────
  bool _showMonthCalendar = false;

  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();

  Map<DateTime, List<dynamic>> itemEvents = {};

  AnimationController? _fadeCtrl;
  Animation<double>? _fadeAnim;

  // ─── calendar panel animation ─────────────────────────────────────
  AnimationController? _calPanelCtrl;

  // ─── Timeline scroll ──────────────────────────────────────────────
  final ScrollController _timelineScroll = ScrollController();
  static const double _hourHeight = 64.0;
  static const double _timeAxisWidth = 62.0;

  // ─── Timeline range matching consultation-schedule ────────────────
  static const int _startHour = 8; // 08:00
  static const int _endHour = 21; // 21:00
  static const int _totalHours = _endHour - _startHour + 1; // 14 slots

  @override
  void initState() {
    super.initState();

    _fadeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 450));
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl!, curve: Curves.easeOut);
    _fadeCtrl!.forward();

    _calPanelCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 300));

    _loadEvents();
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToCurrentHour());
  }

  @override
  void dispose() {
    _fadeCtrl?.dispose();
    _calPanelCtrl?.dispose();
    _timelineScroll.dispose();
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

  void _toggleCalendarPanel() {
    final closing = _showMonthCalendar;
    setState(() {
      _showMonthCalendar = !_showMonthCalendar;
      // เมื่อปิด month calendar กลับมา week strip
      // ให้ reset _focusedDay → _selectedDay เพื่อให้ week strip
      // แสดงสัปดาห์ของวันที่เลือก ไม่ใช่เดือนที่เลื่อนค้างไว้
      if (closing) _focusedDay = _selectedDay;
    });
    if (_showMonthCalendar) {
      _calPanelCtrl?.forward();
    } else {
      _calPanelCtrl?.reverse();
    }
  }

  void _loadEvents() {
    itemEvents = {
      DateTime(2026, 4, 10): [
        {
          "code": "0",
          "clientName": "อนงค์ ดำเนิน",
          "caseType": "คดีมรดกทุกประเภท",
          "subCaseType": "ฟ้องร้องมรดก",
          "appointmentDate": "10/04/2026",
          "appointmentTime": "09.00 - 10.00",
          "startHour": 9,
          "startMin": 0,
          "durationMin": 60,
          "title": "ขอฟ้องร้องมรดกพี่น้อง",
          "details": "ต้องการฟ้องร้องพี่น้องที่โกงเงินมรดก",
          "paymentStatus": "1",
          "colorIndex": 0,
        },
        {
          "code": "1",
          "clientName": "อนงค์ ดำเนิน",
          "caseType": "คดีครอบครัว",
          "subCaseType": "ฟ้องร้องการหย่าร้าง",
          "appointmentDate": "10/04/2026",
          "appointmentTime": "11.00 - 13.00",
          "startHour": 11,
          "startMin": 0,
          "durationMin": 120,
          "title": "ขอฟ้องร้องหย่าร้าง",
          "details": "ต้องการฟ้องร้องหย่าร้างกับสามีคนปัจจุบัน",
          "paymentStatus": "1",
          "colorIndex": 2,
        },
      ],
      DateTime(2026, 4, 20): [
        {
          "code": "0",
          "clientName": "สมชาย ใจดี",
          "caseType": "คดีมรดกทุกประเภท",
          "subCaseType": "ฟ้องร้องมรดก",
          "appointmentDate": "20/04/2026",
          "appointmentTime": "10.00 - 11.30",
          "startHour": 10,
          "startMin": 0,
          "durationMin": 90,
          "title": "ขอฟ้องร้องมรดกพี่น้อง ครั้งที่ 2",
          "details": "ต้องการฟ้องร้องพี่น้องที่โกงเงินมรดก",
          "paymentStatus": "2",
          "colorIndex": 1,
        },
      ],
      DateTime(2026, 4, 22): [
        {
          "code": "0",
          "clientName": "วรรณา สุขสม",
          "caseType": "คดีแรงงาน",
          "subCaseType": "เรียกค่าชดเชย",
          "appointmentDate": "22/04/2026",
          "appointmentTime": "09.00 - 10.00",
          "startHour": 9,
          "startMin": 0,
          "durationMin": 60,
          "title": "คดีแรงงาน เรียกค่าชดเชย",
          "details": "ถูกเลิกจ้างโดยไม่มีสาเหตุ ต้องการเรียกค่าชดเชย",
          "paymentStatus": "1",
          "colorIndex": 3,
        },
        {
          "code": "1",
          "clientName": "ประสิทธิ์ มั่งมี",
          "caseType": "ธุรกิจและบริษัท",
          "subCaseType": "ตรวจร่างสัญญา",
          "appointmentDate": "22/04/2026",
          "appointmentTime": "14.00 - 15.30",
          "startHour": 14,
          "startMin": 0,
          "durationMin": 90,
          "title": "ตรวจร่างสัญญาซื้อขายกิจการ",
          "details": "ตรวจสอบสัญญาซื้อขายกิจการ มูลค่า 5 ล้านบาท",
          "paymentStatus": "2",
          "colorIndex": 4,
        },
      ],
      DateTime(2026, 4, 25): [
        {
          "code": "0",
          "clientName": "อนงค์ ดำเนิน",
          "caseType": "คดีมรดกทุกประเภท",
          "subCaseType": "ฟ้องร้องมรดก",
          "appointmentDate": "25/04/2026",
          "appointmentTime": "13.00 - 14.00",
          "startHour": 13,
          "startMin": 0,
          "durationMin": 60,
          "title": "ขอฟ้องร้องมรดกพี่น้อง",
          "details": "ต้องการฟ้องร้องพี่น้องที่โกงเงินมรดก",
          "paymentStatus": "2",
          "colorIndex": 5,
        },
      ],
    };
    setState(() {});
  }

  List<dynamic> _getEventsForDay(DateTime day) {
    return itemEvents[DateTime(day.year, day.month, day.day)] ?? [];
  }

  int getHashCode(DateTime key) {
    return key.day * 1000000 + key.month * 10000 + key.year;
  }

  // ═══════════════════════════════════════════════════════════════════
  //  BUILD
  // ═══════════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      appBar: _buildAppBar(),
      body: FadeTransition(
        opacity: _fadeAnim ?? const AlwaysStoppedAnimation(1.0),
        child: Column(
          children: [
            // ── top panel: week strip OR full month calendar ──────────
            AnimatedSize(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              child: _showMonthCalendar
                  ? _buildMonthCalendar()
                  : _buildWeekStrip(),
            ),

            // ── toggle arrow button ───────────────────────────────────
            _buildToggleArrow(),

            // ── event list for selected day (shown above timeline) ────
            _buildDayEventList(),

            // ── timeline (day view) ───────────────────────────────────
            Expanded(child: _buildTimeline()),
          ],
        ),
      ),
    );
  }

  // ─── AppBar ───────────────────────────────────────────────────────
  PreferredSizeWidget _buildAppBar() {
    final thaiMonths = [
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
      'ธ.ค.'
    ];
    final monthLabel =
        '${thaiMonths[_focusedDay.month]} ${_focusedDay.year + 543}';

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
            // GestureDetector(
            //   onTap: () => Navigator
            //   child: const Icon(Icons.arrow_back_ios_new_rounded,
            //       color: _kText, size: 20),
            // ),
            const SizedBox(width: 12),
            Text(
              monthLabel,
              style: GoogleFonts.prompt(
                color: _kText,
                fontSize: 17,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            _iconBtn(Icons.today_rounded, () {
              setState(() {
                _selectedDay = DateTime.now();
                _focusedDay = DateTime.now();
              });
              WidgetsBinding.instance
                  .addPostFrameCallback((_) => _scrollToCurrentHour());
            }),
            const SizedBox(width: 6),
            // _iconBtn(Icons.search_rounded, () {}),
          ],
        ),
      ),
    );
  }

  Widget _iconBtn(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: _kSurface,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: _kSub, size: 18),
      ),
    );
  }

  // ─── Week Strip ───────────────────────────────────────────────────
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
                  Text(
                    thaiDays[i],
                    style: GoogleFonts.prompt(
                      fontSize: 11,
                      color: isToday ? _kPrimary : _kSub,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
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
                    child: Text(
                      '${d.day}',
                      style: GoogleFonts.prompt(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isSelected
                            ? Colors.white
                            : isToday
                                ? _kPrimary
                                : _kText,
                      ),
                    ),
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

  // ─── Month Calendar (TableCalendar full) ──────────────────────────
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
            _focusedDay = selectedDay; // sync ให้ตรงกันเสมอ
          });
        },
        onPageChanged: (focusedDay) {
          setState(() => _focusedDay = focusedDay);
        },
        headerStyle: HeaderStyle(
          formatButtonVisible: false,
          leftChevronIcon: const Icon(
            Icons.arrow_back_ios_rounded,
            size: 14,
            color: _kPrimary,
          ),
          rightChevronIcon: const Icon(
            Icons.arrow_forward_ios_rounded,
            size: 14,
            color: _kPrimary,
          ),
          titleTextStyle: GoogleFonts.prompt(
            color: _kText,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
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
          selectedDecoration: const BoxDecoration(
            color: _kPrimary,
            shape: BoxShape.circle,
          ),
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
          markerDecoration: const BoxDecoration(
            color: _kPrimary,
            shape: BoxShape.circle,
          ),
          markersMaxCount: 3,
          markerSize: 5,
          markerMargin: const EdgeInsets.symmetric(horizontal: 1),
        ),
        // ─── custom builders ──────────────────────────────────────
        calendarBuilders: CalendarBuilders(
          selectedBuilder: (context, date, _) {
            return Container(
              margin: const EdgeInsets.all(5),
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: _kPrimary,
              ),
              child: Text(
                '${date.day}',
                style: GoogleFonts.prompt(
                    fontSize: 14,
                    color: Colors.white,
                    fontWeight: FontWeight.w600),
              ),
            );
          },
          todayBuilder: (context, date, _) {
            return Container(
              margin: const EdgeInsets.all(5),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: _kPrimary, width: 1.5),
              ),
              child: Text(
                '${date.day}',
                style: GoogleFonts.prompt(
                    fontSize: 14,
                    color: _kPrimary,
                    fontWeight: FontWeight.w500),
              ),
            );
          },
          defaultBuilder: (context, date, _) {
            return Container(
              margin: const EdgeInsets.all(5),
              alignment: Alignment.center,
              child: Text(
                '${date.day}',
                style: GoogleFonts.prompt(fontSize: 14, color: _kText),
              ),
            );
          },
          markerBuilder: (context, day, events) {
            if (events.isEmpty) return const SizedBox.shrink();
            final isSelected = isSameDay(day, _selectedDay);
            if (isSelected)
              return const SizedBox.shrink(); // ซ่อนเมื่อ selected
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
                            color: _kPrimary,
                            shape: BoxShape.circle,
                          ),
                        ))
                    .toList(),
              ),
            );
          },
        ),
      ),
    );
  }

  // ─── Toggle Arrow ─────────────────────────────────────────────────
  //  ลูกศร ชี้ลง = week strip (default), ชี้ขึ้น = month calendar
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
          // ชี้ลง (0) = กดเพื่อเปิด month | ชี้ขึ้น (0.5 turn = 180°) = กดเพื่อปิด
          turns: _showMonthCalendar ? 0.5 : 0.0,
          child: Container(
            width: 40,
            height: 20,
            decoration: BoxDecoration(
              color: _kSurface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _kBorder, width: 1),
            ),
            child: const Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 18,
              color: _kSub,
            ),
          ),
        ),
      ),
    );
  }

  // ─── Day Event List (shown above timeline) ────────────────────────
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
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: _kSub,
              ),
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
                            // ── period indicator ──────────────────
                            Container(
                              width: 4,
                              height: 32,
                              decoration: BoxDecoration(
                                color: color,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                            const SizedBox(width: 10),
                            // ── text ─────────────────────────────
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
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
                                          horizontal: 6, vertical: 1),
                                      decoration: BoxDecoration(
                                        color: color.withOpacity(0.15),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        label,
                                        style: GoogleFonts.prompt(
                                          fontSize: 9,
                                          fontWeight: FontWeight.w600,
                                          color: color,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      ev['appointmentTime'] ?? '',
                                      style: GoogleFonts.prompt(
                                        fontSize: 10,
                                        color: _kSub,
                                      ),
                                    ),
                                  ],
                                ),
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

  // ─── Timeline ─────────────────────────────────────────────────────
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
                  child: Text(
                    label,
                    style: GoogleFonts.prompt(
                        fontSize: 10, color: _kSub, height: 1),
                    textAlign: TextAlign.right,
                  ),
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
    // offset relative to _startHour
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
              color: Color(0xFFFF4444),
              shape: BoxShape.circle,
            ),
          ),
          Expanded(
            child: Container(height: 2, color: const Color(0xFFFF4444)),
          ),
        ],
      ),
    );
  }

  Widget _buildEventBlock(Map ev) {
    final startHour = (ev['startHour'] as int? ?? 9);
    final startMin = (ev['startMin'] as int? ?? 0);
    final durationMin = (ev['durationMin'] as int? ?? 60);

    // ── สีน้ำเงินเดียวสำหรับ timeline ──────────────────────────────
    const color = _kTimelineColor;

    // offset relative to _startHour so events align with the grid
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
              border: Border(
                left: BorderSide(color: color, width: 3),
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  ev['title'] ?? '',
                  style: GoogleFonts.prompt(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _kText,
                    height: 1.2,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (blockHeight > 28) ...[
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Icon(Icons.access_time_rounded, size: 10, color: color),
                      const SizedBox(width: 3),
                      Text(
                        timeLabel,
                        style: GoogleFonts.prompt(
                          fontSize: 10,
                          color: color,
                          height: 1.2,
                        ),
                      ),
                    ],
                  ),
                ],
                if (ev['clientName'] != null) ...[
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Icon(Icons.person_outline_rounded,
                          size: 10, color: _kSub),
                      const SizedBox(width: 3),
                      Expanded(
                        child: Text(
                          ev['clientName'] ?? '',
                          style: GoogleFonts.prompt(
                            fontSize: 10,
                            color: _kSub,
                            height: 1.2,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ), // ClipRRect
      ),
    );
  }

  void goBack() async {
    Navigator.pop(context, false);
  }
}
