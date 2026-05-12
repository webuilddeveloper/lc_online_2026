// ══════════════════════════════════════════════════════════════════════
//  payment_success.dart  (v2)
//  - เรียก store.upgradeToPro() หลัง payment สำเร็จ
//  - ใช้ subscribe_theme.dart
//  - animation + receipt ครบเหมือนเดิม
// ══════════════════════════════════════════════════════════════════════

import 'package:LawyerOnline/subscribe/subscribe_theme.dart';
import 'package:LawyerOnline/models/lawyer/lawyer_profile_store.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class PaymentSuccessPage extends StatefulWidget {
  final String price;
  final bool isYearly;

  const PaymentSuccessPage({
    Key? key,
    required this.price,
    this.isYearly = false,
  }) : super(key: key);

  @override
  State<PaymentSuccessPage> createState() => _PaymentSuccessPageState();
}

class _PaymentSuccessPageState extends State<PaymentSuccessPage>
    with TickerProviderStateMixin {
  late AnimationController _scaleCtrl;
  late AnimationController _fadeCtrl;
  late Animation<double> _scaleAnim;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();

    _scaleCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _fadeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800));
    _scaleAnim = CurvedAnimation(parent: _scaleCtrl, curve: Curves.elasticOut);
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);

    Future.delayed(const Duration(milliseconds: 200), () {
      if (!mounted) return;
      _scaleCtrl.forward();
      _fadeCtrl.forward();
    });
  }

  @override
  void dispose() {
    _scaleCtrl.dispose();
    _fadeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kCard,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnim,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Spacer(flex: 2),

                // ── Success icon ──────────────────────────────────
                Center(
                  child: ScaleTransition(
                    scale: _scaleAnim,
                    child: Container(
                      width: 90,
                      height: 90,
                      decoration: const BoxDecoration(
                          color: kGreenLight, shape: BoxShape.circle),
                      child: const Icon(Icons.check_rounded,
                          size: 46, color: kGreen),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                Text('ชำระเงินสำเร็จ!',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.prompt(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: kText)),
                const SizedBox(height: 8),
                Text(
                  'ยินดีต้อนรับสู่ Pro Plan\nคุณสามารถเข้าถึงฟีเจอร์ครบครันได้แล้ว',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.prompt(
                      fontSize: 13, color: kSub, height: 1.6),
                ),

                const SizedBox(height: 32),

                // ── Receipt card ──────────────────────────────────
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: kSurface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: kBorder),
                  ),
                  child: Column(children: [
                    _receiptRow('แผน', 'Pro Plan'),
                    const SizedBox(height: 10),
                    _receiptRow(
                        'รอบบิล', widget.isYearly ? 'รายปี' : 'รายเดือน'),
                    const SizedBox(height: 10),
                    _receiptRow('ยอดชำระ', widget.price,
                        valueStyle: GoogleFonts.prompt(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: kPrimary)),
                    const SizedBox(height: 10),
                    _receiptRow('วันที่', _todayString()),
                    const SizedBox(height: 10),
                    const Divider(color: kBorder, height: 1, thickness: 0.5),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('สถานะ',
                            style:
                                GoogleFonts.prompt(fontSize: 13, color: kSub)),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 3),
                          decoration: BoxDecoration(
                              color: kGreenLight,
                              borderRadius: BorderRadius.circular(20)),
                          child: Text('ชำระแล้ว',
                              style: GoogleFonts.prompt(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: kGreen)),
                        ),
                      ],
                    ),
                  ]),
                ),

                const Spacer(flex: 2),

                // ── CTA ───────────────────────────────────────────
                SizedBox(
                  height: 54,
                  child: ElevatedButton(
                    onPressed: () async {
                      // รอ upgradeToPro เสร็จก่อน (ถ้ายังไม่เสร็จ) แล้วค่อย pop
                      final cycle = widget.isYearly
                          ? BillingCycle.yearly
                          : BillingCycle.monthly;
                      await LawyerProfileStore.instance.upgradeToPro(cycle);
                      if (!mounted) return;
                      Navigator.popUntil(context, (route) => route.isFirst);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kPrimary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    child: Text('กลับหน้าหลัก',
                        style: GoogleFonts.prompt(
                            fontSize: 15, fontWeight: FontWeight.w600)),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _receiptRow(String label, String value, {TextStyle? valueStyle}) =>
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: GoogleFonts.prompt(fontSize: 13, color: kSub)),
          Text(value,
              style: valueStyle ??
                  GoogleFonts.prompt(
                      fontSize: 13, fontWeight: FontWeight.w600, color: kText)),
        ],
      );

  String _todayString() {
    final now = DateTime.now();
    return '${now.day}/${now.month}/${now.year}';
  }
}
