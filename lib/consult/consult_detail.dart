import 'dart:io';
import 'package:LawyerOnline/consult/consult_payment.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:LawyerOnline/chat/chat_page_user.dart';
import 'package:LawyerOnline/shared/responsive/app_layout.dart';

class ConsultDetailPage extends StatefulWidget {
  final Map<String, dynamic> lawyer;

  // ── field ชุดใหม่ที่ตกลงกัน ──────────────────────────────────────────────
  final String topic;
  final String topicTitle;
  final String subTopic;
  final String subTopicTitle;
  final String province;
  final String detail;
  final String demand;
  final List<File> images;
  final int caseType; // 1=นัดล่วงหน้า, 2=ด่วน

  const ConsultDetailPage({
    super.key,
    required this.lawyer,
    required this.topic,
    required this.topicTitle,
    required this.subTopic,
    required this.subTopicTitle,
    required this.province,
    required this.detail,
    required this.demand,
    required this.images,
    this.caseType = 1,
  });

  @override
  State<ConsultDetailPage> createState() => _ConsultDetailPageState();
}

class _ConsultDetailPageState extends State<ConsultDetailPage>
    with TickerProviderStateMixin {
  bool isFavorite = false;
  late AnimationController _entryCtrl;
  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;

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
  }

  @override
  void dispose() {
    _entryCtrl.dispose();
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lawyerColor = widget.lawyer['rating'] == 5
        ? const Color(0xFF1565C0)
        : widget.lawyer['rating'] >= 4
            ? const Color(0xFF02A8D1)
            : widget.lawyer['rating'] >= 3
                ? const Color(0xFFFDD835)
                : widget.lawyer['rating'] >= 2
                    ? const Color(0xFFEF6C00)
                    : const Color(0xFFD32F2F);

    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);

    return Scaffold(
      backgroundColor: const Color(0xFFF2F6FF),
      extendBodyBehindAppBar: true,
      body: AppLayout(
        child: SizedBox(
          height: MediaQuery.of(context).size.height,
          child: Column(
            children: [
              _buildHeroHeader(lawyerColor),
              Expanded(
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(24),
                      topRight: Radius.circular(24),
                    ),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black12,
                          blurRadius: 10,
                          offset: Offset(0, -4))
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(24),
                      topRight: Radius.circular(24),
                    ),
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 24, 16, 32),
                        child: Column(
                          children: [
                            _buildStatsRow(),
                            const SizedBox(height: 14),
                            _buildSpecialtyCard(lawyerColor),
                            const SizedBox(height: 14),
                            _buildSocialCard(lawyerColor),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              _buildBookingButton(lawyerColor),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeroHeader(Color color) {
    final topPadding = MediaQuery.of(context).padding.top;
    const appBarH = kToolbarHeight;
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
            top: topPadding + 8,
            left: 0,
            right: 0,
            child: SizedBox(
              height: 40,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  const Text('รายละเอียดหมอความ',
                      style: TextStyle(
                          fontSize: 16,
                          color: Colors.white,
                          fontWeight: FontWeight.w600)),
                  Positioned(
                    left: 15,
                    child: GestureDetector(
                      onTap: () => Navigator.pop(context, false),
                      child: Container(
                        width: 40,
                        height: 40,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          shape: BoxShape.circle,
                          border:
                              Border.all(color: Colors.white.withOpacity(0.3)),
                        ),
                        child: const Icon(Icons.chevron_left_rounded,
                            color: Colors.white, size: 24),
                      ),
                    ),
                  ),
                  Positioned(
                    right: 15,
                    child: GestureDetector(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        setState(() => isFavorite = !isFavorite);
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
                            color: isFavorite
                                ? Colors.red
                                : const Color(0xFFDBDBDB),
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
                            color: isFavorite
                                ? Colors.red
                                : const Color(0xFFDBDBDB),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            top: topPadding + appBarH + 8,
            left: 20,
            right: 20,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
                            child: widget.lawyer['imageUrl'] != null
                                ? Image.network(
                                    widget.lawyer['imageUrl'] as String,
                                    fit: BoxFit.cover,
                                  )
                                : Center(
                                    child: Text(
                                      (widget.lawyer['name'] as String? ?? 'A')
                                          .substring(0, 1),
                                      style: const TextStyle(
                                          fontSize: 38,
                                          color: Colors.white,
                                          fontWeight: FontWeight.w800),
                                    ),
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
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.lawyer['name'] as String? ?? '',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        widget.lawyer['title'] as String? ?? '',
                        style: TextStyle(
                            color: Colors.white.withOpacity(0.8), fontSize: 12),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 10),
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
                          Text('${widget.lawyer['rating']}',
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

  Widget _buildStatsRow() {
    return _AnimatedCard(
      delay: 0.1,
      controller: _entryCtrl,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: _cardDecor(),
        child: Row(children: [
          _statItem('🏆', '148+', 'คดีชนะ'),
          _vertDiv(),
          _statItem('📅', widget.lawyer['experience'] as String? ?? '-',
              'ประสบการณ์'),
          _vertDiv(),
          _statItem('⭐', '${widget.lawyer['reviews']}+', 'รีวิว'),
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

  Widget _buildSpecialtyCard(Color color) {
    final specialties = (widget.lawyer['specialty'] as String? ?? '')
        .split(', ')
      ..removeWhere((s) => s.trim().isEmpty);
    return _AnimatedCard(
      delay: 0.2,
      controller: _entryCtrl,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: _cardDecor(),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _sectionTitle(Icons.gavel_rounded, 'ความเชี่ยวชาญ', color),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: specialties
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

  Widget _buildSocialCard(Color color) {
    final socials = [
      {'icon': 'assets/icons/facebook.png', 'url': 'https://www.facebook.com/'},
      {'icon': 'assets/icons/ig.png', 'url': 'https://www.instagram.com/'},
      {'icon': 'assets/icons/x.png', 'url': 'https://x.com/'},
      {'icon': 'assets/icons/linkin.png', 'url': 'https://www.linkedin.com/'},
    ];
    return _AnimatedCard(
      delay: 0.35,
      controller: _entryCtrl,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: _cardDecor(),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _sectionTitle(Icons.public_rounded, 'โซเชียลมีเดีย', color),
          const SizedBox(height: 14),
          Row(
            children: socials
                .map((s) => Container(
                      margin: const EdgeInsets.only(right: 15),
                      child: GestureDetector(
                        onTap: () {
                          HapticFeedback.lightImpact();
                          launch(s['url'] as String);
                        },
                        child: Container(
                          width: 42,
                          height: 42,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16.8),
                            border: Border.all(
                                width: 1, color: const Color(0xFFDBDBDB)),
                          ),
                          child: Image.asset(s['icon'] as String,
                              width: 18, height: 18),
                        ),
                      ),
                    ))
                .toList(),
          ),
        ]),
      ),
    );
  }

  // ── Booking Button → ConsultQrPage (ส่ง field ชุดใหม่ครบ) ─────────────────
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
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ConsultQrPage(
                amount: 500,
                lawyer: widget.lawyer,
                // ── field ชุดใหม่ครบ ──
                topic: widget.topic,
                topicTitle: widget.topicTitle,
                subTopic: widget.subTopic,
                subTopicTitle: widget.subTopicTitle,
                province: widget.province,
                detail: widget.detail,
                demand: widget.demand,
                caseType: widget.caseType,
                // ไม่มี requestCode = direct flow (นัดล่วงหน้า)
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
                offset: const Offset(0, 5),
              ),
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
                child: const Icon(Icons.payment_rounded,
                    color: Colors.white, size: 16),
              ),
              const SizedBox(width: 10),
              const Text('ยืนยันและชำระเงิน',
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 16)),
            ],
          ),
        ),
      ),
    );
  }

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
          ),
          child: Icon(icon, size: 16, color: Colors.white),
        ),
        const SizedBox(width: 10),
        Text(title,
            style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1A2340))),
      ]);
}

class _AnimatedCard extends StatelessWidget {
  final double delay;
  final AnimationController controller;
  final Widget child;

  const _AnimatedCard({
    required this.delay,
    required this.controller,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (_, ch) {
        final t = Curves.easeOutCubic.transform(
          ((controller.value - delay) / (1 - delay)).clamp(0.0, 1.0),
        );
        return Opacity(
          opacity: t,
          child: Transform.translate(
              offset: Offset(0, 20 * (1 - t)), child: ch),
        );
      },
      child: child,
    );
  }
}