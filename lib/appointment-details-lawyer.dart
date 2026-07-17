import 'package:LawyerOnline/chat/chat_page_lawyer.dart';
import 'package:LawyerOnline/component/appbar.dart';
import 'package:LawyerOnline/component/dialog_service.dart';
import 'package:LawyerOnline/menu.dart';
import 'package:LawyerOnline/models/user_profile_store.dart';
import 'package:LawyerOnline/services/case_cancel_service.dart';
import 'package:LawyerOnline/shared/api_provider.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

class AppointmentDetailsLawyer extends StatefulWidget {
  AppointmentDetailsLawyer({Key? key, this.model});

  dynamic model;

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
  bool isLoadingLawyers = true;
  dynamic userModel = const {};

  int get _caseStatusInt {
    final raw = widget.model?['caseStatus'];
    if (raw is int) return raw;
    if (raw is num) return raw.toInt();
    return int.tryParse(raw?.toString() ?? '') ?? 1;
  }

  Future<void> _loadCaseDetails() async {
    final code = widget.model?['code']?.toString();
    if (code == null || code.isEmpty) return;
    try {
      final param = await postDio("${server}/m/case/read", {"code": code});
      final list = param['objectData'];
      if (list is List && list.isNotEmpty && mounted) {
        setState(() {
          widget.model = Map<String, dynamic>.from(list[0] as Map);
        });
      }
    } catch (_) {}
  }

  Future<void> callReadUser() async {
    try {
      final param = await postDio(
          "${server}/m/register/read", {"code": widget.model['userCode']});
      setState(() {
        userModel = param['objectData'][0];
        isLoadingLawyers = false;
        _animController = AnimationController(
          vsync: this,
          duration: const Duration(milliseconds: 500),
        );
        _fadeAnim =
            CurvedAnimation(parent: _animController, curve: Curves.easeOut);
        _slideAnim = Tween<Offset>(
          begin: const Offset(0, 0.06),
          end: Offset.zero,
        ).animate(
            CurvedAnimation(parent: _animController, curve: Curves.easeOut));
        _animController.forward();
        // _specialtyOptions = [...param['objectData']];
      });
    } catch (_) {
      isLoadingLawyers = false;
    }
  }

  @override
  void initState() {
    super.initState();
    _loadCaseDetails();
    callReadUser();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _onTapConversation(dynamic conv) async {
    setState(() {
      // appointmentList = param['objectData'];
      // _lawyerAppointments = param['objectData'];
      // _isLoadingAppointments = false;
    });
    String myUserId = UserProfileStore.instance.code;
    dynamic lawyerModel = {};

    await postDio("${server}/m/register/read", {"code": conv['lawyer']}).then(
      (paramLawyer) => {
        setState(
          () {
            lawyerModel = paramLawyer['objectData'][0];
          },
        ),
      },
    );

    List<String> ids = [userModel['code'], lawyerModel['code']]..sort();
    var model = {
      "members": ids,
      "userA": userModel['code'],
      "userB": lawyerModel['code'],
      "caseCode":  widget.model['code'],
    };
    var roomCode;
    await postObjectData("/m/chat/room/create", model).then(
      (result) async => {
        if (result['status'] == 'S')
          {
            setState(() {
              roomCode = result['objectData']['roomCode'];
            }),
            await postObjectData("/m/case/update", {
              "code": widget.model['code'],
              "messageRoomCode": roomCode,
              "caseStatus": 3,
            }).then(
              (res) => {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => ChatPageLawyer(
                            model: {
                              'code': widget.model['code'],
                              'name':
                                  '${userModel['firstName']} ${userModel['lastName']}',
                              'avatar': userModel['imageUrl'],
                              // 'clientColor': conv.clientColor,
                              'active': true,
                              'caseSuccess': false,
                            },
                            // jobId: conv.id,
                            roomCode: roomCode,
                            userId: myUserId,
                          )),
                ),
              },
            ),
          }
      },
    );
  }

  // สถานะการนัดหมาย (0=ยกเลิก, 1=รอยืนยัน, 2=ยืนยันแล้ว, 3=กำลังปรึกษา, 4=เสร็จสิ้น)
  int get appointmentStatus => _caseStatusInt;
  String get paymentStatus => widget.model?['isPay'] ?? false;

  // รายละเอียดนัดหมาย กดจากหน้าแรก

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
      body: isLoadingLawyers
          ? _loadingState()
          : FadeTransition(
              opacity: _fadeAnim,
              child: SlideTransition(
                position: _slideAnim,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 120),
                  children: [
                    _buildClientHeader(),
                    const SizedBox(height: 16),
                    if (_caseStatusInt == 0) ...[
                      _buildCancelCard(),
                      const SizedBox(height: 16),
                    ],
                    _buildStatusRow(),
                    const SizedBox(height: 16),
                    _buildAppointmentCard(),
                    const SizedBox(height: 16),
                    _buildCaseCard(),
                    const SizedBox(height: 16),
                    _buildPaymentCard(),
                    // appointmentStatus == 3
                    //     ? _buildAcceptedButton(context)
                    //     : const SizedBox()
                  ],
                ),
              ),
            ),
      bottomNavigationBar: _caseStatusInt == 1 || _caseStatusInt == 3
          ? _buildBottomActions()
          : const SizedBox(),
    );
  }

  Widget _loadingState() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
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
          userModel['imageUrl'] != ""
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(43),
                  child: Container(
                    width: 45,
                    height: 45,
                    color: Colors.white.withOpacity(0.2),
                    child: Image.network(
                      userModel['imageUrl'] ?? '',
                      fit: BoxFit.cover,
                    ),
                  ),
                )
              : Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: Colors.white.withOpacity(0.4), width: 2),
                  ),
                  child: const Center(
                    child: Icon(Icons.person_rounded,
                        color: Colors.white, size: 28),
                  ),
                ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.model?['userName'] ?? 'ลูกความ',
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
                      widget.model?['caseType'] == 1
                          ? 'นัดหมายล่วงหน้า'
                          : 'เคสด่วน',
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

  Widget _appointmentBadge(int status) {
    final dotColor = status == 0
        ? _kDanger
        : status == 2 || status == 3 || status == 4
            ? _kSuccess
            : Colors.amber;

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
              color: dotColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            status == 2
                ? 'ยืนยันแล้ว'
                : status == 1
                    ? 'รอยืนยัน'
                    : status == 0
                        ? 'ยกเลิกแล้ว'
                        : status == 3
                            ? 'กำลังปรึกษา'
                            : 'เสร็จสิ้น',
            style: const TextStyle(
                color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  // ── Status Row: Payment + Appointment ──────────────────
  Widget _buildStatusRow() {
    final isPaid = widget.model?['isPay'];
    final cs = _caseStatusInt;
    final appointmentLabel = cs == 0
        ? 'ยกเลิกแล้ว'
        : cs == 2
            ? 'ยืนยันแล้ว'
            : cs == 1
                ? 'รอยืนยัน'
                : cs == 3
                    ? 'กำลังปรึกษา'
                    : cs == 4
                        ? 'เสร็จสิ้น'
                        : 'รอยืนยัน';
    final appointmentColor = cs == 0
        ? _kDanger
        : cs == 2 || cs == 3 || cs == 4
            ? _kSuccess
            : Colors.orange;

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
            value: appointmentLabel,
            color: appointmentColor,
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
          value: widget.model?['caseDate'] ?? '-',
        ),
        _divider(),
        _infoRow(
          icon: Icons.access_time_rounded,
          label: 'ช่วงเวลา',
          value: '${widget.model?['startTime']}-${widget.model?['endTime']}',
        ),
      ],
    );
  }

  // ── Card: ข้อมูลคดี ─────────────────────────────────────
  Widget _buildCaseCard() {
    return _infoCard(
      icon: Icons.gavel_rounded,
      title: 'รายละเอียด',
      iconBg: const Color(0xFFFFF3EE),
      iconColor: const Color(0xFFED6B2D),
      children: [
        _infoRow(
          icon: Icons.folder_outlined,
          label: 'ประเภทหัวข้อ',
          value: widget.model?['topicTitle'] ?? '-',
        ),
        _divider(),
        _infoRow(
          icon: Icons.subdirectory_arrow_right_rounded,
          label: 'หัวข้อ',
          value: widget.model?['subTopicTitle'] ?? '-',
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
    final isPaid = widget.model?['isPay'];
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

  Widget _buildCancelCard() {
    return _infoCard(
      icon: Icons.cancel_outlined,
      title: 'รายละเอียดการยกเลิก',
      iconBg: const Color.fromARGB(255, 255, 238, 238),
      iconColor: Colors.red,
      children: [
        _infoRow(
          icon: Icons.calendar_today,
          label: 'วันที่ยกเลิก',
          value: widget.model?['cancelDate']?.toString() ?? '-',
        ),
        _divider(),
        _infoRow(
          icon: Icons.alarm,
          label: 'เวลาที่ยกเลิก',
          value: widget.model?['cancelTime']?.toString() ?? '-',
        ),
        _divider(),
        _infoRowMultiLine(
          icon: Icons.notes_rounded,
          label: 'เหตุการยกเลิก',
          value: widget.model?['reasonCancel'] ?? '-',
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
      child: _caseStatusInt == 3
          ? Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  onTap: () {
                    _onTapConversation(widget.model);
                  },
                  child: Container(
                    height: 52,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                          colors: [Color(0xFF0262EC), Color(0xFF0099FF)]),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                            color: _kPrimary.withOpacity(0.4),
                            blurRadius: 14,
                            offset: const Offset(0, 4))
                      ],
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.headset_mic_rounded,
                            color: Colors.white, size: 18),
                        SizedBox(width: 8),
                        Text('เริ่มปรึกษา / แชทกับลูกความ',
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                fontSize: 15)),
                      ],
                    ),
                  ),
                ),
                if ((widget.model['cancelReviewStatus']?.toString() ?? '') ==
                    'pending') ...[
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF7ED),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFFDBA74)),
                    ),
                    child: const Text(
                      'คำขอยกเลิกอยู่ระหว่างรอแอดมินตรวจสอบเหตุผล',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Color(0xFF9A3412),
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ] else ...[
                  const SizedBox(height: 10),
                  GestureDetector(
                    onTap: () {
                      DialogService.showConfirmRejectJob(
                        context,
                        title: 'ขอยกเลิกการปรึกษา',
                        message:
                            'คุณยืนยันที่จะขอยกเลิกขณะกำลังปรึกษาใช่หรือไม่? จะต้องระบุเหตุผลเพื่อให้แอดมินตรวจสอบ',
                        onConfirm: () {
                          showReasonCancelDialog(context);
                        },
                      );
                    },
                    child: Container(
                      height: 48,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFEBEE),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Text(
                        'ขอยกเลิก (ระบุเหตุผล)',
                        style: TextStyle(
                          color: Color(0xFFC62828),
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            )
          : Row(
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
                          Icon(Icons.check_rounded,
                              color: Colors.white, size: 18),
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
            )
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
                    fontSize: 13, color: Colors.grey[500], height: 1.4),
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
                        isApprove ?  updateStatusApproveCase(2) : showReasonCancelDialog(context);
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

  void showReasonCancelDialog(BuildContext context) {
    final TextEditingController reasonCancelController =
        TextEditingController();

    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.45),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Dialog(
              backgroundColor: Colors.transparent,
              insetPadding: EdgeInsets.fromLTRB(
                  24, MediaQuery.of(context).size.height * 0.01, 24, 0),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: _buildFormContent(
                  context,
                  reasonCancelController,
                  setState, // ✅ ส่ง setState ลงไป
                ),
              ),
            );
          },
        );
      },
    );
  }

   Widget _buildFormContent(
    BuildContext context,
    TextEditingController reasonCancelController,
    StateSetter setState, // ✅ รับ setState มาใช้
  ) {
    final hasText = reasonCancelController.text.trim().isNotEmpty;

    return Container(
      key: const ValueKey('form'),
      color: Colors.white,
      child: SingleChildScrollView(
        physics: const ClampingScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('เหตุผลการยกเลิก',
                  style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A2340))),
              const SizedBox(height: 4),
              Text('กรุณาใส่เหตุผลในการยกเลิกนัดหมาย',
                  style: TextStyle(fontSize: 13, color: Colors.grey[400])),
              const SizedBox(height: 20),
              TextFormField(
                controller: reasonCancelController,
                maxLines: 3,
                maxLength: 300,
                keyboardType: TextInputType.multiline,
                textInputAction: TextInputAction.newline,
                // ✅ trigger rebuild ทุกครั้งที่พิมพ์
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: 'กรอกเหตุผล...',
                  hintStyle: TextStyle(color: Colors.grey[400], fontSize: 13),
                  filled: true,
                  fillColor: const Color(0xFFEEF2F5),
                  contentPadding: const EdgeInsets.all(14),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(
                          color: Color(0xFFEEF2F5), width: 1.5)),
                  enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(
                          color: Color(0xFFEEF2F5), width: 1.5)),
                  focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(
                          color: Color(0xFF0262EC), width: 1.5)),
                  counterStyle:
                      TextStyle(color: Colors.grey[400], fontSize: 11),
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
                    onTap: hasText
                        ? () => updateStatusRejectCase(
                            reasonCancelController.text, 0)
                        : null, // ✅ ปิดปุ่มเมื่อไม่มีข้อความ
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      height: 48,
                      decoration: BoxDecoration(
                        gradient: hasText
                            ? const LinearGradient(
                                colors: [Color(0xFF0262EC), Color(0xFF0485FF)])
                            : null,
                        color: hasText ? null : const Color(0xFFCDD5E0),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: hasText
                            ? [
                                BoxShadow(
                                    color: const Color(0xFF0262EC)
                                        .withOpacity(0.3),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4))
                              ]
                            : null,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.send_rounded,
                              color: hasText ? Colors.white : Colors.grey[400],
                              size: 16),
                          const SizedBox(width: 6),
                          Text('ส่งเหตุผล',
                              style: TextStyle(
                                  color:
                                      hasText ? Colors.white : Colors.grey[400],
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

  Future<void> updateStatusRejectCase(reasonCancel, caseStatus) async {
    DialogService.showLoading(context);
    try {
      if (_caseStatusInt == 3 || caseStatus == 3) {
        final param = await CaseCancelService.requestCancel(
          caseCode: widget.model['code']?.toString() ?? '',
          reasonCancel: reasonCancel.toString(),
          requesterCode: UserProfileStore.instance.code,
          userType: 'lawyer',
        );
        if (!mounted) return;
        Navigator.pop(context); // loading
        if (param['status'] == 'S') {
          Navigator.pop(context); // reason dialog
          setState(() {
            widget.model['cancelReviewStatus'] = 'pending';
            widget.model['reasonCancel'] = reasonCancel.toString();
          });
          DialogService.showSuccess(
            context,
            title: 'ส่งคำขอยกเลิกแล้ว',
            message:
                'คำขอยกเลิกถูกส่งให้แอดมินตรวจสอบเหตุผลแล้ว จะแจ้งผลเมื่อดำเนินการเสร็จ',
            onClose: () {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => MenuPage(pageIndex: 0)),
                (route) => false,
              );
            },
          );
        } else {
          DialogService.showError(
            context,
            title: 'ส่งคำขอยกเลิกไม่สำเร็จ',
            message: param['message']?.toString() ?? 'กรุณาลองใหม่',
          );
        }
        return;
      }

      dynamic model = {
        "code": widget.model['code'],
        "caseStatus": caseStatus,
        "reasonCancel": reasonCancel,
        "userType": "lawyer",
        "userCode": widget.model['userCode'],
        "lawyer": widget.model['lawyer'] ?? UserProfileStore.instance.code,
        "userName": widget.model['userName'],
        "lawyerName": widget.model['lawyerName'],
        "updateBy": UserProfileStore.instance.code,
        "cancelDate": DateFormat('yyyy-MM-dd').format(DateTime.now()),
        "cancelTime": DateFormat('HH:mm:ss').format(DateTime.now()),
      };
      final param = await postDio("${server}/m/case/update", model);
      if (param['status'] == 'S') {
        Navigator.pop(context);
        setState(() {
          widget.model['caseStatus'] = caseStatus;
          widget.model['reasonCancel'] = reasonCancel.toString();
          widget.model['cancelDate'] = model['cancelDate'];
          widget.model['cancelTime'] = model['cancelTime'];
        });
        _showResultDialog(isApprove: false);
      }
    } catch (_) {
    }
  }

   Future<void> updateStatusApproveCase(caseStatus) async {
    DialogService.showLoading(context);
    try {
      dynamic model = {
        "code": widget.model['code'],
        "caseStatus": caseStatus,
        "userCode": widget.model['userCode'],
        "lawyerName": widget.model['lawyerName'],
        "cancelDate": DateFormat('yyyy-MM-dd').format(DateTime.now()),
        "cancelTime": DateFormat('HH:mm:ss').format(DateTime.now()),
      };
      print(model);
      final param = await postDio("${server}/m/case/update", model);
      if (param['status'] == 'S') {
        Navigator.pop(context);
        _showResultDialog(isApprove: true);
      }
    } catch (_) {
      // if (!mounted) return;
      setState(() {
       Navigator.pop(context);
       DialogService.showError(
        context,
        title: 'ยืนยันนัดหมายไม่สำเร็จ',
        message: _.toString()
      );
      });
    }
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
                style: TextStyle(
                    fontSize: 13, color: Colors.grey[500], height: 1.5),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              GestureDetector(
                onTap: () {
                  Navigator.pop(ctx);
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                      builder: (_) => MenuPage(pageIndex: 0),
                    ),
                    (route) => false,
                  );
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
