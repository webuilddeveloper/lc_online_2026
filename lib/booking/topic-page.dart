import 'package:LawyerOnline/booking/lawyer-page.dart';
import 'package:LawyerOnline/component/appbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class TopicPage extends StatefulWidget {
  const TopicPage({Key? key}) : super(key: key);

  @override
  State<TopicPage> createState() => _TopicPageState();
}

class _TopicPageState extends State<TopicPage> with TickerProviderStateMixin {
  int? _expandedIndex;
  String _search = '';
  late AnimationController _entryCtrl;

  // ── Palette per category ───────────────────────────
  static const _palettes = [
    // 0: คดีที่พบบ่อย
    _Palette(Color(0xFF0262EC), Color(0xFF34AAFF), '⭐'),
    // 1: ทั่วไป
    _Palette(Color(0xFF64748B), Color(0xFF94A3B8), '💬'),
    // 2: ครอบครัวและมรดก
    _Palette(Color(0xFFE11D48), Color(0xFFFF6B9D), '👨‍👩‍👧'),
    // 3: หนี้สินและการเงิน
    _Palette(Color(0xFFFF6B35), Color(0xFFFFAA60), '💰'),
    // 4: อาญาและอาชญากรรม
    _Palette(Color(0xFFDC2626), Color(0xFFFF6B6B), '🔒'),
    // 5: ทรัพย์สินและที่ดิน
    _Palette(Color(0xFF059669), Color(0xFF34D399), '🏠'),
    // 6: ธุรกิจและบริษัท
    _Palette(Color(0xFF7C3AED), Color(0xFFA78BFA), '🏢'),
    // 7: คดีออนไลน์และเทคโนโลยี
    _Palette(Color(0xFF0891B2), Color(0xFF22D3EE), '💻'),
    // 8: แรงงานและการจ้างงาน
    _Palette(Color(0xFFD97706), Color(0xFFFBBF24), '👷'),
    // 9: ประกันภัยและผู้บริโภค
    _Palette(Color(0xFFDB2777), Color(0xFFF472B6), '🛡️'),
    // 10: ฟ้องศาล เรียกค่าเสียหาย
    _Palette(Color(0xFF6D28D9), Color(0xFFC084FC), '⚖️'),
    // 11: อื่นๆและระหว่างประเทศ
    _Palette(Color(0xFF0F766E), Color(0xFF2DD4BF), '🌐'),
  ];

  final _caseTypeList = [
    {
      "code": "0",
      "title": "ทั่วไป",
      "subCase": []
    },
    {
      "code": "1",
      "title": "คดีที่พบบ่อย",
      "subCase": [
        {"code": "0", "title": "หนี้กู้ยืมเงิน / ลูกหนี้-เจ้าหนี้ / ดอกเบี้ย"},
        {"code": "1", "title": "ตรวจร่างสัญญา / สัญญาธุรกิจ"},
        {"code": "2", "title": "พินัยกรรม / มรดก"},
        {"code": "3", "title": "อุบัติเหตุจราจร"},
        {"code": "4", "title": "หมิ่นประมาททางออนไลน์ / พ.ร.บ.คอมฯ"},
        {"code": "5", "title": "โดนโกงออนไลน์"},
        {"code": "6", "title": "ทำร้ายร่างกาย-ชีวิต / อาชญากรรม"},
        {"code": "7", "title": "พรากผู้เยาว์ / ความรุนแรงในครอบครัว"},
      ]
    },
    
    {
      "code": "2",
      "title": "ครอบครัวและมรดก",
      "subCase": [
        {"code": "0", "title": "ฟ้องชู้ / เรียกค่าทดแทน"},
        {"code": "1", "title": "พินัยกรรม / มรดก"},
        {"code": "2", "title": "ฟ้องหย่า / แบ่งสินสมรส"},
        {"code": "3", "title": "รับรองบุตร / อำนาจปกครองบุตร / เด็ก-ผู้เยาว์"},
        {"code": "4", "title": "พรากผู้เยาว์ / ความรุนแรงในครอบครัว"},
      ]
    },
    {
      "code": "3",
      "title": "หนี้สินและการเงิน",
      "subCase": [
        {"code": "0", "title": "หนี้กู้ยืมเงิน / ลูกหนี้-เจ้าหนี้ / ดอกเบี้ย"},
        {"code": "1", "title": "อายัดบัญชี / บัญชีม้า"},
        {"code": "2", "title": "เช่าซื้อ / ค้ำประกัน"},
        {"code": "3", "title": "จำนำ / จำนอง / ขายฝาก"},
        {"code": "4", "title": "สินเชื่อส่วนบุคคล / ไฟแนนซ์"},
        {"code": "5", "title": "บัตรเครดิต / เช็คเด้ง / ธุรกรรมการเงิน"},
        {"code": "6", "title": "ล้มละลาย / ฟื้นฟูกิจการ"},
        {"code": "7", "title": "บังคับคดี / ยึดทรัพย์ / สืบทรัพย์"},
      ]
    },
    {
      "code": "4",
      "title": "อาญาและอาชญากรรม",
      "subCase": [
        {"code": "0", "title": "ลักทรัพย์ / วิ่งราว / ชิงทรัพย์ / ปล้น"},
        {"code": "1", "title": "หมิ่นประมาท / ดูหมิ่น"},
        {"code": "2", "title": "ความผิดเกี่ยวกับเพศ"},
        {"code": "3", "title": "ทำร้ายร่างกาย-ชีวิต / อาชญากรรม"},
        {"code": "4", "title": "ฉ้อโกง / ยักยอกทรัพย์"},
        {"code": "5", "title": "พรากผู้เยาว์ / ความรุนแรงในครอบครัว"},
        {"code": "6", "title": "คดียาเสพติด"},
        {"code": "7", "title": "ประกันตัว / ชั้นตำรวจ / ชั้นศาล"},
        {"code": "8", "title": "ปลอมแปลง / เอกสารปลอม"},
      ]
    },
    {
      "code": "5",
      "title": "ทรัพย์สินและที่ดิน",
      "subCase": [
        {"code": "0", "title": "ซื้อขายที่ดิน / โอนที่ดิน"},
        {"code": "1", "title": "เช่าบ้าน / ขับไล่ผู้เช่า"},
        {"code": "2", "title": "บุกรุก / ครอบครองปรปักษ์"},
        {"code": "3", "title": "ซื้อ-ขายทรัพย์สิน"},
        {"code": "5", "title": "เช่าทรัพย์ / ยืม-ฝากทรัพย์"},
        {"code": "6", "title": "ภาระจำยอม / ทางจำเป็น"},
        {"code": "7", "title": "ก่อสร้าง / ผู้รับเหมาทิ้งงาน"},
      ]
    },
    {
      "code": "6",
      "title": "ธุรกิจและบริษัท",
      "subCase": [
        {"code": "0", "title": "จดทะเบียนบริษัท / ห้างหุ้นส่วน / ผู้ถือหุ้น"},
        {"code": "1", "title": "ตรวจร่างสัญญา"},
        {"code": "2", "title": "ซื้อกิจการ / ควบรวมบริษัท"},
        {"code": "3", "title": "ภาษีอากร / บัญชี / การวางแผนภาษี"},
        {"code": "5", "title": "ทรัพย์สินทางปัญญา (สิทธิบัตร, ลิขสิทธิ์, เครื่องหมายการค้า)"},
        {"code": "6", "title": "นายหน้า / ตัวแทน"},
      ]
    },
    {
      "code": "7",
      "title": "คดีออนไลน์และเทคโนโลยี",
      "subCase": [
        {"code": "0", "title": "หลอกโอนเงินออนไลน์ / แก๊งคอลเซ็นเตอร์"},
        {"code": "1", "title": "หมิ่นประมาททางออนไลน์ / พ.ร.บ.คอมฯ"},
        {"code": "2", "title": "ธุรกรรมทางอิเล็กทรอนิกส์"},
        {"code": "3", "title": "โดนโกงออนไลน์"},
      ]
    },
    {
      "code": "8",
      "title": "แรงงานและการจ้างงาน",
      "subCase": [
        {"code": "0", "title": "กฎหมายแรงงาน"},
        {"code": "1", "title": "สัญญาจ้างงาน / ข้อบังคับทำงาน"},
        {"code": "2", "title": "เลิกจ้างไม่เป็นธรรม / เงินชดเชย"},
        {"code": "3", "title": "จ้างทำของ / ฟรีแลนซ์"},
        {"code": "4", "title": "แรงงานต่างด้าว"},
        {"code": "5", "title": "สหภาพแรงงาน"},
      ]
    },
    {
      "code": "9",
      "title": "ประกันภัยและผู้บริโภค",
      "subCase": [
        {"code": "0", "title": "ประกันภัย / เคลมประกัน คปภ."},
        {"code": "1", "title": "คดีผู้บริโภค (กรณีสินค้าไม่ตรงปก / สินค้าอันตราย ฯลฯ)"},
        {"code": "2", "title": "อุบัติเหตุจราจร"},
        {"code": "3", "title": "ฟ้องแพทย์ / โรงพยาบาล / อาหารและยา"},
      ]
    },
    {
      "code": "10",
      "title": "ฟ้องศาล เรียกค่าเสียหาย",
      "subCase": [
        {"code": "0", "title": "ละเมิดฟ้องเรียกค่าเสียหาย"},
        {"code": "1", "title": "อุบัติเหตุจราจร"},
        {"code": "2", "title": "เหตุเดือดร้อนรำคาญ"},
        {"code": "3", "title": "ทำร้ายร่างกาย-ชีวิต / อาชญากรรม"},
      ]
    },
    {
      "code": "11",
      "title": "อื่นๆและระหว่างประเทศ",
      "subCase": [
        {"code": "0", "title": "โนตาลีรับรองเอกสาร (Notarial Public Attorney)"},
        {"code": "1", "title": "Visa / Work Permit"},
        {"code": "2", "title": "กฎหมายการค้าระหว่างประเทศ"},
        {"code": "3", "title": "นำเข้า-ส่งออก / ศุลกากร"},
      ]
    },
  ];

  @override
  void initState() {
    super.initState();
    _entryCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();
  }

  @override
  void dispose() {
    _entryCtrl.dispose();
    super.dispose();
  }

  List<dynamic> get _filtered {
    if (_search.isEmpty) return _caseTypeList;
    return _caseTypeList.where((item) {
      final title = (item['title'] as String).toLowerCase();
      final sub = (item['subCase'] as List).any(
          (s) => (s['title'] as String).toLowerCase().contains(_search.toLowerCase()));
      return title.contains(_search.toLowerCase()) || sub;
    }).toList();
  }

  void _navigateToLawyer(dynamic topic, dynamic sub) {
    HapticFeedback.lightImpact();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => LawyerPage(
          topic: topic['title'] as String,
          subTopic: sub['title'] as String,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;

    return Scaffold(
      backgroundColor: const Color(0xFFF2F6FF),
      appBar: appBar(
        title: "นัดหมายทนาย",
        backBtn: true,
        rightBtn: false,
        backAction: () => Navigator.pop(context, false),
        rightAction: () {},
      ),
      body: Column(
        children: [
          // ── Header ──────────────────────────────────
          _buildHeader(),

          // ── Search ──────────────────────────────────
          _buildSearchBar(),

          // ── List ────────────────────────────────────
          Expanded(
            child: filtered.isEmpty
                ? _buildEmpty()
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 40),
                    itemCount: filtered.length,
                    itemBuilder: (_, i) {
                      final item = filtered[i];
                      final origIdx = _caseTypeList.indexOf(item);
                      final palette = _palettes[origIdx % _palettes.length];
                      final isExpanded = _expandedIndex == i;
                      final delay = (i * 0.07).clamp(0.0, 0.7);

                      return AnimatedBuilder(
                        animation: _entryCtrl,
                        builder: (_, child) {
                          final t = Curves.easeOutCubic.transform(
                            ((_entryCtrl.value - delay) / (1 - delay))
                                .clamp(0.0, 1.0),
                          );
                          return Opacity(
                            opacity: t,
                            child: Transform.translate(
                              offset: Offset(0, 28 * (1 - t)),
                              child: child,
                            ),
                          );
                        },
                        child: _CategoryCard(
                          item: item,
                          palette: palette,
                          isExpanded: isExpanded,
                          searchQuery: _search,
                          onHeaderTap: () {
                            HapticFeedback.selectionClick();
                            final subCases = (item['subCase'] as List)
                                .where((s) => (s['title'] as String).trim().isNotEmpty)
                                .toList();
                            if (subCases.isEmpty) {
                              // ไม่มี sub-case → navigate ไปเลย
                              _navigateToLawyer(item, {'title': ''});
                            } else {
                              setState(() =>
                                  _expandedIndex = isExpanded ? null : i);
                            }
                          },
                          onSubTap: (sub) => _navigateToLawyer(item, sub),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(9),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF0262EC), Color(0xFF34AAFF)],
            ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0262EC).withOpacity(0.4),
                blurRadius: 14,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: const Icon(Icons.gavel_rounded,
              color: Colors.white, size: 18),
        ),
        const SizedBox(width: 10),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text(
            'เลือกประเภทหัวข้อ',
            style: TextStyle(
              color: const Color(0xFF1A2340),
              fontSize: 16,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3,
            ),
          ),
          Text(
            'กดเพื่อดูหัวข้อย่อย แล้วเลือกทนายที่ใช่',
            style: TextStyle(
                color: const Color(0xFF1A2340).withOpacity(0.4), fontSize: 11),
          ),
        ]),
      ]),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
      child: Container(
        height: 44,
        decoration: BoxDecoration(
          color: const Color(0xFFE2E8F4),
          borderRadius: BorderRadius.circular(13),
          border: Border.all(color: const Color(0xFFDDE5F0), width: 1.5),
        ),
        child: TextField(
          onChanged: (v) => setState(() {
            _search = v;
            _expandedIndex = null;
          }),
          style: const TextStyle(color: const Color(0xFF1A2340), fontSize: 13),
          decoration: InputDecoration(
            hintText: 'ค้นหาประเภทคดี...',
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

  Widget _buildEmpty() {
    return Center(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: const Color(0xFFF0F4F8),
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.search_off_rounded,
              color: const Color(0xFF1A2340).withOpacity(0.25), size: 28),
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
                color: const Color(0xFF1A2340).withOpacity(0.3), fontSize: 12)),
      ]),
    );
  }
}

// ══════════════════════════════════════════════════════════
//  Category Card
// ══════════════════════════════════════════════════════════

class _CategoryCard extends StatelessWidget {
  final Map<String, dynamic> item;
  final _Palette palette;
  final bool isExpanded;
  final String searchQuery;
  final VoidCallback onHeaderTap;
  final Function(Map<String, dynamic>) onSubTap;

  const _CategoryCard({
    required this.item,
    required this.palette,
    required this.isExpanded,
    required this.searchQuery,
    required this.onHeaderTap,
    required this.onSubTap,
  });

  @override
  Widget build(BuildContext context) {
    final subCases = (item['subCase'] as List<dynamic>)
        .cast<Map<String, dynamic>>()
        .where((s) => (s['title'] as String).trim().isNotEmpty)
        .toList();

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: isExpanded
            ? const Color(0xFFEEF4FF)
            : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isExpanded
              ? palette.primary.withOpacity(0.45)
              : const Color(0xFFE2E8F4),
          width: isExpanded ? 1.5 : 1,
        ),
        boxShadow: isExpanded
            ? [
                BoxShadow(
                  color: palette.primary.withOpacity(0.12),
                  blurRadius: 20,
                  offset: const Offset(0, 6),
                ),
                const BoxShadow(
                  color: Color(0xFFDDE5F0),
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ]
            : [
                const BoxShadow(
                  color: Color(0xFFDDE5F0),
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Column(
          children: [
            // ── Header ──────────────────────────────────
            GestureDetector(
              onTap: onHeaderTap,
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  gradient: isExpanded
                      ? LinearGradient(
                          colors: [
                            palette.primary.withOpacity(0.08),
                            Colors.transparent,
                          ],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        )
                      : null,
                ),
                child: Row(children: [
                  // Icon with gradient bg + glow
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [palette.primary, palette.secondary],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(13),
                      boxShadow: [
                        BoxShadow(
                          color: palette.primary.withOpacity(
                              isExpanded ? 0.5 : 0.25),
                          blurRadius: isExpanded ? 14 : 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(palette.emoji,
                          style: const TextStyle(fontSize: 20)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _HighlightText(
                          text: item['title'] as String,
                          query: searchQuery,
                          style: const TextStyle(
                            color: const Color(0xFF1A2340),
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.2,
                          ),
                          highlightStyle: TextStyle(
                            color: palette.secondary,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          subCases.isEmpty ? 'กดเพื่อเลือกทนายความ' : '${subCases.length} หัวข้อย่อย',
                          style: TextStyle(
                            color: subCases.isEmpty
                                ? palette.primary
                                : const Color(0xFF1A2340).withOpacity(0.35),
                            fontSize: 10,
                            fontWeight: subCases.isEmpty ? FontWeight.w600 : FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Chevron
                  AnimatedRotation(
                    turns: isExpanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeInOut,
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: isExpanded
                            ? palette.primary.withOpacity(0.2)
                            : const Color(0xFFF1F5FB),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        subCases.isEmpty ?
                        Icons.arrow_forward_ios_rounded :
                        Icons.keyboard_arrow_down_rounded,
                        size: subCases.isEmpty ? 10 : 18,
                        color: isExpanded
                            ? palette.secondary
                            : const Color(0xFF9AAABB),
                      ),
                    ),
                  ),
                ]),
              ),
            ),

            // ── Sub Cases ────────────────────────────────
            AnimatedCrossFade(
              firstChild: const SizedBox(width: double.infinity),
              secondChild: Container(
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(
                        color: palette.primary.withOpacity(0.18)),
                  ),
                ),
                child: Column(
                  children: subCases.asMap().entries.map((e) {
                    final idx = e.key;
                    final sub = e.value;
                    final isLast = idx == subCases.length - 1;

                    return GestureDetector(
                      onTap: () => onSubTap(sub),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          border: !isLast
                              ? Border(
                                  bottom: BorderSide(
                                    color: const Color(0xFFF0F4F8),
                                  ),
                                )
                              : null,
                        ),
                        child: Row(children: [
                          // Gradient dot
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  palette.primary,
                                  palette.secondary
                                ],
                              ),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _HighlightText(
                              text: sub['title'] as String,
                              query: searchQuery,
                              style: TextStyle(
                                color: const Color(0xFF1A2340).withOpacity(0.75),
                                fontSize: 13,
                                height: 1.4,
                              ),
                              highlightStyle: TextStyle(
                                color: palette.secondary,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            Icons.arrow_forward_ios_rounded,
                            size: 10,
                            color: const Color(0xFF1A2340).withOpacity(0.2),
                          ),
                        ]),
                      ),
                    );
                  }).toList(),
                ),
              ),
              crossFadeState: isExpanded
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
              duration: const Duration(milliseconds: 280),
              sizeCurve: Curves.easeInOut,
            ),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════
//  Highlight Text
// ══════════════════════════════════════════════════════════

class _HighlightText extends StatelessWidget {
  final String text;
  final String query;
  final TextStyle style;
  final TextStyle highlightStyle;

  const _HighlightText({
    required this.text,
    required this.query,
    required this.style,
    required this.highlightStyle,
  });

  @override
  Widget build(BuildContext context) {
    if (query.isEmpty) return Text(text, style: style);

    final lower = text.toLowerCase();
    final qLower = query.toLowerCase();
    final spans = <TextSpan>[];
    int start = 0;

    while (true) {
      final idx = lower.indexOf(qLower, start);
      if (idx == -1) {
        spans.add(TextSpan(text: text.substring(start), style: style));
        break;
      }
      if (idx > start) {
        spans.add(TextSpan(text: text.substring(start, idx), style: style));
      }
      spans.add(TextSpan(
          text: text.substring(idx, idx + query.length),
          style: highlightStyle));
      start = idx + query.length;
    }

    return RichText(text: TextSpan(children: spans));
  }
}

// ══════════════════════════════════════════════════════════
//  Data Class
// ══════════════════════════════════════════════════════════

class _Palette {
  final Color primary;
  final Color secondary;
  final String emoji;
  const _Palette(this.primary, this.secondary, this.emoji);
}