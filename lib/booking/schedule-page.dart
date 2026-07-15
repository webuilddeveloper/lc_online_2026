import 'package:LawyerOnline/booking/summary-page.dart';
import 'package:LawyerOnline/services/appointment_booking_service.dart';
import 'package:LawyerOnline/component/appbar.dart';
import 'package:LawyerOnline/component/button.dart';
import 'package:LawyerOnline/component/loading_service.dart';
import 'package:LawyerOnline/shared/api_provider.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

class SchedulePage extends StatefulWidget {
  final dynamic lawyer;
  final String topic;
  final String topicTitle;
  final String subTopic;
  final String subTopicTitle;
  final String details;

  const SchedulePage({
    required this.lawyer,
    required this.topic,
    this.topicTitle = '',
    required this.subTopic,
    this.subTopicTitle = '',
    this.details = '',
  });

  @override
  State<SchedulePage> createState() => _SchedulePageState();
}

class _SchedulePageState extends State<SchedulePage> {
  DateTime _focusedDate = DateTime.now();
  DateTime? _selectedDate;
  String? _selectedTime;

  // slots ของวันที่เลือก
  List<dynamic> _timeSlots = [];

  // ข้อมูลตารางเวลาของทนาย (โหลดครั้งแรก)
  List<dynamic> _lawyerOpenDays = []; // [{day, title, isOpen}]
  List<dynamic> _lawyerOpenSlots = []; // [{title, isOpen}]

  bool _slotsLoading = false;
  bool _scheduleLoaded = false;
  bool _isUrgentCaseActive = false;

  final _thMonths = [
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
  final _thDays = ['อา', 'จ', 'อ', 'พ', 'พฤ', 'ศ', 'ส'];

  @override
  void initState() {
    super.initState();
    // โหลด slot วันนี้ก่อน + ได้ lawyerSchedule มาด้วย
    readTimeSlot(DateFormat('yyyy-MM-dd').format(DateTime.now()));
  }

  // ── เช็คว่าวันนี้ทนายเปิดไหม (ใช้กับ calendar) ──────────────
  bool _isDayOpenForLawyer(DateTime date) {
    if (_lawyerOpenDays.isEmpty) return true; // ยังไม่โหลด → เปิดทั้งหมด
    final dayOfWeek =
        date.weekday % 7; // dart: 1=จันทร์ ... 7=อาทิตย์ → %7 → 0=อาทิตย์
    final found = _lawyerOpenDays.firstWhere(
      (d) => d['day'] == dayOfWeek,
      orElse: () => null,
    );
    return found == null ? true : found['isOpen'] == true;
  }

  Future<void> readTimeSlot(String date) async {
    setState(() => _slotsLoading = true);
    try {
      final param = await postDio(
        '$server/m/register/checkSlot',
        {'lawyerCode': widget.lawyer['code'], 'date': date},
      );

      final objectData = param['objectData'];
      final urgentActive = objectData['isUrgentCaseActive'] == true ||
          objectData['isUrgentCaseActive']?.toString() == 'true';

      // ── โหลด lawyerSchedule ครั้งแรก ──────────────────────
      if (!_scheduleLoaded && objectData['lawyerSchedule'] != null) {
        final schedule = objectData['lawyerSchedule'];
        _lawyerOpenDays = List<dynamic>.from(schedule['days'] ?? []);
        _lawyerOpenSlots = List<dynamic>.from(schedule['slots'] ?? []);
        _scheduleLoaded = true;
      }

      // ── โหลด slots ของวันที่ขอ ────────────────────────────
      final dateCheck = objectData['dateCheck'];
      var slots = List<dynamic>.from(dateCheck?['slots'] ?? []);

      if (!urgentActive) {
        final booked = await AppointmentBookingService.loadBookedSlots(
          lawyerCode: widget.lawyer['code']?.toString() ?? '',
          caseDate: date,
        );
        final bookedStarts = booked.map((b) => b.startTime).toSet();
        slots = slots.map((slot) {
          if (slot is Map) {
            final copy = Map<String, dynamic>.from(slot);
            final title = copy['title']?.toString() ?? '';
            if (bookedStarts.contains(title)) {
              copy['isOpen'] = false;
              copy['booked'] = true;
              copy['available'] = false;
            }
            return copy;
          }
          return slot;
        }).toList();
      }

      setState(() {
        _isUrgentCaseActive = urgentActive;
        _timeSlots = urgentActive ? [] : slots;
        _selectedTime = null;
        _slotsLoading = false;
      });
    } catch (e) {
      print('readTimeSlot error: $e');
      setState(() => _slotsLoading = false);
    }
  }

  List<DateTime> _getDaysInMonth() {
    final first = DateTime(_focusedDate.year, _focusedDate.month, 1);
    final last = DateTime(_focusedDate.year, _focusedDate.month + 1, 0);
    return List.generate(
        last.day, (i) => DateTime(first.year, first.month, i + 1));
  }

  Widget _buildHeader() {
    return Row(children: [
      Container(
        padding: const EdgeInsets.all(9),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
              colors: [Color(0xFF0262EC), Color(0xFF34AAFF)]),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
                color: const Color(0xFF0262EC).withOpacity(0.4),
                blurRadius: 14,
                offset: const Offset(0, 3))
          ],
        ),
        child: const Icon(Icons.calendar_month, color: Colors.white, size: 18),
      ),
      const SizedBox(width: 10),
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('เลือกวัน และเวลา',
            style: TextStyle(
                color: Color(0xFF1A2340),
                fontSize: 16,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.3)),
        Text('กดเลือกวันและเวลาที่ทนายว่างที่ต้องการนัดหมาย',
            style: TextStyle(
                color: const Color(0xFF1A2340).withOpacity(0.4), fontSize: 11)),
      ]),
    ]);
  }

  // ── แสดงวันที่ทนายเปิด ───────────────────────────────────────
  Widget _buildOpenDaysInfo() {
    if (_lawyerOpenDays.isEmpty) return const SizedBox();
    final openDays = _lawyerOpenDays
        .where((d) => d['isOpen'] == true)
        .map((d) => d['title']?.toString() ?? '')
        .where((t) => t.isNotEmpty)
        .toList();

    if (openDays.isEmpty) return const SizedBox();

    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFEEF4FF),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF0262EC).withOpacity(0.2)),
        ),
        child: Row(children: [
          const Icon(Icons.calendar_today_rounded,
              size: 14, color: Color(0xFF0262EC)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'ทนายเปิดรับ: ${openDays.join(', ')}',
              style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF0262EC),
                  fontWeight: FontWeight.w500),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _buildUrgentCaseBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF4E5),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFFB74D).withOpacity(0.5)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.bolt_rounded, color: Color(0xFFE65100), size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'urgentCaseBlockBookingTitle'.tr(),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFE65100),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'urgentCaseBlockBookingMessage'.tr(),
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.4,
                    color: Colors.grey[700],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final days = _getDaysInMonth();
    final firstWeekday = days.first.weekday % 7;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: appBar(
        title: 'นัดหมายทนาย',
        backBtn: true,
        rightBtn: false,
        backAction: () => Navigator.pop(context, false),
        rightAction: () {},
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 5),

                  // ── วันที่เปิด ──────────────────────────────
                  _buildOpenDaysInfo(),
                  if (_isUrgentCaseActive) ...[
                    const SizedBox(height: 12),
                    _buildUrgentCaseBanner(),
                  ],
                  const SizedBox(height: 14),

                  // ── Calendar Card ───────────────────────────
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10)
                      ],
                    ),
                    child: Column(children: [
                      // Month navigation
                      Row(children: [
                        GestureDetector(
                          onTap: () => setState(() => _focusedDate = DateTime(
                              _focusedDate.year, _focusedDate.month - 1, 1)),
                          child: const Icon(Icons.chevron_left_rounded,
                              color: Color(0xFF1A2340)),
                        ),
                        Expanded(
                          child: Text(
                            '${_thMonths[_focusedDate.month]} ${_focusedDate.year + 543}',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                                color: Color(0xFF1A2340)),
                          ),
                        ),
                        GestureDetector(
                          onTap: () => setState(() => _focusedDate = DateTime(
                              _focusedDate.year, _focusedDate.month + 1, 1)),
                          child: const Icon(Icons.chevron_right_rounded,
                              color: Color(0xFF1A2340)),
                        ),
                      ]),
                      const SizedBox(height: 12),

                      // Day headers
                      Row(
                        children: _thDays
                            .map((d) => Expanded(
                                  child: Text(d,
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                          fontSize: 11,
                                          color: Colors.grey[400],
                                          fontWeight: FontWeight.w600)),
                                ))
                            .toList(),
                      ),
                      const SizedBox(height: 8),

                      // Calendar grid
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 7, childAspectRatio: 1),
                        itemCount: firstWeekday + days.length,
                        itemBuilder: (_, i) {
                          if (i < firstWeekday) return const SizedBox();
                          final day = days[i - firstWeekday];
                          final isSelected = _selectedDate != null &&
                              day.day == _selectedDate!.day &&
                              day.month == _selectedDate!.month;
                          final isPast = day.isBefore(
                              DateTime.now().subtract(const Duration(days: 1)));
                          // เช็คว่าทนายเปิดวันนี้ไหม
                          final isLawyerClosed =
                              _scheduleLoaded && !_isDayOpenForLawyer(day);

                          final isDisabled = isPast || isLawyerClosed;

                          return GestureDetector(
                            onTap: isDisabled
                                ? null
                                : () {
                                    setState(() {
                                      _selectedDate = day;
                                      _selectedTime = null;
                                    });
                                    readTimeSlot(
                                        DateFormat('yyyy-MM-dd').format(day));
                                  },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              margin: const EdgeInsets.all(2),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? const Color(0xFF0262EC)
                                    : isLawyerClosed
                                        ? const Color(0xFFFFF0F0)
                                        : Colors.transparent,
                                borderRadius: BorderRadius.circular(10),
                                border: isLawyerClosed && !isPast
                                    ? Border.all(
                                        color: Colors.red.withOpacity(0.2))
                                    : null,
                              ),
                              child: Center(
                                child: Text(
                                  '${day.day}',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: isSelected
                                        ? FontWeight.w700
                                        : FontWeight.w400,
                                    color: isSelected
                                        ? Colors.white
                                        : isDisabled
                                            ? Colors.grey[300]
                                            : const Color(0xFF1A2340),
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                      // Legend
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                  color: Colors.grey[200],
                                  borderRadius: BorderRadius.circular(3))),
                          const SizedBox(width: 6),
                          Text('ไม่ว่าง',
                              style: TextStyle(
                                  fontSize: 11, color: Colors.grey[400])),
                          const SizedBox(width: 16),
                          Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                  color: const Color(0xFF0262EC),
                                  borderRadius: BorderRadius.circular(3))),
                          const SizedBox(width: 6),
                          Text('ที่เลือกอยู่',
                              style: TextStyle(
                                  fontSize: 11, color: Colors.grey[400])),
                          const SizedBox(width: 16),
                          Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                                color: const Color(0xFFFFF0F0),
                                borderRadius: BorderRadius.circular(3),
                                border: Border.all(
                                    color: Colors.red.withOpacity(0.3))),
                          ),
                          const SizedBox(width: 6),
                          Text('ทนายไม่รับวันนี้',
                              style: TextStyle(
                                  fontSize: 11, color: Colors.grey[400])),
                        ],
                      ),
                    ]),
                  ),

                  // ── Time Slots ──────────────────────────────
                  if (_selectedDate != null && !_isUrgentCaseActive) ...[
                    const SizedBox(height: 20),
                    const Text('เลือกเวลา',
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1A2340))),
                    const SizedBox(height: 10),
                    if (_slotsLoading)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 32),
                        child:
                            Center(child: DotsLoader(color: Color(0xFF0262EC))),
                      )
                    else if (_timeSlots.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 24),
                        child: Center(
                          child: Text('ไม่มีช่วงเวลาว่างในวันนี้',
                              style: TextStyle(
                                  fontSize: 13, color: Colors.grey[400])),
                        ),
                      )
                    else
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                crossAxisSpacing: 10,
                                mainAxisSpacing: 10,
                                childAspectRatio: 3),
                        itemCount: _timeSlots.length,
                        itemBuilder: (_, i) {
                          final slot = _timeSlots[i];
                          final isAvail = slot['available'] == true;
                          final isSelected = _selectedTime == slot['title'];

                          return GestureDetector(
                            onTap: isAvail
                                ? () => setState(
                                    () => _selectedTime = slot['title'])
                                : null,
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? const Color(0xFF0262EC)
                                    : !isAvail
                                        ? const Color(0xFFF5F7FA)
                                        : Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                    color: isSelected
                                        ? const Color(0xFF0262EC)
                                        : const Color(0xFFEEF2F5)),
                              ),
                              child: Center(
                                child: Text(
                                  slot['title'].toString(),
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: isSelected
                                        ? Colors.white
                                        : !isAvail
                                            ? Colors.grey[300]
                                            : const Color(0xFF1A2340),
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                  ],
                ],
              ),
            ),
          ),

          // ── Next button ─────────────────────────────────────
          Padding(
            padding: EdgeInsets.fromLTRB(
                16, 8, 16, MediaQuery.of(context).padding.bottom + 16),
            child: primaryButton(
              label: 'ถัดไป',
              enabled: _selectedDate != null && _selectedTime != null,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => SummaryPage(
                      lawyer: widget.lawyer,
                      topic: widget.topic,
                      topicTitle: widget.topicTitle,
                      subTopic: widget.subTopic,
                      subTopicTitle: widget.subTopicTitle,
                      time: _selectedTime!,
                      date: _selectedDate,
                      details: widget.details,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
