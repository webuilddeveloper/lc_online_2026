import 'package:LawyerOnline/component/appbar.dart';
import 'package:LawyerOnline/component/dialog_service.dart';
import 'package:LawyerOnline/models/user_profile_store.dart';
import 'package:LawyerOnline/subscribe/lawyer-subscrile.dart';
import 'package:LawyerOnline/models/lawyer/lawyer_profile_store.dart';
import 'package:LawyerOnline/shared/api_provider.dart';
import 'package:LawyerOnline/shared/app_typography.dart';
import 'package:LawyerOnline/component/loading_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:easy_localization/easy_localization.dart';

class ConsultationSchedule extends StatefulWidget {
  ConsultationSchedule({Key? key, this.model});
  dynamic model;

  @override
  State<ConsultationSchedule> createState() => _ConsultationScheduleState();
}

class _ConsultationScheduleState extends State<ConsultationSchedule> {
  final storage = FlutterSecureStorage();
  final TextEditingController costPerHrController = TextEditingController();

  static const _kPrimary = Color(0xFF0262EC);

  List<dynamic> _allDays = [];
  List<dynamic> _allSlots = [];

  bool get isLawyerPro => LawyerProfileStore.instance.isPro;
  final double defaultPrice = 500.0;

  bool _isLoading = true;
  bool _isSaving = false;
  bool _prevIsPro = false;

  @override
  void initState() {
    super.initState();
    _prevIsPro = LawyerProfileStore.instance.isPro;
    LawyerProfileStore.instance.addListener(_onStoreChanged);
    _initializeData();
    
  }

  Future<void> readSlot() async {
    // if (_isLoading) return;
    setState(() {
      _isLoading = true;
    });
    try {
      final param = await postDio("$server/m/register/available/read", {"code": UserProfileStore.instance.code});

      setState(() {
        _allDays = param['objectData']['availableDays'];
        _allSlots = param['objectData']['availableSlots'];
        // _lawyersForYou = param['objectDate'];
        _isLoading = false;
      });
      
      // if (!mounted) return;
     
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _onStoreChanged() {
    if (!mounted) return;
    final nowIsPro = LawyerProfileStore.instance.isPro;
    if (_prevIsPro && !nowIsPro) {
      costPerHrController.text = defaultPrice.toStringAsFixed(0);
      storage.write(
          key: 'schedule_pricePerHour', value: defaultPrice.toStringAsFixed(0));
    }
    _prevIsPro = nowIsPro;
    setState(() {});
  }

  @override
  void dispose() {
    LawyerProfileStore.instance.removeListener(_onStoreChanged);
    costPerHrController.dispose();
    super.dispose();
  }

  Future<void> _initializeData() async {
    await _loadFromModel();
    await _loadSavedPrice();
    await readSlot();
    // setState(() => _isLoading = false);
  }

  // โหลดจาก model (ข้อมูลทนายที่ส่งมา)
  Future<void> _loadFromModel() async {
    final days = widget.model?['availableDays'];

    if (days is List && days.isNotEmpty) {
      _allDays = days
          .map<Map<String, dynamic>>(
            (e) => Map<String, dynamic>.from(e),
          )
          .toList();
    }

    final slots = widget.model?['availableSlots'];

    if (slots is List && slots.isNotEmpty) {
      _allSlots = slots
          .map<Map<String, dynamic>>(
            (e) => Map<String, dynamic>.from(e),
          )
          .toList();
    }
  }

  Future<void> _loadSavedPrice() async {
    final savedPrice = await storage.read(key: 'schedule_pricePerHour');
    if (!isLawyerPro) {
      costPerHrController.text = defaultPrice.toStringAsFixed(0);
    } else if (savedPrice != null && savedPrice.isNotEmpty) {
      costPerHrController.text = savedPrice;
    }
  }

  // ── Save ────────────────────────────────────────────────
  Future<void> _saveSchedule() async {
    if (costPerHrController.text.isEmpty) {
      DialogService.showError(
        context,
        title: 'pricePerHour'.tr(),
        message: 'selectPriceError'.tr(),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final lawyerCode = UserProfileStore.instance.code;
      var model = {
        'code': lawyerCode,
        'availableDays': _allDays,
        'availableSlots': _allSlots,
      };
      await postDio('$server/m/register/updateAvailableSlots', model).then(
        (x) => {
          if (x['status'] == 'S')
            {
              storage.write(
                  key: 'schedule_pricePerHour',
                  value: costPerHrController.text),
              DialogService.showSuccess(
                context,
                title: 'scheduleSuccessTitle'.tr(),
                message: 'scheduleSuccessMessage'.tr(),
                onClose: () => Navigator.pop(context),
              ),
            }
          else
            {
              DialogService.showError(
                context,
                title: 'errorTitle'.tr(),
                message: 'scheduleErrorMessage'.tr(),
              )
            }
        },
      );

      // บันทึกราคาใน storage
    } catch (e) {
      if (mounted) {
        DialogService.showError(
          context,
          title: 'errorTitle'.tr(),
          message: 'scheduleErrorMessage'.tr(),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showProScheduleUpsell() {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('upgradeScheduleNote'.tr()),
        backgroundColor: const Color(0xFFFFB020),
        duration: const Duration(seconds: 3),
        action: SnackBarAction(
          label: 'upgradeLink'.tr(),
          textColor: Colors.white,
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => SubscribePage()),
          ),
        ),
      ),
    );
  }

  Widget _buildScheduleProBanner() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF4E6),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFFB020).withOpacity(0.35)),
      ),
      child: Row(children: [
        const Icon(Icons.workspace_premium_rounded,
            size: 22, color: Color(0xFFFFB020)),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            'upgradeScheduleNote'.tr(),
            style: AppTypography.prompt(
              fontSize: 12.5,
              color: const Color(0xFF5A4A2A),
            ),
          ),
        ),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => SubscribePage()),
          ),
          child: Text(
            'upgradeLink'.tr(),
            style: AppTypography.prompt(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF0262EC),
            ),
          ),
        ),
      ]),
    );
  }

  void _clearAll() {
    if (!isLawyerPro) {
      _showProScheduleUpsell();
      return;
    }
    setState(() {
      for (final day in _allDays) {
        day['isOpen'] = true;
      }

      for (final slot in _allSlots) {
        slot['isOpen'] = true;
      }
      if (isLawyerPro) {
        costPerHrController.text = '';
      } else {
        costPerHrController.text = defaultPrice.toStringAsFixed(0);
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('clearSuccessMessage'.tr()),
        backgroundColor: const Color(0xFF0262EC),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════
  //  BUILD
  // ═══════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: const Color(0xFFEEF2F5),
        appBar: appBar(
          title: 'scheduleLoadingTitle'.tr(),
          backBtn: true,
          rightBtn: false,
          backAction: () => Navigator.pop(context, false),
          rightAction: () {},
        ),
        body: const AppLoadingView(),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFEEF2F5),
      appBar: appBar(
        title: 'scheduleTitle'.tr(),
        backBtn: true,
        rightBtn: false,
        backAction: () => Navigator.pop(context, false),
        rightAction: () {},
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(
          14,
          20,
          14,
          MediaQuery.of(context).padding.bottom + 100,
        ),
        children: [
          if (!isLawyerPro) ...[
            _buildScheduleProBanner(),
            const SizedBox(height: 16),
          ],
          _sectionLabel('วันที่เปิดรับ', Icons.calendar_month_rounded),
          const SizedBox(height: 12),
          _buildDaySelector(),
          const SizedBox(height: 24),
          _sectionLabel('selectTimeSlot'.tr(), Icons.access_time_rounded),
          const SizedBox(height: 12),
          _buildSlotPeriodSections(),
          const SizedBox(height: 24),
          _buildPriceSection(),
        ],
      ),
      bottomNavigationBar: _buildBottomActionBar(),
    );
  }

  Widget _buildBottomActionBar() {
    return Container(
      padding: EdgeInsets.fromLTRB(
        20,
        12,
        20,
        MediaQuery.of(context).padding.bottom + 12,
      ),
      // decoration: BoxDecoration(
      //   color: Colors.white,
      //   boxShadow: [
      //     BoxShadow(
      //       color: Colors.black.withOpacity(0.08),
      //       blurRadius: 16,
      //       offset: const Offset(0, -4),
      //     ),
      //   ],
      // ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: _clearAll,
              child: Container(
                height: 50,
                decoration: BoxDecoration(
                  color: const Color(0xFFDDEEFF),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFFA6BFEE)),
                ),
                child: Center(
                  child: Text(
                    'clearAll'.tr(),
                    style: AppTypography.prompt(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: _kPrimary,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: GestureDetector(
              onTap: _isSaving ? null : _saveSchedule,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                height: 50,
                decoration: BoxDecoration(
                  color: _isSaving ? const Color(0xFFCDD5E0) : _kPrimary,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: _isSaving
                      ? null
                      : [
                          BoxShadow(
                            color: _kPrimary.withOpacity(0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                ),
                child: Center(
                  child: _isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          'save'.tr(),
                          style: AppTypography.button(),
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── วัน (pill toggle) ───────────────────────────────────
  Widget _buildDaySelector() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _allDays.map((d) {
        final dayNum = d['day'] as int;
        final isOpen = d['isOpen'] == true;
        return GestureDetector(
          onTap: () {
            if (!isLawyerPro) {
              _showProScheduleUpsell();
              return;
            }
            setState(() {
              d['isOpen'] = !isOpen;
            });
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: isOpen ? const Color(0xFF0262EC) : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color:
                    isOpen ? const Color(0xFF0262EC) : const Color(0xFFE2E8F4),
              ),
              boxShadow: isOpen
                  ? [
                      BoxShadow(
                          color: const Color(0xFF0262EC).withOpacity(0.25),
                          blurRadius: 8,
                          offset: const Offset(0, 2))
                    ]
                  : null,
            ),
            child: Text(
              d['title'] as String,
              style: AppTypography.prompt(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isOpen ? Colors.white : Colors.grey[400],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  // ── Slot แบ่งช่วงเช้า / กลางวัน / เย็น ─────────────────
  int _slotStartHour(dynamic slot) {
    final title = slot['title']?.toString() ?? '';
    final start = title.split('-').first.trim();
    return int.tryParse(start.split(':').first) ?? 0;
  }

  _SlotPeriod _periodOf(dynamic slot) {
    final hour = _slotStartHour(slot);
    if (hour < 12) return _SlotPeriod.morning;
    if (hour < 17) return _SlotPeriod.afternoon;
    return _SlotPeriod.evening;
  }

  List<dynamic> _slotsInPeriod(_SlotPeriod period) {
    return _allSlots.where((s) => _periodOf(s) == period).toList();
  }

  void _togglePeriod(_SlotPeriod period, bool isOpen) {
    for (final slot in _allSlots) {
      if (_periodOf(slot) == period) {
        slot['isOpen'] = isOpen;
      }
    }
    setState(() {});
  }

  bool _isPeriodAllOpen(_SlotPeriod period) {
    final slots = _slotsInPeriod(period);
    if (slots.isEmpty) return false;
    return slots.every((s) => s['isOpen'] == true);
  }

  Widget _buildSlotPeriodSections() {
    return Column(
      children: [
        _buildPeriodCard(
          period: _SlotPeriod.morning,
          title: 'timeMorning'.tr(),
          range: 'timeMorningRange'.tr(),
          icon: Icons.wb_sunny_outlined,
          accent: const Color(0xFFFFA726),
        ),
        const SizedBox(height: 12),
        _buildPeriodCard(
          period: _SlotPeriod.afternoon,
          title: 'timeAfternoon'.tr(),
          range: 'timeAfternoonRange'.tr(),
          icon: Icons.wb_cloudy_outlined,
          accent: _kPrimary,
        ),
        const SizedBox(height: 12),
        _buildPeriodCard(
          period: _SlotPeriod.evening,
          title: 'timeEvening'.tr(),
          range: 'timeEveningRange'.tr(),
          icon: Icons.nights_stay_outlined,
          accent: const Color(0xFF5C6BC0),
        ),
      ],
    );
  }

  Widget _buildPeriodCard({
    required _SlotPeriod period,
    required String title,
    required String range,
    required IconData icon,
    required Color accent,
  }) {
    final slots = _slotsInPeriod(period);
    if (slots.isEmpty) return const SizedBox.shrink();

    final allOpen = _isPeriodAllOpen(period);
    final openCount =
        slots.where((s) => s['isOpen'] == true).length;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F4)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
            decoration: BoxDecoration(
              color: accent.withOpacity(0.08),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(17),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: accent.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: accent, size: 18),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: AppTypography.prompt(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF1A2340),
                        ),
                      ),
                      Text(
                        range,
                        style: AppTypography.prompt(
                          fontSize: 11,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  '$openCount/${slots.length}',
                  style: AppTypography.prompt(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: accent,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 6),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'selectTimeSlot'.tr(),
                    style: AppTypography.prompt(
                      fontSize: 11,
                      color: Colors.grey[500],
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    if (!isLawyerPro) {
                      _showProScheduleUpsell();
                      return;
                    }
                    _togglePeriod(period, !allOpen);
                  },
                  child: Text(
                    allOpen ? 'deselectAll'.tr() : 'selectAll'.tr(),
                    style: AppTypography.prompt(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: _kPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: slots.map((slot) => _buildSlotChip(slot)).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSlotChip(dynamic slot) {
    final title = slot['title']?.toString() ?? '';
    final isOpen = slot['isOpen'] == true;
    final parts = title.split('-');
    final label = parts.length >= 2 ? '${parts[0]} - ${parts[1]}' : title;

    return GestureDetector(
      onTap: () {
        if (!isLawyerPro) {
          _showProScheduleUpsell();
          return;
        }
        setState(() => slot['isOpen'] = !isOpen);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isOpen ? const Color(0xFFEEF4FF) : const Color(0xFFF8F9FB),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isOpen ? _kPrimary : const Color(0xFFE2E8F4),
            width: isOpen ? 1 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isOpen ? Icons.check_circle_rounded : Icons.schedule_rounded,
              size: 14,
              color: isOpen ? _kPrimary : Colors.grey[400],
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: AppTypography.prompt(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isOpen ? _kPrimary : const Color(0xFF9AAABB),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── ราคาต่อชั่วโมง (เดิม) ──────────────────────────────
  Widget _buildPriceSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionLabel('pricePerHour'.tr(), Icons.payments_outlined),
        const SizedBox(height: 10),
        TextField(
          controller: costPerHrController,
          enabled: isLawyerPro,
          keyboardType: TextInputType.number,
          style: GoogleFonts.prompt(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: isLawyerPro ? Colors.black : Colors.grey,
          ),
          decoration: InputDecoration(
            hintText: 'priceHint'.tr(),
            hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
            prefixIcon: Icon(Icons.payments_outlined,
                color: isLawyerPro ? const Color(0xFF0262EC) : Colors.grey),
            suffixText: 'priceSuffix'.tr(),
            suffixStyle: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
                fontWeight: FontWeight.w500),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFECEDF0))),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFECEDF0))),
            disabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey[300]!)),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                    const BorderSide(color: Color(0xFF0262EC), width: 2)),
            fillColor:
                isLawyerPro ? const Color(0xFFFAFAFA) : const Color(0xFFF5F5F5),
            filled: true,
          ),
        ),
        if (!isLawyerPro) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF4E6),
              borderRadius: BorderRadius.circular(12),
              border:
                  Border.all(color: const Color(0xFFFFB020).withOpacity(0.3)),
            ),
            child: Row(children: [
              const Icon(Icons.info_outline,
                  size: 18, color: Color(0xFFFFB020)),
              const SizedBox(width: 10),
              Expanded(
                child: Text('upgradePriceNote'.tr(),
                    style: TextStyle(fontSize: 12, color: Colors.grey[800])),
              ),
              GestureDetector(
                onTap: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => SubscribePage())),
                child: Text('upgradeLink'.tr(),
                    style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0262EC))),
              ),
            ]),
          ),
        ],
      ],
    );
  }

  Widget _sectionLabel(String title, IconData icon) {
    return Row(children: [
      Icon(icon, size: 16, color: _kPrimary),
      const SizedBox(width: 8),
      Text(
        title,
        style: AppTypography.prompt(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: const Color(0xFF1A2340),
        ),
      ),
    ]);
  }
}

enum _SlotPeriod { morning, afternoon, evening }
