import 'dart:io';
import 'package:LawyerOnline/component/appbar.dart';
import 'package:LawyerOnline/consult/consult_sum.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

class ConsultPage extends StatefulWidget {
  const ConsultPage({super.key});

  @override
  State<ConsultPage> createState() => _ConsultPageState();
}

class _ConsultPageState extends State<ConsultPage> {
  // ── ข้อมูลที่เลือก ──────────────────────────────────────
  Map<String, dynamic>? _selectedTopic; // หมวดหลัก
  Map<String, dynamic>? _selectedSubCase; // หัวข้อย่อย

  DateTime? _selectedDate = DateTime.now();
  String? _selectedProvince = 'กรุงเทพมหานคร';

  final TextEditingController _detailController = TextEditingController();
  final TextEditingController _demandController = TextEditingController();
  final TextEditingController _wageController = TextEditingController();

  List<File> _selectedImages = [];
  final ImagePicker _picker = ImagePicker();

  // ══════════════════════════════════════════════════════
  //  caseTypeList — ตรงกับ TopicPage ทุกประการ
  // ══════════════════════════════════════════════════════
  final List<Map<String, dynamic>> _caseTypeList = [
    {
      'code': '0',
      'title': 'คดีที่พบบ่อย',
      'emoji': '⭐',
      'color': 0xFF0262EC,
      'subCase': [
        {'code': '0', 'title': 'ฟ้องชู้ / เรียกค่าทดแทน'},
        {'code': '1', 'title': 'พินัยกรรม / มรดก'},
        {'code': '2', 'title': 'ฟ้องหย่า / แบ่งสินสมรส'},
        {'code': '3', 'title': 'รับรองบุตร / อำนาจปกครองบุตร / เด็ก-ผู้เยาว์'},
        {'code': '4', 'title': 'พรากผู้เยาว์ / ความรุนแรงในครอบครัว'},
      ],
    },
    {
      'code': '1',
      'title': 'ทั่วไป',
      'emoji': '💬',
      'color': 0xFF64748B,
      'subCase': [],
    },
    {
      'code': '2',
      'title': 'ครอบครัวและมรดก',
      'emoji': '👨‍👩‍👧',
      'color': 0xFFE11D48,
      'subCase': [
        {'code': '0', 'title': 'ฟ้องชู้ / เรียกค่าทดแทน'},
        {'code': '1', 'title': 'พินัยกรรม / มรดก'},
        {'code': '2', 'title': 'ฟ้องหย่า / แบ่งสินสมรส'},
        {'code': '3', 'title': 'รับรองบุตร / อำนาจปกครองบุตร / เด็ก-ผู้เยาว์'},
        {'code': '4', 'title': 'พรากผู้เยาว์ / ความรุนแรงในครอบครัว'},
      ],
    },
    {
      'code': '3',
      'title': 'หนี้สินและการเงิน',
      'emoji': '💰',
      'color': 0xFFFF6B35,
      'subCase': [
        {'code': '0', 'title': 'หนี้กู้ยืมเงิน / ลูกหนี้-เจ้าหนี้ / ดอกเบี้ย'},
        {'code': '1', 'title': 'อายัดบัญชี / บัญชีม้า'},
        {'code': '2', 'title': 'เช่าซื้อ / ค้ำประกัน'},
        {'code': '3', 'title': 'จำนำ / จำนอง / ขายฝาก'},
        {'code': '4', 'title': 'สินเชื่อส่วนบุคคล / ไฟแนนซ์'},
        {'code': '5', 'title': 'บัตรเครดิต / เช็คเด้ง / ธุรกรรมการเงิน'},
        {'code': '6', 'title': 'ล้มละลาย / ฟื้นฟูกิจการ'},
        {'code': '7', 'title': 'บังคับคดี / ยึดทรัพย์ / สืบทรัพย์'},
      ],
    },
    {
      'code': '4',
      'title': 'อาญาและอาชญากรรม',
      'emoji': '🔒',
      'color': 0xFFDC2626,
      'subCase': [
        {'code': '0', 'title': 'ลักทรัพย์ / วิ่งราว / ชิงทรัพย์ / ปล้น'},
        {'code': '1', 'title': 'หมิ่นประมาท / ดูหมิ่น'},
        {'code': '2', 'title': 'ความผิดเกี่ยวกับเพศ'},
        {'code': '3', 'title': 'ทำร้ายร่างกาย-ชีวิต / อาชญากรรม'},
        {'code': '4', 'title': 'ฉ้อโกง / ยักยอกทรัพย์'},
        {'code': '5', 'title': 'พรากผู้เยาว์ / ความรุนแรงในครอบครัว'},
        {'code': '6', 'title': 'คดียาเสพติด'},
        {'code': '7', 'title': 'ประกันตัว / ชั้นตำรวจ / ชั้นศาล'},
        {'code': '8', 'title': 'ปลอมแปลง / เอกสารปลอม'},
      ],
    },
    {
      'code': '5',
      'title': 'ทรัพย์สินและที่ดิน',
      'emoji': '🏠',
      'color': 0xFF059669,
      'subCase': [
        {'code': '0', 'title': 'ซื้อขายที่ดิน / โอนที่ดิน'},
        {'code': '1', 'title': 'เช่าบ้าน / ขับไล่ผู้เช่า'},
        {'code': '2', 'title': 'บุกรุก / ครอบครองปรปักษ์'},
        {'code': '3', 'title': 'ซื้อ-ขายทรัพย์สิน'},
        {'code': '5', 'title': 'เช่าทรัพย์ / ยืม-ฝากทรัพย์'},
        {'code': '6', 'title': 'ภาระจำยอม / ทางจำเป็น'},
        {'code': '7', 'title': 'ก่อสร้าง / ผู้รับเหมาทิ้งงาน'},
      ],
    },
    {
      'code': '6',
      'title': 'ธุรกิจและบริษัท',
      'emoji': '🏢',
      'color': 0xFF7C3AED,
      'subCase': [
        {'code': '0', 'title': 'จดทะเบียนบริษัท / ห้างหุ้นส่วน / ผู้ถือหุ้น'},
        {'code': '1', 'title': 'ตรวจร่างสัญญา'},
        {'code': '2', 'title': 'ซื้อกิจการ / ควบรวมบริษัท'},
        {'code': '3', 'title': 'ภาษีอากร / บัญชี / การวางแผนภาษี'},
        {
          'code': '5',
          'title': 'ทรัพย์สินทางปัญญา (สิทธิบัตร, ลิขสิทธิ์, เครื่องหมายการค้า)'
        },
        {'code': '6', 'title': 'นายหน้า / ตัวแทน'},
      ],
    },
    {
      'code': '7',
      'title': 'คดีออนไลน์และเทคโนโลยี',
      'emoji': '💻',
      'color': 0xFF0891B2,
      'subCase': [
        {'code': '0', 'title': 'หลอกโอนเงินออนไลน์ / แก๊งคอลเซ็นเตอร์'},
        {'code': '1', 'title': 'หมิ่นประมาททางออนไลน์ / พ.ร.บ.คอมฯ'},
        {'code': '2', 'title': 'ธุรกรรมทางอิเล็กทรอนิกส์'},
        {'code': '3', 'title': 'โดนโกงออนไลน์'},
      ],
    },
    {
      'code': '8',
      'title': 'แรงงานและการจ้างงาน',
      'emoji': '👷',
      'color': 0xFFD97706,
      'subCase': [
        {'code': '0', 'title': 'กฎหมายแรงงาน'},
        {'code': '1', 'title': 'สัญญาจ้างงาน / ข้อบังคับทำงาน'},
        {'code': '2', 'title': 'เลิกจ้างไม่เป็นธรรม / เงินชดเชย'},
        {'code': '3', 'title': 'จ้างทำของ / ฟรีแลนซ์'},
        {'code': '4', 'title': 'แรงงานต่างด้าว'},
        {'code': '5', 'title': 'สหภาพแรงงาน'},
      ],
    },
    {
      'code': '9',
      'title': 'ประกันภัยและผู้บริโภค',
      'emoji': '🛡️',
      'color': 0xFFDB2777,
      'subCase': [
        {'code': '0', 'title': 'ประกันภัย / เคลมประกัน คปภ.'},
        {
          'code': '1',
          'title': 'คดีผู้บริโภค (กรณีสินค้าไม่ตรงปก / สินค้าอันตราย ฯลฯ)'
        },
        {'code': '2', 'title': 'อุบัติเหตุจราจร'},
        {'code': '3', 'title': 'ฟ้องแพทย์ / โรงพยาบาล / อาหารและยา'},
      ],
    },
    {
      'code': '10',
      'title': 'ฟ้องศาล เรียกค่าเสียหาย',
      'emoji': '⚖️',
      'color': 0xFF6D28D9,
      'subCase': [
        {'code': '0', 'title': 'ละเมิดฟ้องเรียกค่าเสียหาย'},
        {'code': '1', 'title': 'อุบัติเหตุจราจร'},
        {'code': '2', 'title': 'เหตุเดือดร้อนรำคาญ'},
        {'code': '3', 'title': 'ทำร้ายร่างกาย-ชีวิต / อาชญากรรม'},
      ],
    },
    {
      'code': '11',
      'title': 'อื่นๆและระหว่างประเทศ',
      'emoji': '🌐',
      'color': 0xFF0F766E,
      'subCase': [
        {'code': '0', 'title': 'โนตาลีรับรองเอกสาร (Notarial Public Attorney)'},
        {'code': '1', 'title': 'Visa / Work Permit'},
        {'code': '2', 'title': 'กฎหมายการค้าระหว่างประเทศ'},
        {'code': '3', 'title': 'นำเข้า-ส่งออก / ศุลกากร'},
      ],
    },
  ];

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

  // ── helper: sub-cases ของ topic ที่เลือก ─────────────
  List<Map<String, dynamic>> get _subCases {
    if (_selectedTopic == null) return [];
    return (_selectedTopic!['subCase'] as List<dynamic>)
        .cast<Map<String, dynamic>>()
        .where((s) => (s['title'] as String).trim().isNotEmpty)
        .toList();
  }

  bool get _hasSubCase => _subCases.isNotEmpty;

  bool get _canSubmit {
    if (_selectedTopic == null) return false;
    if (_hasSubCase && _selectedSubCase == null) return false;
    if (_selectedDate == null) return false;
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
  void dispose() {
    _detailController.dispose();
    _demandController.dispose();
    _wageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final topicColor = _selectedTopic != null
        ? Color(_selectedTopic!['color'] as int)
        : const Color(0xFF0262EC);

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
        body: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    // ── Header gradient ──────────────────
                    _buildHeaderCard(),
                    const SizedBox(height: 16),

                    // ── Form card ────────────────────────
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
                          // ── ประเภทหัวข้อ ─────────────
                          _buildTopicField(),
                          const SizedBox(height: 20),

                          // ── หัวข้อย่อย (ถ้ามี) ──────
                          if (_selectedTopic != null && _hasSubCase) ...[
                            _buildSubCaseField(topicColor),
                            const SizedBox(height: 20),
                          ],

                          // ── วันที่ ───────────────────
                          _buildDateField(),
                          const SizedBox(height: 20),

                          // ── จังหวัด ─────────────────
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

                          // ── สรุปเหตุการณ์ ────────────
                          _buildTextArea(
                            label: 'สรุปเหตุการณ์',
                            hint:
                                'อธิบายรายละเอียดคดีโดยย่อ เพื่อให้หมอความเข้าใจก่อนนัดหมาย...',
                            controller: _detailController,
                          ),
                          const SizedBox(height: 20),

                          // ── ข้อเรียกร้อง ─────────────
                          _buildTextArea(
                            label: 'ข้อเรียกร้อง',
                            hint:
                                'ระบุสิ่งที่ต้องการให้ทนายช่วย เช่น ฟ้องร้อง เรียกค่าเสียหาย...',
                            controller: _demandController,
                          ),
                          const SizedBox(height: 20),

                          // ── แนบภาพ ───────────────────
                          _buildImageField(),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── Bottom Button ────────────────────────────
            _buildBottomButton(topicColor),
          ],
        ),
      ),
    );
  }

  // ════════════════════════════════════════════════════════
  //  Header Card
  // ════════════════════════════════════════════════════════

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
              Text('กรอกข้อมูลเบื้อต้น',
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

  // ════════════════════════════════════════════════════════
  //  Topic Field — แสดง grid หมวดหมู่ เหมือน TopicPage
  // ════════════════════════════════════════════════════════

  Widget _buildTopicField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('ประเภทหัวข้อ',
            style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1A2340))),
        const SizedBox(height: 10),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            childAspectRatio: 1.1,
          ),
          itemCount: _caseTypeList.length,
          itemBuilder: (_, i) {
            final item = _caseTypeList[i];
            final color = Color(item['color'] as int);
            final isSelected = _selectedTopic?['code'] == item['code'];

            return GestureDetector(
              onTap: () {
                setState(() {
                  _selectedTopic = item;
                  _selectedSubCase = null;
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Color(0xFF0262EC).withOpacity(0.1)
                      : const Color(0xFFF8F9FB),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isSelected
                        ? Color(0xFF0262EC)
                        : const Color(0xFFE2E8F4),
                    width: isSelected ? 1.5 : 1,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: Color(0xFF0262EC).withOpacity(0.2),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          )
                        ]
                      : [],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(item['emoji'] as String,
                        style: const TextStyle(fontSize: 22)),
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
                              ? Color(0xFF0262EC)
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
  //  Sub-case Field — Dropdown หัวข้อย่อย
  // ════════════════════════════════════════════════════════

  Widget _buildSubCaseField(Color topicColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          // Container(
          //   width: 8,
          //   height: 8,
          //   decoration: BoxDecoration(
          //     color: topicColor,
          //     shape: BoxShape.circle,
          //   ),
          // ),
          // const SizedBox(width: 6),
          const Text('หัวข้อย่อย',
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1A2340))),
        ]),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: _selectedSubCase?['title'] as String?,
          isExpanded: true, 
          onChanged: (val) {
            final sub = _subCases.firstWhere((s) => s['title'] == val,
                orElse: () => {});
            setState(() => _selectedSubCase = sub.isEmpty ? null : sub);
          },
          decoration: InputDecoration(
            hintText: 'เลือกหัวข้อย่อย',
            hintStyle: TextStyle(color: Colors.grey[400], fontSize: 13),
            prefixIcon: Icon(Icons.subdirectory_arrow_right_rounded,
                color: Color(0xFF0262EC), size: 20),
            filled: true,
            fillColor: Colors.white,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: Color(0xFFEEF2F5), width: 1.5),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: Color(0xFFEEF2F5), width: 1.5),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: Color(0xFF0262EC), width: 1.5),
            ),
          ),
          icon: Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF0262EC)),
          dropdownColor: Color(0xFFEEF2F5),
          borderRadius: BorderRadius.circular(14),
          items: _subCases
              .map((s) => DropdownMenuItem<String>(
                    value: s['title'] as String,
                    
                    child: Text(
                      s['title'] as String,
                      style: const TextStyle(fontSize: 13),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ))
              .toList(),
        ),
      ],
    );
  }

  // ════════════════════════════════════════════════════════
  //  Reusable Widgets (เหมือนเดิม)
  // ════════════════════════════════════════════════════════

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

  Widget _buildDateField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('วันที่นัดหมาย',
            style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1A2340))),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
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
              border: Border.all(color: const Color(0xFFEEF2F5), width: 1.5),
            ),
            child: Row(children: [
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
            ]),
          ),
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
                      category: _selectedTopic!['title'] as String,
                      subCategory: _selectedSubCase?['title'] as String? ?? '',
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
                ? LinearGradient(
                    colors: [Color(0xFF0262EC), Color(0xFF0262EC).withOpacity(0.8)])
                : null,
            color: _canSubmit ? null : const Color(0xFFCDD5E0),
            borderRadius: BorderRadius.circular(14),
            boxShadow: _canSubmit
                ? [
                    BoxShadow(
                      color: Color(0xFF0262EC).withOpacity(0.3),
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
