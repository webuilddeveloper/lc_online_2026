import 'package:LawyerOnline/component/appbar.dart';
import 'package:flutter/material.dart';

class AppointmentDetailsLawyer extends StatefulWidget {
  AppointmentDetailsLawyer({Key? key, this.model, this.userType});

  dynamic model;
  String? userType;

  @override
  State<AppointmentDetailsLawyer> createState() =>
      _AppointmentDetailsLawyerState();
}

class _AppointmentDetailsLawyerState extends State<AppointmentDetailsLawyer>
    with SingleTickerProviderStateMixin {
  static const _kPrimary = Color(0xFF0262EC);
  static const _kSuccess = Color(0xFF34C759);
  static const _kDanger = Color(0xFFFF3B30);
  static const _kBg = Color(0xFFF5F7FA);

  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  bool get isLawyer => widget.userType == 'lawyer';

  // สถานะการนัดหมาย (mock: '1' = รอยืนยัน, '2' = ยืนยันแล้ว)
  String get appointmentStatus => widget.model?['appointmentStatus'] ?? '1';
  String get paymentStatus => widget.model?['paymentStatus'] ?? '1';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      appBar: appBar(
        title: "รายละเอียดนัดหมาย",
        backBtn: true,
        rightBtn: false,
        backAction: () => goBack(),
        rightAction: () {},
      ),
      body: FadeTransition(
        opacity: _fadeAnim,
        child: SlideTransition(
          position: _slideAnim,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 120),
            children: [
              _buildClientHeader(),
              const SizedBox(height: 16),
              _buildStatusRow(),
              const SizedBox(height: 16),
              _buildAppointmentCard(),
              const SizedBox(height: 16),
              _buildCaseCard(),
              const SizedBox(height: 16),
              _buildPaymentCard(),
            ],
          ),
        ),
      ),
      bottomNavigationBar: isLawyer ? _buildBottomActions() : const SizedBox(),
    );
  }

  // ── Header: รูป + ชื่อลูกความ ──────────────────────────
  Widget _buildClientHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0262EC), Color(0xFF34AAFF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: _kPrimary.withOpacity(0.35),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withOpacity(0.4), width: 2),
            ),
            child: const Center(
              child: Icon(Icons.person_rounded, color: Colors.white, size: 28),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.model?['clientName'] ?? 'ลูกความ',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.gavel_rounded,
                        color: Colors.white70, size: 13),
                    const SizedBox(width: 5),
                    Text(
                      widget.model?['caseType'] ?? '',
                      style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                          fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Badge สถานะนัดหมาย
          _appointmentBadge(appointmentStatus),
        ],
      ),
    );
  }

  Widget _appointmentBadge(String status) {
    final isConfirmed = status != '1';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withOpacity(0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              color: isConfirmed ? _kSuccess : Colors.amber,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            isConfirmed ? 'ยืนยันแล้ว' : 'รอยืนยัน',
            style: const TextStyle(
                color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  // ── Status Row: Payment + Appointment ──────────────────
  Widget _buildStatusRow() {
    final isPaid = paymentStatus != '1';
    final isConfirmed = appointmentStatus != '1';

    return Row(
      children: [
        Expanded(
          child: _statusCard(
            icon: Icons.payments_outlined,
            label: 'การชำระเงิน',
            value: isPaid ? 'ชำระแล้ว' : 'รอชำระ',
            color: isPaid ? _kSuccess : Colors.orange,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _statusCard(
            icon: Icons.event_available_outlined,
            label: 'การนัดหมาย',
            value: isConfirmed ? 'ยืนยันแล้ว' : 'รอยืนยัน',
            color: isConfirmed ? _kSuccess : Colors.orange,
          ),
        ),
      ],
    );
  }

  Widget _statusCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey[500],
                        fontWeight: FontWeight.w500)),
                const SizedBox(height: 2),
                Text(value,
                    style: TextStyle(
                        fontSize: 13,
                        color: color,
                        fontWeight: FontWeight.w700)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Card: วันเวลานัดหมาย ────────────────────────────────
  Widget _buildAppointmentCard() {
    return _infoCard(
      icon: Icons.calendar_month_rounded,
      title: 'ข้อมูลนัดหมาย',
      iconBg: const Color(0xFFEEF5FF),
      iconColor: _kPrimary,
      children: [
        _infoRow(
          icon: Icons.calendar_today_outlined,
          label: 'วันที่นัดหมาย',
          value: widget.model?['appointmentDate'] ?? '-',
        ),
        _divider(),
        _infoRow(
          icon: Icons.access_time_rounded,
          label: 'ช่วงเวลา',
          value: widget.model?['appointmentTime'] ?? '-',
        ),
      ],
    );
  }

  // ── Card: ข้อมูลคดี ─────────────────────────────────────
  Widget _buildCaseCard() {
    return _infoCard(
      icon: Icons.gavel_rounded,
      title: 'ข้อมูลคดี',
      iconBg: const Color(0xFFFFF3EE),
      iconColor: const Color(0xFFED6B2D),
      children: [
        _infoRow(
          icon: Icons.folder_outlined,
          label: 'ประเภทคดี',
          value: widget.model?['caseType'] ?? '-',
        ),
        _divider(),
        _infoRow(
          icon: Icons.subdirectory_arrow_right_rounded,
          label: 'ประเภทคดีย่อย',
          value: widget.model?['subCaseType'] ?? '-',
        ),
        _divider(),
        _infoRow(
          icon: Icons.title_rounded,
          label: 'หัวข้อคดี',
          value: widget.model?['title'] ?? '-',
        ),
        _divider(),
        _infoRowMultiLine(
          icon: Icons.notes_rounded,
          label: 'รายละเอียดเพิ่มเติม',
          value: widget.model?['details'] ?? '-',
        ),
      ],
    );
  }

  // ── Card: การชำระเงิน ────────────────────────────────────
  Widget _buildPaymentCard() {
    final isPaid = paymentStatus != '1';
    return _infoCard(
      icon: Icons.account_balance_wallet_outlined,
      title: 'การชำระเงิน',
      iconBg: const Color(0xFFEEFAF1),
      iconColor: _kSuccess,
      children: [
        _infoRow(
          icon: Icons.payments_outlined,
          label: 'สถานะ',
          value: isPaid ? 'ชำระเงินสำเร็จ' : 'รอชำระเงิน',
          valueColor: isPaid ? _kSuccess : Colors.orange,
        ),
      ],
    );
  }

  // ── Reusable: infoCard wrapper ──────────────────────────
  Widget _infoCard({
    required IconData icon,
    required String title,
    required Color iconBg,
    required Color iconColor,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Card Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: iconBg,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: iconColor, size: 17),
                ),
                const SizedBox(width: 10),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1A2340),
                  ),
                ),
              ],
            ),
          ),
          Container(height: 1, color: const Color(0xFFF0F3F8)),
          // Card Body
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
            child: Column(children: children),
          ),
        ],
      ),
    );
  }

  Widget _infoRow({
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(icon, size: 15, color: _kPrimary.withOpacity(0.6)),
          const SizedBox(width: 10),
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[500],
                  fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: valueColor ?? const Color(0xFF1A2340),
              ),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRowMultiLine({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 15, color: _kPrimary.withOpacity(0.6)),
              const SizedBox(width: 10),
              Text(
                label,
                style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[500],
                    fontWeight: FontWeight.w500),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F7FA),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF1A2340),
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _divider() => Container(
        height: 1,
        color: const Color(0xFFF0F3F8),
        margin: const EdgeInsets.symmetric(vertical: 0),
      );

  // ── Bottom Actions (Lawyer only) ────────────────────────
  Widget _buildBottomActions() {
    return Container(
      padding: EdgeInsets.fromLTRB(
          16, 12, 16, MediaQuery.of(context).padding.bottom + 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.07),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: [
          // ปุ่มไม่อนุมัติ
          Expanded(
            child: GestureDetector(
              onTap: () => _showConfirmDialog(isApprove: false),
              child: Container(
                height: 50,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF0EE),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                      color: _kDanger.withOpacity(0.3), width: 1.5),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.close_rounded, color: _kDanger, size: 18),
                    SizedBox(width: 6),
                    Text(
                      'ปฏิเสธ',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: _kDanger,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // ปุ่มยืนยัน
          Expanded(
            flex: 2,
            child: GestureDetector(
              onTap: () => _showConfirmDialog(isApprove: true),
              child: Container(
                height: 50,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF0262EC), Color(0xFF0099FF)],
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
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.check_rounded, color: Colors.white, size: 18),
                    SizedBox(width: 6),
                    Text(
                      'ยืนยันนัดหมาย',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Confirm Dialog ──────────────────────────────────────
  void _showConfirmDialog({required bool isApprove}) {
    showDialog(
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.4),
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        elevation: 0,
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.12),
                blurRadius: 40,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icon Circle
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: isApprove
                      ? _kPrimary.withOpacity(0.1)
                      : _kDanger.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isApprove
                      ? Icons.event_available_rounded
                      : Icons.event_busy_rounded,
                  color: isApprove ? _kPrimary : _kDanger,
                  size: 36,
                ),
              ),
              const SizedBox(height: 18),
              Text(
                isApprove ? 'ยืนยันนัดหมาย' : 'ปฏิเสธนัดหมาย',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: isApprove ? _kPrimary : _kDanger,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                isApprove
                    ? 'ต้องการยืนยันการนัดหมายนี้ใช่หรือไม่?'
                    : 'ต้องการปฏิเสธการนัดหมายนี้ใช่หรือไม่?',
                style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[500],
                    height: 1.4),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  // ปุ่มยกเลิก
                  Expanded(
                    child: GestureDetector(
                      onTap: () => Navigator.pop(ctx),
                      child: Container(
                        height: 46,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF2F6FF),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: const Color(0xFFDDE5F4), width: 1.5),
                        ),
                        child: const Center(
                          child: Text('ยกเลิก',
                              style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF5B6E8A))),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  // ปุ่มยืนยัน
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        Navigator.pop(ctx);
                        _showResultDialog(isApprove: isApprove);
                      },
                      child: Container(
                        height: 46,
                        decoration: BoxDecoration(
                          color: isApprove ? _kPrimary : _kDanger,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: (isApprove ? _kPrimary : _kDanger)
                                  .withOpacity(0.35),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            isApprove ? 'ยืนยัน' : 'ปฏิเสธ',
                            style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: Colors.white),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Result Dialog ───────────────────────────────────────
  void _showResultDialog({required bool isApprove}) {
    showDialog(
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.4),
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        elevation: 0,
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.12),
                blurRadius: 40,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Animated Icon
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: 1.0),
                duration: const Duration(milliseconds: 400),
                curve: Curves.elasticOut,
                builder: (_, v, child) =>
                    Transform.scale(scale: v, child: child),
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      colors: isApprove
                          ? [
                              _kPrimary.withOpacity(0.15),
                              _kPrimary.withOpacity(0.05)
                            ]
                          : [
                              _kSuccess.withOpacity(0.15),
                              _kSuccess.withOpacity(0.05)
                            ],
                    ),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isApprove
                          ? _kPrimary.withOpacity(0.3)
                          : _kSuccess.withOpacity(0.3),
                      width: 2,
                    ),
                  ),
                  child: Icon(
                    isApprove
                        ? Icons.check_circle_rounded
                        : Icons.cancel_rounded,
                    color: isApprove ? _kPrimary : _kSuccess,
                    size: 44,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                isApprove ? 'ยืนยันสำเร็จ!' : 'ปฏิเสธเรียบร้อย',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: isApprove ? _kPrimary : const Color(0xFF1A2340),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                isApprove
                    ? 'การนัดหมายได้รับการยืนยันแล้ว\nระบบจะแจ้งลูกความทันที'
                    : 'การนัดหมายถูกปฏิเสธแล้ว\nระบบจะแจ้งลูกความทันที',
                style:
                    TextStyle(fontSize: 13, color: Colors.grey[500], height: 1.5),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              GestureDetector(
                onTap: () {
                  Navigator.pop(ctx);
                  goBack();
                },
                child: Container(
                  width: double.infinity,
                  height: 50,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isApprove
                          ? [const Color(0xFF0262EC), const Color(0xFF0099FF)]
                          : [const Color(0xFF34C759), const Color(0xFF30D158)],
                    ),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: (isApprove ? _kPrimary : _kSuccess)
                            .withOpacity(0.35),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Text(
                      'เสร็จสิ้น',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w700),
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

  void goBack() async {
    Navigator.pop(context, false);
  }
}