import 'package:LawyerOnline/booking/payment-page.dart';
import 'package:LawyerOnline/component/appbar.dart';
import 'package:LawyerOnline/component/button.dart';
import 'package:flutter/material.dart';

class SummaryPage extends StatelessWidget {
  final String topic;
  final dynamic lawyer;
  final DateTime? date;
  final String time;
  final String subTopic;

  const SummaryPage({
    required this.topic,
    required this.lawyer,
    required this.date,
    required this.time,
    required this.subTopic
  });

  @override
  Widget build(BuildContext context) {
    final thMonths = [
      '',
      'มกราคม',
      'กุมภาพันธ์',
      'มีนาคม',
      'เมษายน',
      'พฤษภาคม',
      'มิถุนายน',
      'กรกฎาคม',
      'สิงหาคม',
      'กันยายน',
      'ตุลาคม',
      'พฤศจิกายน',
      'ธันวาคม'
    ];

    final dateStr = date != null
        ? '${date!.day} ${thMonths[date!.month]} ${date!.year + 543}'
        : '';

    final cost = lawyer?['price'].toString() ?? 'ฟรี';
    final isFree = cost == 0;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      // appBar: _BookingAppBar(
      //   title: 'สรุปรายละเอียด',
      //   step: 4,
      //   totalSteps: 5,
      //   onBack: onBack,
      // ),
      appBar: appBar(
        title: "นัดหมายทนาย",
        backBtn: true,
        rightBtn: false,
        backAction: () => goBack(context),
        rightAction: () => {},
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildHeader(),
                  const SizedBox(height: 15),
                  // ── Lawyer Card ──────────────────────────────
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      // gradient: const LinearGradient(
                      //   colors: [Color(0xFF0262EC), Color(0xFF0485FF)],
                      //   begin: Alignment.topLeft,
                      //   end: Alignment.bottomRight,
                      // ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(children: [
                      // CircleAvatar(
                      //   radius: 30,
                      //   backgroundColor: Colors.white.withOpacity(0.2),
                      //   child: Text(lawyer?['avatar'] ?? 'ท',
                      //       style: const TextStyle(
                      //           fontSize: 24,
                      //           fontWeight: FontWeight.bold,
                      //           color: Colors.white)),
                      // ),
                      (lawyer?['imageUrl'] ?? "") != ""
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(30),
                              child: Image.asset(
                                lawyer?['imageUrl'],
                                width: 55,
                                height: 55,
                                fit: BoxFit.cover,
                              ),
                            )
                          : CircleAvatar(
                              radius: 30,
                              backgroundColor: Color(lawyer?['color'] as int)
                                  .withOpacity(0.15),
                              child: Text(
                                lawyer?['avatar'] as String,
                                style: TextStyle(
                                    color: Color(lawyer?['color'] as int),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 24),
                              ),
                            ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(lawyer?['name'] ?? '',
                                style: const TextStyle(
                                    color: Colors.black,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 16)),
                            const SizedBox(height: 2),
                            Text(lawyer['title'] ?? 'ทนายความอาวุโส',
                                style: const TextStyle(
                                    color: Colors.black, fontSize: 12)),
                            const SizedBox(height: 6),

                            Row(children: [
                              const Icon(Icons.star_rounded,
                                  color: Color(0xFFFFC107), size: 14),
                              const SizedBox(width: 3),
                              Text('${lawyer?['rating'] ?? lawyer?['scroll']}',
                                  style: const TextStyle(
                                      color: Colors.black,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 12)),
                            ]),
                          ],
                        ),
                      ),
                    ]),
                  ),
                  const SizedBox(height: 16),

                  // ── Detail Card ──────────────────────────────
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        _summaryRow(
                            Icons.label_outline_rounded, 'หัวข้อ', topic),
                        const Divider(height: 24, color: Color(0xFFF5F7FA)),
                        _summaryRow(
                            Icons.label_outline_rounded, 'หัวข้อย่อย', subTopic),
                        const Divider(height: 24, color: Color(0xFFF5F7FA)),
                        _summaryRow(
                            Icons.calendar_today_outlined, 'วันที่', dateStr),
                        const Divider(height: 24, color: Color(0xFFF5F7FA)),
                        _summaryRow(Icons.access_time_rounded, 'เวลา', time),
                        const Divider(height: 24, color: Color(0xFFF5F7FA)),
                        _summaryRow(
                            Icons.timer_outlined, 'ระยะเวลา', '1 ชั่วโมง'),
                        const Divider(height: 24, color: Color(0xFFF5F7FA)),
                        _summaryRow(
                            Icons.videocam_outlined, 'รูปแบบ', 'วิดีโอคอล'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ── Price Card ──────────────────────────────
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('ค่าบริการ',
                                  style: TextStyle(
                                      fontSize: 14, color: Colors.grey[500])),
                              Text(cost,
                                  style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF1A2340))),
                            ]),
                        const SizedBox(height: 12),
                        const Divider(color: Color(0xFFF5F7FA)),
                        const SizedBox(height: 12),
                        Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('ยอดรวม',
                                  style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF1A2340))),
                              Text(
                                isFree ? 'ฟรี' : cost,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF0262EC),
                                ),
                              ),
                            ]),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(
                16, 8, 16, MediaQuery.of(context).padding.bottom + 16),
            child: primaryButton(
              label: isFree ? 'ยืนยันนัดหมาย' : 'ชำระเงิน',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => PaymentPage(
                    lawyer: lawyer,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryRow(IconData icon, String label, String value) {
    return Row(children: [
      Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: const Color(0xFF0262EC).withOpacity(0.08),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, size: 16, color: const Color(0xFF0262EC)),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: TextStyle(fontSize: 11, color: Colors.grey[400])),
            const SizedBox(height: 2),
            Text(value,
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A2340))),
          ],
        ),
      ),
    ]);
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 0, 0, 0),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(9),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF0262EC), Color(0xFF34AAFF)],
            ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0262EC).withOpacity(0.4),
                blurRadius: 14,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: const Icon(Icons.checklist,
              color: Colors.white, size: 18),
        ),
        const SizedBox(width: 10),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text(
            'สรุปรายละเอียด',
            style: TextStyle(
              color: const Color(0xFF1A2340),
              fontSize: 16,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3,
            ),
          ),
          Text(
            'สรุปรายละเอียดต่างๆก่อนชำระเงิน',
            style: TextStyle(
                color: const Color(0xFF1A2340).withOpacity(0.4), fontSize: 11),
          ),
        ]),
      ]),
    );
  }

  void goBack(BuildContext context) async {
    Navigator.pop(context, false);
  }
}
