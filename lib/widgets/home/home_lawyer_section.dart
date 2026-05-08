import 'package:LawyerOnline/appointment-details-lawyer.dart';
import 'package:LawyerOnline/lawyer-job-list.dart';
import 'package:LawyerOnline/menu.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:LawyerOnline/models/lawyer/lawyer_jobs_store.dart';
import 'package:LawyerOnline/component/dialog_service.dart';
import 'package:LawyerOnline/shared/responsive/res_layout.dart';
import 'package:LawyerOnline/shared/responsive/responsive_values.dart';

const _kPrimary = Color(0xFF0262EC);
const _kAccent = Color(0xFF2F80ED);
const _kCard = Colors.white;
const _kText = Color(0xFF0D1B2A);
const _kSub = Color(0xFF6B7A99);

// ─── Lawyer Dashboard ─────────────────────────────────────────────
// Mobile  → Column (เดิม ไม่เปลี่ยน)
// Desktop → Row 2-column: LEFT=appointments, RIGHT=job requests
class HomeLawyerSection extends StatelessWidget {
  final List<dynamic> appointments;
  final List<dynamic> jobRequests;
  final void Function(String id, String newStatus)? onJobStatusChanged;

  const HomeLawyerSection({
    super.key,
    required this.appointments,
    required this.jobRequests,
    this.onJobStatusChanged,
  });

  @override
  Widget build(BuildContext context) {
    final activeJobs = [
      ...jobRequests.where((j) => j['status'] == 'accepted'),
      ...jobRequests.where((j) => j['status'] == 'pending'),
    ];

    if (ResponsiveLayout.isDesktop(context)) {
      return _buildDesktopLayout(context, activeJobs);
    }
    return _buildMobileLayout(context, activeJobs);
  }

  // ══════════════════════════════════════════════════════════
  //  DESKTOP: 2-column Row
  // ══════════════════════════════════════════════════════════
  Widget _buildDesktopLayout(BuildContext context, List<dynamic> activeJobs) {
    final hPad = RV.pagePadding(context);

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: hPad),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── LEFT: รายการนัดหมาย (flex 3) ─────────────────
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _sectionHeader(
                  context,
                  title: 'รายการนัดหมาย (${appointments.length})',
                  onMore: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => MenuPage(pageIndex: 3))),
                  padded: false, // padding จัดการโดย parent แล้ว
                ),
                const SizedBox(height: 8),
                if (appointments.isNotEmpty)
                  _buildAppointmentListDesktop(context)
                else
                  _emptyState('ยังไม่มีนัดหมาย'),
                const SizedBox(height: 20),
              ],
            ),
          ),

          SizedBox(width: RV.cardGap(context) * 1.5),

          // ── RIGHT: เคสด่วนจากลูกความ (flex 2) ────────────
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _sectionHeader(
                  context,
                  title: 'เคสด่วนจากลูกความ (${activeJobs.length})',
                  onMore: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => LawyerJobListPage())),
                  padded: false,
                ),
                const SizedBox(height: 8),
                if (activeJobs.isNotEmpty)
                  _buildJobRequestListDesktop(context, activeJobs)
                else
                  _emptyState('ยังไม่มีเคสด่วนขณะนี้'),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Desktop: Appointment cards — vertical list ─────────────────────
  Widget _buildAppointmentListDesktop(BuildContext context) {
    final gap = RV.cardGap(context);
    // สร้าง Row ทีละคู่ — ไม่พึ่ง LayoutBuilder เพื่อหลีก unbounded width ใน IntrinsicHeight
    final rows = <Widget>[];
    for (int i = 0; i < appointments.length; i += 2) {
      final left = appointments[i];
      final right = i + 1 < appointments.length ? appointments[i + 1] : null;
      rows.add(
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _appointmentCardDesktop(
                context,
                left,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AppointmentDetailsLawyer(model: left),
                  ),
                ),
              ),
            ),
            SizedBox(width: gap),
            Expanded(
              child: right != null
                  ? _appointmentCardDesktop(
                      context,
                      right,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              AppointmentDetailsLawyer(model: right),
                        ),
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      );
      if (i + 2 < appointments.length) rows.add(SizedBox(height: gap));
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: rows,
    );
  }

  // ── Desktop appointment card: fullwidth แนวตั้ง ────────────────────
  Widget _appointmentCardDesktop(BuildContext context, Map model,
      {VoidCallback? onTap}) {
    final isPaid = (model['paymentStatus'] ?? '') == '1';
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          splashColor: Colors.white.withOpacity(0.15),
          highlightColor: Colors.white.withOpacity(0.08),
          child: Ink(
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1565C0), Color(0xFF1E88E5)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: _kAccent.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 35),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Row 1: icon + name + badge ──────────────────────
                  Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.event_rounded,
                            color: Color.fromARGB(255, 255, 255, 255),
                            size: 30),
                      ),
                      const SizedBox(width: 10),
                      const Icon(Icons.person_rounded,
                          size: 16, color: Color.fromARGB(255, 255, 255, 255)),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          model['clientName'] ?? '',
                          style: GoogleFonts.prompt(
                              color: const Color.fromARGB(255, 255, 255, 255),
                              fontSize: 16,
                              fontWeight: FontWeight.w500),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      // badge — fixed width ไม่ overflow
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(
                          color: isPaid
                              ? Colors.white.withOpacity(0.25)
                              : Colors.orange.withOpacity(0.85),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          isPaid ? 'ยืนยันแล้ว' : 'รอชำระ',
                          style: GoogleFonts.prompt(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  // ── Row 2: title ─────────────────────────────────────
                  Text(model['title'] ?? '',
                      style: GoogleFonts.prompt(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w700),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  Text(model['subCaseType'] ?? '',
                      style: GoogleFonts.prompt(
                          color: Colors.white70,
                          fontSize: 12,
                          fontWeight: FontWeight.w500),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 6),
                  // ── Row 3: date + time inline ─────────────────────────
                  Row(
                    children: [
                      const Icon(Icons.calendar_today_rounded,
                          size: 10, color: Colors.white70),
                      const SizedBox(width: 4),
                      Text(model['appointmentDate'] ?? '',
                          style: GoogleFonts.prompt(
                              fontSize: 11, color: Colors.white70)),
                      const SizedBox(width: 10),
                      const Icon(Icons.access_time_rounded,
                          size: 10, color: Colors.white70),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(model['appointmentTime'] ?? '',
                            style: GoogleFonts.prompt(
                                fontSize: 11, color: Colors.white70),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                      ),
                    ],
                  ),
                ],
              ), // Column
            ), // Padding
          ), // Ink
        ), // InkWell
      ), // Material
    ); // MouseRegion
  }

  // ── Desktop: Job request list (vertical, ไม่ต้อง padding ซ้ำ) ──────
  Widget _buildJobRequestListDesktop(BuildContext context, List<dynamic> jobs) {
    return Column(
      children: [
        for (int i = 0; i < jobs.length; i++) ...[
          if (i > 0) const SizedBox(height: 10),
          _urgentJobCard(context, jobs[i]),
        ],
      ],
    );
  }

  // ══════════════════════════════════════════════════════════
  //  MOBILE: Column เดิม ไม่เปลี่ยน
  // ══════════════════════════════════════════════════════════
  Widget _buildMobileLayout(BuildContext context, List<dynamic> activeJobs) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Appointments ─────────────────────────────────────────
        _sectionHeader(
          context,
          title: 'รายการนัดหมาย (${appointments.length})',
          onMore: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => MenuPage(pageIndex: 3))),
        ),
        if (appointments.isNotEmpty)
          _buildAppointmentListMobile(context)
        else
          _emptyState('ยังไม่มีนัดหมาย'),
        const SizedBox(height: 20),

        // ── Job Requests ─────────────────────────────────────────
        _sectionHeader(
          context,
          title: 'เคสด่วนจากลูกความ (${activeJobs.length})',
          onMore: () => Navigator.push(
              context, MaterialPageRoute(builder: (_) => LawyerJobListPage())),
        ),
        const SizedBox(height: 8),
        if (activeJobs.isNotEmpty)
          _buildJobRequestListMobile(context, activeJobs)
        else
          _emptyState('ยังไม่มีเคสด่วนขณะนี้'),
        const SizedBox(height: 20),
      ],
    );
  }

  // ── Section header ────────────────────────────────────────────────
  // padded: true  → มี horizontal padding 18 (mobile default)
  // padded: false → ไม่มี padding (desktop จัดการ padding จาก parent)
  Widget _sectionHeader(
    BuildContext context, {
    required String title,
    VoidCallback? onMore,
    bool padded = true,
  }) {
    final content = Row(
      children: [
        Text(
          title,
          style: GoogleFonts.prompt(
            fontSize: RV.titleSize(context) - 1,
            fontWeight: FontWeight.w700,
            color: _kText,
          ),
        ),
        const Spacer(),
        if (onMore != null)
          MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: onMore,
              child: Text(
                'ดูทั้งหมด',
                style: GoogleFonts.prompt(
                  fontSize: 12,
                  color: _kAccent,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
      ],
    );

    if (!padded) return content;

    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 0, 18, 6),
      child: content,
    );
  }

  // ── Mobile: Appointment Cards (horizontal scroll — เดิม) ──────────
  Widget _buildAppointmentListMobile(BuildContext context) {
    return SizedBox(
      height: 180,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(18, 4, 48, 0),
        itemCount: appointments.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (_, i) => _appointmentCardMobile(
          context,
          appointments[i],
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => AppointmentDetailsLawyer(model: appointments[i]),
            ),
          ),
        ),
      ),
    );
  }

  // ── Mobile appointment card (เดิม — ไม่เปลี่ยน) ──────────────────
  Widget _appointmentCardMobile(BuildContext context, Map model,
      {VoidCallback? onTap}) {
    final isPaid = (model['paymentStatus'] ?? '') == '1';

    // ใช้ LayoutBuilder เพื่อให้ width ถูกต้อง ไม่พึ่ง size.width โดยตรง
    return LayoutBuilder(
      builder: (ctx, constraints) {
        // fallback: ถ้า constraints ไม่มีข้อมูล ใช้ screen width
        final screenW = MediaQuery.of(context).size.width;
        final cardW = (screenW - 18 * 2 - 14) / 2;

        return MouseRegion(
          cursor: SystemMouseCursors.click,
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(18),
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(18),
              splashColor: Colors.white.withOpacity(0.15),
              highlightColor: Colors.white.withOpacity(0.08),
              child: Ink(
                width: cardW,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1565C0), Color(0xFF1E88E5)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: _kAccent.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.event_rounded,
                                color: Colors.white, size: 20),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 7, vertical: 3),
                            decoration: BoxDecoration(
                              color: isPaid
                                  ? Colors.white.withOpacity(0.25)
                                  : Colors.orange.withOpacity(0.85),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              isPaid ? 'ยืนยันแล้ว' : 'รอชำระ',
                              style: GoogleFonts.prompt(
                                  color: Colors.white,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                      Row(children: [
                        const Icon(Icons.person_rounded,
                            size: 11, color: Colors.white60),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            model['clientName'] ?? '',
                            style: GoogleFonts.prompt(
                                color: Colors.white60,
                                fontSize: 10,
                                fontWeight: FontWeight.w500),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ]),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(model['subCaseType'] ?? '',
                              style: GoogleFonts.prompt(
                                  color: Colors.white70,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis),
                          Text(model['title'] ?? '',
                              style: GoogleFonts.prompt(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(children: [
                            const Icon(Icons.calendar_today_rounded,
                                size: 10, color: Colors.white70),
                            const SizedBox(width: 4),
                            Text(model['appointmentDate'] ?? '',
                                style: GoogleFonts.prompt(
                                    fontSize: 12, color: Colors.white70)),
                          ]),
                          const SizedBox(height: 2),
                          Row(children: [
                            const Icon(Icons.access_time_rounded,
                                size: 10, color: Colors.white70),
                            const SizedBox(width: 4),
                            Text(model['appointmentTime'] ?? '',
                                style: GoogleFonts.prompt(
                                    fontSize: 12,
                                    color: const Color.fromARGB(
                                        179, 255, 255, 255))),
                          ]),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _emptyState(String message) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 18),
      child: Center(
        child: Text(
          message,
          style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
        ),
      ),
    );
  }

  // ── Mobile: Job Request Cards (vertical — เดิม) ───────────────────
  Widget _buildJobRequestListMobile(BuildContext context, List<dynamic> jobs) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 0, 18, 0),
      child: Column(
        children: [
          for (int i = 0; i < jobs.length; i++) ...[
            if (i > 0) const SizedBox(height: 10),
            _urgentJobCard(context, jobs[i]),
          ],
        ],
      ),
    );
  }

  // ── Urgent job card (shared — ไม่เปลี่ยน UI เลย) ─────────────────
  Widget _urgentJobCard(BuildContext context, Map<String, dynamic> job) {
    final status = job['status'] as String;
    final barColors = _statusBarColors(status);
    final badge = _statusBadge(status);
    final isAccepted = status == 'accepted';

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: () {
            final isPending = status == 'pending';
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (detailCtx) => LawyerJobDetailPage(
                  job: job,
                  onAccept: isPending
                      ? () {
                          DialogService.showConfirmAcceptJob(
                            detailCtx,
                            title: "รับงาน",
                            message: "คุณยืนยันที่จะรับคำขอนี้ใช่หรือไม่",
                            onConfirm: () {
                              LawyerJobsStore.instance
                                  .acceptJob(job['id'] as String);
                              if (detailCtx.mounted) {
                                Navigator.pop(detailCtx);
                                onJobStatusChanged?.call(job['id'], 'accepted');
                              }
                            },
                          );
                        }
                      : null,
                  onReject: isPending
                      ? () {
                          DialogService.showConfirmRejectJob(
                            detailCtx,
                            title: "ปฏิเสธคำขอ",
                            message: "คุณยืนยันที่จะปฏิเสธคำขอนี้ใช่หรือไม่",
                            onConfirm: () {
                              LawyerJobsStore.instance
                                  .rejectJob(job['id'] as String);
                              if (detailCtx.mounted) {
                                Navigator.pop(detailCtx);
                                onJobStatusChanged?.call(job['id'], 'rejected');
                              }
                            },
                          );
                        }
                      : null,
                ),
              ),
            );
          },
          borderRadius: BorderRadius.circular(16),
          splashColor: const Color(0xFF0262EC).withOpacity(0.08),
          highlightColor: const Color(0xFF0262EC).withOpacity(0.04),
          child: Ink(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: IntrinsicHeight(
              child: Row(
                children: [
                  // ── color bar ───────────────────────────────────────
                  Container(
                    width: 8,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: barColors,
                      ),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(16),
                        bottomLeft: Radius.circular(16),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // ── header ──────────────────────────────────
                          Row(children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: Color(job['clientColor']),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Center(
                                child: Text(
                                  job['clientAvatar'],
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(job['clientName'],
                                      style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFF1A2340),
                                      )),
                                  const SizedBox(height: 2),
                                  Row(children: [
                                    Icon(Icons.access_time,
                                        size: 12, color: Colors.grey[400]),
                                    const SizedBox(width: 4),
                                    Text(job['requestedAt'],
                                        style: TextStyle(
                                            fontSize: 11,
                                            color: Colors.grey[500])),
                                  ]),
                                ],
                              ),
                            ),
                            badge,
                          ]),
                          const SizedBox(height: 14),
                          // ── topic badge ─────────────────────────────
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: _kPrimary.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.gavel_rounded,
                                    size: 12, color: _kPrimary),
                                const SizedBox(width: 5),
                                Text(job['topic'],
                                    style: const TextStyle(
                                      color: _kPrimary,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    )),
                              ],
                            ),
                          ),
                          const SizedBox(height: 10),
                          // ── subtopic + details btn ──────────────────
                          Row(children: [
                            Expanded(
                              child: Text(job['subTopic'],
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF1A2340),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis),
                            ),
                            const SizedBox(width: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 8),
                              decoration: BoxDecoration(
                                color: _kPrimary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text('ดูรายละเอียด',
                                      style: TextStyle(
                                        color: _kPrimary,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                      )),
                                  SizedBox(width: 4),
                                  Icon(Icons.arrow_forward_ios,
                                      size: 10, color: _kPrimary),
                                ],
                              ),
                            ),
                          ]),
                          // ── appointment box (accepted only) ─────────
                          if (isAccepted &&
                              (job['date'] as String? ?? '').isNotEmpty) ...[
                            const SizedBox(height: 10),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: _kPrimary.withOpacity(0.05),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                    color: _kPrimary.withOpacity(0.2)),
                              ),
                              child: Row(children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: _kPrimary.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(Icons.calendar_today,
                                      size: 16, color: _kPrimary),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '${job['date']} • ${job['time']}',
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                          color: Color(0xFF1A2340),
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text('อยู่ในช่วงเวลาให้คำปรึกษา',
                                          style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey[800])),
                                    ],
                                  ),
                                ),
                              ]),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ), // Row
            ), // IntrinsicHeight
          ), // Ink
        ), // InkWell
      ), // Material
    ); // MouseRegion
  }
}

// ─── Status helpers (เดิม ไม่เปลี่ยน) ────────────────────────────────
List<Color> _statusBarColors(String status) {
  switch (status) {
    case 'accepted':
      return [const Color(0xFF00AA17), const Color(0xFF00AA17)];
    case 'pending':
      return [const Color(0xFFD97706), const Color(0xFFF59E0B)];
    default:
      return [Colors.grey, Colors.grey.shade400];
  }
}

Widget _statusBadge(String status) {
  final Map<String, dynamic>? config = switch (status) {
    'accepted' => {
        'colors': [const Color(0xFF0262EC), const Color(0xFF0099FF)],
        'icon': Icons.check_circle,
        'label': 'รับแล้ว',
        'shadow': const Color(0xFF0262EC),
      },
    'pending' => {
        'colors': [const Color(0xFFD97706), const Color(0xFFF59E0B)],
        'icon': Icons.hourglass_top,
        'label': 'รอตอบรับ',
        'shadow': const Color(0xFFD97706),
      },
    _ => null,
  };

  if (config == null) return const SizedBox.shrink();

  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(
      gradient: LinearGradient(colors: config['colors']),
      borderRadius: BorderRadius.circular(8),
      boxShadow: [
        BoxShadow(
          color: (config['shadow'] as Color).withOpacity(0.3),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ],
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(config['icon'] as IconData, size: 14, color: Colors.white),
        const SizedBox(width: 4),
        Text(config['label'],
            style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold)),
      ],
    ),
  );
}
