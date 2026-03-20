import 'package:LawyerOnline/booking/summary-page.dart';
import 'package:LawyerOnline/component/appbar.dart';
import 'package:LawyerOnline/component/dialog_service.dart';
import 'package:LawyerOnline/menu.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

// ══════════════════════════════════════════════════════════
//  AppAppointment — ปรับให้
//  • เลือกวันจาก Calendar เหมือน SchedulePage
//  • เลือกเวลาจาก Time Slots เหมือน SchedulePage
//  • เลือกประเภทหัวข้อ Grid เหมือน TopicPage
//  • ปุ่มถัดไป → ไป PaymentPage (หรือ DialogService)
// ══════════════════════════════════════════════════════════

class AppAppointment extends StatefulWidget {
  AppAppointment(
      {Key? key,
      this.model,
      this.title,
      this.lawyer,
      this.topic,
      this.subTopic})
      : super(key: key);

  dynamic model;
  String? title;
  String? topic;
  String? subTopic;
  dynamic lawyer;

  @override
  State<AppAppointment> createState() => _AppAppointmentState();
}

class _AppAppointmentState extends State<AppAppointment> {
  final TextEditingController titleController = TextEditingController();
  final TextEditingController detailsController = TextEditingController();

  // ── Topic / SubCase state ─────────────────────────────
  dynamic _selectedTopic;
  dynamic _selectedSubCase;

  // ── Calendar state ────────────────────────────────────
  DateTime _focusedDate = DateTime.now();
  DateTime? _selectedDate;
  String? _selectedTime;

  String? topic;
  String? subTopic;

  // ── Time slots ────────────────────────────────────────
  final _timeSlots = [
    '09:00 - 10:00',
    '10:00 - 11:00',
    '11:00 - 12:00',
    '13:00 - 14:00',
    '14:00 - 15:00',
    '15:00 - 16:00',
    '16:00 - 17:00',
  ];
  final _unavailableSlots = ['10:00 - 11:00', '14:00 - 15:00'];

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

  // ── caseTypeList ──────────────────────────────────────
  static const _palettes = [
    _Palette(Color(0xFF64748B), Color(0xFF94A3B8), '💬'),
    _Palette(Color(0xFF0262EC), Color(0xFF34AAFF), '⭐'),
    _Palette(Color(0xFFE11D48), Color(0xFFFF6B9D), '👨‍👩‍👧'),
    _Palette(Color(0xFFFF6B35), Color(0xFFFFAA60), '💰'),
    _Palette(Color(0xFFDC2626), Color(0xFFFF6B6B), '🔒'),
    _Palette(Color(0xFF059669), Color(0xFF34D399), '🏠'),
    _Palette(Color(0xFF7C3AED), Color(0xFFA78BFA), '🏢'),
    _Palette(Color(0xFF0891B2), Color(0xFF22D3EE), '💻'),
    _Palette(Color(0xFFD97706), Color(0xFFFBBF24), '👷'),
    _Palette(Color(0xFFDB2777), Color(0xFFF472B6), '🛡️'),
    _Palette(Color(0xFF6D28D9), Color(0xFFC084FC), '⚖️'),
    _Palette(Color(0xFF0F766E), Color(0xFF2DD4BF), '🌐'),
  ];

  final List<dynamic> _caseTypeList = [
    {
      'code': '0',
      'title': 'ทั่วไป',
      'emoji': '💬',
      'color': 0xFF64748B,
      'subCase': <dynamic>[]
    },
    {
      'code': '1',
      'title': 'คดีที่พบบ่อย',
      'emoji': '⭐',
      'color': 0xFF0262EC,
      'subCase': [
        {'code': '0', 'title': 'หนี้กู้ยืมเงิน / ลูกหนี้-เจ้าหนี้'},
        {'code': '1', 'title': 'ตรวจร่างสัญญา'},
        {'code': '2', 'title': 'พินัยกรรม / มรดก'},
        {'code': '3', 'title': 'อุบัติเหตุจราจร'},
        {'code': '4', 'title': 'หมิ่นประมาททางออนไลน์'},
        {'code': '5', 'title': 'โดนโกงออนไลน์'},
      ]
    },
    {
      'code': '2',
      'title': 'ครอบครัวและมรดก',
      'emoji': '👨‍👩‍👧',
      'color': 0xFFE11D48,
      'subCase': [
        {'code': '0', 'title': 'ฟ้องชู้ / เรียกค่าทดแทน'},
        {'code': '1', 'title': 'พินัยกรรม / มรดก'},
        {'code': '2', 'title': 'ฟ้องหย่า / แบ่งสินสมรส'},
        {'code': '3', 'title': 'รับรองบุตร / อำนาจปกครองบุตร'},
        {'code': '4', 'title': 'พรากผู้เยาว์'},
      ]
    },
    {
      'code': '3',
      'title': 'หนี้สินและการเงิน',
      'emoji': '💰',
      'color': 0xFFFF6B35,
      'subCase': [
        {'code': '0', 'title': 'หนี้กู้ยืมเงิน / ดอกเบี้ย'},
        {'code': '1', 'title': 'อายัดบัญชี / บัญชีม้า'},
        {'code': '2', 'title': 'เช่าซื้อ / ค้ำประกัน'},
        {'code': '3', 'title': 'ล้มละลาย / ฟื้นฟูกิจการ'},
      ]
    },
    {
      'code': '4',
      'title': 'อาญาและอาชญากรรม',
      'emoji': '🔒',
      'color': 0xFFDC2626,
      'subCase': [
        {'code': '0', 'title': 'ลักทรัพย์ / ชิงทรัพย์'},
        {'code': '1', 'title': 'หมิ่นประมาท'},
        {'code': '2', 'title': 'ทำร้ายร่างกาย'},
        {'code': '3', 'title': 'ฉ้อโกง / ยักยอกทรัพย์'},
        {'code': '4', 'title': 'คดียาเสพติด'},
      ]
    },
    {
      'code': '5',
      'title': 'ทรัพย์สินและที่ดิน',
      'emoji': '🏠',
      'color': 0xFF059669,
      'subCase': [
        {'code': '0', 'title': 'ซื้อขายที่ดิน / โอนที่ดิน'},
        {'code': '1', 'title': 'เช่าบ้าน / ขับไล่ผู้เช่า'},
        {'code': '2', 'title': 'บุกรุก / ครอบครองปรปักษ์'},
      ]
    },
    {
      'code': '6',
      'title': 'ธุรกิจและบริษัท',
      'emoji': '🏢',
      'color': 0xFF7C3AED,
      'subCase': [
        {'code': '0', 'title': 'จดทะเบียนบริษัท'},
        {'code': '1', 'title': 'ตรวจร่างสัญญา'},
        {'code': '2', 'title': 'ทรัพย์สินทางปัญญา'},
      ]
    },
    {
      'code': '7',
      'title': 'คดีออนไลน์',
      'emoji': '💻',
      'color': 0xFF0891B2,
      'subCase': [
        {'code': '0', 'title': 'หลอกโอนเงินออนไลน์'},
        {'code': '1', 'title': 'หมิ่นประมาททางออนไลน์'},
        {'code': '2', 'title': 'โดนโกงออนไลน์'},
      ]
    },
    {
      'code': '8',
      'title': 'แรงงาน',
      'emoji': '👷',
      'color': 0xFFD97706,
      'subCase': [
        {'code': '0', 'title': 'เลิกจ้างไม่เป็นธรรม'},
        {'code': '1', 'title': 'สัญญาจ้างงาน'},
        {'code': '2', 'title': 'แรงงานต่างด้าว'},
      ]
    },
    {
      'code': '9',
      'title': 'ประกันภัย',
      'emoji': '🛡️',
      'color': 0xFFDB2777,
      'subCase': [
        {'code': '0', 'title': 'เคลมประกัน คปภ.'},
        {'code': '1', 'title': 'อุบัติเหตุจราจร'},
      ]
    },
    {
      'code': '10',
      'title': 'ฟ้องศาล',
      'emoji': '⚖️',
      'color': 0xFF6D28D9,
      'subCase': [
        {'code': '0', 'title': 'ละเมิดฟ้องเรียกค่าเสียหาย'},
        {'code': '1', 'title': 'เหตุเดือดร้อนรำคาญ'},
      ]
    },
    {
      'code': '11',
      'title': 'อื่นๆ/ต่างประเทศ',
      'emoji': '🌐',
      'color': 0xFF0F766E,
      'subCase': [
        {'code': '0', 'title': 'Visa / Work Permit'},
        {'code': '1', 'title': 'กฎหมายการค้าระหว่างประเทศ'},
      ]
    },
  ];

  // ── Lawyer list ───────────────────────────────────────
  final List<dynamic> lawyerList = [
    {'code': '0', 'title': 'ศักดิ์สิทธิ์ พิพากษ์'},
    {'code': '1', 'title': 'ธนากร นิติศักดิ์'},
    {'code': '2', 'title': 'พงษ์ภพ ยุติธรรม'},
    {'code': '3', 'title': 'อารีย์ ศิษย์กฎหมาย'},
    {'code': '4', 'title': 'Sachin K'},
  ];
  String? _selectedLawyerCode;

  // ── can proceed ───────────────────────────────────────
  bool get _canSubmit =>
      (widget.topic != null || _selectedTopic != null) &&
      (widget.subTopic != null || _selectedSubCase != null) &&
      _selectedDate != null &&
      _selectedTime != null;

  List<dynamic> get _subCases {
    if (_selectedTopic == null) return [];
    return (_selectedTopic!['subCase'] as List<dynamic>)
        .cast<dynamic>()
        .where((s) => (s['title'] as String).trim().isNotEmpty)
        .toList();
  }

  List<DateTime> get _daysInMonth {
    final first = DateTime(_focusedDate.year, _focusedDate.month, 1);
    final last = DateTime(_focusedDate.year, _focusedDate.month + 1, 0);
    return List.generate(
        last.day, (i) => DateTime(first.year, first.month, i + 1));
  }

  @override
  void initState() {
    super.initState();
    if (widget.lawyer != null) {
      _selectedLawyerCode = widget.lawyer.toString();
    }
  }

  @override
  void dispose() {
    titleController.dispose();
    detailsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final topicColor = Color(0xFF0262EC);
    // _selectedTopic != null
    //     ? Color(_selectedTopic!['color'] as int)
    //     : const Color(0xFF0262EC);

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      behavior: HitTestBehavior.opaque,
      child: Scaffold(
        backgroundColor: const Color(0xFFEEF2F5),
        appBar: appBar(
          title: widget.title ?? 'ตารางวันปรึกษา',
          backBtn: true,
          rightBtn: false,
          backAction: () => goBack(),
          rightAction: () {},
        ),
        body: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── หัวเรื่อง ─────────────────────────
                    // _buildTextField(
                    //   title: 'หัวเรื่อง',
                    //   hint: 'กรุณาใส่หัวเรื่อง',
                    //   controller: titleController,
                    // ),
                    // const SizedBox(height: 16),

                    // ── เลือกประเภทหัวข้อ (grid) ──────────
                    widget.topic == null ? Column(
                      children: [
                        _buildTopicSection(topicColor),
                        const SizedBox(height: 16),
                      ],
                    ) : const SizedBox(),

                    // ── หัวข้อย่อย (dropdown) ─────────────
                    if (_selectedTopic != null && _subCases.isNotEmpty) ...[
                      _buildSubCaseDropdown(topicColor),
                      const SizedBox(height: 16),
                    ],

                    // ── ทนายที่ปรึกษา ─────────────────────
                    // _buildLawyerDropdown(),
                    // const SizedBox(height: 16),

                    // ── Calendar ──────────────────────────
                    _buildCalendarCard(),
                    const SizedBox(height: 16),

                    // ── Time Slots ────────────────────────
                    if (_selectedDate != null) ...[
                      _buildTimeSlots(),
                      const SizedBox(height: 16),
                    ],

                    // ── รายละเอียดเพิ่มเติม ───────────────
                    _buildTextArea(
                      title: 'รายละเอียดเพิ่มเติม',
                      controller: detailsController,
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),

            // ── Bottom Button ──────────────────────────
            _buildBottomButton(topicColor),
          ],
        ),
      ),
    );
  }

  // ════════════════════════════════════════════════════════
  //  Topic Grid — เหมือน TopicPage
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
            final item = _caseTypeList[i];
            final color = Color(item['color'] as int);
            final isSelected = _selectedTopic?['code'] == item['code'];

            return GestureDetector(
              onTap: () {
                setState(() {
                  _selectedTopic = isSelected ? null : item;
                  _selectedSubCase = null;
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                decoration: BoxDecoration(
                  color: isSelected ? color.withOpacity(0.1) : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected ? color : const Color(0xFFE2E8F4),
                    width: isSelected ? 1.5 : 1,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                              color: color.withOpacity(0.18),
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
                    Text(item['emoji'] as String,
                        style: const TextStyle(fontSize: 20)),
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
                          fontWeight:
                              isSelected ? FontWeight.w700 : FontWeight.w500,
                          color: isSelected ? color : const Color(0xFF5B6E8A),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _fieldLabel('หัวข้อย่อย', required: true),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          value: _selectedSubCase?['title'] as String?,
          isExpanded: true,
          onChanged: (val) {
            final sub = _subCases.firstWhere((s) => s['title'] == val,
                orElse: () => {});
            setState(() => _selectedSubCase = sub.isEmpty ? null : sub);
          },
          decoration: _inputDecor(
            prefixIcon: Icon(Icons.subdirectory_arrow_right_rounded,
                color: color, size: 20),
          ),
          hint: Text('เลือกหัวข้อย่อย',
              style: TextStyle(color: Colors.grey[400], fontSize: 13)),
          icon: Icon(Icons.keyboard_arrow_down_rounded, color: color),
          dropdownColor: Colors.white,
          borderRadius: BorderRadius.circular(14),
          items: _subCases
              .map((s) => DropdownMenuItem<String>(
                    value: s['title'] as String,
                    child: Text(s['title'] as String,
                        style: const TextStyle(fontSize: 13)),
                  ))
              .toList(),
        ),
      ],
    );
  }

  // ════════════════════════════════════════════════════════
  //  Lawyer Dropdown
  // ════════════════════════════════════════════════════════

  Widget _buildLawyerDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _fieldLabel('ทนายที่ปรึกษา'),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          value: _selectedLawyerCode,
          isExpanded: true,
          onChanged: (val) => setState(() => _selectedLawyerCode = val),
          decoration: _inputDecor(
            prefixIcon: const Icon(Icons.person_outline_rounded,
                color: Color(0xFF0262EC), size: 20),
          ),
          hint: Text('เลือกทนายความ',
              style: TextStyle(color: Colors.grey[400], fontSize: 13)),
          icon: const Icon(Icons.keyboard_arrow_down_rounded,
              color: Color(0xFF0262EC)),
          dropdownColor: Colors.white,
          borderRadius: BorderRadius.circular(14),
          items: lawyerList
              .map((l) => DropdownMenuItem<String>(
                    value: l['code'],
                    child:
                        Text(l['title']!, style: const TextStyle(fontSize: 13)),
                  ))
              .toList(),
        ),
      ],
    );
  }

  // ════════════════════════════════════════════════════════
  //  Calendar — เหมือน SchedulePage
  // ════════════════════════════════════════════════════════

  Widget _buildCalendarCard() {
    final days = _daysInMonth;
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
                  offset: const Offset(0, 2)),
            ],
          ),
          child: Column(
            children: [
              // Month nav
              Row(children: [
                GestureDetector(
                  onTap: () => setState(() => _focusedDate =
                      DateTime(_focusedDate.year, _focusedDate.month - 1, 1)),
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F7FA),
                      borderRadius: BorderRadius.circular(8),
                    ),
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
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F7FA),
                      borderRadius: BorderRadius.circular(8),
                    ),
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
              // Calendar grid
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
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
                  final isPast = day.isBefore(
                      DateTime.now().subtract(const Duration(days: 1)));

                  return GestureDetector(
                    onTap: isPast
                        ? null
                        : () => setState(() {
                              _selectedDate = day;
                              _selectedTime = null;
                            }),
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
      ],
    );
  }

  // ════════════════════════════════════════════════════════
  //  Time Slots — เหมือน SchedulePage
  // ════════════════════════════════════════════════════════

  Widget _buildTimeSlots() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _fieldLabel('เลือกเวลา', required: true),
        const SizedBox(height: 10),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 3.2,
          ),
          itemCount: _timeSlots.length,
          itemBuilder: (_, i) {
            final slot = _timeSlots[i];
            final isUnavailable = _unavailableSlots.contains(slot);
            final isSelected = _selectedTime == slot;

            return GestureDetector(
              onTap: isUnavailable
                  ? null
                  : () => setState(() => _selectedTime = slot),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFF0262EC)
                      : isUnavailable
                          ? const Color(0xFFF5F7FA)
                          : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected
                        ? const Color(0xFF0262EC)
                        : const Color(0xFFEEF2F5),
                  ),
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
                  child: Text(slot,
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isSelected
                              ? Colors.white
                              : isUnavailable
                                  ? Colors.grey[300]
                                  : const Color(0xFF1A2340))),
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 8),
        // Legend
        Row(children: [
          Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(3))),
          const SizedBox(width: 6),
          Text('ไม่ว่าง',
              style: TextStyle(fontSize: 11, color: Colors.grey[400])),
          const SizedBox(width: 16),
          Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                  color: const Color(0xFF0262EC),
                  borderRadius: BorderRadius.circular(3))),
          const SizedBox(width: 6),
          Text('เลือกแล้ว',
              style: TextStyle(fontSize: 11, color: Colors.grey[400])),
        ]),
      ],
    );
  }

  // ════════════════════════════════════════════════════════
  //  Bottom Button → PaymentPage / Dialog
  // ════════════════════════════════════════════════════════

  Widget _buildBottomButton(Color topicColor) {
    return Container(
      padding: EdgeInsets.fromLTRB(
          16, 10, 16, MediaQuery.of(context).padding.bottom + 14),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
              color: Color(0x12000000), blurRadius: 10, offset: Offset(0, -3))
        ],
      ),
      child: GestureDetector(
        onTap: _canSubmit
            ? () {
                // ── navigate ไป PaymentPage หรือ ShowSuccess ──
                // DialogService.showSuccess(
                //   context,
                //   title: 'จองนัดหมายสำเร็จ',
                //   message:
                //       'ระบบได้บันทึกนัดหมายใหม่เรียบร้อยแล้ว',
                //   onClose: () {
                //     Navigator.of(context).pushAndRemoveUntil(
                //       MaterialPageRoute(
                //           builder: (_) => MenuPage()),
                //       (route) => route.isFirst,
                //     );
                //   },
                // );
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => SummaryPage(
                      lawyer: widget.lawyer,
                      topic: widget.topic ?? _selectedTopic['title'],
                      subTopic: widget.subTopic ?? _selectedSubCase['title'],
                      time: _selectedTime!,
                      date: _selectedDate,
                    ),
                  ),
                );
              }
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
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // if (_canSubmit) ...[
              //   Container(
              //     padding: const EdgeInsets.all(5),
              //     decoration: BoxDecoration(
              //       color: Colors.white.withOpacity(0.2),
              //       borderRadius: BorderRadius.circular(7),
              //     ),
              //     child: const Icon(Icons.calendar_month_rounded,
              //         color: Colors.white, size: 15),
              //   ),
              //   const SizedBox(width: 8),
              // ],
              Text(
                'ต่อไป',
                style: TextStyle(
                    color: _canSubmit ? Colors.white : Colors.grey[400],
                    fontWeight: FontWeight.w700,
                    fontSize: 15),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ════════════════════════════════════════════════════════
  //  Shared Widgets
  // ════════════════════════════════════════════════════════

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
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFECEDF0)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFECEDF0)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF0262EC), width: 1.5),
      ),
      fillColor: const Color(0xFFFAFAFA),
      filled: true,
    );
  }

  Widget _buildTextField({
    required String title,
    required String hint,
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
          style: GoogleFonts.prompt(
              fontSize: 14, fontWeight: FontWeight.w500, color: Colors.black),
          decoration: _inputDecor().copyWith(hintText: hint),
        ),
      ],
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
            hintStyle: const TextStyle(color: Colors.grey, fontSize: 13),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFECEDF0)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFECEDF0)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  const BorderSide(color: Color(0xFF0262EC), width: 1.5),
            ),
          ),
        ),
      ],
    );
  }

  void goBack() async {
    Navigator.pop(context, false);
  }
}

// ══════════════════════════════════════════════════════════
//  _Palette helper
// ══════════════════════════════════════════════════════════

class _Palette {
  final Color primary;
  final Color secondary;
  final String emoji;
  const _Palette(this.primary, this.secondary, this.emoji);
}
