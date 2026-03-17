import 'dart:io';
import 'package:LawyerOnline/component/appbar.dart';
import 'package:LawyerOnline/consult/consult_sum.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

class ConsultPage extends StatefulWidget {
  const ConsultPage({super.key});

  @override
  State<ConsultPage> createState() => _ConsultPageState();
}

class _ConsultPageState extends State<ConsultPage> {
  String? _selectedCategory;
  String? _selectedSubCategory;
  DateTime? _selectedDate = DateTime.now();
  String? _selectedProvince = "กรุงเทพมหานคร";
  final TextEditingController _detailController = TextEditingController();
  final TextEditingController _demandController = TextEditingController();
  final TextEditingController _wageController = TextEditingController();

  List<File> _selectedImages = [];
  final ImagePicker _picker = ImagePicker();

  final Map<String, List<String>> _caseTypes = {
    'คดีแพ่ง': [
      'คดีครอบครัว',
      'คดีมรดก',
      'คดีสัญญา',
      'คดีละเมิด',
      'คดีทรัพย์สิน'
    ],
    'คดีอาญา': [
      'คดีทุจริต',
      'คดียาเสพติด',
      'คดีทำร้ายร่างกาย',
      'คดีลักทรัพย์',
      'คดีฉ้อโกง'
    ],
    'คดีแรงงาน': ['เลิกจ้างไม่เป็นธรรม', 'ค่าจ้างค้างชำระ', 'ชดเชยอุบัติเหตุ'],
    'คดีธุรกิจ': [
      'จดทะเบียนบริษัท',
      'สัญญาธุรกิจ',
      'คดีล้มละลาย',
      'ทรัพย์สินทางปัญญา'
    ],
  };

  final List<String> _provinces = [
    'กรุงเทพมหานคร',
    'เชียงใหม่',
    'ชลบุรี',
    'ภูเก็ต',
    'ขอนแก่น',
    'นครราชสีมา',
    'สุราษฎร์ธานี',
    'อุดรธานี',
    'นครสวรรค์',
    'พิษณุโลก',
  ];

  bool get _canSubmit =>
      _selectedCategory != null &&
      _selectedSubCategory != null &&
      _selectedDate != null &&
      _selectedProvince != null &&
      _detailController.text.trim().isNotEmpty;
  // _demandController.text.trim().isNotEmpty &&
  // _wageController.text.trim().isNotEmpty;

  Future<void> _pickImages() async {
    final List<XFile> images = await _picker.pickMultiImage();

    if (images.isNotEmpty) {
      setState(() {
        _selectedImages.addAll(images.map((e) => File(e.path)));
      });
    }
  }

  @override
  void dispose() {
    _detailController.dispose();
    super.dispose();
  }

  Widget _buildDropdownField({
    required String label,
    required String hint,
    required IconData icon,
    required String? value,
    required List<String> items,
    required void Function(String?) onChanged,
    bool enabled = true,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1A2340),
            )),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: value,
          onChanged: enabled ? onChanged : null,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
            prefixIcon: Icon(icon, color: const Color(0xFF0262EC), size: 20),
            filled: true,
            fillColor: enabled ? Colors.white : const Color(0xFFF5F7FA),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide:
                  const BorderSide(color: Color(0xFFEEF2F5), width: 1.5),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide:
                  const BorderSide(color: Color(0xFFEEF2F5), width: 1.5),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide:
                  const BorderSide(color: Color(0xFF0262EC), width: 1.5),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide:
                  const BorderSide(color: Color(0xFFEEF2F5), width: 1.5),
            ),
          ),
          icon: const Icon(Icons.keyboard_arrow_down_rounded,
              color: Color(0xFF0262EC)),
          dropdownColor: Colors.white,
          borderRadius: BorderRadius.circular(14),
          items: items
              .map((e) => DropdownMenuItem(
                    value: e,
                    child: Text(e, style: const TextStyle(fontSize: 14)),
                  ))
              .toList(),
        ),
      ],
    );
  }

  Widget _buildDateField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('วันที่นัดหมาย',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1A2340),
            )),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              // initialDate: DateTime.now().add(const Duration(days: 1)),  + 1วัน
              initialDate: DateTime.now(),
              firstDate: DateTime.now(),
              lastDate: DateTime.now().add(const Duration(days: 90)),
              builder: (context, child) => Theme(
                data: Theme.of(context).copyWith(
                  colorScheme:
                      const ColorScheme.light(primary: Color(0xFF0262EC)),
                ),
                child: child!,
              ),
            );
            if (picked != null) setState(() => _selectedDate = picked);
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: const Color(0xFFEEF2F5),
                // _selectedDate != null
                //     ? const Color(0xFF0262EC)
                //     : const Color(0xFFEEF2F5),
                width: 1.5,
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.calendar_today_outlined,
                    color: Color(0xFF0262EC), size: 20),
                const SizedBox(width: 12),
                Text(
                  _selectedDate == null
                      ? 'เลือกวันที่'
                      : '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year + 543}',
                  style: TextStyle(
                    color: _selectedDate != null
                        ? const Color(0xFF1A2340)
                        : Colors.grey[400],
                    fontSize: 14,
                  ),
                ),
                const Spacer(),
                const Icon(Icons.keyboard_arrow_down_rounded,
                    color: Color(0xFF0262EC)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDetailField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('สรุปเหตุการณ์',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1A2340),
            )),
        const SizedBox(height: 8),
        TextFormField(
          controller: _detailController,
          maxLines: 4,
          maxLength: 500,
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
            hintText:
                'อธิบายรายละเอียดคดีโดยย่อ เพื่อให้หมอความเข้าใจก่อนนัดหมาย...',
            hintStyle:
                TextStyle(color: Colors.grey[400], fontSize: 13, height: 1.5),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.all(16),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide:
                  const BorderSide(color: Color(0xFFEEF2F5), width: 1.5),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide:
                  const BorderSide(color: Color(0xFFEEF2F5), width: 1.5),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide:
                  const BorderSide(color: Color(0xFF0262EC), width: 1.5),
            ),
            counterStyle: TextStyle(color: Colors.grey[400], fontSize: 11),
          ),
        ),
      ],
    );
  }

  _buildDemandsField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('ข้อเรียกร้อง',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1A2340),
            )),
        const SizedBox(height: 8),
        TextFormField(
          controller: _demandController,
          maxLines: 4,
          maxLength: 500,
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
            hintText:
                'ระบุสิ่งที่ต้องการให้ทนายช่วย เช่น ฟ้องร้อง เรียกค่าเสียหาย หรือให้คำปรึกษา...',
            hintStyle:
                TextStyle(color: Colors.grey[400], fontSize: 13, height: 1.5),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.all(16),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide:
                  const BorderSide(color: Color(0xFFEEF2F5), width: 1.5),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide:
                  const BorderSide(color: Color(0xFFEEF2F5), width: 1.5),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide:
                  const BorderSide(color: Color(0xFF0262EC), width: 1.5),
            ),
            counterStyle: TextStyle(color: Colors.grey[400], fontSize: 11),
          ),
        ),
      ],
    );
  }

  _buildWagwField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('ค่าจ้างทนาย',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1A2340),
            )),
        const SizedBox(height: 8),
        TextFormField(
          keyboardType: TextInputType.number,
          controller: _wageController,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          maxLines: 1,
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
            hintText: 'ระบุค่าจ่างทนายที่คุณต้องการ',
            hintStyle:
                TextStyle(color: Colors.grey[400], fontSize: 13, height: 1.5),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.all(16),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide:
                  const BorderSide(color: Color(0xFFEEF2F5), width: 1.5),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide:
                  const BorderSide(color: Color(0xFFEEF2F5), width: 1.5),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide:
                  const BorderSide(color: Color(0xFF0262EC), width: 1.5),
            ),
            counterStyle: TextStyle(color: Colors.grey[400], fontSize: 11),
          ),
        ),
      ],
    );
  }

  Widget _buildImageField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'แนบภาพหลักฐาน',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1A2340),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 140,
          width: double.infinity,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ..._selectedImages.asMap().entries.map((entry) {
                  int index = entry.key;
                  File image = entry.value;

                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.file(
                            image,
                            width: 140,
                            height: 140,
                            fit: BoxFit.cover,
                          ),
                        ),

                        /// ปุ่มลบ
                        Positioned(
                          right: 4,
                          top: 4,
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedImages.removeAt(index);
                              });
                            },
                            child: Container(
                              decoration: const BoxDecoration(
                                color: Colors.black54,
                                shape: BoxShape.circle,
                              ),
                              padding: const EdgeInsets.all(3),
                              child: const Icon(
                                Icons.close,
                                color: Colors.white,
                                size: 14,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }),

                /// ปุ่มเพิ่มรูป
                GestureDetector(
                  onTap: _pickImages,
                  child: DottedBorder(
                    // options: const RoundedRectDottedBorderOptions(
                    //   radius: Radius.circular(12),
                    //   color: Color(0xFFEEF2F5),
                    //   strokeWidth: 1.5,
                    // ),
                    borderType: BorderType.RRect,
                    radius: const Radius.circular(12),
                    color: Color(0xFFEEF2F5),
                    strokeWidth: 1.5,
                    child: Container(
                      width: 140,
                      height: 140,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.add_a_photo,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEEF2F5),
      appBar: appBar(
        title: "หมอความออนไลน์",
        backBtn: true,
        rightBtn: false,
        rightAction: () => {},
        backAction: () => Navigator.pop(context, false),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // ── Header ──
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF0262EC), Color(0xFF0485FF)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.balance_outlined,
                              color: Colors.white, size: 24),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('กรอกข้อมูลคดี',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16)),
                              SizedBox(height: 2),
                              Text('เพื่อจับคู่กับหมอความที่เหมาะสม',
                                  style: TextStyle(
                                      color: Colors.white70, fontSize: 12)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ── Form ──
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        _buildDropdownField(
                          label: 'ประเภทคดี',
                          hint: 'เลือกประเภทคดี',
                          icon: Icons.gavel_outlined,
                          value: _selectedCategory,
                          items: _caseTypes.keys.toList(),
                          onChanged: (val) => setState(() {
                            _selectedCategory = val;
                            _selectedSubCategory = null;
                          }),
                        ),
                        const SizedBox(height: 20),
                        _buildDropdownField(
                          label: 'ประเภทคดีย่อย',
                          hint: _selectedCategory == null
                              ? 'เลือกประเภทคดีก่อน'
                              : 'เลือกประเภทคดีย่อย',
                          icon: Icons.folder_outlined,
                          value: _selectedSubCategory,
                          items: _selectedCategory != null
                              ? _caseTypes[_selectedCategory]!
                              : [],
                          onChanged: (val) =>
                              setState(() => _selectedSubCategory = val),
                          enabled: _selectedCategory != null,
                        ),
                        const SizedBox(height: 20),
                        _buildDateField(),
                        const SizedBox(height: 20),
                        _buildDropdownField(
                          label: 'จังหวัด',
                          hint: 'เลือกจังหวัด',
                          icon: Icons.location_on_outlined,
                          value: _selectedProvince,
                          items: _provinces,
                          onChanged: (val) =>
                              setState(() => _selectedProvince = val),
                        ),
                        // const SizedBox(height: 20),
                        // _buildWagwField(),
                        const SizedBox(height: 20),
                        _buildDetailField(),
                        const SizedBox(height: 20),
                        _buildDemandsField(),
                        const SizedBox(height: 20),
                        _buildImageField(),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Bottom Button ──
          Container(
            padding: EdgeInsets.fromLTRB(
                20, 12, 20, MediaQuery.of(context).padding.bottom + 12),
            decoration: const BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                    color: Color(0x15000000),
                    blurRadius: 10,
                    offset: Offset(0, -3))
              ],
            ),
            child: GestureDetector(
              onTap: _canSubmit
                  ? () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ConsultSummaryPage(
                            category: _selectedCategory!,
                            subCategory: _selectedSubCategory!,
                            date: _selectedDate!,
                            province: _selectedProvince!,
                            detail: _detailController.text.trim(),
                            demand: _demandController.text.trim(),
                            wage: _wageController.text.trim(),
                            images: _selectedImages,
                          ),
                        ),
                      );
                    }
                  : null,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                height: 52,
                decoration: BoxDecoration(
                  gradient: _canSubmit
                      ? const LinearGradient(
                          colors: [Color(0xFF0262EC), Color(0xFF0485FF)])
                      : null,
                  color: _canSubmit ? null : const Color(0xFFCDD5E0),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: _canSubmit
                      ? [
                          BoxShadow(
                            color: const Color(0xFF0262EC).withOpacity(0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          )
                        ]
                      : null,
                ),
                child: Center(
                  child: Text(
                    'ถัดไป',
                    style: TextStyle(
                      color: _canSubmit ? Colors.white : Colors.grey[400],
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
