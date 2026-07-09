// ══════════════════════════════════════════════════════════════════════
//  payment_success.dart  (v2)
//  - เรียก store.upgradeToPro() หลัง payment สำเร็จ
//  - ใช้ subscribe_theme.dart
//  - animation + receipt ครบเหมือนเดิม
// ══════════════════════════════════════════════════════════════════════

import 'package:LawyerOnline/subscribe/subscribe_theme.dart';
import 'package:LawyerOnline/models/lawyer/lawyer_profile_store.dart';
import 'package:LawyerOnline/shared/app_typography.dart';
import 'package:flutter/material.dart';

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
  bool _upgradeDone = false;
  bool _upgradeFailed = false;

  @override
  void initState() {
    super.initState();
    _upgradeSubscription();

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

  Future<void> _upgradeSubscription() async {
    final cycle =
        widget.isYearly ? BillingCycle.yearly : BillingCycle.monthly;
    final ok = await LawyerProfileStore.instance.upgradeToPro(cycle);
    if (!mounted) return;
    setState(() {
      _upgradeDone = true;
      _upgradeFailed = !ok;
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
                    style: AppTypography.prompt(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: kText)),
                const SizedBox(height: 8),
                Text(
                  _upgradeFailed
                      ? 'ชำระเงินสำเร็จ แต่ยังไม่สามารถเปิด Pro ได้\nกรุณาลองอีกครั้งจากหน้าโปรไฟล์'
                      : 'ยินดีต้อนรับสู่ Pro Plan\nคุณสามารถเข้าถึงฟีเจอร์ครบครันได้แล้ว',
                  textAlign: TextAlign.center,
                  style: AppTypography.prompt(
                      fontSize: 13, color: kSub, height: 1.6),
                ),
                if (_upgradeDone &&
                    !_upgradeFailed &&
                    LawyerProfileStore.instance.isOnTrial) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: kPrimaryLight,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'ทดลองใช้ฟรี ${LawyerProfileStore.instance.trialDaysRemaining ?? 0} วัน',
                      textAlign: TextAlign.center,
                      style: AppTypography.prompt(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: kPrimary,
                      ),
                    ),
                  ),
                ],

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
                        valueStyle: AppTypography.prompt(
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
                                AppTypography.prompt(fontSize: 13, color: kSub)),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 3),
                          decoration: BoxDecoration(
                              color: kGreenLight,
                              borderRadius: BorderRadius.circular(20)),
                          child: Text('ชำระแล้ว',
                              style: AppTypography.prompt(
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
                      if (!_upgradeDone) {
                        await _upgradeSubscription();
                      }
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
                    child: Text('กลับหน้าหลัก', style: AppTypography.button()),
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
          Text(label, style: AppTypography.prompt(fontSize: 13, color: kSub)),
          Text(value,
              style: valueStyle ??
                  AppTypography.prompt(
                      fontSize: 13, fontWeight: FontWeight.w600, color: kText)),
        ],
      );

  String _todayString() {
    final now = DateTime.now();
    return '${now.day}/${now.month}/${now.year}';
  }
}
