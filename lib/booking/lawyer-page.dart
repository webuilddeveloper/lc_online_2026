import 'package:LawyerOnline/booking/lawyer-details.dart';
import 'package:LawyerOnline/component/appbar.dart';
import 'package:flutter/material.dart';

class LawyerPage extends StatefulWidget {
  final String topic;
  final String subTopic;

  const LawyerPage({
    required this.topic,
    required this.subTopic,
  });

  @override
  State<LawyerPage> createState() => _LawyerPageState();
}

class _LawyerPageState extends State<LawyerPage> {
  int? _selectedIdx;

  // ── Filter State ───────────────────────────────────────
  bool _filterAvailableOnly = false;
  String _sortBy = 'none'; // none | rating | experience | distance
  String _searchText = '';

  final List<dynamic> _lawyers = [
    {
      'name': 'ศักดิ์สิทธิ์ พิพากษ์',
      'title': 'ทนายความอาวุโส',
      'specialty': 'Criminal lawyer, Corporate lawyer',
      'experience': '11+ ปี',
      'experienceYears': 11,
      'rating': 5.0,
      'reviews': 60,
      'price': 500,
      'distance': '1.2 กม.',
      'distanceKm': 1.2,
      'eta': '~3 นาที',
      'available': true,
      'office': 'สำนักงาน ศักดิ์สิทธิ์',
      'avatar': 'ศ',
      'color': 0xFF1565C0,
      'imageUrl': 'assets/images/lawyer-avatar-1.png',
    },
    {
      'name': 'พิมพ์ใจ รักษาธรรม',
      'title': 'ทนายความ',
      'specialty': 'กฎหมายครอบครัว, มรดก',
      'experience': '12 ปี',
      'experienceYears': 12,
      'rating': 4.8,
      'reviews': 198,
      'price': 500,
      'distance': '2.5 กม.',
      'distanceKm': 2.5,
      'eta': '~5 นาที',
      'available': true,
      'office': 'สำนักงานกฎหมาย พิมพ์ใจ',
      'avatar': 'พ',
      'color': 0xFF6A1B9A,
      'imageUrl': 'assets/images/lawyer-avatar-2.png',
    },
    {
      'name': 'ธนากร นิติบัณฑิต',
      'title': 'ที่ปรึกษากฎหมาย',
      'specialty': 'กฎหมายธุรกิจ, สัญญา',
      'experience': '9 ปี',
      'experienceYears': 9,
      'rating': 3.0,
      'reviews': 145,
      'price': 500,
      'distance': '3.1 กม.',
      'distanceKm': 3.1,
      'eta': '~7 นาที',
      'available': false,
      'office': 'บริษัท นิติธนากร จำกัด',
      'avatar': 'ธ',
      'color': 0xFF2E7D32,
      'imageUrl': 'assets/images/lawyer-avatar-3.png',
    },
    {
      'name': 'วีระ ศักดิ์สิทธิ์กุล',
      'title': 'ทนายความอาวุโส',
      'specialty': 'คดีแรงงาน, ประกันสังคม',
      'experience': '22 ปี',
      'experienceYears': 22,
      'rating': 2.0,
      'reviews': 427,
      'price': 500,
      'distance': '4.0 กม.',
      'distanceKm': 4.0,
      'eta': '~8 นาที',
      'available': true,
      'office': 'สำนักงาน วีระ ลอว์',
      'avatar': 'ว',
      'color': 0xFFBF360C,
      'imageUrl': 'assets/images/lawyer-avatar-5.png',
    },
    {
      'name': 'อรุณี ยุติธรรม',
      'title': 'ทนายความ',
      'specialty': 'กฎหมายที่ดิน, ทรัพย์สิน',
      'experience': '7 ปี',
      'experienceYears': 7,
      'rating': 4.5,
      'reviews': 89,
      'price': 500,
      'distance': '5.3 กม.',
      'distanceKm': 5.3,
      'eta': '~10 นาที',
      'available': true,
      'office': 'สำนักงานกฎหมาย อรุณี',
      'avatar': 'อ',
      'color': 0xFF00695C,
      'imageUrl': 'assets/images/lawyer-avatar-4.png',
    },
  ];

  // ── Computed filtered + sorted list ───────────────────
  List<dynamic> get _filteredLawyers {
    var list = List<dynamic>.from(_lawyers);

    // Filter: search text
    if (_searchText.isNotEmpty) {
      list = list.where((l) {
        final name = (l['name'] as String).toLowerCase();
        final specialty = (l['specialty'] as String).toLowerCase();
        final q = _searchText.toLowerCase();
        return name.contains(q) || specialty.contains(q);
      }).toList();
    }

    // Filter: available only
    if (_filterAvailableOnly) {
      list = list.where((l) => l['available'] as bool).toList();
    }

    // Sort
    switch (_sortBy) {
      case 'rating':
        list.sort(
            (a, b) => (b['rating'] as double).compareTo(a['rating'] as double));
        break;
      case 'experience':
        list.sort((a, b) => (b['experienceYears'] as int)
            .compareTo(a['experienceYears'] as int));
        break;
      case 'distance':
        list.sort((a, b) =>
            (a['distanceKm'] as double).compareTo(b['distanceKm'] as double));
        break;
    }

    return list;
  }

  int get _activeFilterCount {
    int c = 0;
    if (_filterAvailableOnly) c++;
    if (_sortBy != 'none') c++;
    if (_searchText.isNotEmpty) c++;
    return c;
  }

  void _clearFilters() => setState(() {
        _filterAvailableOnly = false;
        _sortBy = 'none';
        _searchText = '';
      });

  // ── Bottom Sheet Filter ────────────────────────────────
  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _FilterSheet(
        availableOnly: _filterAvailableOnly,
        sortBy: _sortBy,
        onApply: (available, sort) {
          setState(() {
            _filterAvailableOnly = available;
            _sortBy = sort;
          });
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredLawyers;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: appBar(
        title: 'นัดหมายทนาย',
        backBtn: true,
        rightBtn: false,
        backAction: () => Navigator.pop(context, false),
        rightAction: () {},
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        behavior: HitTestBehavior.opaque,
        child: Column(
          children: [
            // ── Header ──────────────────────────────────────
            _buildHeader(),

            // ── Topic chip ──────────────────────────────────
            // _buildTopicChip(),

            // ── Search + Filter bar ─────────────────────────
            _buildSearchFilterBar(),

            // ── Active filter chips ─────────────────────────
            if (_activeFilterCount > 0) _buildActiveChips(),

            // ── Result count ────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
              child: Row(children: [
                Text(
                  'พบ ${filtered.length} ทนายความ',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[500],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ]),
            ),

            // ── List ────────────────────────────────────────
            Expanded(
              child: filtered.isEmpty
                  ? _buildEmpty()
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: filtered.length,
                      itemBuilder: (_, i) {
                        final l = filtered[i];
                        final originalIdx = _lawyers.indexOf(l);
                        final isSelected = _selectedIdx == originalIdx;
                        final available = l['available'] as bool;

                        return GestureDetector(
                          onTap: available
                              ? () {
                                  setState(() => _selectedIdx = originalIdx);
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => LawyerDetailPage(
                                        lawyer: l,
                                        topic: widget.topic,
                                        subTopic: widget.subTopic,
                                      ),
                                    ),
                                  );
                                }
                              : null,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                color: isSelected
                                    ? const Color(0xFF0262EC)
                                    : Colors.transparent,
                                width: 2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 10,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Opacity(
                              opacity: available ? 1.0 : 0.5,
                              child: Column(
                                children: [
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      // Avatar
                                      (l['imageUrl'] ?? '') != ''
                                          ? ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(30),
                                              child: Image.asset(
                                                l['imageUrl'],
                                                width: 55,
                                                height: 55,
                                                fit: BoxFit.cover,
                                              ),
                                            )
                                          : CircleAvatar(
                                              radius: 30,
                                              backgroundColor:
                                                  Color(l['color'] as int)
                                                      .withOpacity(0.15),
                                              child: Text(
                                                l['avatar'] as String,
                                                style: TextStyle(
                                                  color:
                                                      Color(l['color'] as int),
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 24,
                                                ),
                                              ),
                                            ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(children: [
                                              Expanded(
                                                child: Text(
                                                  l['name'] as String,
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.w700,
                                                    fontSize: 15,
                                                    color: Color(0xFF1A2340),
                                                  ),
                                                ),
                                              ),
                                              _badge(available),
                                            ]),
                                            const SizedBox(height: 2),
                                            Text(l['title'] as String,
                                                style: TextStyle(
                                                    color: Colors.grey[400],
                                                    fontSize: 12)),
                                            const SizedBox(height: 4),
                                            Row(children: [
                                              const Icon(Icons.star_rounded,
                                                  color: Color(0xFFFFC107),
                                                  size: 14),
                                              const SizedBox(width: 2),
                                              Text('${l['rating']}',
                                                  style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      fontSize: 12)),
                                              Text(' (${l['reviews']} รีวิว)',
                                                  style: TextStyle(
                                                      color: Colors.grey[400],
                                                      fontSize: 12)),
                                            ]),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  const Divider(
                                      height: 1, color: Color(0xFFEEF2F5)),
                                  const SizedBox(height: 10),
                                  Row(children: [
                                    _chip(Icons.gavel_outlined,
                                        l['specialty'] as String),
                                    const SizedBox(width: 8),
                                    _chip(Icons.history_outlined,
                                        l['experience'] as String),
                                  ]),
                                  const SizedBox(height: 8),
                                  Row(children: [
                                    _chip(Icons.location_on_outlined,
                                        l['distance'] as String),
                                    const SizedBox(width: 8),
                                    _chip(Icons.business_outlined,
                                        l['office'] as String),
                                  ]),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  // ════════════════════════════════════════════════════════
  //  Widgets
  // ════════════════════════════════════════════════════════

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(9),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
                colors: [Color(0xFF0262EC), Color(0xFF34AAFF)]),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0262EC).withOpacity(0.4),
                blurRadius: 14,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: const Icon(Icons.contact_page,
              color: Color(0xFFFFFFFF), size: 20),
        ),
        const SizedBox(width: 10),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('เลือกทนายความ',
              style: TextStyle(
                  color: Color(0xFF1A2340),
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.3)),
          Text('กดเลือกทนายที่ใช่ เพื่อดูรายละเอียด',
              style: TextStyle(
                  color: const Color(0xFF1A2340).withOpacity(0.4),
                  fontSize: 11)),
        ]),
      ]),
    );
  }

  Widget _buildTopicChip() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFF0262EC).withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.label_outline_rounded,
                size: 14, color: Color(0xFF0262EC)),
            const SizedBox(width: 4),
            Text(widget.topic,
                style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF0262EC),
                    fontWeight: FontWeight.w600)),
            if (widget.subTopic.isNotEmpty)
              Text(' › ${widget.subTopic}',
                  style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF0262EC),
                      fontWeight: FontWeight.w600)),
          ]),
        ),
      ]),
    );
  }

  Widget _buildSearchFilterBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
      child: Row(children: [
        // Search field
        Expanded(
          child: Container(
            height: 42,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F4)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TextField(
              onChanged: (v) => setState(() => _searchText = v),
              style: const TextStyle(fontSize: 13),
              decoration: InputDecoration(
                hintText: 'ค้นหาชื่อหรือความเชี่ยวชาญ...',
                hintStyle: TextStyle(color: Colors.grey[400], fontSize: 13),
                prefixIcon: Icon(Icons.search_rounded,
                    color: Colors.grey[400], size: 18),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),

        // Filter button
        GestureDetector(
          onTap: _showFilterSheet,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: _activeFilterCount > 0
                  ? const Color(0xFF0262EC)
                  : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _activeFilterCount > 0
                    ? const Color(0xFF0262EC)
                    : const Color(0xFFE2E8F4),
              ),
              boxShadow: [
                BoxShadow(
                  color: _activeFilterCount > 0
                      ? const Color(0xFF0262EC).withOpacity(0.3)
                      : Colors.black.withOpacity(0.04),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Icon(
                  Icons.tune_rounded,
                  color:
                      _activeFilterCount > 0 ? Colors.white : Colors.grey[500],
                  size: 20,
                ),
                // Badge count
                if (_activeFilterCount > 0)
                  Positioned(
                    top: 5,
                    right: 5,
                    child: Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: const Color(0xFF0262EC), width: 1.5),
                      ),
                      child: Center(
                        child: Text(
                          '$_activeFilterCount',
                          style: const TextStyle(
                            fontSize: 8,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF0262EC),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ]),
    );
  }

  Widget _buildActiveChips() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 6),
      child: Row(children: [
        // ว่างอยู่ chip
        if (_filterAvailableOnly)
          _activeChip('ว่างอยู่',
              onRemove: () => setState(() => _filterAvailableOnly = false)),

        if (_filterAvailableOnly && _sortBy != 'none') const SizedBox(width: 6),

        // Sort chip
        if (_sortBy != 'none')
          _activeChip(_sortLabel(_sortBy),
              onRemove: () => setState(() => _sortBy = 'none')),

        const Spacer(),

        // Clear all
        GestureDetector(
          onTap: _clearFilters,
          child: Text('ล้างทั้งหมด',
              style: TextStyle(
                  fontSize: 11,
                  color: const Color(0xFF0262EC).withOpacity(0.8),
                  fontWeight: FontWeight.w600)),
        ),
      ]),
    );
  }

  Widget _activeChip(String label, {required VoidCallback onRemove}) =>
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: const Color(0xFF0262EC).withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFF0262EC).withOpacity(0.3)),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 11,
                  color: Color(0xFF0262EC),
                  fontWeight: FontWeight.w600)),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: onRemove,
            child: const Icon(Icons.close_rounded,
                size: 13, color: Color(0xFF0262EC)),
          ),
        ]),
      );

  Widget _buildEmpty() => Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: const Color(0xFFEEF2F5),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.person_search_rounded,
                color: Colors.grey[400], size: 30),
          ),
          const SizedBox(height: 12),
          Text('ไม่พบทนายความที่ตรงกับฟิลเตอร์',
              style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          GestureDetector(
            onTap: _clearFilters,
            child: Text('ล้างฟิลเตอร์',
                style: TextStyle(
                    fontSize: 12,
                    color: const Color(0xFF0262EC).withOpacity(0.8))),
          ),
        ]),
      );

  Widget _badge(bool ok) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: ok ? const Color(0xFFE8F5E9) : const Color(0xFFFFEBEE),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          ok ? 'ว่างอยู่' : 'ไม่ว่าง',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: ok ? const Color(0xFF2E7D32) : const Color(0xFFC62828),
          ),
        ),
      );

  Widget _chip(IconData icon, String label) => Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFFEEF2F5),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(children: [
            Icon(icon, size: 13, color: const Color(0xFF0262EC)),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 11, color: Color(0xFF1A2340)),
              ),
            ),
          ]),
        ),
      );

  String _sortLabel(String sort) {
    switch (sort) {
      case 'rating':
        return 'คะแนนสูงสุด';
      case 'experience':
        return 'ประสบการณ์';
      case 'distance':
        return 'ใกล้ที่สุด';
      default:
        return '';
    }
  }
}

// ══════════════════════════════════════════════════════════
//  _FilterSheet — Bottom Sheet
// ══════════════════════════════════════════════════════════

class _FilterSheet extends StatefulWidget {
  final bool availableOnly;
  final String sortBy;
  final Function(bool available, String sort) onApply;

  const _FilterSheet({
    required this.availableOnly,
    required this.sortBy,
    required this.onApply,
  });

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  late bool _available;
  late String _sort;

  static const _kPrimary = Color(0xFF0262EC);

  @override
  void initState() {
    super.initState();
    _available = widget.availableOnly;
    _sort = widget.sortBy;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
          20, 0, 20, MediaQuery.of(context).padding.bottom + 20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 20),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFE2E8F4),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),

          // Title
          const Text('ตัวกรอง',
              style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1A2340))),
          const SizedBox(height: 20),

          // ── ว่างอยู่ ──────────────────────────────────
          const Text('สถานะ',
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1A2340))),
          const SizedBox(height: 10),
          GestureDetector(
            onTap: () => setState(() => _available = !_available),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: _available
                    ? _kPrimary.withOpacity(0.08)
                    : const Color(0xFFF8F9FB),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: _available
                      ? _kPrimary.withOpacity(0.4)
                      : const Color(0xFFE2E8F4),
                  width: 1.5,
                ),
              ),
              child: Row(children: [
                Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    color: _available ? _kPrimary : Colors.white,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: _available ? _kPrimary : const Color(0xFFCCCCCC),
                    ),
                  ),
                  child: _available
                      ? const Icon(Icons.check_rounded,
                          color: Colors.white, size: 14)
                      : null,
                ),
                const SizedBox(width: 12),
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                      color: Color(0xFF34C759), shape: BoxShape.circle),
                ),
                const SizedBox(width: 6),
                const Text('แสดงเฉพาะที่ว่างอยู่',
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1A2340))),
              ]),
            ),
          ),
          const SizedBox(height: 20),

          // ── เรียงตาม ──────────────────────────────────
          const Text('เรียงตาม',
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1A2340))),
          const SizedBox(height: 10),
          Row(children: [
            _sortChip('none', 'ค่าเริ่มต้น', Icons.sort_rounded),
            const SizedBox(width: 8),
            _sortChip('rating', 'คะแนน', Icons.star_rounded),
          ]),
          const SizedBox(height: 8),
          Row(children: [
            _sortChip('experience', 'ประสบการณ์', Icons.history_rounded),
            const SizedBox(width: 8),
            _sortChip('distance', 'ใกล้ที่สุด', Icons.location_on_rounded),
          ]),
          const SizedBox(height: 24),

          // ── Buttons ───────────────────────────────────
          Row(children: [
            Expanded(
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _available = false;
                    _sort = 'none';
                  });
                },
                child: Container(
                  height: 48,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF2F6FF),
                    borderRadius: BorderRadius.circular(14),
                    border:
                        Border.all(color: const Color(0xFFDDE5F4), width: 1.5),
                  ),
                  child: const Center(
                    child: Text('ล้างฟิลเตอร์',
                        style: TextStyle(
                            color: Color(0xFF5B6E8A),
                            fontWeight: FontWeight.w600,
                            fontSize: 14)),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              flex: 2,
              child: GestureDetector(
                onTap: () {
                  widget.onApply(_available, _sort);
                  Navigator.pop(context);
                },
                child: Container(
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF0262EC), Color(0xFF0099FF)],
                    ),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: _kPrimary.withOpacity(0.35),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Text('นำฟิลเตอร์ไปใช้',
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 14)),
                  ),
                ),
              ),
            ),
          ]),
        ],
      ),
    );
  }

  Widget _sortChip(String value, String label, IconData icon) {
    final selected = _sort == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _sort = value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected
                ? _kPrimary.withOpacity(0.08)
                : const Color(0xFFF8F9FB),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected
                  ? _kPrimary.withOpacity(0.4)
                  : const Color(0xFFE2E8F4),
              width: 1.5,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon,
                  size: 14, color: selected ? _kPrimary : Colors.grey[400]),
              const SizedBox(width: 5),
              Text(label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: selected ? _kPrimary : const Color(0xFF64748B),
                  )),
            ],
          ),
        ),
      ),
    );
  }
}
