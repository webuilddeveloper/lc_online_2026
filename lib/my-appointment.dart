import 'package:LawyerOnline/component/appbar.dart';
import 'package:LawyerOnline/appointment-details.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// ══════════════════════════════════════════════════════════
//  Status index:
//  0 = รอทนายรับเคส
//  1 = ยืนยันแล้ว
//  2 = กำลังปรึกษา
//  3 = เสร็จสิ้น
// ══════════════════════════════════════════════════════════

// ── Per-tab filter state ─────────────────────────────────
class _TabFilter {
  String search;
  String sort; // 'date_asc' | 'date_desc' | 'name_asc'

  _TabFilter({this.search = '', this.sort = 'date_desc'});

  _TabFilter copyWith({String? search, String? sort}) => _TabFilter(
        search: search ?? this.search,
        sort: sort ?? this.sort,
      );

  bool get hasActiveFilter => search.isNotEmpty || sort != 'date_desc';
}

class AppointmentListPage extends StatefulWidget {
  const AppointmentListPage({super.key});

  @override
  State<AppointmentListPage> createState() => _AppointmentListPageState();
}

class _AppointmentListPageState extends State<AppointmentListPage>
    with TickerProviderStateMixin {
  String _activeTab = 'all';
  late AnimationController _entryCtrl;

  // ── Per-tab filter map ───────────────────────────────────
  final Map<String, _TabFilter> _tabFilters = {
    'all': _TabFilter(),
    'pending': _TabFilter(),
    'active': _TabFilter(),
    'done': _TabFilter(),
  };

  // ── Search controllers per tab ────────────────────────────
  final Map<String, TextEditingController> _searchControllers = {
    'all': TextEditingController(),
    'pending': TextEditingController(),
    'active': TextEditingController(),
    'done': TextEditingController(),
  };

  //     'name'    : widget.model['name'] ?? '',
                // 'avatar'  : (widget.model['name'] as String? ?? 'ท')
                //                 .characters.first,
                // 'title'   : widget.model['title'] ??
                //             (widget.model['skills'] != null &&
                //                 (widget.model['skills'] as List).isNotEmpty
                //                 ? (widget.model['skills'] as List).first
                //                 : widget.model['experience'] ?? ''),
                // 'rating'  : widget.model['rating'] ??
                //             widget.model['scroll'] ?? 0,
                // 'imageUrl': widget.model['imageUrl'] ?? '',

  // ── Mock data ─────────────────────────────────────────────
  final List<Map<String, dynamic>> _appointments = [
    {
      'id': 'APT-005',
      'name': 'วีระ ศักดิ์สิทธิ์กุล',
      'title': 'ทนายความอาวุโส',
      'lawyerAvatar': 'ว',
      'imageUrl': 'assets/images/lawyer-avatar-5.png',
      'topic': 'คดีอาญา',
      'subTopic': 'ถูกกล่าวหาโดยไม่มีมูล',
      'date': '05 เม.ย. 2569',
      'dateSortKey': 20690405,
      'time': '13:00 - 14:00',
      'status': 0,
      'type': 'video',
      'rating': null,
    },
    {
      'id': 'APT-006',
      'name': 'อรุณี ยุติธรรม',
      'title': 'ทนายความ',
      'lawyerAvatar': 'อ',
      'imageUrl': 'assets/images/lawyer-avatar-4.png',
      'topic': 'กฎหมายที่ดิน',
      'subTopic': 'ขอออกโฉนดที่ดิน',
      'date': '07 เม.ย. 2569',
      'dateSortKey': 20690407,
      'time': '09:00 - 10:00',
      'status': 1,
      'type': 'video',
      'rating': null,
    },
    {
      'id': 'APT-001',
      'name': 'ศักดิ์สิทธิ์ พิพากษ์',
      'title': 'ทนายความอาวุโส',
      'lawyerAvatar': 'ศ',
      'imageUrl': 'assets/images/lawyer-avatar-1.png',
      'topic': 'ครอบครัวและมรดก',
      'subTopic': 'ฟ้องหย่า / แบ่งสินสมรส',
      'date': '28 มี.ค. 2569',
      'dateSortKey': 20690328,
      'time': '10:00 - 11:00',
      'status': 2,
      'type': 'video',
      'rating': null,
    },
    {
      'id': 'APT-002',
      'name': 'พิมพ์ใจ รักษาธรรม',
      'title': 'ทนายความ',
      'lawyerAvatar': 'พ',
      'imageUrl': 'assets/images/lawyer-avatar-2.png',
      'topic': 'หนี้สินและการเงิน',
      'subTopic': 'หนี้กู้ยืมเงิน / ดอกเบี้ย',
      'date': '02 เม.ย. 2569',
      'dateSortKey': 20690402,
      'time': '14:00 - 15:00',
      'status': 2,
      'type': 'video',
      'rating': null,
    },
    {
      'id': 'APT-003',
      'name': 'ธนากร นิติบัณฑิต',
      'title': 'ที่ปรึกษากฎหมาย',
      'lawyerAvatar': 'ธ',
      'imageUrl': 'assets/images/lawyer-avatar-3.png',
      'topic': 'ธุรกิจและบริษัท',
      'subTopic': 'ตรวจร่างสัญญา',
      'date': '15 มี.ค. 2569',
      'dateSortKey': 20690315,
      'time': '09:00 - 10:00',
      'status': 3,
      'type': 'video',
      'rating': 5.0,
    },
    {
      'id': 'APT-004',
      'name': 'อาริย์ ศิษย์กฎหมาย',
      'title': 'ทนายความ',
      'lawyerAvatar': 'อ',
      'imageUrl': 'assets/images/lawyer-avatar-4.png',
      'topic': 'แรงงานและการจ้างงาน',
      'subTopic': 'เลิกจ้างไม่เป็นธรรม',
      'date': '10 มี.ค. 2569',
      'dateSortKey': 20690310,
      'time': '11:00 - 12:00',
      'status': 3,
      'type': 'video',
      'rating': 4.0,
    },
  ];

  @override
  void initState() {
    super.initState();
    _entryCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..forward();
  }

  @override
  void dispose() {
    _entryCtrl.dispose();
    for (final c in _searchControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  // ── Current tab's filter ────────────────────────────────
  _TabFilter get _currentFilter => _tabFilters[_activeTab]!;

  void _updateFilter(_TabFilter f) =>
      setState(() => _tabFilters[_activeTab] = f);

  // ── Filtered + sorted list ──────────────────────────────
  List<Map<String, dynamic>> get _filtered {
    final f = _currentFilter;

    // 1. filter by tab
    List<Map<String, dynamic>> list;
    switch (_activeTab) {
      case 'pending':
        list = _appointments.where((a) => a['status'] == 0).toList();
        break;
      case 'active':
        list = _appointments
            .where((a) => a['status'] == 1 || a['status'] == 2)
            .toList();
        break;
      case 'done':
        list = _appointments.where((a) => a['status'] == 3).toList();
        break;
      default:
        list = List.from(_appointments);
    }

    // 2. search
    if (f.search.isNotEmpty) {
      final q = f.search.toLowerCase();
      list = list.where((a) {
        return (a['name'] as String).toLowerCase().contains(q) ||
            (a['topic'] as String).toLowerCase().contains(q) ||
            (a['subTopic'] as String).toLowerCase().contains(q) ||
            (a['id'] as String).toLowerCase().contains(q);
      }).toList();
    }

    // 3. sort
    switch (f.sort) {
      case 'date_asc':
        list.sort((a, b) =>
            (a['dateSortKey'] as int).compareTo(b['dateSortKey'] as int));
        break;
      case 'name_asc':
        list.sort((a, b) =>
            (a['name'] as String).compareTo(b['name'] as String));
        break;
      default: // date_desc
        list.sort((a, b) =>
            (b['dateSortKey'] as int).compareTo(a['dateSortKey'] as int));
    }

    return list;
  }

  int _countByTab(String tab) {
    switch (tab) {
      case 'pending':
        return _appointments.where((a) => a['status'] == 0).length;
      case 'active':
        return _appointments
            .where((a) => a['status'] == 1 || a['status'] == 2)
            .length;
      case 'done':
        return _appointments.where((a) => a['status'] == 3).length;
      default:
        return _appointments.length;
    }
  }

  // ════════════════════════════════════════════════════════
  //  Status helpers
  // ════════════════════════════════════════════════════════

  String _statusLabel(int s) => const [
        'รอทนายรับเคส',
        'ยืนยันแล้ว',
        'กำลังปรึกษา',
        'เสร็จสิ้น',
      ][s.clamp(0, 3)];

  Color _statusColor(int s) => const [
        Color(0xFFEA580C),
        Color(0xFF0262EC),
        Color(0xFF059669),
        Color(0xFF6D28D9),
      ][s.clamp(0, 3)];

  IconData _statusIcon(int s) => const [
        Icons.pending_actions_rounded,
        Icons.verified_rounded,
        Icons.headset_mic_rounded,
        Icons.task_alt_rounded,
      ][s.clamp(0, 3)];

  // ════════════════════════════════════════════════════════
  //  BUILD
  // ════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;
    final f = _currentFilter;

    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      behavior: HitTestBehavior.opaque,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: appBar(
          title: 'นัดหมายของฉัน',
          backBtn: false,
          rightBtn: false,
          backAction: () => Navigator.pop(context),
          rightAction: () {},
        ),
        body: GestureDetector(
          onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
          behavior: HitTestBehavior.opaque,
          child: Column(
            children: [
              // ── Tab bar ────────────────────────────────────
              _buildTabBar(),
      
              // ── Filter bar (per-tab) ────────────────────────
              _buildFilterBar(f),
      
              // ── Active filter chips ─────────────────────────
              if (f.hasActiveFilter) _buildActiveFilterChips(f),
      
              // ── Result count ───────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
                child: Row(children: [
                  Text(
                    'พบ ${filtered.length} รายการ',
                    style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[500],
                        fontWeight: FontWeight.w500),
                  ),
                ]),
              ),
      
              // ── List ───────────────────────────────────────
              Expanded(
                child: filtered.isEmpty
                    ? _buildEmpty(f.hasActiveFilter)
                    : Container(
                        color: const Color(0xFFF2F6FF),
                        child: ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                          itemCount: filtered.length,
                          itemBuilder: (_, i) {
                            final item = filtered[i];
                            final delay = (i * 0.08).clamp(0.0, 0.7);
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
                                    offset: Offset(0, 24 * (1 - t)),
                                    child: child,
                                  ),
                                );
                              },
                              child: _buildCard(item),
                            );
                          },
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ════════════════════════════════════════════════════════
  //  Tab Bar
  // ════════════════════════════════════════════════════════

  Widget _buildTabBar() {
    final tabs = [
      {'key': 'all', 'label': 'ทั้งหมด'},
      {'key': 'pending', 'label': 'รอรับเคส'},
      {'key': 'active', 'label': 'ดำเนินการ'},
      {'key': 'done', 'label': 'เสร็จสิ้น'},
    ];

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Row(
        children: tabs.map((t) {
          final isActive = _activeTab == t['key'];
          final count = _countByTab(t['key']!);
          final isPendingTab = t['key'] == 'pending';
          final hasPending =
              _appointments.where((a) => a['status'] == 0).isNotEmpty;
          final hasTabFilter = _tabFilters[t['key']]!.hasActiveFilter;

          final badgeColor = (isPendingTab && hasPending)
              ? const Color(0xFFEA580C)
              : isActive
                  ? const Color(0xFF0262EC)
                  : Colors.grey[200]!;

          return Expanded(
            child: GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() {
                  _activeTab = t['key']!;
                  _searchControllers[_activeTab]!.clear();
                  _updateFilter(_TabFilter());
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: isActive
                          ? const Color(0xFF0262EC)
                          : Colors.transparent,
                      width: 2.5,
                    ),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      t['label']!,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight:
                            isActive ? FontWeight.w700 : FontWeight.w500,
                        color: isActive
                            ? const Color(0xFF0262EC)
                            : Colors.grey[500],
                      ),
                    ),
                    const SizedBox(width: 4),
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 5, vertical: 2),
                          decoration: BoxDecoration(
                            color: badgeColor,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '$count',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: (isPendingTab && hasPending) || isActive
                                  ? Colors.white
                                  : Colors.grey[500],
                            ),
                          ),
                        ),
                        // Filter dot indicator
                        if (hasTabFilter)
                          Positioned(
                            top: -2,
                            right: -3,
                            child: Container(
                              width: 7,
                              height: 7,
                              decoration: const BoxDecoration(
                                color: Color(0xFF0262EC),
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ════════════════════════════════════════════════════════
  //  Filter Bar  (search + sort button)
  // ════════════════════════════════════════════════════════

  Widget _buildFilterBar(_TabFilter f) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
      child: Row(children: [
        // ── Search field ──────────────────────────────────
        Expanded(
          child: Container(
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFFF5F7FA),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F4)),
            ),
            child: TextField(
              controller: _searchControllers[_activeTab],
              onChanged: (v) => _updateFilter(f.copyWith(search: v)),
              style: const TextStyle(fontSize: 13),
              decoration: InputDecoration(
                hintText: 'ค้นหาชื่อทนาย, หัวข้อ, รหัส...',
                hintStyle: TextStyle(color: Colors.grey[400], fontSize: 12),
                prefixIcon: Icon(Icons.search_rounded,
                    color: Colors.grey[400], size: 17),
                suffixIcon: f.search.isNotEmpty
                    ? GestureDetector(
                        onTap: () {
                          _searchControllers[_activeTab]!.clear();
                          _updateFilter(f.copyWith(search: ''));
                        },
                        child: Icon(Icons.close_rounded,
                            color: Colors.grey[400], size: 16),
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 11),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),

        // ── Sort button ───────────────────────────────────
        GestureDetector(
          onTap: () => _showSortSheet(f),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: f.sort != 'date_desc'
                  ? const Color(0xFF0262EC)
                  : const Color(0xFFF5F7FA),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: f.sort != 'date_desc'
                    ? const Color(0xFF0262EC)
                    : const Color(0xFFE2E8F4),
              ),
            ),
            child: Icon(
              Icons.sort_rounded,
              size: 18,
              color: f.sort != 'date_desc' ? Colors.white : Colors.grey[500],
            ),
          ),
        ),
      ]),
    );
  }

  // ════════════════════════════════════════════════════════
  //  Active filter chips  (แสดงใต้ filter bar)
  // ════════════════════════════════════════════════════════

  Widget _buildActiveFilterChips(_TabFilter f) {
    final sortLabels = {
      'date_desc': 'วันที่ล่าสุด',
      'date_asc': 'วันที่เก่าสุด',
      'name_asc': 'ชื่อ ก-ฮ',
    };

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Row(children: [
        if (f.sort != 'date_desc')
          _filterChip(
            label: sortLabels[f.sort]!,
            icon: Icons.sort_rounded,
            onRemove: () => _updateFilter(f.copyWith(sort: 'date_desc')),
          ),
        if (f.sort != 'date_desc' && f.search.isNotEmpty)
          const SizedBox(width: 6),
        if (f.search.isNotEmpty)
          _filterChip(
            label: '"${f.search}"',
            icon: Icons.search_rounded,
            onRemove: () {
              _searchControllers[_activeTab]!.clear();
              _updateFilter(f.copyWith(search: ''));
            },
          ),
        const Spacer(),
        GestureDetector(
          onTap: () {
            _searchControllers[_activeTab]!.clear();
            _updateFilter(_TabFilter());
          },
          child: Text(
            'ล้างทั้งหมด',
            style: TextStyle(
                fontSize: 11,
                color: const Color(0xFF0262EC).withOpacity(0.8),
                fontWeight: FontWeight.w600),
          ),
        ),
      ]),
    );
  }

  Widget _filterChip({
    required String label,
    required IconData icon,
    required VoidCallback onRemove,
  }) =>
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: const Color(0xFF0262EC).withOpacity(0.08),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFF0262EC).withOpacity(0.25)),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 11, color: const Color(0xFF0262EC)),
          const SizedBox(width: 4),
          Text(label,
              style: const TextStyle(
                  fontSize: 11,
                  color: Color(0xFF0262EC),
                  fontWeight: FontWeight.w600)),
          const SizedBox(width: 5),
          GestureDetector(
            onTap: onRemove,
            child: const Icon(Icons.close_rounded,
                size: 13, color: Color(0xFF0262EC)),
          ),
        ]),
      );

  // ════════════════════════════════════════════════════════
  //  Sort Bottom Sheet
  // ════════════════════════════════════════════════════════

  void _showSortSheet(_TabFilter f) {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _SortSheet(
        currentSort: f.sort,
        onSelect: (sort) => _updateFilter(f.copyWith(sort: sort)),
      ),
    );
  }

  // ════════════════════════════════════════════════════════
  //  Appointment Card
  // ════════════════════════════════════════════════════════

  Widget _buildCard(Map<String, dynamic> item) {
    final status = item['status'] as int;
    final color = _statusColor(status);
    const lawyerColor = Color(0xFF0262EC);
    final isDone = status == 3;
    final isConsulting = status == 2;
    final isWaiting = status == 0;

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AppointmentDetails(appointment: item),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: isConsulting
              ? Border.all(
                  color: const Color(0xFF059669).withOpacity(0.4), width: 1.5)
              : isWaiting
                  ? Border.all(
                      color: const Color(0xFFEA580C).withOpacity(0.4),
                      width: 1.5)
                  : Border.all(color: const Color(0xFFE2E8F4)),
          boxShadow: [
            BoxShadow(
              color: isConsulting
                  ? const Color(0xFF059669).withOpacity(0.08)
                  : isWaiting
                      ? const Color(0xFFEA580C).withOpacity(0.08)
                      : Colors.black.withOpacity(0.04),
              blurRadius: 12,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(children: [
          // ── Waiting banner ──────────────────────────────
          if (isWaiting)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFEA580C).withOpacity(0.08),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(18),
                  topRight: Radius.circular(18),
                ),
              ),
              child: Row(children: [
                _blinkingDot(const Color(0xFFEA580C)),
                const SizedBox(width: 7),
                const Text('กำลังรอทนายความรับเคสของคุณ',
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFFEA580C))),
              ]),
            ),

          // ── Header ─────────────────────────────────────
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(50),
                child: Container(
                  width: 60,
                  height: 60,
                  color: const Color(0xFFF2F4F7),
                  child: item['imageUrl'] != null
                      ? Image.asset(item['imageUrl'] as String,
                          fit: BoxFit.cover)
                      : Center(
                          child: Text(item['lawyerAvatar'] as String,
                              style: const TextStyle(
                                  fontSize: 24,
                                  color: lawyerColor,
                                  fontWeight: FontWeight.bold))),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Expanded(
                          child: Text(item['name'] as String,
                              style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF1A2340))),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(mainAxisSize: MainAxisSize.min, children: [
                            Icon(_statusIcon(status), size: 11, color: color),
                            const SizedBox(width: 4),
                            Text(_statusLabel(status),
                                style: TextStyle(
                                    fontSize: 10,
                                    color: color,
                                    fontWeight: FontWeight.w700)),
                          ]),
                        ),
                      ]),
                      const SizedBox(height: 2),
                      Text(item['title'] as String,
                          style:
                              TextStyle(fontSize: 11, color: Colors.grey[500])),
                    ]),
              ),
            ]),
          ),

          const Divider(height: 1, color: Color(0xFFF0F4F8)),

          // ── Detail ─────────────────────────────────────
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(children: [
              Row(children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: lawyerColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.label_outline_rounded,
                      size: 14, color: lawyerColor),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item['topic'] as String,
                            style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF1A2340))),
                        if ((item['subTopic'] as String).isNotEmpty)
                          Text(item['subTopic'] as String,
                              style: TextStyle(
                                  fontSize: 10, color: Colors.grey[500])),
                      ]),
                ),
              ]),
              const SizedBox(height: 8),
              Row(children: [
                Expanded(
                  child: _detailChip(
                      Icons.calendar_today_rounded, item['date'] as String),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _detailChip(
                      Icons.access_time_rounded, item['time'] as String),
                ),
              ]),
              if (isDone && item['rating'] != null) ...[
                const SizedBox(height: 8),
                Row(children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF8EC),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                          color: const Color(0xFFD97706).withOpacity(0.3)),
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      const Icon(Icons.star_rounded,
                          color: Color(0xFFFFC107), size: 13),
                      const SizedBox(width: 4),
                      Text('${item['rating']} คะแนน',
                          style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFFD97706))),
                    ]),
                  ),
                  const SizedBox(width: 8),
                  Text('# ${item['id']}',
                      style: TextStyle(fontSize: 10, color: Colors.grey[400])),
                ]),
              ] else ...[
                const SizedBox(height: 6),
                Row(children: [
                  Text('# ${item['id']}',
                      style: TextStyle(fontSize: 10, color: Colors.grey[400])),
                ]),
              ],
            ]),
          ),

          // ── Waiting actions ────────────────────────────
          if (isWaiting)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
              child: Row(children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => _showCancelDialog(item['id'] as String),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEA580C).withOpacity(0.06),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: const Color(0xFFEA580C).withOpacity(0.25)),
                      ),
                      child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.close_rounded,
                                size: 14, color: Color(0xFFEA580C)),
                            SizedBox(width: 6),
                            Text('ยกเลิกเคส',
                                style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFFEA580C))),
                          ]),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: GestureDetector(
                    onTap: () => HapticFeedback.lightImpact(),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0262EC),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                              color: const Color(0xFF0262EC).withOpacity(0.25),
                              blurRadius: 8,
                              offset: const Offset(0, 3))
                        ],
                      ),
                      child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.visibility_outlined,
                                size: 14, color: Colors.white),
                            SizedBox(width: 6),
                            Text('ดูรายละเอียด',
                                style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white)),
                          ]),
                    ),
                  ),
                ),
              ]),
            ),
        ]),
      ),
    );
  }

  // ════════════════════════════════════════════════════════
  //  Helpers
  // ════════════════════════════════════════════════════════

  Widget _blinkingDot(Color color) => TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.3, end: 1.0),
        duration: const Duration(milliseconds: 800),
        builder: (_, v, __) => Opacity(
          opacity: v,
          child: Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
        ),
        onEnd: () => setState(() {}),
      );

  void _showCancelDialog(String id) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
                color: const Color(0xFFEA580C).withOpacity(0.1),
                shape: BoxShape.circle),
            child: const Icon(Icons.warning_amber_rounded,
                color: Color(0xFFEA580C), size: 18),
          ),
          const SizedBox(width: 10),
          const Text('ยกเลิกเคส',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1A2340))),
        ]),
        content: Text(
          'ต้องการยกเลิกเคส #$id ใช่หรือไม่?\nการกระทำนี้ไม่สามารถย้อนกลับได้',
          style: const TextStyle(
              fontSize: 13, color: Color(0xFF64748B), height: 1.6),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        actions: [
          Row(children: [
            Expanded(
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                      color: const Color(0xFFF2F6FF),
                      borderRadius: BorderRadius.circular(12)),
                  child: const Center(
                    child: Text('ยกเลิก',
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF64748B))),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: GestureDetector(
                onTap: () {
                  setState(
                      () => _appointments.removeWhere((a) => a['id'] == id));
                  Navigator.pop(context);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEA580C),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                          color: const Color(0xFFEA580C).withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 3))
                    ],
                  ),
                  child: const Center(
                    child: Text('ยืนยัน',
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Colors.white)),
                  ),
                ),
              ),
            ),
          ]),
        ],
      ),
    );
  }

  Widget _detailChip(IconData icon, String label) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: const Color(0xFFF5F7FA),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFE2E8F4)),
        ),
        child: Row(children: [
          Icon(icon, size: 12, color: const Color(0xFF0262EC)),
          const SizedBox(width: 6),
          Expanded(
            child: Text(label,
                style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF1A2340),
                    fontWeight: FontWeight.w500),
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
          ),
        ]),
      );

  Widget _buildEmpty(bool hasFilter) => Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 72,
            height: 72,
            decoration: const BoxDecoration(
                color: Color(0xFFEEF2F5), shape: BoxShape.circle),
            child: Icon(
                hasFilter
                    ? Icons.search_off_rounded
                    : Icons.calendar_today_outlined,
                color: Colors.grey[400],
                size: 32),
          ),
          const SizedBox(height: 14),
          Text(
            hasFilter ? 'ไม่พบรายการที่ตรงกัน' : 'ไม่มีรายการนัดหมาย',
            style: TextStyle(
                color: Colors.grey[600],
                fontSize: 15,
                fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          if (hasFilter)
            GestureDetector(
              onTap: () {
                _searchControllers[_activeTab]!.clear();
                _updateFilter(_TabFilter());
              },
              child: Text('ล้างฟิลเตอร์',
                  style: TextStyle(
                      fontSize: 12,
                      color: const Color(0xFF0262EC).withOpacity(0.8))),
            )
          else
            Text('การนัดหมายของคุณจะปรากฏที่นี่',
                style: TextStyle(color: Colors.grey[400], fontSize: 12)),
        ]),
      );
}

// ══════════════════════════════════════════════════════════
//  _SortSheet  —  Bottom sheet เลือก sort
// ══════════════════════════════════════════════════════════

class _SortSheet extends StatelessWidget {
  final String currentSort;
  final ValueChanged<String> onSelect;

  const _SortSheet({required this.currentSort, required this.onSelect});

  static const _kPrimary = Color(0xFF0262EC);

  static const _options = [
    ('date_desc', Icons.arrow_downward_rounded, 'วันที่ล่าสุดก่อน'),
    ('date_asc', Icons.arrow_upward_rounded, 'วันที่เก่าสุดก่อน'),
    ('name_asc', Icons.sort_by_alpha_rounded, 'ชื่อทนาย ก–ฮ'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: SafeArea(
        top: false,
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 36,
            height: 4,
            margin: const EdgeInsets.only(top: 12, bottom: 16),
            decoration: BoxDecoration(
                color: const Color(0xFFE2E8F4),
                borderRadius: BorderRadius.circular(2)),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 4),
            child: Row(children: [
              const Text('เรียงตาม',
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1A2340))),
            ]),
          ),
          ..._options.map((o) {
            final (value, icon, label) = o;
            final selected = currentSort == value;
            return ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 20),
              leading: Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: selected
                      ? _kPrimary.withOpacity(0.1)
                      : const Color(0xFFF5F7FA),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(icon,
                    size: 17, color: selected ? _kPrimary : Colors.grey[400]),
              ),
              title: Text(label,
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                      color: selected ? _kPrimary : const Color(0xFF1A2340))),
              trailing: selected
                  ? const Icon(Icons.check_rounded, color: _kPrimary, size: 18)
                  : null,
              onTap: () {
                HapticFeedback.selectionClick();
                onSelect(value);
                Navigator.pop(context);
              },
            );
          }),
          const SizedBox(height: 8),
        ]),
      ),
    );
  }
}

