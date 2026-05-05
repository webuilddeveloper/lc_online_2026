import 'package:LawyerOnline/appointment-details-lawyer.dart';
import 'package:LawyerOnline/lawyer-job-list.dart';
import 'package:LawyerOnline/menu.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:LawyerOnline/models/lawyer/lawyer_jobs_store.dart';
import 'package:flutter/services.dart';
import 'package:LawyerOnline/component/dialog_service.dart';

const _kPrimary = Color(0xFF0262EC);
const _kAccent = Color(0xFF2F80ED);
const _kCard = Colors.white;
const _kText = Color(0xFF0D1B2A);
const _kSub = Color(0xFF6B7A99);

// ─── Lawyer Dashboard ─────────────────────────────────────────────
// รวม: appointment list, job request list + urgent job cards
// StatelessWidget → rebuild เฉพาะเมื่อ props เปลี่ยนเท่านั้น
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
          _buildAppointmentList(context)
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
          _buildJobRequestList(context, activeJobs)
        else
          _emptyState('ยังไม่มีเคสด่วนขณะนี้'),
        const SizedBox(height: 20),
      ],
    );
  }

  // ── Section header ────────────────────────────────────────────────
  Widget _sectionHeader(
    BuildContext context, {
    required String title,
    VoidCallback? onMore,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 0, 18, 6),
      child: Row(
        children: [
          Text(
            title,
            style: GoogleFonts.prompt(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: _kText,
            ),
          ),
          const Spacer(),
          if (onMore != null)
            GestureDetector(
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
        ],
      ),
    );
  }

  // ── Appointment Cards (horizontal scroll) ─────────────────────────
  Widget _buildAppointmentList(BuildContext context) {
    return SizedBox(
      height: 180,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(18, 4, 48, 0),
        itemCount: appointments.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (_, i) => _appointmentCard(
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

  Widget _appointmentCard(BuildContext context, Map model,
      {VoidCallback? onTap}) {
    final isPaid = (model['paymentStatus'] ?? '') == '1';
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: (MediaQuery.of(context).size.width - 18 * 2 - 14) / 2,
        padding: const EdgeInsets.all(14),
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
                  padding:
                      const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
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
              const Icon(Icons.person_rounded, size: 11, color: Colors.white60),
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
                          color: const Color.fromARGB(179, 255, 255, 255))),
                ]),
              ],
            ),
          ],
        ),
      ),
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

  // ── Job Request Cards (vertical) ──────────────────────────────────
  Widget _buildJobRequestList(BuildContext context, List<dynamic> jobs) {
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

  Widget _urgentJobCard(BuildContext context, Map<String, dynamic> job) {
    final status = job['status'] as String;
    final barColors = _statusBarColors(status);
    final badge = _statusBadge(status);
    final isAccepted = status == 'accepted';

    return GestureDetector(
      onTap: () {
        final isPending = status == 'pending';
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => LawyerJobDetailPage(
              job: job,
              onAccept: isPending
                  ? () => LawyerJobsStore.instance.acceptJob(
                        context,
                        job['id'],
                        onDone: () {
                          Navigator.pop(context);
                          onJobStatusChanged?.call(job['id'], 'accepted');
                        },
                      )
                  : null,
              onReject: isPending
                  ? () => LawyerJobsStore.instance.rejectJob(
                        context,
                        job['id'],
                        onDone: () {
                          Navigator.pop(context);
                          onJobStatusChanged?.call(job['id'], 'rejected');
                        },
                      )
                  : null,
            ),
          ),
        );
      },
      child: Container(
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
                                        fontSize: 11, color: Colors.grey[500])),
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
                            border:
                                Border.all(color: _kPrimary.withOpacity(0.2)),
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
                                crossAxisAlignment: CrossAxisAlignment.start,
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
          ),
        ),
      ),
    );
  }
}

// ─── Status helpers ───────────────────────────────────────────────
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
