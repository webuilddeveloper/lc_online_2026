import 'package:LawyerOnline/component/appbar.dart';
import 'package:LawyerOnline/component/dialog_service.dart';
import 'package:LawyerOnline/subscribe/lawyer-subscrile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:convert'; // เพิ่มสำหรับ JSON encode/decode

class ConsultationSchedule extends StatefulWidget {
  ConsultationSchedule({Key? key, this.model});

  dynamic model;

  @override
  State<ConsultationSchedule> createState() => _ConsultationScheduleState();
}

class _ConsultationScheduleState extends State<ConsultationSchedule> {
  final storage = FlutterSecureStorage();
  final TextEditingController costPerHrController = TextEditingController();

  // วันนัดหมาย
  List<Map<String, String>> postCategoryList = [
    {"code": "0", "title": "ทุกวัน"},
    {"code": "1", "title": "วันธรรมดา"},
    {"code": "2", "title": "สุดสัปดาห์"},
  ];
  String? selectedCategory = "0";

  // ช่วงเวลา - แบ่งเป็น 3 ช่วง
  List<String> selectedTimeSlots = [];

  // ราคา default และสถานะ Pro
  bool isLawyerPro = false;
  final double defaultPrice = 500.0;

  // สถานะการโหลดข้อมูล
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  // โหลดข้อมูลทั้งหมดตอนเริ่มต้น
  Future<void> _initializeData() async {
    await _checkLawyerProStatus();
    await _loadSavedSchedule();
    setState(() {
      _isLoading = false;
    });
  }

  // เช็คสถานะ Lawyer Pro
  Future<void> _checkLawyerProStatus() async {
    final proStatus = await storage.read(key: 'isLawyerPro');
    setState(() {
      isLawyerPro = proStatus == 'true';
    });
  }

  // โหลดข้อมูลที่บันทึกไว้
  Future<void> _loadSavedSchedule() async {
    try {
      // อ่านข้อมูลจาก storage
      final savedDayType = await storage.read(key: 'schedule_dayType');
      final savedTimeSlots = await storage.read(key: 'schedule_timeSlots');
      final savedPrice = await storage.read(key: 'schedule_pricePerHour');

      setState(() {
        // โหลดวันที่เลือก
        if (savedDayType != null) {
          selectedCategory = savedDayType;
        }

        // โหลดช่วงเวลาที่เลือก
        if (savedTimeSlots != null && savedTimeSlots.isNotEmpty) {
          try {
            final List<dynamic> timeSlotsList = jsonDecode(savedTimeSlots);
            selectedTimeSlots = timeSlotsList.cast<String>();
          } catch (e) {
            print('Error parsing time slots: $e');
            selectedTimeSlots = [];
          }
        }

        // โหลดราคา
        if (savedPrice != null && savedPrice.isNotEmpty) {
          costPerHrController.text = savedPrice;
        } else if (!isLawyerPro) {
          // ถ้าไม่มีค่าบันทึกและไม่ใช่ Pro ให้ใช้ราคา default
          costPerHrController.text = defaultPrice.toStringAsFixed(0);
        }
      });

      print(
          'โหลดข้อมูลสำเร็จ - Day: $selectedCategory, TimeSlots: $selectedTimeSlots, Price: ${costPerHrController.text}');
    } catch (e) {
      print('Error loading saved schedule: $e');
      // ถ้า error ให้ใช้ค่า default
      if (!isLawyerPro) {
        costPerHrController.text = defaultPrice.toStringAsFixed(0);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // แสดง loading ระหว่างโหลดข้อมูล
    if (_isLoading) {
      return Scaffold(
        backgroundColor: const Color(0xFFEEF2F5),
        appBar: appBar(
          title: "ตั้งค่าเวลาให้คำปรึกษา",
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
        title: "ตั้งค่าวันและเวลาที่สามารถนัดปรึกษาได้",
        backBtn: true,
        rightBtn: false,
        backAction: () => goBack(),
        rightAction: () => {},
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
        children: [
          const SizedBox(height: 30),
          _appointmentDetailsCard(),
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
                      border:
                          Border.all(width: 1, color: const Color.fromARGB(255, 166, 191, 238)),
                    ),
                    child: const Text(
                      "ล้างค่าทั้งหมด",
                      style: TextStyle(
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
                    child: const Text(
                      "บันทึก",
                      style: TextStyle(
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

  Widget _appointmentDetailsCard() {
    return Container(
      decoration: const BoxDecoration(),
      child: Column(
        children: [
          const SizedBox(height: 10),

          // วันนัดหมายปรึกษา
          _selectCategory(title: 'วันนัดหมายปรึกษา', list: postCategoryList),

          const SizedBox(height: 30),

          // ช่วงเวลา - แบ่งเป็น 3 ช่วง
          _buildTimeSlotSection(),

          const SizedBox(height: 30),

          // ราคาต่อชั่วโมง
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
        const Text(
          'เลือกช่วงเวลาที่ว่าง',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF0262EC),
          ),
        ),
        const SizedBox(height: 16),

        // ช่วงเช้า (08:00 - 11:00)
        _buildTimePeriod(
          title: 'ช่วงเช้า',
          subtitle: '08:00 - 11:00 น.',
          timeSlots: ['08:00', '09:00', '10:00', '11:00'],
        ),

        const SizedBox(height: 16),

        // ช่วงบ่าย (12:00 - 17:00)
        _buildTimePeriod(
          title: 'ช่วงบ่าย',
          subtitle: '13:00 - 17:00 น.',
          timeSlots: ['13:00', '14:00', '15:00', '16:00', '17:00'],
        ),

        const SizedBox(height: 16),

        // ช่วงเย็น (18:00 - 21:00)
        _buildTimePeriod(
          title: 'ช่วงเย็น',
          subtitle: '18:00 - 21:00 น.',
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
                    allSelected ? 'ยกเลิกทั้งหมด' : 'เลือกทั้งหมด',
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

  // เลือก/ยกเลิกช่วงเวลา
  void _toggleTimeSlot(String time) {
    setState(() {
      if (selectedTimeSlots.contains(time)) {
        selectedTimeSlots.remove(time);
      } else {
        selectedTimeSlots.add(time);
      }
      // เรียงเวลาใหม่
      selectedTimeSlots.sort();
    });
  }

  // เช็คว่าเลือกทั้งหมดในช่วงนั้นหรือไม่
  bool _isAllSelectedInPeriod(List<String> timeSlots) {
    return timeSlots.every((time) => selectedTimeSlots.contains(time));
  }

  // เลือก/ยกเลิกทั้งช่วง
  void _toggleAllInPeriod(List<String> timeSlots) {
    setState(() {
      if (_isAllSelectedInPeriod(timeSlots)) {
        // ยกเลิกทั้งหมด
        selectedTimeSlots.removeWhere((time) => timeSlots.contains(time));
      } else {
        // เลือกทั้งหมด
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
            const Text(
              'ราคาต่อชั่วโมง',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF0262EC),
              ),
            ),
            const SizedBox(width: 8),
            if (!isLawyerPro)
              Container(
                  // padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  // decoration: BoxDecoration(
                  //   color: const Color(0xFFFFF4E6),
                  //   borderRadius: BorderRadius.circular(6),
                  //   border: Border.all(color: const Color(0xFFFFB020)),
                  // ),
                  // child: const Text(
                  //   'Default',
                  //   style: TextStyle(
                  //     fontSize: 10,
                  //     fontWeight: FontWeight.w700,
                  //     color: Color(0xFFFFB020),
                  //   ),
                  // ),
                  ),
          ],
        ),
        const SizedBox(height: 8),

        // ถ้าไม่ใช่ Lawyer Pro แสดงข้อความแจ้ง

        TextField(
          controller: costPerHrController,
          enabled: isLawyerPro, // ถ้าไม่ใช่ Pro ก็แก้ไม่ได้
          keyboardType: TextInputType.number,
          style: GoogleFonts.prompt(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: isLawyerPro ? Colors.black : Colors.grey,
          ),
          decoration: InputDecoration(
            hintText: "บาท/ชั่วโมง",
            hintStyle: TextStyle(
              color: Colors.grey[400],
              fontSize: 14,
            ),
            prefixIcon: Icon(
              Icons.payments_outlined,
              color: isLawyerPro ? const Color(0xFF0262EC) : Colors.grey,
            ),
            suffixText: 'บาท',
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
                    'อัปเกรดเป็น Lawyer Pro เพื่อตั้งราคาเองได้',
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
                  child: const Text(
                    'อัปเกรด',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0262EC),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // const SizedBox(height: ),
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

    // ล้างข้อมูลใน storage ด้วย
    await _clearStorageData();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('ล้างข้อมูลเรียบร้อยแล้ว'),
          backgroundColor: Color(0xFF0262EC),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  // ล้างข้อมูลใน storage
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
    // Validation
    if (selectedTimeSlots.isEmpty) {
      DialogService.showError(
        context,
        title: "กรุณาเลือกช่วงเวลา",
        message: "โปรดเลือกอย่างน้อย 1 ช่วงเวลาที่ว่าง",
      );
      return;
    }

    if (costPerHrController.text.isEmpty) {
      DialogService.showError(
        context,
        title: "กรุณากรอกราคา",
        message: "โปรดระบุราคาต่อชั่วโมง",
      );
      return;
    }

    try {
      // ล้างค่าเก่าก่อนบันทึกค่าใหม่ เพื่อป้องกันค่าค้างค้า
      await _clearStorageData();

      // บันทึกข้อมูลใหม่ลง storage
      await storage.write(key: 'schedule_dayType', value: selectedCategory);
      await storage.write(
        key: 'schedule_timeSlots',
        value: jsonEncode(selectedTimeSlots),
      );
      await storage.write(
        key: 'schedule_pricePerHour',
        value: costPerHrController.text,
      );

      // สร้างข้อมูลสำหรับส่ง API (ถ้ามี)
      final scheduleData = {
        'dayType': selectedCategory, // 0=ทุกวัน, 1=วันธรรมดา, 2=สุดสัปดาห์
        'timeSlots': selectedTimeSlots, // ["08:00", "09:00", "14:00", ...]
        'pricePerHour': double.parse(costPerHrController.text),
        'isProPrice': isLawyerPro,
      };

      print('บันทึกข้อมูลสำเร็จ: $scheduleData');

      // TODO: ส่งข้อมูลไป API ตรงนี้
      // await _sendToAPI(scheduleData);

      // แสดง dialog สำเร็จ
      if (mounted) {
        DialogService.showSuccess(
          context,
          title: "บันทึกข้อมูลแล้ว",
          message: "ระบบได้บันทึกตารางเวลาของคุณเรียบร้อยแล้ว",
          onClose: () {
            Navigator.pop(context);
          },
        );
      }
    } catch (e) {
      // print('Error saving schedule: $e');
      if (mounted) {
        DialogService.showError(
          context,
          title: "เกิดข้อผิดพลาด",
          message: "ไม่สามารถบันทึกข้อมูลได้ กรุณาลองใหม่อีกครั้ง",
        );
      }
    }
  }

  void goBack() async {
    Navigator.pop(context, false);
  }

  @override
  void dispose() {
    costPerHrController.dispose();
    super.dispose();
  }
}
