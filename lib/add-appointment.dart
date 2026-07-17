import 'package:LawyerOnline/booking/summary-page.dart';
import 'package:LawyerOnline/component/appbar.dart';
import 'package:LawyerOnline/component/app_dropdown.dart';
import 'package:LawyerOnline/component/dialog_service.dart';
import 'package:LawyerOnline/component/loading_service.dart';
import 'package:LawyerOnline/menu.dart';
import 'package:LawyerOnline/shared/api_provider.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class AppAppointment extends StatefulWidget {
  AppAppointment({
    Key? key,
    this.model,
    this.title,
    this.lawyer,
    this.topic,
    this.subTopic,
    this.topicTitle,
    this.subTopicTitle,
  }) : super(key: key);

  dynamic model;
  String? title;
  String? topic;
  String? topicTitle;
  String? subTopic;
  String? subTopicTitle;
  dynamic lawyer;

  @override
  State<AppAppointment> createState() => _AppAppointmentState();
}

class _AppAppointmentState extends State<AppAppointment> {
  final TextEditingController titleController   = TextEditingController();
  final TextEditingController detailsController = TextEditingController();

  dynamic _selectedTopic;
  dynamic _selectedSubCase;

  DateTime _focusedDate = DateTime.now();
  DateTime? _selectedDate;
  String?   _selectedTime;

  // ── slot & day data จาก API ─────────────────────────────
  List<dynamic> _timeSlots      = [];
  List<dynamic> _lawyerOpenDays = [];
  bool _slotsLoading            = false;
  bool _scheduleLoaded          = false;

  // ── topic list ──────────────────────────────────────────
  List<dynamic> _caseTypeList    = [];
  bool          isLoadingTopics  = true;

  final _thMonths = ['', 'ม.ค.', 'ก.พ.', 'มี.ค.', 'เม.ย.', 'พ.ค.', 'มิ.ย.',
      'ก.ค.', 'ส.ค.', 'ก.ย.', 'ต.ค.', 'พ.ย.', 'ธ.ค.'];
  final _thDays = ['อา', 'จ', 'อ', 'พ', 'พฤ', 'ศ', 'ส'];

  // ── can proceed ─────────────────────────────────────────
  bool get _canSubmit =>
      (widget.topic != null || _selectedTopic != null) &&
      (widget.subTopic != null || _selectedSubCase != null) &&
      _selectedDate != null &&
      _selectedTime != null;

  String get _topicCode     => widget.topic    ?? _selectedTopic?['code']    ?? '';
  String get _topicTitle    => widget.topicTitle ?? _selectedTopic?['title'] ?? '';
  String get _subTopicCode  => widget.subTopic  ?? _selectedSubCase?['code'] ?? '';
  String get _subTopicTitle => widget.subTopicTitle ?? _selectedSubCase?['title'] ?? '';

  List<DateTime> get _daysInMonth {
    final first = DateTime(_focusedDate.year, _focusedDate.month, 1);
    final last  = DateTime(_focusedDate.year, _focusedDate.month + 1, 0);
    return List.generate(
        last.day, (i) => DateTime(first.year, first.month, i + 1));
  }

  // ── เช็คว่าทนายเปิดวันนั้นไหม ───────────────────────────
  bool _isDayOpenForLawyer(DateTime date) {
    if (_lawyerOpenDays.isEmpty) return true;
    final dayOfWeek = date.weekday % 7; // 0=อาทิตย์ ... 6=เสาร์
    final found = _lawyerOpenDays.firstWhere(
      (d) => d['day'] == dayOfWeek,
      orElse: () => null,
    );
    return found == null ? true : found['isOpen'] == true;
  }

  @override
  void initState() {
    super.initState();
    callReadTopic();
    // โหลด slot วันนี้ก่อน (ถ้ามี lawyer)
    if (widget.lawyer != null) {
      readTimeSlot(DateFormat('yyyy-MM-dd').format(DateTime.now()));
    }
  }

  @override
  void dispose() {
    titleController.dispose();
    detailsController.dispose();
    super.dispose();
  }

  Future<void> callReadTopic() async {
    try {
      final param = await postDio('$server/m/topic/read', {});
      setState(() {
        _caseTypeList = param['objectData'];
        isLoadingTopics = false;
      });
    } catch (_) {
      setState(() => isLoadingTopics = false);
    }
  }

  Future<void> readTimeSlot(String date) async {
    if (widget.lawyer == null) return;
    setState(() => _slotsLoading = true);
    try {
      final param = await postDio(
        '$server/m/register/checkSlot',
        {
          'lawyerCode': widget.lawyer is Map
              ? widget.lawyer['code']
              : widget.lawyer.toString(),
          'date': date,
        },
      );

      final objectData = param['objectData'];

      // โหลด lawyerSchedule ครั้งแรกครั้งเดียว
      if (!_scheduleLoaded && objectData['lawyerSchedule'] != null) {
        final schedule = objectData['lawyerSchedule'];
        _lawyerOpenDays = List<dynamic>.from(schedule['days'] ?? []);
        _scheduleLoaded = true;
      }

      final dateCheck = objectData['dateCheck'];
      final slots = List<dynamic>.from(dateCheck?['slots'] ?? []);

      setState(() {
        _timeSlots = slots;
        _selectedTime = null;
        _slotsLoading = false;
      });
    } catch (e) {
      print('readTimeSlot error: $e');
      setState(() => _slotsLoading = false);
    }
  }

  // ═══════════════════════════════════════════════════════
  //  BUILD
  // ═══════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    const topicColor = Color(0xFF0262EC);

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      behavior: HitTestBehavior.opaque,
      child: Scaffold(
        backgroundColor: const Color(0xFFEEF2F5),
        appBar: appBar(
          title: widget.title ?? 'ตารางวันปรึกษา',
          backBtn: true,
          rightBtn: false,
          backAction: () => Navigator.pop(context, false),
          rightAction: () {},
        ),
        body: isLoadingTopics
            ? _loadingState()
            : Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // ── เลือกประเภทหัวข้อ ───────────
                          if (widget.topic == null) ...[
                            _buildTopicSection(topicColor),
                            const SizedBox(height: 16),
                          ],

                          // ── หัวข้อย่อย ──────────────────
                          if (_selectedTopic != null) ...[
                            _buildSubCaseDropdown(topicColor),
                            const SizedBox(height: 16),
                          ],

                          // ── วันที่ทนายเปิด (banner) ──────
                          _buildOpenDaysBanner(),

                          // ── Calendar ─────────────────────
                          _buildCalendarCard(),
                          const SizedBox(height: 16),

                          // ── Time Slots ───────────────────
                          if (_selectedDate != null) ...[
                            _buildTimeSlots(),
                            const SizedBox(height: 16),
                          ],

                          // ── รายละเอียดเพิ่มเติม ──────────
                          _buildTextArea(
                            title: 'รายละเอียดเพิ่มเติม',
                            controller: detailsController,
                          ),
                          const SizedBox(height: 32),
                        ],
                      ),
                    ),
                  ),
                  _buildBottomButton(topicColor),
                ],
              ),
      ),
    );
  }

  // ── Banner วันที่เปิด ────────────────────────────────────
  Widget _buildOpenDaysBanner() {
    if (_lawyerOpenDays.isEmpty) return const SizedBox(height: 14);
    final openDays = _lawyerOpenDays
        .where((d) => d['isOpen'] == true)
        .map((d) => d['title']?.toString() ?? '')
        .where((t) => t.isNotEmpty)
        .toList();
    if (openDays.isEmpty) return const SizedBox(height: 14);

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
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

  // ════════════════════════════════════════════════════════
  //  Topic Grid
  // ════════════════════════════════════════════════════════
  Widget _buildTopicSection(Color topicColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _fieldLabel('ประเภทหัวข้อที่จะปรึกษา', required: true),
        const SizedBox(height: 10),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            childAspectRatio: 0.9,
          ),
          itemCount: _caseTypeList.length,
          itemBuilder: (_, i) {
            final item       = _caseTypeList[i];
            final isSelected = _selectedTopic?['code'] == item['code'];

            return GestureDetector(
              onTap: () => setState(() {
                _selectedTopic   = isSelected ? null : item;
                _selectedSubCase = null;
              }),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                decoration: BoxDecoration(
                  color: isSelected
                      ? topicColor.withOpacity(0.1)
                      : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected ? topicColor : const Color(0xFFE2E8F4),
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                              color: topicColor.withOpacity(0.18),
                              blurRadius: 8,
                              offset: const Offset(0, 2))
                        ]
                      : [
                          BoxShadow(
                              color: Colors.black.withOpacity(0.04),
                              blurRadius: 4,
                              offset: const Offset(0, 1))
                        ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.network(item['imageUrl'], width: 50, height: 50),
                    const SizedBox(height: 4),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 3),
                      child: Text(
                        item['title'] as String,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: isSelected
                              ? FontWeight.w700
                              : FontWeight.w500,
                          color: isSelected
                              ? topicColor
                              : const Color(0xFF5B6E8A),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  // ════════════════════════════════════════════════════════
  //  Sub-case Dropdown
  // ════════════════════════════════════════════════════════
  Widget _buildSubCaseDropdown(Color color) {
    final rawSubs   = _selectedTopic['subTopics'];
    final subTopics = (rawSubs is List ? rawSubs : <dynamic>[])
        .whereType<Map<String, dynamic>>()
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _fieldLabel('หัวข้อย่อย', required: true),
        const SizedBox(height: 6),
        AppDropdownField<String>(
          value: _selectedSubCase?['code'] as String?,
          hint: 'เลือกหัวข้อย่อย',
          prefixIcon: Icons.subdirectory_arrow_right_rounded,
          accentColor: color,
          items: subTopics
              .map(
                (s) => DropdownMenuItem<String>(
                  value: s['code'] as String,
                  child: Text(
                    s['title'] as String,
                    style: AppDropdownStyles.itemStyle(),
                  ),
                ),
              )
              .toList(),
          onChanged: (val) {
            final sub = subTopics.firstWhere(
              (s) => s['code'] == val,
              orElse: () => {},
            );
            setState(() => _selectedSubCase = sub);
          },
        ),
      ],
    );
  }

  // ════════════════════════════════════════════════════════
  //  Calendar
  // ════════════════════════════════════════════════════════
  Widget _buildCalendarCard() {
    final days         = _daysInMonth;
    final firstWeekday = days.first.weekday % 7;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _fieldLabel('วันนัดหมายปรึกษา', required: true),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2))
            ],
          ),
          child: Column(children: [
            // Month nav
            Row(children: [
              GestureDetector(
                onTap: () => setState(() => _focusedDate =
                    DateTime(_focusedDate.year, _focusedDate.month - 1, 1)),
                child: Container(
                  width: 32, height: 32,
                  decoration: BoxDecoration(
                      color: const Color(0xFFF5F7FA),
                      borderRadius: BorderRadius.circular(8)),
                  child: const Icon(Icons.chevron_left_rounded,
                      color: Color(0xFF1A2340), size: 20),
                ),
              ),
              Expanded(
                child: Text(
                  '${_thMonths[_focusedDate.month]} ${_focusedDate.year + 543}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: Color(0xFF1A2340)),
                ),
              ),
              GestureDetector(
                onTap: () => setState(() => _focusedDate =
                    DateTime(_focusedDate.year, _focusedDate.month + 1, 1)),
                child: Container(
                  width: 32, height: 32,
                  decoration: BoxDecoration(
                      color: const Color(0xFFF5F7FA),
                      borderRadius: BorderRadius.circular(8)),
                  child: const Icon(Icons.chevron_right_rounded,
                      color: Color(0xFF1A2340), size: 20),
                ),
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

            // Grid
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 7, childAspectRatio: 1),
              itemCount: firstWeekday + days.length,
              itemBuilder: (_, i) {
                if (i < firstWeekday) return const SizedBox();
                final day        = days[i - firstWeekday];
                final isSelected = _selectedDate != null &&
                    day.day == _selectedDate!.day &&
                    day.month == _selectedDate!.month;
                final isPast = day.isBefore(
                    DateTime.now().subtract(const Duration(days: 1)));
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
                          ? Border.all(color: Colors.red.withOpacity(0.2))
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
          ]),
        ),
      ],
    );
  }

  // ════════════════════════════════════════════════════════
  //  Time Slots
  // ════════════════════════════════════════════════════════
  Widget _buildTimeSlots() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _fieldLabel('เลือกเวลา', required: true),
        const SizedBox(height: 10),
        if (_slotsLoading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 32),
            child: Center(child: DotsLoader(color: Color(0xFF0262EC))),
          )
        else if (_timeSlots.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Center(
              child: Text('ไม่มีช่วงเวลาว่างในวันนี้',
                  style: TextStyle(fontSize: 13, color: Colors.grey[400])),
            ),
          )
        else ...[
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 3.2),
            itemCount: _timeSlots.length,
            itemBuilder: (_, i) {
              final slot       = _timeSlots[i];
              final isAvail    = slot['available'] == true;
              final isSelected = _selectedTime == slot['title'];

              return GestureDetector(
                onTap: isAvail
                    ? () => setState(() => _selectedTime = slot['title'])
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
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                                color: const Color(0xFF0262EC).withOpacity(0.25),
                                blurRadius: 8,
                                offset: const Offset(0, 2))
                          ]
                        : [],
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
          const SizedBox(height: 8),
          // Legend
          Row(children: [
            Container(
                width: 10, height: 10,
                decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(3))),
            const SizedBox(width: 6),
            Text('ไม่ว่าง',
                style: TextStyle(fontSize: 11, color: Colors.grey[400])),
            const SizedBox(width: 16),
            Container(
                width: 10, height: 10,
                decoration: BoxDecoration(
                    color: const Color(0xFF0262EC),
                    borderRadius: BorderRadius.circular(3))),
            const SizedBox(width: 6),
            Text('เลือกแล้ว',
                style: TextStyle(fontSize: 11, color: Colors.grey[400])),
            const SizedBox(width: 16),
            Container(
                width: 10, height: 10,
                decoration: BoxDecoration(
                    color: const Color(0xFFFFF0F0),
                    borderRadius: BorderRadius.circular(3),
                    border:
                        Border.all(color: Colors.red.withOpacity(0.3)))),
            const SizedBox(width: 6),
            Text('ทนายไม่รับวันนี้',
                style: TextStyle(fontSize: 11, color: Colors.grey[400])),
          ]),
        ],
      ],
    );
  }

  // ════════════════════════════════════════════════════════
  //  Bottom Button
  // ════════════════════════════════════════════════════════
  Widget _buildBottomButton(Color topicColor) {
    return Container(
      padding: EdgeInsets.fromLTRB(
          16, 10, 16, MediaQuery.of(context).padding.bottom + 14),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
              color: Color(0x12000000),
              blurRadius: 10,
              offset: Offset(0, -3))
        ],
      ),
      child: GestureDetector(
        onTap: _canSubmit
            ? () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => SummaryPage(
                      lawyer: widget.lawyer,
                      topic: _topicCode,
                      topicTitle: _topicTitle,
                      subTopic: _subTopicCode,
                      subTopicTitle: _subTopicTitle,
                      time: _selectedTime!,
                      date: _selectedDate,
                      details: detailsController.text,
                    ),
                  ),
                )
            : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: 52,
          decoration: BoxDecoration(
            gradient: _canSubmit
                ? LinearGradient(
                    colors: [topicColor, topicColor.withOpacity(0.8)],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight)
                : null,
            color: _canSubmit ? null : const Color(0xFFCDD5E0),
            borderRadius: BorderRadius.circular(14),
            boxShadow: _canSubmit
                ? [
                    BoxShadow(
                        color: topicColor.withOpacity(0.35),
                        blurRadius: 12,
                        offset: const Offset(0, 4))
                  ]
                : null,
          ),
          child: Center(
            child: Text(
              'ต่อไป',
              style: TextStyle(
                color: _canSubmit ? Colors.white : Colors.grey[400],
                fontWeight: FontWeight.w700,
                fontSize: 15,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ════════════════════════════════════════════════════════
  //  Shared Widgets
  // ════════════════════════════════════════════════════════
  Widget _loadingState() {
    return const AppLoadingView(showDots: false);
  }

  Widget _fieldLabel(String label, {bool required = false}) {
    return RichText(
      text: TextSpan(
        text: label,
        style: GoogleFonts.prompt(color: const Color(0xFF0262EC), fontSize: 12),
        children: [
          if (required)
            TextSpan(
              text: ' *',
              style: GoogleFonts.prompt(
                  color: const Color(0xFFDB2E26), fontSize: 12),
            ),
        ],
      ),
    );
  }

  InputDecoration _inputDecor({Widget? prefixIcon}) {
    return InputDecoration(
      prefixIcon: prefixIcon,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFECEDF0))),
      enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFECEDF0))),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              const BorderSide(color: Color(0xFF0262EC), width: 1.5)),
      fillColor: const Color(0xFFFAFAFA),
      filled: true,
    );
  }

  Widget _buildTextArea({
    required String title,
    required TextEditingController controller,
    bool required = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _fieldLabel(title, required: required),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          maxLines: null,
          minLines: 4,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.all(14),
            hintText: 'พิมพ์รายละเอียดที่นี่...',
            hintStyle:
                const TextStyle(color: Colors.grey, fontSize: 13),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                    const BorderSide(color: Color(0xFFECEDF0))),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                    const BorderSide(color: Color(0xFFECEDF0))),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                    color: Color(0xFF0262EC), width: 1.5)),
          ),
        ),
      ],
    );
  }
}

class _Palette {
  final Color  primary;
  final Color  secondary;
  final String emoji;
  const _Palette(this.primary, this.secondary, this.emoji);
}