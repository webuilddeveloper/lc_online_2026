import 'package:LawyerOnline/booking/payment-page.dart';
import 'package:LawyerOnline/component/appbar.dart';
import 'package:LawyerOnline/component/button.dart';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

class SummaryPage extends StatelessWidget {
  final dynamic lawyer;
  final DateTime? date;
  final String time;
  final String topic;        // code
  final String topicTitle;   // title
  final String subTopic;     // code
  final String subTopicTitle; // title
  final String details;
  Color get _lawyerColor {
    final r = (lawyer['rateAverage'] ?? 0) as num;
    if (r >= 4.8) return const Color(0xFF1565C0);
    if (r >= 4.0) return const Color(0xFF02A8D1);
    if (r >= 3.0) return const Color(0xFFFDD835);
    if (r >= 2.0) return const Color(0xFFEF6C00);
    return const Color(0xFFD32F2F);
  }

  SummaryPage({
    required this.topic,
    required this.lawyer,
    required this.date,
    required this.time,
    required this.subTopic,
    required this.topicTitle,
    required this.subTopicTitle,
    required this.details
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

    final cost = lawyer?['price'].toString() ?? 'free'.tr();
    final isFree = cost == '500';
    

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      // appBar: _BookingAppBar(
      //   title: 'bookingSummaryTitle'.tr(),
      //   step: 4,
      //   totalSteps: 5,
      //   onBack: onBack,
      // ),
      appBar: appBar(
        title: 'bookingTitle'.tr(),
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
                              child: Image.network(
                                lawyer?['imageUrl'],
                                width: 55,
                                height: 55,
                                fit: BoxFit.cover,
                              ),
                            )
                          : CircleAvatar(
                              radius: 30,
                              backgroundColor: _lawyerColor
                                  .withOpacity(0.15),
                              child: Text(
                                lawyer?['avatar'] as String,
                                style: TextStyle(
                                    color: _lawyerColor,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 24),
                              ),
                            ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('${lawyer?['firstName']} ${lawyer?['lastName']}',
                                style: const TextStyle(
                                    color: Colors.black,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 16)),
                            const SizedBox(height: 2),
                            Text('seniorLawyer'.tr(),
                                style: const TextStyle(
                                    color: Colors.black, fontSize: 12)),
                            const SizedBox(height: 6),
                            Row(children: [
                              const Icon(Icons.star_rounded,
                                  color: Color(0xFFFFC107), size: 14),
                              const SizedBox(width: 3),
                              Text('${lawyer?['rateAverage']}',
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
                            Icons.label_outline_rounded, 'topicLabel'.tr(), topicTitle),
                        const Divider(height: 24, color: Color(0xFFF5F7FA)),
                        _summaryRow(
                          Icons.label_outline_rounded,
                          'subTopicLabel'.tr(),
                          subTopicTitle.trim().isEmpty ? '-' : subTopicTitle,
                        ),
                        const Divider(height: 24, color: Color(0xFFF5F7FA)),
                        _summaryRow(
                            Icons.calendar_today_outlined, 'dateLabel'.tr(), dateStr),
                        const Divider(height: 24, color: Color(0xFFF5F7FA)),
                        _summaryRow(Icons.access_time_rounded, 'timeLabel'.tr(), time),
                        const Divider(height: 24, color: Color(0xFFF5F7FA)),
                        _summaryRow(
                            Icons.timer_outlined, 'durationLabel'.tr(), 'duration1Hour'.tr()),
                        const Divider(height: 24, color: Color(0xFFF5F7FA)),
                        _summaryRow(
                            Icons.videocam_outlined, 'formatLabel'.tr(), 'formatVideoCall'.tr()),
                        const Divider(height: 24, color: Color(0xFFF5F7FA)),
                        _summaryRow(
                            Icons.comment, 'additionalDetails'.tr(), details ?? '-'),
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
                              Text('serviceFee'.tr(),
                                  style: TextStyle(
                                      fontSize: 14, color: Colors.grey[500])),
                              Text(lawyer['cost'],
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
                              Text('totalAmount'.tr(),
                                  style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF1A2340))),
                              Text(
                                lawyer['cost'],
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
              label: isFree ? 'bookingConfirm'.tr() : 'bookingPay'.tr(),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => PaymentPage(
                    lawyer: lawyer,
                    topic: topic,
                    topicTitle: topicTitle,
                    subTopic: subTopic,
                    subTopicTitle: subTopicTitle,
                    time: time,
                    date: date,
                    details: details,
                    
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
            Text(value == '' ? '-' : value,
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
          child: const Icon(Icons.checklist, color: Colors.white, size: 18),
        ),
        const SizedBox(width: 10),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(
            'bookingSummaryTitle'.tr(),
            style: const TextStyle(
              color: const Color(0xFF1A2340),
              fontSize: 16,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3,
            ),
          ),
          Text(
            'bookingSummaryHint'.tr(),
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
