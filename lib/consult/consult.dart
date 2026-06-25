import 'dart:io';
import 'package:LawyerOnline/component/appbar.dart';
import 'package:LawyerOnline/consult/consult_sum.dart';
import 'package:LawyerOnline/shared/api_provider.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:LawyerOnline/shared/responsive/app_layout.dart';

class ConsultPage extends StatefulWidget {
  const ConsultPage({super.key});

  @override
  State<ConsultPage> createState() => _ConsultPageState();
}

class _ConsultPageState extends State<ConsultPage> {
  dynamic _selectedTopic;
  dynamic _selectedSubCase;

  String? _selectedProvince = 'กรุงเทพมหานคร';

  final TextEditingController _detailController = TextEditingController();
  final TextEditingController _demandController = TextEditingController();

  List<File> _selectedImages = [];
  final ImagePicker _picker = ImagePicker();

  List<dynamic> _caseTypeList = [];

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

  Future<void> readTopic() async {
    try {
      final param = await postDio('${server}/m/topic/read', {});
      setState(() {
        print('--===--==--==-- ${param}');
        _caseTypeList = param['objectData'];
      });
    } catch (_) {}
  }

  List<Map<String, dynamic>> get _subCases {
    if (_selectedTopic == null) return [];
    final raw = _selectedTopic!['subTopics'] ?? _selectedTopic!['subCase'];
    if (raw == null || raw is! List) return [];
    return (raw as List<dynamic>)
        .whereType<Map<String, dynamic>>()
        .where((s) => (s['title'] as String? ?? '').trim().isNotEmpty)
        .toList();
  }

  bool get _hasSubCase => _subCases.isNotEmpty;

  bool get _canSubmit {
    if (_selectedTopic == null) return false;
    if (_hasSubCase && _selectedSubCase == null) return false;
    if (_selectedProvince == null) return false;
    if (_detailController.text.trim().isEmpty) return false;
    return true;
  }

  Future<void> _pickImages() async {
    final List<XFile> images = await _picker.pickMultiImage();
    if (images.isNotEmpty) {
      setState(() {
        _selectedImages.addAll(images.map((e) => File(e.path)));
      });
    }
  }

  @override
  void initState() {
    super.initState();
    readTopic();
  }

  @override
  void dispose() {
    _detailController.dispose();
    _demandController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const topicColor = Color(0xFF0262EC);

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      behavior: HitTestBehavior.opaque,
      child: Scaffold(
        backgroundColor: const Color(0xFFEEF2F5),
        appBar: appBar(
          title: 'หมอความออนไลน์',
          backBtn: true,
          rightBtn: false,
          rightAction: () {},
          backAction: () => Navigator.pop(context, false),
        ),
        body: AppLayout(
          child: SizedBox(
            height: MediaQuery.of(context).size.height,
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        _buildHeaderCard(),
                        const SizedBox(height: 16),
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
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildTopicField(),
                              const SizedBox(height: 20),
                              if (_selectedTopic != null) ...[
                                _buildSubCaseField(topicColor),
                                const SizedBox(height: 20),
                              ],
                              _buildDropdownField(
                                label: 'จังหวัด',
                                hint: 'เลือกจังหวัด',
                                icon: Icons.location_on_outlined,
                                value: _selectedProvince,
                                items: _provinces,
                                onChanged: (val) =>
                                    setState(() => _selectedProvince = val),
                              ),
                              const SizedBox(height: 20),
                              _buildTextArea(
                                label: 'สรุปเหตุการณ์',
                                hint:
                                    'อธิบายรายละเอียดคดีโดยย่อ เพื่อให้หมอความเข้าใจก่อนนัดหมาย...',
                                controller: _detailController,
                              ),
                              const SizedBox(height: 20),
                              _buildTextArea(
                                label: 'ข้อเรียกร้อง',
                                hint:
                                    'ระบุสิ่งที่ต้องการให้ทนายช่วย เช่น ฟ้องร้อง เรียกค่าเสียหาย...',
                                controller: _demandController,
                              ),
                              const SizedBox(height: 20),
                              _buildImageField(),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                _buildBottomButton(topicColor),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0262EC), Color(0xFF0485FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child:
              const Icon(Icons.balance_outlined, color: Colors.white, size: 24),
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('กรอกข้อมูลเบื้องต้น',
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16)),
              SizedBox(height: 2),
              Text('เพื่อจับคู่กับหมอความที่เหมาะสม',
                  style: TextStyle(color: Colors.white70, fontSize: 12)),
            ],
          ),
        ),
      ]),
    );
  }

  Widget _buildTopicField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'ประเภทหัวข้อ',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1A2340),
          ),
        ),
        const SizedBox(height: 10),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            childAspectRatio: 1,
          ),
          itemCount: _caseTypeList.length,
          itemBuilder: (_, i) {
            final item = _caseTypeList[i];
            final isSelected = _selectedTopic?['code'] == item['code'];
            return GestureDetector(
              onTap: () => setState(() {
                _selectedTopic = item;
                _selectedSubCase = null;
              }),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFF0262EC).withOpacity(0.1)
                      : const Color(0xFFF8F9FB),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isSelected
                        ? const Color(0xFF0262EC)
                        : const Color(0xFFE2E8F4),
                    width: isSelected ? 1.5 : 1,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: const Color(0xFF0262EC).withOpacity(0.2),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          )
                        ]
                      : [],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.network(item['imageUrl'], width: 50, height: 50),
                    const SizedBox(height: 5),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Text(
                        item['title'] as String,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight:
                              isSelected ? FontWeight.w700 : FontWeight.w500,
                          color: isSelected
                              ? const Color(0xFF0262EC)
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

  Widget _buildSubCaseField(Color topicColor) {
    final rawSubs = _selectedTopic['subTopics'];
    final subTopics =
        (rawSubs is List ? rawSubs : <dynamic>[]).whereType<dynamic>().toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('หัวข้อย่อย',
            style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1A2340))),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: _selectedSubCase?['code'] as String?,
          isExpanded: true,
          onChanged: (val) {
            final sub = subTopics.firstWhere(
              (s) => s['code'] == val,
              orElse: () => {},
            );
            setState(() => _selectedSubCase = sub);
          },
          decoration: InputDecoration(
            hintText: 'เลือกหัวข้อย่อย',
            hintStyle: TextStyle(color: Colors.grey[400], fontSize: 13),
            prefixIcon: const Icon(Icons.subdirectory_arrow_right_rounded,
                color: Color(0xFF0262EC), size: 20),
            filled: true,
            fillColor: Colors.white,
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
          ),
          icon: const Icon(Icons.keyboard_arrow_down_rounded,
              color: Color(0xFF0262EC)),
          dropdownColor: const Color(0xFFEEF2F5),
          borderRadius: BorderRadius.circular(14),
          items: subTopics
              .map<DropdownMenuItem<String>>((s) => DropdownMenuItem<String>(
                    value: s['code'] as String,
                    child: Text(s['title'] as String,
                        style: const TextStyle(fontSize: 13)),
                  ))
              .toList(),
        ),
      ],
    );
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
                color: Color(0xFF1A2340))),
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

  Widget _buildTextArea({
    required String label,
    required String hint,
    required TextEditingController controller,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1A2340))),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLines: 4,
          maxLength: 500,
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
            hintText: hint,
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
        const Text('แนบภาพหลักฐาน',
            style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1A2340))),
        const SizedBox(height: 8),
        SizedBox(
          height: 140,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                ..._selectedImages.asMap().entries.map((entry) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Stack(children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.file(entry.value,
                            width: 140, height: 140, fit: BoxFit.cover),
                      ),
                      Positioned(
                        right: 4,
                        top: 4,
                        child: GestureDetector(
                          onTap: () => setState(
                              () => _selectedImages.removeAt(entry.key)),
                          child: Container(
                            decoration: const BoxDecoration(
                                color: Colors.black54, shape: BoxShape.circle),
                            padding: const EdgeInsets.all(3),
                            child: const Icon(Icons.close,
                                color: Colors.white, size: 14),
                          ),
                        ),
                      ),
                    ]),
                  );
                }),
                GestureDetector(
                  onTap: _pickImages,
                  child: DottedBorder(
                    borderType: BorderType.RRect,
                    radius: const Radius.circular(12),
                    color: const Color(0xFFEEF2F5),
                    strokeWidth: 1.5,
                    child: Container(
                      width: 140,
                      height: 140,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.add_a_photo, color: Colors.grey),
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

  Widget _buildBottomButton(Color topicColor) {
    return Container(
      padding: EdgeInsets.fromLTRB(
          20, 12, 20, MediaQuery.of(context).padding.bottom + 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
              color: Color(0x15000000), blurRadius: 10, offset: Offset(0, -3))
        ],
      ),
      child: GestureDetector(
        onTap: _canSubmit
            ? () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ConsultSummaryPage(
                      // ── field ชุดใหม่ที่ตกลงกัน ──
                      topic: _selectedTopic!['code'] as String,
                      topicTitle: _selectedTopic!['title'] as String,
                      subTopic: _selectedSubCase?['code'] as String? ?? '',
                      subTopicTitle:
                          _selectedSubCase?['title'] as String? ?? '',
                      province: _selectedProvince!,
                      detail: _detailController.text.trim(),
                      demand: _demandController.text.trim(),
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
    );
  }
}
