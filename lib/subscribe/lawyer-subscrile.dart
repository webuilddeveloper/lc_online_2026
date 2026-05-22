// ══════════════════════════════════════════════════════════════════════
//  lawyer_subscribe.dart  (v2)
//  - Features เพิ่มครบ + icon ทุกรายการ
//  - UI ยกระดับ: hero, price highlight, savings callout, compare notes
//  - Logic ถูกต้อง: currentPlan จาก store, CTA ทุก state, downgrade dialog
// ══════════════════════════════════════════════════════════════════════

import 'package:LawyerOnline/component/appbar.dart';
import 'package:LawyerOnline/subscribe/checkout.dart';
import 'package:LawyerOnline/subscribe/subscribe_theme.dart';
import 'package:LawyerOnline/models/lawyer/lawyer_profile_store.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SubscribePage extends StatefulWidget {
  const SubscribePage({Key? key}) : super(key: key);

  @override
  State<SubscribePage> createState() => _SubscribePageState();
}

class _SubscribePageState extends State<SubscribePage>
    with SingleTickerProviderStateMixin {
  // ── ดึง current plan จาก store ──────────────────────────────────
  final _store = LawyerProfileStore.instance;
  bool _isYearly = false;
  late String _selectedPlan;

  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;

  // ─── Feature data ───────────────────────────────────────────────
  final List<_Feature> _freeFeatures = const [
    _Feature(
        icon: Icons.gavel_rounded, label: 'รับเคสออนไลน์ทั่วไป', enabled: true),
    _Feature(
        icon: Icons.person_outline_rounded,
        label: 'โปรไฟล์มาตรฐาน',
        enabled: true),
    _Feature(
        icon: Icons.chat_bubble_outline_rounded,
        label: 'แชทกับลูกค้า',
        enabled: true),
    _Feature(
        icon: Icons.star_outline_rounded,
        label: 'รับรีวิวจากลูกค้า',
        enabled: true),
    _Feature(
        icon: Icons.share_outlined,
        label: 'เชื่อม Social Media',
        enabled: false),
    _Feature(
        icon: Icons.price_change_outlined,
        label: 'ตั้งค่าราคาขั้นสูง',
        enabled: false),
    _Feature(
        icon: Icons.schedule_outlined,
        label: 'จัดการตารางรับเคส',
        enabled: false),
    _Feature(
        icon: Icons.trending_up_rounded,
        label: 'ติดอันดับสูงกว่าในผลค้นหา',
        enabled: false),
  ];

  final List<_Feature> _proFeatures = const [
    _Feature(
        icon: Icons.gavel_rounded,
        label: 'รับเคสออนไลน์ทุกประเภท',
        enabled: true),
    _Feature(
        icon: Icons.badge_outlined,
        label: 'โปรไฟล์ขยาย + แบดจ์ Pro',
        enabled: true),
    _Feature(
        icon: Icons.chat_bubble_outline_rounded,
        label: 'แชทกับลูกค้า',
        enabled: true),
    _Feature(
        icon: Icons.star_outline_rounded,
        label: 'รีวิวพร้อมแสดงผลเด่น',
        enabled: true),
    _Feature(
        icon: Icons.share_outlined,
        label: 'Social Media (FB, LINE, IG)',
        enabled: true),
    _Feature(
        icon: Icons.price_change_outlined,
        label: 'ตั้งค่าราคาและเงื่อนไขเอง',
        enabled: true),
    _Feature(
        icon: Icons.schedule_outlined,
        label: 'เปิด/ปิดรับเคสตามช่วงเวลา',
        enabled: true),
    _Feature(
        icon: Icons.trending_up_rounded,
        label: 'ติดอันดับสูงกว่าในผลค้นหา',
        enabled: true),
  ];

  final List<_CompareRow> _compareRows = const [
    _CompareRow(
        label: 'รับเคสออนไลน์',
        free: true,
        pro: true,
        freeNote: 'ทั่วไป',
        proNote: 'ทุกประเภท'),
    _CompareRow(
        label: 'โปรไฟล์',
        free: true,
        pro: true,
        freeNote: 'มาตรฐาน',
        proNote: 'ขยาย+แบดจ์'),
    _CompareRow(label: 'แชทกับลูกค้า', free: true, pro: true),
    _CompareRow(
        label: 'รีวิวจากลูกค้า', free: true, pro: true, proNote: 'แสดงเด่น'),
    _CompareRow(label: 'Social Media', free: false, pro: true),
    _CompareRow(label: 'ตั้งค่าราคาเอง', free: false, pro: true),
    _CompareRow(label: 'จัดการตารางรับเคส', free: false, pro: true),
    _CompareRow(label: 'ติดอันดับสูงกว่า', free: false, pro: true),
    _CompareRow(label: 'ทดลองใช้ฟรี', free: false, pro: true, proNote: '7 วัน'),
  ];

  // ── Lifecycle ────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    // เริ่มต้น selected plan ตาม current plan จริงจาก store
    _selectedPlan = _store.isPro ? 'pro' : 'free';
    _isYearly = _store.billingCycle.isYearly;

    _animCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 450));
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  // ── Computed ─────────────────────────────────────────────────────
  bool get _isCurrentFree => _store.currentPlan == CurrentPlan.free;
  bool get _isCurrentPro => _store.currentPlan == CurrentPlan.pro;

  String get _proPrice => _isYearly ? '฿472' : '฿590';

  /// CTA label ครบทุก state
  String get _ctaLabel {
    if (_selectedPlan == 'free') {
      return _isCurrentFree ? 'แผนปัจจุบันของคุณ' : 'ดาวน์เกรดเป็นฟรี';
    }
    if (_isCurrentPro) return 'แผนปัจจุบันของคุณ';
    return _isYearly
        ? 'เริ่มใช้งาน Pro รายปี — ฟรี 7 วัน'
        : 'เริ่มใช้งาน Pro — ฟรี 7 วัน';
  }

  bool get _ctaEnabled {
    if (_selectedPlan == 'free' && _isCurrentFree) return false;
    if (_selectedPlan == 'pro' && _isCurrentPro) return false;
    return true;
  }

  Color get _ctaBg {
    if (!_ctaEnabled) return kBorder;
    if (_selectedPlan == 'free') return kSurface;
    return kPrimary;
  }

  Color get _ctaTextColor {
    if (!_ctaEnabled) return kSub;
    if (_selectedPlan == 'free') return kText;
    return Colors.white;
  }

  // ══════════════════════════════════════════════════════════════════
  //  BUILD
  // ══════════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kSurface,
      appBar: appBar(
        title: 'Lawyer Pro',
        backBtn: true,
        rightBtn: false,
        backAction: () => Navigator.pop(context, false),
        rightAction: () {},
      ),
      body: FadeTransition(
        opacity: _fadeAnim,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.only(bottom: 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHero(),
              const SizedBox(height: 16),
              _buildBillingToggle(),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(children: [
                  _buildPlanCard(
                    planId: 'free',
                    name: 'ฟรี',
                    price: '฿0',
                    unit: '/เดือน',
                    tagLabel: _isCurrentFree ? 'แผนปัจจุบัน' : 'พื้นฐาน',
                    tagColor: _isCurrentFree ? kPrimaryLight : kSurface,
                    tagTextColor: _isCurrentFree ? kPrimary : kSub,
                    features: _freeFeatures,
                    isFeatured: false,
                  ),
                  const SizedBox(height: 12),
                  _buildPlanCard(
                    planId: 'pro',
                    name: 'Pro',
                    price: _proPrice,
                    unit: '/เดือน',
                    originalPrice: _isYearly ? '฿590' : null,
                    tagLabel: _isCurrentPro ? 'แผนปัจจุบัน' : 'แนะนำ',
                    tagColor: _isCurrentPro ? kGreenLight : kGoldLight,
                    tagTextColor: _isCurrentPro ? kGreen : kGold,
                    features: _proFeatures,
                    isFeatured: true,
                  ),
                ]),
              ),
              const SizedBox(height: 24),
              _buildCompareSection(),
              const SizedBox(height: 24),
              _buildCTA(),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Hero ─────────────────────────────────────────────────────────
  Widget _buildHero() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 4),
      child: Column(children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [kPrimary, kPrimaryDark],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: kPrimary.withOpacity(0.28),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: const Icon(Icons.workspace_premium_rounded,
              color: Colors.white, size: 30),
        ),
        const SizedBox(height: 16),
        Text(
          'ยกระดับการให้บริการด้วย Lawyer Pro',
          textAlign: TextAlign.center,
          style: GoogleFonts.prompt(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: kText,
              height: 1.3),
        ),
        const SizedBox(height: 6),
        Text(
          'ฟีเจอร์ครบครันที่ช่วยให้ทนายมืออาชีพ\nเติบโตและรับเคสได้มากขึ้น',
          textAlign: TextAlign.center,
          style: GoogleFonts.prompt(fontSize: 13, color: kSub, height: 1.6),
        ),
      ]),
    );
  }

  // ─── Billing Toggle ───────────────────────────────────────────────
  Widget _buildBillingToggle() {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: kSurface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: kBorder),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildSegmentTab(
                label: 'รายเดือน',
                selected: !_isYearly,
                onTap: () => setState(() => _isYearly = false)),
            _buildSegmentTab(
                label: 'รายปี',
                selected: _isYearly,
                onTap: () => setState(() => _isYearly = true),
                badge: 'ประหยัด 20%'),
          ],
        ),
      ),
    );
  }

  Widget _buildSegmentTab({
    required String label,
    required bool selected,
    required VoidCallback onTap,
    String? badge,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? kCard : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          boxShadow: selected
              ? [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.07),
                      blurRadius: 8,
                      offset: const Offset(0, 2))
                ]
              : [],
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Text(label,
              style: GoogleFonts.prompt(
                  fontSize: 14,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                  color: selected ? kText : kSub)),
          if (badge != null) ...[
            const SizedBox(width: 6),
            AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: selected ? kGreenLight : Colors.transparent,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: selected
                      ? kGreen.withOpacity(0.3)
                      : kSub.withOpacity(0.25),
                ),
              ),
              child: Text(badge,
                  style: GoogleFonts.prompt(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: selected ? kGreen : kSub)),
            ),
          ],
        ]),
      ),
    );
  }

  // ─── Plan Card ────────────────────────────────────────────────────
  Widget _buildPlanCard({
    required String planId,
    required String name,
    required String price,
    required String unit,
    String? originalPrice,
    required String tagLabel,
    required Color tagColor,
    required Color tagTextColor,
    required List<_Feature> features,
    required bool isFeatured,
  }) {
    final isSelected = _selectedPlan == planId;
    final isCurrent = (planId == 'free' && _isCurrentFree) ||
        (planId == 'pro' && _isCurrentPro);
    final isPro = planId == 'pro';

    return GestureDetector(
      onTap: () => setState(() => _selectedPlan = planId),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        decoration: BoxDecoration(
          color: kCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? kPrimary : kBorder,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                      color: kPrimary.withOpacity(0.10),
                      blurRadius: 18,
                      offset: const Offset(0, 5))
                ]
              : [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 4,
                      offset: const Offset(0, 2))
                ],
        ),
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // ── top row: name + tag ──
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Row(children: [
              Text(name,
                  style: GoogleFonts.prompt(
                      fontSize: 17, fontWeight: FontWeight.w700, color: kText)),
              if (isCurrent) ...[
                const SizedBox(width: 6),
                const Icon(Icons.check_circle_rounded,
                    size: 16, color: kPrimary),
              ],
            ]),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(
                  color: tagColor, borderRadius: BorderRadius.circular(20)),
              child: Text(tagLabel,
                  style: GoogleFonts.prompt(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: tagTextColor)),
            ),
          ]),

          // ── price row ──
          Padding(
            padding: const EdgeInsets.only(top: 10, bottom: 14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(price,
                    style: GoogleFonts.prompt(
                        fontSize: 30,
                        fontWeight: FontWeight.w800,
                        color: isSelected ? kPrimary : kText)),
                const SizedBox(width: 4),
                Text(unit,
                    style: GoogleFonts.prompt(fontSize: 13, color: kSub)),
                if (originalPrice != null) ...[
                  const SizedBox(width: 10),
                  Text(originalPrice,
                      style: GoogleFonts.prompt(
                          fontSize: 12,
                          color: kSub,
                          decoration: TextDecoration.lineThrough)),
                  const SizedBox(width: 6),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                        color: kGreenLight,
                        borderRadius: BorderRadius.circular(6)),
                    child: Text('−20%',
                        style: GoogleFonts.prompt(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: kGreen)),
                  ),
                ],
              ],
            ),
          ),

          Divider(color: kBorder, height: 1),
          const SizedBox(height: 14),

          // ── features ──
          ...features.map((f) => _featureItem(f, isPro: isPro)),
        ]),
      ),
    );
  }

  Widget _featureItem(_Feature f, {required bool isPro}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
        Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            color: f.enabled
                ? (isPro ? kPrimaryLight : kGreenLight)
                : const Color(0xFFF1F3F8),
            shape: BoxShape.circle,
          ),
          child: Icon(
            f.enabled ? Icons.check_rounded : Icons.close_rounded,
            size: 11,
            color: f.enabled
                ? (isPro ? kPrimary : kGreen)
                : kSub.withOpacity(0.45),
          ),
        ),
        const SizedBox(width: 9),
        Icon(f.icon, size: 13, color: f.enabled ? kSub : kSub.withOpacity(0.3)),
        const SizedBox(width: 6),
        Expanded(
          child: Opacity(
            opacity: f.enabled ? 1.0 : 0.4,
            child: Text(f.label,
                style: GoogleFonts.prompt(
                    fontSize: 13, color: kText, height: 1.3)),
          ),
        ),
      ]),
    );
  }

  // ─── Compare Section ──────────────────────────────────────────────
  Widget _buildCompareSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Text('เปรียบเทียบฟีเจอร์',
              style: GoogleFonts.prompt(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: kSub,
                  letterSpacing: 0.5)),
        ),
        Container(
          decoration: BoxDecoration(
            color: kCard,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: kBorder),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.02),
                  blurRadius: 4,
                  offset: const Offset(0, 2))
            ],
          ),
          child: Column(children: [
            // header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: kSurface,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(14)),
                border: Border(bottom: BorderSide(color: kBorder)),
              ),
              child: Row(children: [
                Expanded(
                    child: Text('ฟีเจอร์',
                        style: GoogleFonts.prompt(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: kSub))),
                SizedBox(
                    width: 72,
                    child: Text('ฟรี',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.prompt(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: kSub))),
                SizedBox(
                    width: 72,
                    child: Text('Pro',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.prompt(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: kPrimary))),
              ]),
            ),
            ..._compareRows.asMap().entries.map((e) => _compareRowWidget(
                e.value,
                isLast: e.key == _compareRows.length - 1)),
          ]),
        ),
      ]),
    );
  }

  Widget _compareRowWidget(_CompareRow row, {bool isLast = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : Border(bottom: BorderSide(color: kBorder, width: 0.5)),
      ),
      child: Row(children: [
        Expanded(
            child: Text(row.label,
                style: GoogleFonts.prompt(fontSize: 12, color: kText))),
        SizedBox(
            width: 72,
            child: Center(
                child: _compareCell(row.free, row.freeNote, isPro: false))),
        SizedBox(
            width: 72,
            child:
                Center(child: _compareCell(row.pro, row.proNote, isPro: true))),
      ]),
    );
  }

  /// แสดง pill note ถ้ามี หรือ check/cross ปกติ
  Widget _compareCell(bool value, String? note, {required bool isPro}) {
    if (value && note != null && note.isNotEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: isPro ? kPrimaryLight : kGreenLight,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(note,
            style: GoogleFonts.prompt(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: isPro ? kPrimary : kGreen)),
      );
    }
    return Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        color: value
            ? (isPro ? kPrimaryLight : kGreenLight)
            : const Color(0xFFF1F3F8),
        shape: BoxShape.circle,
      ),
      child: Icon(
        value ? Icons.check_rounded : Icons.close_rounded,
        size: 11,
        color: value ? (isPro ? kPrimary : kGreen) : kSub.withOpacity(0.45),
      ),
    );
  }

  // ─── CTA ─────────────────────────────────────────────────────────
  Widget _buildCTA() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(children: [
        // savings callout — เฉพาะ pro + yearly
        if (_selectedPlan == 'pro' && _isYearly && !_isCurrentPro) ...[
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: kGreenLight,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: kGreen.withOpacity(0.2)),
            ),
            child: Row(children: [
              const Icon(Icons.savings_outlined, size: 16, color: kGreen),
              const SizedBox(width: 8),
              Expanded(
                child: Text('จ่ายรายปี ประหยัด ฿1,416 เมื่อเทียบกับรายเดือน',
                    style: GoogleFonts.prompt(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: kGreen)),
              ),
            ]),
          ),
        ],

        // main button
        AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          width: double.infinity,
          height: 54,
          decoration: BoxDecoration(
            color: _ctaBg,
            border: (_selectedPlan == 'free' && _ctaEnabled)
                ? Border.all(color: kBorder, width: 1.5)
                : null,
            borderRadius: BorderRadius.circular(14),
            boxShadow: (_ctaEnabled && _selectedPlan == 'pro')
                ? [
                    BoxShadow(
                        color: kPrimary.withOpacity(0.22),
                        blurRadius: 14,
                        offset: const Offset(0, 5))
                  ]
                : [],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: _ctaEnabled ? _onCtaTap : null,
              child: Center(
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  if (_ctaEnabled && _selectedPlan == 'pro') ...[
                    const Icon(Icons.workspace_premium_rounded,
                        size: 18, color: Colors.white),
                    const SizedBox(width: 8),
                  ],
                  Text(_ctaLabel,
                      style: GoogleFonts.prompt(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: _ctaTextColor)),
                ]),
              ),
            ),
          ),
        ),

        const SizedBox(height: 10),
        Text(
          _selectedPlan == 'pro'
              ? 'ยกเลิกได้ทุกเมื่อ · ไม่มีค่าใช้จ่ายซ่อนเร้น · ปลอดภัย 100%'
              : 'ใช้งานได้โดยไม่มีกำหนด · ไม่ต้องใช้บัตรเครดิต',
          textAlign: TextAlign.center,
          style: GoogleFonts.prompt(fontSize: 11, color: kSub),
        ),
      ]),
    );
  }

  // ─── Actions ─────────────────────────────────────────────────────
  void _onCtaTap() {
    if (_selectedPlan == 'pro') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => CheckoutPage(isYearly: _isYearly),
        ),
      );
    } else {
      _showDowngradeDialog();
    }
  }

  void _showDowngradeDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('ยืนยันการดาวน์เกรด',
            style: GoogleFonts.prompt(
                fontWeight: FontWeight.w600, fontSize: 16, color: kText)),
        content: Text(
          'คุณต้องการเปลี่ยนเป็นแผนฟรีใช่ไหม?\n'
          'ฟีเจอร์ Pro จะถูกปิดเมื่อสิ้นสุดรอบบิลปัจจุบัน',
          style: GoogleFonts.prompt(fontSize: 13, color: kSub, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('ยกเลิก',
                style: GoogleFonts.prompt(
                    color: kSub, fontWeight: FontWeight.w500)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await _store.downgradeToFree(); // ✅ อัปเดต store ทันที
              if (mounted) setState(() => _selectedPlan = 'free');
            },
            child: Text('ยืนยันดาวน์เกรด',
                style: GoogleFonts.prompt(
                    color: Colors.red, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}

// ─── Data classes ─────────────────────────────────────────────────────
class _Feature {
  final IconData icon;
  final String label;
  final bool enabled;
  const _Feature(
      {required this.icon, required this.label, required this.enabled});
}

class _CompareRow {
  final String label;
  final bool free;
  final bool pro;
  final String? freeNote;
  final String? proNote;
  const _CompareRow({
    required this.label,
    required this.free,
    required this.pro,
    this.freeNote,
    this.proNote,
  });
}
