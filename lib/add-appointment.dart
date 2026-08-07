import 'package:LawyerOnline/booking/summary-page.dart';
import 'package:LawyerOnline/component/appbar.dart';
import 'package:LawyerOnline/component/app_dropdown.dart';
import 'package:LawyerOnline/component/dialog_service.dart';
import 'package:LawyerOnline/component/loading_service.dart';
import 'package:LawyerOnline/menu.dart';
import 'package:LawyerOnline/shared/api_provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:easy_localization/easy_localization.dart';

class AppAppointment extends StatefulWidget {
  AppAppointment({
    Key? key,
    this.model,
    this.title,
    this.lawyer,
    this.topic,
    this.subTopic,
    this.topicTitle,
    this.subTopicTitle,
  }) : super(key: key);

  dynamic model;
  String? title;
  String? topic;
  String? topicTitle;
  String? subTopic;
  String? subTopicTitle;
  dynamic lawyer;

  @override
  State<AppAppointment> createState() => _AppAppointmentState();
}

class _AppAppointmentState extends State<AppAppointment> {
  final TextEditingController titleController   = TextEditingController();
  final TextEditingController detailsController = TextEditingController();

  dynamic _selectedTopic;
  dynamic _selectedSubCase;

  DateTime _focusedDate = DateTime.now();
  DateTime? _selectedDate;
  String?   _selectedTime;

  // ── slot & day data จาก API ─────────────────────────────
  List<dynamic> _timeSlots      = [];
  List<dynamic> _lawyerOpenDays = [];
  bool _slotsLoading            = false;
  bool _scheduleLoaded          = false;
  int _slotRequestSeq           = 0;

  // ── topic list ──────────────────────────────────────────
  List<dynamic> _caseTypeList    = [];
  bool          isLoadingTopics  = true;

  final _thMonths = ['', 'ม.ค.', 'ก.พ.', 'มี.ค.', 'เม.ย.', 'พ.ค.', 'มิ.ย.',
      'ก.ค.', 'ส.ค.', 'ก.ย.', 'ต.ค.', 'พ.ย.', 'ธ.ค.'];
  final _thDays = ['อา', 'จ', 'อ', 'พ', 'พฤ', 'ศ', 'ส'];

  // ── can proceed ─────────────────────────────────────────
  bool get _hasIncomingTopic =>
      (widget.topic?.trim().isNotEmpty ?? false) ||
      (widget.topicTitle?.trim().isNotEmpty ?? false);

  bool get _hasIncomingSubTopic =>
      (widget.subTopic?.trim().isNotEmpty ?? false) ||
      (widget.subTopicTitle?.trim().isNotEmpty ?? false);

  bool get _topicHasSubTopics {
    if (_selectedTopic is! Map) return false;
    final raw =
        _selectedTopic['subTopics'] ?? _selectedTopic['subCase'];
    if (raw is! List) return false;
    return raw.whereType<Map>().any(
          (s) => (s['title']?.toString().trim() ?? '').isNotEmpty,
        );
  }

  bool get _hasTopic => _hasIncomingTopic || _selectedTopic != null;

  bool get _hasSubTopic {
    if (_hasIncomingSubTopic || _selectedSubCase != null) return true;
    // หัวข้อที่ไม่มีหัวข้อย่อย — ไม่ต้องบังคับเลือก
    if (_selectedTopic != null && !_topicHasSubTopics) return true;
    return false;
  }

  bool get _canSubmit =>
      _hasTopic &&
      _hasSubTopic &&
      _selectedDate != null &&
      _selectedTime != null;

  String get _topicCode =>
      _selectedTopic?['code']?.toString() ?? widget.topic?.trim() ?? '';
  String get _topicTitle =>
      _selectedTopic?['title']?.toString() ??
      widget.topicTitle?.trim() ??
      widget.topic?.trim() ??
      '';
  String get _subTopicCode =>
      _selectedSubCase?['code']?.toString() ?? widget.subTopic?.trim() ?? '';
  String get _subTopicTitle =>
      _selectedSubCase?['title']?.toString() ??
      widget.subTopicTitle?.trim() ??
      widget.subTopic?.trim() ??
      '';

  List<DateTime> get _daysInMonth {
    final first = DateTime(_focusedDate.year, _focusedDate.month, 1);
    final last  = DateTime(_focusedDate.year, _focusedDate.month + 1, 0);
    return List.generate(
        last.day, (i) => DateTime(first.year, first.month, i + 1));
  }

  // ── เช็คว่าทนายเปิดวันนั้นไหม ───────────────────────────
  bool _isDayOpenForLawyer(DateTime date) {
    if (_lawyerOpenDays.isEmpty) return true;
    final dayOfWeek = date.weekday % 7; // 0=อาทิตย์ ... 6=เสาร์
    final found = _lawyerOpenDays.firstWhere(
      (d) => d['day'] == dayOfWeek,
      orElse: () => null,
    );
    return found == null ? true : found['isOpen'] == true;
  }

  @override
  void initState() {
    super.initState();
    callReadTopic();
    // โหลด slot วันนี้ก่อน (ถ้ามี lawyer)
    if (widget.lawyer != null) {
      readTimeSlot(DateFormat('yyyy-MM-dd').format(DateTime.now()));
    }
  }

  @override
  void dispose() {
    titleController.dispose();
    detailsController.dispose();
    super.dispose();
  }

  Future<void> callReadTopic() async {
    try {
      final param = await postDio('$server/m/topic/read', {});
      setState(() {
        _caseTypeList = param['objectData'] is List
            ? List<dynamic>.from(param['objectData'] as List)
            : [];
        _resolveIncomingTopicSelection();
        isLoadingTopics = false;
      });
    } catch (_) {
      setState(() => isLoadingTopics = false);
    }
  }

  /// จับคู่ topic/subTopic ที่ส่งมาจากหน้าแรก (มักเป็น title) กับข้อมูล API
  void _resolveIncomingTopicSelection() {
    final topicKey = (widget.topic ?? widget.topicTitle ?? '')
        .trim()
        .replaceAll('\n', '');
    if (topicKey.isEmpty) return;

    dynamic matchedTopic;
    for (final item in _caseTypeList) {
      if (item is! Map) continue;
      final code = item['code']?.toString().trim() ?? '';
      final title = (item['title']?.toString() ?? '').trim().replaceAll('\n', '');
      if (code == topicKey || title == topicKey) {
        matchedTopic = item;
        break;
      }
    }
    if (matchedTopic == null) return;
    _selectedTopic = matchedTopic;

    final subKey = (widget.subTopic ?? widget.subTopicTitle ?? '')
        .trim()
        .replaceAll('\n', '');
    if (subKey.isEmpty) return;

    final rawSubs = matchedTopic['subTopics'];
    final subs = (rawSubs is List ? rawSubs : const <dynamic>[])
        .whereType<Map>()
        .toList();
    for (final s in subs) {
      final code = s['code']?.toString().trim() ?? '';
      final title = (s['title']?.toString() ?? '').trim();
      if (code == subKey || title == subKey) {
        _selectedSubCase = Map<String, dynamic>.from(s);
        break;
      }
    }
  }

  Future<void> readTimeSlot(String date) async {
    if (widget.lawyer == null) return;
    final requestSeq = ++_slotRequestSeq;
    if (mounted) setState(() => _slotsLoading = true);
    try {
      final param = await postDio(
        '$server/m/register/checkSlot',
        {
          'lawyerCode': widget.lawyer is Map
              ? widget.lawyer['code']
              : widget.lawyer.toString(),
          'date': date,
        },
      );

      if (!mounted || requestSeq != _slotRequestSeq) return;

      final objectData = param['objectData'];
      if (objectData is! Map) {
        setState(() {
          _timeSlots = [];
          _slotsLoading = false;
        });
        return;
      }

      // โหลด lawyerSchedule ครั้งแรกครั้งเดียว
      if (!_scheduleLoaded && objectData['lawyerSchedule'] != null) {
        final schedule = objectData['lawyerSchedule'];
        _lawyerOpenDays = List<dynamic>.from(schedule['days'] ?? []);
        _scheduleLoaded = true;
      }

      final dateCheck = objectData['dateCheck'];
      final slots = List<dynamic>.from(dateCheck?['slots'] ?? []);

      setState(() {
        _timeSlots = slots;
        if (_selectedTime != null) {
          final stillValid = slots.any((s) =>
              s is Map &&
              s['title']?.toString() == _selectedTime &&
              (s['available'] == true ||
                  s['isOpen'] == true ||
                  s['isLawyerOpen'] == true));
          if (!stillValid) _selectedTime = null;
        }
        _slotsLoading = false;
      });
    } catch (e) {
      print('readTimeSlot error: $e');
      if (!mounted || requestSeq != _slotRequestSeq) return;
      setState(() => _slotsLoading = false);
    }
  }

  // ═══════════════════════════════════════════════════════
  //  BUILD
  // ═══════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    const topicColor = Color(0xFF0262EC);

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      behavior: HitTestBehavior.opaque,
      child: Scaffold(
        backgroundColor: const Color(0xFFEEF2F5),
        appBar: appBar(
          title: widget.title ?? 'appointmentScheduleTitle'.tr(),
          backBtn: true,
          rightBtn: false,
          backAction: () => Navigator.pop(context, false),
          rightAction: () {},
        ),
        body: isLoadingTopics
            ? _loadingState()
            : Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // ── เลือกประเภทหัวข้อ ───────────
                          // ซ่อนเฉพาะเมื่อส่งหัวข้อมาแล้ว (เช่น จากหน้าแรก)
                          if (!_hasIncomingTopic) ...[
                            _buildTopicSection(topicColor),
                            const SizedBox(height: 16),
                          ] else if (_selectedTopic != null) ...[
                            _buildIncomingTopicChip(topicColor),
                            const SizedBox(height: 16),
                          ],

                          // ── หัวข้อย่อย ──────────────────
                          // โชว์เมื่อมีหัวข้อแล้ว แต่ยังไม่มีหัวข้อย่อยจากภายนอก
                          if (_selectedTopic != null &&
                              _topicHasSubTopics &&
                              !_hasIncomingSubTopic) ...[
                            _buildSubCaseDropdown(topicColor),
                            const SizedBox(height: 16),
                          ],

                          // ── วันที่ทนายเปิด (banner) ──────
                          _buildOpenDaysBanner(),

                          // ── Calendar ─────────────────────
                          _buildCalendarCard(),
                          const SizedBox(height: 16),

                          // ── Time Slots ───────────────────
                          if (_selectedDate != null) ...[
                            _buildTimeSlots(),
                            const SizedBox(height: 16),
                          ],

                          // ── รายละเอียดเพิ่มเติม ──────────
                          _buildTextArea(
                            title: 'additionalDetails'.tr(),
                            controller: detailsController,
                          ),
                          const SizedBox(height: 32),
                        ],
                      ),
                    ),
                  ),
                  _buildBottomButton(topicColor),
                ],
              ),
      ),
    );
  }

  // ── Banner วันที่เปิด ────────────────────────────────────
  Widget _buildOpenDaysBanner() {
    if (_lawyerOpenDays.isEmpty) return const SizedBox(height: 14);
    final openDays = _lawyerOpenDays
        .where((d) => d['isOpen'] == true)
        .map((d) => d['title']?.toString() ?? '')
        .where((t) => t.isNotEmpty)
        .toList();
    if (openDays.isEmpty) return const SizedBox(height: 14);

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFEEF4FF),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF0262EC).withOpacity(0.2)),
        ),
        child: Row(children: [
          const Icon(Icons.calendar_today_rounded,
              size: 14, color: Color(0xFF0262EC)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'bookingLawyerOpenDays'.tr(args: [openDays.join(', ')]),
              style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF0262EC),
                  fontWeight: FontWeight.w500),
            ),
          ),
        ]),
      ),
    );
  }

  // ════════════════════════════════════════════════════════
  //  Topic Grid
  // ════════════════════════════════════════════════════════
  Widget _topicImage(String imageUrl, {double size = 50}) {
    final url = imageUrl.trim();
    if (url.isEmpty) {
      return Icon(Icons.gavel_rounded,
          size: size * 0.7, color: const Color(0xFF94A3B8));
    }
    if (url.startsWith('assets/')) {
      return Image.asset(url, width: size, height: size, fit: BoxFit.contain);
    }
    return CachedNetworkImage(
      imageUrl: url,
      width: size,
      height: size,
      fit: BoxFit.contain,
      memCacheWidth: 160,
      placeholder: (_, __) => SizedBox(
        width: size,
        height: size,
        child: const Center(
          child: SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      ),
      errorWidget: (_, __, ___) => Icon(Icons.gavel_rounded,
          size: size * 0.7, color: const Color(0xFF94A3B8)),
    );
  }

  Widget _buildTopicSection(Color topicColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _fieldLabel('appointmentTopicToConsult'.tr(), required: true),
        const SizedBox(height: 10),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            childAspectRatio: 0.9,
          ),
          itemCount: _caseTypeList.length,
          itemBuilder: (_, i) {
            final item       = _caseTypeList[i];
            final isSelected = _selectedTopic?['code'] == item['code'];

            return GestureDetector(
              onTap: () => setState(() {
                _selectedTopic   = isSelected ? null : item;
                _selectedSubCase = null;
              }),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                decoration: BoxDecoration(
                  color: isSelected
                      ? topicColor.withOpacity(0.1)
                      : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected ? topicColor : const Color(0xFFE2E8F4),
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                              color: topicColor.withOpacity(0.18),
                              blurRadius: 8,
                              offset: const Offset(0, 2))
                        ]
                      : [
                          BoxShadow(
                              color: Colors.black.withOpacity(0.04),
                              blurRadius: 4,
                              offset: const Offset(0, 1))
                        ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _topicImage(item['imageUrl']?.toString() ?? ''),
                    const SizedBox(height: 4),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 3),
                      child: Text(
                        item['title']?.toString() ?? '',
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: isSelected
                              ? FontWeight.w700
                              : FontWeight.w500,
                          color: isSelected
                              ? topicColor
                              : const Color(0xFF5B6E8A),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  // ════════════════════════════════════════════════════════
  //  Sub-case Dropdown
  // ════════════════════════════════════════════════════════
  Widget _buildIncomingTopicChip(Color topicColor) {
    final title = _topicTitle;
    if (title.isEmpty) return const SizedBox.shrink();
    final subTitle = _subTopicTitle.trim();
    final hasSub = subTitle.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _fieldLabel('appointmentTopicToConsult'.tr(), required: true),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: topicColor.withOpacity(0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: topicColor.withOpacity(0.25)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 1),
                child: Icon(Icons.label_rounded, size: 18, color: topicColor),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: hasSub
                    ? Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                              text: title,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: topicColor,
                                height: 1.35,
                              ),
                            ),
                            TextSpan(
                              text: ' > ',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: topicColor.withOpacity(0.55),
                                height: 1.35,
                              ),
                            ),
                            TextSpan(
                              text: subTitle,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: topicColor.withOpacity(0.85),
                                height: 1.35,
                              ),
                            ),
                          ],
                        ),
                        softWrap: true,
                      )
                    : Text(
                        title,
                        softWrap: true,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: topicColor,
                          height: 1.35,
                        ),
                      ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSubCaseDropdown(Color color) {
    final rawSubs =
        _selectedTopic['subTopics'] ?? _selectedTopic['subCase'];
    final subTopics = (rawSubs is List ? rawSubs : <dynamic>[])
        .whereType<Map>()
        .map((s) => Map<String, dynamic>.from(s))
        .where((s) => (s['title']?.toString().trim() ?? '').isNotEmpty)
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _fieldLabel('subTopicLabel'.tr(), required: true),
        const SizedBox(height: 6),
        AppDropdownField<String>(
          value: _selectedSubCase?['code']?.toString(),
          hint: 'selectSubTopic'.tr(),
          prefixIcon: Icons.subdirectory_arrow_right_rounded,
          accentColor: color,
          items: subTopics
              .map(
                (s) => DropdownMenuItem<String>(
                  value: s['code']?.toString(),
                  child: Text(
                    s['title']?.toString() ?? '',
                    style: AppDropdownStyles.itemStyle(),
                  ),
                ),
              )
              .toList(),
          onChanged: (val) {
            final sub = subTopics.firstWhere(
              (s) => s['code']?.toString() == val,
              orElse: () => <String, dynamic>{},
            );
            setState(() => _selectedSubCase =
                sub.isEmpty ? null : sub);
          },
        ),
      ],
    );
  }

  // ════════════════════════════════════════════════════════
  //  Calendar
  // ════════════════════════════════════════════════════════
  Widget _buildCalendarCard() {
    final days         = _daysInMonth;
    final firstWeekday = days.first.weekday % 7;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _fieldLabel('appointmentDateTitle'.tr(), required: true),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2))
            ],
          ),
          child: Column(children: [
            // Month nav
            Row(children: [
              GestureDetector(
                onTap: () => setState(() => _focusedDate =
                    DateTime(_focusedDate.year, _focusedDate.month - 1, 1)),
                child: Container(
                  width: 32, height: 32,
                  decoration: BoxDecoration(
                      color: const Color(0xFFF5F7FA),
                      borderRadius: BorderRadius.circular(8)),
                  child: const Icon(Icons.chevron_left_rounded,
                      color: Color(0xFF1A2340), size: 20),
                ),
              ),
              Expanded(
                child: Text(
                  '${_thMonths[_focusedDate.month]} ${_focusedDate.year + 543}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: Color(0xFF1A2340)),
                ),
              ),
              GestureDetector(
                onTap: () => setState(() => _focusedDate =
                    DateTime(_focusedDate.year, _focusedDate.month + 1, 1)),
                child: Container(
                  width: 32, height: 32,
                  decoration: BoxDecoration(
                      color: const Color(0xFFF5F7FA),
                      borderRadius: BorderRadius.circular(8)),
                  child: const Icon(Icons.chevron_right_rounded,
                      color: Color(0xFF1A2340), size: 20),
                ),
              ),
            ]),
            const SizedBox(height: 12),

            // Day headers
            Row(
              children: _thDays
                  .map((d) => Expanded(
                        child: Text(d,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey[400],
                                fontWeight: FontWeight.w600)),
                      ))
                  .toList(),
            ),
            const SizedBox(height: 8),

            // Grid
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 7, childAspectRatio: 1),
              itemCount: firstWeekday + days.length,
              itemBuilder: (_, i) {
                if (i < firstWeekday) return const SizedBox();
                final day        = days[i - firstWeekday];
                final isSelected = _selectedDate != null &&
                    day.day == _selectedDate!.day &&
                    day.month == _selectedDate!.month;
                final isPast = day.isBefore(
                    DateTime.now().subtract(const Duration(days: 1)));
                final isLawyerClosed =
                    _scheduleLoaded && !_isDayOpenForLawyer(day);
                final isDisabled = isPast || isLawyerClosed;

                return GestureDetector(
                  onTap: isDisabled
                      ? null
                      : () {
                          setState(() {
                            _selectedDate = day;
                            _selectedTime = null;
                          });
                          readTimeSlot(
                              DateFormat('yyyy-MM-dd').format(day));
                        },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    margin: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFF0262EC)
                          : isLawyerClosed
                              ? const Color(0xFFFFF0F0)
                              : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                      border: isLawyerClosed && !isPast
                          ? Border.all(color: Colors.red.withOpacity(0.2))
                          : null,
                    ),
                    child: Center(
                      child: Text(
                        '${day.day}',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: isSelected
                              ? FontWeight.w700
                              : FontWeight.w400,
                          color: isSelected
                              ? Colors.white
                              : isDisabled
                                  ? Colors.grey[300]
                                  : const Color(0xFF1A2340),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ]),
        ),
      ],
    );
  }

  // ════════════════════════════════════════════════════════
  //  Time Slots
  // ════════════════════════════════════════════════════════
  Widget _buildTimeSlots() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _fieldLabel('bookingSelectTime'.tr(), required: true),
        const SizedBox(height: 10),
        if (_slotsLoading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 32),
            child: Center(child: DotsLoader(color: Color(0xFF0262EC))),
          )
        else if (_timeSlots.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Center(
              child: Text('bookingNoSlotsToday'.tr(),
                  style: TextStyle(fontSize: 13, color: Colors.grey[400])),
            ),
          )
        else ...[
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 3.2),
            itemCount: _timeSlots.length,
            itemBuilder: (_, i) {
              final slot       = _timeSlots[i];
              final isAvail    = slot['available'] == true ||
                  (slot['available'] != false &&
                      (slot['isOpen'] == true || slot['isLawyerOpen'] == true) &&
                      slot['isBooked'] != true);
              final slotTitle  = slot['title']?.toString() ?? '';
              final isSelected = _selectedTime == slotTitle;

              return GestureDetector(
                onTap: isAvail
                    ? () => setState(() => _selectedTime = slotTitle)
                    : null,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFF0262EC)
                        : !isAvail
                            ? const Color(0xFFF5F7FA)
                            : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: isSelected
                            ? const Color(0xFF0262EC)
                            : const Color(0xFFEEF2F5)),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                                color: const Color(0xFF0262EC).withOpacity(0.25),
                                blurRadius: 8,
                                offset: const Offset(0, 2))
                          ]
                        : [],
                  ),
                  child: Center(
                    child: Text(
                      slot['title'].toString(),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isSelected
                            ? Colors.white
                            : !isAvail
                                ? Colors.grey[300]
                                : const Color(0xFF1A2340),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 8),
          // Legend
          Row(children: [
            Container(
                width: 10, height: 10,
                decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(3))),
            const SizedBox(width: 6),
            Text('unavailableNow'.tr(),
                style: TextStyle(fontSize: 11, color: Colors.grey[400])),
            const SizedBox(width: 16),
            Container(
                width: 10, height: 10,
                decoration: BoxDecoration(
                    color: const Color(0xFF0262EC),
                    borderRadius: BorderRadius.circular(3))),
            const SizedBox(width: 6),
            Text('bookingSelected'.tr(),
                style: TextStyle(fontSize: 11, color: Colors.grey[400])),
            const SizedBox(width: 16),
            Container(
                width: 10, height: 10,
                decoration: BoxDecoration(
                    color: const Color(0xFFFFF0F0),
                    borderRadius: BorderRadius.circular(3),
                    border:
                        Border.all(color: Colors.red.withOpacity(0.3)))),
            const SizedBox(width: 6),
            Text('bookingLawyerClosedToday'.tr(),
                style: TextStyle(fontSize: 11, color: Colors.grey[400])),
          ]),
        ],
      ],
    );
  }

  // ════════════════════════════════════════════════════════
  //  Bottom Button
  // ════════════════════════════════════════════════════════
  Widget _buildBottomButton(Color topicColor) {
    return Container(
      padding: EdgeInsets.fromLTRB(
          16, 10, 16, MediaQuery.of(context).padding.bottom + 14),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
              color: Color(0x12000000),
              blurRadius: 10,
              offset: Offset(0, -3))
        ],
      ),
      child: GestureDetector(
        onTap: _canSubmit
            ? () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => SummaryPage(
                      lawyer: widget.lawyer,
                      topic: _topicCode,
                      topicTitle: _topicTitle,
                      subTopic: _subTopicCode,
                      subTopicTitle: _subTopicTitle,
                      time: _selectedTime!,
                      date: _selectedDate,
                      details: detailsController.text,
                    ),
                  ),
                )
            : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: 52,
          decoration: BoxDecoration(
            gradient: _canSubmit
                ? LinearGradient(
                    colors: [topicColor, topicColor.withOpacity(0.8)],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight)
                : null,
            color: _canSubmit ? null : const Color(0xFFCDD5E0),
            borderRadius: BorderRadius.circular(14),
            boxShadow: _canSubmit
                ? [
                    BoxShadow(
                        color: topicColor.withOpacity(0.35),
                        blurRadius: 12,
                        offset: const Offset(0, 4))
                  ]
                : null,
          ),
          child: Center(
            child: Text(
              'appointmentContinue'.tr(),
              style: TextStyle(
                color: _canSubmit ? Colors.white : Colors.grey[400],
                fontWeight: FontWeight.w700,
                fontSize: 15,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ════════════════════════════════════════════════════════
  //  Shared Widgets
  // ════════════════════════════════════════════════════════
  Widget _loadingState() {
    return const AppLoadingView(showDots: false);
  }

  Widget _fieldLabel(String label, {bool required = false}) {
    return RichText(
      text: TextSpan(
        text: label,
        style: GoogleFonts.prompt(color: const Color(0xFF0262EC), fontSize: 12),
        children: [
          if (required)
            TextSpan(
              text: ' *',
              style: GoogleFonts.prompt(
                  color: const Color(0xFFDB2E26), fontSize: 12),
            ),
        ],
      ),
    );
  }

  InputDecoration _inputDecor({Widget? prefixIcon}) {
    return InputDecoration(
      prefixIcon: prefixIcon,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFECEDF0))),
      enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFECEDF0))),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              const BorderSide(color: Color(0xFF0262EC), width: 1.5)),
      fillColor: const Color(0xFFFAFAFA),
      filled: true,
    );
  }

  Widget _buildTextArea({
    required String title,
    required TextEditingController controller,
    bool required = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _fieldLabel(title, required: required),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          maxLines: null,
          minLines: 4,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.all(14),
            hintText: 'appointmentDetailsHint'.tr(),
            hintStyle:
                const TextStyle(color: Colors.grey, fontSize: 13),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                    const BorderSide(color: Color(0xFFECEDF0))),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                    const BorderSide(color: Color(0xFFECEDF0))),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                    color: Color(0xFF0262EC), width: 1.5)),
          ),
        ),
      ],
    );
  }
}

class _Palette {
  final Color  primary;
  final Color  secondary;
  final String emoji;
  const _Palette(this.primary, this.secondary, this.emoji);
}