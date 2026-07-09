import 'package:LawyerOnline/component/appbar.dart';
import 'package:LawyerOnline/appointment-details.dart';
import 'package:LawyerOnline/component/dialog_service.dart';
import 'package:LawyerOnline/component/loading_service.dart';
import 'package:LawyerOnline/models/user/user_case_adapter.dart';
import 'package:LawyerOnline/shared/api_provider.dart';
import 'package:LawyerOnline/shared/responsive/app_layout.dart';
import 'package:LawyerOnline/shared/responsive/res_layout.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

// ══════════════════════════════════════════════════════════
//  Status index:
//  0 = ยกเลิก
//  1 = รอทนายยืนยัน
//  2 = รอปรึกษาทนาย
//  3 = กำลังปรึกษา
//  4 = เสร็จสิ้น
// ══════════════════════════════════════════════════════════

class _TabFilter {
  String search;
  String sort;

  _TabFilter({this.search = '', this.sort = 'date_desc'});

  _TabFilter copyWith({String? search, String? sort}) => _TabFilter(
        search: search ?? this.search,
        sort: sort ?? this.sort,
      );

  bool get hasActiveFilter => search.isNotEmpty || sort != 'date_desc';
}

class CaseListPage extends StatefulWidget {
  const CaseListPage({super.key, this.isTabActive = false,});

  final bool isTabActive;

  @override
  State<CaseListPage> createState() => _CaseListPageState();
}

class _CaseListPageState extends State<CaseListPage>
    with TickerProviderStateMixin {
  String _activeTab = 'all';
  late AnimationController _entryCtrl;

  final Map<String, _TabFilter> _tabFilters = {
    'all': _TabFilter(),
    'pending': _TabFilter(),
    'waiting': _TabFilter(),
    'consulting': _TabFilter(),
    'done': _TabFilter(),
    'cancelled': _TabFilter(),
  };

  final Map<String, TextEditingController> _searchControllers = {
    'all': TextEditingController(),
    'pending': TextEditingController(),
    'waiting': TextEditingController(),
    'consulting': TextEditingController(),
    'done': TextEditingController(),
    'cancelled': TextEditingController(),
  };

  List<dynamic> _caseList = [];
  bool _isLoading = true;

  final List<Map<String, dynamic>> _tabs = [
    {"key": "all", "label": "ทั้งหมด", "caseStatus": null},
    {"key": "pending", "label": "รอทนาย", "caseStatus": 1},
    {"key": "waiting", "label": "รอปรึกษา", "caseStatus": 2},
    {"key": "consulting", "label": "กำลังปรึกษา", "caseStatus": 3},
    {"key": "done", "label": "เสร็จสิ้น", "caseStatus": 4},
    {"key": "cancelled", "label": "ยกเลิก", "caseStatus": 0},
  ];

  @override
  void initState() {
    super.initState();
    _entryCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..forward();
    _loadCases();
  }

  @override
  void dispose() {
    _entryCtrl.dispose();
    for (final c in _searchControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  // ── API ────────────────────────────────────────────────
  Future<void> _loadCases() async {
    try {
      final res = await postDio('${server}/m/case/read', {});
      if (!mounted) return;

      setState(() {
        _caseList = res['objectData'] ?? [];
        _isLoading = false;
      });

      debugPrint('✅ Loaded ${_caseList.length} cases');
    } catch (e) {
      debugPrint('❌ Load cases error: $e');
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  _TabFilter get _currentFilter => _tabFilters[_activeTab]!;

  void _updateFilter(_TabFilter f) =>
      setState(() => _tabFilters[_activeTab] = f);

  List<Map<String, dynamic>> get _filtered {
    final f = _currentFilter;

    // 1. filter by tab
    List<Map<String, dynamic>> list = _caseList.cast<Map<String, dynamic>>();
    
    final tabStatus = _tabs
        .firstWhere((t) => t['key'] == _activeTab)['caseStatus'] as int?;
    
    if (tabStatus != null) {
      list = list.where((a) => a['caseStatus'] == tabStatus).toList();
    }

    // 2. search
    if (f.search.isNotEmpty) {
      final q = f.search.toLowerCase();
      list = list.where((a) {
        return (a['lawyerName']?.toString() ?? '').toLowerCase().contains(q) ||
            (a['topicTitle']?.toString() ?? '').toLowerCase().contains(q) ||
            (a['subTopicTitle']?.toString() ?? '').toLowerCase().contains(q) ||
            (a['code']?.toString() ?? '').toLowerCase().contains(q);
      }).toList();
    }

    // 3. sort
    switch (f.sort) {
      case 'date_asc':
        list.sort((a, b) {
          final dateA = DateTime.tryParse(a['caseDate']?.toString() ?? '');
          final dateB = DateTime.tryParse(b['caseDate']?.toString() ?? '');
          if (dateA == null || dateB == null) return 0;
          return dateA.compareTo(dateB);
        });
        break;
      case 'name_asc':
        list.sort((a, b) => (a['lawyerName']?.toString() ?? '')
            .compareTo(b['lawyerName']?.toString() ?? ''));
        break;
      default:
        list.sort((a, b) {
          final dateA = DateTime.tryParse(a['caseDate']?.toString() ?? '');
          final dateB = DateTime.tryParse(b['caseDate']?.toString() ?? '');
          if (dateA == null || dateB == null) return 0;
          return dateB.compareTo(dateA);
        });
    }

    return list;
  }

  int _countByTab(String tabKey) {
    final status = _tabs.firstWhere((t) => t['key'] == tabKey)['caseStatus'];
    if (status == null) return _caseList.length;
    return _caseList.where((a) => a['caseStatus'] == status).length;
  }

  String _statusLabel(int s) {
    switch (s) {
      case 0:
        return 'ยกเลิก';
      case 1:
        return 'รอทนาย';
      case 2:
        return 'รอปรึกษา';
      case 3:
        return 'กำลังปรึกษา';
      case 4:
        return 'เสร็จสิ้น';
      default:
        return 'ไม่ทราบ';
    }
  }

  Color _statusColor(int s) => const [
        Color(0xFFEF4444), // 0 = ยกเลิก
        Color(0xFFEA580C), // 1 = รอทนาย
        Color(0xFFF59E0B), // 2 = รอปรึกษา
        Color(0xFF059669), // 3 = ปรึกษา
        Color(0xFF6D28D9), // 4 = เสร็จ
      ][s.clamp(0, 4)];

  IconData _statusIcon(int s) => const [
        Icons.cancel_outlined,
        Icons.hourglass_top_rounded,
        Icons.pending_actions_rounded,
        Icons.headset_mic_rounded,
        Icons.task_alt_rounded,
      ][s.clamp(0, 4)];

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;
    final f = _currentFilter;
    final isDesktop = ResponsiveLayout.isDesktop(context);

    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      behavior: HitTestBehavior.opaque,
      child: Scaffold(
        backgroundColor:
            isDesktop ? const Color.fromARGB(255, 233, 242, 249) : Colors.white,
        appBar: isDesktop
            ? null
            : appBar(
                title: 'เคสของฉัน',
                backBtn: true,
                rightBtn: false,
                backAction: () => Navigator.pop(context),
                rightAction: () {},
              ),
        body: _isLoading
            ? _buildLoadingState()
            : GestureDetector(
                onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
                behavior: HitTestBehavior.opaque,
                child: AppLayout(
                  child: Container(
                    clipBehavior: isDesktop ? Clip.antiAlias : Clip.none,
                    decoration: isDesktop
                        ? const BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(20),
                              topRight: Radius.circular(20),
                            ),
                          )
                        : null,
                    child: Column(
                      children: [
                        if (isDesktop)
                          Padding(
                            padding:
                                const EdgeInsets.fromLTRB(24, 24, 24, 8),
                            child: Row(
                              children: [
                                const Text(
                                  'เคสของฉัน',
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF1A2340),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        _buildTabBar(),
                        _buildFilterBar(f),
                        if (f.hasActiveFilter) _buildActiveFilterChips(f),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
                          child: Row(children: [
                            Text(
                              'พบ ${filtered.length} เคส',
                              style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[500],
                                  fontWeight: FontWeight.w500),
                            ),
                          ]),
                        ),
                        Expanded(
                          child: filtered.isEmpty
                              ? _buildEmpty(f.hasActiveFilter)
                              : Container(
                                  color: const Color(0xFFF2F6FF),
                                  child: ListView.builder(
                                    padding: const EdgeInsets.fromLTRB(
                                        16, 8, 16, 32),
                                    itemCount: filtered.length,
                                    itemBuilder: (_, i) {
                                      final item = filtered[i];
                                      final delay =
                                          (i * 0.08).clamp(0.0, 0.7);
                                      return AnimatedBuilder(
                                        animation: _entryCtrl,
                                        builder: (_, child) {
                                          final t = Curves.easeOutCubic
                                              .transform(
                                            ((_entryCtrl.value - delay) /
                                                    (1 - delay))
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
                        const SizedBox(height: 50),
                      ],
                    ),
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: _tabs.map((t) {
            final isActive = _activeTab == t['key'];
            final count = _countByTab(t['key']!);
            final hasTabFilter = _tabFilters[t['key']]!.hasActiveFilter;
            const activeColor = Color(0xFF0262EC);

            return GestureDetector(
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
                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: isActive
                          ? activeColor
                          : Colors.transparent,
                      width: 2.5,
                    ),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      t['label']!,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight:
                            isActive ? FontWeight.w700 : FontWeight.w500,
                        color: isActive
                            ? activeColor
                            : Colors.grey[500],
                      ),
                    ),
                    const SizedBox(width: 4),
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: isActive ? activeColor : Colors.grey[200],
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            '$count',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: isActive ? Colors.white : Colors.grey[500],
                            ),
                          ),
                        ),
                        if (hasTabFilter)
                          Positioned(
                            top: -2,
                            right: -3,
                            child: Container(
                              width: 7,
                              height: 7,
                              decoration: const BoxDecoration(
                                color: activeColor,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildFilterBar(_TabFilter f) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
      child: Row(children: [
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
                hintText: 'ค้นหาเคส...',
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
                contentPadding: const EdgeInsets.only(bottom: 0, top: 5),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
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

  Widget _buildActiveFilterChips(_TabFilter f) {
    final sortLabels = {
      'date_desc': 'เร็วที่สุด',
      'date_asc': 'เก่าที่สุด',
      'name_asc': 'ชื่อ A-Z',
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
            'ล้างตัวกรอง',
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

  void _showSortSheet(_TabFilter f) {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _SortSheet(
        currentSort: f.sort,
        onSelect: (sort) => _updateFilter(f.copyWith(sort: sort)),
      ),
    );
  }

  Widget _buildCard(Map<String, dynamic> item) {
    final status = item['caseStatus'] as int? ?? 0;
    final color = _statusColor(status);
    const lawyerColor = Color(0xFF0262EC);
    final isDone = status == 4;
    final isConsulting = status == 3;
    final isWaiting = status == 1;

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        final caseMap = Map<String, dynamic>.from(item);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AppointmentDetails(
              appointment:
                  UserCaseAdapter.forAppointmentDetails(caseMap),
            ),
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
                const Text('รอทนายยืนยัน',
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFFEA580C))),
              ]),
            ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(50),
                child: Container(
                  width: 60,
                  height: 60,
                  color: const Color(0xFFF2F4F7),
                  child: Center(
                    child: Text(
                      (item['lawyerName']?.toString() ?? 'ท')
                          .characters
                          .first,
                      style: const TextStyle(
                          fontSize: 24,
                          color: lawyerColor,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Expanded(
                          child: Text(
                              item['lawyerName']?.toString() ?? 'ไม่ระบุ',
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
                      Text('ทนายความ',
                          style: TextStyle(
                              fontSize: 11, color: Colors.grey[500])),
                    ]),
              ),
            ]),
          ),
          const Divider(height: 1, color: Color(0xFFF0F4F8)),
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
                        Text(item['topicTitle']?.toString() ?? '',
                            style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF1A2340))),
                        if ((item['subTopicTitle']?.toString() ?? '')
                            .isNotEmpty)
                          Text(item['subTopicTitle']?.toString() ?? '',
                              style: TextStyle(
                                  fontSize: 10, color: Colors.grey[500])),
                      ]),
                ),
              ]),
              const SizedBox(height: 8),
              Row(children: [
                Expanded(
                  child: _detailChip(Icons.calendar_today_rounded,
                      item['caseDate']?.toString() ?? ''),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _detailChip(Icons.access_time_rounded,
                      '${item['startTime'] ?? ''} - ${item['endTime'] ?? ''}'),
                ),
              ]),
              if (isDone) ...[
                const SizedBox(height: 8),
                Row(children: [
                  Text('# ${item['code'] ?? item['id']}',
                      style: TextStyle(fontSize: 10, color: Colors.grey[400])),
                ]),
              ] else ...[
                const SizedBox(height: 6),
                Row(children: [
                  Text('# ${item['code'] ?? item['id']}',
                      style: TextStyle(fontSize: 10, color: Colors.grey[400])),
                ]),
              ],
            ]),
          ),
          if (isWaiting)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
              child: Row(children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => _showCancelDialog(item['code'] as String),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEA580C).withOpacity(0.06),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: const Color(0xFFEA580C).withOpacity(0.25)),
                      ),
                      child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.close_rounded,
                                size: 14, color: Color(0xFFEA580C)),
                            const SizedBox(width: 6),
                            const Text('ยกเลิกเคส',
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
                      child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.visibility_outlined,
                                size: 14, color: Colors.white),
                            const SizedBox(width: 6),
                            const Text('ดูรายละเอียด',
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
          'คุณต้องการยกเลิก $id หรือไม่',
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
                    child: Text('ไม่ใช่',
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
                  Navigator.pop(context);
                  _showReasonDialog(id);
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
                    child: Text('ใช่',
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

  void _showReasonDialog(String caseId) {
    final commentController = TextEditingController();
    StateSetter? _modalSetState;

    commentController.addListener(() {
      _modalSetState?.call(() {});
    });

    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierLabel: "reason",
      barrierColor: Colors.black.withOpacity(0.4),
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (ctx, animation, secondaryAnimation) => StatefulBuilder(
        builder: (context, setModalState) {
          _modalSetState = setModalState;
          return Center(
            child: AppLayout(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 30),
                padding: const EdgeInsets.all(25),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(25),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(height: 10),
                      const Text(
                        'เหตุผลในการยกเลิก',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: commentController,
                        maxLines: 3,
                        maxLength: 300,
                        keyboardType: TextInputType.multiline,
                        textInputAction: TextInputAction.newline,
                        decoration: InputDecoration(
                          hintText: 'บอกเหตุผลการยกเลิก',
                          hintStyle:
                              TextStyle(color: Colors.grey[400], fontSize: 13),
                          filled: true,
                          fillColor: const Color(0xFFEEF2F5),
                          contentPadding: const EdgeInsets.all(14),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(
                                color: Color(0xFFEEF2F5), width: 1.5),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(
                                color: Color(0xFFEEF2F5), width: 1.5),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(
                                color: Color(0xFF0262EC), width: 1.5),
                          ),
                          counterStyle: TextStyle(
                              color: Colors.grey[400], fontSize: 11),
                        ),
                      ),
                      const SizedBox(height: 25),
                      SizedBox(
                        width: double.infinity,
                        child: Row(
                          children: [
                            Expanded(
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor:
                                      const Color(0xFFEA580C),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                                onPressed: () {
                                  Navigator.pop(context);
                                },
                                child: const Text(
                                  'ยกเลิก',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 15),
                            Expanded(
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: commentController
                                          .text.isNotEmpty
                                      ? const Color(0xFF0262EC)
                                      : const Color(0xFFEEF2F5),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                                onPressed:
                                    commentController.text.isNotEmpty
                                        ? () {
                                            Navigator.pop(context);
                                            DialogService.showAutoClose(
                                              context,
                                              title: 'สำเร็จ',
                                              seconds: 3,
                                              isBtn: false,
                                              message:
                                                  'ยกเลิกเคสสำเร็จแล้ว',
                                              onClose: () {
                                                setState(() {
                                                  _caseList.removeWhere((c) =>
                                                      c['code'] == caseId);
                                                });
                                              },
                                            );
                                          }
                                        : null,
                                child: const Text(
                                  'ยืนยัน',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return Transform.scale(
          scale: Curves.easeOutBack.transform(animation.value),
          child: child,
        );
      },
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
            hasFilter ? 'ไม่พบเคสที่ตรงกัน' : 'ไม่มีเคส',
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
              child: const Text('ล้างตัวกรอง',
                  style: TextStyle(
                      fontSize: 12,
                      color: Color(0xFF0262EC))),
            )
          else
            Text('ไม่มีข้อมูลเคส',
                style: TextStyle(color: Colors.grey[400], fontSize: 12)),
        ]),
      );

  Widget _buildLoadingState() {
    return const AppLoadingInline(height: 80, size: 28);
  }
}

// ══════════════════════════════════════════════════════════
//  _SortSheet
// ══════════════════════════════════════════════════════════

class _SortSheet extends StatelessWidget {
  final String currentSort;
  final ValueChanged<String> onSelect;

  const _SortSheet({required this.currentSort, required this.onSelect});

  static const _kPrimary = Color(0xFF0262EC);

  static const _options = [
    ('date_desc', Icons.arrow_downward_rounded, 'เร็วที่สุด'),
    ('date_asc', Icons.arrow_upward_rounded, 'เก่าที่สุด'),
    ('name_asc', Icons.sort_by_alpha_rounded, 'ชื่อ A-Z'),
  ];

  @override
  Widget build(BuildContext context) {
    final sheet = AppLayout(
      child: Container(
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
                const Text('เรียงลำดับ',
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
                        fontWeight:
                            selected ? FontWeight.w700 : FontWeight.w500,
                        color: selected ? _kPrimary : const Color(0xFF1A2340))),
                trailing: selected
                    ? const Icon(Icons.check_rounded,
                        color: _kPrimary, size: 18)
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
      ),
    );

    return GestureDetector(
      onTap: () => Navigator.pop(context),
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          GestureDetector(
            onTap: () {},
            child: sheet,
          ),
        ],
      ),
    );
  }
}