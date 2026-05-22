import 'package:LawyerOnline/component/appbar.dart';
import 'package:LawyerOnline/component/dialog_service.dart';
import 'package:LawyerOnline/subscribe/lawyer-subscrile.dart';
import 'package:LawyerOnline/models/lawyer/lawyer_profile_store.dart';
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

  // วันนัดหมาย — title โหลดตอน build เพื่อให้ .tr() ทำงานได้ใน context
  String? selectedCategory = "0";

  // ช่วงเวลา
  List<String> selectedTimeSlots = [];

  bool get isLawyerPro => LawyerProfileStore.instance.isPro;
  final double defaultPrice = 500.0;

  bool _isLoading = true;
  bool _prevIsPro = false;

  @override
  void initState() {
    super.initState();
    _prevIsPro = LawyerProfileStore.instance.isPro;
    LawyerProfileStore.instance.addListener(_onStoreChanged);
    _initializeData();
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
    await _loadSavedSchedule();
    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _loadSavedSchedule() async {
    try {
      final savedDayType = await storage.read(key: 'schedule_dayType');
      final savedTimeSlots = await storage.read(key: 'schedule_timeSlots');
      final savedPrice = await storage.read(key: 'schedule_pricePerHour');

      setState(() {
        if (savedDayType != null) {
          selectedCategory = savedDayType;
        }

        if (savedTimeSlots != null && savedTimeSlots.isNotEmpty) {
          try {
            final List<dynamic> timeSlotsList = jsonDecode(savedTimeSlots);
            selectedTimeSlots = timeSlotsList.cast<String>();
          } catch (e) {
            print('Error parsing time slots: $e');
            selectedTimeSlots = [];
          }
        }

        if (!isLawyerPro) {
          costPerHrController.text = defaultPrice.toStringAsFixed(0);
        } else if (savedPrice != null && savedPrice.isNotEmpty) {
          costPerHrController.text = savedPrice;
        }
      });

      print(
          'โหลดข้อมูลสำเร็จ - Day: $selectedCategory, TimeSlots: $selectedTimeSlots, Price: ${costPerHrController.text}');
    } catch (e) {
      print('Error loading saved schedule: $e');
      if (!isLawyerPro) {
        costPerHrController.text = defaultPrice.toStringAsFixed(0);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // วันนัดหมาย — สร้างในเมธอด build เพื่อให้ .tr() อยู่ใน context
    final List<Map<String, String>> postCategoryList = [
      {"code": "0", "title": 'dayEvery'.tr()},
      {"code": "1", "title": 'dayWeekday'.tr()},
      {"code": "2", "title": 'dayWeekend'.tr()},
    ];

    if (_isLoading) {
      return Scaffold(
        backgroundColor: const Color(0xFFEEF2F5),
        appBar: appBar(
          title: 'scheduleLoadingTitle'.tr(),
          backBtn: true,
          rightBtn: false,
          backAction: () => goBack(),
          rightAction: () => {},
        ),
        body: const Center(
          child: CircularProgressIndicator(
            color: Color(0xFF0262EC),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFEEF2F5),
      appBar: appBar(
        title: 'scheduleTitle'.tr(),
        backBtn: true,
        rightBtn: false,
        backAction: () => goBack(),
        rightAction: () => {},
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
        children: [
          const SizedBox(height: 30),
          _appointmentDetailsCard(postCategoryList),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: _clearAll,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        vertical: 15, horizontal: 10),
                    decoration: BoxDecoration(
                      color: const Color.fromARGB(255, 221, 238, 255),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                          width: 1,
                          color: const Color.fromARGB(255, 166, 191, 238)),
                    ),
                    child: Text(
                      'clearAll'.tr(),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0262EC),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: GestureDetector(
                  onTap: _saveSchedule,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        vertical: 15, horizontal: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0262EC),
                      borderRadius: BorderRadius.circular(18),
                      border:
                          Border.all(width: 1, color: const Color(0xFFDBDBDB)),
                    ),
                    child: Text(
                      'save'.tr(),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _appointmentDetailsCard(List<Map<String, String>> postCategoryList) {
    return Container(
      decoration: const BoxDecoration(),
      child: Column(
        children: [
          const SizedBox(height: 10),
          _selectCategory(title: 'appointmentDay'.tr(), list: postCategoryList),
          const SizedBox(height: 30),
          _buildTimeSlotSection(),
          const SizedBox(height: 30),
          _buildPriceSection(),
        ],
      ),
    );
  }

  // ============================================================================
  // SECTION: เลือกวันนัดหมาย
  // ============================================================================

  Widget _selectCategory({
    required List<Map<String, String>>? list,
    String title = '',
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF0262EC),
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 10,
          children: list!.map((e) {
            final selected = selectedCategory == e['code'];
            return ChoiceChip(
              label: Text(
                e['title']!,
                style: TextStyle(
                  color: selected ? Colors.white : const Color(0xFF0D1B2A),
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
              selected: selected,
              selectedColor: const Color(0xFF0262EC),
              backgroundColor: const Color(0xFFF3F6FF),
              showCheckmark: false,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: selected
                      ? const Color(0xFF0262EC)
                      : const Color(0xFFE2E8F0),
                  width: 1.5,
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              onSelected: (_) {
                setState(() {
                  selectedCategory = e['code'];
                });
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  // ============================================================================
  // SECTION: เลือกช่วงเวลา (เช้า/บ่าย/เย็น)
  // ============================================================================

  Widget _buildTimeSlotSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'selectTimeSlot'.tr(),
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF0262EC),
          ),
        ),
        const SizedBox(height: 16),
        _buildTimePeriod(
          title: 'timeMorning'.tr(),
          subtitle: 'timeMorningRange'.tr(),
          timeSlots: ['08:00', '09:00', '10:00', '11:00'],
        ),
        const SizedBox(height: 16),
        _buildTimePeriod(
          title: 'timeAfternoon'.tr(),
          subtitle: 'timeAfternoonRange'.tr(),
          timeSlots: ['13:00', '14:00', '15:00', '16:00', '17:00'],
        ),
        const SizedBox(height: 16),
        _buildTimePeriod(
          title: 'timeEvening'.tr(),
          subtitle: 'timeEveningRange'.tr(),
          timeSlots: ['18:00', '19:00', '20:00', '21:00'],
        ),
      ],
    );
  }

  Widget _buildTimePeriod({
    required String title,
    required String subtitle,
    required List<String> timeSlots,
  }) {
    final allSelected = _isAllSelectedInPeriod(timeSlots);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF0D1B2A),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
              GestureDetector(
                onTap: () => _toggleAllInPeriod(timeSlots),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: allSelected
                        ? const Color(0xFFE8F3FF)
                        : const Color.fromARGB(255, 255, 255, 255),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: allSelected
                          ? const Color(0xFF0262EC)
                          : const Color(0xFFDEE2E6),
                      width: 1.5,
                    ),
                  ),
                  child: Text(
                    allSelected ? 'deselectAll'.tr() : 'selectAll'.tr(),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: allSelected
                          ? const Color(0xFF0262EC)
                          : const Color(0xFF6C757D),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: timeSlots.map((time) {
              final isSelected = selectedTimeSlots.contains(time);
              return GestureDetector(
                onTap: () => _toggleTimeSlot(time),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFF0262EC)
                        : const Color.fromARGB(255, 255, 255, 255),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isSelected
                          ? const Color(0xFF0262EC)
                          : const Color(0xFFDEE2E6),
                      width: 1.5,
                    ),
                  ),
                  child: Text(
                    time,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color:
                          isSelected ? Colors.white : const Color(0xFF64748B),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  void _toggleTimeSlot(String time) {
    setState(() {
      if (selectedTimeSlots.contains(time)) {
        selectedTimeSlots.remove(time);
      } else {
        selectedTimeSlots.add(time);
      }
      selectedTimeSlots.sort();
    });
  }

  bool _isAllSelectedInPeriod(List<String> timeSlots) {
    return timeSlots.every((time) => selectedTimeSlots.contains(time));
  }

  void _toggleAllInPeriod(List<String> timeSlots) {
    setState(() {
      if (_isAllSelectedInPeriod(timeSlots)) {
        selectedTimeSlots.removeWhere((time) => timeSlots.contains(time));
      } else {
        for (var time in timeSlots) {
          if (!selectedTimeSlots.contains(time)) {
            selectedTimeSlots.add(time);
          }
        }
      }
      selectedTimeSlots.sort();
    });
  }

  // ============================================================================
  // SECTION: ราคาต่อชั่วโมง
  // ============================================================================

  Widget _buildPriceSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'pricePerHour'.tr(),
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF0262EC),
              ),
            ),
            const SizedBox(width: 8),
            if (!isLawyerPro) Container(),
          ],
        ),
        const SizedBox(height: 8),
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
            hintStyle: TextStyle(
              color: Colors.grey[400],
              fontSize: 14,
            ),
            prefixIcon: Icon(
              Icons.payments_outlined,
              color: isLawyerPro ? const Color(0xFF0262EC) : Colors.grey,
            ),
            suffixText: 'priceSuffix'.tr(),
            suffixStyle: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFECEDF0)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFECEDF0)),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF0262EC), width: 2),
            ),
            fillColor:
                isLawyerPro ? const Color(0xFFFAFAFA) : const Color(0xFFF5F5F5),
            filled: true,
          ),
        ),
        const SizedBox(height: 8),
        if (!isLawyerPro) ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF4E6),
              borderRadius: BorderRadius.circular(12),
              border:
                  Border.all(color: const Color(0xFFFFB020).withOpacity(0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline,
                    size: 18, color: Color(0xFFFFB020)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'upgradePriceNote'.tr(),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[800],
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => SubscribePage(),
                    ),
                  ),
                  child: Text(
                    'upgradeLink'.tr(),
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0262EC),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  // ============================================================================
  // ACTIONS
  // ============================================================================

  void _clearAll() async {
    setState(() {
      selectedCategory = '0';
      selectedTimeSlots.clear();
      if (isLawyerPro) {
        costPerHrController.text = '';
      } else {
        costPerHrController.text = defaultPrice.toStringAsFixed(0);
      }
    });

    await _clearStorageData();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('clearSuccessMessage'.tr()),
          backgroundColor: const Color(0xFF0262EC),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _clearStorageData() async {
    try {
      await storage.delete(key: 'schedule_dayType');
      await storage.delete(key: 'schedule_timeSlots');
      await storage.delete(key: 'schedule_pricePerHour');
      print('ล้างข้อมูลใน storage สำเร็จ');
    } catch (e) {
      print('Error clearing storage: $e');
    }
  }

  void _saveSchedule() async {
    if (selectedTimeSlots.isEmpty) {
      DialogService.showError(
        context,
        title: 'selectTimeSlot'.tr(),
        message: 'selectTimeSlotError'.tr(),
      );
      return;
    }

    if (costPerHrController.text.isEmpty) {
      DialogService.showError(
        context,
        title: 'pricePerHour'.tr(),
        message: 'selectPriceError'.tr(),
      );
      return;
    }

    try {
      await _clearStorageData();

      await storage.write(key: 'schedule_dayType', value: selectedCategory);
      await storage.write(
        key: 'schedule_timeSlots',
        value: jsonEncode(selectedTimeSlots),
      );
      await storage.write(
        key: 'schedule_pricePerHour',
        value: costPerHrController.text,
      );

      final scheduleData = {
        'dayType': selectedCategory,
        'timeSlots': selectedTimeSlots,
        'pricePerHour': double.parse(costPerHrController.text),
        'isProPrice': isLawyerPro,
      };

      print('บันทึกข้อมูลสำเร็จ: $scheduleData');

      // TODO: ส่งข้อมูลไป API ตรงนี้
      // await _sendToAPI(scheduleData);

      if (mounted) {
        DialogService.showSuccess(
          context,
          title: 'scheduleSuccessTitle'.tr(),
          message: 'scheduleSuccessMessage'.tr(),
          onClose: () {
            Navigator.pop(context);
          },
        );
      }
    } catch (e) {
      if (mounted) {
        DialogService.showError(
          context,
          title: 'errorTitle'.tr(),
          message: 'scheduleErrorMessage'.tr(),
        );
      }
    }
  }

  void goBack() async {
    Navigator.pop(context, false);
  }
}
