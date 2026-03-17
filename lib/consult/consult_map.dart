import 'dart:async';
import 'dart:math';
import 'package:LawyerOnline/component/appbar.dart';
import 'package:LawyerOnline/consult/consult_detail.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

enum _Phase { searching, found }

class ConsultMapPage extends StatefulWidget {
  const ConsultMapPage({super.key});
  @override
  State<ConsultMapPage> createState() => _ConsultMapPageState();
}

class _ConsultMapPageState extends State<ConsultMapPage>
    with TickerProviderStateMixin {
  int selectedIndex = 0;
  _Phase _phase = _Phase.searching;
  bool _isReassigning = false;

  final MapController _mapController = MapController();
  LatLng _userLocation = const LatLng(13.7563, 100.5018);

  // Pulse rings
  late AnimationController _p1, _p2, _p3;
  late Animation<double> _p1a, _p2a, _p3a;

  // Slide-up panel
  late AnimationController _slideAnim;
  late Animation<Offset> _slideOffset;

  // Card pop
  late AnimationController _cardAnim;

  // Status text cycling during initial search
  final List<String> _statusTexts = [
    'กำลังระบุตำแหน่งของคุณ...',
    'กำลังค้นหาทนายในพื้นที่...',
    'กำลังส่งคำขอไปยังทนาย...',
    'ทนายรับเคสของคุณแล้ว! 🎉',
  ];
  int _statusIdx = 0;
  Timer? _textTimer;

  // The assigned lawyer — mutable, changes on reassign
  late Map<String, dynamic> _assignedLawyer;

  // Full lawyer pool (used by tab 2 list and random assign)
  final _lawyers = <Map<String, dynamic>>[
    {
      'name': 'ศักดิ์สิทธิ์ พิพากษ์',
      'title': 'ทนายความอาวุโส',
      'specialty': 'Criminal lawyer, Corporate lawyer',
      'experience': '11+ ปี',
      'rating': 4.8,
      'reviews': 60,
      'price': 0,
      'distance': '1.2 กม.',
      'eta': '~3 นาที',
      'available': true,
      'office': 'สำนักงาน ศักดิ์สิทธิ์',
      'avatar': 'ศ',
      'color': 0xFF1565C0,
      "imageUrl": "assets/images/lawyer-avatar-1.png",
    },
    {
      'name': 'พิมพ์ใจ รักษาธรรม',
      'title': 'ทนายความ',
      'specialty': 'กฎหมายครอบครัว, มรดก',
      'experience': '12 ปี',
      'rating': 4.8,
      'reviews': 198,
      'price': 1200,
      'distance': '2.5 กม.',
      'eta': '~5 นาที',
      'available': true,
      'office': 'สำนักงานกฎหมาย พิมพ์ใจ',
      'avatar': 'พ',
      'color': 0xFF6A1B9A,
      "imageUrl": "assets/images/lawyer-avatar-2.png",
    },
    {
      'name': 'ธนากร นิติบัณฑิต',
      'title': 'ที่ปรึกษากฎหมาย',
      'specialty': 'กฎหมายธุรกิจ, สัญญา',
      'experience': '9 ปี',
      'rating': 4.7,
      'reviews': 145,
      'price': 1000,
      'distance': '3.1 กม.',
      'eta': '~7 นาที',
      'available': false,
      'office': 'บริษัท นิติธนากร จำกัด',
      'avatar': 'ธ',
      'color': 0xFF2E7D32,
      "imageUrl": "assets/images/lawyer-avatar-3.png",
    },
    {
      'name': 'วีระ ศักดิ์สิทธิ์กุล',
      'title': 'ทนายความอาวุโส',
      'specialty': 'คดีแรงงาน, ประกันสังคม',
      'experience': '22 ปี',
      'rating': 5.0,
      'reviews': 427,
      'price': 2000,
      'distance': '4.0 กม.',
      'eta': '~8 นาที',
      'available': true,
      'office': 'สำนักงาน วีระ ลอว์',
      'avatar': 'ว',
      'color': 0xFFBF360C,
      "imageUrl": "assets/images/lawyer-avatar-5.png",
    },
    {
      'name': 'อรุณี ยุติธรรม',
      'title': 'ทนายความ',
      'specialty': 'กฎหมายที่ดิน, ทรัพย์สิน',
      'experience': '7 ปี',
      'rating': 4.6,
      'reviews': 89,
      'price': 800,
      'distance': '5.3 กม.',
      'eta': '~10 นาที',
      'available': true,
      'office': 'สำนักงานกฎหมาย อรุณี',
      'avatar': 'อ',
      'color': 0xFF00695C,
      "imageUrl": "assets/images/lawyer-avatar-4.png",
    },
  ];

  // ─────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _assignedLawyer = Map.from(_lawyers[0]);
    _initPulse();
    _initSlide();
    _initCard();
    _tryGps();
    _startSequence();
  }

  void _initPulse() {
    _p1 = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1600))
      ..repeat();
    _p1a = Tween<double>(begin: 0, end: 1)
        .animate(CurvedAnimation(parent: _p1, curve: Curves.easeOut));

    _p2 = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1600));
    _p2a = Tween<double>(begin: 0, end: 1)
        .animate(CurvedAnimation(parent: _p2, curve: Curves.easeOut));
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) _p2.repeat();
    });

    _p3 = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1600));
    _p3a = Tween<double>(begin: 0, end: 1)
        .animate(CurvedAnimation(parent: _p3, curve: Curves.easeOut));
    Future.delayed(const Duration(milliseconds: 1000), () {
      if (mounted) _p3.repeat();
    });
  }

  void _initSlide() {
    _slideAnim = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _slideOffset = Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero)
        .animate(
            CurvedAnimation(parent: _slideAnim, curve: Curves.easeOutCubic));
  }

  void _initCard() {
    _cardAnim = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
  }

  void _startSequence() {
    _textTimer = Timer.periodic(const Duration(milliseconds: 900), (t) {
      if (!mounted) return;
      if (_statusIdx < _statusTexts.length - 1) {
        setState(() => _statusIdx++);
      } else {
        t.cancel();
      }
    });

    Timer(const Duration(milliseconds: 3600), () {
      if (!mounted) return;
      _p1.stop();
      _p2.stop();
      _p3.stop();
      _assignedLawyer = Map.from(_pickRandom(null));
      setState(() => _phase = _Phase.found);
      _slideAnim.forward().then((_) => _cardAnim.forward());
    });
  }

  Map<String, dynamic> _pickRandom(String? excludeName) {
    final pool = _lawyers.where((l) => l['name'] != excludeName).toList();
    return pool[Random().nextInt(pool.length)];
  }

  void _onReassign() async {
    if (_isReassigning) return;
    setState(() => _isReassigning = true);
    _cardAnim.reverse();
    await Future.delayed(const Duration(milliseconds: 350));
    await Future.delayed(const Duration(milliseconds: 1800));
    if (!mounted) return;
    final current = _assignedLawyer['name'] as String;
    _assignedLawyer = Map.from(_pickRandom(current));
    setState(() => _isReassigning = false);
    _cardAnim.forward(from: 0);
  }

  void _tryGps() async {
    try {
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.whileInUse ||
          perm == LocationPermission.always) {
        final pos = await Geolocator.getCurrentPosition(
                desiredAccuracy: LocationAccuracy.high)
            .timeout(const Duration(seconds: 4));
        if (mounted) {
          final loc = LatLng(pos.latitude, pos.longitude);
          setState(() => _userLocation = loc);
          _mapController.move(loc, 14);
        }
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _p1.dispose();
    _p2.dispose();
    _p3.dispose();
    _slideAnim.dispose();
    _cardAnim.dispose();
    _textTimer?.cancel();
    _mapController.dispose();
    super.dispose();
  }

  // ══════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEEF2F5),
      appBar: appBar(
        title: "หมอความออนไลน์",
        backBtn: true,
        rightBtn: false,
        rightAction: () {},
        backAction: () => Navigator.pop(context),
      ),
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(children: [
            Expanded(child: _tab("หาทนายให้ฉัน", 0)),
            const SizedBox(width: 12),
            Expanded(child: _tab("เลือกทนายเอง", 1)),
          ]),
        ),
        Expanded(child: selectedIndex == 0 ? _mapView() : _listView()),
      ]),
    );
  }

  Widget _tab(String t, int i) {
    final on = selectedIndex == i;
    return GestureDetector(
      onTap: () => setState(() => selectedIndex = i),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 45,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: on ? const Color(0xFF0262EC) : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
              color: on ? const Color(0xFF0262EC) : const Color(0xFFDDE3EE)),
        ),
        child: Text(t,
            style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: on ? Colors.white : Colors.grey[500])),
      ),
    );
  }

  // ══════════════ MAP VIEW ══════════════
  Widget _mapView() {
    return Stack(children: [
      FlutterMap(
        mapController: _mapController,
        options: MapOptions(initialCenter: _userLocation, initialZoom: 14),
        children: [
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'td.webuild.lawyer',
          ),
          MarkerLayer(markers: [
            Marker(
                point: _userLocation,
                width: 60,
                height: 60,
                child: _userMarker()),
          ]),
        ],
      ),
      if (_phase == _Phase.searching) _searchingOverlay(),
      if (_phase == _Phase.found)
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: SlideTransition(
            position: _slideOffset,
            child: _acceptedPanel(),
          ),
        ),
    ]);
  }

  Widget _userMarker() => Stack(alignment: Alignment.center, children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFF0262EC).withOpacity(0.15),
          ),
        ),
        Container(
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFF0262EC),
            border: Border.all(color: Colors.white, width: 3),
            boxShadow: [
              BoxShadow(
                  color: const Color(0xFF0262EC).withOpacity(0.5),
                  blurRadius: 8)
            ],
          ),
        ),
      ]);

  // ══════════════ SEARCHING OVERLAY ══════════════
  Widget _searchingOverlay() => Container(
        color: Colors.black.withOpacity(0.38),
        child: Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            SizedBox(
              width: 200,
              height: 200,
              child: Stack(alignment: Alignment.center, children: [
                _ring(_p1a),
                _ring(_p2a),
                _ring(_p3a),
                Container(
                  width: 62,
                  height: 62,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF0262EC),
                    boxShadow: [
                      BoxShadow(
                          color: const Color(0xFF0262EC).withOpacity(0.6),
                          blurRadius: 20,
                          spreadRadius: 4)
                    ],
                  ),
                  child: const Icon(Icons.gavel_rounded,
                      color: Colors.white, size: 28),
                ),
              ]),
            ),
            const SizedBox(height: 28),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 350),
              transitionBuilder: (child, anim) => FadeTransition(
                  opacity: anim,
                  child: SlideTransition(
                      position: Tween<Offset>(
                              begin: const Offset(0, 0.3), end: Offset.zero)
                          .animate(anim),
                      child: child)),
              child: Container(
                key: ValueKey(_statusIdx),
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withOpacity(0.12), blurRadius: 14)
                    ]),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  SizedBox(
                    width: 15,
                    height: 15,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: const AlwaysStoppedAnimation<Color>(
                          Color(0xFF0262EC)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(_statusTexts[_statusIdx],
                      style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF0262EC),
                          fontSize: 14)),
                ]),
              ),
            ),
          ]),
        ),
      );

  Widget _ring(Animation<double> a) => AnimatedBuilder(
        animation: a,
        builder: (_, __) => Transform.scale(
          scale: a.value,
          child: Opacity(
              opacity: (1 - a.value).clamp(0.0, 1.0),
              child: Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFF0262EC).withOpacity(0.3)))),
        ),
      );

  // ══════════════ ACCEPTED PANEL ══════════════
  Widget _acceptedPanel() {
    final l = _assignedLawyer;
    final color = Color(l['color'] as int);

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
              color: Color(0x22000000), blurRadius: 20, offset: Offset(0, -4))
        ],
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        // Handle bar
        Container(
          margin: const EdgeInsets.only(top: 10),
          width: 36,
          height: 4,
          decoration: BoxDecoration(
              color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
        ),
        const SizedBox(height: 16),

        // ── Status header ──
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: _isReassigning
                    ? Colors.orange.withOpacity(0.1)
                    : const Color(0xFFE8F5E9),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                _isReassigning
                    ? Icons.search_outlined
                    : Icons.check_circle_outline,
                color: _isReassigning ? Colors.orange : const Color(0xFF2E7D32),
                size: 18,
              ),
            ),
            const SizedBox(width: 10),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(
                _isReassigning ? 'กำลังหาทนายใหม่...' : 'ทนายรับเคสของคุณแล้ว!',
                style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: Color(0xFF1A2340)),
              ),
              Text(
                _isReassigning ? 'โปรดรอสักครู่' : 'กำลังเตรียมตัวเพื่อช่วยคุณ',
                style: TextStyle(color: Colors.grey[400], fontSize: 12),
              ),
            ]),
            const Spacer(),
            if (!_isReassigning)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                    color: const Color(0xFFF0F7FF),
                    borderRadius: BorderRadius.circular(10)),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.schedule_outlined,
                      size: 13, color: Color(0xFF0262EC)),
                  const SizedBox(width: 4),
                  Text(l['eta'] as String,
                      style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF0262EC),
                          fontWeight: FontWeight.w700)),
                ]),
              ),
          ]),
        ),

        const SizedBox(height: 16),
        const Divider(
            height: 1, indent: 20, endIndent: 20, color: Color(0xFFEEF2F5)),
        const SizedBox(height: 16),

        // ── Lawyer card — swaps on reassign ──
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 400),
          transitionBuilder: (child, anim) => FadeTransition(
            opacity: anim,
            child: SlideTransition(
              position:
                  Tween<Offset>(begin: const Offset(0, 0.15), end: Offset.zero)
                      .animate(anim),
              child: child,
            ),
          ),
          child: _isReassigning
              ? Padding(
                  key: const ValueKey('__searching__'),
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Container(
                    height: 110,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                          color: Colors.orange.withOpacity(0.25), width: 1.5),
                    ),
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      const SizedBox(
                        width: 28,
                        height: 28,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.orange),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text('กำลังส่งคำขอไปยังทนายคนอื่น...',
                          style: TextStyle(
                              color: Colors.orange[700],
                              fontSize: 13,
                              fontWeight: FontWeight.w600)),
                    ]),
                  ),
                )
              : _lawyerCardPanel(l, color),
        ),

        const SizedBox(height: 20),

        // ── Action buttons ──
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(children: [
            Expanded(
              child: GestureDetector(
                onTap: _isReassigning ? null : _onReassign,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  height: 50,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: _isReassigning
                        ? Colors.grey[100]
                        : const Color(0xFFFFEBEE),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text('เปลี่ยนทนาย',
                      style: TextStyle(
                          color: _isReassigning
                              ? Colors.grey[400]
                              : const Color(0xFFC62828),
                          fontWeight: FontWeight.w700,
                          fontSize: 13)),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: GestureDetector(
                onTap: _isReassigning
                    ? null
                    : () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) =>
                                ConsultDetailPage(lawyer: _assignedLawyer))),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  height: 50,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    gradient: _isReassigning
                        ? null
                        : const LinearGradient(
                            colors: [Color(0xFF0262EC), Color(0xFF0485FF)]),
                    color: _isReassigning ? Colors.grey[200] : null,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text('ยืนยันทนายนี้',
                      style: TextStyle(
                          color:
                              _isReassigning ? Colors.grey[400] : Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 14)),
                ),
              ),
            ),
          ]),
        ),
        const SizedBox(height: 28),
      ]),
    );
  }

  Widget _lawyerCardPanel(Map<String, dynamic> l, Color color) {
    return Padding(
      key: ValueKey(l['name']),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.04),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: color.withOpacity(0.2), width: 1.5),
        ),
        child: Row(children: [
          Stack(children: [
            (l['imageUrl'] ?? "") != ""
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(30),
                    child: Image.asset(
                      l['imageUrl'],
                      width: 60,
                      height: 60,
                      fit: BoxFit.cover,
                    ),
                  )
                : CircleAvatar(
                    radius: 30,
                    backgroundColor: color.withOpacity(0.12),
                    child: Text(l['avatar'] as String,
                        style: TextStyle(
                            color: color,
                            fontWeight: FontWeight.bold,
                            fontSize: 24)),
                  ),
            Positioned(
              right: 1,
              bottom: 1,
              child: Container(
                width: 13,
                height: 13,
                decoration: BoxDecoration(
                  color: const Color(0xFF43A047),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
              ),
            ),
          ]),
          const SizedBox(width: 14),
          Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(l['name'] as String,
                  style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      color: Color(0xFF1A2340))),
              const SizedBox(height: 2),
              Text(l['title'] as String,
                  style: TextStyle(color: Colors.grey[400], fontSize: 12)),
              const SizedBox(height: 6),
              Row(children: [
                const Icon(Icons.star_rounded,
                    color: Color(0xFFFFC107), size: 14),
                const SizedBox(width: 3),
                Text('${l['rating']}',
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 13)),
                Text(' · ${l['experience']}',
                    style: TextStyle(color: Colors.grey[400], fontSize: 12)),
              ]),
              const SizedBox(height: 4),
              Row(children: [
                Icon(Icons.near_me_outlined, size: 12, color: color),
                const SizedBox(width: 4),
                Text(l['distance'] as String,
                    style: TextStyle(color: Colors.grey[500], fontSize: 12)),
              ]),
            ]),
          ),
          Column(children: [
            _iconBtn(Icons.call_outlined, color, () {}),
            const SizedBox(height: 8),
            _iconBtn(Icons.chat_bubble_outline, color, () {}),
          ]),
        ]),
      ),
    );
  }

  Widget _iconBtn(IconData icon, Color color, VoidCallback onTap) =>
      GestureDetector(
        onTap: onTap,
        child: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 18),
        ),
      );

  // ══════════════ LIST VIEW (tab 2) ══════════════
  Widget _listView() => ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
        itemCount: _lawyers.length,
        itemBuilder: (_, i) => _lawyerCard(_lawyers[i]),
      );

  Widget _lawyerCard(Map<String, dynamic> l) {
    final color = Color(l['color'] as int);
    return GestureDetector(
      onTap: () => Navigator.push(context,
          MaterialPageRoute(builder: (_) => ConsultDetailPage(lawyer: l))),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2))
            ]),
        child: Column(children: [
          Row(children: [
            (l['imageUrl'] ?? "") != ""
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
                    backgroundColor: color.withOpacity(0.12),
                    child: Text(l['avatar'] as String,
                        style: TextStyle(
                            color: color,
                            fontWeight: FontWeight.bold,
                            fontSize: 24)),
                  ),
            const SizedBox(width: 14),
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Row(children: [
                    Expanded(
                        child: Text(l['name'] as String,
                            style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                                color: Color(0xFF1A2340)))),
                    _badge(l['available'] as bool),
                  ]),
                  const SizedBox(height: 2),
                  Text(l['title'] as String,
                      style: TextStyle(color: Colors.grey[400], fontSize: 12)),
                  const SizedBox(height: 4),
                  Row(children: [
                    const Icon(Icons.star_rounded,
                        color: Color(0xFFFFC107), size: 14),
                    const SizedBox(width: 2),
                    Text('${l['rating']}',
                        style: const TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 12)),
                    Text(' (${l['reviews']} รีวิว)',
                        style:
                            TextStyle(color: Colors.grey[400], fontSize: 12)),
                  ]),
                ])),
          ]),
          const SizedBox(height: 12),
          const Divider(height: 1, color: Color(0xFFEEF2F5)),
          const SizedBox(height: 12),
          Row(children: [
            _chip(Icons.gavel_outlined, l['specialty'] as String),
            const SizedBox(width: 8),
            _chip(Icons.history_outlined, l['experience'] as String),
          ]),
          const SizedBox(height: 8),
          Row(children: [
            _chip(Icons.location_on_outlined, l['distance'] as String),
            const SizedBox(width: 8),
            _chip(Icons.business_outlined, l['office'] as String),
          ]),
          const SizedBox(height: 12),
          Row(children: [
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                gradient: l['available'] as bool
                    ? const LinearGradient(
                        colors: [Color(0xFF0262EC), Color(0xFF0485FF)])
                    : null,
                color: l['available'] as bool ? null : Colors.grey[200],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text('นัดหมาย',
                  style: TextStyle(
                      color: l['available'] as bool
                          ? Colors.white
                          : Colors.grey[400],
                      fontWeight: FontWeight.w700,
                      fontSize: 13)),
            ),
          ]),
        ]),
      ),
    );
  }

  Widget _badge(bool ok) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: ok ? const Color(0xFFE8F5E9) : const Color(0xFFFFEBEE),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(ok ? 'ว่างอยู่' : 'ไม่ว่าง',
            style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: ok ? const Color(0xFF2E7D32) : const Color(0xFFC62828))),
      );

  Widget _chip(IconData icon, String label) => Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
              color: const Color(0xFFEEF2F5),
              borderRadius: BorderRadius.circular(8)),
          child: Row(children: [
            Icon(icon, size: 13, color: const Color(0xFF0262EC)),
            const SizedBox(width: 6),
            Expanded(
                child: Text(label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 11, color: Color(0xFF1A2340)))),
          ]),
        ),
      );
}
