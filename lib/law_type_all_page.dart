import 'package:LawyerOnline/component/appbar.dart';
import 'package:LawyerOnline/lawyer-online-list.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class LawTypeAllPage extends StatefulWidget {
  const LawTypeAllPage({super.key});

  @override
  State<LawTypeAllPage> createState() => _LawTypeAllPageState();
}

class _LawTypeAllPageState extends State<LawTypeAllPage> {
  dynamic _selectedTopic;
  dynamic _selectedSubTopic;
  String _search = '';

  // ── caseTypeList + emoji + color (เหมือน ConsultPage) ─
  final List<Map<String, dynamic>> _caseTypeList = [
    {
      'code': '0',
      'title': 'ทั่วไป',
      'emoji': '💬',
      'color': 0xFF64748B,
      'subCase': <Map<String, dynamic>>[],
    },
    {
      'code': '1',
      'title': 'คดีที่พบบ่อย',
      'emoji': '⭐',
      'color': 0xFF0262EC,
      'subCase': [
        {'code': '0', 'title': 'หนี้กู้ยืมเงิน / ลูกหนี้-เจ้าหนี้ / ดอกเบี้ย'},
        {'code': '1', 'title': 'ตรวจร่างสัญญา / สัญญาธุรกิจ'},
        {'code': '2', 'title': 'พินัยกรรม / มรดก'},
        {'code': '3', 'title': 'อุบัติเหตุจราจร'},
        {'code': '4', 'title': 'หมิ่นประมาททางออนไลน์ / พ.ร.บ.คอมฯ'},
        {'code': '5', 'title': 'โดนโกงออนไลน์'},
        {'code': '6', 'title': 'ทำร้ายร่างกาย-ชีวิต / อาชญากรรม'},
        {'code': '7', 'title': 'พรากผู้เยาว์ / ความรุนแรงในครอบครัว'},
      ],
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
        {'code': '5', 'title': 'ทรัพย์สินทางปัญญา (สิทธิบัตร, ลิขสิทธิ์, เครื่องหมายการค้า)'},
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
        {'code': '1', 'title': 'คดีผู้บริโภค (กรณีสินค้าไม่ตรงปก / สินค้าอันตราย ฯลฯ)'},
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

  List<Map<String, dynamic>> get _subCases {
    if (_selectedTopic == null) return [];
    return (_selectedTopic!['subCase'] as List<dynamic>)
        .cast<Map<String, dynamic>>()
        .where((s) => (s['title'] as String).trim().isNotEmpty)
        .toList();
  }

  bool get _hasSubCase => _subCases.isNotEmpty;

  List<Map<String, dynamic>> get _filtered {
    if (_search.isEmpty) return _caseTypeList;
    return _caseTypeList.where((item) {
      final title = (item['title'] as String).toLowerCase();
      final sub = (item['subCase'] as List).any((s) =>
          (s['title'] as String).toLowerCase().contains(_search.toLowerCase()));
      return title.contains(_search.toLowerCase()) || sub;
    }).toList();
  }

  void _navigate(Map<String, dynamic> topic) {
    HapticFeedback.lightImpact();
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => LawyerOnlineList(topic: topic['title'] as String, subTopic: _selectedSubTopic['title'],),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;
    final selectedColor = _selectedTopic != null
        ? Color(_selectedTopic!['color'] as int)
        : const Color(0xFF0262EC);

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      behavior: HitTestBehavior.opaque,
      child: Scaffold(
        backgroundColor: const Color(0xFFF2F6FF),
        appBar: appBarCustom(
          title: 'ประเภทกฎหมายทั้งหมด',
          backBtn: true,
          isRightWidget: false,
          backAction: () => Navigator.pop(context),
        ),
        body: Column(
          children: [
            // ── Search bar ──────────────────────────────
            _buildSearchBar(),

            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Grid ──────────────────────────────
                    if (filtered.isEmpty)
                      _buildEmpty()
                    else
                      _buildGrid(filtered),

                    // ── Sub-case dropdown (ถ้าเลือก topic ที่มี subCase) ──
                    if (_selectedTopic != null && _hasSubCase) ...[
                      const SizedBox(height: 20),
                      _buildSubCaseSection(selectedColor),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ════════════════════════════════════════════════════════
  //  Search Bar
  // ════════════════════════════════════════════════════════

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Container(
        height: 44,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(13),
          border: Border.all(color: const Color(0xFFDDE5F0)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: TextField(
          onChanged: (v) => setState(() {
            _search = v;
            if (_selectedTopic != null) {
              // ถ้า topic ที่เลือกไม่อยู่ใน filtered ให้ reset
              final titles = _filtered.map((e) => e['title']).toList();
              if (!titles.contains(_selectedTopic!['title'])) {
                _selectedTopic = null;
              }
            }
          }),
          style: const TextStyle(color: Color(0xFF1A2340), fontSize: 13),
          decoration: InputDecoration(
            hintText: 'ค้นหาประเภทกฎหมาย...',
            hintStyle: TextStyle(
                color: const Color(0xFF1A2340).withOpacity(0.3), fontSize: 13),
            prefixIcon: Icon(Icons.search_rounded,
                color: const Color(0xFF1A2340).withOpacity(0.35), size: 18),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 12),
          ),
        ),
      ),
    );
  }

  // ════════════════════════════════════════════════════════
  //  Grid — copy จาก ConsultPage._buildTopicField()
  // ════════════════════════════════════════════════════════

  Widget _buildGrid(List<Map<String, dynamic>> items) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 1.1,
      ),
      itemCount: items.length,
      itemBuilder: (_, i) {
        final item = items[i];
        final color = Color(item['color'] as int);
        final isSelected = _selectedTopic?['code'] == item['code'];

        return GestureDetector(
          onTap: () {
            HapticFeedback.lightImpact();
            final subCases = (item['subCase'] as List)
                .where((s) => (s['title'] as String).trim().isNotEmpty)
                .toList();
            if (subCases.isEmpty) {
              // ทั่วไป → navigate เลย
              _navigate(item);
            } else {
              setState(() {
                _selectedTopic = isSelected ? null : item;
              });
            }
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            decoration: BoxDecoration(
              color: isSelected
                  ? color.withOpacity(0.1)
                  : const Color(0xFFF8F9FB),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isSelected ? color : const Color(0xFFE2E8F4),
                width: isSelected ? 1.5 : 1,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: color.withOpacity(0.2),
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
                      color:
                          isSelected ? color : const Color(0xFF5B6E8A),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ════════════════════════════════════════════════════════
  //  Sub-case section — โผล่หลัง grid เมื่อเลือก topic
  // ════════════════════════════════════════════════════════

  Widget _buildSubCaseSection(Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Container(
            width: 8,
            height: 8,
            decoration:
                BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Text(
            'หัวข้อย่อยของ "${_selectedTopic!['title']}"',
            style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1A2340)),
          ),
        ]),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withOpacity(0.25)),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.08),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: _subCases.asMap().entries.map((e) {
              final idx = e.key;
              final sub = e.value;
              final isLast = idx == _subCases.length - 1;
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedSubTopic = sub;
                  });
                  _navigate(_selectedTopic!);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 13),
                  decoration: BoxDecoration(
                    border: !isLast
                        ? const Border(
                            bottom: BorderSide(
                                color: Color(0xFFF0F4F8)))
                        : null,
                  ),
                  child: Row(children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        sub['title'] as String,
                        style: TextStyle(
                          fontSize: 13,
                          color:
                              const Color(0xFF1A2340).withOpacity(0.75),
                          height: 1.4,
                        ),
                      ),
                    ),
                    Icon(Icons.arrow_forward_ios_rounded,
                        size: 11,
                        color:
                            const Color(0xFF1A2340).withOpacity(0.2)),
                  ]),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.only(top: 60),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 64,
            height: 64,
            decoration: const BoxDecoration(
                color: Color(0xFFF0F4F8), shape: BoxShape.circle),
            child: Icon(Icons.search_off_rounded,
                color: const Color(0xFF1A2340).withOpacity(0.25),
                size: 28),
          ),
          const SizedBox(height: 12),
          Text('ไม่พบ "$_search"',
              style: TextStyle(
                  color: const Color(0xFF1A2340).withOpacity(0.55),
                  fontSize: 14,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text('ลองค้นหาด้วยคำอื่น',
              style: TextStyle(
                  color: const Color(0xFF1A2340).withOpacity(0.3),
                  fontSize: 12)),
        ]),
      ),
    );
  }
}