import 'package:LawyerOnline/component/appbar.dart';
import 'package:LawyerOnline/component/dialog_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:LawyerOnline/models/lawyer/lawyer_jobs_store.dart';
import 'package:LawyerOnline/models/user_profile_store.dart';
import 'package:LawyerOnline/chat/chat_page_lawyer.dart';
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

  static const _kPrimary = Color(0xFF0262EC);

  List<Map<String, dynamic>> get _jobs =>
      LawyerJobsStore.instance.jobsForLawyer(UserProfileStore.instance.code);

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
        return _jobs
            .where((j) => _isUrgent(j) && j['status'] == 'pending')
            .toList();
      case 'accepted':
        return _jobs
            .where((j) => _isUrgent(j) && j['status'] == 'accepted')
            .toList();
      case 'booking':
        return _jobs
            .where((j) =>
                _isBooking(j) &&
                (j['status'] == 'pending' ||
                    j['status'] == 'confirmed' ||
                    j['status'] == 'in_session'))
            .toList();
      case 'done':
        return _jobs
            .where((j) => j['status'] == 'done' || j['status'] == 'rejected')
            .toList();
      case 'all':
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
      default:
        const orderDef = {
          'in_session': 0,
          'accepted': 1,
          'confirmed': 2,
          'pending': 3,
          'rejected': 4,
          'done': 5
        };
        return [..._jobs]..sort((a, b) =>
            (orderDef[a['status']] ?? 9).compareTo(orderDef[b['status']] ?? 9));
    }
  }

  // refresh list หลังจาก detail page pop กลับมา
  void _onJobUpdated() {
    if (!mounted) return;
    setState(() {});
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
        'count':
            _jobs.where((j) => _isUrgent(j) && j['status'] == 'pending').length,
        'color': const Color(0xFFD97706),
      },
      {
        'key': 'accepted',
        'label': 'รับแล้ว',
        'count': _jobs
            .where((j) => _isUrgent(j) && j['status'] == 'accepted')
            .length,
        'color': const Color.fromARGB(255, 2, 156, 23),
      },
      {
        'key': 'booking',
        'label': 'นัดหมาย',
        'count': _jobs
            .where((j) =>
                _isBooking(j) &&
                (j['status'] == 'pending' ||
                    j['status'] == 'confirmed' ||
                    j['status'] == 'in_session'))
            .length,
        'color': const Color(0xFF7C3AED),
      },
      {
        'key': 'done',
        'label': 'ปิดเคส',
        'count': _jobs
            .where((j) => j['status'] == 'done' || j['status'] == 'rejected')
            .length,
        'color': Colors.grey,
      },
    ];

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      child: Row(
        children: tabs.map((t) {
          final isActive = _activeTab == t['key'];
          final color = t['color'] as Color;
          return Expanded(
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
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      t['label'] as String,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight:
                            isActive ? FontWeight.w700 : FontWeight.w500,
                        color: isActive ? color : Colors.grey[500],
                      ),
                    ),
                    const SizedBox(width: 5),
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

  Widget _buildJobCard(Map<String, dynamic> job) {
    final status = job['status'] as String;
    final clientColor = Color(job['clientColor'] as int);
    final isPending = status == 'pending';
    final isAccepted = status == 'accepted' || status == 'in_session';
    final isBooking = _isBooking(job);
    final isBookingConfirmed = isBooking && status == 'confirmed';

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => LawyerJobDetailPage(
              job: job,
              onAccept: isPending ? () {} : null,
              onReject: isPending ? () {} : null,
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
            if (isPending) ...[
              const Divider(height: 1, color: Color(0xFFF0F4F8)),
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
                child: Row(children: [
                  // Reject
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        DialogService.showConfirmRejectJob(
                          context,
                          title: "ปฏิเสธคำขอ",
                          message: "คุณยืนยันที่จะปฏิเสธคำขอนี้ใช่หรือไม่",
                          onConfirm: () {
                            LawyerJobsStore.instance
                                .rejectJob(job['id'] as String);
                            if (mounted) {
                              setState(() {});
                              _showSnackbar('ปฏิเสธคำขอแล้ว!', false);
                            }
                          },
                        );
                      },
                      child: Container(
                        height: 42,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF2F2),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: const Color(0xFFEF4444).withOpacity(0.3)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.close_rounded,
                                color: Color(0xFFEF4444), size: 16),
                            SizedBox(width: 6),
                            Text('ปฏิเสธ',
                                style: TextStyle(
                                    color: Color(0xFFEF4444),
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13)),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  // Accept
                  Expanded(
                    flex: 2,
                    child: GestureDetector(
                      onTap: () {
                        DialogService.showConfirmAcceptJob(
                          context,
                          title: "รับงาน",
                          message: "คุณยืนยันที่จะรับคำขอนี้ใช่หรือไม่",
                          onConfirm: () {
                            if (isBooking) {
                              LawyerJobsStore.instance
                                  .confirmBooking(job['id'] as String);
                            } else {
                              LawyerJobsStore.instance
                                  .acceptJob(job['id'] as String);
                            }
                            if (mounted) {
                              setState(() {});
                              _showSnackbar('รับงานสำเร็จแล้ว!', true);
                            }
                          },
                        );
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
                                color: _kPrimary.withOpacity(0.35),
                                blurRadius: 10,
                                offset: const Offset(0, 3))
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.check_rounded,
                                color: Colors.white, size: 16),
                            const SizedBox(width: 6),
                            Text('รับงาน',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ]),
              ),
            ],

            // ── Accepted — chat button ────────────────────
            if (isAccepted) ...[
              const Divider(height: 1, color: Color(0xFFF0F4F8)),
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
                child: GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          ChatPageLawyer(jobId: job['id'] as String?, model: {
                        'id': job['id'],
                        'jobId': job['id'],
                        'jobSource': job['jobSource'] ?? 'urgent',
                        'jobStatus': job['status'],
                        'name': job['clientName'] ?? '',
                        'avatar': job['clientAvatar'] ?? '',
                        'imageUrl': '', // เพิ่ม default imageUrl
                        'active': true, // เพิ่ม default active status
                        'caseSuccess':
                            job['status'] == 'done', // เพิ่ม caseSuccess flag
                        'clientColor': job['clientColor'], // เพิ่มสีถ้าต้องการ
                      }),
                    ),
                  ),
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
            if (isBookingConfirmed) ...[
              const Divider(height: 1, color: Color(0xFFF0F4F8)),
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
                child: Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8F4FF),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF7C3AED)),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.lock_clock_rounded,
                          color: Color(0xFF7C3AED), size: 16),
                      SizedBox(width: 8),
                      Text('รอถึงวันนัดหมายเพื่อเริ่มปรึกษา',
                          style: TextStyle(
                              color: Color(0xFF7C3AED),
                              fontWeight: FontWeight.w700,
                              fontSize: 13)),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
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

// ══════════════════════════════════════════════════════════
//  LawyerJobDetailPage — รายละเอียดคำขอ + รับ/ปฏิเสธ
// ══════════════════════════════════════════════════════════

class LawyerJobDetailPage extends StatelessWidget {
  final Map<String, dynamic> job;
  final VoidCallback? onAccept;
  final VoidCallback? onReject;

  const LawyerJobDetailPage({
    super.key,
    required this.job,
    this.onAccept,
    this.onReject,
  });

  static const _kPrimary = Color(0xFF0262EC);

  @override
  Widget build(BuildContext context) {
    final status = job['status'] as String;
    final isPending = status == 'pending';
    final isAccepted = status == 'accepted' || status == 'in_session';
    final clientColor = Color(job['clientColor'] as int);
    final isDesktop = ResponsiveLayout.isDesktop(context);

    return Scaffold(
      backgroundColor:
          isDesktop ? const Color(0xFFE9F2F9) : const Color(0xFFF2F6FF),
      appBar: isDesktop
          ? null
          : appBar(
              title: 'รายละเอียดคำขอ',
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
                        'รายละเอียดคำขอ',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                    ],
                  ),
                ),
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                  child: Column(children: [
                    // ── Status info ─────────────────────────
                    _buildStatusCard(status),
                    const SizedBox(height: 14),

                    // ── Client Card ─────────────────────────
                    _buildClientCard(clientColor),
                    const SizedBox(height: 14),

                    // ── Case Detail ─────────────────────────
                    _buildDetailCard(clientColor),
                    const SizedBox(height: 14),

                    // ── Schedule ────────────────────────────
                    if ((job['date'] as String).isNotEmpty) ...[
                      _buildScheduleCard(),
                      const SizedBox(height: 14),
                    ],
                  ]),
                ),
              ),

              // ── Bottom Buttons ─────────────────────────────
              if (isPending)
                _buildPendingButtons(context)
              else if (isAccepted)
                _buildAcceptedButton(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildClientCard(Color color) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _cardDecor(),
      child: Row(children: [
        Container(
          width: 58,
          height: 58,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(colors: [color, color.withOpacity(0.7)]),
            boxShadow: [
              BoxShadow(
                  color: color.withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 3))
            ],
          ),
          child: Center(
            child: Text(job['clientAvatar'] as String,
                style: const TextStyle(
                    fontSize: 22,
                    color: Colors.white,
                    fontWeight: FontWeight.w800)),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(job['clientName'] as String,
                  style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1A2340))),
              const SizedBox(height: 4),
              Row(children: [
                Icon(Icons.schedule_rounded, size: 12, color: Colors.grey[400]),
                const SizedBox(width: 4),
                Text('ส่งคำขอ ${job['requestedAt']}',
                    style: TextStyle(fontSize: 11, color: Colors.grey[400])),
              ]),
              const SizedBox(height: 6),
              Row(children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _kPrimary.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(job['budget'] as String,
                      style: const TextStyle(
                          fontSize: 12,
                          color: _kPrimary,
                          fontWeight: FontWeight.w700)),
                ),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    const Icon(Icons.videocam_outlined,
                        size: 12, color: Color(0xFF64748B)),
                    const SizedBox(width: 4),
                    Text('วิดีโอคอล',
                        style:
                            TextStyle(fontSize: 11, color: Colors.grey[600])),
                  ]),
                ),
              ]),
            ],
          ),
        ),
      ]),
    );
  }

  Widget _buildDetailCard(Color color) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _cardDecor(),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _sectionTitle(Icons.gavel_rounded, 'รายละเอียดคดี', color),
        const SizedBox(height: 14),
        // Topic
        _infoRow('ประเภทหัวข้อ', job['topic'] as String),
        const Divider(height: 20, color: Color(0xFFF0F4F8)),
        _infoRow('หัวข้อย่อย', job['subTopic'] as String),
        const Divider(height: 20, color: Color(0xFFF0F4F8)),
        // Full detail
        Text('รายละเอียด',
            style: TextStyle(fontSize: 11, color: Colors.grey[400])),
        const SizedBox(height: 6),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFF8F9FB),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            job['detail'] as String,
            style:
                TextStyle(fontSize: 13, color: Colors.grey[700], height: 1.6),
          ),
        ),
      ]),
    );
  }

  Widget _buildScheduleCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _cardDecor(),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _sectionTitle(
            Icons.calendar_month_rounded, 'วันและเวลานัดหมาย', _kPrimary),
        const SizedBox(height: 14),
        Row(children: [
          Expanded(
            child: _scheduleChip(Icons.calendar_today_rounded,
                job['date'] as String, const Color(0xFF0262EC)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _scheduleChip(Icons.access_time_rounded,
                job['time'] as String, const Color(0xFF059669)),
          ),
        ]),
      ]),
    );
  }

  Widget _scheduleChip(IconData icon, String label, Color color) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Row(children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(label,
                style: TextStyle(
                    fontSize: 12, color: color, fontWeight: FontWeight.w700)),
          ),
        ]),
      );

  Widget _buildStatusCard(String status) {
    final configs = {
      'pending': (
        const Color(0xFFD97706),
        Icons.hourglass_top_rounded,
        'รอการตอบรับ',
        'กรุณาตอบรับหรือปฏิเสธภายใน 24 ชั่วโมง'
      ),
      'accepted': (
        _kPrimary,
        Icons.verified_rounded,
        'รับงานแล้ว',
        'คุณได้รับงานนี้แล้ว สามารถติดต่อลูกความได้เลย'
      ),
      'confirmed': (
        const Color(0xFF7C3AED),
        Icons.event_available_rounded,
        'ยืนยันนัดหมายแล้ว',
        'รอถึงวันนัดหมายเพื่อเริ่มการปรึกษา'
      ),
      'in_session': (
        const Color(0xFF059669),
        Icons.headset_mic_rounded,
        'กำลังปรึกษา',
        'เริ่มห้องปรึกษาแล้ว สามารถพูดคุยกับลูกความได้'
      ),
      'rejected': (
        const Color(0xFFEF4444),
        Icons.cancel_outlined,
        'ปฏิเสธแล้ว',
        'คุณได้ปฏิเสธคำขอนี้'
      ),
      'done': (
        const Color.fromARGB(255, 6, 235, 36),
        Icons.task_alt_rounded,
        'เสร็จสิ้น',
        'การปรึกษาเสร็จสิ้นแล้ว'
      ),
    };
    final cfg = configs[status] ?? configs['pending']!;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cfg.$1.withOpacity(0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cfg.$1.withOpacity(0.2)),
      ),
      child: Row(children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: cfg.$1.withOpacity(0.15),
            shape: BoxShape.circle,
          ),
          child: Icon(cfg.$2, size: 18, color: cfg.$1),
        ),
        const SizedBox(width: 12),
        Expanded(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(cfg.$3,
                style: TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w700, color: cfg.$1)),
            Text(cfg.$4,
                style: TextStyle(fontSize: 11, color: Colors.grey[500])),
          ]),
        ),
      ]),
    );
  }

  Widget _buildPendingButtons(BuildContext context) {
    final isBooking = (job['jobSource'] ?? 'urgent') == 'booking';
    return Container(
      padding: EdgeInsets.fromLTRB(
          16, 10, 16, MediaQuery.of(context).padding.bottom + 14),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFEEF2F5))),
      ),
      child: Row(children: [
        // Reject
        Expanded(
          child: GestureDetector(
            onTap: () {
              DialogService.showConfirmRejectJob(
                context,
                title: "ปฏิเสธคำขอ",
                message: "คุณยืนยันที่จะปฏิเสธคำขอนี้ใช่หรือไม่",
                onConfirm: () {
                  LawyerJobsStore.instance.rejectJob(job['id'] as String);
                  if (context.mounted) Navigator.pop(context);
                },
              );
            },
            child: Container(
              height: 52,
              decoration: BoxDecoration(
                color: const Color(0xFFFFF2F2),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                    color: const Color(0xFFEF4444).withOpacity(0.4),
                    width: 1.5),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.close_rounded, color: Color(0xFFEF4444), size: 18),
                  SizedBox(width: 6),
                  Text('ปฏิเสธ',
                      style: TextStyle(
                          color: Color(0xFFEF4444),
                          fontWeight: FontWeight.w700,
                          fontSize: 14)),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        // Accept
        Expanded(
          flex: 2,
          child: GestureDetector(
            onTap: () {
              DialogService.showConfirmAcceptJob(
                context,
                title: "รับงาน",
                message: "คุณยืนยันที่จะรับคำขอนี้ใช่หรือไม่",
                onConfirm: () {
                  if (isBooking) {
                    LawyerJobsStore.instance
                        .confirmBooking(job['id'] as String);
                  } else {
                    LawyerJobsStore.instance.acceptJob(job['id'] as String);
                  }
                  if (context.mounted) Navigator.pop(context);
                },
              );
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
                  const Icon(Icons.check_circle_outline_rounded,
                      color: Colors.white, size: 18),
                  const SizedBox(width: 8),
                  Text('รับงานนี้',
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 15)),
                ],
              ),
            ),
          ),
        ),
      ]),
    );
  }

  Widget _buildAcceptedButton(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
          16, 10, 16, MediaQuery.of(context).padding.bottom + 14),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFEEF2F5))),
      ),
      child: GestureDetector(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ChatPageLawyer(
              jobId: job['id'],
              model: {
                'name': job['clientName'],
                'avatar': job['clientAvatar'],
                'active': true,
                'caseSuccess': job['status'] == 'done',
                'clientColor': job['clientColor'],
              },
            ),
          ),
        ),
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
              Icon(Icons.headset_mic_rounded, color: Colors.white, size: 18),
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
    );
  }

  Widget _infoRow(String label, String value) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text(label,
                style: TextStyle(fontSize: 11, color: Colors.grey[400])),
          ),
          Expanded(
            child: Text(value,
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A2340))),
          ),
        ],
      );

  Widget _sectionTitle(IconData icon, String title, Color color) =>
      Row(children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [color, color.withOpacity(0.7)]),
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                  color: color.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2))
            ],
          ),
          child: Icon(icon, size: 16, color: Colors.white),
        ),
        const SizedBox(width: 10),
        Text(title,
            style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1A2340))),
      ]);

  BoxDecoration _cardDecor() => BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 12,
              offset: const Offset(0, 3))
        ],
      );
}
