import 'package:LawyerOnline/appointment-details.dart';
import 'package:LawyerOnline/chat/chat_page_user.dart';
import 'package:LawyerOnline/component/dialog_service.dart';
import 'package:LawyerOnline/component/loading_service.dart';
import 'package:LawyerOnline/menu.dart';
import 'package:LawyerOnline/models/user_profile_store.dart';
import 'package:LawyerOnline/shared/api_provider.dart';
import 'package:flutter/material.dart';
import 'package:LawyerOnline/component/appbar.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:LawyerOnline/shared/responsive/app_layout.dart';

/// caseStatus (logic เก่า):
///   0 = ยกเลิกเคส
///   2 = ทนายรับเคสแล้ว รอเริ่มปรึกษา
///   3 = กำลังปรึกษาทนายความ
///   4 = เสร็จสิ้น
///
/// caseType:
///   1 = นัดหมายล่วงหน้า
///   2 = เปิดเคสด่วน

int _caseStatusToStep(int caseStatus) {
  switch (caseStatus) {
    case 0:
      return 0; // ยกเลิก → ส่งคำขอ
    case 2:
      return 1; // รอเริ่มปรึกษา → รอการยืนยัน
    case 3:
      return 3; // กำลังปรึกษา → กำลังปรึกษา
    case 4:
      return 4; // เสร็จสิ้น
    default:
      return 0;
  }
}

class ConsultStatusPage extends StatefulWidget {
  final String caseCode;

  const ConsultStatusPage({Key? key, required this.caseCode}) : super(key: key);

  @override
  State<ConsultStatusPage> createState() => _ConsultStatusPageState();
}

class _ConsultStatusPageState extends State<ConsultStatusPage>
    with TickerProviderStateMixin {
  dynamic _caseData;
  bool _isLoading = true;
  dynamic lawyerModel;

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
    _loadCase();

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

  // ── Load Case Data (logic เก่า) ────────────────────────────────────────────
  Future<void> _loadCase() async {
    setState(() => _isLoading = true);
    try {
      final res = await postDio('${server}/m/case/read', {
        'code': widget.caseCode,
        'userCode': UserProfileStore.instance.code,
      });

      final resLawyer = await postDio('${server}/m/register/read', {
        'code': res['objectData'][0]['lawyer'],
      });

      if (resLawyer['status'] == 'S') {
        setState(() => lawyerModel = resLawyer['objectData'][0]);
      }

      // ✅ print ดูก่อน

      print('objectData: ${res['objectData']}');

      if (res['status'] == 'S' && res['objectData'] != null) {
        final raw = res['objectData'];
        if (raw is List && raw.isNotEmpty) {
          setState(
              () => _caseData = Map<String, dynamic>.from(raw.first as Map));
        } else if (raw is Map) {
          setState(() => _caseData = Map<String, dynamic>.from(raw));
        }
      }
    } catch (e) {
      print('_loadCase error: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  int? _parseCaseStatus(dynamic statusRaw) {
    if (statusRaw == null) return null;
    if (statusRaw is int) return statusRaw;
    if (statusRaw is double) return statusRaw.toInt();
    if (statusRaw is String) return int.tryParse(statusRaw.trim());
    return null;
  }

  // ── Helper: Get Current Step for UI ────────────────────────────────────────
  int get _currentStep {
    try {
      if (_caseData == null) return 0;
      if (_caseData is! Map) return 0;
      final statusRaw = (_caseData as Map)['caseStatus'];
      final status = _parseCaseStatus(statusRaw) ?? -1;
      final step = _caseStatusToStep(status);
      return step.clamp(0, _steps.length - 1);
    } catch (_) {
      return 0;
    }
  }

  // ── ยกเลิกเคส (logic เก่า) ────────────────────────────────────────────────
  Future<void> _cancelCase() async {
    final confirm = await DialogService.showConfirm(
      context,
      title: 'ยืนยันการยกเลิก',
      message: 'คุณต้องการยกเลิกเคสนี้ใช่ไหม?',
    );
    if (confirm != true) return;

    final res = await postDio('${server}/m/case/update', {
      'code': widget.caseCode,
      'userCode': UserProfileStore.instance.code,
      'caseStatus': 0, // Assuming 5 represents cancelled status

    });
    if (!mounted) return;
    if (res['status'] == 'S') {
      await _loadCase();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(res['message'] ?? 'ยกเลิกไม่สำเร็จ')),
      );
    }
  }

  // ── เปิดแชท (logic เก่า) ──────────────────────────────────────────────────
  void _openChat() async {
    if (_caseData == null) return;
    var roomCode;
    // สร้าง roomCode
    List<String> ids = [
      _caseData['userCode'],
      _caseData['lawyer']
    ]..sort();

    final currentCaseCode = _caseData['code']?.toString() ??
        widget.caseCode.toString();

    var model = {
      "members": ids,
      "userA": _caseData['userCode'],
      "userB": _caseData['lawyer'],
      "caseCode": currentCaseCode,
    };

    final result = await postObjectData("/m/chat/room/create", model);
    if (result['status'] != 'S' || !mounted) return;

    roomCode = result['objectData']['roomCode'];
    await postObjectData('/m/case/update', {
      'code': currentCaseCode,
      'messageRoomCode': roomCode,
    });
    if (!mounted) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatPageUser(
          model: {
            ...Map<String, dynamic>.from(_caseData as Map),
            'name':
                '${lawyerModel['firstName']} ${lawyerModel['lastName']}',
            'imageUrl': lawyerModel['imageUrl'],
            'caseCode': currentCaseCode,
            'code': currentCaseCode,
            'active': true,
            'caseSuccess': false,
          },
          roomCode: roomCode,
          userId: UserProfileStore.instance.code,
          caseCode: currentCaseCode,
        ),
      ),
    );
  }

  // ── Rating Dialog ──────────────────────────────────────────────────────────
  Future<void> createReview(String comment, double rating) async {
    Navigator.pop(context);
    DialogService.showLoading(context);
    try {
      dynamic model = {
        "lawyerRef": _caseData['lawyer'],
        "caseRef": _caseData['code'],
        "userRef": _caseData['userCode'],
        "comment": comment,
        "rate": rating
      };
      final param = await postDio("${server}/m/case/review/create", model);
      if (param['status'] == 'S') {
        await postDio("${server}/m/case/update", {
          "code": _caseData['code'],
          "isReview": true,
          "caseStatus": 4,
        }).then(
          (result) {
            if (result['status'] == 'S') {
              Navigator.pop(context);
              _buildSuccessContent(context);
            }
          },
        );
      }
    } catch (_) {
      Navigator.pop(context);
      DialogService.showError(
        context,
        title: "ให้คะแนนไม่สำเร็จ",
        message: _.toString(),
      );
    }
  }

  // ── Build Main UI ──────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      appBar: appBar(
        title: 'สถานะนัดหมาย',
        backBtn: true,
        rightBtn: false,
        rightAction: () {},
        backAction: () => Navigator.pop(context),
      ),
      body: _isLoading
          ? AppLoadingView(message: 'loading'.tr())
          : _caseData == null
              ? const Center(child: Text('ไม่พบข้อมูลเคส'))
              : AppLayout(
                  child: Column(
                    children: [
                      Expanded(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            children: [
                              _headerCard(),
                              const SizedBox(height: 16),
                              if (_caseData?['lawyerName'] != null &&
                                  (_caseData?['lawyerName'] as String)
                                      .isNotEmpty) ...[
                                _lawyerCard(),
                                const SizedBox(height: 16),
                              ],
                              _caseDetailCard(),
                              const SizedBox(height: 16),
                              if (_caseData?['appointmentDate'] != null ||
                                  _caseData?['appointmentTime'] != null) ...[
                                _infoRow(),
                                const SizedBox(height: 16),
                              ],
                              _progressCard(),
                              const SizedBox(height: 8),
                            ],
                          ),
                        ),
                      ),
                      _bottomBar(context),
                    ],
                  ),
                ),
    );
  }

  // ── Header Card ────────────────────────────────────────────────────────────
  Widget _headerCard() {
    return GestureDetector(
      onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => AppointmentDetails(appointment: _caseData!))),
      child: Container(
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
                    'ขั้นตอน ${_currentStep + 1}/${_steps.length} · ${_steps[_currentStep].label}',
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
            ),
            // Container(
            //   padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            //   decoration: BoxDecoration(
            //     color: Colors.white.withOpacity(0.2),
            //     borderRadius: BorderRadius.circular(20),
            //   ),
            //   child: Row(children: [
            //     Container(
            //       width: 6,
            //       height: 6,
            //       decoration: const BoxDecoration(
            //           color: Colors.white, shape: BoxShape.circle),
            //     ),
            //     // const SizedBox(width: 5),
            //     // const Text('Live',
            //     //     style: TextStyle(
            //     //         color: Colors.white,
            //     //         fontSize: 11,
            //     //         fontWeight: FontWeight.w700)),
            //   ]),
            // ),
          ],
        ),
      ),
    );
  }

  // ── Lawyer Card ────────────────────────────────────────────────────────────
  Widget _lawyerCard() {
    final lawyerName = _caseData?['lawyerName'] ?? '';
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
        (lawyerModel?['imageUrl'] ?? "") != ""
            ? ClipRRect(
                borderRadius: BorderRadius.circular(30),
                child: Image.network(
                  lawyerModel?['imageUrl'],
                  width: 55,
                  height: 55,
                  fit: BoxFit.cover,
                ),
              )
            : const CircleAvatar(
                radius: 30,
                backgroundColor: Color(0xFFF2F4F7),
                child: Icon(Icons.person, color: Color(0xFF0262EC)),
              ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                  '${lawyerModel?['firstName'] ?? ''} ${lawyerModel?['lastName'] ?? ''}',
                  style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      color: Color(0xFF1A2340))),
              const SizedBox(height: 3),
              Text('ทนายความของคุณ',
                  style: TextStyle(color: Colors.grey[500], fontSize: 12)),
            ],
          ),
        ),
      ]),
    );
  }

  // ── Case Detail Card ───────────────────────────────────────────────────────
  Widget _caseDetailCard() {
    return GestureDetector(
      onTap: () {
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => AppointmentDetails(appointment: _caseData!)));
      },
      child: Container(
        width: double.infinity,
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('รายละเอียดเคส',
                style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: Color(0xFF1A2340))),
            const SizedBox(height: 10),
            _infoRowCard('หัวข้อ', _caseData?['topicTitle'] ?? '-'),
            _infoRowCard('หมวดย่อย', _caseData?['subTopicTitle'] ?? '-'),
            _infoRowCard('จังหวัด', _caseData?['province'] ?? '-'),
            if ((_caseData?['story'] ?? '').toString().isNotEmpty)
              _infoRowCard('รายละเอียด', _caseData!['story']),
            if ((_caseData?['requirement'] ?? '').toString().isNotEmpty)
              _infoRowCard('ข้อเรียกร้อง', _caseData!['requirement']),
          ],
        ),
      ),
    );
  }

  Widget _infoRowCard(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(label,
                style: TextStyle(color: Colors.grey[600], fontSize: 12)),
          ),
          Expanded(
            child: Text(value,
                style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF1A2340))),
          ),
        ],
      ),
    );
  }

  // ── Info Row (Date & Time) ─────────────────────────────────────────────────
  Widget _infoRow() {
    return Row(children: [
      if (_caseData?['appointmentDate'] != null)
        Expanded(
            child: _infoChip(Icons.calendar_today_outlined,
                _caseData!['appointmentDate'] ?? '')),
      if (_caseData?['appointmentDate'] != null &&
          _caseData?['appointmentTime'] != null)
        const SizedBox(width: 10),
      if (_caseData?['appointmentTime'] != null)
        Expanded(
            child: _infoChip(Icons.access_time_rounded,
                _caseData!['appointmentTime'] ?? '')),
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

  // ── Progress Card ──────────────────────────────────────────────────────────
  Widget _progressCard() {
    final currentStep = _currentStep;
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

  // ── Bottom Bar ─────────────────────────────────────────────────────────────
  Widget _bottomBar(BuildContext context) {
    final status = _parseCaseStatus(_caseData?['caseStatus']) ?? -1;
    final currentStep = _currentStep;
    final canUsePrimaryAction = currentStep >= 3;
    final String primaryLabel =
        currentStep < 4 ? 'เข้าสู่ห้องปรึกษา' : 'ให้คะแนนทนายความ';
    final IconData primaryIcon =
        currentStep < 4 ? Icons.video_call_rounded : Icons.star_rate_rounded;

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
          // ปุ่มหลัก (Chat หรือ Rating)
          if (status == 3 || status == 4) ...[
            if (canUsePrimaryAction) ...[
              GestureDetector(
                onTap: () {
                  if (currentStep < 4) {
                    _openChat();
                  } else {
                    if (_caseData?['isReview'] == false) {
                      showRatingDialog(context);
                    }
                  }
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
            ],
          ],

          // ปุ่มดูนัดหมาย
          if (status == 2) ...[
            GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AppointmentDetails(appointment: _caseData),
                ),
              ),
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
                    const Icon(Icons.calendar_today,
                        color: Colors.white, size: 20),
                    const SizedBox(width: 8),
                    const Text('ดูรายละเอียดนัดหมาย',
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 15)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
          ],

          // ปุ่มยกเลิก
          if (status == 2) ...[
            GestureDetector(
              onTap: _cancelCase,
              child: Container(
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.red, width: 1.5),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.delete_outline, color: Colors.red, size: 18),
                    SizedBox(width: 8),
                    Text('ยกเลิกเคส',
                        style: TextStyle(
                            color: Colors.red,
                            fontWeight: FontWeight.w600,
                            fontSize: 14)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
          ],

          // ปุ่มกลับหน้าหลัก
          GestureDetector(
            onTap: () => {
              // Navigator.popUntil(context, (route) => route.isFirst)
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const MenuPage()),
                (route) => false,
              )
            },
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

  // ── Rating Dialog ──────────────────────────────────────────────────────────
  void showRatingDialog(BuildContext context) {
    double rating = 0;
    final TextEditingController commentController = TextEditingController();

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
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 350),
                  switchInCurve: Curves.easeOutBack,
                  switchOutCurve: Curves.easeIn,
                  transitionBuilder: (child, animation) => ScaleTransition(
                    scale: animation,
                    child: FadeTransition(opacity: animation, child: child),
                  ),
                  child: _buildFormContent(
                    context,
                    rating,
                    commentController,
                    (value) => setState(() => rating = value),
                    () {
                      createReview(commentController.text, rating);
                    },
                  ),
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
    double rating,
    TextEditingController commentController,
    ValueChanged<double> onRatingUpdate,
    VoidCallback onSubmit,
  ) {
    return Container(
      color: Colors.white,
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
              Text(
                _ratingLabel(rating),
                style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF0262EC),
                    fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: commentController,
                maxLines: 3,
                maxLength: 300,
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
                              color:
                                  rating > 0 ? Colors.white : Colors.grey[400],
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

  _buildSuccessContent(BuildContext context) {
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
                child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 350),
                    switchInCurve: Curves.easeOutBack,
                    switchOutCurve: Curves.easeIn,
                    transitionBuilder: (child, animation) => ScaleTransition(
                          scale: animation,
                          child:
                              FadeTransition(opacity: animation, child: child),
                        ),
                    child: Container(
                      color: Colors.white,
                      padding: const EdgeInsets.fromLTRB(24, 40, 24, 32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 80,
                            height: 80,
                            decoration: const BoxDecoration(
                                color: Color(0xFFE8F5E9),
                                shape: BoxShape.circle),
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
                            style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey[500],
                                height: 1.6),
                          ),
                          const SizedBox(height: 28),
                          GestureDetector(
                            onTap: () => Navigator.pushAndRemoveUntil(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const MenuPage()),
                              (route) => false,
                            ),
                            child: Container(
                              height: 50,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(colors: [
                                  Color(0xFF0262EC),
                                  Color(0xFF0485FF)
                                ]),
                                borderRadius: BorderRadius.circular(14),
                                boxShadow: [
                                  BoxShadow(
                                      color: const Color(0xFF0262EC)
                                          .withOpacity(0.3),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4))
                                ],
                              ),
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.home_rounded,
                                      color: Colors.white, size: 18),
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
                    )),
              ),
            );
          },
        );
      },
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
}

class _StepData {
  final IconData icon;
  final String label;
  final String sublabel;
  const _StepData(
      {required this.icon, required this.label, required this.sublabel});
}
