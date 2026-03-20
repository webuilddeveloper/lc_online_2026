import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';

// ══════════════════════════════════════════════════════
//  Entry point — BookingFlowPage
//  เรียกใช้: Navigator.push(..., BookingFlowPage())
// ══════════════════════════════════════════════════════

class BookingFlowPage extends StatefulWidget {
  const BookingFlowPage({super.key});

  @override
  State<BookingFlowPage> createState() => _BookingFlowPageState();
}

class _BookingFlowPageState extends State<BookingFlowPage> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  // ── Booking State ──────────────────────────────────
  String? selectedTopic;
  Map<String, dynamic>? selectedLawyer;
  DateTime? selectedDate;
  String? selectedTime;

  static const _kPrimary = Color(0xFF0262EC);
  static const _kBg = Color(0xFFF5F7FA);

  void _nextPage() {
    _pageController.nextPage(
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOut,
    );
    setState(() => _currentPage++);
  }

  void _prevPage() {
    _pageController.previousPage(
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOut,
    );
    setState(() => _currentPage--);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          // Step 1 — เลือกประเภทหัวข้อ
          _TopicPage(
            onSelected: (topic) {
              setState(() => selectedTopic = topic);
              _nextPage();
            },
          ),
          // Step 2 — เลือกทนายความ
          _LawyerPage(
            topic: selectedTopic ?? '',
            onSelected: (lawyer) {
              setState(() => selectedLawyer = lawyer);
              _nextPage();
            },
            onBack: _prevPage,
          ),
          // Step 3 — เลือกวันเวลา
          _SchedulePage(
            lawyer: selectedLawyer,
            onSelected: (date, time) {
              setState(() {
                selectedDate = date;
                selectedTime = time;
              });
              _nextPage();
            },
            onBack: _prevPage,
          ),
          // Step 4 — สรุปรายละเอียด
          _SummaryPage(
            topic: selectedTopic ?? '',
            lawyer: selectedLawyer,
            date: selectedDate,
            time: selectedTime ?? '',
            onConfirm: _nextPage,
            onBack: _prevPage,
          ),
          // Step 5 — ชำระเงิน QR
          _PaymentPage(
            lawyer: selectedLawyer,
            onPaid: () => _showSuccessDialog(context),
            onBack: _prevPage,
          ),
        ],
      ),
    );
  }

  void _showSuccessDialog(BuildContext context) {
    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 400),
      transitionBuilder: (_, anim, __, child) => ScaleTransition(
        scale: CurvedAnimation(parent: anim, curve: Curves.easeOutBack),
        child: FadeTransition(opacity: anim, child: child),
      ),
      pageBuilder: (_, __, ___) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: _kPrimary.withOpacity(0.15),
                blurRadius: 40,
                offset: const Offset(0, 16),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ไอคอนสำเร็จ
              Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF34C759), Color(0xFF30D158)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF34C759).withOpacity(0.4),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: const Icon(Icons.check_rounded,
                    color: Colors.white, size: 48),
              ),
              const SizedBox(height: 24),
              const Text(
                'นัดหมายเรียบร้อย!',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1A2340),
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'ทนายความจะติดต่อกลับเพื่อยืนยัน\nนัดหมายของคุณภายใน 24 ชั่วโมง',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[500],
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 8),
              // รายละเอียดนัด
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F7FA),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  children: [
                    _dialogRow(Icons.person_outline_rounded, selectedLawyer?['name'] ?? ''),
                    const SizedBox(height: 8),
                    _dialogRow(Icons.calendar_today_outlined,
                        selectedDate != null
                            ? '${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year}'
                            : ''),
                    const SizedBox(height: 8),
                    _dialogRow(Icons.access_time_rounded, selectedTime ?? ''),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              GestureDetector(
                onTap: () => Navigator.of(context)
                    .popUntil((route) => route.isFirst),
                child: Container(
                  height: 52,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF0262EC), Color(0xFF0485FF)],
                    ),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: _kPrimary.withOpacity(0.35),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Text(
                      'กลับหน้าหลัก',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _dialogRow(IconData icon, String text) {
    return Row(children: [
      Icon(icon, size: 16, color: const Color(0xFF0262EC)),
      const SizedBox(width: 10),
      Text(text,
          style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1A2340))),
    ]);
  }
}

// ══════════════════════════════════════════════════════
//  Shared Widgets
// ══════════════════════════════════════════════════════

class _BookingAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final int step;
  final int totalSteps;
  final VoidCallback? onBack;

  const _BookingAppBar({
    required this.title,
    required this.step,
    required this.totalSteps,
    this.onBack,
  });

  @override
  Size get preferredSize => const Size.fromHeight(100);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: EdgeInsets.fromLTRB(
          16, MediaQuery.of(context).padding.top + 8, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            if (onBack != null)
              GestureDetector(
                onTap: onBack,
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F7FA),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.chevron_left_rounded,
                      color: Color(0xFF1A2340)),
                ),
              )
            else
              const SizedBox(width: 36),
            const SizedBox(width: 12),
            Expanded(
              child: Text(title,
                  style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1A2340))),
            ),
            Text('$step/$totalSteps',
                style:
                    TextStyle(fontSize: 12, color: Colors.grey[400])),
          ]),
          const SizedBox(height: 10),
          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: step / totalSteps,
              minHeight: 4,
              backgroundColor: const Color(0xFFEEF2F5),
              valueColor: const AlwaysStoppedAnimation(Color(0xFF0262EC)),
            ),
          ),
        ],
      ),
    );
  }
}

Widget _primaryButton({
  required String label,
  required VoidCallback onTap,
  bool enabled = true,
}) {
  return GestureDetector(
    onTap: enabled ? onTap : null,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      height: 54,
      decoration: BoxDecoration(
        gradient: enabled
            ? const LinearGradient(
                colors: [Color(0xFF0262EC), Color(0xFF0485FF)])
            : null,
        color: enabled ? null : const Color(0xFFCDD5E0),
        borderRadius: BorderRadius.circular(16),
        boxShadow: enabled
            ? [
                BoxShadow(
                  color: const Color(0xFF0262EC).withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                )
              ]
            : null,
      ),
      child: Center(
        child: Text(label,
            style: TextStyle(
              color: enabled ? Colors.white : Colors.grey[400],
              fontWeight: FontWeight.w700,
              fontSize: 15,
            )),
      ),
    ),
  );
}

// ══════════════════════════════════════════════════════
//  Step 1 — เลือกประเภทหัวข้อ
// ══════════════════════════════════════════════════════

class _TopicPage extends StatefulWidget {
  final Function(String) onSelected;
  const _TopicPage({required this.onSelected});

  @override
  State<_TopicPage> createState() => _TopicPageState();
}

class _TopicPageState extends State<_TopicPage> {
  String? _selected;

  final _topics = [
    {'icon': '👨‍👩‍👧', 'title': 'กฎหมายครอบครัว', 'sub': 'หย่าร้าง, มรดก, การรับบุตรบุญธรรม'},
    {'icon': '🏢', 'title': 'กฎหมายธุรกิจ', 'sub': 'สัญญา, บริษัท, ข้อพิพาทการค้า'},
    {'icon': '⚖️', 'title': 'กฎหมายแพ่งและอาญา', 'sub': 'คดีอาญา, ละเมิด, ฉ้อโกง'},
    {'icon': '🏠', 'title': 'ที่ดินและอสังหาริมทรัพย์', 'sub': 'ซื้อขาย, เช่า, โฉนด'},
    {'icon': '👷', 'title': 'กฎหมายแรงงาน', 'sub': 'เลิกจ้าง, ค่าชดเชย, สัญญาจ้าง'},
    {'icon': '💻', 'title': 'กฎหมายเทคโนโลยี', 'sub': 'ความเป็นส่วนตัว, ลิขสิทธิ์ดิจิทัล'},
    {'icon': '🌍', 'title': 'กฎหมายต่างด้าว', 'sub': 'วีซ่า, ใบอนุญาตทำงาน'},
    {'icon': '📋', 'title': 'อื่นๆ', 'sub': 'ปรึกษาเรื่องอื่นๆ'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: _BookingAppBar(
        title: 'เลือกประเภทที่ปรึกษา',
        step: 1,
        totalSteps: 5,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _topics.length,
              itemBuilder: (_, i) {
                final topic = _topics[i];
                final isSelected = _selected == topic['title'];
                return GestureDetector(
                  onTap: () => setState(() => _selected = topic['title']),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected
                            ? const Color(0xFF0262EC)
                            : Colors.transparent,
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: isSelected
                              ? const Color(0xFF0262EC).withOpacity(0.1)
                              : Colors.black.withOpacity(0.04),
                          blurRadius: isSelected ? 16 : 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color(0xFF0262EC).withOpacity(0.1)
                              : const Color(0xFFF5F7FA),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Center(
                          child: Text(topic['icon']!,
                              style: const TextStyle(fontSize: 26)),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(topic['title']!,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: isSelected
                                      ? const Color(0xFF0262EC)
                                      : const Color(0xFF1A2340),
                                )),
                            const SizedBox(height: 3),
                            Text(topic['sub']!,
                                style: TextStyle(
                                    fontSize: 12, color: Colors.grey[400])),
                          ],
                        ),
                      ),
                      if (isSelected)
                        const Icon(Icons.check_circle_rounded,
                            color: Color(0xFF0262EC), size: 22),
                    ]),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(
                16, 8, 16, MediaQuery.of(context).padding.bottom + 16),
            child: _primaryButton(
              label: 'ถัดไป',
              enabled: _selected != null,
              onTap: () => widget.onSelected(_selected!),
            ),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════
//  Step 2 — เลือกทนายความ
// ══════════════════════════════════════════════════════

class _LawyerPage extends StatefulWidget {
  final String topic;
  final Function(Map<String, dynamic>) onSelected;
  final VoidCallback onBack;

  const _LawyerPage({
    required this.topic,
    required this.onSelected,
    required this.onBack,
  });

  @override
  State<_LawyerPage> createState() => _LawyerPageState();
}

class _LawyerPageState extends State<_LawyerPage> {
  int? _selectedIdx;

  final _lawyers = [
    {
      'name': 'ศักดิ์สิทธิ์ พิพากษ์',
      'title': 'Family & Estate Lawyer',
      'rating': 4.8,
      'reviews': 60,
      'experience': '11 ปี',
      'cost': 'ฟรี',
      'imageUrl': 'assets/images/lawyer-avatar-1.png',
      'avatar': 'ศ',
      'color': 0xFF0262EC,
      'skills': ['กฎหมายครอบครัว', 'มรดก'],
      'available': true,
    },
    {
      'name': 'ธนากร นิติศักดิ์',
      'title': 'Business & Labor Lawyer',
      'rating': 4.1,
      'reviews': 45,
      'experience': '19 ปี',
      'cost': '500 บาท/ชม.',
      'imageUrl': 'assets/images/lawyer-avatar-2.png',
      'avatar': 'ธ',
      'color': 0xFF6C63FF,
      'skills': ['กฎหมายธุรกิจ', 'แรงงาน'],
      'available': true,
    },
    {
      'name': 'พงษ์ภพ ยุติธรรม',
      'title': 'Criminal & Civil Lawyer',
      'rating': 3.9,
      'reviews': 38,
      'experience': '10 ปี',
      'cost': '300 บาท/ชม.',
      'imageUrl': 'assets/images/lawyer-avatar-3.png',
      'avatar': 'พ',
      'color': 0xFF34C759,
      'skills': ['คดีอาญา', 'แพ่ง'],
      'available': false,
    },
    {
      'name': 'อาริย์ ศิษย์กฎหมาย',
      'title': 'Immigration Lawyer',
      'rating': 4.5,
      'reviews': 52,
      'experience': '12 ปี',
      'cost': '800 บาท/ชม.',
      'imageUrl': 'assets/images/lawyer-avatar-4.png',
      'avatar': 'อ',
      'color': 0xFFFF9500,
      'skills': ['แรงงานต่างด้าว', 'วีซ่า'],
      'available': true,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: _BookingAppBar(
        title: 'เลือกทนายความ',
        step: 2,
        totalSteps: 5,
        onBack: widget.onBack,
      ),
      body: Column(
        children: [
          // Topic chip
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Row(children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF0262EC).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(children: [
                  const Icon(Icons.label_outline_rounded,
                      size: 14, color: Color(0xFF0262EC)),
                  const SizedBox(width: 4),
                  Text(widget.topic,
                      style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF0262EC),
                          fontWeight: FontWeight.w600)),
                ]),
              ),
            ]),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _lawyers.length,
              itemBuilder: (_, i) {
                final l = _lawyers[i];
                final isSelected = _selectedIdx == i;
                final available = l['available'] as bool;

                return GestureDetector(
                  onTap: available
                      ? () => setState(() => _selectedIdx = i)
                      : null,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: isSelected
                            ? const Color(0xFF0262EC)
                            : Colors.transparent,
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Opacity(
                      opacity: available ? 1.0 : 0.5,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Avatar
                          CircleAvatar(
                            radius: 28,
                            backgroundColor:
                                Color(l['color'] as int).withOpacity(0.15),
                            child: Text(l['avatar'] as String,
                                style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Color(l['color'] as int))),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(children: [
                                  Expanded(
                                    child: Text(l['name'] as String,
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w700,
                                            fontSize: 14,
                                            color: Color(0xFF1A2340))),
                                  ),
                                  if (!available)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: Colors.grey[100],
                                        borderRadius:
                                            BorderRadius.circular(8),
                                      ),
                                      child: Text('ไม่ว่าง',
                                          style: TextStyle(
                                              fontSize: 10,
                                              color: Colors.grey[500])),
                                    ),
                                ]),
                                const SizedBox(height: 2),
                                Text(l['title'] as String,
                                    style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey[500])),
                                const SizedBox(height: 8),
                                Row(children: [
                                  const Icon(Icons.star_rounded,
                                      color: Color(0xFFFFC107), size: 14),
                                  const SizedBox(width: 2),
                                  Text('${l['rating']}',
                                      style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600)),
                                  const SizedBox(width: 4),
                                  Text('(${l['reviews']} รีวิว)',
                                      style: TextStyle(
                                          fontSize: 11,
                                          color: Colors.grey[400])),
                                  const Spacer(),
                                  Text(l['cost'] as String,
                                      style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                          color: Color(0xFF0262EC))),
                                ]),
                                const SizedBox(height: 6),
                                Wrap(
                                  spacing: 6,
                                  children: (l['skills'] as List<String>)
                                      .map((s) => Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 8, vertical: 3),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFF5F7FA),
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                            ),
                                            child: Text(s,
                                                style: const TextStyle(
                                                    fontSize: 10,
                                                    color:
                                                        Color(0xFF64748B))),
                                          ))
                                      .toList(),
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
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(
                16, 8, 16, MediaQuery.of(context).padding.bottom + 16),
            child: _primaryButton(
              label: 'เลือกทนายนี้',
              enabled: _selectedIdx != null,
              onTap: () => widget.onSelected(_lawyers[_selectedIdx!]),
            ),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════
//  Step 3 — เลือกวันเวลา
// ══════════════════════════════════════════════════════

class _SchedulePage extends StatefulWidget {
  final Map<String, dynamic>? lawyer;
  final Function(DateTime, String) onSelected;
  final VoidCallback onBack;

  const _SchedulePage({
    required this.lawyer,
    required this.onSelected,
    required this.onBack,
  });

  @override
  State<_SchedulePage> createState() => _SchedulePageState();
}

class _SchedulePageState extends State<_SchedulePage> {
  DateTime _focusedDate = DateTime.now();
  DateTime? _selectedDate;
  String? _selectedTime;

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

  List<DateTime> _getDaysInMonth() {
    final first = DateTime(_focusedDate.year, _focusedDate.month, 1);
    final last = DateTime(_focusedDate.year, _focusedDate.month + 1, 0);
    return List.generate(last.day, (i) => DateTime(first.year, first.month, i + 1));
  }

  final _thMonths = [
    '', 'ม.ค.', 'ก.พ.', 'มี.ค.', 'เม.ย.', 'พ.ค.', 'มิ.ย.',
    'ก.ค.', 'ส.ค.', 'ก.ย.', 'ต.ค.', 'พ.ย.', 'ธ.ค.'
  ];

  final _thDays = ['อา', 'จ', 'อ', 'พ', 'พฤ', 'ศ', 'ส'];

  @override
  Widget build(BuildContext context) {
    final days = _getDaysInMonth();
    final firstWeekday = days.first.weekday % 7;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: _BookingAppBar(
        title: 'เลือกวันและเวลา',
        step: 3,
        totalSteps: 5,
        onBack: widget.onBack,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                            onTap: () => setState(() => _focusedDate =
                                DateTime(_focusedDate.year,
                                    _focusedDate.month - 1, 1)),
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
                            onTap: () => setState(() => _focusedDate =
                                DateTime(_focusedDate.year,
                                    _focusedDate.month + 1, 1)),
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
                            final isPast = day
                                .isBefore(DateTime.now().subtract(const Duration(days: 1)));

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

                  // ── Time Slots ──────────────────────────────
                  if (_selectedDate != null) ...[
                    const SizedBox(height: 20),
                    const Text('เลือกเวลา',
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1A2340))),
                    const SizedBox(height: 10),
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
                        final isUnavailable =
                            _unavailableSlots.contains(slot);
                        final isSelected = _selectedTime == slot;

                        return GestureDetector(
                          onTap: isUnavailable
                              ? null
                              : () =>
                                  setState(() => _selectedTime = slot),
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
                    Row(children: [
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
                      Text('เลือกแล้ว',
                          style: TextStyle(
                              fontSize: 11, color: Colors.grey[400])),
                    ]),
                  ],
                ],
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(
                16, 8, 16, MediaQuery.of(context).padding.bottom + 16),
            child: _primaryButton(
              label: 'ถัดไป',
              enabled: _selectedDate != null && _selectedTime != null,
              onTap: () =>
                  widget.onSelected(_selectedDate!, _selectedTime!),
            ),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════
//  Step 4 — สรุปรายละเอียด
// ══════════════════════════════════════════════════════

class _SummaryPage extends StatelessWidget {
  final String topic;
  final Map<String, dynamic>? lawyer;
  final DateTime? date;
  final String time;
  final VoidCallback onConfirm;
  final VoidCallback onBack;

  const _SummaryPage({
    required this.topic,
    required this.lawyer,
    required this.date,
    required this.time,
    required this.onConfirm,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final thMonths = [
      '', 'มกราคม', 'กุมภาพันธ์', 'มีนาคม', 'เมษายน', 'พฤษภาคม', 'มิถุนายน',
      'กรกฎาคม', 'สิงหาคม', 'กันยายน', 'ตุลาคม', 'พฤศจิกายน', 'ธันวาคม'
    ];

    final dateStr = date != null
        ? '${date!.day} ${thMonths[date!.month]} ${date!.year + 543}'
        : '';

    final cost = lawyer?['cost'] ?? 'ฟรี';
    final isFree = cost == 'ฟรี';

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      // appBar: _BookingAppBar(
      //   title: 'สรุปรายละเอียด',
      //   step: 4,
      //   totalSteps: 5,
      //   onBack: onBack,
      // ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // ── Lawyer Card ──────────────────────────────
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF0262EC), Color(0xFF0485FF)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundColor: Colors.white.withOpacity(0.2),
                        child: Text(lawyer?['avatar'] ?? 'ท',
                            style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.white)),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(lawyer?['name'] ?? '',
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 16)),
                            const SizedBox(height: 2),
                            Text(lawyer?['title'] ?? '',
                                style: const TextStyle(
                                    color: Colors.white70, fontSize: 12)),
                            const SizedBox(height: 6),
                            Row(children: [
                              const Icon(Icons.star_rounded,
                                  color: Color(0xFFFFC107), size: 14),
                              const SizedBox(width: 3),
                              Text('${lawyer?['rating'] ?? ''}',
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 12)),
                            ]),
                          ],
                        ),
                      ),
                    ]),
                  ),
                  const SizedBox(height: 16),

                  // ── Detail Card ──────────────────────────────
                  Container(
                    padding: const EdgeInsets.all(20),
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
                        _summaryRow(
                            Icons.label_outline_rounded, 'หัวข้อ', topic),
                        const Divider(height: 24, color: Color(0xFFF5F7FA)),
                        _summaryRow(Icons.calendar_today_outlined,
                            'วันที่', dateStr),
                        const Divider(height: 24, color: Color(0xFFF5F7FA)),
                        _summaryRow(
                            Icons.access_time_rounded, 'เวลา', time),
                        const Divider(height: 24, color: Color(0xFFF5F7FA)),
                        _summaryRow(Icons.timer_outlined, 'ระยะเวลา',
                            '1 ชั่วโมง'),
                        const Divider(height: 24, color: Color(0xFFF5F7FA)),
                        _summaryRow(Icons.videocam_outlined, 'รูปแบบ',
                            'วิดีโอคอล'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ── Price Card ──────────────────────────────
                  Container(
                    padding: const EdgeInsets.all(20),
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
                        Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('ค่าบริการ',
                                  style: TextStyle(
                                      fontSize: 14, color: Colors.grey[500])),
                              Text(cost,
                                  style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF1A2340))),
                            ]),
                        const SizedBox(height: 12),
                        const Divider(color: Color(0xFFF5F7FA)),
                        const SizedBox(height: 12),
                        Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('ยอดรวม',
                                  style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF1A2340))),
                              Text(
                                isFree ? 'ฟรี' : cost,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF0262EC),
                                ),
                              ),
                            ]),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(
                16, 8, 16, MediaQuery.of(context).padding.bottom + 16),
            child: _primaryButton(
              label: isFree ? 'ยืนยันนัดหมาย' : 'ชำระเงิน',
              onTap: onConfirm,
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryRow(IconData icon, String label, String value) {
    return Row(children: [
      Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: const Color(0xFF0262EC).withOpacity(0.08),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, size: 16, color: const Color(0xFF0262EC)),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: TextStyle(fontSize: 11, color: Colors.grey[400])),
            const SizedBox(height: 2),
            Text(value,
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A2340))),
          ],
        ),
      ),
    ]);
  }
}

// ══════════════════════════════════════════════════════
//  Step 5 — ชำระเงิน QR Code
// ══════════════════════════════════════════════════════

class _PaymentPage extends StatefulWidget {
  final Map<String, dynamic>? lawyer;
  final VoidCallback onPaid;
  final VoidCallback onBack;

  const _PaymentPage({
    required this.lawyer,
    required this.onPaid,
    required this.onBack,
  });

  @override
  State<_PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<_PaymentPage> {
  bool _isPaid = false;

  @override
  Widget build(BuildContext context) {
    final cost = widget.lawyer?['cost'] ?? '0';

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: _BookingAppBar(
        title: 'ชำระเงิน',
        step: 5,
        totalSteps: 5,
        onBack: widget.onBack,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // ── QR Card ─────────────────────────────────
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.06),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        // PromptPay logo area
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1A2340),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            'PromptPay',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                              letterSpacing: 1,
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // QR Code
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                                color: const Color(0xFFEEF2F5), width: 2),
                          ),
                          child: QrImageView(
                            data:
                                'promptpay://0812345678/${cost.replaceAll(' บาท/ชม.', '')}',
                            version: QrVersions.auto,
                            size: 220,
                            backgroundColor: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Amount
                        Text('ยอดชำระ',
                            style: TextStyle(
                                fontSize: 13, color: Colors.grey[400])),
                        const SizedBox(height: 4),
                        Text(cost,
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF0262EC),
                              letterSpacing: -0.5,
                            )),
                        const SizedBox(height: 16),

                        // Account info
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF5F7FA),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(children: [
                            _paymentInfoRow('ชื่อบัญชี', 'LawyerOnline Co.,Ltd'),
                            const SizedBox(height: 6),
                            _paymentInfoRow('หมายเลข', '081-234-5678'),
                          ]),
                        ),
                        const SizedBox(height: 16),

                        // Instruction
                        Text(
                          'สแกน QR Code ด้วยแอปธนาคารของคุณ\nแล้วกดยืนยันการชำระเงินด้านล่าง',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[400],
                            height: 1.6,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ── Confirm Paid ─────────────────────────────
                  GestureDetector(
                    onTap: () => setState(() => _isPaid = !_isPaid),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: _isPaid
                              ? const Color(0xFF34C759)
                              : const Color(0xFFEEF2F5),
                          width: 1.5,
                        ),
                      ),
                      child: Row(children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: _isPaid
                                ? const Color(0xFF34C759)
                                : Colors.white,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: _isPaid
                                  ? const Color(0xFF34C759)
                                  : Colors.grey[300]!,
                            ),
                          ),
                          child: _isPaid
                              ? const Icon(Icons.check_rounded,
                                  color: Colors.white, size: 16)
                              : null,
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'ฉันชำระเงินเรียบร้อยแล้ว',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1A2340),
                          ),
                        ),
                      ]),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(
                16, 8, 16, MediaQuery.of(context).padding.bottom + 16),
            child: _primaryButton(
              label: 'ยืนยันการชำระเงิน',
              enabled: _isPaid,
              onTap: widget.onPaid,
            ),
          ),
        ],
      ),
    );
  }

  Widget _paymentInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: TextStyle(fontSize: 12, color: Colors.grey[500])),
        Text(value,
            style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1A2340))),
      ],
    );
  }
}