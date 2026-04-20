import 'dart:collection';

import 'package:LawyerOnline/appointment-details-lawyer.dart';
import 'package:LawyerOnline/component/appbar.dart';
import 'package:LawyerOnline/shared/extension.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/date_symbol_data_local.dart';

class CalendarPage extends StatefulWidget {
  const CalendarPage({super.key});

  @override
  _CalendarPageState createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage>
    with TickerProviderStateMixin {
  final storage = new FlutterSecureStorage();
  ValueNotifier<List<dynamic>>? _selectedEvents;

  // เปลี่ยนจาก month เป็น week เพื่อประหยัดพื้นที่บนหน้าจอเล็ก
  CalendarFormat _calendarFormat = CalendarFormat.month;
  RangeSelectionMode _rangeSelectionMode = RangeSelectionMode.toggledOff;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  DateTime? _rangeStart;
  DateTime? _rangeEnd;

  LinkedHashMap<DateTime, List<dynamic>>? model;
  var markData = [];
  Map<DateTime, List<dynamic>>? itemEvents;

  AnimationController? _animationController;

  @override
  void initState() {
    super.initState();
    _selectedDay = DateTime.now();
    _selectedEvents = ValueNotifier(_getEventsForDay(_selectedDay!));

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _animationController!.forward();
    getMarkerEvent();
  }

  @override
  void dispose() {
    _selectedEvents!.dispose();
    super.dispose();
  }

  getMarkerEvent() async {
    itemEvents = {
      DateTime(2026, 4, 10): [
        {
          "code": "0",
          "clientName": "อนงค์ ดำเนิน",
          "caseType": "คดีมรดกทุกประเภท",
          "subCaseType": "ฟ้องร้องมรดก",
          "appointmentDate": "28/03/2026",
          "appointmentTime": "11.00 - 14.00",
          "title": "ขอฟ้องร้องมรดกพี่น้อง",
          "details":
              "ต้องการฟ้องร้องพี่น้องที่โกงเงินมรดกอย่าตั้งใจเป็นเวลานานไม่แบ่งใครเป็นมรดกของคุณพ่อแต่คุณแม่ยังมีชีวิตอยู่",
          "paymentStatus": "1"
        },
        {
          "code": "1",
          "clientName": "อนงค์ ดำเนิน",
          "caseType": "คดีครอบครัวประเภท",
          "subCaseType": "ฟ้องร้องการหย่าร้าง",
          "appointmentDate": "28/03/2026",
          "appointmentTime": "11.00 - 14.00",
          "title": "ขอฟ้องร้องหย่าร้าง",
          "details": "ต้องการฟ้องร้องหย่าร้างกับสามีคนปัจจุบัน",
          "paymentStatus": "1"
        },
      ],
      DateTime(2026, 4, 20): [
        {
          "code": "0",
          "clientName": "อนงค์ ดำเนิน",
          "caseType": "คดีมรดกทุกประเภท",
          "subCaseType": "ฟ้องร้องมรดก",
          "appointmentDate": "28/03/2026",
          "appointmentTime": "11.00 - 14.00",
          "title": "ขอฟ้องร้องมรดกพี่น้อง ครั้งที่ 2",
          "details":
              "ต้องการฟ้องร้องพี่น้องที่โกงเงินมรดกอย่าตั้งใจเป็นเวลานานไม่แบ่งใครเป็นมรดกของคุณพ่อแต่คุณแม่ยังมีชีวิตอยู่",
          "paymentStatus": "2",
          "appointmentStatus": "2"
        },
      ],
      
      DateTime(2026, 4, 25): [
        {
          "code": "1",
          "clientName": "อนงค์ ดำเนิน",
          "caseType": "คดีมรดกทุกประเภท",
          "subCaseType": "ฟ้องร้องมรดก",
          "appointmentDate": "28/03/2026",
          "appointmentTime": "11.00 - 14.00",
          "title": "ขอฟ้องร้องมรดกพี่น้อง",
          "details":
              "ต้องการฟ้องร้องพี่น้องที่โกงเงินมรดกอย่าตั้งใจเป็นเวลานานไม่แบ่งใครเป็นมรดกของคุณพ่อแต่คุณแม่ยังมีชีวิตอยู่",
          "paymentStatus": "2",
          "appointmentStatus": "2"
        },
      ],
    };

    var mainEvent = LinkedHashMap<DateTime, List<dynamic>>(
      equals: isSameDay,
      hashCode: getHashCode,
    )..addAll(itemEvents!);

    setState(() {
      model = mainEvent;
      _selectedEvents?.value = _getEventsForDay(_selectedDay!);
    });
  }

  int getHashCode(DateTime key) {
    return key.day * 1000000 + key.month * 10000 + key.year;
  }

  List<dynamic> _getEventsForDay(DateTime day) {
    return itemEvents?[DateTime(day.year, day.month, day.day)] ?? [];
  }

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    final bool changed = !isSameDay(_selectedDay, selectedDay);
    if (changed) {
      setState(() {
        _selectedDay = selectedDay;
        _focusedDay = focusedDay;
        _rangeStart = null;
        _rangeEnd = null;
        _rangeSelectionMode = RangeSelectionMode.toggledOff;
      });
    }
    _selectedEvents?.value = _getEventsForDay(selectedDay);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: appBarCustom(
        title: 'นัดหมาย',
        backBtn: false,
        backAction: () => goBack(),
        isRightWidget: false,
      ),
      body: Stack(
        children: [
          // Background สองโซน
          Column(
            children: [
              // Expanded(
              //   flex: 3,
              //   child: Container(color: Colors.white),
              // ),
              Expanded(
                flex: 6,
                child: Container(color: const Color(0xFFEEF2F5)),
              ),
            ],
          ),
          // ✅ เปลี่ยนจาก Column เป็น CustomScrollView ให้ scroll ได้ทั้งหน้า
          SafeArea(
            child: CustomScrollView(
              slivers: [
                // ปฏิทิน
                SliverToBoxAdapter(
                  child: _buildCalendar(context),
                ),
                // ปุ่มสลับ week/month
                SliverToBoxAdapter(
                  child: _buildFormatToggle(),
                ),
                // รายการนัดหมาย
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(15, 0, 15, 30),
                  sliver: _buildEventList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ✅ ปฏิทินแยกเป็น widget ของตัวเอง ไม่ใช้ Expanded
  Widget _buildCalendar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(
          bottom: Radius.circular(24),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            spreadRadius: 0,
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: TableCalendar<dynamic>(
        locale: 'th_TH',
        firstDay: DateTime.utc(DateTime.now().year - 1, 01, 01),
        lastDay: DateTime.utc(DateTime.now().year + 1, 12, 31),
        focusedDay: _focusedDay,
        selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
        rangeStartDay: _rangeStart,
        rangeEndDay: _rangeEnd,
        calendarFormat: _calendarFormat,
        rangeSelectionMode: _rangeSelectionMode,
        availableGestures: AvailableGestures.all,
        eventLoader: _getEventsForDay,
        startingDayOfWeek: StartingDayOfWeek.monday,
        // ✅ ปิด formatButton ใน header เพราะเราทำปุ่มเองด้านล่าง
        headerStyle: const HeaderStyle(
          formatButtonVisible: false,
          leftChevronVisible: false,
          rightChevronVisible: false,
        ),
        calendarStyle: CalendarStyle(
          defaultDecoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(12),
          ),
          outsideDaysVisible: false,
          weekendTextStyle: const TextStyle().copyWith(
            color: Colors.black,
            fontWeight: FontWeight.normal,
          ),
          holidayTextStyle: const TextStyle().copyWith(
            color: Color(0xFFC5DAFC),
            fontWeight: FontWeight.normal,
          ),
        ),
        onDaySelected: _onDaySelected,
        onPageChanged: (focusedDay) {
          setState(() {
            _focusedDay = focusedDay;
          });
        },
        calendarBuilders: CalendarBuilders(
          headerTitleBuilder: (context, day) {
            final thaiMonth = DateFormat.MMMM('th_TH').format(day);
            return Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _focusedDay = DateTime(
                                _focusedDay.year, _focusedDay.month - 1, 1);
                          });
                        },
                        child: const Icon(
                          Icons.arrow_back_ios,
                          size: 14,
                          color: Color(0xFF0262EC),
                        ),
                      ),
                      Text(
                        '$thaiMonth',
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w500),
                      ),
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _focusedDay = DateTime(
                                _focusedDay.year, _focusedDay.month + 1, 1);
                          });
                        },
                        child: const Icon(
                          Icons.arrow_forward_ios,
                          size: 14,
                          color: Color(0xFF0262EC),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Divider(
                    thickness: 1,
                    height: 1,
                    color: Color(0xFFD9D9D9),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            );
          },
          selectedBuilder: (context, date, _) {
            return FadeTransition(
              opacity: Tween(begin: 0.0, end: 1.0)
                  .animate(_animationController!),
              child: Container(
                margin: const EdgeInsets.all(5.0),
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFF0262EC),
                ),
                width: 35,
                height: 35,
                child: Text(
                  '${date.day}',
                  style: const TextStyle().copyWith(
                      fontSize: 16.0,
                      fontFamily: 'Sarabun',
                      fontWeight: FontWeight.normal,
                      color: Colors.white),
                ),
              ),
            );
          },
          defaultBuilder: (context, date, _) {
            return FadeTransition(
              opacity: Tween(begin: 0.0, end: 1.0)
                  .animate(_animationController!),
              child: Container(
                margin: const EdgeInsets.all(5.0),
                alignment: Alignment.center,
                width: 35,
                height: 35,
                child: Text(
                  '${date.day}',
                  style: const TextStyle().copyWith(
                    fontSize: 16.0,
                    fontFamily: 'Sarabun',
                    fontWeight: FontWeight.normal,
                  ),
                ),
              ),
            );
          },
          todayBuilder: (context, date, _) {
            return FadeTransition(
              opacity: Tween(begin: 0.0, end: 1.0)
                  .animate(_animationController!),
              child: Container(
                margin: const EdgeInsets.all(5.0),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    width: 1,
                    color: const Color(0xFF0262EC),
                  ),
                ),
                width: 35,
                height: 35,
                child: Text(
                  '${date.day}',
                  style: const TextStyle().copyWith(
                    fontSize: 16.0,
                    fontFamily: 'Sarabun',
                    fontWeight: FontWeight.normal,
                  ),
                ),
              ),
            );
          },
          markerBuilder: (context, day, events) =>
              events.isNotEmpty ? _buildEventsMarker(events) : const SizedBox(),
        ),
      ),
    );
  }

  // ✅ ปุ่มสลับ week / month แยกออกมาเป็น widget
  Widget _buildFormatToggle() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          GestureDetector(
            onTap: () {
              setState(() {
                _calendarFormat = _calendarFormat == CalendarFormat.month
                    ? CalendarFormat.week
                    : CalendarFormat.month;
              });
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFF0262EC), width: 1),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _calendarFormat == CalendarFormat.month
                        ? 'ย่อปฏิทิน'
                        : 'ขยายปฏิทิน',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF0262EC),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    _calendarFormat == CalendarFormat.month
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    size: 16,
                    color: const Color(0xFF0262EC),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ✅ Event list เป็น Sliver แทน Expanded + ListView
  Widget _buildEventList() {
    return ValueListenableBuilder<List<dynamic>>(
      valueListenable: _selectedEvents!,
      builder: (context, value, _) {
        if (value.isEmpty) {
          return SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(top: 60),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.calendar_today_outlined,
                      size: 64,
                      color: Colors.grey.shade300,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'ไม่มีนัดหมายในวันนี้',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'เลือกวันอื่นเพื่อดูนัดหมาย',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade400,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }
        return SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              return Padding(
                padding: EdgeInsets.only(
                  top: index == 0 ? 10 : 0,
                  bottom: 15,
                ),
                child: GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AppointmentDetailsLawyer(
                          model: value[index],
                        ),
                      ),
                    );
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFF0262EC),
                          const Color(0xFF0048B8),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF0262EC).withOpacity(0.2),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            color: Colors.white.withOpacity(0.2),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.3),
                              width: 1.5,
                            ),
                          ),
                          child: Icon(
                            Icons.calendar_today,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                value[index]['title'] ?? '',
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                  height: 1.2,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  Icon(
                                    Icons.calendar_today,
                                    size: 12,
                                    color: Colors.white.withOpacity(0.8),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    value[index]['appointmentDate'] ?? '',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.white.withOpacity(0.9),
                                      fontWeight: FontWeight.w500,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  Icon(
                                    Icons.access_time,
                                    size: 12,
                                    color: Colors.white.withOpacity(0.8),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    value[index]['appointmentTime'] ?? '',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.white.withOpacity(0.9),
                                      fontWeight: FontWeight.w500,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
            childCount: value.length,
          ),
        );
      },
    );
  }

  Widget _buildEventsMarker(List events) {
    return Positioned(
      bottom: -4,
      right: 0,
      left: 0,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: Color(0xFF0262EC),
        ),
        width: 7.0,
        height: 7.0,
      ),
    );
  }

  void goBack() async {
    Navigator.pop(context, false);
  }
}