import 'package:LawyerOnline/message-form.dart';
import 'package:flutter/material.dart';
import 'package:LawyerOnline/component/appbar.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';

class ConsultStatusPage extends StatefulWidget {
  final int currentStep;
  final dynamic? lawyer;
  final String? appointmentDate;
  final String? appointmentTime;

  const ConsultStatusPage({
    super.key,
    this.currentStep = 3,
    this.lawyer,
    this.appointmentDate,
    this.appointmentTime,
  });

  @override
  State<ConsultStatusPage> createState() => _ConsultStatusPageState();
}

class _ConsultStatusPageState extends State<ConsultStatusPage>
    with TickerProviderStateMixin {
  late AnimationController _staggerController;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnim;

  static const _kPrimary = Color(0xFF0262EC);
  static const _kBg = Color(0xFFEEF2F5);

  final _steps = const [
    _StepData(
      icon: Icons.send_rounded,
      label: 'ส่งคำขอ',
      sublabel: 'ระบบได้รับคำขอของคุณแล้ว',
    ),
    _StepData(
      icon: Icons.hourglass_top_rounded,
      label: 'รอการยืนยัน',
      sublabel: 'ทนายกำลังตรวจสอบตารางนัด',
    ),
    _StepData(
      icon: Icons.verified_rounded,
      label: 'ยืนยันนัดหมาย',
      sublabel: 'ทนายยืนยันนัดหมายแล้ว',
    ),
    _StepData(
      icon: Icons.headset_mic_rounded,
      label: 'กำลังปรึกษา',
      sublabel: 'เซสชันการปรึกษากำลังดำเนินอยู่',
    ),
    _StepData(
      icon: Icons.task_alt_rounded,
      label: 'เสร็จสิ้น',
      sublabel: 'การปรึกษาเสร็จสมบูรณ์',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _staggerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..forward();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _pulseAnim = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _staggerController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lawyer = widget.lawyer;
    final currentStep = widget.currentStep.clamp(0, _steps.length - 1);

    return Scaffold(
      backgroundColor: _kBg,
      appBar: appBar(
        title: 'สถานะนัดหมาย',
        backBtn: true,
        rightBtn: false,
        rightAction: () {},
        backAction: () => Navigator.pop(context),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  _headerCard(currentStep),
                  const SizedBox(height: 16),
                  if (lawyer != null) ...[
                    _lawyerCard(lawyer),
                    const SizedBox(height: 16),
                  ],
                  if (widget.appointmentDate != null ||
                      widget.appointmentTime != null) ...[
                    _infoRow(),
                    const SizedBox(height: 16),
                  ],
                  _progressCard(currentStep),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
          _bottomBar(currentStep, context),
        ],
      ),
    );
  }

  Widget _headerCard(int currentStep) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0262EC), Color(0xFF0485FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.event_note_outlined,
                color: Colors.white, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'ติดตามสถานะนัดหมาย',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'ขั้นตอน ${currentStep + 1}/${_steps.length} · ${_steps[currentStep].label}',
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(children: [
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                    color: Colors.white, shape: BoxShape.circle),
              ),
              const SizedBox(width: 5),
              const Text('Live',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w700)),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _lawyerCard(Map<String, dynamic> lawyer) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2))
        ],
      ),
      child: Row(children: [
        // CircleAvatar(
        //   radius: 26,
        //   backgroundColor: _kPrimary.withOpacity(0.12),
        //   child: Text(
        //     lawyer['avatar'] as String? ?? 'ท',
        //     style: const TextStyle(
        //         color: _kPrimary, fontWeight: FontWeight.bold, fontSize: 20),
        //   ),
        // ),
        ClipRRect(
          borderRadius: BorderRadius.circular(50),
          child: Container(
            width: 60,
            height: 60,
            color: const Color(0xFFF2F4F7),
            child: lawyer['imageUrl'] != null
                ? Image.asset(
                    lawyer['imageUrl'] as String,
                    fit: BoxFit.cover,
                  )
                : Center(
                    child: Text(
                      lawyer['avatar'] as String,
                      style: TextStyle(
                          fontSize: 48,
                          color: Color(lawyer['color'] as int),
                          fontWeight: FontWeight.bold),
                    ),
                  ),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(lawyer['name'] as String? ?? '',
                  style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      color: Color(0xFF1A2340))),
              const SizedBox(height: 3),
              Text(lawyer['title'] as String? ?? '',
                  style: TextStyle(color: Colors.grey[500], fontSize: 12)),
              const SizedBox(height: 6),
              Row(children: [
                const Icon(Icons.star_rounded,
                    color: Color(0xFFFFC107), size: 14),
                const SizedBox(width: 3),
                Text('${lawyer['rating'] ?? ''}',
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 13)),
              ]),
            ],
          ),
        ),
        // Container(
        //   padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        //   decoration: BoxDecoration(
        //     color: _kPrimary.withOpacity(0.1),
        //     borderRadius: BorderRadius.circular(12),
        //   ),
        //   child: const Icon(Icons.chat_bubble_outline_rounded,
        //       color: _kPrimary, size: 20),
        // ),
      ]),
    );
  }

  Widget _infoRow() {
    return Row(children: [
      if (widget.appointmentDate != null)
        Expanded(
            child: _infoChip(
                Icons.calendar_today_outlined, widget.appointmentDate!)),
      if (widget.appointmentDate != null && widget.appointmentTime != null)
        const SizedBox(width: 10),
      if (widget.appointmentTime != null)
        Expanded(
            child:
                _infoChip(Icons.access_time_rounded, widget.appointmentTime!)),
    ]);
  }

  Widget _infoChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFEEF2F5), width: 1.5),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2))
        ],
      ),
      child: Row(children: [
        Icon(icon, color: _kPrimary, size: 16),
        const SizedBox(width: 8),
        Text(label,
            style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: Color(0xFF1A2340))),
      ]),
    );
  }

  Widget _progressCard(int currentStep) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _kPrimary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.linear_scale_rounded,
                  color: _kPrimary, size: 16),
            ),
            const SizedBox(width: 10),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('ขั้นตอนการดำเนินการ',
                  style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      color: Color(0xFF1A2340))),
              Text('${currentStep + 1} จาก ${_steps.length} ขั้นตอน',
                  style: TextStyle(color: Colors.grey[400], fontSize: 11)),
            ]),
          ]),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: (currentStep + 1) / _steps.length,
              minHeight: 6,
              backgroundColor: const Color(0xFFEEF2F5),
              valueColor: const AlwaysStoppedAnimation<Color>(_kPrimary),
            ),
          ),
          const SizedBox(height: 24),
          ...List.generate(_steps.length, (i) {
            final delay = i * 0.15;
            return AnimatedBuilder(
              animation: _staggerController,
              builder: (_, child) {
                final t = Curves.easeOut.transform(
                  ((_staggerController.value - delay) / (1 - delay))
                      .clamp(0.0, 1.0),
                );
                return Opacity(
                  opacity: t,
                  child: Transform.translate(
                      offset: Offset(20 * (1 - t), 0), child: child),
                );
              },
              child: _stepItem(i, currentStep),
            );
          }),
        ],
      ),
    );
  }

  Widget _stepItem(int index, int currentStep) {
    final step = _steps[index];
    final isDone = index < currentStep;
    final isCurrent = index == currentStep;
    final isPending = index > currentStep;
    final isLast = index == _steps.length - 1;

    final dotColor = isDone
        ? const Color(0xFF16A34A)
        : isCurrent
            ? _kPrimary
            : const Color(0xFFCBD5E1);

    final lineColor =
        isDone ? const Color(0xFF16A34A) : const Color(0xFFEEF2F5);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 44,
            child: Column(children: [
              isCurrent
                  ? ScaleTransition(
                      scale: _pulseAnim,
                      child: _dot(dotColor, step.icon, isDone, isCurrent),
                    )
                  : _dot(dotColor, step.icon, isDone, isCurrent),
              if (!isLast)
                Expanded(
                  child: Center(
                    child: Container(
                      width: 2,
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      decoration: BoxDecoration(
                          color: lineColor,
                          borderRadius: BorderRadius.circular(2)),
                    ),
                  ),
                ),
            ]),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(top: 4, bottom: isLast ? 0 : 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Text(
                      step.label,
                      style: TextStyle(
                        fontWeight:
                            isCurrent ? FontWeight.w700 : FontWeight.w500,
                        fontSize: 14,
                        color: isPending
                            ? const Color(0xFFCBD5E1)
                            : isCurrent
                                ? _kPrimary
                                : const Color(0xFF1A2340),
                      ),
                    ),
                    if (isDone) ...[
                      const SizedBox(width: 6),
                      const Icon(Icons.check_circle_rounded,
                          color: Color(0xFF16A34A), size: 14),
                    ],
                    if (isCurrent) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: _kPrimary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text('ตอนนี้',
                            style: TextStyle(
                                color: _kPrimary,
                                fontSize: 10,
                                fontWeight: FontWeight.w700)),
                      ),
                    ],
                  ]),
                  const SizedBox(height: 3),
                  Text(
                    step.sublabel,
                    style: TextStyle(
                        fontSize: 12,
                        color: isPending
                            ? const Color(0xFFCBD5E1)
                            : Colors.grey[500]),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _dot(Color color, IconData icon, bool isDone, bool isCurrent) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isDone
            ? const Color(0xFFDCFCE7)
            : isCurrent
                ? _kPrimary.withOpacity(0.12)
                : const Color(0xFFF1F5F9),
        border: Border.all(
          color: isDone
              ? const Color(0xFF16A34A)
              : isCurrent
                  ? _kPrimary
                  : const Color(0xFFE2E8F0),
          width: isCurrent ? 2.5 : 1.5,
        ),
      ),
      child: Icon(
        isDone ? Icons.check_rounded : icon,
        size: 18,
        color: isDone
            ? const Color(0xFF16A34A)
            : isCurrent
                ? _kPrimary
                : const Color(0xFFCBD5E1),
      ),
    );
  }

  Widget _bottomBar(int currentStep, BuildContext context) {
    final String primaryLabel =
        currentStep == 3 ? 'เข้าสู่ห้องปรึกษา' : 'ให้คะแนนทนายความ';
    final IconData primaryIcon =
        currentStep == 3 ? Icons.video_call_rounded : Icons.star_rate_rounded;

    return Container(
      padding: EdgeInsets.fromLTRB(
          20, 12, 20, MediaQuery.of(context).padding.bottom + 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
              color: Color(0x15000000), blurRadius: 10, offset: Offset(0, -3))
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: () {
              currentStep == 3
                  ? Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(
                          builder: (_) =>
                              MessageFormPage(model: widget.lawyer)),
                      (Route<dynamic> route) => route.isFirst)
                  : showRatingDialog(context);
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
                      color: _kPrimary.withOpacity(0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4))
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(primaryIcon, color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                  Text(primaryLabel,
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 15)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          GestureDetector(
            onTap: () => Navigator.popUntil(context, (route) => route.isFirst),
            child: Container(
              height: 48,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFEEF2F5), width: 1.5),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.home_outlined, color: Color(0xFF64748B), size: 18),
                  SizedBox(width: 8),
                  Text('กลับหน้าหลัก',
                      style: TextStyle(
                          color: Color(0xFF64748B),
                          fontWeight: FontWeight.w600,
                          fontSize: 14)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StepData {
  final IconData icon;
  final String label;
  final String sublabel;
  const _StepData(
      {required this.icon, required this.label, required this.sublabel});
}

// ══════════════════════════════════════════════════════════
//  Rating Dialog — แก้ keyboard overflow
// ══════════════════════════════════════════════════════════
void showRatingDialog(BuildContext context) {
  double rating = 0;
  bool submitted = false;
  final TextEditingController commentController = TextEditingController();

  showDialog(
    context: context,
    // ✅ ทำให้ dialog ขยับขึ้นเมื่อ keyboard เปิด
    barrierColor: Colors.black.withOpacity(0.45),
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setState) {
          return Dialog(
            backgroundColor: Colors.transparent,
            // ✅ insetPadding ตอบสนอง keyboard (viewInsets.bottom)
            insetPadding: EdgeInsets.fromLTRB(
                24, MediaQuery.of(context).size.height * 0.01, 24, 0
                // MediaQuery.of(context).viewInsets.bottom + 16,
                ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 350),
                switchInCurve: Curves.easeOutBack,
                switchOutCurve: Curves.easeIn,
                transitionBuilder: (child, animation) => ScaleTransition(
                  scale: animation,
                  child: FadeTransition(opacity: animation, child: child),
                ),
                child: submitted
                    ? _buildSuccessContent(context)
                    : _buildFormContent(
                        context,
                        rating,
                        commentController,
                        (value) => setState(() => rating = value),
                        () => setState(() => submitted = true),
                      ),
              ),
            ),
          );
        },
      );
    },
  );
}

Widget _buildSuccessContent(BuildContext context) {
  return Container(
    key: const ValueKey('success'),
    color: Colors.white,
    padding: const EdgeInsets.fromLTRB(24, 40, 24, 32),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: const BoxDecoration(
              color: Color(0xFFE8F5E9), shape: BoxShape.circle),
          child: const Icon(Icons.check_rounded,
              color: Color(0xFF2E7D32), size: 44),
        ),
        const SizedBox(height: 20),
        const Text('ส่งคะแนนสำเร็จ!',
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A2340))),
        const SizedBox(height: 8),
        Text(
          'ขอบคุณที่ให้ความคิดเห็น\nคะแนนของคุณมีคุณค่ามากสำหรับเรา',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 13, color: Colors.grey[500], height: 1.6),
        ),
        const SizedBox(height: 28),
        GestureDetector(
          onTap: () => Navigator.popUntil(context, (route) => route.isFirst),
          child: Container(
            height: 50,
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                  colors: [Color(0xFF0262EC), Color(0xFF0485FF)]),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                    color: const Color(0xFF0262EC).withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4))
              ],
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.home_rounded, color: Colors.white, size: 18),
                SizedBox(width: 8),
                Text('กลับหน้าหลัก',
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 15)),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}

Widget _buildFormContent(
  BuildContext context,
  double rating,
  TextEditingController commentController,
  ValueChanged<double> onRatingUpdate,
  VoidCallback onSubmit,
) {
  return Container(
    key: const ValueKey('form'),
    color: Colors.white,
    // ✅ ครอบด้วย SingleChildScrollView ป้องกัน overflow เมื่อ keyboard ขึ้น
    child: SingleChildScrollView(
      physics: const ClampingScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('ให้คะแนนทนาย',
                style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A2340))),
            const SizedBox(height: 4),
            Text('ความคิดเห็นของคุณมีคุณค่ามาก',
                style: TextStyle(fontSize: 13, color: Colors.grey[400])),
            const SizedBox(height: 20),
            RatingBar.builder(
              initialRating: 0,
              minRating: 1,
              direction: Axis.horizontal,
              allowHalfRating: false,
              itemCount: 5,
              itemSize: 38,
              glow: false,
              itemPadding: const EdgeInsets.symmetric(horizontal: 4),
              itemBuilder: (context, _) =>
                  const Icon(Icons.star_rounded, color: Color(0xFFFFC107)),
              onRatingUpdate: onRatingUpdate,
            ),
            const SizedBox(height: 8),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Text(
                _ratingLabel(rating),
                key: ValueKey(rating),
                style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF0262EC),
                    fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: commentController,
              maxLines: 3,
              maxLength: 300,
              // ✅ ป้องกัน keyboard ดัน content แล้ว overflow
              keyboardType: TextInputType.multiline,
              textInputAction: TextInputAction.newline,
              decoration: InputDecoration(
                hintText: 'กรอกความคิดเห็น...',
                hintStyle: TextStyle(color: Colors.grey[400], fontSize: 13),
                filled: true,
                fillColor: const Color(0xFFEEF2F5),
                contentPadding: const EdgeInsets.all(14),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide:
                        const BorderSide(color: Color(0xFFEEF2F5), width: 1.5)),
                enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide:
                        const BorderSide(color: Color(0xFFEEF2F5), width: 1.5)),
                focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide:
                        const BorderSide(color: Color(0xFF0262EC), width: 1.5)),
                counterStyle: TextStyle(color: Colors.grey[400], fontSize: 11),
              ),
            ),
            const SizedBox(height: 16),
            Row(children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                          color: const Color(0xFFEEF2F5), width: 1.5),
                    ),
                    child: const Center(
                      child: Text('ยกเลิก',
                          style: TextStyle(
                              color: Color(0xFF64748B),
                              fontWeight: FontWeight.w600,
                              fontSize: 14)),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: GestureDetector(
                  onTap: rating > 0 ? onSubmit : null,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    height: 48,
                    decoration: BoxDecoration(
                      gradient: rating > 0
                          ? const LinearGradient(
                              colors: [Color(0xFF0262EC), Color(0xFF0485FF)])
                          : null,
                      color: rating > 0 ? null : const Color(0xFFCDD5E0),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: rating > 0
                          ? [
                              BoxShadow(
                                  color:
                                      const Color(0xFF0262EC).withOpacity(0.3),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4))
                            ]
                          : null,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.send_rounded,
                            color: rating > 0 ? Colors.white : Colors.grey[400],
                            size: 16),
                        const SizedBox(width: 6),
                        Text('ส่งคะแนน',
                            style: TextStyle(
                                color: rating > 0
                                    ? Colors.white
                                    : Colors.grey[400],
                                fontWeight: FontWeight.w700,
                                fontSize: 14)),
                      ],
                    ),
                  ),
                ),
              ),
            ]),
          ],
        ),
      ),
    ),
  );
}

String _ratingLabel(double rating) {
  switch (rating.toInt()) {
    case 1:
      return 'แย่มาก';
    case 2:
      return 'พอใช้';
    case 3:
      return 'ดีพอสมควร';
    case 4:
      return 'ดีมาก';
    case 5:
      return 'ยอดเยี่ยม! 🎉';
    default:
      return 'กรุณาให้คะแนน';
  }
}
