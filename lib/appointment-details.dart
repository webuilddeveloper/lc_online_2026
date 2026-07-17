import 'package:LawyerOnline/models/user/user_case_adapter.dart';
import 'package:LawyerOnline/receipt_page.dart';
import 'package:LawyerOnline/add-appointment.dart';
import 'package:LawyerOnline/case_workspace_page.dart';
import 'package:LawyerOnline/post_consultation_review_page.dart';
import 'package:LawyerOnline/services/appointment_reminder_service.dart';
import 'package:LawyerOnline/services/case_cancel_service.dart';
import 'package:LawyerOnline/booking/topic-page.dart';
import 'package:LawyerOnline/component/dialog_service.dart';
import 'package:LawyerOnline/menu.dart';
import 'package:LawyerOnline/models/user_profile_store.dart';
import 'package:LawyerOnline/shared/api_provider.dart';
import 'package:LawyerOnline/shared/app_typography.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;
import 'package:LawyerOnline/chat/chat_page_user.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:LawyerOnline/shared/responsive/res_layout.dart';
import 'package:LawyerOnline/shared/responsive/app_layout.dart';

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
    'status.requested',
    'status.waitingForConfirm',
    'status.confirmed',
    'status.consulting',
    'status.completed'
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
    ('steps.requested.title', 'steps.requested.desc'),
    ('steps.pending.title', 'steps.pending.desc'),
    ('steps.confirmed.title', 'steps.confirmed.desc'),
    ('steps.consulting.title', 'steps.consulting.desc'),
    ('steps.completed.title', 'steps.completed.desc'),
  ];

  dynamic lawyerModel = const {};
  bool isLoadingLawyers = true;

  @override
  void initState() {
    super.initState();
    debugPrint(
      'AppointmentDetails caseType=${widget.appointment['caseType']} '
      'code=${widget.appointment['code']}',
    );

    _scrollCtrl = ScrollController()
      ..addListener(() {
        if (mounted) setState(() => _scrollOffset = _scrollCtrl.offset);
      });

    _enterCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

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
    _enterCtrl.forward();

    callReadUser();
    _loadCaseDetails();
    AppointmentReminderService.scheduleForCase(widget.appointment);
  }

  Future<void> _loadCaseDetails() async {
    final code = widget.appointment['code']?.toString();
    if (code == null || code.isEmpty) return;
    try {
      final param = await postDio('${server}/m/case/read', {'code': code});
      final list = param['objectData'];
      if (list is List && list.isNotEmpty && mounted) {
        setState(() {
          final adapted = UserCaseAdapter.forAppointmentDetails(
            Map<String, dynamic>.from(list[0] as Map),
          );
          widget.appointment.addAll(adapted);
        });
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _enterCtrl.dispose();
    _pulseCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> callReadUser() async {
    try {
      final lawyerCode = widget.appointment['lawyer']?.toString() ??
          widget.appointment['lawyerCode']?.toString() ??
          '';
      if (lawyerCode.isEmpty) {
        if (mounted) setState(() => isLoadingLawyers = false);
        return;
      }
      final param =
          await postDio("${server}/m/register/read", {"code": lawyerCode});
      if (!mounted) return;
      final raw = param['objectData'];
      setState(() {
        if (raw is List && raw.isNotEmpty) {
          lawyerModel = raw[0];
        } else if (raw is Map) {
          lawyerModel = raw;
        }
        isLoadingLawyers = false;
      });
    } catch (_) {
      if (mounted) setState(() => isLoadingLawyers = false);
    }
  }

  Future<void> updateStatusRejectCase(reasonCancel, caseStatus) async {
    DialogService.showLoading(context);
    try {
      // กำลังปรึกษา → ส่งคำขอยกเลิกให้แอดมินตรวจเหตุผล
      if (appointmentModel['caseStatus'] == 3 || caseStatus == 3) {
        final param = await CaseCancelService.requestCancel(
          caseCode: widget.appointment['code']?.toString() ?? '',
          reasonCancel: reasonCancel.toString(),
          requesterCode: UserProfileStore.instance.code,
          userType: 'user',
        );
        if (!mounted) return;
        Navigator.pop(context); // close loading
        if (param['status'] == 'S') {
          Navigator.pop(context); // close reason dialog if still open
          setState(() {
            widget.appointment['cancelReviewStatus'] = 'pending';
            widget.appointment['reasonCancel'] = reasonCancel.toString();
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
        "code": widget.appointment['code'],
        "caseStatus": caseStatus,
        "reasonCancel": reasonCancel,
        "userType": "user",
        "userCode": widget.appointment['userCode'] ?? UserProfileStore.instance.code,
        "lawyer": widget.appointment['lawyer'],
        "userName": widget.appointment['userName'],
        "lawyerName": widget.appointment['lawyerName'] ??
            '${lawyerModel['firstName'] ?? ''} ${lawyerModel['lastName'] ?? ''}'
                .trim(),
        "updateBy": UserProfileStore.instance.code,
        "cancelDate": DateFormat('yyyy-MM-dd').format(DateTime.now()),
        "cancelTime": DateFormat('HH:mm:ss').format(DateTime.now()),
      };
      final param = await postDio("${server}/m/case/update", model);
      if (param['status'] == 'S') {
        Navigator.pop(context);
        setState(() {
          widget.appointment['caseStatus'] = caseStatus;
          widget.appointment['reasonCancel'] = reasonCancel.toString();
          widget.appointment['cancelDate'] = model['cancelDate'];
          widget.appointment['cancelTime'] = model['cancelTime'];
        });
        DialogService.showSuccess(
          context,
          title: "ยกเลิกนัดหมายแล้ว",
          message:
              "คุณได้ทำการยกเลิกนัดหมายทนายความกับ คุณ${lawyerModel['firstName']} ${lawyerModel['lastName']} เรียบร้อยแล้ว",
          onClose: () {
            Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => MenuPage(pageIndex: 0)),
                (route) => false);
          },
        );
      }
    } catch (_) {}
  }

  Future<void> createReview(comment, rating) async {
    Navigator.pop(context);
    DialogService.showLoading(context);
    try {
      // { "lawyerRef", value.lawyerRef },
      //                   { "caseRef", value.caseRef },
      //                   { "userRef", value.userRef },
      //                   { "rate", value.rate },
      //                   { "comment", value.comment},
      dynamic model = {
        "lawyerRef": widget.appointment['lawyer'],
        "caseRef": widget.appointment['code'],
        "userRef": widget.appointment['userCode'],
        "comment": comment,
        "rate": rating
      };
      print(model);
      final param = await postDio("${server}/m/case/review/create", model);
      if (param['status'] == 'S') {
        await postDio("${server}/m/case/update", {
          "code": widget.appointment['code'],
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
        title: "ให้คะแนนไม่สำเร็จสำเร็จ",
        message: _.toString(),
      );
    }
  }

  // ── Shorthand getters ────────────────────────────────────
  Map<String, dynamic> get appointmentModel => widget.appointment;

  bool get _isUrgentCase {
    final value = appointmentModel['caseType'] ??
        appointmentModel['CaseType'] ??
        appointmentModel['case_type'] ??
        appointmentModel['type'];
    if (value == 2 || value == '2' || value == 2.0) return true;
    if (value == 1 || value == '1' || value == 1.0) return false;
    if (value is num) return value.toInt() == 2;
    final text = value?.toString().trim().toLowerCase() ?? '';
    if (text == '2' ||
        text == 'urgent' ||
        text.contains('ด่วน') ||
        text == 'broadcast') {
      return true;
    }
    return false;
  }

  Color get _caseTypeColor =>
      _isUrgentCase ? const Color(0xFFDC2626) : const Color(0xFF0262EC);

  String get _caseTypeLabel =>
      _isUrgentCase ? 'caseTypeUrgent'.tr() : 'caseTypeBooking'.tr();

  IconData get _caseTypeIcon =>
      _isUrgentCase ? Icons.bolt_rounded : Icons.event_available_rounded;

  int get status {
    final raw = appointmentModel['caseStatus'];
    if (raw is int) return raw.clamp(0, 4);
    if (raw is num) return raw.toInt().clamp(0, 4);
    if (raw is String) return (int.tryParse(raw) ?? 1).clamp(0, 4);
    return 1;
  }

  bool get isCancelled => status == 0;
  bool get isDone => status == 4;
  bool get isActive => status == 3;
  bool get isTerminal => isCancelled || isDone;

  String get _statusLabel {
    switch (status) {
      case 0:
        return 'ยกเลิกแล้ว';
      case 1:
        return 'รอทนายรับเคส';
      case 2:
        return 'รอปรึกษา';
      case 3:
        return 'กำลังปรึกษา';
      case 4:
        return 'เสร็จสิ้น';
      default:
        return 'ไม่ทราบสถานะ';
    }
  }

  Color get _statusBannerColor {
    switch (status) {
      case 0:
        return const Color(0xFFDC2626);
      case 4:
        return const Color(0xFF7C3AED);
      case 3:
        return _green;
      case 2:
        return _blue;
      default:
        return const Color(0xFFD97706);
    }
  }
  Color get statusColor => _statusColors[status];
  Color get lawyerColor => Color(0xFF0262EC);

  // ════════════════════════════════════════════════════════
  //  BUILD
  // ════════════════════════════════════════════════════════

  bool get _isDesktop => ResponsiveLayout.isDesktop(context);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // backgroundColor: _isDesktop ? const Color(0xFFE9F2F9) : _surface,
      body: AppLayout(
        child: isLoadingLawyers
            ? _loadingState()
            : _isDesktop
                ? Column(
                    children: [
                      // Desktop inline header
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 14),
                        child: Row(
                          children: [
                            _circleBtn(
                              icon: Icons.arrow_back_ios_new_rounded,
                              color: _ink,
                              bg: Colors.white,
                              onTap: () {
                                HapticFeedback.lightImpact();
                                Navigator.pop(context);
                              },
                            ),
                            const SizedBox(width: 14),
                            Text(
                              'appointmentInfo.title'.tr(),
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: _ink,
                              ),
                            ),
                            const Spacer(),
                            _circleBtn(
                              icon: Icons.more_horiz_rounded,
                              color: _ink,
                              bg: Colors.white,
                              onTap: _showMenu,
                            ),
                          ],
                        ),
                      ),
                      // Desktop content area
                      Expanded(
                        child: Container(
                          decoration: const BoxDecoration(
                            color: _surface,
                            borderRadius:
                                BorderRadius.vertical(top: Radius.circular(20)),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: Stack(
                            children: [
                              CustomScrollView(
                                controller: _scrollCtrl,
                                physics: const ClampingScrollPhysics(),
                                slivers: [
                                  _buildHero(),
                                  SliverPadding(
                                    padding: const EdgeInsets.fromLTRB(
                                        20, 0, 20, 100),
                                    sliver: SliverList(
                                      delegate: SliverChildListDelegate([
                                        _stagger(0, _buildDateTimeRow()),
                                        _gap(14),
                                        _stagger(1, _buildStatusBanner()),
                                        if (status == 0) ...[
                                          _gap(14),
                                          _stagger(2, _buildCancelCard()),
                                        ],
                                        if (status == 4) ...[
                                          _gap(14),
                                          _stagger(2, _buildCompletedCard()),
                                        ],
                                        _gap(14),
                                        _stagger(3, _buildLawyerCard()),
                                        _gap(14),
                                        _stagger(4, _buildInfoCard()),
                                        _gap(14),
                                        _stagger(5, _buildWorkspaceCard()),
                                        if (status == 3 &&
                                            appointmentModel['rating'] !=
                                                null) ...[
                                          _gap(14),
                                          _stagger(6, _buildRatingCard()),
                                        ],
                                        _gap(14),
                                        _stagger(7, _buildNoteCard()),
                                      ]),
                                    ),
                                  ),
                                ],
                              ),
                              // Bottom CTA
                              Positioned(
                                bottom: 0,
                                left: 0,
                                right: 0,
                                child: _stagger(8, _buildBottomCTA()),
                              )
                            ],
                          ),
                        ),
                      ),
                    ],
                  )
                : Stack(
                    children: [
                      CustomScrollView(
                        controller: _scrollCtrl,
                        physics: const ClampingScrollPhysics(),
                        slivers: [
                          _buildHero(),
                          SliverPadding(
                            padding: const EdgeInsets.fromLTRB(15, 0, 15, 100),
                            sliver: SliverList(
                              delegate: SliverChildListDelegate([
                                _stagger(0, _buildDateTimeRow()),
                                _gap(14),
                                _stagger(1, _buildStatusBanner()),
                                if (status == 0) ...[
                                  _gap(14),
                                  _stagger(2, _buildCancelCard()),
                                ],
                                if (status == 4) ...[
                                  _gap(14),
                                  _stagger(2, _buildCompletedCard()),
                                ],
                                _gap(14),
                                _stagger(3, _buildLawyerCard()),
                                _gap(14),
                                _stagger(4, _buildInfoCard()),
                                _gap(14),
                                _stagger(5, _buildWorkspaceCard()),
                                _gap(14),
                                _stagger(6, _buildNoteCard()),
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
                        child: _stagger(8, _buildBottomCTA()),
                      )
                    ],
                  ),
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
                  Positioned(
                    right: -5,
                    top: 15,
                    child: Container(
                      width: 140,
                      height: 140,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
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
            Positioned(
              left: 20,
              right: 20,
              bottom: 50,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    'appointmentInfo.title'.tr(),
                    style: const TextStyle(
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
          borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(32),
            bottomRight: Radius.circular(32),
          ),
        ),
        child: Container(
          height: 70,
          padding: const EdgeInsets.symmetric(horizontal: 15),
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
                      'appointmentInfo.title'.tr(),
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
              // _circleBtn(
              //   icon: Icons.more_horiz_rounded,
              //   color: showTitle ? Colors.black : _ink,
              //   bg: showTitle ? Color(0xFFFAFAFA) : Colors.white,
              //   onTap: _showMenu,
              // ),
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
      _pill(
          Icons.calendar_today_rounded,
          'appointmentInfo.appointmentDate'.tr(),
          appointmentModel['caseDate']?.toString() ?? '-',
          _blue),
      const SizedBox(width: 10),
      _pill(
          Icons.schedule_rounded,
          'appointmentInfo.appointmentTime'.tr(),
          "${appointmentModel['startTime'] ?? ''} - ${appointmentModel['endTime'] ?? ''}",
          _green),
      const SizedBox(width: 10),
      _pill(_caseTypeIcon, 'appointmentInfo.caseType'.tr(), _caseTypeLabel,
          _caseTypeColor),
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
                  child: lawyerModel['imageUrl'] != null
                      ? Image.network(lawyerModel['imageUrl'] as String,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              _avatarText(lawyerColor))
                      : _avatarText(lawyerColor),
                ),
              ),
              if (lawyerModel['isActive'] ?? true)
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
                    '${lawyerModel['firstName']} ${lawyerModel['lastName']}',
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
                      // lawyerModel['title'] as String,
                      'ทนายความ',
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
                      (i) => const Icon(
                        Icons.star_rounded,
                        size: 13,
                        color: Color(0xFFFFC107),
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text('${lawyerModel['rateAverage']}',
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: _ink)),
                    const SizedBox(width: 4),
                    Text(
                      '(${lawyerModel['review'].length})',
                      style: TextStyle(
                        fontSize: 10,
                        color: _slate.withOpacity(0.6),
                      ),
                    ),
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

  void showReviewDialog(BuildContext context) {
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
                  child:
                      // submitted
                      //     ? _buildSuccessContent(context)
                      //     :
                      _buildFormContent(
                    context,
                    rating,
                    commentController,
                    (value) => setState(() => rating = value),
                    () => setState(
                      () {
                        // print(commentController.text);
                        createReview(commentController.text, rating);
                        print(rating);
                        submitted = true;
                      },
                    ),
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
                child: _buildFormCancelContent(
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

  Widget _buildFormCancelContent(
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

  Widget _avatarText(Color color) => Center(
        child: Text(
          appointmentModel['lawyerAvatar'] as String,
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
          _cardTitle(Icons.info_outline_rounded, 'appointmentInfo.title'.tr()),
          const SizedBox(height: 14),
          _infoRow(
            'appointmentInfo.caseType'.tr(),
            _caseTypeLabel,
            accent: true,
            valueColor: _caseTypeColor,
          ),
          _divider(),
          _infoRow('appointmentInfo.topic'.tr(),
              appointmentModel['topicTitle']?.toString() ?? ''),
          _divider(),
          _infoRow('appointmentInfo.subTopic'.tr(),
              appointmentModel['subTopicTitle']?.toString() ?? ''),
          _divider(),
          _infoRow('appointmentInfo.serviceType'.tr(),
              'appointmentInfo.videoCall'.tr()),
        ],
      ),
    );
  }

  Widget _infoRow(
    String label,
    String value, {
    bool accent = false,
    Color? valueColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(children: [
        SizedBox(
          width: 110,
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
                  color: valueColor ?? (accent ? _blue : _ink))),
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
          _cardTitle(
              Icons.route_rounded, 'appointmentInfo.appointmentTimeline'.tr()),
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
                child: Text('appointmentInfo.currentStep'.tr(),
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
    final s = [
      'appointmentInfo.requested'.tr(),
      'appointmentInfo.pending'.tr(),
      'appointmentInfo.confirmed'.tr(),
      'appointmentInfo.consulting'.tr(),
      'appointmentInfo.completed'.tr()
    ];
    return s[i];
  }

  Widget _buildWorkspaceCard() {
    final code = appointmentModel['code']?.toString() ?? '';
    if (code.isEmpty) return const SizedBox.shrink();
    return _cardWrap(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _cardTitle(Icons.folder_open_rounded, 'caseWorkspaceTitle'.tr()),
          const SizedBox(height: 10),
          Text(
            'caseWorkspaceSubtitle'.tr(),
            style: const TextStyle(fontSize: 12, color: Color(0xFF8593A8)),
          ),
          const SizedBox(height: 12),
          if (appointmentModel['isPay'] == true ||
              appointmentModel['isPay']?.toString() == 'true')
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Material(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(16),
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () {
                    HapticFeedback.lightImpact();
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ReceiptPage(caseCode: code),
                      ),
                    );
                  },
                  child: Ink(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 15,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF0262EC), Color(0xFF087FF5)],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF0262EC).withOpacity(.22),
                          blurRadius: 14,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(.16),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.white.withOpacity(.18),
                            ),
                          ),
                          child: const Icon(
                            Icons.receipt_long_rounded,
                            color: Colors.white,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'receiptView'.tr(),
                                style: AppTypography.prompt(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'ตรวจสอบรายละเอียดและดาวน์โหลด PDF',
                                style: AppTypography.prompt(
                                  fontSize: 10.5,
                                  color: Colors.white.withOpacity(.76),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(.14),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.arrow_forward_ios_rounded,
                            color: Colors.white,
                            size: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CaseWorkspacePage(caseCode: code),
                  ),
                );
              },
              icon: const Icon(Icons.open_in_new_rounded, size: 18),
              label: Text('caseWorkspaceOpen'.tr()),
            ),
          ),
        ],
      ),
    );
  }

  // ════════════════════════════════════════════════════════
  //  RATING CARD
  // ════════════════════════════════════════════════════════

  Widget _buildRatingCard() {
    final r = (appointmentModel['rating'] as num).toDouble();
    return _cardWrap(
      child: Column(children: [
        _cardTitle(Icons.star_outline_rounded, 'appointmentInfo.rating'.tr()),
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
                  ? 'appointmentInfo.Excellent'.tr()
                  : r >= 3.5
                      ? 'appointmentInfo.Good'.tr()
                      : 'appointmentInfo.Normal'.tr(),
              style: const TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w700, color: _ink),
            ),
          ]),
        ]),
      ]),
    );
  }

  // ════════════════════════════════════════════════════════
  //  STATUS BANNER
  // ════════════════════════════════════════════════════════

  Widget _buildStatusBanner() {
    final color = _statusBannerColor;
    return _cardWrap(
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              isCancelled
                  ? Icons.cancel_outlined
                  : isDone
                      ? Icons.task_alt_rounded
                      : isActive
                          ? Icons.headset_mic_rounded
                          : Icons.info_outline_rounded,
              color: color,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'สถานะนัดหมาย',
                  style: TextStyle(
                    fontSize: 11,
                    color: _slate.withOpacity(0.8),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  _statusLabel,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: color,
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
  //  COMPLETED CARD
  // ════════════════════════════════════════════════════════

  Widget _buildCompletedCard() {
    return _cardWrap(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _cardTitle(Icons.task_alt_rounded, 'รายละเอียดการปรึกษา'),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F3FF),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFDDD6FE)),
            ),
            child: const Row(
              children: [
                Icon(Icons.check_circle_outline_rounded,
                    size: 16, color: Color(0xFF7C3AED)),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'การปรึกษานี้เสร็จสิ้นแล้ว',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF6D28D9),
                    ),
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
  //  CANCEL CARD
  // ════════════════════════════════════════════════════════

  Widget _buildCancelCard() {
    final reason = appointmentModel['reasonCancel']?.toString().trim() ?? '';
    final cancelDate = appointmentModel['cancelDate']?.toString() ?? '-';
    final cancelTime = appointmentModel['cancelTime']?.toString() ?? '-';

    return _cardWrap(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _cardTitle(Icons.cancel_outlined, 'รายละเอียดการยกเลิก'),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF1F2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFFECDD3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline_rounded,
                    size: 16, color: Color(0xFFDC2626)),
                const SizedBox(width: 8),
                Text(
                  'นัดหมายนี้ถูกยกเลิกแล้ว',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Colors.red.shade700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          _infoRow('วันที่ยกเลิก', cancelDate),
          _divider(),
          _infoRow('เวลาที่ยกเลิก', cancelTime),
          _divider(),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'เหตุผลการยกเลิก',
                  style: TextStyle(
                    fontSize: 12,
                    color: _slate,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8F9FB),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    reason.isNotEmpty ? reason : '-',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[700],
                      height: 1.6,
                    ),
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
  //  NOTE CARD
  // ════════════════════════════════════════════════════════

  Widget _buildNoteCard() {
    return _cardWrap(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _cardTitle(Icons.sticky_note_2_outlined, 'save'.tr()),
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
            child: Text("appointmentInfo.preparation_guide".tr(),
                style:
                    const TextStyle(fontSize: 13, color: _slate, height: 1.65)),
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
      child: status == 4
          ? Row(
              children: [
                Expanded(
                  child: _ctaBtn(
                    label: 'appointmentInfo.newAppointment'.tr(),
                    icon: Icons.add_rounded,
                    color: _blue,
                    filled: false,
                    onTap: _openNewAppointment,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: appointmentModel['isReview'] == false
                      ? _ctaBtn(
                          label: 'appointmentInfo.rateAppointment'.tr(),
                          icon: Icons.star_rounded,
                          color: _amber,
                          filled: true,
                          onTap: _openReviewPage,
                        )
                      : _ctaBtn(
                          label: 'returns.returnHome'.tr(),
                          icon: Icons.home,
                          color: Theme.of(context).primaryColor,
                          filled: true,
                          onTap: _goHome,
                        ),
                ),
              ],
            )
          : status == 0
              ? _ctaBtn(
                  label: 'appointmentInfo.newAppointment'.tr(),
                  icon: Icons.add_rounded,
                  color: _blue,
                  filled: true,
                  fullWidth: true,
                  onTap: _openNewAppointment,
                )
              : status == 3
                  ? Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        GestureDetector(
                          onTap: () {
                            _onTapConversation();
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            height: 52,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFF0262EC),
                                    Color(0xFF0485FF)
                                  ]),
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: [
                                BoxShadow(
                                    color:
                                        Color(0xFF0262EC).withOpacity(0.3),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4))
                              ],
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.video_call_rounded,
                                    color: Colors.white, size: 20),
                                const SizedBox(width: 8),
                                Text('call_room.consultingRoom'.tr(),
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 15)),
                              ],
                            ),
                          ),
                        ),
                        if ((appointmentModel['cancelReviewStatus']
                                    ?.toString() ??
                                '') ==
                            'pending') ...[
                          const SizedBox(height: 10),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 10),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFF7ED),
                              borderRadius: BorderRadius.circular(12),
                              border:
                                  Border.all(color: const Color(0xFFFDBA74)),
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
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
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
                  : Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        GestureDetector(
                          onTap: () {
                            DialogService.showConfirmRejectJob(
                              context,
                              title: "ปฏิเสธคำขอ",
                              message: "คุณยืนยันที่จะปฏิเสธคำขอนี้ใช่หรือไม่",
                              onConfirm: () {
                                showReasonCancelDialog(context);
                              },
                            );
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            height: 50,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: Color(0xFFFFEBEE),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Text(
                                'appointmentInfo.cancelAppointment'.tr(),
                                style: const TextStyle(
                                    color: Color(0xFFC62828),
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13)),
                          ),
                        ),
                      ],
                    ),
    );
  }

  void _openNewAppointment() {
    HapticFeedback.lightImpact();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AppAppointment(
          lawyer: lawyerModel,
        ),
      ),
    );
  }

  void _openReviewPage() {
    HapticFeedback.lightImpact();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PostConsultationReviewPage(
          caseCode: appointmentModel['code']?.toString() ?? '',
          lawyerRef: appointmentModel['lawyer']?.toString() ?? '',
          userRef: appointmentModel['userCode']?.toString() ?? '',
          lawyerName:
              '${lawyerModel['firstName'] ?? ''} ${lawyerModel['lastName'] ?? ''}'
                  .trim(),
        ),
      ),
    );
  }

  void _goHome() {
    HapticFeedback.lightImpact();
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => MenuPage()),
      (route) => false,
    );
  }

  void _onTapConversation() async {
    var roomCode;
    // สร้าง roomCode
    List<String> ids = [
      widget.appointment['userCode'],
      widget.appointment['lawyer']
    ]..sort();

    var model = {
      "members": ids,
      "userA": widget.appointment['userCode'],
      "userB": widget.appointment['lawyer'],
      "caseCode": widget.appointment['code'],
    };

    final result = await postObjectData("/m/chat/room/create", model);
    if (result['status'] == 'S') {
      setState(
        () {
          roomCode = result['objectData']['roomCode'];
          print(roomCode);
          // เปิดหน้าแชท
          // Navigator.push(
          //   context,
          //   MaterialPageRoute(
          //     builder: (_) => ChatPage(
          //       roomCode: roomCode,
          //       userId: myUserId,
          //     ),
          //   ),
          // );
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ChatPageUser(
                model: {
                  'name':
                      '${lawyerModel['firstName']} ${lawyerModel['lastName']}',
                  'imageUrl': lawyerModel['imageUrl'],
                  'caseCode': result['objectData']['caseCode'],
                  'active': true,
                  'caseSuccess': false,
                  ...widget.appointment
                },
                roomCode: roomCode,
                userId: UserProfileStore.instance.code,
              ),
            ),
          );
          // .then((_) => _load());
        },
      );
    }
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
          Text('appointmentInfo.cancelAppointmentTitle'.tr(),
              style: const TextStyle(
                  fontSize: 16, fontWeight: FontWeight.w800, color: _ink)),
        ]),
        content: Text(
          'appointmentInfo.cancelAppointment'.tr(),
          style: const TextStyle(fontSize: 13, color: _slate, height: 1.6),
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
                  child: Center(
                    child: Text('cancel'.tr(),
                        style: const TextStyle(
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
                    title: "status.completed".tr(),
                    message: "message_cancel_appointment.success".tr(),
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
                  child: Center(
                    child: Text('confirm'.tr(),
                        style: const TextStyle(
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
      builder: (_) => AppLayout(
        child: Container(
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
                _menuTile(Icons.share_rounded,
                    'appointmentInfo.shareAppointment'.tr(), _blue),
                _menuTile(Icons.picture_as_pdf_rounded,
                    'appointmentInfo.downloadPDF'.tr(), _green),
                _menuTile(Icons.flag_outlined,
                    'appointmentInfo.reportIssue'.tr(), _amber),
                const SizedBox(height: 8),
              ]),
            ),
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

  void goBack() async {
    Navigator.pop(context, false);
  }

  String _ratingLabel(double rating) {
    switch (rating.toInt()) {
      case 1:
        return 'rating_appointment.terrible'.tr();
      case 2:
        return 'rating_appointment.fair'.tr();
      case 3:
        return 'rating_appointment.good'.tr();
      case 4:
        return 'rating_appointment.very_good'.tr();
      case 5:
        return 'rating_appointment.excellent'.tr();
      default:
        return 'rating_appointment.prompt'.tr();
    }
  }

  _buildSuccessContent(BuildContext context) {
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
                          child:
                              FadeTransition(opacity: animation, child: child),
                        ),
                    child: Container(
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
                                  builder: (_) =>
                                      MenuPage()), // หน้า home จริงๆ
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
}
