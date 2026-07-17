import 'dart:convert';

import 'package:LawyerOnline/appointment-details-lawyer.dart';
import 'package:LawyerOnline/repositories/lawyer_repository.dart';
import 'package:LawyerOnline/shared/responsive/res_layout.dart';
import 'package:LawyerOnline/shared/responsive/responsive_values.dart';
import 'package:LawyerOnline/widgets/calendar/all_events_section.dart';
import 'package:LawyerOnline/widgets/calendar/calendar_theme.dart';
import 'package:LawyerOnline/widgets/calendar/timeline_section.dart';
import 'package:LawyerOnline/component/loading_service.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:LawyerOnline/models/lawyer/lawyer_jobs_store.dart';
import 'package:LawyerOnline/models/user_profile_store.dart';
import 'package:LawyerOnline/repositories/lawyer_appointment_repository.dart';

class CalendarPage extends StatefulWidget {
  CalendarPage({super.key, this.isBtnBack = false, this.isTabActive = false,});

  bool isBtnBack;
  final bool isTabActive;

  @override
  _CalendarPageState createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage>
    with TickerProviderStateMixin {
  final storage = FlutterSecureStorage();

  bool _showMonthCalendar = false;
  bool _showAllView = false;

  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();

  final LawyerAppointmentRepository _appointmentRepository =
      const ApiLawyerAppointmentRepository();
  List<dynamic> _appointments = const [];
  bool _isLoadingAppointments = false;
  String? _appointmentLoadError;

  Map<DateTime, List<dynamic>> get itemEvents =>
      CaseAppointmentMapper.eventMapFromAppointments(_appointments);

  AnimationController? _fadeCtrl;
  Animation<double>? _fadeAnim;
  AnimationController? _calPanelCtrl;

  final ScrollController _timelineScroll = ScrollController();
  final ScrollController _allViewScroll = ScrollController();

  @override
  void initState() {
    super.initState();
    LawyerJobsStore.instance.addListener(_onJobsChanged);
    _fadeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 450));
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl!, curve: Curves.easeOut);
    _fadeCtrl!.forward();
    _calPanelCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 300));
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToCurrentHour());
    _loadAppointments();
    storage.read(key: 'calendarShowAllView').then((val) {
      if (val == 'true' && mounted) setState(() => _showAllView = true);
    });
  }

  @override
  void dispose() {
    LawyerJobsStore.instance.removeListener(_onJobsChanged);
    _fadeCtrl?.dispose();
    _calPanelCtrl?.dispose();
    _timelineScroll.dispose();
    _allViewScroll.dispose();
    super.dispose();
  }

  void _onJobsChanged() {
    // store เปลี่ยน → rebuild UI จากข้อมูลที่มี ไม่ยิง API ซ้ำ
    // (home refresh จะอัปเดต LawyerJobsStore บ่อย ทำให้เคยวนโหลดปฏิทินไม่จบ)
    if (mounted) setState(() {});
  }

  Future<void> _loadAppointments() async {
    final lawyerCode = UserProfileStore.instance.code.trim();

    if (lawyerCode.isEmpty) {
      return;
    }

    final localAppointments =
        LawyerJobsStore.instance.bookingAppointmentsForLawyer(lawyerCode);

    if (_isLoadingAppointments) {
      if (localAppointments.isNotEmpty && mounted) {
        setState(() {
          _appointments = CaseAppointmentMapper.mergeAppointments(
            _appointments,
            localAppointments,
          );
        });
      }
      return;
    }

    setState(() {
      if (localAppointments.isNotEmpty) {
        _appointments = CaseAppointmentMapper.mergeAppointments(
          _appointments,
          localAppointments,
        );
      }
      _isLoadingAppointments = true;
      _appointmentLoadError = null;
    });

    try {
      final realAppointments =
          await _appointmentRepository.readAppointmentsForLawyer(lawyerCode);

      if (!mounted) return;

      setState(() {
        _appointments = CaseAppointmentMapper.mergeAppointments(
          realAppointments,
          LawyerJobsStore.instance.bookingAppointmentsForLawyer(lawyerCode),
        );

        _isLoadingAppointments = false;
        _appointmentLoadError = null;
      });
    } catch (e, st) {
      if (!mounted) return;

      final fallbackAppointments =
          LawyerJobsStore.instance.bookingAppointmentsForLawyer(lawyerCode);

      setState(() {
        _appointments = fallbackAppointments;
        _appointmentLoadError =
            fallbackAppointments.isEmpty ? 'genericError'.tr() : null;
        _isLoadingAppointments = false;
      });

      if (mounted && fallbackAppointments.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('ไม่สามารถโหลดนัดหมายได้'),
            backgroundColor: Colors.red[600],
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  void _scrollToCurrentHour() {
    final now = DateTime.now();
    final offset = ((now.hour - kStartHour) - 1) * kHourHeight;
    if (_timelineScroll.hasClients) {
      _timelineScroll.animateTo(
        offset.clamp(0.0, _timelineScroll.position.maxScrollExtent),
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeOut,
      );
    }
  }

  void _scrollAllViewToToday() {
    final sortedKeys = itemEvents.keys.toList()..sort();
    if (sortedKeys.isEmpty) return;
    final today = DateTime.now();
    final todayKey = DateTime(today.year, today.month, today.day);

    int targetIndex = 0;
    bool hasToday = false;

    for (int i = 0; i < sortedKeys.length; i++) {
      if (isSameDay(sortedKeys[i], todayKey)) {
        targetIndex = i;
        hasToday = true;
        break;
      }
      if (sortedKeys[i].isAfter(todayKey)) {
        targetIndex = i;
        break;
      }
      targetIndex = i;
    }

    double offset = 8.0;
    for (int i = 0; i < targetIndex; i++) {
      final evCount = itemEvents[sortedKeys[i]]?.length ?? 0;
      offset += 72 + (evCount * 88) + 16;
    }

    if (_allViewScroll.hasClients) {
      _allViewScroll.animateTo(
        offset.clamp(0.0, _allViewScroll.position.maxScrollExtent),
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeOut,
      );
    }

    if (!hasToday) {
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('calendar.todayNoAppt'.tr(),
            style: GoogleFonts.prompt(fontSize: 13, color: Colors.white)),
        backgroundColor: kPrimary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        duration: const Duration(seconds: 2),
      ));
    }
  }

  void _toggleCalendarPanel() {
    final closing = _showMonthCalendar;
    setState(() {
      _showMonthCalendar = !_showMonthCalendar;
      if (closing) _focusedDay = _selectedDay;
    });
    if (_showMonthCalendar) {
      _calPanelCtrl?.forward();
    } else {
      _calPanelCtrl?.reverse();
    }
  }

  List<dynamic> _getEventsForDay(DateTime day) {
    final key = DateTime(day.year, day.month, day.day);
    return itemEvents[key] ?? [];
  }

  int getHashCode(DateTime key) =>
      key.day * 1000000 + key.month * 10000 + key.year;

  void _navigateToEvent(dynamic ev) async {
    if (ev == null) return;

    if (ev is! Map) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ข้อมูลนัดหมายผิดพลาด')),
      );
      return;
    }

    final Map<String, dynamic> result = {
      ...?ev as Map<String, dynamic>,
      ...(ev['rawCase'] as Map<String, dynamic>?) ?? {},
    };
    result.remove('rawCase');

    if (result.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ไม่พบข้อมูลนัดหมาย')),
      );
      return;
    }

    try {
      final refreshed = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => AppointmentDetailsLawyer(model: result),
            ),
          ) as bool? ??
          false;

      if (refreshed && mounted) {
        _loadAppointments();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('เกิดข้อผิดพลาด: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = ResponsiveLayout.isDesktop(context);

    return Scaffold(
      backgroundColor: kBg,
      appBar: isDesktop ? null : _buildAppBar(),
      body: isDesktop ? _buildDesktopBody() : _buildMobileBody(),
    );
  }

  Widget _buildDesktopBody() {
    final hPad = RV.pagePadding(context);

    return FadeTransition(
      opacity: _fadeAnim ?? const AlwaysStoppedAnimation(1.0),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: hPad, vertical: 24),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 500,
              child: Column(
                children: [
                  _buildDesktopCalendarHeader(),
                  const SizedBox(height: 12),
                  Expanded(
                    child: _showAllView
                        ? AllAppointmentsViewDesktop(
                            itemEvents: itemEvents,
                            scrollController: _allViewScroll,
                            onEventTap: _navigateToEvent,
                          )
                        : _buildDesktopLeftPanel(),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 24),
            Expanded(
              child: Column(
                children: [
                  _buildDesktopRightHeader(),
                  const SizedBox(height: 12),
                  _calendarStatusBanner(),
                  if (_isLoadingAppointments || _appointmentLoadError != null)
                    const SizedBox(height: 12),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        decoration: BoxDecoration(
                          color: kBg,
                          border: Border.all(color: kBorder),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: TimelineView(
                          selectedDay: _selectedDay,
                          events: _getEventsForDay(_selectedDay),
                          scrollController: _timelineScroll,
                          onEventTap: _navigateToEvent,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDesktopCalendarHeader() {
    final monthLabel =
        '${'calendar.monthShort.${_focusedDay.month}'.tr()} ${calYearLabel(_focusedDay.year)}';

    return Row(
      children: [
        Text(monthLabel,
            style: GoogleFonts.prompt(
                color: kText, fontSize: 18, fontWeight: FontWeight.w700)),
        const Spacer(),
        _iconBtn(
          _showAllView
              ? Icons.calendar_today_rounded
              : Icons.format_list_bulleted_rounded,
          () {
            final next = !_showAllView;
            setState(() => _showAllView = next);
            storage.write(key: 'calendarShowAllView', value: next.toString());
          },
          active: _showAllView,
        ),
        const SizedBox(width: 8),
        _iconBtn(Icons.today_rounded, () {
          if (_showAllView) {
            _scrollAllViewToToday();
          } else {
            setState(() {
              _selectedDay = DateTime.now();
              _focusedDay = DateTime.now();
            });
            WidgetsBinding.instance
                .addPostFrameCallback((_) => _scrollToCurrentHour());
          }
        }),
      ],
    );
  }

  Widget _buildDesktopRightHeader() {
    final isToday = isSameDay(_selectedDay, DateTime.now());
    final dayLabel =
        '${'calendar.dayPrefix'.tr()}${'calendar.dayFull.${_selectedDay.weekday}'.tr()} ${_selectedDay.day} '
        '${'calendar.monthFull.${_selectedDay.month}'.tr()} ${calYearLabel(_selectedDay.year)}';
    final events = _getEventsForDay(_selectedDay);

    return Row(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(dayLabel,
                style: GoogleFonts.prompt(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: isToday ? kPrimary : kText)),
            if (events.isNotEmpty)
              Text('${events.length} ${'calendar.apptCount'.tr()}',
                  style: GoogleFonts.prompt(fontSize: 12, color: kSub)),
          ],
        ),
        const Spacer(),
        _iconBtn(Icons.chevron_left_rounded, () {
          setState(() {
            _selectedDay = _selectedDay.subtract(const Duration(days: 1));
            _focusedDay = _selectedDay;
          });
        }),
        const SizedBox(width: 6),
        _iconBtn(Icons.chevron_right_rounded, () {
          setState(() {
            _selectedDay = _selectedDay.add(const Duration(days: 1));
            _focusedDay = _selectedDay;
          });
        }),
      ],
    );
  }

  Widget _buildDesktopLeftPanel() {
    return Container(
      decoration: BoxDecoration(
        color: kBg,
        border: Border.all(color: kBorder),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: MonthCalendarPanel(
              focusedDay: _focusedDay,
              selectedDay: _selectedDay,
              getEventsForDay: _getEventsForDay,
              onDaySelected: (s, f) => setState(() {
                _selectedDay = s;
                _focusedDay = f;
              }),
              onPageChanged: (f) => setState(() => _focusedDay = f),
            ),
          ),
          const Divider(height: 1, color: kBorder),
          DayEventListDesktop(
            events: _getEventsForDay(_selectedDay),
            onEventTap: _navigateToEvent,
          ),
        ],
      ),
    );
  }

  Widget _buildMobileBody() {
    return RefreshIndicator(
      color: const Color(0xFF0262EC),
      onRefresh: _loadAppointments,
      child: IndexedStack(
        index: _showAllView ? 1 : 0,
        children: [
          FadeTransition(
            opacity: _fadeAnim ?? const AlwaysStoppedAnimation(1.0),
            child: Column(
              children: [
                AnimatedSize(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  child: _showMonthCalendar
                      ? MonthCalendarPanel(
                          focusedDay: _focusedDay,
                          selectedDay: _selectedDay,
                          getEventsForDay: _getEventsForDay,
                          onDaySelected: (s, f) => setState(() {
                            _selectedDay = s;
                            _focusedDay = f;
                          }),
                          onPageChanged: (f) =>
                              setState(() => _focusedDay = f),
                        )
                      : WeekStrip(
                          focusedDay: _focusedDay,
                          selectedDay: _selectedDay,
                          getEventsForDay: _getEventsForDay,
                          onDaySelected: (d) => setState(() {
                            _selectedDay = d;
                            _focusedDay = d;
                          }),
                        ),
                ),
                ToggleArrow(
                  showMonthCalendar: _showMonthCalendar,
                  onTap: _toggleCalendarPanel,
                ),
                _calendarStatusBanner(),
                DayEventListMobile(
                  events: _getEventsForDay(_selectedDay),
                  onEventTap: _navigateToEvent,
                ),
                Expanded(
                  child: TimelineView(
                    selectedDay: _selectedDay,
                    events: _getEventsForDay(_selectedDay),
                    scrollController: _timelineScroll,
                    onEventTap: _navigateToEvent,
                  ),
                ),
              ],
            ),
          ),
          AllAppointmentsViewMobile(
            itemEvents: itemEvents,
            scrollController: _allViewScroll,
            onEventTap: _navigateToEvent,
          ),
        ],
      ),
    );
  }

  Widget _calendarStatusBanner() {
    if (_isLoadingAppointments) {
      return const AppLoadingInline(height: 48, size: 24, padding: EdgeInsets.symmetric(vertical: 8));
    }

    final error = _appointmentLoadError;
    if (error == null || error.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Text(
        error,
        textAlign: TextAlign.center,
        style: GoogleFonts.prompt(fontSize: 13, color: kSub),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    final monthLabel =
        '${'calendar.monthFull.${_focusedDay.month}'.tr()} ${calYearLabel(_focusedDay.year)}';

    return AppBar(
      backgroundColor: kBg,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      automaticallyImplyLeading: false,
      titleSpacing: 0,
      iconTheme: const IconThemeData(color: kText),
      title: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            // const SizedBox(width: 12),

            widget.isBtnBack
                ? GestureDetector(
                    onTap: goBack,
                    child: Container(
                      width: 40,
                      height: 40,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFAFAFA),
                        shape: BoxShape.circle,
                        border: Border.all(
                            width: 1, color: const Color(0xFFDBDBDB)),
                      ),
                      child: const Icon(Icons.arrow_back_ios_new, size: 15),
                    ),
                  )
                : Text(monthLabel,
                    style: GoogleFonts.prompt(
                        color: kText,
                        fontSize: 17,
                        fontWeight: FontWeight.w600)),
            const Spacer(),
            _iconBtn(
              _showAllView
                  ? Icons.calendar_today_rounded
                  : Icons.format_list_bulleted_rounded,
              () {
                final next = !_showAllView;
                setState(() => _showAllView = next);
                storage.write(
                    key: 'calendarShowAllView', value: next.toString());
              },
              active: _showAllView,
            ),
            const SizedBox(width: 6),
            _iconBtn(Icons.today_rounded, () {
              if (_showAllView) {
                _scrollAllViewToToday();
              } else {
                setState(() {
                  _selectedDay = DateTime.now();
                  _focusedDay = DateTime.now();
                });
                WidgetsBinding.instance
                    .addPostFrameCallback((_) => _scrollToCurrentHour());
              }
            }),
            const SizedBox(width: 6),
          ],
        ),
      ),
    );
  }

  Widget _iconBtn(IconData icon, VoidCallback onTap, {bool active = false}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: active ? kPrimary : kSurface,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: active ? Colors.white : kSub, size: 18),
      ),
    );
  }

  void goBack() async {
    Navigator.pop(context, false);
  }
}
