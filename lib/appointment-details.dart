import 'package:LawyerOnline/booking/topic-page.dart';
import 'package:LawyerOnline/component/dialog_service.dart';
import 'package:LawyerOnline/message-form.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;

// ══════════════════════════════════════════════════════════
//  AppointmentDetailPage  (Redesigned — Clean Premium)
//
//  Navigator.push(context, MaterialPageRoute(
//    builder: (_) => AppointmentDetailPage(appointment: item)));
// ══════════════════════════════════════════════════════════

class AppointmentDetails extends StatefulWidget {
  final Map<String, dynamic> appointment;
  const AppointmentDetails({super.key, required this.appointment});

  @override
  State<AppointmentDetails> createState() => _AppointmentDetailsState();
}

class _AppointmentDetailsState extends State<AppointmentDetails>
    with TickerProviderStateMixin {
  // ── Controllers ─────────────────────────────────────────
  late final AnimationController _enterCtrl;
  late final AnimationController _pulseCtrl;
  late final ScrollController _scrollCtrl;
  double _scrollOffset = 0;

  // ── Animations (staggered) ───────────────────────────────
  late final List<Animation<double>> _anims;

  // ── Color palette ────────────────────────────────────────
  static const _blue = Color(0xFF0262EC);
  static const _green = Color(0xFF00C48C);
  static const _amber = Color(0xFFFFAA00);
  static const _red = Color(0xFFFF4B6E);
  static const _ink = Color(0xFF0F172A);
  static const _slate = Color(0xFF64748B);
  static const _surface = Color(0xFFF8FAFF);
  static const _card = Colors.white;

  // ── Status config ────────────────────────────────────────
  static const _statusLabels = [
    'ส่งคำขอ',
    'รอยืนยัน',
    'ยืนยันแล้ว',
    'กำลังปรึกษา',
    'เสร็จสิ้น'
  ];
  static const _statusColors = [
    Color(0xFF94A3B8),
    Color(0xFFFFAA00),
    _blue,
    _green,
    Color(0xFF8B5CF6),
  ];
  static const _statusIcons = [
    Icons.send_rounded,
    Icons.hourglass_top_rounded,
    Icons.verified_rounded,
    Icons.headset_mic_rounded,
    Icons.task_alt_rounded,
  ];

  static const _steps = [
    ('ส่งคำขอนัดหมาย', 'ระบบรับคำขอแล้ว'),
    ('รอการยืนยัน', 'ทนายตรวจสอบตารางเวลา'),
    ('ยืนยันแล้ว', 'นัดหมายได้รับการยืนยัน'),
    ('กำลังปรึกษา', 'การปรึกษากำลังดำเนินอยู่'),
    ('เสร็จสิ้น', 'การปรึกษาเสร็จสมบูรณ์'),
  ];

  @override
  void initState() {
    super.initState();

    _scrollCtrl = ScrollController()
      ..addListener(() {
        setState(() => _scrollOffset = _scrollCtrl.offset);
      });

    _enterCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..forward();

    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);

    _anims = List.generate(7, (i) {
      final start = i * 0.09;
      return CurvedAnimation(
        parent: _enterCtrl,
        curve: Interval(
          start.clamp(0, 0.8),
          (start + 0.45).clamp(0, 1.0),
          curve: Curves.easeOutExpo,
        ),
      );
    });
  }

  @override
  void dispose() {
    _enterCtrl.dispose();
    _pulseCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  // ── Shorthand getters ────────────────────────────────────
  Map<String, dynamic> get a => widget.appointment;
  int get status => (a['status'] as int).clamp(0, 4);
  bool get isDone => status == 4;
  bool get isActive => status == 3;
  Color get statusColor => _statusColors[status];
  Color get lawyerColor => Color(0xFF0262EC);

  // ════════════════════════════════════════════════════════
  //  BUILD
  // ════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _surface,
      body: Stack(
        children: [
          CustomScrollView(
            controller: _scrollCtrl,
            physics: ClampingScrollPhysics(),
            slivers: [
              _buildHero(),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(15, 0, 15, 120),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    _stagger(0, _buildDateTimeRow()),
                    _gap(14),
                    _stagger(1, _buildLawyerCard()),
                    _gap(14),
                    _stagger(2, _buildInfoCard()),
                    // _gap(14),
                    // _stagger(3, _buildTimelineCard()),
                    if (isDone && a['rating'] != null) ...[
                      _gap(14),
                      _stagger(4, _buildRatingCard()),
                    ],
                    _gap(14),
                    _stagger(5, _buildNoteCard()),
                  ]),
                ),
              ),
            ],
          ),

          // Floating AppBar
          _buildFloatingAppBar(),

          // Bottom CTA
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _stagger(6, _buildBottomCTA()),
          ),
        ],
      ),
    );
  }

  // ════════════════════════════════════════════════════════
  //  HERO
  // ════════════════════════════════════════════════════════

  Widget _buildHero() {
    return SliverToBoxAdapter(
      child: SizedBox(
        height: 160,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // Background gradient
            Container(
              height: 180,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    lawyerColor,
                    Color.fromARGB(
                      lawyerColor.alpha,
                      lawyerColor.red,
                      lawyerColor.green,
                      math.min(lawyerColor.blue + 40, 255),
                    ),
                    lawyerColor.withOpacity(0.85),
                  ],
                ),
              ),
              child: Stack(
                children: [
                  Positioned(
                    right: -30,
                    top: 0,
                    child: Container(
                      width: 180,
                      height: 180,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.06),
                      ),
                    ),
                  ),
                  // Positioned(
                  //   right: 40,
                  //   top: 60,
                  //   child: Container(
                  //     width: 90,
                  //     height: 90,
                  //     decoration: BoxDecoration(
                  //       shape: BoxShape.circle,
                  //       color: Colors.white.withOpacity(0.05),
                  //     ),
                  //   ),
                  // ),
                  Positioned(
                    right: -5,
                    top: 15,
                    child: Container(
                      width: 140,
                      height: 140,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        // color: Colors.white.withOpacity(0.08),
                      ),
                      child: Icon(
                        Icons.gavel_rounded,
                        color: Colors.white.withOpacity(0.08),
                        size: 100,
                      ),
                    ),
                  ),
                  Positioned(
                    left: -20,
                    bottom: 0,
                    child: Container(
                      width: 140,
                      height: 140,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.04),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Content
            const Positioned(
              left: 20,
              right: 20,
              bottom: 50,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // const SizedBox(height: 80),
                  // Status pill
                  // AnimatedBuilder(
                  //   animation: _pulseCtrl,
                  //   builder: (_, __) => Container(
                  //     padding: const EdgeInsets.symmetric(
                  //         horizontal: 12, vertical: 6),
                  //     decoration: BoxDecoration(
                  //       color: Colors.white.withOpacity(0.18),
                  //       borderRadius: BorderRadius.circular(999),
                  //       border: Border.all(
                  //         color: Colors.white.withOpacity(
                  //             isActive ? 0.4 + _pulseCtrl.value * 0.3 : 0.3),
                  //       ),
                  //     ),
                  //     child: Row(
                  //       mainAxisSize: MainAxisSize.min,
                  //       children: [
                  //         if (isActive)
                  //           Container(
                  //             width: 6, height: 6,
                  //             margin: const EdgeInsets.only(right: 6),
                  //             decoration: const BoxDecoration(
                  //               color: Colors.white,
                  //               shape: BoxShape.circle,
                  //             ),
                  //           ),
                  //         Icon(_statusIcons[status],
                  //             size: 12, color: Colors.white),
                  //         const SizedBox(width: 5),
                  //         Text(_statusLabels[status],
                  //             style: const TextStyle(
                  //                 fontSize: 12,
                  //                 fontWeight: FontWeight.w700,
                  //                 color: Colors.white)),
                  //       ],
                  //     ),
                  //   ),
                  // ),
                  // SizedBox(height: 10),
                  Text(
                    'ข้อมูลการนัดหมาย',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      height: 1.15,
                      letterSpacing: -0.3,
                    ),
                  ),
                ],
              ),
            ),

            // White rounded shelf
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                height: 18,
                decoration: const BoxDecoration(
                  color: _surface,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ════════════════════════════════════════════════════════
  //  FLOATING APP BAR
  // ════════════════════════════════════════════════════════

  Widget _buildFloatingAppBar() {
    final showTitle = _scrollOffset > 80;
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
        decoration: BoxDecoration(
          color: showTitle ? Colors.white : Colors.transparent,
          // showTitle ? lawyerColor : Colors.transparent,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 17,
              offset: const Offset(0, 0),
            ),
          ],
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(32),
            bottomRight: Radius.circular(32),
          ),
        ),
        child: Container(
          height: 70,
          padding: EdgeInsets.symmetric(horizontal: 15),
          // decoration: BoxDecoration(
          //   borderRadius: BorderRadius.only(
          //     bottomLeft: Radius.circular(32),
          //     bottomRight: Radius.circular(32),
          //   ),
          // ),
          child: Row(
            children: [
              _circleBtn(
                icon: Icons.arrow_back_ios_new_rounded,
                color: showTitle ? Colors.black : _ink,
                bg: showTitle ? Color(0xFFFAFAFA) : Colors.white,
                onTap: () {
                  HapticFeedback.lightImpact();
                  Navigator.pop(context);
                },
              ),
              Expanded(
                child: AnimatedOpacity(
                  opacity: showTitle ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 200),
                  child: Center(
                    child: Text(
                      'ข้อมูลการนัดหมาย',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: Colors.black,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ),
              _circleBtn(
                icon: Icons.more_horiz_rounded,
                color: showTitle ? Colors.black : _ink,
                bg: showTitle ? Color(0xFFFAFAFA) : Colors.white,
                onTap: _showMenu,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _circleBtn({
    required IconData icon,
    required Color color,
    required Color bg,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: bg,
          shape: BoxShape.circle,
          border: Border.all(
            width: 1,
            color: const Color(0xFFDBDBDB),
          ),
          // boxShadow: [
          //   BoxShadow(
          //     color: Colors.black.withOpacity(0.08),
          //     blurRadius: 8,
          //     offset: const Offset(0, 2),
          //   ),
          // ],
        ),
        child: Icon(icon, size: 18, color: color),
      ),
    );
  }

  // ════════════════════════════════════════════════════════
  //  DATE-TIME ROW  (3 pills)
  // ════════════════════════════════════════════════════════

  Widget _buildDateTimeRow() {
    return Row(children: [
      _pill(Icons.calendar_today_rounded, 'วันนัด', a['date'] as String, _blue),
      const SizedBox(width: 10),
      _pill(Icons.schedule_rounded, 'เวลา', a['time'] as String, _green),
      const SizedBox(width: 10),
      _pill(
          Icons.videocam_rounded, 'รูปแบบ', 'วิดีโอ', const Color(0xFF8B5CF6)),
    ]);
  }

  Widget _pill(IconData icon, String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        decoration: BoxDecoration(
          color: _card,
          borderRadius: BorderRadius.circular(20),
          boxShadow: _shadow,
        ),
        child: Column(children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 16, color: color),
          ),
          const SizedBox(height: 7),
          Text(label,
              style: TextStyle(
                  fontSize: 9,
                  color: _slate.withOpacity(0.7),
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.3)),
          const SizedBox(height: 3),
          Text(value,
              style: const TextStyle(
                  fontSize: 11, fontWeight: FontWeight.w800, color: _ink),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis),
        ]),
      ),
    );
  }

  // ════════════════════════════════════════════════════════
  //  LAWYER CARD
  // ════════════════════════════════════════════════════════

  Widget _buildLawyerCard() {
    return _cardWrap(
      child: Column(
        children: [
          Row(children: [
            Stack(children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(56),
                child: Container(
                  width: 64,
                  height: 64,
                  color: lawyerColor.withOpacity(0.15),
                  child: a['imageUrl'] != null
                      ? Image.asset(a['imageUrl'] as String,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              _avatarText(lawyerColor))
                      : _avatarText(lawyerColor),
                ),
              ),
              if (isActive)
                Positioned(
                  right: 2,
                  bottom: 2,
                  child: AnimatedBuilder(
                    animation: _pulseCtrl,
                    builder: (_, __) => Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        color: _green,
                        shape: BoxShape.circle,
                        border: Border.all(color: _card, width: 2.5),
                        boxShadow: [
                          BoxShadow(
                            color: _green.withOpacity(0.4 * _pulseCtrl.value),
                            blurRadius: 6,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ]),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    a['name'] as String,
                    style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: _ink,
                        letterSpacing: -0.2),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                    decoration: BoxDecoration(
                      color: lawyerColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      a['title'] as String,
                      style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: lawyerColor),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(children: [
                    ...List.generate(
                        5,
                        (i) => const Icon(Icons.star_rounded,
                            size: 13, color: Color(0xFFFFC107))),
                    const SizedBox(width: 5),
                    const Text('4.8',
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: _ink)),
                    const SizedBox(width: 4),
                    Text('(60)',
                        style: TextStyle(
                            fontSize: 10, color: _slate.withOpacity(0.6))),
                  ]),
                ],
              ),
            ),
          ]),
          // const SizedBox(height: 16),
          // Row(
          //   children: [
          //     Expanded(
          //       child: _outlineBtn(
          //         icon: Icons.phone_rounded,
          //         label: 'โทรศัพท์',
          //         color: _green,
          //         onTap: () => HapticFeedback.lightImpact(),
          //       ),
          //     ),
          //     const SizedBox(width: 10),
          //     Expanded(
          //       child: _outlineBtn(
          //         icon: Icons.chat_bubble_rounded,
          //         label: 'ส่งข้อความ',
          //         color: _blue,
          //         onTap: () => HapticFeedback.lightImpact(),
          //       ),
          //     ),
          //   ],
          // ),
        ],
      ),
    );
  }

  Widget _avatarText(Color color) => Center(
        child: Text(
          a['lawyerAvatar'] as String,
          style: TextStyle(
              fontSize: 26, color: color, fontWeight: FontWeight.w900),
        ),
      );

  Widget _outlineBtn({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 11),
        decoration: BoxDecoration(
          color: color.withOpacity(0.07),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon, size: 15, color: color),
          const SizedBox(width: 6),
          Text(label,
              style: TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w700, color: color)),
        ]),
      ),
    );
  }

  // ════════════════════════════════════════════════════════
  //  INFO CARD
  // ════════════════════════════════════════════════════════

  Widget _buildInfoCard() {
    return _cardWrap(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _cardTitle(Icons.info_outline_rounded, 'ข้อมูลการนัดหมาย'),
          const SizedBox(height: 14),
          _infoRow('หัวข้อ', a['topic'] as String),
          _divider(),
          _infoRow('ประเด็น', a['subTopic'] as String),
          _divider(),
          _infoRow('ประเภท', 'วิดีโอคอล'),
          _divider(),
          _infoRow('รหัสนัด', '# ${a['id']}', accent: true),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value, {bool accent = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(children: [
        SizedBox(
          width: 90,
          child: Text(label,
              style: const TextStyle(
                  fontSize: 12, color: _slate, fontWeight: FontWeight.w500)),
        ),
        Expanded(
          child: Text(value,
              textAlign: TextAlign.right,
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: accent ? _blue : _ink)),
        ),
      ]),
    );
  }

  Widget _divider() =>
      const Divider(height: 1, thickness: 1, color: Color(0xFFF1F5F9));

  // ════════════════════════════════════════════════════════
  //  TIMELINE CARD  (horizontal stepper)
  // ════════════════════════════════════════════════════════

  Widget _buildTimelineCard() {
    return _cardWrap(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _cardTitle(Icons.route_rounded, 'ขั้นตอน'),
          const SizedBox(height: 20),

          // Horizontal stepper
          SizedBox(
            height: 56,
            child: Row(
              children: List.generate(_steps.length * 2 - 1, (i) {
                if (i.isOdd) {
                  final stepIdx = i ~/ 2;
                  final passed = stepIdx < status;
                  return Expanded(
                    child: Container(
                      height: 2,
                      margin: const EdgeInsets.only(bottom: 20),
                      decoration: BoxDecoration(
                        color: passed ? statusColor : const Color(0xFFE2E8F4),
                        borderRadius: BorderRadius.circular(1),
                      ),
                    ),
                  );
                }
                final idx = i ~/ 2;
                final done = idx < status;
                final active = idx == status;
                final pending = idx > status;

                return Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    AnimatedBuilder(
                      animation: _pulseCtrl,
                      builder: (_, __) => Container(
                        width: active ? 34 : 28,
                        height: active ? 34 : 28,
                        decoration: BoxDecoration(
                          color: done
                              ? statusColor
                              : active
                                  ? statusColor.withOpacity(0.15)
                                  : const Color(0xFFF1F5F9),
                          shape: BoxShape.circle,
                          border: active
                              ? Border.all(
                                  color: statusColor.withOpacity(
                                      0.5 + _pulseCtrl.value * 0.4),
                                  width: 2,
                                )
                              : null,
                          boxShadow: active
                              ? [
                                  BoxShadow(
                                    color: statusColor
                                        .withOpacity(0.25 * _pulseCtrl.value),
                                    blurRadius: 10,
                                    spreadRadius: 3,
                                  )
                                ]
                              : null,
                        ),
                        child: Center(
                          child: done
                              ? const Icon(Icons.check_rounded,
                                  size: 14, color: Colors.white)
                              : active
                                  ? Icon(_statusIcons[status],
                                      size: 14, color: statusColor)
                                  : Text('${idx + 1}',
                                      style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w700,
                                          color: pending
                                              ? const Color(0xFFCBD5E1)
                                              : Colors.white)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _shortLabel(idx),
                      style: TextStyle(
                          fontSize: 9,
                          fontWeight:
                              active ? FontWeight.w800 : FontWeight.w500,
                          color: pending
                              ? const Color(0xFFCBD5E1)
                              : active
                                  ? statusColor
                                  : const Color(0xFF94A3B8)),
                      textAlign: TextAlign.center,
                    ),
                  ],
                );
              }),
            ),
          ),

          const SizedBox(height: 18),

          // Current step detail box
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.07),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: statusColor.withOpacity(0.2)),
            ),
            child: Row(children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(_statusIcons[status], size: 18, color: statusColor),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _steps[status].$1,
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: statusColor),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _steps[status].$2,
                      style: TextStyle(
                          fontSize: 11, color: statusColor.withOpacity(0.7)),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text('ปัจจุบัน',
                    style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: statusColor)),
              ),
            ]),
          ),
        ],
      ),
    );
  }

  String _shortLabel(int i) {
    const s = ['ส่งคำขอ', 'รอยืนยัน', 'ยืนยัน', 'ปรึกษา', 'สำเร็จ'];
    return s[i];
  }

  // ════════════════════════════════════════════════════════
  //  RATING CARD
  // ════════════════════════════════════════════════════════

  Widget _buildRatingCard() {
    final r = (a['rating'] as num).toDouble();
    return _cardWrap(
      child: Column(children: [
        _cardTitle(Icons.star_outline_rounded, 'คะแนนที่ให้'),
        const SizedBox(height: 16),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Text(r.toStringAsFixed(1),
              style: const TextStyle(
                  fontSize: 52,
                  fontWeight: FontWeight.w900,
                  color: _ink,
                  letterSpacing: -2,
                  height: 1)),
          const SizedBox(width: 14),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(
              children: List.generate(5, (i) {
                if (i < r.floor()) {
                  return const Icon(Icons.star_rounded,
                      color: Color(0xFFFFC107), size: 22);
                } else if (i < r) {
                  return const Icon(Icons.star_half_rounded,
                      color: Color(0xFFFFC107), size: 22);
                }
                return const Icon(Icons.star_outline_rounded,
                    color: Color(0xFFE2E8F4), size: 22);
              }),
            ),
            const SizedBox(height: 5),
            Text(
              r >= 4.5
                  ? '😊  ดีเยี่ยม'
                  : r >= 3.5
                      ? '🙂  ดี'
                      : '😐  พอใช้',
              style: const TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w700, color: _ink),
            ),
          ]),
        ]),
      ]),
    );
  }

  // ════════════════════════════════════════════════════════
  //  NOTE CARD
  // ════════════════════════════════════════════════════════

  Widget _buildNoteCard() {
    return _cardWrap(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _cardTitle(Icons.sticky_note_2_outlined, 'บันทึก'),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: _blue.withOpacity(0.04),
              borderRadius: BorderRadius.circular(14),
              border: Border(
                left: BorderSide(color: _blue.withOpacity(0.5), width: 3),
              ),
            ),
            child: const Text(
              'กรุณาเตรียมเอกสารที่เกี่ยวข้อง และเข้าห้องสนทนาก่อนเวลานัด 5 นาที\n'
              'หากมีข้อสงสัยเพิ่มเติม สามารถติดต่อผ่านแชทได้ตลอดเวลา',
              style: TextStyle(fontSize: 13, color: _slate, height: 1.65),
            ),
          ),
        ],
      ),
    );
  }

  // ════════════════════════════════════════════════════════
  //  BOTTOM CTA
  // ════════════════════════════════════════════════════════

  Widget _buildBottomCTA() {
    final pad = MediaQuery.of(context).padding.bottom;
    return Container(
      padding: EdgeInsets.fromLTRB(20, 20, 20, 14 + pad),
      decoration: BoxDecoration(
        color: _card,
        border: const Border(top: BorderSide(color: Color(0xFFF1F5F9))),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.07),
            blurRadius: 20,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: status == 3
          ? Row(
              children: [
                Expanded(
                  child: _ctaBtn(
                    label: 'นัดหมายใหม่',
                    icon: Icons.add_rounded,
                    color: _blue,
                    filled: false,
                    onTap: () {
                      HapticFeedback.lightImpact();
                      // Navigator.pushAndRemoveUntil(
                      //   context,
                      //   MaterialPageRoute(
                      //     builder: (context) => TopicPage(),
                      //   )
                      // )
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(
                          builder: (_) => TopicPage(),
                        ),
                        (Route<dynamic> route) => route.isFirst,
                      );
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _ctaBtn(
                    label: 'ให้คะแนน',
                    icon: Icons.star_rounded,
                    color: _amber,
                    filled: true,
                    onTap: () => HapticFeedback.lightImpact(),
                  ),
                ),
              ],
            )
          : status == 2
              ? Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                
                    GestureDetector(
                      onTap: () => {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) =>
                                    MessageFormPage(model: widget.appointment)),
                            )
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        height: 52,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                              colors: [Color(0xFF0262EC), Color(0xFF0485FF)]),
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                                color: Color(0xFF0262EC).withOpacity(0.3),
                                blurRadius: 10,
                                offset: const Offset(0, 4))
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.video_call_rounded,
                                color: Colors.white, size: 20),
                            const SizedBox(width: 8),
                            Text('เข้าสู่ห้องปรึกษา',
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 15)),
                          ],
                        ),
                      ),
                    ),
                  ],
                )
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    GestureDetector(
                      onTap: _showCancelDialog,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        height: 50,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: Color(0xFFFFEBEE),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Text('ยกเลิกนัดหมาย',
                            style: TextStyle(
                                color: Color(0xFFC62828),
                                fontWeight: FontWeight.w700,
                                fontSize: 13)),
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget _ctaBtn({
    required String label,
    required IconData icon,
    required Color color,
    required bool filled,
    bool fullWidth = false,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: fullWidth ? double.infinity : null,
        padding: const EdgeInsets.symmetric(vertical: 15),
        decoration: BoxDecoration(
          color: filled ? color : color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(16),
          border: filled ? null : Border.all(color: color.withOpacity(0.25)),
          boxShadow: filled
              ? [
                  BoxShadow(
                    color: color.withOpacity(0.3),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  )
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: filled ? Colors.white : color),
            const SizedBox(width: 8),
            Text(label,
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: filled ? Colors.white : color,
                    letterSpacing: -0.1)),
          ],
        ),
      ),
    );
  }

  // ════════════════════════════════════════════════════════
  //  SHARED HELPERS
  // ════════════════════════════════════════════════════════

  static const _shadow = [
    BoxShadow(color: Color(0x0A0F172A), blurRadius: 16, offset: Offset(0, 4)),
    BoxShadow(color: Color(0x060F172A), blurRadius: 4, offset: Offset(0, 1)),
  ];

  Widget _cardWrap({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(24),
        boxShadow: _shadow,
      ),
      child: child,
    );
  }

  Widget _cardTitle(IconData icon, String title) {
    return Row(children: [
      Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: _blue.withOpacity(0.09),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, size: 16, color: _blue),
      ),
      const SizedBox(width: 10),
      Text(title,
          style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: _ink,
              letterSpacing: -0.2)),
    ]);
  }

  Widget _stagger(int i, Widget child) {
    final anim = _anims[i.clamp(0, _anims.length - 1)];
    return FadeTransition(
      opacity: anim,
      child: SlideTransition(
        position: Tween<Offset>(begin: const Offset(0, 0.06), end: Offset.zero)
            .animate(anim),
        child: child,
      ),
    );
  }

  Widget _gap(double h) => SizedBox(height: h);

  // ════════════════════════════════════════════════════════
  //  DIALOGS / MENUS
  // ════════════════════════════════════════════════════════

  void _showCancelDialog() {
    HapticFeedback.mediumImpact();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
        actionsPadding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        title: Row(children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
                color: _red.withOpacity(0.1), shape: BoxShape.circle),
            child:
                const Icon(Icons.warning_amber_rounded, color: _red, size: 20),
          ),
          const SizedBox(width: 12),
          const Text('ยกเลิกนัดหมาย',
              style: TextStyle(
                  fontSize: 16, fontWeight: FontWeight.w800, color: _ink)),
        ]),
        content: const Text(
          'คุณต้องการยกเลิกการนัดหมายนี้ใช่หรือไม่?\nการกระทำนี้ไม่สามารถย้อนกลับได้',
          style: TextStyle(fontSize: 13, color: _slate, height: 1.6),
        ),
        actions: [
          Row(children: [
            Expanded(
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  decoration: BoxDecoration(
                      color: _surface, borderRadius: BorderRadius.circular(14)),
                  child: const Center(
                    child: Text('ยกเลิก',
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: _slate)),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: GestureDetector(
                onTap: () {
                  Navigator.pop(context);
                  DialogService.showSuccess(
                    context,
                    title: "สำเร็จ",
                    message:
                        "ระบบได้ยกเลิกนัดหมายเรียบร้อยแล้ว และจะทำการคืนเงินนัดหมายผ่านช่องทางบัญชีธนาคารที่ลงทะเบียนไว้",
                    onClose: () {
                      Navigator.pop(context);
                    },
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  decoration: BoxDecoration(
                    color: _red,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: _red.withOpacity(0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      )
                    ],
                  ),
                  child: const Center(
                    child: Text('ยืนยัน',
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Colors.white)),
                  ),
                ),
              ),
            ),
          ]),
        ],
      ),
    );
  }

  void _showMenu() {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
            color: _card, borderRadius: BorderRadius.circular(24)),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                    color: const Color(0xFFE2E8F4),
                    borderRadius: BorderRadius.circular(2)),
              ),
              _menuTile(Icons.share_rounded, 'แชร์นัดหมาย', _blue),
              _menuTile(Icons.picture_as_pdf_rounded, 'ดาวน์โหลด PDF', _green),
              _menuTile(Icons.flag_outlined, 'รายงานปัญหา', _amber),
              const SizedBox(height: 8),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _menuTile(IconData icon, String label, Color color) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12)),
        child: Icon(icon, size: 18, color: color),
      ),
      title: Text(label,
          style: const TextStyle(
              fontSize: 14, fontWeight: FontWeight.w600, color: _ink)),
      onTap: () {
        HapticFeedback.lightImpact();
        Navigator.pop(context);
      },
    );
  }
}
