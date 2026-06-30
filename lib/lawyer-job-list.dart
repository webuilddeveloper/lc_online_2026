import 'dart:convert';

import 'package:LawyerOnline/component/appbar.dart';
import 'package:LawyerOnline/component/dialog_service.dart';
import 'package:LawyerOnline/lawyer-job-details.dart';
import 'package:LawyerOnline/shared/api_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:LawyerOnline/models/lawyer/lawyer_jobs_store.dart';
import 'package:LawyerOnline/models/user_profile_store.dart';
import 'package:LawyerOnline/chat/chat_page_lawyer.dart';
import 'package:LawyerOnline/repositories/booking_case_repository.dart';
import 'package:LawyerOnline/repositories/lawyer_appointment_repository.dart';
import 'package:LawyerOnline/services/case_request_service.dart';
import 'package:LawyerOnline/shared/responsive/app_layout.dart';
import 'package:LawyerOnline/shared/responsive/res_layout.dart';
// ══════════════════════════════════════════════════════════
//  LawyerJobListPage — รายการคำขอจากลูกความ (ฝั่งทนาย)
//  เรียกใช้: Navigator.push(context, MaterialPageRoute(
//    builder: (_) => const LawyerJobListPage()));
// ══════════════════════════════════════════════════════════

class LawyerJobListPage extends StatefulWidget {
  const LawyerJobListPage({super.key});

  @override
  State<LawyerJobListPage> createState() => _LawyerJobListPageState();
}

class _LawyerJobListPageState extends State<LawyerJobListPage>
    with TickerProviderStateMixin {
  String _activeTab = 'all';
  late AnimationController _entryCtrl;
  final LawyerAppointmentRepository _appointmentRepository =
      const ApiLawyerAppointmentRepository();
  final BookingCaseRepository _caseRepository =
      const ApiBookingCaseRepository();
  List<Map<String, dynamic>> _apiJobs = const [];
  List<Map<String, dynamic>> _caseRequestJobs = const [];
  bool _isLoadingApiJobs = false;

  static const _kPrimary = Color(0xFF0262EC);

  List<Map<String, dynamic>> get _jobs => _mergeJobs(
        _mergeJobs(_apiJobs, _caseRequestJobs),
        LawyerJobsStore.instance.jobsForLawyer(UserProfileStore.instance.code),
      );

  bool _isBooking(Map<String, dynamic> job) =>
      (job['jobSource'] ?? 'urgent') == 'booking';

  bool _isUrgent(Map<String, dynamic> job) => !_isBooking(job);

  @override
  void initState() {
    super.initState();
    LawyerJobsStore.instance.addListener(_onJobUpdated);
    _entryCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..forward();
    _loadApiJobs();
  }

  @override
  void dispose() {
    LawyerJobsStore.instance.removeListener(_onJobUpdated);
    _entryCtrl.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> get _filtered {
    switch (_activeTab) {
      case 'pending':
        return _jobs.where((j) => j['status'] == 'pending').toList();
      case 'in_session':
        return _jobs.where((j) => j['status'] == 'in_session').toList();
      case 'done':
        return _jobs
            .where((j) => j['status'] == 'done' || j['status'] == 'rejected')
            .toList();
      case 'all':
      default:
        const order = {
          'in_session': 0,
          'accepted': 1,
          'confirmed': 2,
          'pending': 3,
          'rejected': 4,
          'done': 5
        };
        return [..._jobs]..sort((a, b) =>
            (order[a['status']] ?? 9).compareTo(order[b['status']] ?? 9));
    }
  }

  // refresh list หลังจาก detail page pop กลับมา
  void _onJobUpdated() {
    if (!mounted) return;
    setState(() {});
    _loadApiJobs();
  }

  Future<void> _loadApiJobs() async {
    final lawyerCode = UserProfileStore.instance.code.trim();
    if (lawyerCode.isEmpty || _isLoadingApiJobs) return;
    _isLoadingApiJobs = true;
    try {
      final snapshot =
          await _appointmentRepository.readScheduleForLawyer(lawyerCode);
      final caseReqService = CaseRequestService();
      final caseRequests = await caseReqService.getLawyerPendingRequests();
      if (!mounted) return;
      setState(() {
        _apiJobs = snapshot.bookingJobs;
        _caseRequestJobs = caseRequests
            .map(CaseRequestService.jobFromCaseRequest)
            .toList(growable: false);
      });
      LawyerJobsStore.instance.replaceCaseRequestJobs(_caseRequestJobs);
    } finally {
      _isLoadingApiJobs = false;
    }
  }

  List<Map<String, dynamic>> _mergeJobs(
    List<Map<String, dynamic>> apiJobs,
    List<Map<String, dynamic>> localJobs,
  ) {
    final byId = <String, Map<String, dynamic>>{};
    for (final job in apiJobs) {
      final id = job['id']?.toString() ?? '';
      if (id.isNotEmpty) byId[id] = Map<String, dynamic>.from(job);
    }
    for (final job in localJobs) {
      final id = job['id']?.toString() ?? '';
      if (id.isNotEmpty) byId[id] = Map<String, dynamic>.from(job);
    }
    return byId.values.toList(growable: false);
  }

  Future<void> _setJobStatus(Map<String, dynamic> job, String status) async {
    final jobId = job['id']?.toString() ?? '';
    final isApiCase = job['isApiCase'] == true;
    final isBooking = _isBooking(job);

    // if (!isApiCase) {
    //   if (isBooking && status == 'confirmed') {
    //     LawyerJobsStore.instance.confirmBooking(jobId);
    //   } else if (status == 'accepted') {
    //     LawyerJobsStore.instance.acceptJob(jobId);
    //   } else {
    //     LawyerJobsStore.instance.updateStatus(jobId, status);
    //   }
    //   return;
    // }

    final updatedJob = Map<String, dynamic>.from(job)..['status'] = status;
    if (mounted) {
      setState(() {
        _apiJobs = _apiJobs.map((item) {
          return item['id'] == jobId ? updatedJob : item;
        }).toList(growable: false);
      });
    }

    final rawCase = job['rawCase'];
    final payload = rawCase is Map
        ? Map<String, dynamic>.from(rawCase)
        : <String, dynamic>{'code': job['caseCode'] ?? jobId};
    payload['caseStatus'] = _caseStatusFromJobStatus(status);
    if ((payload['code']?.toString() ?? '').isEmpty && jobId.isNotEmpty) {
      payload['code'] = jobId;
    }

    try {
      await _caseRepository.updateCase(payload);
      _loadApiJobs();
    } catch (_) {
      if (mounted) _showSnackbar('เกิดข้อผิดพลาด กรุณาลองใหม่', false);
    }
  }

  int _caseStatusFromJobStatus(String status) {
    switch (status) {
      case 'confirmed':
        return 2;
      case 'in_session':
        return 3;
      case 'done':
        return 4;
      case 'rejected':
        return 5;
      default:
        return 1;
    }
  }

  void _showSnackbar(String msg, bool success) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor:
            success ? const Color(0xFF34C759) : const Color(0xFFEF4444),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pending = _jobs.where((j) => j['status'] == 'pending').length;
    final filtered = _filtered;
    final isDesktop = ResponsiveLayout.isDesktop(context);

    return Scaffold(
      backgroundColor:
          isDesktop ? const Color(0xFFE9F2F9) : const Color(0xFFF2F6FF),
      appBar: isDesktop
          ? null
          : appBar(
              title: 'คำขอจากลูกความ',
              backBtn: true,
              rightBtn: false,
              backAction: () => Navigator.pop(context),
              rightAction: () {},
            ),
      body: AppLayout(
        child: Container(
          decoration: isDesktop
              ? BoxDecoration(
                  color: const Color(0xFFF2F6FF),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                )
              : null,
          child: Column(
            children: [
              if (isDesktop)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () {
                          HapticFeedback.lightImpact();
                          Navigator.pop(context);
                        },
                        child: Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            border: Border.all(
                                width: 1, color: const Color(0xFFDBDBDB)),
                          ),
                          child: const Icon(Icons.arrow_back_ios_new_rounded,
                              size: 18, color: Color(0xFF0F172A)),
                        ),
                      ),
                      const SizedBox(width: 14),
                      const Text(
                        'คำขอจากลูกความ',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                    ],
                  ),
                ),
              // ── Pending alert ──────────────────────────────
              if (pending > 0)
                Container(
                  margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF0262EC), Color(0xFF0099FF)],
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.notifications_active_rounded,
                          color: Colors.white, size: 18),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'มี $pending คำขอที่รอการตอบรับ',
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 13),
                          ),
                          Text(
                            'กรุณาตอบรับด่วน',
                            style: TextStyle(
                                color: Colors.white.withOpacity(0.8),
                                fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                  ]),
                ),

              // ── Tab bar ────────────────────────────────────
              _buildTabBar(),

              // ── List ───────────────────────────────────────
              Expanded(
                child: filtered.isEmpty
                    ? _buildEmpty()
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                        itemCount: filtered.length,
                        itemBuilder: (_, i) {
                          final item = filtered[i];
                          final delay = (i * 0.1).clamp(0.0, 0.6);
                          return AnimatedBuilder(
                            animation: _entryCtrl,
                            builder: (_, child) {
                              final t = Curves.easeOutCubic.transform(
                                ((_entryCtrl.value - delay) / (1 - delay))
                                    .clamp(0.0, 1.0),
                              );
                              return Opacity(
                                opacity: t,
                                child: Transform.translate(
                                    offset: Offset(0, 20 * (1 - t)),
                                    child: child),
                              );
                            },
                            child: _buildJobCard(item),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ════════════════════════════════════════════════════════
  //  Tab Bar
  // ════════════════════════════════════════════════════════

  Widget _buildTabBar() {
    final tabs = [
      {
        'key': 'all',
        'label': 'ทั้งหมด',
        'count': _jobs.length,
        'color': _kPrimary,
      },
      {
        'key': 'pending',
        'label': 'รอตอบรับ',
        'count': _jobs.where((j) => j['status'] == 'pending').length,
        'color': const Color(0xFFD97706),
      },
      {
        'key': 'in_session',
        'label': 'กำลังปรึกษา',
        'count': _jobs.where((j) => j['status'] == 'in_session').length,
        'color': const Color(0xFF059669),
      },
      {
        'key': 'done',
        'label': 'เสร็จสิ้น',
        'count': _jobs
            .where((j) => j['status'] == 'done' || j['status'] == 'rejected')
            .length,
        'color': const Color(0xFF6D28D9),
      },
    ];

    final tabWidth = (MediaQuery.of(context).size.width - 32) / tabs.length;

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      child: Row(
        children: tabs.map((t) {
          final isActive = _activeTab == t['key'];
          final color = t['color'] as Color;
          return SizedBox(
            width: tabWidth,
            child: GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() {
                  _activeTab = t['key'] as String;
                  _entryCtrl
                    ..reset()
                    ..forward();
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: isActive ? color : Colors.transparent,
                      width: 2.5,
                    ),
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      t['label'] as String,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight:
                            isActive ? FontWeight.w700 : FontWeight.w500,
                        color: isActive ? color : Colors.grey[500],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: isActive ? color : Colors.grey[200],
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${t['count']}',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: isActive ? Colors.white : Colors.grey[500],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
  // ════════════════════════════════════════════════════════
  //  Job Card
  // ════════════════════════════════════════════════════════

  Widget _buildJobCard(dynamic job) {
    final status = job['status'] as String;
    final clientColor = Color(job['clientColor'] as int);
    final isPending = status == 'pending';
    final isAccepted = status == 'in_session';
    final isBooking = _isBooking(job);
    final isBookingConfirmed = isBooking && status == 'confirmed';

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => LawyerJobDetailPage(
              job: job,
              onAccept: isPending
                  ? () {
                      _setJobStatus(
                        job,
                        isBooking ? 'confirmed' : 'accepted',
                      );
                    }
                  : null,
              onReject: isPending
                  ? () {
                      _setJobStatus(job, 'rejected');
                    }
                  : null,
            ),
          ),
        ).then((_) => _onJobUpdated());
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isPending
                ? const Color(0xFFD97706).withOpacity(0.35)
                : const Color(0xFFE2E8F4),
            width: isPending ? 1.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isPending
                  ? const Color(0xFFD97706).withOpacity(0.08)
                  : Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          children: [
            // ── Header ────────────────────────────────────
            Padding(
              padding: const EdgeInsets.all(14),
              child: Row(children: [
                // Client avatar
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [clientColor, clientColor.withOpacity(0.7)],
                    ),
                    boxShadow: [
                      BoxShadow(
                          color: clientColor.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2))
                    ],
                  ),
                  child: Center(
                    child: Text(
                      job['clientAvatar'] as String,
                      style: const TextStyle(
                          fontSize: 16,
                          color: Colors.white,
                          fontWeight: FontWeight.w800),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Expanded(
                          child: Text(
                            job['clientName'] as String,
                            style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF1A2340)),
                          ),
                        ),
                        _statusBadge(status),
                      ]),
                      const SizedBox(height: 2),
                      Text(
                        job['requestedAt'] as String,
                        style: TextStyle(fontSize: 10, color: Colors.grey[400]),
                      ),
                    ],
                  ),
                ),
              ]),
            ),

            const Divider(height: 1, color: Color(0xFFF0F4F8)),

            // ── Detail ────────────────────────────────────
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(children: [
                // Topic
                Row(children: [
                  Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: clientColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.label_outline_rounded,
                        size: 14, color: clientColor),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(job['topic'] as String,
                              style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF1A2340))),
                          Text(job['subTopic'] as String,
                              style: TextStyle(
                                  fontSize: 10, color: Colors.grey[500])),
                        ]),
                  ),
                  // Budget
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _kPrimary.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      job['budget'] as String,
                      style: const TextStyle(
                          fontSize: 11,
                          color: _kPrimary,
                          fontWeight: FontWeight.w700),
                    ),
                  ),
                ]),
                const SizedBox(height: 10),
                // Detail preview
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8F9FB),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    job['detail'] as String,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontSize: 11, color: Colors.grey[600], height: 1.5),
                  ),
                ),

                // Date / time (ถ้ามี)
                if ((job['date'] as String).isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Row(children: [
                    Expanded(
                        child: _chip(Icons.calendar_today_rounded,
                            job['date'] as String)),
                    const SizedBox(width: 8),
                    Expanded(
                        child: _chip(
                            Icons.access_time_rounded, job['time'] as String)),
                  ]),
                ],
              ]),
            ),

            // ── Action buttons (pending only) ─────────────
            // if (isPending) ...[
            //   const Divider(height: 1, color: Color(0xFFF0F4F8)),
            //   Padding(
            //     padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
            //     child: Row(children: [
            //       // Reject
            //       Expanded(
            //         child: GestureDetector(
            //           onTap: () {
            //             DialogService.showConfirmRejectJob(
            //               context,
            //               title: "ปฏิเสธคำขอ",
            //               message: "คุณยืนยันที่จะปฏิเสธคำขอนี้ใช่หรือไม่",
            //               onConfirm: () {
            //                 _setJobStatus(job, 'rejected');
            //                 if (mounted) {
            //                   setState(() {});
            //                   _showSnackbar('ปฏิเสธคำขอแล้ว!', false);
            //                 }
            //               },
            //             );
            //           },
            //           child: Container(
            //             height: 42,
            //             decoration: BoxDecoration(
            //               color: const Color(0xFFFFF2F2),
            //               borderRadius: BorderRadius.circular(12),
            //               border: Border.all(
            //                   color: const Color(0xFFEF4444).withOpacity(0.3)),
            //             ),
            //             child: Row(
            //               mainAxisAlignment: MainAxisAlignment.center,
            //               children: [
            //                 Icon(Icons.close_rounded,
            //                     color: Color(0xFFEF4444), size: 16),
            //                 SizedBox(width: 6),
            //                 Text('ปฏิเสธ',
            //                     style: TextStyle(
            //                         color: Color(0xFFEF4444),
            //                         fontWeight: FontWeight.w700,
            //                         fontSize: 13)),
            //               ],
            //             ),
            //           ),
            //         ),
            //       ),
            //       const SizedBox(width: 10),
            //       // Accept
            //       Expanded(
            //         flex: 2,
            //         child: GestureDetector(
            //           onTap: () {
            //             DialogService.showConfirmAcceptJob(
            //               context,
            //               title: "รับงาน",
            //               message: "คุณยืนยันที่จะรับคำขอนี้ใช่หรือไม่",
            //               onConfirm: () {
            //                 if (isBooking) {
            //                   _setJobStatus(job, 'confirmed');
            //                 } else {
            //                   _setJobStatus(job, 'accepted');
            //                 }
            //                 if (mounted) {
            //                   setState(() {});
            //                   _showSnackbar('รับงานสำเร็จแล้ว!', true);
            //                 }
            //               },
            //             );
            //           },
            //           child: Container(
            //             height: 42,
            //             decoration: BoxDecoration(
            //               gradient: const LinearGradient(
            //                 colors: [Color(0xFF0262EC), Color(0xFF0099FF)],
            //               ),
            //               borderRadius: BorderRadius.circular(12),
            //               boxShadow: [
            //                 BoxShadow(
            //                     color: _kPrimary.withOpacity(0.35),
            //                     blurRadius: 10,
            //                     offset: const Offset(0, 3))
            //               ],
            //             ),
            //             child: Row(
            //               mainAxisAlignment: MainAxisAlignment.center,
            //               children: [
            //                 const Icon(Icons.check_rounded,
            //                     color: Colors.white, size: 16),
            //                 const SizedBox(width: 6),
            //                 Text('รับงาน',
            //                     style: TextStyle(
            //                         color: Colors.white,
            //                         fontWeight: FontWeight.w700,
            //                         fontSize: 13)),
            //               ],
            //             ),
            //           ),
            //         ),
            //       ),
            //     ]),
            //   ),
            // ],

            // ── Accepted — chat button ────────────────────
            if (isAccepted) ...[
              const Divider(height: 1, color: Color(0xFFF0F4F8)),
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
                child: GestureDetector(
                  onTap: () => {
                    _onTapConversation(job),

                    // Navigator.push(
                    //   context,
                    //   MaterialPageRoute(
                    //     builder: (_) =>
                    //         ChatPageLawyer(
                    //           // jobId: job['id'] as String?,
                    //          model: {
                    //       'id': job['id'],
                    //       'jobId': job['id'],
                    //       'jobSource': job['jobSource'] ?? 'urgent',
                    //       'jobStatus': job['status'],
                    //       'name': job['clientName'] ?? '',
                    //       'avatar': job['clientAvatar'] ?? '',
                    //       'imageUrl': '', // เพิ่ม default imageUrl
                    //       'active': true, // เพิ่ม default active status
                    //       'caseSuccess':
                    //           job['status'] == 'done', // เพิ่ม caseSuccess flag
                    //       'clientColor': job['clientColor'], // เพิ่มสีถ้าต้องการ
                    //     }),
                    //   ),
                    // ),
                  },
                  child: Container(
                    height: 42,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF0262EC), Color(0xFF0099FF)],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                            color: _kPrimary.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 3))
                      ],
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.headset_mic_rounded,
                            color: Colors.white, size: 16),
                        SizedBox(width: 8),
                        Text('เริ่มปรึกษา / แชทกับลูกความ',
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 13)),
                      ],
                    ),
                  ),
                ),
              ),
            ],
            // if (isBookingConfirmed) ...[
            //   const Divider(height: 1, color: Color(0xFFF0F4F8)),
            //   Padding(
            //     padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
            //     child: Container(
            //       width: double.infinity,
            //       padding:
            //           const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            //       decoration: BoxDecoration(
            //         color: const Color(0xFFF8F4FF),
            //         borderRadius: BorderRadius.circular(12),
            //         border: Border.all(color: const Color(0xFF7C3AED)),
            //       ),
            //       child: const Row(
            //         mainAxisAlignment: MainAxisAlignment.center,
            //         children: [
            //           Icon(Icons.lock_clock_rounded,
            //               color: Color(0xFF7C3AED), size: 16),
            //           SizedBox(width: 8),
            //           Text('รอถึงวันนัดหมายเพื่อเริ่มปรึกษา',
            //               style: TextStyle(
            //                   color: Color(0xFF7C3AED),
            //                   fontWeight: FontWeight.w700,
            //                   fontSize: 13)),
            //         ],
            //       ),
            //     ),
            //   ),
            // ],
          ],
        ),
      ),
    );
  }

  void _onTapConversation(dynamic job) async {
    setState(() {
      // appointmentList = param['objectData'];
      // _lawyerAppointments = param['objectData'];
      // _isLoadingAppointments = false;
    });
    String myUserId = UserProfileStore.instance.code;
    dynamic caseModel = {};

    await postDio("${server}/m/case/read", {"code": job['code']}).then(
      (paramJob) => {
        setState(
          () {
            caseModel = paramJob['objectData'][0];
          },
        ),
      },
    );

    List<String> ids = [caseModel['userCode'], caseModel['lawyer']]..sort();
    var model = {
      "members": ids,
      "userA": caseModel['userCode'],
      "userB": caseModel['lawyer'],
      "caseCode": caseModel['code'],
    };
    var roomCode;

    print('==============123. ${job}');
    print('==============123. ${caseModel}');
    await postObjectData("/m/chat/room/create", model).then(
      (result) async => {
        if (result['status'] == 'S')
          {
            setState(() {
              roomCode = result['objectData']['roomCode'];
            }),
            await postObjectData("/m/case/update",
                {"code": caseModel['code'], "messageRoomCode": roomCode}).then(
              (res) => {
                // Navigator.push(
                //   context,
                //   MaterialPageRoute(
                //       builder: (_) => ChatPageLawyer(
                //             model: {
                //               'code': widget.model['code'],
                //               'name':
                //                   caseModel['lawyerName'],
                //               'avatar': userModel['imageUrl'],
                //               // 'clientColor': conv.clientColor,
                //               'active': true,
                //               'caseSuccess': false,
                //             },
                //             // jobId: conv.id,
                //             roomCode: roomCode,
                //             userId: myUserId,
                //           )),
                // ),
              },
            ),
          }
      },
    );
  }

  Widget _statusBadge(String status) {
    final configs = {
      'pending': (
        const Color(0xFFD97706),
        const Color(0xFFFFF8EC),
        Icons.hourglass_top_rounded,
        'รอตอบรับ'
      ),
      'accepted': (
        _kPrimary,
        const Color(0xFFEEF4FF),
        Icons.check_circle_outline_rounded,
        'รับแล้ว'
      ),
      'confirmed': (
        const Color(0xFF7C3AED),
        const Color(0xFFF8F4FF),
        Icons.event_available_rounded,
        'ยืนยันนัดแล้ว'
      ),
      'in_session': (
        const Color(0xFF059669),
        const Color(0xFFECFDF5),
        Icons.headset_mic_rounded,
        'กำลังปรึกษา'
      ),
      'rejected': (
        const Color(0xFFEF4444),
        const Color(0xFFFFF2F2),
        Icons.cancel_outlined,
        'ปฏิเสธ'
      ),
      'done': (
        const Color(0xFF6D28D9),
        const Color(0xFFF3EEFF),
        Icons.task_alt_rounded,
        'เสร็จสิ้น'
      ),
    };
    final cfg = configs[status] ?? configs['pending']!;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: cfg.$2,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(cfg.$3, size: 11, color: cfg.$1),
        const SizedBox(width: 4),
        Text(cfg.$4,
            style: TextStyle(
                fontSize: 10, color: cfg.$1, fontWeight: FontWeight.w700)),
      ]),
    );
  }

  Widget _chip(IconData icon, String label) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: const Color(0xFFF5F7FA),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFE2E8F4)),
        ),
        child: Row(children: [
          Icon(icon, size: 11, color: _kPrimary),
          const SizedBox(width: 5),
          Expanded(
            child: Text(label,
                style: const TextStyle(fontSize: 11, color: Color(0xFF1A2340)),
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
          ),
        ]),
      );

  Widget _buildEmpty() => Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 72,
            height: 72,
            decoration: const BoxDecoration(
                color: Color(0xFFEEF2F5), shape: BoxShape.circle),
            child:
                Icon(Icons.inbox_outlined, color: Colors.grey[400], size: 32),
          ),
          const SizedBox(height: 14),
          Text('ไม่มีคำขอในหมวดนี้',
              style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 15,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          Text('คำขอจากลูกความจะปรากฏที่นี่',
              style: TextStyle(color: Colors.grey[400], fontSize: 12)),
        ]),
      );
}
