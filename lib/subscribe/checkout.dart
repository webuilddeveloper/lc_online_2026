// ══════════════════════════════════════════════════════════════════════
//  checkout.dart  (v2)
//  - ใช้ subscribe_theme.dart แทน copy const
//  - features list ซิงค์กับ subscribe page
//  - yearly price breakdown ถูกต้อง
// ══════════════════════════════════════════════════════════════════════

import 'package:LawyerOnline/component/appbar.dart';
import 'package:LawyerOnline/subscribe/payment.dart';
import 'package:LawyerOnline/subscribe/subscribe_theme.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class CheckoutPage extends StatelessWidget {
  final bool isYearly;
  const CheckoutPage({Key? key, this.isYearly = false}) : super(key: key);

  String get _priceDisplay => isYearly ? '฿472' : '฿590';
  String get _billingLabel => isYearly ? 'รายปี (จ่าย ฿5,664/ปี)' : 'รายเดือน';

  static const List<String> _proFeatures = [
    'รับเคสออนไลน์ทุกประเภท',
    'โปรไฟล์ขยาย + แบดจ์ Pro',
    'Social Media (FB, LINE, IG)',
    'ตั้งค่าราคาและเงื่อนไขเอง',
    'เปิด/ปิดรับเคสตามช่วงเวลา',
    'ติดอันดับสูงกว่าในผลค้นหา',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kSurface,
      appBar: appBar(
        title: 'สรุปคำสั่งซื้อ',
        backBtn: true,
        rightBtn: false,
        backAction: () => Navigator.pop(context, false),
        rightAction: () {},
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child:
            Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          // ── Plan summary card ──────────────────────────────────────
          _sectionCard(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Row(children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [kPrimary, kPrimaryDark],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.workspace_premium_rounded,
                        color: Colors.white, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Pro Plan',
                              style: GoogleFonts.prompt(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: kText)),
                          Text(_billingLabel,
                              style: GoogleFonts.prompt(
                                  fontSize: 12, color: kSub)),
                        ]),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(
                        color: kGoldLight,
                        borderRadius: BorderRadius.circular(20)),
                    child: Text('แนะนำ',
                        style: GoogleFonts.prompt(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: kGold)),
                  ),
                ]),
                const SizedBox(height: 16),
                _divider(),
                const SizedBox(height: 14),
                ..._proFeatures.map((f) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(children: [
                        Container(
                          width: 16,
                          height: 16,
                          decoration: const BoxDecoration(
                              color: kPrimaryLight, shape: BoxShape.circle),
                          child: const Icon(Icons.check_rounded,
                              size: 10, color: kPrimary),
                        ),
                        const SizedBox(width: 8),
                        Text(f,
                            style:
                                GoogleFonts.prompt(fontSize: 12, color: kSub)),
                      ]),
                    )),
              ])),

          const SizedBox(height: 12),

          // ── Price breakdown ────────────────────────────────────────
          _sectionCard(
              child: Column(children: [
            _priceRow('ราคาแผน Pro (รายเดือน)', '฿590'),
            if (isYearly) ...[
              const SizedBox(height: 8),
              _priceRow('ส่วนลดรายปี (−20%)', '−฿118/เดือน',
                  valueColor: kGreen),
            ],
            const SizedBox(height: 10),
            _divider(),
            const SizedBox(height: 10),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text('ยอดที่ชำระ/เดือน',
                  style: GoogleFonts.prompt(
                      fontSize: 14, fontWeight: FontWeight.w700, color: kText)),
              Text(_priceDisplay,
                  style: GoogleFonts.prompt(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: kPrimary)),
            ]),
            if (isYearly) ...[
              const SizedBox(height: 4),
              Align(
                alignment: Alignment.centerRight,
                child: Text('(฿5,664 ต่อปี)',
                    style: GoogleFonts.prompt(fontSize: 11, color: kSub)),
              ),
            ],
          ])),

          const SizedBox(height: 12),

          // ── Trial notice ───────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: kGreenLight,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: kGreen.withOpacity(0.2)),
            ),
            child: Row(children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                    color: kGreen.withOpacity(0.15), shape: BoxShape.circle),
                child: const Icon(Icons.card_giftcard_rounded,
                    size: 18, color: kGreen),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('ทดลองใช้ฟรี 7 วัน',
                          style: GoogleFonts.prompt(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: kGreen)),
                      Text('จะถูกเรียกเก็บเงินหลังครบ 7 วัน · ยกเลิกก่อนได้ฟรี',
                          style: GoogleFonts.prompt(
                              fontSize: 11,
                              color: kGreen.withOpacity(0.7),
                              height: 1.5)),
                    ]),
              ),
            ]),
          ),

          const SizedBox(height: 24),

          // ── CTA ───────────────────────────────────────────────────
          SizedBox(
            height: 54,
            child: ElevatedButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => PaymentCardPage(
                    price: _priceDisplay,
                    isYearly: isYearly,
                  ),
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: kPrimary,
                foregroundColor: Colors.white,
                elevation: 0,
                shadowColor: kPrimary.withOpacity(0.3),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              child: Text('ดำเนินการชำระเงิน',
                  style: GoogleFonts.prompt(
                      fontSize: 15, fontWeight: FontWeight.w600)),
            ),
          ),
          const SizedBox(height: 10),
          Center(
            child: Text('ปลอดภัยด้วย SSL · ยกเลิกได้ทุกเมื่อ',
                style: GoogleFonts.prompt(fontSize: 11, color: kSub)),
          ),
          const SizedBox(height: 20),
        ]),
      ),
    );
  }

  Widget _sectionCard({required Widget child}) => Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: kCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: kBorder),
        ),
        child: child,
      );

  Widget _divider() => const Divider(color: kBorder, height: 1, thickness: 0.5);

  Widget _priceRow(String label, String value, {Color? valueColor}) => Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: GoogleFonts.prompt(fontSize: 13, color: kSub)),
          Text(value,
              style: GoogleFonts.prompt(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: valueColor ?? kText)),
        ],
      );
}
