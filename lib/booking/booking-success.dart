import 'package:LawyerOnline/consult/consult_status.dart';
import 'package:LawyerOnline/message-form.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// ══════════════════════════════════════════════════════════
//  BookingSuccessPage
//  เรียกใช้:
//  Navigator.pushReplacement(context, MaterialPageRoute(
//    builder: (_) => BookingSuccessPage(
//      lawyer: lawyerMap,
//      topic: 'ครอบครัวและมรดก',
//      subTopic: 'ฟ้องหย่า / แบ่งสินสมรส',
//      appointmentDate: '28 มีนาคม 2569',
//      appointmentTime: '10:00 - 11:00',
//      bookingCode: 'BK-2026-00123',
//    ),
//  ));
// ══════════════════════════════════════════════════════════

class BookingSuccessPage extends StatefulWidget {
  final Map<String, dynamic>? lawyer;
  final String topic;
  final String subTopic;
  final String appointmentDate;
  final String appointmentTime;
  final String? bookingCode;

  const BookingSuccessPage({
    super.key,
    this.lawyer,
    required this.topic,
    required this.subTopic,
    required this.appointmentDate,
    required this.appointmentTime,
    this.bookingCode,
  });

  @override
  State<BookingSuccessPage> createState() => _BookingSuccessPageState();
}

class _BookingSuccessPageState extends State<BookingSuccessPage>
    with TickerProviderStateMixin {
  late AnimationController _checkCtrl;
  late AnimationController _contentCtrl;
  late AnimationController _pulseCtrl;

  late Animation<double> _checkScale;
  late Animation<double> _checkOpacity;
  late Animation<double> _ringScale;
  late Animation<double> _pulseAnim;

  static const _kPrimary = Color(0xFF0262EC);
  static const _kGreen = Color(0xFF34C759);
  static const _kBg = Color(0xFFF2F6FF);

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.dark);

    // Check animation
    _checkCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _checkScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _checkCtrl,
        curve: const Interval(0.2, 0.8, curve: Curves.elasticOut),
      ),
    );

    _checkOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _checkCtrl,
        curve: const Interval(0.0, 0.4, curve: Curves.easeOut),
      ),
    );

    _ringScale = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(
        parent: _checkCtrl,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOutCubic),
      ),
    );

    // Content stagger
    _contentCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    // Pulse
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);

    _pulseAnim = Tween<double>(begin: 1.0, end: 1.12).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );

    // Play sequence
    Future.delayed(const Duration(milliseconds: 100), () {
      _checkCtrl.forward();
    });
    Future.delayed(const Duration(milliseconds: 600), () {
      _contentCtrl.forward();
    });

    HapticFeedback.heavyImpact();
  }

  @override
  void dispose() {
    _checkCtrl.dispose();
    _contentCtrl.dispose();
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lawyer = widget.lawyer;
    final lawyerColor = Color(lawyer?['color'] as int? ?? 0xFF0262EC);

    return Scaffold(
      backgroundColor: _kBg,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 32, 20, 24),
                child: Column(
                  children: [
                    // ── Success Icon ───────────────────────
                    _buildSuccessIcon(),
                    const SizedBox(height: 24),

                    // ── Title ──────────────────────────────
                    _buildTitle(),
                    const SizedBox(height: 28),

                    // ── Booking Code ───────────────────────
                    if (widget.bookingCode != null) ...[
                      _buildBookingCode(),
                      const SizedBox(height: 20),
                    ],

                    // ── Lawyer Card ────────────────────────
                    if (lawyer != null) ...[
                      _buildAnimatedItem(
                          delay: 0.0,
                          child: _buildLawyerCard(lawyer, lawyerColor)),
                      const SizedBox(height: 14),
                    ],

                    // ── Detail Card ────────────────────────
                    _buildAnimatedItem(
                      delay: 0.1,
                      child: _buildDetailCard(lawyerColor),
                    ),
                    const SizedBox(height: 14),

                    // ── Notice ─────────────────────────────
                    _buildAnimatedItem(
                      delay: 0.2,
                      child: _buildNoticeCard(),
                    ),
                  ],
                ),
              ),
            ),

            // ── Bottom Buttons ─────────────────────────────
            _buildBottomButtons(lawyerColor),
          ],
        ),
      ),
    );
  }

  // ════════════════════════════════════════════════════════
  //  Success Icon — pulsing ring + animated checkmark
  // ════════════════════════════════════════════════════════

  Widget _buildSuccessIcon() {
    return AnimatedBuilder(
      animation: _checkCtrl,
      builder: (_, __) {
        return Column(
          children: [
            // Outer pulse ring
            ScaleTransition(
              scale: _pulseAnim,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Outer glow ring
                  ScaleTransition(
                    scale: _ringScale,
                    child: FadeTransition(
                      opacity: _checkOpacity,
                      child: Container(
                        width: 130,
                        height: 130,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _kGreen.withOpacity(0.12),
                        ),
                      ),
                    ),
                  ),
                  // Middle ring
                  ScaleTransition(
                    scale: _ringScale,
                    child: FadeTransition(
                      opacity: _checkOpacity,
                      child: Container(
                        width: 108,
                        height: 108,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _kGreen.withOpacity(0.18),
                        ),
                      ),
                    ),
                  ),
                  // Inner check circle
                  ScaleTransition(
                    scale: _checkScale,
                    child: Container(
                      width: 84,
                      height: 84,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          colors: [Color(0xFF34C759), Color(0xFF30D158)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: _kGreen.withOpacity(0.45),
                            blurRadius: 24,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.check_rounded,
                        color: Colors.white,
                        size: 44,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  // ════════════════════════════════════════════════════════
  //  Title + subtitle
  // ════════════════════════════════════════════════════════

  Widget _buildTitle() {
    return _buildAnimatedItem(
      delay: 0.0,
      child: Column(children: [
        const Text(
          'จองนัดหมายสำเร็จ! 🎉',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w900,
            color: Color(0xFF1A2340),
            letterSpacing: -0.5,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          'ทนายความจะยืนยันนัดหมายของคุณ\nภายใน 24 ชั่วโมง',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey[500],
            height: 1.6,
          ),
        ),
      ]),
    );
  }

  // ════════════════════════════════════════════════════════
  //  Booking Code
  // ════════════════════════════════════════════════════════

  Widget _buildBookingCode() {
    return _buildAnimatedItem(
      delay: 0.05,
      child: GestureDetector(
        onTap: () {
          Clipboard.setData(ClipboardData(text: widget.bookingCode ?? ''));
          HapticFeedback.lightImpact();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('คัดลอกรหัสจองแล้ว'),
              backgroundColor: _kPrimary,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              duration: const Duration(seconds: 2),
            ),
          );
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                _kPrimary.withOpacity(0.08),
                _kPrimary.withOpacity(0.04),
              ],
            ),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _kPrimary.withOpacity(0.2), width: 1.5),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.confirmation_number_outlined,
                  size: 16, color: _kPrimary),
              const SizedBox(width: 8),
              Text(
                'รหัสจองนัดหมาย: ${widget.bookingCode}',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: _kPrimary,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.copy_rounded,
                  size: 14, color: _kPrimary.withOpacity(0.6)),
            ],
          ),
        ),
      ),
    );
  }

  // ════════════════════════════════════════════════════════
  //  Lawyer Card
  // ════════════════════════════════════════════════════════

  Widget _buildLawyerCard(Map<String, dynamic> lawyer, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecor(),
      child: Row(children: [
        // Avatar
        Container(
          width: 54,
          height: 54,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [color, color.withOpacity(0.7)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.35),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Center(
            child: (lawyer['imageUrl'] ?? "") != ""
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(30),
                    child: Image.asset(
                      lawyer['imageUrl'],
                      width: 55,
                      height: 55,
                      fit: BoxFit.cover,
                    ),
                  )
                : CircleAvatar(
                    radius: 30,
                    backgroundColor:
                        Color(lawyer['color'] as int).withOpacity(0.15),
                    child: Text(lawyer['avatar'] as String,
                        style: TextStyle(
                            color: Color(lawyer['color'] as int),
                            fontWeight: FontWeight.bold,
                            fontSize: 24)),
                  ),
            // Text(
            //   lawyer['avatar'] as String? ?? 'ท',
            //   style: const TextStyle(
            //     fontSize: 22,
            //     color: Colors.white,
            //     fontWeight: FontWeight.w800,
            //   ),
            // ),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(lawyer['name'] as String? ?? '',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1A2340),
                  )),
              const SizedBox(height: 3),
              Text(
                lawyer['title'] as String? ?? 'ทนายความ',
                style: TextStyle(fontSize: 11, color: Colors.grey[500]),
              ),
              const SizedBox(height: 6),
              Row(children: [
                const Icon(Icons.star_rounded,
                    color: Color(0xFFFFC107), size: 13),
                const SizedBox(width: 3),
                Text(
                  '${lawyer['rating'] ?? ''} · ${lawyer['experience'] ?? ''}',
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF1A2340),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ]),
            ],
          ),
        ),
        // Status badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: _kGreen.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: _kGreen.withOpacity(0.3), width: 1),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Container(
              width: 6,
              height: 6,
              decoration:
                  const BoxDecoration(color: _kGreen, shape: BoxShape.circle),
            ),
            const SizedBox(width: 5),
            const Text('ว่าง',
                style: TextStyle(
                    fontSize: 11, color: _kGreen, fontWeight: FontWeight.w700)),
          ]),
        ),
      ]),
    );
  }

  // ════════════════════════════════════════════════════════
  //  Detail Card
  // ════════════════════════════════════════════════════════

  Widget _buildDetailCard(Color color) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _cardDecor(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                    colors: [_kPrimary, _kPrimary.withOpacity(0.7)]),
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                      color: _kPrimary.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2))
                ],
              ),
              child: const Icon(Icons.event_note_rounded,
                  size: 16, color: Colors.white),
            ),
            const SizedBox(width: 10),
            const Text('รายละเอียดนัดหมาย',
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1A2340))),
          ]),
          const SizedBox(height: 16),

          // Detail rows
          _detailRow(
            icon: Icons.label_outline_rounded,
            label: 'ประเภทคดี',
            value: widget.topic,
            color: color,
          ),
          if (widget.subTopic.isNotEmpty) ...[
            _divider(),
            _detailRow(
              icon: Icons.subdirectory_arrow_right_rounded,
              label: 'หัวข้อย่อย',
              value: widget.subTopic,
              color: color,
            ),
          ],
          _divider(),
          _detailRow(
            icon: Icons.calendar_today_rounded,
            label: 'วันที่นัด',
            value: widget.appointmentDate,
            color: color,
            highlight: true,
          ),
          _divider(),
          _detailRow(
            icon: Icons.access_time_rounded,
            label: 'เวลา',
            value: widget.appointmentTime,
            color: color,
            highlight: true,
          ),
          _divider(),
          _detailRow(
            icon: Icons.videocam_rounded,
            label: 'รูปแบบ',
            value: 'วิดีโอคอล',
            color: color,
          ),
          _divider(),
          _detailRow(
            icon: Icons.timer_outlined,
            label: 'ระยะเวลา',
            value: '1 ชั่วโมง',
            color: color,
          ),
        ],
      ),
    );
  }

  Widget _detailRow({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    bool highlight = false,
  }) {
    return Row(children: [
      Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: highlight ? color.withOpacity(0.1) : const Color(0xFFF5F7FA),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon,
            size: 16, color: highlight ? color : const Color(0xFF8899AA)),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: TextStyle(fontSize: 10, color: Colors.grey[400])),
            const SizedBox(height: 2),
            Text(value,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: highlight ? color : const Color(0xFF1A2340),
                )),
          ],
        ),
      ),
    ]);
  }

  Widget _divider() => Container(
        margin: const EdgeInsets.symmetric(vertical: 10),
        height: 1,
        color: const Color(0xFFF0F4F8),
      );

  // ════════════════════════════════════════════════════════
  //  Notice Card
  // ════════════════════════════════════════════════════════

  Widget _buildNoticeCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8E8),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: const Color(0xFFFFB800).withOpacity(0.35), width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: const Color(0xFFFFB800).withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.info_outline_rounded,
                size: 16, color: Color(0xFFFFB800)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('หมายเหตุ',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF7A5800))),
                const SizedBox(height: 4),
                Text(
                  'ทนายความจะติดต่อยืนยันนัดหมายผ่านระบบข้อความ กรุณาตรวจสอบการแจ้งเตือนของคุณ',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.brown[400],
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ════════════════════════════════════════════════════════
  //  Bottom Buttons
  // ════════════════════════════════════════════════════════

  Widget _buildBottomButtons(Color color) {
    return Container(
      padding: EdgeInsets.fromLTRB(
          20, 12, 20, MediaQuery.of(context).padding.bottom + 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFEEF2F5), width: 1)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Primary: เข้าหน้าปรึกษา ──────────────────
          GestureDetector(
            onTap: () {
              HapticFeedback.mediumImpact();
              // Navigator.pushAndRemoveUntil(
              //   context,
              //   MaterialPageRoute(
              //     builder: (_) => ConsultStatusPage(
              //       currentStep: 3,
              //       lawyer: widget.lawyer,
              //       appointmentDate: widget.appointmentDate,
              //       appointmentTime: widget.appointmentTime,
              //     ),
              //   ),
              //   (route) => route.isFirst,
              // );
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(
                  builder: (_) => MessageFormPage(
                    model: widget.lawyer,
                  ),
                ),
                (route) => route.isFirst,
              );
            },
            child: Container(
              height: 54,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [color, color.withOpacity(0.8)],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: color.withOpacity(0.4),
                    blurRadius: 16,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.headset_mic_rounded,
                        color: Colors.white, size: 16),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'เข้าหน้าปรึกษาทนายความ',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                      letterSpacing: 0.2,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),

          // ── Secondary: กลับหน้าหลัก ──────────────────
          GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              Navigator.popUntil(context, (route) => route.isFirst);
            },
            child: Container(
              height: 50,
              decoration: BoxDecoration(
                color: const Color(0xFFF2F6FF),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFDDE5F4), width: 1.5),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.home_outlined, color: Color(0xFF5B6E8A), size: 18),
                  SizedBox(width: 8),
                  Text(
                    'กลับหน้าหลัก',
                    style: TextStyle(
                      color: Color(0xFF5B6E8A),
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ════════════════════════════════════════════════════════
  //  Helpers
  // ════════════════════════════════════════════════════════

  BoxDecoration _cardDecor() => BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      );

  Widget _buildAnimatedItem({
    required double delay,
    required Widget child,
  }) {
    return AnimatedBuilder(
      animation: _contentCtrl,
      builder: (_, ch) {
        final t = Curves.easeOutCubic.transform(
          ((_contentCtrl.value - delay) / (1 - delay)).clamp(0.0, 1.0),
        );
        return Opacity(
          opacity: t,
          child:
              Transform.translate(offset: Offset(0, 20 * (1 - t)), child: ch),
        );
      },
      child: child,
    );
  }
}
