import 'package:LawyerOnline/component/appbar.dart';
import 'package:LawyerOnline/subscribe/checkout.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ─── Palette ─────────────────────────────────────────────────────────
const _kPrimary = Color(0xFF185FA5);
const _kPrimaryLight = Color(0xFFE6F1FB);
const _kGold = Color(0xFFBA7517);
const _kGoldLight = Color(0xFFFAEEDA);
const _kGreen = Color(0xFF3B6D11);
const _kGreenLight = Color(0xFFEAF3DE);
const _kSurface = Color(0xFFF4F6FB);
const _kCard = Colors.white;
const _kText = Color(0xFF0D1B2A);
const _kSub = Color(0xFF6B7A99);
const _kBorder = Color(0xFFE2EAF4);

class SubscribePage extends StatefulWidget {
  const SubscribePage({Key? key}) : super(key: key);

  @override
  State<SubscribePage> createState() => _SubscribePageState();
}

class _SubscribePageState extends State<SubscribePage>
    with SingleTickerProviderStateMixin {
  bool _isYearly = false;
  String _selectedPlan = 'pro';
  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;

  // ─── plan data ──────────────────────────────────────────────────
  final List<_Feature> _freeFeatures = [
    _Feature(label: 'รับเคสพื้นฐาน', enabled: true),
    _Feature(label: 'โปรไฟล์มาตรฐาน', enabled: true),
    _Feature(label: 'ช่องทาง Social Media', enabled: false),
    _Feature(label: 'ตั้งค่าราคาขั้นสูง', enabled: false),
  ];

  final List<_Feature> _proFeatures = [
    _Feature(label: 'ทุกฟีเจอร์ฟรี รวมถึง...', enabled: true),
    _Feature(label: 'เพิ่ม Social Media (FB, LINE, IG)', enabled: true),
    _Feature(label: 'รายละเอียดโปรไฟล์ขยาย', enabled: true),
    _Feature(label: 'ตั้งค่าราคาและเงื่อนไขได้เอง', enabled: true),
    _Feature(label: 'เปิด/ปิดรับเคสตามช่วงเวลา', enabled: true),
    _Feature(label: 'แสดงผลสูงกว่าในผลการค้นหา', enabled: true),
  ];

  final List<_CompareRow> _compareRows = [
    _CompareRow(label: 'รับเคสออนไลน์', free: true, pro: true),
    _CompareRow(label: 'Social Media', free: false, pro: true),
    _CompareRow(label: 'ตั้งค่าราคาเอง', free: false, pro: true),
    _CompareRow(label: 'รายละเอียดโปรไฟล์', free: false, pro: true),
    _CompareRow(label: 'ติดอันดับสูงกว่า', free: false, pro: true),
  ];

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  String get _proPrice => _isYearly ? '฿472' : '฿590';
  String get _ctaLabel => _selectedPlan == 'free'
      ? 'ใช้งานฟรีต่อไป'
      : _isYearly
          ? 'เริ่มใช้งาน Pro รายปี — ฟรี 7 วัน'
          : 'เริ่มใช้งาน Pro — ฟรี 7 วัน';

  // ═══════════════════════════════════════════════════════════════════
  //  BUILD
  // ═══════════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kSurface,
      // appBar: AppBar(
      //   backgroundColor: _kCard,
      //   elevation: 0,
      //   leading: IconButton(
      //     icon: const Icon(Icons.arrow_back_ios_new_rounded,
      //         size: 18, color: _kText),
      //     onPressed: () => Navigator.pop(context),
      //   ),
      //   title: Text('อัปเกรดแผน',
      //       style: GoogleFonts.prompt(
      //           fontSize: 16, fontWeight: FontWeight.w600, color: _kText)),
      //   centerTitle: true,
      // ),
      // อัพเกรดฟีเจอร์
      appBar: appBar(
        title: "Lawyer Pro",
        backBtn: true,
        rightBtn: false,
        backAction: () => goBack(),
        rightAction: () => {},
      ),
      body: FadeTransition(
        opacity: _fadeAnim,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.only(bottom: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHero(),
              const SizedBox(height: 10),
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
                    tagLabel: 'ใช้งานอยู่',
                    tagColor: _kPrimaryLight,
                    tagTextColor: _kPrimary,
                    features: _freeFeatures,
                    isFeatured: false,
                  ),
                  const SizedBox(height: 12),
                  _buildPlanCard(
                    planId: 'pro',
                    name: 'Pro',
                    price: _proPrice,
                    unit: '/เดือน',
                    originalPrice: _isYearly ? '฿739' : null,
                    tagLabel: 'แนะนำ',
                    tagColor: _kGoldLight,
                    tagTextColor: _kGold,
                    features: _proFeatures,
                    isFeatured: true,
                  ),
                ]),
              ),
              const SizedBox(height: 20),
              _buildCompareSection(),
              const SizedBox(height: 20),
              _buildCTA(),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Hero ────────────────────────────────────────────────────────
  Widget _buildHero() {
    return Container(
      // color: _kCard,
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
      child: Column(children: [
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
              color: _kPrimary, borderRadius: BorderRadius.circular(14)),
          child:
              const Icon(Icons.layers_rounded, color: Colors.white, size: 26),
        ),
        const SizedBox(height: 14),
        Text(
          'ยกระดับการให้บริการของคุณด้วย Lawyer Pro',
          textAlign: TextAlign.center,
          style: GoogleFonts.prompt(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: _kText,
          ),
        )
        // const SizedBox(height: 6),
        // Text(
        //   'เข้าถึงฟีเจอร์ครบครันที่ช่วยให้\nทนายมืออาชีพเติบโตได้เร็วขึ้น',
        //   textAlign: TextAlign.center,
        //   style: GoogleFonts.prompt(fontSize: 13, color: _kSub, height: 1.6),
        // ),
      ]),
    );
  }

  // ─── Billing Toggle ───────────────────────────────────────────────
  // Widget _buildBillingToggle() {
  //   return Row(mainAxisAlignment: MainAxisAlignment.center, children: [
  //     Text('รายเดือน',
  //         style: GoogleFonts.prompt(
  //           fontSize: 13,
  //           fontWeight: _isYearly ? FontWeight.w400 : FontWeight.w600,
  //           color: _isYearly ? _kSub : _kText,
  //         )),
  //     const SizedBox(width: 10),
  //     GestureDetector(
  //       onTap: () => setState(() => _isYearly = !_isYearly),
  //       child: AnimatedContainer(
  //         duration: const Duration(milliseconds: 250),
  //         curve: Curves.easeOutCubic,
  //         width: 44,
  //         height: 24,
  //         decoration: BoxDecoration(
  //             color: _kPrimary, borderRadius: BorderRadius.circular(12)),
  //         child: Padding(
  //           padding: const EdgeInsets.all(3),
  //           child: AnimatedAlign(
  //             duration: const Duration(milliseconds: 250),
  //             curve: Curves.easeOutCubic,
  //             alignment:
  //                 _isYearly ? Alignment.centerRight : Alignment.centerLeft,
  //             child: Container(
  //               width: 18,
  //               height: 18,
  //               decoration: const BoxDecoration(
  //                   color: Colors.white, shape: BoxShape.circle),
  //             ),
  //           ),
  //         ),
  //       ),
  //     ),
  //     const SizedBox(width: 10),
  //     Text('รายปี',
  //         style: GoogleFonts.prompt(
  //           fontSize: 13,
  //           fontWeight: _isYearly ? FontWeight.w600 : FontWeight.w400,
  //           color: _isYearly ? _kText : _kSub,
  //         )),
  //     if (_isYearly) ...[
  //       const SizedBox(width: 8),
  //       Container(
  //         padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
  //         decoration: BoxDecoration(
  //             color: _kGreenLight, borderRadius: BorderRadius.circular(20)),
  //         child: Text('ประหยัด 20%',
  //             style: GoogleFonts.prompt(
  //                 fontSize: 10, fontWeight: FontWeight.w600, color: _kGreen)),
  //       ),
  //     ],
  //   ]);
  // }
  Widget _buildBillingToggle() {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: _kSurface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _kBorder, width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildSegmentTab(
              label: 'รายเดือน',
              selected: !_isYearly,
              onTap: () => setState(() => _isYearly = false),
            ),
            _buildSegmentTab(
              label: 'รายปี',
              selected: _isYearly,
              onTap: () => setState(() => _isYearly = true),
              badge: 'ประหยัด 20%',
            ),
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
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: selected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  )
                ]
              : [],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: GoogleFonts.prompt(
                fontSize: 15,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                color: selected ? _kText : _kSub,
              ),
            ),
            if (badge != null) ...[
              const SizedBox(width: 6),
              // Container นี้มีขนาดคงที่เสมอ ไม่ทำให้ layout โยก
              AnimatedOpacity(
                duration: const Duration(milliseconds: 200),
                opacity: selected ? 1.0 : 0.5,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: selected ? _kGreenLight : Colors.transparent,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: selected ? _kGreenLight : _kSub.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    badge,
                    style: GoogleFonts.prompt(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: selected ? _kGreen : _kSub,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
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
    return GestureDetector(
      onTap: () => setState(() => _selectedPlan = planId),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        decoration: BoxDecoration(
          color: _kCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? _kPrimary : _kBorder,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: _kPrimary.withOpacity(0.12),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  )
                ]
              : [],
        ),
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // ── top row ──
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(name,
                  style: GoogleFonts.prompt(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: _kText)),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                    color: tagColor, borderRadius: BorderRadius.circular(20)),
                child: Text(tagLabel,
                    style: GoogleFonts.prompt(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: tagTextColor)),
              ),
            ],
          ),

          // ── price ──
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(price,
                      style: GoogleFonts.prompt(
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                          color: _kText)),
                  const SizedBox(width: 4),
                  Text(unit,
                      style: GoogleFonts.prompt(fontSize: 13, color: _kSub)),
                  if (originalPrice != null) ...[
                    const SizedBox(width: 8),
                    Text(originalPrice,
                        style: GoogleFonts.prompt(
                          fontSize: 12,
                          color: _kSub,
                          decoration: TextDecoration.lineThrough,
                        )),
                  ],
                ]),
          ),

          // ── divider ──
          Divider(color: _kBorder, height: 1),
          const SizedBox(height: 14),

          // ── features ──
          ...features.map((f) => _featureItem(f, isPro: planId == 'pro')),
        ]),
      ),
    );
  }

  Widget _featureItem(_Feature f, {required bool isPro}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        f.enabled
            ? Container(
                width: 18,
                height: 18,
                margin: const EdgeInsets.only(top: 1),
                decoration: BoxDecoration(
                  color: isPro ? _kPrimaryLight : _kGreenLight,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.check_rounded,
                    size: 11, color: isPro ? _kPrimary : _kGreen),
              )
            : Container(
                width: 18,
                height: 18,
                margin: const EdgeInsets.only(top: 1),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F3F8),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.close_rounded, size: 11, color: _kSub),
              ),
        const SizedBox(width: 9),
        Expanded(
          child: Opacity(
            opacity: f.enabled ? 1.0 : 0.45,
            child: Text(f.label,
                style: GoogleFonts.prompt(
                    fontSize: 13, color: _kSub, height: 1.4)),
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
                  color: _kSub,
                  letterSpacing: 0.5)),
        ),
        Container(
          decoration: BoxDecoration(
            color: _kCard,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _kBorder),
          ),
          child: Column(
            children: [
              // header
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: _kSurface,
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(14)),
                  border: Border(bottom: BorderSide(color: _kBorder)),
                ),
                child: Row(children: [
                  Expanded(
                      child: Text('ฟีเจอร์',
                          style: GoogleFonts.prompt(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: _kSub))),
                  SizedBox(
                      width: 80,
                      child: Text('ฟรี',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.prompt(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: _kSub))),
                  SizedBox(
                      width: 80,
                      child: Text('Pro',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.prompt(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: _kPrimary))),
                ]),
              ),
              // rows
              ..._compareRows.asMap().entries.map((e) {
                final isLast = e.key == _compareRows.length - 1;
                return _compareRowWidget(e.value, isLast: isLast);
              }),
            ],
          ),
        ),
      ]),
    );
  }

  Widget _compareRowWidget(_CompareRow row, {bool isLast = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : Border(bottom: BorderSide(color: _kBorder, width: 0.5)),
      ),
      child: Row(children: [
        Expanded(
            child: Text(row.label,
                style: GoogleFonts.prompt(fontSize: 12, color: _kSub))),
        SizedBox(width: 80, child: Center(child: _dotWidget(row.free))),
        SizedBox(
            width: 80, child: Center(child: _dotWidget(row.pro, isPro: true))),
      ]),
    );
  }

  Widget _dotWidget(bool value, {bool isPro = false}) {
    if (value) {
      return Container(
        width: 20,
        height: 20,
        decoration: BoxDecoration(
          color: isPro ? _kPrimaryLight : _kGreenLight,
          shape: BoxShape.circle,
        ),
        child: Icon(Icons.check_rounded,
            size: 11, color: isPro ? _kPrimary : _kGreen),
      );
    }
    return Container(
      width: 20,
      height: 20,
      decoration:
          const BoxDecoration(color: Color(0xFFF1F3F8), shape: BoxShape.circle),
      child: Icon(Icons.close_rounded, size: 11, color: _kSub),
    );
  }

  // ─── CTA ─────────────────────────────────────────────────────────
  Widget _buildCTA() {
    final isPro = _selectedPlan == 'pro';
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          width: double.infinity,
          height: 52,
          decoration: BoxDecoration(
            color: isPro ? _kPrimary : Colors.transparent,
            border: isPro ? null : Border.all(color: _kBorder),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () {
                if (isPro) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => CheckoutPage(isYearly: _isYearly),
                    ),
                  );
                }
              },
              child: Center(
                child: Text(
                  _ctaLabel,
                  style: GoogleFonts.prompt(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: isPro ? Colors.white : _kSub,
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Text('ยกเลิกได้ทุกเมื่อ · ไม่มีค่าใช้จ่ายซ่อนเร้น',
            style: GoogleFonts.prompt(fontSize: 11, color: _kSub)),
      ]),
    );
  }

  void goBack() async {
    Navigator.pop(context, false);
  }
}

// ─── Data classes ─────────────────────────────────────────────────
class _Feature {
  final String label;
  final bool enabled;
  const _Feature({required this.label, required this.enabled});
}

class _CompareRow {
  final String label;
  final bool free;
  final bool pro;
  const _CompareRow(
      {required this.label, required this.free, required this.pro});
}
