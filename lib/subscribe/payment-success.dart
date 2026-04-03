import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

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

class PaymentSuccessPage extends StatefulWidget {
  final String price;
  final bool isYearly;
  const PaymentSuccessPage(
      {Key? key, required this.price, this.isYearly = false})
      : super(key: key);

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
    _scaleAnim = CurvedAnimation(
        parent: _scaleCtrl, curve: Curves.elasticOut);
    _fadeAnim =
        CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);

    Future.delayed(const Duration(milliseconds: 200), () {
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
      backgroundColor: _kCard,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnim,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Spacer(flex: 2),

                // ── Success icon ──
                Center(
                  child: ScaleTransition(
                    scale: _scaleAnim,
                    child: Container(
                      width: 90,
                      height: 90,
                      decoration: const BoxDecoration(
                          color: _kGreenLight, shape: BoxShape.circle),
                      child: const Icon(Icons.check_rounded,
                          size: 46, color: _kGreen),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                Text('ชำระเงินสำเร็จ!',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.prompt(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: _kText)),
                const SizedBox(height: 8),
                Text(
                  'ยินดีต้อนรับสู่ Pro Plan\nคุณสามารถเข้าถึงฟีเจอร์ครบครันได้แล้ว',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.prompt(
                      fontSize: 13, color: _kSub, height: 1.6),
                ),

                const SizedBox(height: 32),

                // ── Receipt card ──
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: _kSurface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: _kBorder),
                  ),
                  child: Column(children: [
                    _receiptRow('แผน', 'Pro Plan'),
                    const SizedBox(height: 10),
                    _receiptRow('รอบบิล',
                        widget.isYearly ? 'รายปี' : 'รายเดือน'),
                    const SizedBox(height: 10),
                    _receiptRow('ยอดชำระ', widget.price,
                        valueStyle: GoogleFonts.prompt(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: _kPrimary)),
                    const SizedBox(height: 10),
                    _receiptRow('วันที่', _todayString()),
                    const SizedBox(height: 10),
                    Divider(color: _kBorder, height: 1, thickness: 0.5),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('สถานะ',
                            style: GoogleFonts.prompt(
                                fontSize: 13, color: _kSub)),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 3),
                          decoration: BoxDecoration(
                              color: _kGreenLight,
                              borderRadius: BorderRadius.circular(20)),
                          child: Text('ชำระแล้ว',
                              style: GoogleFonts.prompt(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: _kGreen)),
                        ),
                      ],
                    ),
                  ]),
                ),

                const Spacer(flex: 2),

                // ── CTA buttons ──
                SizedBox(
                  height: 52,
                  child: ElevatedButton(
                    onPressed: () => Navigator.popUntil(
                        context, (route) => route.isFirst),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _kPrimary,
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
                const SizedBox(height: 10),
                // TextButton(
                //   onPressed: () {},
                //   child: Text('ดูรายละเอียดการสมัคร',
                //       style: GoogleFonts.prompt(
                //           fontSize: 13, color: _kPrimary)),
                // ),
                // const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _receiptRow(String label, String value, {TextStyle? valueStyle}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: GoogleFonts.prompt(fontSize: 13, color: _kSub)),
        Text(value,
            style: valueStyle ??
                GoogleFonts.prompt(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: _kText)),
      ],
    );
  }

  String _todayString() {
    final now = DateTime.now();
    return '${now.day}/${now.month}/${now.year}';
  }
}