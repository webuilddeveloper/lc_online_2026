import 'dart:async';

import 'package:LawyerOnline/add-appointment.dart';
import 'package:LawyerOnline/lawyer-online-details.dart';
import 'package:LawyerOnline/lawyer-online-filter.dart';
import 'package:LawyerOnline/shared/api_provider.dart';
import 'package:flutter/material.dart';
import 'package:LawyerOnline/component/appbar.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

class LawyerOnlineList extends StatefulWidget {
  LawyerOnlineList({super.key, this.topic, this.subTopic});

  String? topic;
  String? subTopic;

  @override
  State<LawyerOnlineList> createState() => _LawyerOnlineListState();
}

class _LawyerOnlineListState extends State<LawyerOnlineList>
    with TickerProviderStateMixin {
  static const _kPrimary = Color(0xFF0262EC);

  // ── Data ──────────────────────────────────────────────
  final List<dynamic> lawyerOnlineList = [
    {
      "code": "0",
      "name": "ศักดิ์สิทธิ์ พิพากษ์",
      'title': 'ทนายความอาวุโส',
      "rating": 4.8,
      "cost": "Free",
      "costUnit": "/hr",
      "imageUrl": "assets/images/lawyer-avatar-1.png",
      "experience": "11+ ปี",
      "experienceYears": 11,
      "clientReviews": 60,
      "casesWon": "148+",
      "price": 500,
      "available": true,
      "distance": "1.2 กม.",
      "distanceKm": 1.2,
      "province": "กรุงเทพมหานคร",
      "skills": ["อาญาและอาชญากรรม", "ครอบครัวและมรดก"],
      'avatar': 'ศ',
      'color': 0xFF1565C0,
    },
    {
      "code": "1",
      "name": "ธนากร นิติศักดิ์",
      'title': 'ทนายความอาวุโส',
      "rating": 4.1,
      "cost": "Free",
      "costUnit": "/hr",
      "imageUrl": "assets/images/lawyer-avatar-2.png",
      "experience": "19+ ปี",
      "experienceYears": 19,
      "clientReviews": 60,
      "casesWon": "148+",
      "price": 500,
      "available": true,
      "distance": "650 กม.",
      "distanceKm": 650,
      "province": "เชียงใหม่",
      "skills": ["หนี้สินและการเงิน", "ธุรกิจและบริษัท"],
      'avatar': 'ธ',
      'color': 0xFF6A1B9A,
    },
    {
      "code": "2",
      "name": "พงษ์ภพ ยุติธรรม",
      'title': 'ทนายความอาวุโส',
      "rating": 3.9,
      "cost": "Free",
      "costUnit": "/hr",
      "imageUrl": "assets/images/lawyer-avatar-3.png",
      "experience": "10+ ปี",
      "experienceYears": 10,
      "clientReviews": 60,
      "casesWon": "148+",
      "price": 500,
      "available": false,
      "distance": "450 กม.",
      "distanceKm": 450,
      "province": "ขอนแก่น",
      "skills": ["แรงงานและการจ้างงาน", "ประกันภัยและผู้บริโภค"],
      'avatar': 'พ',
      'color': 0xFF2E7D32,
    },
    {
      "code": "3",
      "name": "อาริย์ ศิษย์กฎหมาย",
      'title': 'ทนายความอาวุโส',
      "rating": 3.0,
      "cost": "200",
      "costUnit": "/hr",
      "imageUrl": "assets/images/lawyer-avatar-4.png",
      "experience": "12+ ปี",
      "experienceYears": 12,
      "clientReviews": 60,
      "casesWon": "148+",
      "price": 500,
      "available": true,
      "distance": "65 กม.",
      "distanceKm": 65,
      "province": "ชลบุรี",
      "skills": ["ทรัพย์สินและที่ดิน", "ฟ้องศาล เรียกค่าเสียหาย"],
      'avatar': 'อ',
      'color': 0xFFBF360C,
    },
    {
      "code": "4",
      "name": "Sachin K",
      'title': 'ทนายความอาวุโส',
      "rating": 4.9,
      "cost": "1000",
      "costUnit": "/hr",
      "imageUrl": "assets/images/lawyer-avatar-5.png",
      "experience": "20+ ปี",
      "experienceYears": 20,
      "clientReviews": 60,
      "casesWon": "148+",
      "price": 500,
      "available": true,
      "distance": "930 กม.",
      "distanceKm": 930,
      "province": "ภูเก็ต",
      "skills": ["คดีออนไลน์และเทคโนโลยี", "อื่นๆและระหว่างประเทศ"],
      'avatar': 'S',
      'color': 0xFF00695C,
    },
  ];

  // ── Filter State ───────────────────────────────────────
  bool _filterAvailableOnly = false;
  String _sortBy = 'none'; // none | rating | experience | distance
  String _searchText = '';
  String _selectedProvince = 'ทั้งหมด';
  int? _selectedIdx;

  // Provinces (derived from data + "ทั้งหมด")
  List<dynamic> _allProvinces = [];

  // ── Computed filtered + sorted list ───────────────────
  List<dynamic> get _filteredLawyers {
    var list = List<dynamic>.from(lawyerOnlineList);

    if (_searchText.isNotEmpty) {
      list = list.where((l) {
        final name = (l['name'] as String).toLowerCase();
        final skills = (l['skills'] as List).join(' ').toLowerCase();
        final q = _searchText.toLowerCase();
        return name.contains(q) || skills.contains(q);
      }).toList();
    }

    if (_filterAvailableOnly) {
      list = list.where((l) => l['available'] as bool).toList();
    }

    if (_selectedProvince != 'ทั้งหมด') {
      list = list.where((l) => l['province'] == _selectedProvince).toList();
    }

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
    if (_selectedProvince != 'ทั้งหมด') c++;
    return c;
  }

  void _clearFilters() => setState(() {
        _filterAvailableOnly = false;
        _sortBy = 'none';
        _searchText = '';
        _selectedProvince = 'ทั้งหมด';
      });

  // ── Location ───────────────────────────────────────────
  LatLng? currentLocation;

  @override
  void initState() {
    super.initState();
    // getCurrentLocation();
    getProvince();
  }

  Future<void> getCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    Position position = await Geolocator.getCurrentPosition();
    setState(() {
      currentLocation = LatLng(position.latitude, position.longitude);
    });
  }

  void goBack() async {
    Navigator.pop(context, false);
  }

  // ── Filter Bottom Sheet ────────────────────────────────
  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setModalState) => _buildFilterSheet(ctx, setModalState),
      ),
    );
  }

  // ════════════════════════════════════════════════════════
  //  BUILD
  // ════════════════════════════════════════════════════════

  Future<dynamic> getProvince() async {
    final result = await postObjectData("route/province/read", {});
    if (result['status'] == 'S') {
      setState(() {
        _allProvinces = [
          {'code': '0', 'title': 'ทั้งหมด'},
          ...result['objectData'].map((p) => {'code': p['code'], 'title': p['title']})
        ];
        print(_allProvinces);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredLawyers;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: appBarCustom(
        title: "หมอความออนไลน์",
        backBtn: true,
        isRightWidget: false,
        backAction: () => goBack(),
        
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        behavior: HitTestBehavior.opaque,
        child: Column(
          children: [
            // _buildHeader(),
            const SizedBox(height: 5,),
            _buildSearchFilterBar(),
            if (_activeFilterCount > 0 || (widget.topic ?? '') != '') _buildActiveChips(),
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
            Expanded(
              child: filtered.isEmpty
                  ? _buildEmpty()
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: filtered.length,
                      itemBuilder: (_, i) => _buildLawyerCard(filtered[i]),
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
          child: const Icon(Icons.gavel_rounded,
              color: Color(0xFFFFFFFF), size: 20),
        ),
        const SizedBox(width: 10),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('หมอความออนไลน์',
              style: TextStyle(
                  color: Color(0xFF1A2340),
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.3)),
          Text('เลือกทนายที่ใช่ เพื่อนัดหมายปรึกษา',
              style: TextStyle(
                  color: const Color(0xFF1A2340).withOpacity(0.4),
                  fontSize: 11)),
        ]),
      ]),
    );
  }

  Widget _buildSearchFilterBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
      child: Row(children: [
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
        GestureDetector(
          onTap: _showFilterSheet,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: _activeFilterCount > 0 ? _kPrimary : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _activeFilterCount > 0
                    ? _kPrimary
                    : const Color(0xFFE2E8F4),
              ),
              boxShadow: [
                BoxShadow(
                  color: _activeFilterCount > 0
                      ? _kPrimary.withOpacity(0.3)
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
                        border: Border.all(color: _kPrimary, width: 1.5),
                      ),
                      child: Center(
                        child: Text(
                          '$_activeFilterCount',
                          style: const TextStyle(
                            fontSize: 8,
                            fontWeight: FontWeight.w800,
                            color: _kPrimary,
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
        if (widget.topic != '') ...[
          _activeChip(widget.topic!,
              onRemove: () => {}, isRemove: false),
          const SizedBox(width: 6),
        ],
        if (_filterAvailableOnly)
          _activeChip('ว่างอยู่',
              onRemove: () => setState(() => _filterAvailableOnly = false)),
        if (_filterAvailableOnly && _sortBy != 'none') const SizedBox(width: 6),
        if (_sortBy != 'none')
          _activeChip(_sortLabel(_sortBy),
              onRemove: () => setState(() => _sortBy = 'none')),
        if (_selectedProvince != 'ทั้งหมด') ...[
          if (_filterAvailableOnly || _sortBy != 'none')
            const SizedBox(width: 6),
          _activeChip(_selectedProvince,
              icon: Icons.location_city_outlined,
              onRemove: () => setState(() => _selectedProvince = 'ทั้งหมด')),
        ],
        const Spacer(),
        GestureDetector(
          onTap: _clearFilters,
          child: Text('ล้างทั้งหมด',
              style: TextStyle(
                  fontSize: 11,
                  color: _kPrimary.withOpacity(0.8),
                  fontWeight: FontWeight.w600)),
        ),
      ]),
    );
  }

  Widget _activeChip(String label,
          {required VoidCallback onRemove, IconData? icon, bool isRemove = true}) =>
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: _kPrimary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _kPrimary.withOpacity(0.3)),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          if (icon != null) ...[
            Icon(icon, size: 11, color: _kPrimary),
            const SizedBox(width: 3),
          ],
          Text(label,
              style: const TextStyle(
                  fontSize: 11, color: _kPrimary, fontWeight: FontWeight.w600)),
          const SizedBox(width: 4),
          isRemove ?
          GestureDetector(
            onTap: onRemove,
            child: const Icon(Icons.close_rounded, size: 13, color: _kPrimary),
          ) : const SizedBox()
        ]),
      );

  Widget _buildLawyerCard(dynamic l) {
    final available = l['available'] as bool;
    final originalIdx =
        lawyerOnlineList.indexWhere((e) => e['code'] == l['code']);
    final isSelected = _selectedIdx == originalIdx;

    return GestureDetector(
      onTap: available
          ? () {
              setState(() => _selectedIdx = originalIdx);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => LawyerOnlineDetails(
                    code: l['code'],
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
            color:  Colors.transparent,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: _kPrimary.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Opacity(
          opacity: available ? 1.0 : 0.5,
          child: Column(
            children: [
              // ── Row 1: Avatar + Info + Badge ──────────
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Avatar
                  (l['imageUrl'] ?? '') != ''
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(30),
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
                              Color(l['color'] as int).withOpacity(0.15),
                          child: Text(
                            l['avatar'] as String,
                            style: TextStyle(
                              color: Color(l['color'] as int),
                              fontWeight: FontWeight.bold,
                              fontSize: 24,
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
                                color: Colors.grey[400], fontSize: 12)),
                        const SizedBox(height: 4),
                        Row(children: [
                          const Icon(Icons.star_rounded,
                              color: Color(0xFFFFC107), size: 14),
                          const SizedBox(width: 2),
                          Text('${l['rating']}',
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600, fontSize: 12)),
                          Text(' (${l['clientReviews']} รีวิว)',
                              style: TextStyle(
                                  color: Colors.grey[400], fontSize: 12)),
                        ]),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(height: 1, color: Color(0xFFEEF2F5)),
              const SizedBox(height: 10),

              // ── Row 2: Skills + Experience ─────────────
              Row(children: [
                _chip(Icons.gavel_outlined,
                    (l['skills'] as List).first as String),
                const SizedBox(width: 8),
                _chip(Icons.history_outlined, l['experience'] as String),
              ]),
              const SizedBox(height: 8),

              // ── Row 3: Province + Distance ─────────────
              Row(children: [
                _chip(
                  Icons.location_city_outlined,
                  l['province'] as String,
                  highlight: _selectedProvince == l['province'],
                ),
                const SizedBox(width: 8),
                _chip(Icons.location_on_outlined, l['distance'] as String),
              ]),
              const SizedBox(height: 8),

              // ── Row 4: Cost ────────────────────────────
              Row(children: [
                _chip(
                  Icons.payments_outlined,
                  l['cost'] == 'Free'
                      ? 'ไม่เสียค่าใช้จ่าย'
                      : '${l['cost']}${l['costUnit']}',
                ),
              ]),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmpty() => Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 64,
            height: 64,
            decoration: const BoxDecoration(
              color: Color(0xFFEEF2F5),
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
                style:
                    TextStyle(fontSize: 12, color: _kPrimary.withOpacity(0.8))),
          ),
        ]),
      );

  // ── Badge (ว่างอยู่ / ไม่ว่าง) ────────────────────────
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

  // ── Info Chip ──────────────────────────────────────────
  Widget _chip(IconData icon, String label, {bool highlight = false}) =>
      Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: highlight
                ? _kPrimary.withOpacity(0.08)
                : const Color(0xFFEEF2F5),
            borderRadius: BorderRadius.circular(8),
            border: highlight
                ? Border.all(color: _kPrimary.withOpacity(0.3))
                : null,
          ),
          child: Row(children: [
            Icon(icon, size: 13, color: _kPrimary),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: highlight ? FontWeight.w700 : FontWeight.w400,
                  color: highlight ? _kPrimary : const Color(0xFF1A2340),
                ),
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

  // ════════════════════════════════════════════════════════
  //  Filter Bottom Sheet (เหมือน LawyerPage ทุกประการ)
  // ════════════════════════════════════════════════════════

  Widget _buildFilterSheet(BuildContext context, StateSetter setModalState) {
    return Container(
      padding: EdgeInsets.fromLTRB(
          20, 0, 20, MediaQuery.of(context).padding.bottom + 20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
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

            const Text('ตัวกรอง',
                style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1A2340))),
            const SizedBox(height: 20),

            // ── สถานะ ─────────────────────────────────────
            const Text('สถานะ',
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1A2340))),
            const SizedBox(height: 10),
            GestureDetector(
              onTap: () => setModalState(
                  () => _filterAvailableOnly = !_filterAvailableOnly),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: _filterAvailableOnly
                      ? _kPrimary.withOpacity(0.08)
                      : const Color(0xFFF8F9FB),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: _filterAvailableOnly
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
                      color: _filterAvailableOnly ? _kPrimary : Colors.white,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: _filterAvailableOnly
                            ? _kPrimary
                            : const Color(0xFFCCCCCC),
                      ),
                    ),
                    child: _filterAvailableOnly
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

            // ── จังหวัด ────────────────────────────────────
            Row(children: [
              const Text('จังหวัด',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1A2340))),
              const Spacer(),
              if (_selectedProvince != 'ทั้งหมด')
                GestureDetector(
                  onTap: () =>
                      setModalState(() => _selectedProvince = 'ทั้งหมด'),
                  child: Text('ล้าง',
                      style: TextStyle(
                          fontSize: 11,
                          color: _kPrimary.withOpacity(0.7),
                          fontWeight: FontWeight.w600)),
                ),
            ]),
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              decoration: BoxDecoration(
                color: _selectedProvince != 'ทั้งหมด'
                    ? _kPrimary.withOpacity(0.08)
                    : const Color(0xFFF8F9FB),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: _selectedProvince != 'ทั้งหมด'
                      ? _kPrimary.withOpacity(0.4)
                      : const Color(0xFFE2E8F4),
                  width: 1.5,
                ),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value:
                      _allProvinces.any((e) => e['title'] == _selectedProvince)
                          ? _selectedProvince
                          : null,
                  isExpanded: true,
                  icon: Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: _selectedProvince != 'ทั้งหมด'
                        ? _kPrimary
                        : Colors.grey[400],
                    size: 20,
                  ),
                  selectedItemBuilder: (_) => _allProvinces.map((p) {
                    return Row(children: [
                      Icon(
                        p['title'] != 'ทั้งหมด'
                            ? Icons.location_city_outlined
                            : Icons.public_rounded,
                        size: 15,
                        color: _selectedProvince != 'ทั้งหมด'
                            ? _kPrimary
                            : Colors.grey[400],
                      ),
                      const SizedBox(width: 8),
                      Text(
                        p['title']!,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: _selectedProvince != 'ทั้งหมด'
                              ? _kPrimary
                              : const Color(0xFF64748B),
                        ),
                      ),
                    ]);
                  }).toList(),
                  items: _allProvinces.map<DropdownMenuItem<String>>((p) {
                    final isSelected = _selectedProvince == p['title'];
                    return DropdownMenuItem<String>(
                      value: p['title'],
                      child: Row(children: [
                        Icon(
                          p['title'] != 'ทั้งหมด'
                              ? Icons.location_city_outlined
                              : Icons.public_rounded,
                          size: 15,
                          color: isSelected ? _kPrimary : Colors.grey[400],
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            p['title']!,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: isSelected
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              color: isSelected
                                  ? _kPrimary
                                  : const Color(0xFF1A2340),
                            ),
                          ),
                        ),
                        if (isSelected)
                          const Icon(Icons.check_rounded,
                              size: 15, color: _kPrimary),
                      ]),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null)
                      setModalState(() => _selectedProvince = val);
                  },
                ),
              ),
            ),
            const SizedBox(height: 20),

            // ── เรียงตาม ───────────────────────────────────
            const Text('เรียงตาม',
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1A2340))),
            const SizedBox(height: 10),
            Row(children: [
              _sortChip(
                  'none', 'ค่าเริ่มต้น', Icons.sort_rounded, setModalState),
              const SizedBox(width: 8),
              _sortChip('rating', 'คะแนน', Icons.star_rounded, setModalState),
            ]),
            const SizedBox(height: 8),
            Row(children: [
              _sortChip('experience', 'ประสบการณ์', Icons.history_rounded,
                  setModalState),
              const SizedBox(width: 8),
              _sortChip('distance', 'ใกล้ที่สุด', Icons.location_on_rounded,
                  setModalState),
            ]),
            const SizedBox(height: 24),

            // ── Buttons ────────────────────────────────────
            Row(children: [
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    setModalState(() {
                      _filterAvailableOnly = false;
                      _sortBy = 'none';
                      _selectedProvince = 'ทั้งหมด';
                    });
                  },
                  child: Container(
                    height: 48,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF2F6FF),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                          color: const Color(0xFFDDE5F4), width: 1.5),
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
                    setState(() {});
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
      ),
    );
  }

  Widget _sortChip(
      String value, String label, IconData icon, StateSetter setModalState) {
    final selected = _sortBy == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setModalState(() => _sortBy = value),
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
