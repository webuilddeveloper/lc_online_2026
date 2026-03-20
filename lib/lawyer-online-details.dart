import 'package:LawyerOnline/add-appointment.dart';
import 'package:LawyerOnline/component/appbar.dart';
import 'package:LawyerOnline/message-form.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lottie/lottie.dart';
import 'package:url_launcher/url_launcher.dart';

class LawyerOnlineDetails extends StatefulWidget {
  LawyerOnlineDetails({Key? key, this.code, this.topic, this.subTopic}) : super(key: key);
  final String? code;
  String? topic;
  String? subTopic;

  @override
  State<LawyerOnlineDetails> createState() => _LawyerOnlineDetailsState();
}

class _LawyerOnlineDetailsState extends State<LawyerOnlineDetails>
    with TickerProviderStateMixin {
  // ── Animations (visual ใหม่) ────────────────────────────
  late AnimationController _entryCtrl;
  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;

  // ── Data (เหมือนเดิม) ────────────────────────────────────
  List<Map<String, dynamic>> lawyerOnlineList = [
    {
      "code": "0",
      "name": "ศักดิ์สิทธิ์ พิพากษ์",
      'title': 'ทนายความอาวุโส',
      "scroll": 4.8,
      "cost": "Free",
      "costUnit": "/hr",
      "imageUrl": "assets/images/lawyer-avatar-1.png",
      "experience": "11+ years",
      "clientReviews": "60+",
      "casesWon": "148+",
      "price": 500,
      "skills": ["อาญาและอาชญากรรม", "ครอบครัวและมรดก"],
    },
    {
      "code": "1",
      "name": "ธนากร นิติศักดิ์",
      'title': 'ทนายความอาวุโส',
      "scroll": 4.1,
      "cost": "Free",
      "costUnit": "/hr",
      "imageUrl": "assets/images/lawyer-avatar-2.png",
      "experience": "19+ years",
      "clientReviews": "60+",
      "casesWon": "148+",
      "price": 500,
      "skills": ["หนี้สินและการเงิน", "ธุรกิจและบริษัท"],
    },
    {
      "code": "2",
      "name": "พงษ์ภพ ยุติธรรม",
      'title': 'ทนายความอาวุโส',
      "scroll": 3.9,
      "cost": "Free",
      "costUnit": "/hr",
      "imageUrl": "assets/images/lawyer-avatar-3.png",
      "experience": "10+ years",
      "clientReviews": "60+",
      "casesWon": "148+",
      "price": 500,
      "skills": ["แรงงานและการจ้างงาน", "ประกันภัยและผู้บริโภค"],
    },
    {
      "code": "3",
      "name": "อาริย์ ศิษย์กฎหมาย",
      'title': 'ทนายความอาวุโส',
      "scroll": 3.0,
      "cost": "200",
      "costUnit": "/hr",
      "imageUrl": "assets/images/lawyer-avatar-4.png",
      "experience": "12+ years",
      "clientReviews": "60+",
      "casesWon": "148+",
      "price": 500,
      "skills": ["ทรัพย์สินและที่ดิน", "ฟ้องศาล เรียกค่าเสียหาย"],
    },
    {
      "code": "4",
      "name": "Sachin K",
      'title': 'ทนายความอาวุโส',
      "scroll": 4.9,
      "cost": "1000",
      "costUnit": "/hr",
      "imageUrl": "assets/images/lawyer-avatar-5.png",
      "experience": "20+ years",
      "clientReviews": "60+",
      "casesWon": "148+",
      "price": 500,
      "skills": ["คดีออนไลน์และเทคโนโลยี", "อื่นๆและระหว่างประเทศ"],
    },
  ];

  dynamic model = {};
  String code = "";
  bool isFavorite = false;

  // ── สีตาม rating (เหมือน LawyerDetailPage) ──────────────
  Color get _lawyerColor {
    final r = (model['scroll'] ?? 0) as num;
    if (r >= 4.8) return const Color(0xFF1565C0);
    if (r >= 4.0) return const Color(0xFF02A8D1);
    if (r >= 3.0) return const Color(0xFFFDD835);
    if (r >= 2.0) return const Color(0xFFEF6C00);
    return const Color(0xFFD32F2F);
  }

  @override
  void initState() {
    super.initState();
    callRead(); // logic เดิม

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
  }

  @override
  void dispose() {
    _entryCtrl.dispose();
    _pulseCtrl.dispose();
    super.dispose();
  }

  // ── Logic เดิมทุกอย่าง ──────────────────────────────────
  void callRead() {
    code = widget.code ?? "0";
    final result = lawyerOnlineList.where((x) => x['code'] == code);
    model = result.isNotEmpty ? result.first : lawyerOnlineList.first;
  }

  void goBack(value) async {
    Navigator.pop(context, value);
  }

  // ════════════════════════════════════════════════════════
  //  Build
  // ════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    final color = _lawyerColor;
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);

    return Scaffold(
      backgroundColor: const Color(0xFFF2F6FF),
      extendBodyBehindAppBar: true,
      // ── AppBar โปร่งใส (เหมือน LawyerDetailPage) ────────
      appBar: AppBar(
        title: const Text(
          'รายละเอียดหมอความ',
          style: TextStyle(fontSize: 16, color: Colors.white),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: GestureDetector(
          onTap: () => goBack(false), // action เดิม
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
          Container(
            margin: const EdgeInsets.fromLTRB(0, 8, 15, 8),
            child: GestureDetector(
              onTap: () {
                // action เดิม
                setState(() {
                  isFavorite = !isFavorite;
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                  border: Border.all(
                    width: 1,
                    color: isFavorite ? Colors.red : const Color(0xFFDBDBDB),
                  ),
                ),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  transitionBuilder: (child, animation) =>
                      ScaleTransition(scale: animation, child: child),
                  child: Icon(
                    isFavorite ? Icons.favorite : Icons.favorite_border,
                    key: ValueKey(isFavorite),
                    size: 18,
                    color: isFavorite ? Colors.red : const Color(0xFFDBDBDB),
                  ),
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
                // ── Hero Header ──────────────────────────
                _buildHeroHeader(color),
                // ── Scrollable content ───────────────────
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
                          // _buildContactCard(color),
                          // const SizedBox(height: 14),
                          _buildSocialCard(color),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // ── Booking Button ───────────────────────────
          _buildBookingButton(color),
        ],
      ),
    );
  }

  // ════════════════════════════════════════════════════════
  //  Hero Header — เหมือน LawyerDetailPage
  // ════════════════════════════════════════════════════════

  Widget _buildHeroHeader(Color color) {
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
          // Gradient bg
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
              Positioned(
                left: -15,
                bottom: 40,
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.05),
                  ),
                ),
              ),
            ]),
          ),
          // Content
          Positioned(
            top: topPadding + kToolbarHeight + 8,
            left: 20,
            right: 20,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Avatar + pulse ring
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
                          child: Container(
                            width: 96,
                            height: 96,
                            color: Colors.white.withOpacity(0.2),
                            child: Image.asset(
                              model['imageUrl'] ?? '',
                              fit: BoxFit.cover,
                            ),
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
                            color: const Color(0xFF34C759),
                            shape: BoxShape.circle,
                            border:
                                Border.all(color: Colors.white, width: 2.5),
                          ),
                        ),
                      ),
                    ]),
                  ),
                  const SizedBox(height: 6),
                  // Verified badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.88),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                            color: color.withOpacity(0.2),
                            blurRadius: 6,
                            offset: const Offset(0, 2))
                      ],
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
                      Text(
                        model['name'] ?? '',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.4,
                          shadows: [
                            Shadow(color: Colors.black26, blurRadius: 8,
                                offset: Offset(0, 2))
                          ],
                        ),
                      ),
                      const SizedBox(height: 3),
                      // cost
                      Text(
                        (model['cost'] ?? '') == 'Free'
                            ? 'ฟรี'
                            : '฿${model['cost']}${model['costUnit'] ?? ''}',
                        style: TextStyle(
                            color: Colors.white.withOpacity(0.85),
                            fontSize: 12,
                            fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 10),
                      // Rating pill
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: Colors.white.withOpacity(0.4)),
                        ),
                        child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                          const Icon(Icons.star_rounded,
                              color: Color(0xFFFFC107), size: 14),
                          const SizedBox(width: 4),
                          Text('${model['scroll'] ?? ''}',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 13)),
                          Text(' / 5.0',
                              style: TextStyle(
                                  color: Colors.white.withOpacity(0.65),
                                  fontSize: 11)),
                        ]),
                      ),
                      const SizedBox(height: 10),
                      Wrap(spacing: 6, runSpacing: 6, children: [
                        _heroBadge(Icons.work_history_rounded,
                            model['experience'] ?? '-'),
                        _heroBadge(Icons.people_outline_rounded,
                            '${model['clientReviews'] ?? ''} รีวิว'),
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
    return _AnimCard(
      delay: 0.1,
      ctrl: _entryCtrl,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: _cardDecor(),
        child: Row(children: [
          _statItem('🏆', model['casesWon'] ?? '-', 'คดีชนะ'),
          _vertDiv(),
          _statItem('📅', model['experience'] ?? '-', 'ประสบการณ์'),
          _vertDiv(),
          _statItem('⭐', model['clientReviews'] ?? '-', 'รีวิว'),
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
  //  Skills Card (About Lawyer เดิม)
  // ════════════════════════════════════════════════════════

  Widget _buildSkillsCard(Color color) {
    final skills = List<String>.from(model['skills'] ?? []);

    return _AnimCard(
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
                .map((s) => Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: [
                          color.withOpacity(0.1),
                          color.withOpacity(0.05),
                        ]),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: color.withOpacity(0.25)),
                      ),
                      child: Text(s,
                          style: TextStyle(
                              fontSize: 12,
                              color: color,
                              fontWeight: FontWeight.w600)),
                    ))
                .toList(),
          ),
        ]),
      ),
    );
  }

  // ════════════════════════════════════════════════════════
  //  Contact Card — action เดิม → MessageFormPage
  // ════════════════════════════════════════════════════════

  Widget _buildContactCard(Color color) {
    return _AnimCard(
      delay: 0.28,
      ctrl: _entryCtrl,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: _cardDecor(),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _sectionTitle(Icons.forum_rounded, 'ติดต่อหมอความ', color),
          const SizedBox(height: 14),
          Row(children: [
            _contactTile(
              iconAsset: 'assets/icons/chat.png',
              label: 'แชท',
              accent: const Color(0xFF0262EC),
              bg: const Color(0xFFEEF4FF),
              onTap: () => Navigator.push(context, MaterialPageRoute(
                builder: (context) => MessageFormPage(model: model), // action เดิม
              )),
            ),
            const SizedBox(width: 10),
            _contactTile(
              iconAsset: 'assets/icons/phone.png',
              label: 'โทร',
              accent: const Color(0xFF34C759),
              bg: const Color(0xFFEEFAF1),
              onTap: () => Navigator.push(context, MaterialPageRoute(
                builder: (context) => MessageFormPage(model: model), // action เดิม
              )),
            ),
            const SizedBox(width: 10),
            _contactTile(
              iconAsset: 'assets/icons/videocall.png',
              label: 'วิดีโอ',
              accent: const Color(0xFFFF6B35),
              bg: const Color(0xFFFFF2EE),
              onTap: () => Navigator.push(context, MaterialPageRoute(
                builder: (context) => MessageFormPage(model: model), // action เดิม
              )),
            ),
          ]),
        ]),
      ),
    );
  }

  Widget _contactTile({
    required String iconAsset,
    required String label,
    required Color accent,
    required Color bg,
    required VoidCallback onTap,
  }) =>
      Expanded(
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: accent.withOpacity(0.2)),
            ),
            child: Column(children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: accent.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Center(
                    child: Image.asset(iconAsset, width: 18, height: 18)),
              ),
              const SizedBox(height: 6),
              Text(label,
                  style: TextStyle(
                      fontSize: 11,
                      color: accent,
                      fontWeight: FontWeight.w700)),
            ]),
          ),
        ),
      );

  // ════════════════════════════════════════════════════════
  //  Social Card — action เดิม → launch URL
  // ════════════════════════════════════════════════════════

  Widget _buildSocialCard(Color color) {
    final socials = [
      {
        'icon': 'assets/icons/facebook.png',
        'label': 'Facebook',
        'url': 'https://www.facebook.com/',
        'color': const Color(0xFF1877F2),
        'bg': const Color(0xFFEEF4FF),
      },
      {
        'icon': 'assets/icons/ig.png',
        'label': 'Instagram',
        'url': 'https://www.instagram.com/',
        'color': const Color(0xFFE1306C),
        'bg': const Color(0xFFFFF0F5),
      },
      {
        'icon': 'assets/icons/x.png',
        'label': 'X',
        'url': 'https://x.com/',
        'color': const Color(0xFF111111),
        'bg': const Color(0xFFF5F5F5),
      },
      {
        'icon': 'assets/icons/linkin.png',
        'label': 'LinkedIn',
        'url': 'https://www.linkedin.com/',
        'color': const Color(0xFF0A66C2),
        'bg': const Color(0xFFEEF5FF),
      },
    ];

    return _AnimCard(
      delay: 0.35,
      ctrl: _entryCtrl,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: _cardDecor(),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _sectionTitle(Icons.public_rounded, 'โซเชียลมีเดีย', color),
          const SizedBox(height: 14),
          Row(
            children: socials.asMap().entries.map((e) {
              final s = e.value;
              final isLast = e.key == socials.length - 1;
              return Container(
                margin: EdgeInsets.only(right: 15),
                width: 50,
                height: 50,
                child: GestureDetector(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    launch(s['url'] as String);
                  },
                  child: Container(
                    width: 42,
                    height: 42,
                    alignment: Alignment.center,
                    // padding: const EdgeInsets.symmetric(
                    //   horizontal: 12,
                    //   vertical: 10,
                    // ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16.8),
                      border: Border.all(
                        width: 1,
                        color: const Color(0xFFDBDBDB),
                      ),
                    ),
                    child: Image.asset(
                      s['icon'] as String,
                      width: 18,
                      height: 18,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ]),
      ),
    );
  }

  // ════════════════════════════════════════════════════════
  //  Booking Button — action เดิม → AppAppointment
  // ════════════════════════════════════════════════════════

  Widget _buildBookingButton(Color color) {
    return Container(
      padding: EdgeInsets.fromLTRB(
          16, 10, 16, MediaQuery.of(context).padding.bottom + 14),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFEEF2F5), width: 1)),
      ),
      child: GestureDetector(
        onTap: () {
          // action เดิม
          // Navigator.push(
          //   context,
          //   MaterialPageRoute(
          //     builder: (context) => AppAppointment(lawyer: model),
          //   ),
          // );
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => AppAppointment(
                lawyer: model,
                topic: widget.topic,
                subTopic: widget.subTopic,
              ),
            ),
          );
        },
        child: Container(
          height: 54,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [color, color.withOpacity(0.8)],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                  color: color.withOpacity(0.4),
                  blurRadius: 16,
                  offset: const Offset(0, 5)),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.calendar_month_rounded,
                    color: Colors.white, size: 16),
              ),
              const SizedBox(width: 10),
              const Text('จองนัดหมาย',
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                      letterSpacing: 0.2)),
            ],
          ),
        ),
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
            gradient:
                LinearGradient(colors: [color, color.withOpacity(0.7)]),
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

  // ── successDialog logic เดิม ────────────────────────────
  successDialog() {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Lottie.asset('assets/lottie/success.json', width: 120),
              const Text('สำเร็จ!',
                  style: TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              const Text('ดำเนินการเรียบร้อยแล้ว',
                  style: TextStyle(color: Colors.grey)),
              const SizedBox(height: 20),
              ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('ปิด')),
            ],
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════
//  _AnimCard — staggered entry (เหมือน LawyerDetailPage)
// ══════════════════════════════════════════════════════════

class _AnimCard extends StatelessWidget {
  final double delay;
  final AnimationController ctrl;
  final Widget child;

  const _AnimCard(
      {required this.delay, required this.ctrl, required this.child});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: ctrl,
      builder: (_, ch) {
        final t = Curves.easeOutCubic.transform(
          ((ctrl.value - delay) / (1 - delay)).clamp(0.0, 1.0),
        );
        return Opacity(
          opacity: t,
          child:
              Transform.translate(offset: Offset(0, 20 * (1 - t)), child: ch),
        );
      },
      child: child,
    );
  }
}