import 'package:LawyerOnline/appointment-details-lawyer.dart';
import 'package:LawyerOnline/calendar.dart';
import 'package:LawyerOnline/lawyer-job-details.dart';
import 'package:LawyerOnline/lawyer-job-list.dart';
import 'package:LawyerOnline/menu.dart';
import 'package:LawyerOnline/models/user_profile_store.dart';
import 'package:LawyerOnline/shared/api_provider.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:LawyerOnline/models/lawyer/lawyer_jobs_store.dart';
import 'package:LawyerOnline/repositories/lawyer_repository.dart';
import 'package:LawyerOnline/chat/chat_page_lawyer.dart';
import 'package:LawyerOnline/component/dialog_service.dart';
import 'package:LawyerOnline/component/loading_service.dart';
import 'package:LawyerOnline/services/video_call_service.dart';
import 'package:LawyerOnline/shared/responsive/res_layout.dart';
import 'package:LawyerOnline/shared/responsive/responsive_values.dart';
import 'package:LawyerOnline/widgets/home/home_theme.dart';
import 'package:easy_localization/easy_localization.dart';

const _kPrimary = Color(0xFF0262EC);
const _kAccent = Color(0xFF2F80ED);
const _kText = Color(0xFF0D1B2A);

class HomeLawyerSection extends StatefulWidget {
  final List<dynamic> jobRequests;
  final int refreshToken;
  final bool isLoadingAppointments;
  final String? appointmentLoadError;
  final Future<void> Function(dynamic job, String newStatus)?
      onJobStatusChanged;

  const HomeLawyerSection({
    super.key,
    required this.jobRequests,
    this.refreshToken = 0,
    this.isLoadingAppointments = false,
    this.appointmentLoadError,
    this.onJobStatusChanged,
  });

  @override
  State<HomeLawyerSection> createState() => _HomeLawyerSectionState();
}

class _HomeLawyerSectionState extends State<HomeLawyerSection> {
  List<dynamic> appointmentsList = const [];

  @override
  void initState() {
    super.initState();
    _loadLawyerappointmentsList();
  }

  @override
  void didUpdateWidget(HomeLawyerSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.refreshToken != widget.refreshToken) {
      _loadLawyerappointmentsList();
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeUrgentJobs = widget.jobRequests.where((j) {
      if ((j['jobSource'] ?? 'urgent') != 'urgent') return false;
      final status = j['status']?.toString() ?? '';
      return status == 'pending' ||
          status == 'accepted' ||
          status == 'in_session';
    }).toList();
    final pendingBookings = widget.jobRequests
        .where((j) =>
            (j['jobSource'] ?? 'urgent') == 'booking' &&
            j['status'] == 'pending')
        .toList();
    final dueBookings =
        widget.jobRequests.where(_isConfirmedBookingDueToday).toList();

    if (ResponsiveLayout.isDesktop(context)) {
      return _buildDesktopLayout(
          context, activeUrgentJobs, pendingBookings, dueBookings);
    }
    return _buildMobileLayout(
        context, activeUrgentJobs, pendingBookings, dueBookings);
  }

  bool _isConfirmedBookingDueToday(dynamic job) {
    if (job is! Map) return false;
    if ((job['jobSource'] ?? 'urgent') != 'booking') return false;
    if (job['status'] != 'confirmed') return false;
    final dateStr = job['date']?.toString() ?? '';
    final parts = dateStr.split('/');
    if (parts.length != 3) return false;
    final day = int.tryParse(parts[0]);
    final month = int.tryParse(parts[1]);
    final year = int.tryParse(parts[2]);
    if (day == null || month == null || year == null) return false;
    final now = DateTime.now();
    return now.day == day && now.month == month && now.year == year;
  }

  // ══════════════════════════════════════════════════════════
  //  DESKTOP
  // ══════════════════════════════════════════════════════════
  Widget _buildDesktopLayout(
      BuildContext context,
      List<dynamic> activeUrgentJobs,
      List<dynamic> pendingBookings,
      List<dynamic> dueBookings) {
    final hPad = RV.pagePadding(context);

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: hPad),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _sectionHeader(
                  context,
                  title:
                      '${'appointmentList'.tr()} (${appointmentsList.length})',
                  onMore: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => MenuPage(pageIndex: 3))),
                  padded: false,
                ),
                const SizedBox(height: 8),
                if (widget.isLoadingAppointments)
                  _loadingState()
                else if ((widget.appointmentLoadError ?? '').isNotEmpty)
                  _emptyState(widget.appointmentLoadError!)
                else if (appointmentsList.isNotEmpty)
                  _buildAppointmentListDesktop(context)
                else
                  _emptyState('noAppointments'.tr()),
                const SizedBox(height: 20),
              ],
            ),
          ),
          SizedBox(width: RV.cardGap(context) * 1.5),
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (dueBookings.isNotEmpty) ...[
                  _sectionHeader(
                    context,
                    title: 'นัดหมายวันนี้ (${dueBookings.length})',
                    onMore: () => Navigator.push(context,
                        MaterialPageRoute(builder: (_) => LawyerJobListPage())),
                    padded: false,
                  ),
                  const SizedBox(height: 8),
                  _buildTodayBookingList(context, dueBookings),
                  const SizedBox(height: 20),
                ],
                if (pendingBookings.isNotEmpty) ...[
                  _sectionHeader(
                    context,
                    title: 'นัดหมายรอยืนยัน (${pendingBookings.length})',
                    onMore: () => Navigator.push(context,
                        MaterialPageRoute(builder: (_) => LawyerJobListPage())),
                    padded: false,
                  ),
                  const SizedBox(height: 8),
                  _buildJobRequestListDesktop(context, pendingBookings),
                  const SizedBox(height: 20),
                ],
                _sectionHeader(
                  context,
                  title: '${'urgentCases'.tr()} (${activeUrgentJobs.length})',
                  onMore: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => LawyerJobListPage())),
                  padded: false,
                ),
                const SizedBox(height: 8),
                if (activeUrgentJobs.isNotEmpty)
                  _buildJobRequestListDesktop(context, activeUrgentJobs)
                else
                  _emptyState('noUrgentCases'.tr()),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppointmentListDesktop(BuildContext context) {
    final gap = RV.cardGap(context);
    final rows = <Widget>[];
    for (int i = 0; i < appointmentsList.length; i += 2) {
      final left = appointmentsList[i];
      final right =
          i + 1 < appointmentsList.length ? appointmentsList[i + 1] : null;
      rows.add(
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _appointmentCardDesktop(context, left,
                  onTap: () => _navigateFromAppointment(context, left)),
            ),
            SizedBox(width: gap),
            Expanded(
              child: right != null
                  ? _appointmentCardDesktop(context, right,
                      onTap: () => _navigateFromAppointment(context, right))
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      );
      if (i + 2 < appointmentsList.length) rows.add(SizedBox(height: gap));
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: rows);
  }

  Future<void> _loadLawyerappointmentsList() async {
    final lawyerCode = UserProfileStore.instance.code;

    if (lawyerCode.isEmpty) return;
    try {
      final param =
          await postDio("${server}/m/case/read", {"lawyer": lawyerCode});

      if (param['status'] == 'S') {
        final allCases = List<dynamic>.from(param['objectData'] ?? []);
        final filtered = allCases.where((item) {
          if (item is! Map) return false;
          if (!CaseAppointmentMapper.isVisibleOnHome(
            Map<String, dynamic>.from(item),
          )) {
            return false;
          }
          return !CaseAppointmentMapper.isUrgentCase(
            Map<String, dynamic>.from(item),
          );
        }).toList();
        if (!mounted) return;
        setState(() {
          appointmentsList = filtered;
        });
      }
    } catch (_) {
      // if (!mounted) return;
      // final fallbackappointmentsList =
      //     LawyerJobsStore.instance.bookingappointmentsListForLawyer(lawyerCode);
      setState(() {
        // _lawyerappointmentsList = fallbackappointmentsList;
        // _apiBookingJobs = const [];
        // _appointmentLoadError =
        //     fallbackappointmentsList.isEmpty ? 'genericError'.tr() : null;
        // _isLoadingAppointments = false;
      });
    }
  }

  void _navigateFromAppointment(BuildContext context, dynamic appt) {
    final caseStatus = (appt['caseStatus'] ?? '').toString();
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => AppointmentDetailsLawyer(model: appt)),
    ).then((x) => _loadLawyerappointmentsList());
    // if (caseStatus == '1') {
    //   Navigator.push(
    //     context,
    //     MaterialPageRoute(
    //       builder: (detailCtx) => LawyerJobDetailPage(
    //         job: appt,
    //         onAccept: () {
    //           // LawyerJobsStore.instance.acceptJob(appt['code'] as String);
    //           // if (detailCtx.mounted) {
    //           //   Navigator.pop(detailCtx);
    //           //   widget.onJobStatusChanged?.call(appt, 'accepted');
    //           // }
    //           print('1');
    //         },
    //         onReject: () {
    //           // DialogService.showConfirmRejectJob(
    //           //   detailCtx,
    //           //   title: "rejectJob".tr(),
    //           //   message: "rejectJobConfirm".tr(),
    //           //   onConfirm: () {
    //           //     LawyerJobsStore.instance.rejectJob(appt['code'] as String);
    //           //     if (detailCtx.mounted) {
    //           //       Navigator.pop(detailCtx);
    //           //       widget.onJobStatusChanged?.call(appt, 'rejected');
    //           //     }
    //           //   },
    //           // );
    //           print('2');
    //         },
    //       ),
    //     ),
    //   ).then((value) => {
    //         _loadLawyerappointmentsList()
    //         // print(value)
    //         // if (value) rippleController.reverse()
    //       });
    // } else {

    // }
  }

  Widget _appointmentCardDesktop(BuildContext context, Map model,
      {VoidCallback? onTap}) {
    final isPaid = (model['paymentStatus'] ?? '') == '1';
    final statusCfg = _caseStatusConfig((model['caseStatus'] ?? '').toString());

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.black.withOpacity(0.20), width: 1.5),
        ),
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
              ),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 35),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.event_rounded,
                            color: Colors.white, size: 30),
                      ),
                      const SizedBox(width: 10),
                      const Icon(Icons.person_rounded,
                          size: 16, color: Colors.white),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          model['clientName'] ?? '',
                          style: GoogleFonts.prompt(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w500),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(
                          color: Color(statusCfg['color'] as int)
                              .withOpacity(0.90),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(statusCfg['label'] as String,
                            style: GoogleFonts.prompt(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.w600)),
                      ),
                      const SizedBox(width: 6),
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
                          isPaid ? 'paid'.tr() : 'awaitingPayment'.tr(),
                          style: GoogleFonts.prompt(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.w600),
                        ),
                      ),
                    ]),
                    const SizedBox(height: 6),
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
                    Row(children: [
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
                    ]),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildJobRequestListDesktop(BuildContext context, List<dynamic> jobs) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        children: [
          for (int i = 0; i < jobs.length; i++) ...[
            if (i > 0) const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: _urgentJobCard(context, jobs[i]),
            ),
          ],
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════
  //  MOBILE
  // ══════════════════════════════════════════════════════════
  Widget _buildMobileLayout(
      BuildContext context,
      List<dynamic> activeUrgentJobs,
      List<dynamic> pendingBookings,
      List<dynamic> dueBookings) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
         _sectionHeader(
          context,
          title: '${'urgentCases'.tr()} (${activeUrgentJobs.length})',
          onMore: () => Navigator.push(
              context, MaterialPageRoute(builder: (_) => LawyerJobListPage())),
        ),
        const SizedBox(height: 8),
        if (activeUrgentJobs.isNotEmpty)
          _buildJobRequestListMobile(context, activeUrgentJobs)
        else
          _emptyState('noUrgentCases'.tr()),
        const SizedBox(height: 20),
        _sectionHeader(
          context,
          title: '${'appointmentList'.tr()} (${appointmentsList.length})',
          onMore: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => CalendarPage(isBtnBack: true,),
            ),
          ).then((_) {
            // ✅ เมื่อ pop กลับมา เรียก callback
            _loadLawyerappointmentsList();
          }),
        ),
        if (widget.isLoadingAppointments)
          _loadingState()
        else if ((widget.appointmentLoadError ?? '').isNotEmpty)
          _emptyState(widget.appointmentLoadError!)
        else if (appointmentsList.isNotEmpty)
          _buildAppointmentListMobile(context)
        else
          _emptyState('noAppointments'.tr()),
        const SizedBox(height: 20),
        if (dueBookings.isNotEmpty) ...[
          _sectionHeader(
            context,
            title: 'นัดหมายวันนี้ (${dueBookings.length})',
            onMore: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => LawyerJobListPage())),
          ),
          const SizedBox(height: 8),
          _buildTodayBookingList(context, dueBookings),
          const SizedBox(height: 20),
        ],
        if (pendingBookings.isNotEmpty) ...[
          _sectionHeader(
            context,
            title: 'นัดหมายรอยืนยัน (${pendingBookings.length})',
            onMore: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => LawyerJobListPage())),
          ),
          const SizedBox(height: 8),
          _buildJobRequestListMobile(context, pendingBookings),
          const SizedBox(height: 20),
        ],
       
      ],
    );
  }

  Widget _sectionHeader(BuildContext context,
      {required String title, VoidCallback? onMore, bool padded = true}) {
    final header = HomeSectionHeader(
      title: title,
      onMore: onMore,
      padding: padded
          ? const EdgeInsets.fromLTRB(18, 0, 18, 10)
          : EdgeInsets.zero,
    );
    return header;
  }

  Widget _buildAppointmentListMobile(BuildContext context) {
    return SizedBox(
      height: 220,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        clipBehavior: Clip.none,
        padding: const EdgeInsets.fromLTRB(18, 4, 48, 12),
        itemCount: appointmentsList.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (_, i) => _appointmentCardMobile(
          context,
          appointmentsList[i],
          onTap: () => _navigateFromAppointment(context, appointmentsList[i]),
        ),
      ),
    );
  }

  Widget _appointmentCardMobile(BuildContext context, Map model,
      {VoidCallback? onTap}) {
    final statusCfg = _caseStatusConfig((model['caseStatus'] ?? '').toString());

    return LayoutBuilder(
      builder: (ctx, constraints) {
        final screenW = MediaQuery.of(context).size.width;
        final cardW = (screenW - 18 * 2 - 14) / 2;

        return MouseRegion(
          cursor: SystemMouseCursors.click,
          child: Container(
            width: cardW,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border:
                  Border.all(color: Colors.black.withOpacity(0.20), width: 0.5),
            ),
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
                                color: Color(statusCfg['color'] as int)
                                    .withOpacity(0.90),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(statusCfg['label'] as String,
                                  style: GoogleFonts.prompt(
                                      color: Colors.white,
                                      fontSize: 9,
                                      fontWeight: FontWeight.w600)),
                            ),
                          ],
                        ),
                        Align(
                          alignment: Alignment.centerRight,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 7, vertical: 3),
                            decoration: BoxDecoration(
                              color: model['isPay']
                                  ? Colors.white.withOpacity(0.25)
                                  : Colors.orange.withOpacity(0.85),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              model['isPay']
                                  ? 'paid'.tr()
                                  : 'awaitingPayment'.tr(),
                              style: GoogleFonts.prompt(
                                  color: Colors.white,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w600),
                            ),
                          ),
                        ),
                        Row(children: [
                          const Icon(Icons.person_rounded,
                              size: 11, color: Colors.white60),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(model['userName'] ?? '',
                                style: GoogleFonts.prompt(
                                    color: Colors.white60,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w500),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis),
                          ),
                        ]),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(model['subTopicTitle'] ?? '',
                                style: GoogleFonts.prompt(
                                    color: Colors.white70,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis),
                            Text(model['topicTitle'] ?? '',
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
                              Text(model['caseDate'] ?? '',
                                  style: GoogleFonts.prompt(
                                      fontSize: 12, color: Colors.white70)),
                            ]),
                            const SizedBox(height: 2),
                            Row(children: [
                              const Icon(Icons.access_time_rounded,
                                  size: 10, color: Colors.white70),
                              const SizedBox(width: 4),
                              Text('${model['startTime']}-${model['endTime']}',
                                  style: GoogleFonts.prompt(
                                      fontSize: 12, color: Colors.white70)),
                            ]),
                          ],
                        ),
                      ],
                    ),
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
        child: Text(message,
            style: TextStyle(fontSize: 13, color: Colors.grey.shade500)),
      ),
    );
  }

  Widget _loadingState() {
    return const AppLoadingInline(height: 72, size: 28);
  }

  Widget _buildTodayBookingList(BuildContext context, List<dynamic> jobs) {
    final isDesktop = ResponsiveLayout.isDesktop(context);
    return Padding(
      padding: EdgeInsets.fromLTRB(isDesktop ? 0 : 18, 0, isDesktop ? 0 : 18, 8),
      child: Column(
        children: [
          for (int i = 0; i < jobs.length; i++) ...[
            if (i > 0) const SizedBox(height: 10),
            _todayBookingCard(context, jobs[i]),
          ],
        ],
      ),
    );
  }

  Widget _todayBookingCard(BuildContext context, Map<String, dynamic> job) {
    final clientName = job['clientName']?.toString() ?? '';
    final avatar = job['clientAvatar']?.toString().isNotEmpty == true
        ? job['clientAvatar'].toString()
        : (clientName.isNotEmpty ? clientName[0] : '?');
    final colorValue = job['clientColor'];
    final avatarColor = colorValue is int
        ? Color(colorValue)
        : const Color(0xFF0262EC);
    final topic = job['topic']?.toString().trim() ?? '';
    final subTopic = job['subTopic']?.toString().trim() ?? '';
    final detail = job['detail']?.toString().trim() ?? '';
    final time = job['time']?.toString().trim() ?? '';
    final date = job['date']?.toString().trim() ?? '';
    final budget = job['budget']?.toString().trim() ?? '';
    final raw = job['rawCase'];
    final rawMap = raw is Map ? Map<String, dynamic>.from(raw) : null;
    final isPaid = rawMap?['isPay'] == true || job['isPay'] == true;
    final price = budget.isNotEmpty
        ? budget
        : (rawMap?['price']?.toString().trim() ?? '');

    final timeParts = time.split(RegExp(r'\s*[-–—]\s*'));
    final caseData = <String, dynamic>{
      if (rawMap != null) ...rawMap,
      'caseDate': rawMap?['caseDate'] ?? date,
      'appointmentDate': rawMap?['appointmentDate'] ?? date,
      'date': date,
      'startTime': rawMap?['startTime'] ??
          (timeParts.isNotEmpty ? timeParts.first.trim() : ''),
      'endTime': rawMap?['endTime'] ??
          (timeParts.length > 1 ? timeParts.last.trim() : ''),
      'caseStatus': rawMap?['caseStatus'] ?? job['caseStatusInt'] ?? 2,
      'caseType': rawMap?['caseType'] ?? 1,
    };
    final joinResult = VideoCallService.checkJoinWindow(caseData);
    final canStart = joinResult == VideoCallJoinResult.allowed;
    final windowLabel = VideoCallService.joinWindowMessage(caseData);

    void openDetail() {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => LawyerJobDetailPage(job: job)),
      );
    }

    void startConsult() {
      if (!canStart) {
        final msg = joinResult == VideoCallJoinResult.tooEarly
            ? (windowLabel.isNotEmpty
                ? 'ยังไม่ถึงเวลานัด ($windowLabel)'
                : 'ยังไม่ถึงเวลานัด')
            : (windowLabel.isNotEmpty
                ? 'เลยเวลานัดแล้ว ($windowLabel)'
                : 'เลยเวลานัดแล้ว');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg)),
        );
        return;
      }
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ChatPageLawyer(
            model: {
              'id': job['id'],
              'jobId': job['id'],
              'jobSource': job['jobSource'] ?? 'booking',
              'jobStatus': 'in_session',
              'name': clientName,
              'avatar': avatar,
              'active': true,
              'caseSuccess': false,
              'clientColor': job['clientColor'],
              'code': job['caseCode'] ?? job['id'],
              'caseCode': job['caseCode'] ?? job['id'],
            },
          ),
        ),
      );
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: openDetail,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0262EC).withOpacity(0.06),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  width: 5,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0xFF0262EC), Color(0xFF38BDF8)],
                    ),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(16),
                      bottomLeft: Radius.circular(16),
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 46,
                              height: 46,
                              decoration: BoxDecoration(
                                color: avatarColor,
                                borderRadius: BorderRadius.circular(13),
                              ),
                              child: Center(
                                child: Text(
                                  avatar,
                                  style: GoogleFonts.prompt(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    clientName.isNotEmpty
                                        ? clientName
                                        : 'ลูกความ',
                                    style: GoogleFonts.prompt(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                      color: const Color(0xFF0F172A),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 6),
                                  Wrap(
                                    spacing: 6,
                                    runSpacing: 6,
                                    children: [
                                      _todayChip(
                                        icon: Icons.today_rounded,
                                        label: 'นัดวันนี้',
                                        bg: const Color(0xFFEFF6FF),
                                        fg: const Color(0xFF0262EC),
                                      ),
                                      if (time.isNotEmpty)
                                        _todayChip(
                                          icon: Icons.schedule_rounded,
                                          label: time,
                                          bg: const Color(0xFFECFDF5),
                                          fg: const Color(0xFF059669),
                                        ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            Icon(
                              Icons.chevron_right_rounded,
                              color: Colors.grey[400],
                            ),
                          ],
                        ),
                        if (topic.isNotEmpty || subTopic.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 10),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (topic.isNotEmpty)
                                  Text(
                                    topic,
                                    style: GoogleFonts.prompt(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: const Color(0xFF1E293B),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                if (subTopic.isNotEmpty) ...[
                                  if (topic.isNotEmpty)
                                    const SizedBox(height: 2),
                                  Text(
                                    subTopic,
                                    style: GoogleFonts.prompt(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      color: const Color(0xFF64748B),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                        if (detail.isNotEmpty) ...[
                          const SizedBox(height: 10),
                          Text(
                            detail,
                            style: GoogleFonts.prompt(
                              fontSize: 12,
                              height: 1.45,
                              color: const Color(0xFF64748B),
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            if (date.isNotEmpty) ...[
                              Icon(Icons.calendar_month_rounded,
                                  size: 14, color: Colors.grey[500]),
                              const SizedBox(width: 4),
                              Text(
                                date,
                                style: GoogleFonts.prompt(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                            if (price.isNotEmpty) ...[
                              if (date.isNotEmpty) ...[
                                const SizedBox(width: 10),
                                Container(
                                  width: 1,
                                  height: 12,
                                  color: const Color(0xFFE2E8F0),
                                ),
                                const SizedBox(width: 10),
                              ],
                              Icon(Icons.payments_outlined,
                                  size: 14, color: Colors.grey[500]),
                              const SizedBox(width: 4),
                              Text(
                                '฿$price',
                                style: GoogleFonts.prompt(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF0F172A),
                                ),
                              ),
                            ],
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: isPaid
                                    ? const Color(0xFFECFDF5)
                                    : const Color(0xFFFFF7ED),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                isPaid ? 'ชำระแล้ว' : 'รอชำระ',
                                style: GoogleFonts.prompt(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: isPaid
                                      ? const Color(0xFF059669)
                                      : const Color(0xFFD97706),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _todayActionButton(
                          canStart: canStart,
                          joinResult: joinResult,
                          timeLabel: time.isNotEmpty ? time : windowLabel,
                          onStart: startConsult,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _todayActionButton({
    required bool canStart,
    required VideoCallJoinResult joinResult,
    required String timeLabel,
    required VoidCallback onStart,
  }) {
    if (canStart) {
      return SizedBox(
        width: double.infinity,
        height: 42,
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF0262EC), Color(0xFF0099FF)],
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onStart,
              borderRadius: BorderRadius.circular(12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.play_arrow_rounded,
                      color: Colors.white, size: 18),
                  const SizedBox(width: 6),
                  Text(
                    'เริ่มปรึกษา',
                    style: GoogleFonts.prompt(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    final isTooEarly = joinResult == VideoCallJoinResult.tooEarly;
    final bg = isTooEarly ? const Color(0xFFFFF7ED) : const Color(0xFFF1F5F9);
    final border =
        isTooEarly ? const Color(0xFFFDBA74) : const Color(0xFFCBD5E1);
    final fg = isTooEarly ? const Color(0xFFC2410C) : const Color(0xFF64748B);
    final icon = isTooEarly
        ? Icons.schedule_rounded
        : Icons.event_busy_rounded;
    final title = isTooEarly ? 'รอถึงเวลานัด' : 'เลยเวลานัดแล้ว';
    final subtitle = timeLabel.isNotEmpty
        ? (isTooEarly ? 'เริ่มได้ช่วง $timeLabel' : timeLabel)
        : (isTooEarly
            ? 'ปุ่มเริ่มปรึกษาจะเปิดเมื่อถึงเวลานัด'
            : 'ไม่สามารถเริ่มปรึกษาได้แล้ว');

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onStart,
        borderRadius: BorderRadius.circular(12),
        child: Ink(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: border),
          ),
          child: Row(
            children: [
              Icon(icon, size: 18, color: fg),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.prompt(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: fg,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: GoogleFonts.prompt(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: fg.withOpacity(0.85),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _todayChip({
    required IconData icon,
    required String label,
    required Color bg,
    required Color fg,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: fg),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.prompt(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: fg,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildJobRequestListMobile(BuildContext context, List<dynamic> jobs) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 0, 18, 8),
      child: Column(
        children: [
          for (int i = 0; i < jobs.length; i++) ...[
            if (i > 0) const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: _urgentJobCard(context, jobs[i]),
            ),
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
    final isBooking = (job['jobSource'] ?? 'urgent') == 'booking';

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: const Color.fromARGB(255, 221, 221, 221), width: 1),
        ),
        child: Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            onTap: () {
              final isPending = status == 'pending';
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (detailCtx) => LawyerJobDetailPage(
                    job: job,
                    onAccept: null,
                    onReject: null,
                  ),
                ),
              );
            },
            borderRadius: BorderRadius.circular(16),
            splashColor: const Color(0xFF0262EC).withOpacity(0.08),
            highlightColor: const Color(0xFF0262EC).withOpacity(0.04),
            child: Ink(
              decoration: BoxDecoration(
                  color: Colors.white, borderRadius: BorderRadius.circular(16)),
              child: IntrinsicHeight(
                child: Row(
                  children: [
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
                            Row(children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: Color(job['clientColor']),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Center(
                                  child: Text(job['clientAvatar'],
                                      style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold)),
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
                                            color: Color(0xFF1A2340))),
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
                                          fontWeight: FontWeight.w600)),
                                ],
                              ),
                            ),
                            const SizedBox(height: 10),
                            Row(children: [
                              Expanded(
                                child: Text(job['subTopic'],
                                    style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFF1A2340)),
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
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text('viewDetails'.tr(),
                                        style: const TextStyle(
                                            color: _kPrimary,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w700)),
                                    const SizedBox(width: 4),
                                    const Icon(Icons.arrow_forward_ios,
                                        size: 10, color: _kPrimary),
                                  ],
                                ),
                              ),
                            ]),
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
                                        Text('${job['date']} • ${job['time']}',
                                            style: const TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w700,
                                                color: Color(0xFF1A2340))),
                                        const SizedBox(height: 2),
                                        Text('consultingPeriod'.tr(),
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
          ),
        ),
      ),
    );
  }
}

// ─── Helpers (top-level) ──────────────────────────────────────────────
Map<String, dynamic> _caseStatusConfig(String status) {
  switch (status) {
    case '0':
      return {'label': 'ยกเลิกเคส', 'color': 0xFF9E9E9E};
    case '1':
      return {'label': 'รอทนายรับเคส', 'color': 0xFFD97706};
    case '2':
      return {'label': 'รอปรึกษา', 'color': 0xFF0262EC};
    case '3':
      return {'label': 'กำลังปรึกษา', 'color': 0xFF059669};
    case '4':
      return {'label': 'เสร็จสิ้น', 'color': 0xFF6366F1};
    default:
      return {'label': 'ไม่ทราบสถานะ', 'color': 0xFF9E9E9E};
  }
}

Map<String, dynamic> _appointmentToJob(dynamic appt) => {
      'id': appt['code'] ?? '',
      'jobSource': 'booking',
      'status': 'pending',
      'clientName': appt['clientName'] ?? '',
      'clientAvatar': ((appt['clientName'] ?? '') as String).isNotEmpty
          ? (appt['clientName'] as String).substring(0, 1)
          : '?',
      'clientColor': 0xFF0262EC,
      'topic': appt['title'] ?? '',
      'subTopic': appt['subCaseType'] ?? '',
      'requestedAt': appt['appointmentDate'] ?? '',
      'date': appt['appointmentDate'] ?? '',
      'time': appt['appointmentTime'] ?? '',
      'isApiCase': true,
    };

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
        'labelKey': 'accepted',
        'shadow': const Color(0xFF0262EC),
      },
    'pending' => {
        'colors': [const Color(0xFFD97706), const Color(0xFFF59E0B)],
        'icon': Icons.hourglass_top,
        'labelKey': 'pending',
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
        Text((config['labelKey'] as String).tr(),
            style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold)),
      ],
    ),
  );
}
