import 'package:LawyerOnline/booking/summary-page.dart';
import 'package:LawyerOnline/component/appbar.dart';
import 'package:LawyerOnline/component/button.dart';
import 'package:LawyerOnline/component/loading_service.dart';
import 'package:flutter/material.dart';

class SchedulePage extends StatefulWidget {
  final dynamic lawyer;
  final String topic;
  final String subTopic;

  const SchedulePage(
      {required this.lawyer, required this.topic, required this.subTopic});

  @override
  State<SchedulePage> createState() => _SchedulePageState();
}

class _SchedulePageState extends State<SchedulePage> {
  DateTime _focusedDate = DateTime.now();
  DateTime? _selectedDate;
  String? _selectedTime;

  // final _timeSlots = [
  //   '09:00 - 10:00',
  //   '10:00 - 11:00',
  //   '11:00 - 12:00',
  //   '13:00 - 14:00',
  //   '14:00 - 15:00',
  //   '15:00 - 16:00',
  //   '16:00 - 17:00',
  // ];

  final List<dynamic> _timeSlots = [
    {
      "title": '09:00 - 10:00',
      "dateStart": DateTime(0, 0, 0, 9, 0),
      "dateEnd": DateTime(0, 0, 0, 10, 0),
      "isActive": true
    },
    {
      "title": '10:00 - 11:00',
      "dateStart": DateTime(0, 0, 0, 10, 0),
      "dateEnd": DateTime(0, 0, 0, 11, 0),
      "isActive": true
    },
    {
      "title": '11:00 - 12:00',
      "dateStart": DateTime(0, 0, 0, 11, 0),
      "dateEnd": DateTime(0, 0, 0, 12, 0),
      "isActive": true
    },
    {
      "title": '12:00 - 13:00',
      "dateStart": DateTime(0, 0, 0, 12, 0),
      "dateEnd": DateTime(0, 0, 0, 13, 0),
      "isActive": true
    },
    {
      "title": '13:00 - 14:00',
      "dateStart": DateTime(0, 0, 0, 13, 0),
      "dateEnd": DateTime(0, 0, 0, 14, 0),
      "isActive": true
    },
    {
      "title": '14:00 - 15:00',
      "dateStart": DateTime(0, 0, 0, 14, 0),
      "dateEnd": DateTime(0, 0, 0, 15, 0),
      "isActive": true
    },
    {
      "title": '15:00 - 16:00',
      "dateStart": DateTime(0, 0, 0, 15, 0),
      "dateEnd": DateTime(0, 0, 0, 16, 0),
      "isActive": true
    },
    {
      "title": '16:00 - 17:00',
      "dateStart": DateTime(0, 0, 0, 16, 0),
      "dateEnd": DateTime(0, 0, 0, 17, 0),
      "isActive": true
    },
  ];

  final _unavailableSlots = ['10:00 - 11:00', '14:00 - 15:00'];

  bool _slotsLoading = false;

  List<DateTime> _getDaysInMonth() {
    final first = DateTime(_focusedDate.year, _focusedDate.month, 1);
    final last = DateTime(_focusedDate.year, _focusedDate.month + 1, 0);
    return List.generate(
        last.day, (i) => DateTime(first.year, first.month, i + 1));
  }

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

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 0, 0, 0),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(9),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF0262EC), Color(0xFF34AAFF)],
            ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0262EC).withOpacity(0.4),
                blurRadius: 14,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child:
              const Icon(Icons.calendar_month, color: Colors.white, size: 18),
        ),
        const SizedBox(width: 10),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text(
            'เลือกวัน และเวลา',
            style: TextStyle(
              color: const Color(0xFF1A2340),
              fontSize: 16,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3,
            ),
          ),
          Text(
            'กดเลือกวันและเวลาที่ทนายว่างที่ต้องการนัดหมาย',
            style: TextStyle(
                color: const Color(0xFF1A2340).withOpacity(0.4), fontSize: 11),
          ),
        ]),
      ]),
    );
  }

  @override
  void initState() {
    super.initState();
    var dateNow = DateTime.now().hour;

    // setListTimeSlots();
    // print('>>>>>>> dateNow ${dateNow}');
    print('>>>>>>> ${_timeSlots}');
  }

  Future<void> setListTimeSlots() async {
    setState(() => _slotsLoading = true);

    // จำลอง async (เช่น fetch จาก API ในอนาคต)
    await Future.delayed(const Duration(milliseconds: 600));

    var dateNow = DateTime.now();
    setState(
      () {
        for (var e in _timeSlots) {
          final dateStart = (e['dateStart'] as DateTime).hour;
          if (_selectedDate!.day > dateNow.day ||
              _selectedDate!.month > dateNow.month) {
            e['isActive'] = true;
          } else {
            e['isActive'] = dateStart > dateNow.hour;
          }
        }
        _slotsLoading = false;
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final days = _getDaysInMonth();
    final firstWeekday = days.first.weekday % 7;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: appBar(
        title: "นัดหมายทนาย",
        backBtn: true,
        rightBtn: false,
        backAction: () => goBack(),
        rightAction: () => {},
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
                  const SizedBox(height: 14),
                  // ── Calendar Card ──────────────────────────
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
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
                            crossAxisCount: 7,
                            childAspectRatio: 1,
                          ),
                          itemCount: firstWeekday + days.length,
                          itemBuilder: (_, i) {
                            if (i < firstWeekday) return const SizedBox();
                            final day = days[i - firstWeekday];
                            final isSelected = _selectedDate != null &&
                                day.day == _selectedDate!.day &&
                                day.month == _selectedDate!.month;
                            final isPast = day.isBefore(DateTime.now()
                                .subtract(const Duration(days: 1)));

                            return GestureDetector(
                              onTap: isPast
                                  ? null
                                  : () {
                                      setState(
                                        () {
                                          _selectedDate = day;
                                          _selectedTime = null;
                                        },
                                      );
                                      setListTimeSlots();
                                    },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 150),
                                margin: const EdgeInsets.all(2),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? const Color(0xFF0262EC)
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Center(
                                  child: Text('${day.day}',
                                      style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: isSelected
                                              ? FontWeight.w700
                                              : FontWeight.w400,
                                          color: isSelected
                                              ? Colors.white
                                              : isPast
                                                  ? Colors.grey[300]
                                                  : const Color(0xFF1A2340))),
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),

                  // ── Time Slots ──────────────────────────────
                  if (_selectedDate != null) ...[
                    const SizedBox(height: 20),
                    const Text(
                      'เลือกเวลา',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1A2340),
                      ),
                    ),
                    // const SizedBox(height: 10),
                    // Text(
                    //   '*เมื่อเลือกช่วงเวลาแล้ว กรุณาเตรียมเวลาก่อนในการปรึกษาทนายความประมาณ 30 นาที',
                    //   style: TextStyle(fontSize: 11, color: Colors.red[400]),
                    // ),
                    const SizedBox(height: 10),
                    if (_slotsLoading)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 32),
                        child: Center(
                          child: DotsLoader(color: Color(0xFF0262EC)),
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
                          childAspectRatio: 3,
                        ),
                        itemCount: _timeSlots.length,
                        itemBuilder: (_, i) {
                          final slot = _timeSlots[i];
                          // final isUnavailable = _unavailableSlots.contains(slot);
                          final isSelected = _selectedTime == slot['title'];

                          return GestureDetector(
                            // ignore: unnecessary_null_comparison
                            onTap: slot == null
                                ? null
                                : () => setState(
                                      () {
                                        print(slot['title']);
                                        slot['isActive']
                                            ? _selectedTime = slot['title']
                                            : null;
                                      },
                                    ),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? const Color(0xFF0262EC)
                                    : !slot['isActive']
                                        ? const Color(0xFFF5F7FA)
                                        : Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isSelected
                                      ? const Color(0xFF0262EC)
                                      : const Color(0xFFEEF2F5),
                                ),
                              ),
                              child: Center(
                                child: Text(slot['title'].toString(),
                                    style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: isSelected
                                            ? Colors.white
                                            : !slot['isActive']
                                                ? Colors.grey[300]
                                                : const Color(0xFF1A2340))),
                              ),
                            ),
                          );
                        },
                      ),

                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'ไม่ว่าง',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[400],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: const Color(0xFF0262EC),
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'เลือกแล้ว',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[400],
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(
                16, 8, 16, MediaQuery.of(context).padding.bottom + 16),
            child: primaryButton(
              label: 'ถัดไป',
              enabled: _selectedDate != null && _selectedTime != null,
              onTap: () {
                // widget.onSelected(_selectedDate!, _selectedTime!);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => SummaryPage(
                      lawyer: widget.lawyer,
                      topic: widget.topic,
                      subTopic: widget.subTopic,
                      time: _selectedTime!,
                      date: _selectedDate,
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

  void goBack() async {
    Navigator.pop(context, false);
  }
}
