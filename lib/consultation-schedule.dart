import 'package:LawyerOnline/component/appbar.dart';
import 'package:LawyerOnline/component/dialog_service.dart';
import 'package:LawyerOnline/models/user_profile_store.dart';
import 'package:LawyerOnline/subscribe/lawyer-subscrile.dart';
import 'package:LawyerOnline/models/lawyer/lawyer_profile_store.dart';
import 'package:LawyerOnline/shared/api_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:convert';
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

  // ── วันที่เปิดรับ (0=อาทิตย์ ... 6=เสาร์) ──────────────
  // static const _allDays = [
  //   {'day': 1, 'title': 'จันทร์'},
  //   {'day': 2, 'title': 'อังคาร'},
  //   {'day': 3, 'title': 'พุธ'},
  //   {'day': 4, 'title': 'พฤหัสบดี'},
  //   {'day': 5, 'title': 'ศุกร์'},
  //   {'day': 6, 'title': 'เสาร์'},
  //   {'day': 0, 'title': 'อาทิตย์'},
  // ];

  // // ── slot เวลา ───────────────────────────────────────────
  // static const _allSlots = [
  //   '09:00-10:00',
  //   '10:00-11:00',
  //   '11:00-12:00',
  //   '12:00-13:00',
  //   '13:00-14:00',
  //   '14:00-15:00',
  //   '15:00-16:00',
  //   '16:00-17:00',
  // ];

  List<dynamic> _allDays = [
   
  ];

  List<dynamic> _allSlots = [
   
  ];

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
        print('------------------- ${param['objectData']}');
        _allDays = param['objectData']['availableDays'];
        _allSlots = param['objectData']['availableSlots'];
        // _lawyersForYou = param['objectDate'];
        _isLoading = false;
      });
      
      // if (!mounted) return;
     
      // print('------------------- ${mapped}');
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

  void _clearAll() {
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
        body: const Center(
            child: CircularProgressIndicator(color: Color(0xFF0262EC))),
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
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        children: [
          // ── Info banner ──────────────────────────────
          

          // ── Section: วัน ─────────────────────────────
          _sectionLabel('วันที่เปิดรับ', Icons.calendar_month_rounded),
          const SizedBox(height: 12),
          _buildDaySelector(),
          const SizedBox(height: 24),

          // ── Section: Slot เวลา ────────────────────────
          _sectionLabel('ช่วงเวลารับงาน', Icons.access_time_rounded),
          const SizedBox(height: 12),
          _buildSlotList(),
          const SizedBox(height: 24),

          // ── Section: ราคา ─────────────────────────────
          _buildPriceSection(),
          const SizedBox(height: 24),

          // ── Buttons ───────────────────────────────────
          Row(children: [
            Expanded(
              child: GestureDetector(
                onTap: _clearAll,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDDEEFF),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: const Color(0xFFA6BFEE)),
                  ),
                  child: Text(
                    'clearAll'.tr(),
                    style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0262EC)),
                    textAlign: TextAlign.center,
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
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  decoration: BoxDecoration(
                    color: _isSaving
                        ? const Color(0xFFCDD5E0)
                        : const Color(0xFF0262EC),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: _isSaving
                      ? const Center(
                          child: SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white)))
                      : Text(
                          'save'.tr(),
                          style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Colors.white),
                          textAlign: TextAlign.center,
                        ),
                ),
              ),
            ),
          ]),
          const SizedBox(height: 20),
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
              style: TextStyle(
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

  // ── Slot list (toggle row) ──────────────────────────────
  Widget _buildSlotList() {
    return Column(
      children: _allSlots.map((slot) {
        final title = slot['title'].toString();
        final isOpen = slot['isOpen'] == true;
        final parts = title.split('-');
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: GestureDetector(
            onTap: () {
              setState(() {
                slot['isOpen'] = !isOpen;
              });
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: isOpen ? const Color(0xFFEEF4FF) : Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isOpen
                      ? const Color(0xFF0262EC).withOpacity(0.4)
                      : const Color(0xFFE2E8F4),
                  width: isOpen ? 1.5 : 1,
                ),
              ),
              child: Row(children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: isOpen
                        ? const Color(0xFF0262EC).withOpacity(0.1)
                        : const Color(0xFFF1F5FB),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.access_time_rounded,
                      color:
                          isOpen ? const Color(0xFF0262EC) : Colors.grey[400],
                      size: 20),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${parts[0]} - ${parts[1]}',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: isOpen
                              ? const Color(0xFF0262EC)
                              : const Color(0xFF9AAABB),
                        ),
                      ),
                      Text(
                        isOpen ? 'เปิดรับลูกความ' : 'ปิด',
                        style: TextStyle(
                          fontSize: 11,
                          color: isOpen
                              ? const Color(0xFF0262EC).withOpacity(0.6)
                              : Colors.grey[400],
                        ),
                      ),
                    ],
                  ),
                ),
                // Toggle switch
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 48,
                  height: 28,
                  decoration: BoxDecoration(
                    color: isOpen
                        ? const Color(0xFF0262EC)
                        : const Color(0xFFE2E8F4),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: AnimatedAlign(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeInOut,
                    alignment:
                        isOpen ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      width: 22,
                      height: 22,
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      decoration: const BoxDecoration(
                          color: Colors.white, shape: BoxShape.circle),
                    ),
                  ),
                ),
              ]),
            ),
          ),
        );
      }).toList(),
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
      Icon(icon, size: 16, color: const Color(0xFF0262EC)),
      const SizedBox(width: 8),
      Text(title,
          style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1A2340))),
    ]);
  }
}
