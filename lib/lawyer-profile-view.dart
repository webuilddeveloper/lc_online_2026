import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:LawyerOnline/models/user_profile_store.dart';
import 'package:LawyerOnline/models/lawyer/lawyer_profile_store.dart';
import 'package:LawyerOnline/lawyer-edit-profile.dart';
import 'package:LawyerOnline/widgets/profile/lawyer/lawyer_profile_widgets.dart';

// ══════════════════════════════════════════════════════════
//  LawyerProfileViewPage
//  หน้าดูโปรไฟล์ตัวเองของทนาย (style เหมือน LawyerOnlineDetails)
//  - มีปุ่ม "แก้ไขโปรไฟล์" พร้อมข้อความที่ AppBar ด้านบนขวาแทนปุ่ม Favorite
//  - แสดงคะแนนรีวิวตลอดเวลา (ถ้ายังไม่มีคะแนนหรือเป็น 0.0 จะขึ้น 5.0 เป็นค่าเริ่มต้น)
// ══════════════════════════════════════════════════════════

class LawyerProfileViewPage extends StatefulWidget {
  const LawyerProfileViewPage({super.key});

  @override
  State<LawyerProfileViewPage> createState() => _LawyerProfileViewPageState();
}

class _LawyerProfileViewPageState extends State<LawyerProfileViewPage>
    with TickerProviderStateMixin {
  late AnimationController _entryCtrl;
  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;

  Color get _lawyerColor {
    final r = LawyerProfileStore.instance.rating;
    // ถ้าไม่มีเรตติ้ง (เป็น 0.0) ให้ใช้สีเริ่มต้นที่เหมาะสม หรือจะอิงตามเกรดเฉลี่ยสูงสุดก็ได้
    final displayRating = r == 0.0 ? 5.0 : r;
    if (displayRating >= 4.8) return const Color(0xFF1565C0);
    if (displayRating >= 4.0) return const Color(0xFF02A8D1);
    if (displayRating >= 3.0) return const Color(0xFFFDD835);
    if (displayRating >= 2.0) return const Color(0xFFEF6C00);
    return const Color(0xFF0262EC);
  }

  @override
  void initState() {
    super.initState();
    _entryCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 1.0, end: 1.06).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );
    UserProfileStore.instance.addListener(_refresh);
    LawyerProfileStore.instance.addListener(_refresh);
  }

  @override
  void dispose() {
    _entryCtrl.dispose();
    _pulseCtrl.dispose();
    UserProfileStore.instance.removeListener(_refresh);
    LawyerProfileStore.instance.removeListener(_refresh);
    super.dispose();
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final color = _lawyerColor;
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);

    return Scaffold(
      backgroundColor: const Color(0xFFF2F6FF),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          '',
          style: TextStyle(fontSize: 16, color: Colors.white),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: GestureDetector(
          onTap: () => Navigator.pop(context), // หรือใส่เป็นฟังก์ชันกลับหน้าก่อนหน้าของคุณ
          child: Container(
            margin: const EdgeInsets.fromLTRB(15, 8, 0, 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(50),
              border: Border.all(color: Colors.white.withOpacity(0.3)),
            ),
            child: const Icon(Icons.chevron_left_rounded,
                color: Colors.white, size: 24),
          ),
        ),
        actions: [
          // ปุ่มแก้ไขโปรไฟล์พร้อมข้อความ
          Container(
            margin: const EdgeInsets.fromLTRB(0, 8, 15, 8),
            child: GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const LawyerEditProfilePage()),
              ),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    width: 1,
                    color: Colors.white.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.edit_rounded,
                      size: 14,
                      color: Colors.white,
                    ),
                    // const SizedBox(width: 4),
                    // const Text(
                    //   '',
                    //   style: TextStyle(
                    //     color: Colors.white,
                    //     fontSize: 12,
                    //     fontWeight: FontWeight.w600,
                    //   ),
                    // ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Column(
              children: [
                _buildHeroHeader(color),
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                      child: Column(
                        children: [
                          _buildStatsRow(color),
                          const SizedBox(height: 14),
                          _buildSkillsCard(color),
                          const SizedBox(height: 14),
                          _buildBioCard(color),
                          const SizedBox(height: 14),
                          _buildSocialCard(color),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ════════════════════════════════════════════════════════
  //  Hero Header
  // ════════════════════════════════════════════════════════

  Widget _buildHeroHeader(Color color) {
    final store = UserProfileStore.instance;
    final ls = LawyerProfileStore.instance;
    final topPadding = MediaQuery.of(context).padding.top;
    final heroH = 220.0 + topPadding;

    return AnimatedBuilder(
      animation: _entryCtrl,
      builder: (_, child) => Opacity(
        opacity: Curves.easeOut.transform(_entryCtrl.value),
        child: child,
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            height: heroH,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  color,
                  color.withOpacity(0.75),
                  const Color(0xFFF2F6FF),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: const [0.0, 0.6, 1.0],
              ),
            ),
            child: Stack(children: [
              Positioned(
                right: -5,
                top: 35,
                child: Icon(Icons.gavel_rounded,
                    color: Colors.white.withOpacity(0.08), size: 150),
              ),
            ]),
          ),
          Positioned(
            top: topPadding + kToolbarHeight + 8,
            left: 20,
            right: 20,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Avatar
                Column(children: [
                  ScaleTransition(
                    scale: _pulseAnim,
                    child: Stack(children: [
                      Container(
                        width: 106,
                        height: 106,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.28),
                        ),
                      ),
                      Positioned(
                        top: 5,
                        left: 5,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(43),
                          child: SizedBox(
                            width: 96,
                            height: 96,
                            child: store.imageUrl.isNotEmpty &&
                                    store.imageUrl.startsWith('http')
                                ? Image.network(store.imageUrl,
                                    fit: BoxFit.cover)
                                : Image.asset('assets/icons/profile.png',
                                    fit: BoxFit.cover),
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 7,
                        right: 7,
                        child: Container(
                          width: 16,
                          height: 16,
                          decoration: BoxDecoration(
                            color: ls.isAvailable
                                ? const Color(0xFF34C759)
                                : const Color(0xFFCCCCCC),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2.5),
                          ),
                        ),
                      ),
                    ]),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.88),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.verified_rounded, size: 11, color: color),
                      const SizedBox(width: 3),
                      Text('ยืนยันแล้ว',
                          style: TextStyle(
                              fontSize: 9,
                              color: color,
                              fontWeight: FontWeight.w700)),
                    ]),
                  ),
                ]),
                const SizedBox(width: 16),
                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(store.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.4,
                            shadows: [
                              Shadow(
                                  color: Colors.black26,
                                  blurRadius: 8,
                                  offset: Offset(0, 2))
                            ],
                          )),
                      const SizedBox(height: 3),
                      Text(
                        ls.title.isEmpty ? 'ทนายความ' : ls.title,
                        style: TextStyle(
                            color: Colors.white.withOpacity(0.85),
                            fontSize: 12,
                            fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 10),
                      // กล่องแสดงเรตติ้ง (ถ้าคะแนนเป็น 0.0 จะแสดงเป็น 5.0 ทันที)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: Colors.white.withOpacity(0.4)),
                        ),
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          const Icon(Icons.star_rounded,
                              color: Color(0xFFFFC107), size: 14),
                          const SizedBox(width: 4),
                          Text(
                            ls.rating == 0.0 ? '5.0' : '${ls.rating}',
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                fontSize: 13),
                          ),
                          Text(' / 5.0',
                              style: TextStyle(
                                  color: Colors.white.withOpacity(0.65),
                                  fontSize: 11)),
                        ]),
                      ),
                      const SizedBox(height: 10),
                      Wrap(spacing: 6, runSpacing: 6, children: [
                        if (ls.experience.isNotEmpty)
                          _heroBadge(Icons.work_history_rounded,
                              '${ls.experience} ปี'),
                        if (ls.isUrgentCaseEnabled)
                          _heroBadge(Icons.flash_on_rounded, 'รับคดีด่วน'),
                      ]),
                    ],
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: heroH),
        ],
      ),
    );
  }

  Widget _heroBadge(IconData icon, String label) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.18),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 10, color: Colors.white.withOpacity(0.9)),
          const SizedBox(width: 4),
          Text(label,
              style: TextStyle(
                  fontSize: 10,
                  color: Colors.white.withOpacity(0.9),
                  fontWeight: FontWeight.w600)),
        ]),
      );

  // ════════════════════════════════════════════════════════
  //  Stats Row
  // ════════════════════════════════════════════════════════

  Widget _buildStatsRow(Color color) {
    final ls = LawyerProfileStore.instance;
    return ProfileAnimCard(
      delay: 0.1,
      ctrl: _entryCtrl,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: _cardDecor(),
        child: Row(children: [
          _statItem('🏆', ls.casesWon.isEmpty ? '-' : ls.casesWon, 'คดีชนะ'),
          _vertDiv(),
          _statItem('📅', ls.experience.isEmpty ? '-' : '${ls.experience} ปี',
              'ประสบการณ์'),
          _vertDiv(),
          _statItem(
              '⭐', ls.clientReviews.isEmpty ? '-' : ls.clientReviews, 'รีวิว'),
        ]),
      ),
    );
  }

  Widget _statItem(String emoji, String value, String label) => Expanded(
        child: Column(children: [
          Text(emoji, style: const TextStyle(fontSize: 22)),
          const SizedBox(height: 4),
          Text(value,
              style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                  color: Color(0xFF1A2340))),
          const SizedBox(height: 2),
          Text(label,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 10, color: Colors.grey[500])),
        ]),
      );

  Widget _vertDiv() =>
      Container(width: 1, height: 44, color: const Color(0xFFEEF2F5));

  // ════════════════════════════════════════════════════════
  //  Skills Card
  // ════════════════════════════════════════════════════════

  Widget _buildSkillsCard(Color color) {
    final skills = LawyerProfileStore.instance.skills;
    if (skills.isEmpty) return const SizedBox.shrink();

    return ProfileAnimCard(
      delay: 0.2,
      ctrl: _entryCtrl,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: _cardDecor(),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _sectionTitle(Icons.gavel_rounded, 'ความเชี่ยวชาญ', color),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: skills
                .map((s) => SkillViewChip(skill: s, color: color))
                .toList(),
          ),
        ]),
      ),
    );
  }

  // ════════════════════════════════════════════════════════
  //  Bio Card
  // ════════════════════════════════════════════════════════

  Widget _buildBioCard(Color color) {
    final bio = LawyerProfileStore.instance.bio;
    if (bio.isEmpty) return const SizedBox.shrink();

    return ProfileAnimCard(
      delay: 0.28,
      ctrl: _entryCtrl,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: _cardDecor(),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _sectionTitle(Icons.person_outline_rounded, 'แนะนำตัว', color),
          const SizedBox(height: 12),
          Text(bio,
              style: const TextStyle(
                  fontSize: 13, color: Color(0xFF4A5568), height: 1.6)),
        ]),
      ),
    );
  }

  // ════════════════════════════════════════════════════════
  //  Social Card
  // ════════════════════════════════════════════════════════

  Widget _buildSocialCard(Color color) {
    final ls = LawyerProfileStore.instance;
    final socials = <Map<String, String>>[
      if (ls.facebook.isNotEmpty)
        {'icon': 'assets/icons/facebook.png', 'label': 'Facebook'},
      if (ls.instagram.isNotEmpty)
        {'icon': 'assets/icons/ig.png', 'label': 'Instagram'},
      if (ls.twitter.isNotEmpty) {'icon': 'assets/icons/x.png', 'label': 'X'},
      if (ls.linkedin.isNotEmpty)
        {'icon': 'assets/icons/linkin.png', 'label': 'LinkedIn'},
    ];
    if (socials.isEmpty) return const SizedBox.shrink();

    return ProfileAnimCard(
      delay: 0.35,
      ctrl: _entryCtrl,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: _cardDecor(),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _sectionTitle(Icons.public_rounded, 'โซเชียลมีเดีย', color),
          const SizedBox(height: 14),
          Row(
            children: socials.map((s) {
              return Container(
                margin: const EdgeInsets.only(right: 12),
                width: 46,
                height: 46,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFDBDBDB)),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 6,
                        offset: const Offset(0, 2)),
                  ],
                ),
                child: Image.asset(s['icon']!, width: 20, height: 20),
              );
            }).toList(),
          ),
        ]),
      ),
    );
  }

  // ════════════════════════════════════════════════════════
  //  Helpers
  // ════════════════════════════════════════════════════════

  BoxDecoration _cardDecor() => BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 12,
              offset: const Offset(0, 3)),
        ],
      );

  Widget _sectionTitle(IconData icon, String title, Color color) =>
      Row(children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [color, color.withOpacity(0.7)]),
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                  color: color.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2))
            ],
          ),
          child: Icon(icon, size: 16, color: Colors.white),
        ),
        const SizedBox(width: 10),
        Text(title,
            style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1A2340),
                letterSpacing: -0.2)),
      ]);
}