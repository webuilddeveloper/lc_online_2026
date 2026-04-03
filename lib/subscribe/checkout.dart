import 'package:LawyerOnline/component/appbar.dart';
import 'package:LawyerOnline/subscribe/payment.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

const _kPrimary = Color(0xFF185FA5);
const _kPrimaryLight = Color(0xFFE6F1FB);
const _kGold = Color(0xFFBA7517);
const _kGoldLight = Color(0xFFFAEEDA);
const _kSurface = Color(0xFFF4F6FB);
const _kCard = Colors.white;
const _kText = Color(0xFF0D1B2A);
const _kSub = Color(0xFF6B7A99);
const _kBorder = Color(0xFFE2EAF4);
const _kGreen = Color(0xFF3B6D11);
const _kGreenLight = Color(0xFFEAF3DE);

class CheckoutPage extends StatefulWidget {
  const CheckoutPage({Key? key, this.isYearly = false}) : super(key: key);
  final bool isYearly;

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage>{
  

  String get _price => widget.isYearly ? '฿472' : '฿590';
  String get _priceNum => widget.isYearly ? '472' : '590';
  String get _billingLabel => widget.isYearly ? 'รายปี (จ่าย ฿5,664/ปี)' : 'รายเดือน';

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
      //   title: Text('สรุปคำสั่งซื้อ',
      //       style: GoogleFonts.prompt(
      //           fontSize: 16, fontWeight: FontWeight.w600, color: _kText)),
      //   centerTitle: true,
      // ),
      appBar: appBar(
        title: "สรุปคำสั่งซื้อ",
        backBtn: true,
        rightBtn: false,
        backAction: () => goBack(),
        rightAction: () => {},
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child:
            Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          // ── Plan summary card ──
          _sectionCard(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                      color: _kPrimary,
                      borderRadius: BorderRadius.circular(11)),
                  child: const Icon(Icons.layers_rounded,
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
                                color: _kText)),
                        Text(_billingLabel,
                            style:
                                GoogleFonts.prompt(fontSize: 12, color: _kSub)),
                      ]),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                      color: _kGoldLight,
                      borderRadius: BorderRadius.circular(20)),
                  child: Text('แนะนำ',
                      style: GoogleFonts.prompt(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: _kGold)),
                ),
              ]),
              const SizedBox(height: 16),
              _divider(),
              const SizedBox(height: 14),
              // features included
              ...[
                'เพิ่ม Social Media (FB, LINE, IG)',
                'รายละเอียดโปรไฟล์ขยาย',
                'ตั้งค่าราคาและเงื่อนไขได้เอง',
                'เปิด/ปิดรับเคสตามช่วงเวลา',
                'แสดงผลสูงกว่าในผลการค้นหา',
              ].map((f) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(children: [
                      Container(
                        width: 16,
                        height: 16,
                        decoration: const BoxDecoration(
                            color: _kPrimaryLight, shape: BoxShape.circle),
                        child: const Icon(Icons.check_rounded,
                            size: 10, color: _kPrimary),
                      ),
                      const SizedBox(width: 8),
                      Text(f,
                          style:
                              GoogleFonts.prompt(fontSize: 12, color: _kSub)),
                    ]),
                  )),
            ]),
          ),

          const SizedBox(height: 12),

          // ── Price breakdown ──
          _sectionCard(
            child: Column(children: [
              _priceRow('ราคาแผน Pro', _price),
              if (widget.isYearly) ...[
                const SizedBox(height: 8),
                _priceRow('ส่วนลดรายปี (20%)', '- ฿148', valueColor: _kGreen),
              ],
              const SizedBox(height: 10),
              _divider(),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('ยอดรวม',
                      style: GoogleFonts.prompt(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: _kText)),
                  Text(_price,
                      style: GoogleFonts.prompt(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: _kPrimary)),
                ],
              ),
            ]),
          ),

          const SizedBox(height: 12),

          // ── Trial notice ──
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: _kGreenLight,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _kGreen.withOpacity(0.2)),
            ),
            child: Row(children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                    color: _kGreen.withOpacity(0.15), shape: BoxShape.circle),
                child: const Icon(Icons.card_giftcard_rounded,
                    size: 17, color: _kGreen),
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
                              color: _kGreen)),
                      Text('จะถูกเรียกเก็บเงินหลังครบ 7 วัน\nยกเลิกก่อนได้ฟรี',
                          style: GoogleFonts.prompt(
                              fontSize: 11,
                              color: _kGreen.withOpacity(0.7),
                              height: 1.5)),
                    ]),
              ),
            ]),
          ),

          const SizedBox(height: 24),

          // ── CTA ──
          SizedBox(
            height: 52,
            child: ElevatedButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => PaymentCardPage(
                    price: _price,
                    isYearly: widget.isYearly,
                  ),
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: _kPrimary,
                foregroundColor: Colors.white,
                elevation: 0,
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
                style: GoogleFonts.prompt(fontSize: 11, color: _kSub)),
          ),
          const SizedBox(height: 20),
        ]),
      ),
    );
  }

  Widget _sectionCard({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _kCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _kBorder),
      ),
      child: child,
    );
  }

  Widget _divider() => Divider(color: _kBorder, height: 1, thickness: 0.5);

  Widget _priceRow(String label, String value, {Color? valueColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: GoogleFonts.prompt(fontSize: 13, color: _kSub)),
        Text(value,
            style: GoogleFonts.prompt(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: valueColor ?? _kText)),
      ],
    );
  }

  void goBack() async {
    Navigator.pop(context, false);
  }
}
