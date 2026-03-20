import 'package:LawyerOnline/component/appbar.dart';
import 'package:LawyerOnline/consult/consult_map.dart';
import 'package:LawyerOnline/consult/consult_status.dart';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

class ConsultQrPage extends StatelessWidget {
  final int amount;
  final dynamic lawyer;

  const ConsultQrPage({super.key, required this.amount, required this.lawyer});

  String _generatePromptPayPayload(int amount) {
    final amountStr = amount.toDouble().toStringAsFixed(2);
    const phoneNumber = '0812345678';

    return '00020101021129370016A000000677010111011300668${phoneNumber.replaceFirst('0', '')}5303764540${amountStr}5802TH5920LawyerOnline Payment6304';
  }

  String _formatAmount(int amount) => amount
      .toString()
      .replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');

  @override
  Widget build(BuildContext context) {
    final payload = _generatePromptPayPayload(amount);

    return Scaffold(
      backgroundColor: const Color(0xFFEEF2F5),
      appBar: appBar(
        title: "ชำระเงิน",
        backBtn: true,
        rightBtn: false,
        rightAction: () => {},
        backAction: () => Navigator.pop(context),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // ── QR Card ──
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(28),
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
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEEF4FF),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.qr_code_2_outlined,
                            color: Color(0xFF0262EC), size: 20),
                        SizedBox(width: 8),
                        Text('PromptPay',
                            style: TextStyle(
                                color: Color(0xFF0262EC),
                                fontWeight: FontWeight.bold,
                                fontSize: 16)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  QrImageView(
                    data: payload,
                    version: QrVersions.auto,
                    size: 220,
                    eyeStyle: const QrEyeStyle(
                      eyeShape: QrEyeShape.square,
                      color: Color(0xFF0262EC),
                    ),
                    dataModuleStyle: const QrDataModuleStyle(
                      dataModuleShape: QrDataModuleShape.square,
                      color: Color(0xFF1A2340),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Divider(color: Color(0xFFEEF2F5)),
                  const SizedBox(height: 16),
                  Text('ยอดชำระ',
                      style: TextStyle(color: Colors.grey[400], fontSize: 13)),
                  const SizedBox(height: 6),
                  Text(
                    '฿${_formatAmount(amount)}',
                    style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0262EC)),
                  ),
                  const SizedBox(height: 4),
                  Text('บาท',
                      style: TextStyle(color: Colors.grey[400], fontSize: 13)),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ── คำแนะนำ ──
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFBEB),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFFFE082), width: 1),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.info_outline,
                      color: Color(0xFFF59E0B), size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'เปิดแอปธนาคารของท่าน แล้วสแกน QR Code ด้านบน เพื่อชำระเงิน ระบบจะยืนยันการชำระเงินโดยอัตโนมัติ',
                      style: TextStyle(
                          color: Colors.amber[800], fontSize: 12, height: 1.5),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // ── ปุ่มตรวจสอบ ──
            GestureDetector(
              onTap: () {
                showGeneralDialog(
                  context: context,
                  barrierDismissible: false,
                  barrierColor: Colors.black.withOpacity(0.6),
                  transitionDuration: const Duration(milliseconds: 400),
                  transitionBuilder:
                      (context, animation, secondaryAnimation, child) {
                    return ScaleTransition(
                      scale: CurvedAnimation(
                          parent: animation, curve: Curves.easeOutBack),
                      child: FadeTransition(opacity: animation, child: child),
                    );
                  },
                  pageBuilder: (context, _, __) => Dialog(
                    backgroundColor: Colors.transparent,
                    elevation: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 28, vertical: 36),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(28),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF4CAF50).withOpacity(0.15),
                            blurRadius: 40,
                            offset: const Offset(0, 16),
                          ),
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 24,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF66BB6A), Color(0xFF43A047)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color:
                                      const Color(0xFF4CAF50).withOpacity(0.4),
                                  blurRadius: 20,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: const Icon(Icons.check_rounded,
                                color: Colors.white, size: 40),
                          ),
                          const SizedBox(height: 24),
                          const Text(
                            'ชำระเงินสำเร็จ',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 20,
                              color: Color(0xFF1A1A2E),
                              letterSpacing: -0.3,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'กำลังดำเนินการ โปรดรอสักครู่...',
                            style: TextStyle(
                                color: Colors.grey[400], fontSize: 13.5),
                          ),
                          const SizedBox(height: 28),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(99),
                            child: const LinearProgressIndicator(
                              value: null,
                              backgroundColor: Color(0xFFF0F0F0),
                              valueColor: AlwaysStoppedAnimation<Color>(
                                  Color(0xFF0262EC)),
                              minHeight: 4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );

                Future.delayed(const Duration(seconds: 2), () {
                  Navigator.pop(context); // ปิด dialog
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ConsultStatusPage(lawyer: lawyer),
                    ),
                  );
                  // Navigator.push(
                  //   context,
                  //   MaterialPageRoute(
                  //     builder: (_) => const ConsultMapPage(),
                  //   ),
                  // );
                });
              },
              child: Container(
                height: 52,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                      colors: [Color(0xFF0262EC), Color(0xFF0485FF)]),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF0262EC).withOpacity(0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Center(
                  child: Text('ตรวจสอบการชำระเงิน',
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 15)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // void _showSuccessDialog(BuildContext context) {
  //   showGeneralDialog(
  //     context: context,
  //     barrierDismissible: false,
  //     barrierColor: Colors.black.withOpacity(0.6),
  //     transitionDuration: const Duration(milliseconds: 400),
  //     transitionBuilder: (context, animation, secondaryAnimation, child) {
  //       return ScaleTransition(
  //         scale: CurvedAnimation(parent: animation, curve: Curves.easeOutBack),
  //         child: FadeTransition(opacity: animation, child: child),
  //       );
  //     },
  //     pageBuilder: (context, _, __) => Dialog(
  //       backgroundColor: Colors.transparent,
  //       elevation: 0,
  //       child: Container(
  //         padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 36),
  //         decoration: BoxDecoration(
  //           color: Colors.white,
  //           borderRadius: BorderRadius.circular(28),
  //           boxShadow: [
  //             BoxShadow(
  //               color: const Color(0xFF4CAF50).withOpacity(0.15),
  //               blurRadius: 40,
  //               offset: const Offset(0, 16),
  //             ),
  //             BoxShadow(
  //               color: Colors.black.withOpacity(0.08),
  //               blurRadius: 24,
  //               offset: const Offset(0, 4),
  //             ),
  //           ],
  //         ),
  //         child: Column(
  //           mainAxisSize: MainAxisSize.min,
  //           children: [
  //             Container(
  //               width: 80,
  //               height: 80,
  //               decoration: BoxDecoration(
  //                 gradient: const LinearGradient(
  //                   colors: [Color(0xFF66BB6A), Color(0xFF43A047)],
  //                   begin: Alignment.topLeft,
  //                   end: Alignment.bottomRight,
  //                 ),
  //                 shape: BoxShape.circle,
  //                 boxShadow: [
  //                   BoxShadow(
  //                     color: const Color(0xFF4CAF50).withOpacity(0.4),
  //                     blurRadius: 20,
  //                     offset: const Offset(0, 8),
  //                   ),
  //                 ],
  //               ),
  //               child: const Icon(Icons.check_rounded,
  //                   color: Colors.white, size: 40),
  //             ),
  //             const SizedBox(height: 24),
  //             const Text(
  //               'สำเร็จ',
  //               style: TextStyle(
  //                 fontWeight: FontWeight.w700,
  //                 fontSize: 20,
  //                 color: Color(0xFF1A1A2E),
  //                 letterSpacing: -0.3,
  //               ),
  //             ),
  //             const SizedBox(height: 8),
  //             Text(
  //               'บันทึกข้อมูลเรียบร้อยแล้ว...',
  //               style: TextStyle(color: Colors.grey[400], fontSize: 13.5),
  //             ),
  //             const SizedBox(height: 28),
  //             GestureDetector(
  //               onTap: () {
  //                 Navigator.pushReplacement(
  //                   context,
  //                   MaterialPageRoute(
  //                     builder: (_) => ConsultStatusPage(lawyer: widget.lawyer),
  //                   ),
  //                 );
  //               },
  //               child: Container(
  //                 height: 48,
  //                 decoration: BoxDecoration(
  //                   color: const Color(0xFF4CAF50),
  //                   borderRadius: BorderRadius.circular(14),
  //                 ),
  //                 child: const Center(
  //                   child: Text('ตกลง',
  //                       style: TextStyle(
  //                           color: Colors.white,
  //                           fontWeight: FontWeight.w600,
  //                           fontSize: 15)),
  //                 ),
  //               ),
  //             ),
  //           ],
  //         ),
  //       ),
  //     ),
  //   );
  // }
}
