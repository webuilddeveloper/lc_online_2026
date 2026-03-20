import 'package:LawyerOnline/booking/booking-success.dart';
import 'package:LawyerOnline/component/appbar.dart';
import 'package:LawyerOnline/component/button.dart';
import 'package:LawyerOnline/component/dialog_service.dart';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

class PaymentPage extends StatefulWidget {
  final Map<String, dynamic>? lawyer;

  const PaymentPage({
    required this.lawyer,
  });

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  bool _isPaid = false;

  @override
  Widget build(BuildContext context) {
    final cost = widget.lawyer?['price'].toString() ?? '0';

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: appBar(
        title: "นัดหมายทนาย",
        backBtn: true,
        rightBtn: false,
        backAction: () => goBack(),
        rightAction: () => {},
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // ── QR Card ─────────────────────────────────
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.06),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        // PromptPay logo area
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1A2340),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            'PromptPay',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                              letterSpacing: 1,
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // QR Code
                        GestureDetector(
                          onTap: () => DialogService.showAutoClose(
                            context,
                            title: "ชำระเงินสำเร็จ",
                            message: "ระบบได้รับยอดเงินเรียบร้อยแล้ว",
                            seconds: 3,
                            isBtn: false,
                            onClose: () {
                              Navigator.pop(context);
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => BookingSuccessPage(
                                    lawyer: widget.lawyer,
                                    topic: 'ครอบครัวและมรดก',
                                    subTopic: 'ฟ้องหย่า / แบ่งสินสมรส',
                                    appointmentDate: '28 มีนาคม 2569',
                                    appointmentTime: '10:00 - 11:00',
                                    bookingCode: 'BK-2026-00123',
                                  ),
                                ),
                              );
                            },
                          ),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                  color: const Color(0xFFEEF2F5), width: 2),
                            ),
                            child: QrImageView(
                              data:
                                  'promptpay://0812345678/${cost.replaceAll(' บาท/ชม.', '')}',
                              version: QrVersions.auto,
                              size: 220,
                              backgroundColor: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Amount
                        Text('ยอดชำระ',
                            style: TextStyle(
                                fontSize: 13, color: Colors.grey[400])),
                        const SizedBox(height: 4),
                        Text(cost,
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF0262EC),
                              letterSpacing: -0.5,
                            )),
                        const SizedBox(height: 16),

                        // Account info
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF5F7FA),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(children: [
                            _paymentInfoRow(
                                'ชื่อบัญชี', 'LawyerOnline Co.,Ltd'),
                            const SizedBox(height: 6),
                            _paymentInfoRow('หมายเลข', '081-234-5678'),
                          ]),
                        ),
                        const SizedBox(height: 16),

                        // Instruction
                        Text(
                          'สแกน QR Code ด้วยแอปธนาคารของคุณ\nแล้วระบบจะยืนยันการชำระเงินอัตโนมัติ',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[400],
                            height: 1.6,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ── Confirm Paid ─────────────────────────────
                  // GestureDetector(
                  //   onTap: () => setState(() => _isPaid = !_isPaid),
                  //   child: Container(
                  //     padding: const EdgeInsets.all(16),
                  //     decoration: BoxDecoration(
                  //       color: Colors.white,
                  //       borderRadius: BorderRadius.circular(16),
                  //       border: Border.all(
                  //         color: _isPaid
                  //             ? const Color(0xFF34C759)
                  //             : const Color(0xFFEEF2F5),
                  //         width: 1.5,
                  //       ),
                  //     ),
                  //     child: Row(children: [
                  //       AnimatedContainer(
                  //         duration: const Duration(milliseconds: 200),
                  //         width: 24,
                  //         height: 24,
                  //         decoration: BoxDecoration(
                  //           color: _isPaid
                  //               ? const Color(0xFF34C759)
                  //               : Colors.white,
                  //           borderRadius: BorderRadius.circular(6),
                  //           border: Border.all(
                  //             color: _isPaid
                  //                 ? const Color(0xFF34C759)
                  //                 : Colors.grey[300]!,
                  //           ),
                  //         ),
                  //         child: _isPaid
                  //             ? const Icon(Icons.check_rounded,
                  //                 color: Colors.white, size: 16)
                  //             : null,
                  //       ),
                  //       const SizedBox(width: 12),
                  //       const Text(
                  //         'ฉันชำระเงินเรียบร้อยแล้ว',
                  //         style: TextStyle(
                  //           fontSize: 14,
                  //           fontWeight: FontWeight.w600,
                  //           color: Color(0xFF1A2340),
                  //         ),
                  //       ),
                  //     ]),
                  //   ),
                  // ),
                ],
              ),
            ),
          ),
          // Padding(
          //   padding: EdgeInsets.fromLTRB(
          //       16, 8, 16, MediaQuery.of(context).padding.bottom + 16),
          //   child: primaryButton(
          //     label: 'ยืนยันการชำระเงิน',
          //     enabled: _isPaid,
          //     onTap: () => Navigator.pushReplacement(
          //       context,
          //       MaterialPageRoute(
          //         builder: (_) => BookingSuccessPage(
          //           lawyer: widget.lawyer,
          //           topic: 'ครอบครัวและมรดก',
          //           subTopic: 'ฟ้องหย่า / แบ่งสินสมรส',
          //           appointmentDate: '28 มีนาคม 2569',
          //           appointmentTime: '10:00 - 11:00',
          //           bookingCode: 'BK-2026-00123',
          //         ),
          //       ),
          //     ),
          //     // Navigator.push(
          //     //   context,
          //     //   MaterialPageRoute(
          //     //     builder: (_) => PaymentPage(
          //     //       lawyer: widget.lawyer,
          //     //     ),
          //     //   ),
          //     // ),
          //   ),
          // ),
        ],
      ),
    );
  }

  Widget _paymentInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[500])),
        Text(value,
            style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1A2340))),
      ],
    );
  }

  void goBack() async {
    Navigator.pop(context, false);
  }
}
