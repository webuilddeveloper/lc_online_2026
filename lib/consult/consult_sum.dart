// ignore_for_file: deprecated_member_use, unused_field

import 'dart:io';

import 'package:LawyerOnline/component/appbar.dart';
import 'package:LawyerOnline/consult/consult_map.dart';
import 'package:LawyerOnline/consult/consult_qr.dart';

import 'package:flutter/material.dart';

class ConsultSummaryPage extends StatefulWidget {
  final String category;
  final String subCategory;
  final DateTime date;
  final String province;
  final String detail;
  final String demand;
  final String wage;
  final List<File> images;

  const ConsultSummaryPage(
      {super.key,
      required this.category,
      required this.subCategory,
      required this.date,
      required this.province,
      required this.detail,
      required this.demand,
      required this.wage,
      required this.images});

  @override
  State<ConsultSummaryPage> createState() => _ConsultSummaryPageState();
}

class _ConsultSummaryPageState extends State<ConsultSummaryPage> {
  String _paymentMethod = 'QR Code';

  int _hours = 1;
  // final int _pricePerHour = 500;
  // int get _total => _pricePerHour * _hours;
  // String _formatAmount(int amount) => amount
  //     .toString()
  //     .replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');

  String _formatAmount(String amount) {
    return amount.replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon) {
    final bool isEmpty = value.trim().isEmpty;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFFEEF4FF),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: const Color(0xFF0262EC), size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(fontSize: 11, color: Colors.grey[400]),
              ),
              const SizedBox(height: 2),
              Text(
                isEmpty ? "ไม่ได้พบข้อมูล" : value,
                style: isEmpty
                    ? const TextStyle(
                        fontSize: 13,
                        color: Colors.grey,
                        fontStyle: FontStyle.italic,
                      )
                    : const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1A2340),
                        height: 1.4,
                      ),
              ),
            ],
          ),
        )
      ],
    );
  }

  Widget _buildInfoRowImage(String label, List<File> images, IconData icon) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFFEEF4FF),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: const Color(0xFF0262EC), size: 18),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[400]),
              ),
              const SizedBox(height: 8),

              /// เช็คว่ามีรูปไหม
              images.isEmpty
                  ? const Text(
                      "ไม่ได้แนบภาพหลักฐาน",
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey,
                        fontStyle: FontStyle.italic,
                      ),
                    )
                  : SizedBox(
                      height: 100,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: images.length,
                        itemBuilder: (context, index) {
                          final image = images[index];
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.file(
                                image,
                                width: 100,
                                height: 100,
                                fit: BoxFit.cover,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSectionCard(
      {required String title, required IconData icon, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: const Color(0xFF0262EC), size: 18),
              const SizedBox(width: 8),
              Text(title,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: Color(0xFF1A2340))),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1, color: Color(0xFFEEF2F5)),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEEF2F5),
      appBar: appBar(
        title: "สรุปรายการ",
        backBtn: true,
        rightBtn: false,
        rightAction: () => {},
        backAction: () => Navigator.pop(context),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // ── ข้อมูลคดี ──
                  _buildSectionCard(
                    title: 'ข้อมูลคดี',
                    icon: Icons.description_outlined,
                    child: Column(
                      children: [
                        _buildInfoRow(
                            'ประเภทคดี', widget.category, Icons.gavel_outlined),
                        const SizedBox(height: 14),
                        _buildInfoRow('ประเภทย่อย', widget.subCategory,
                            Icons.folder_outlined),
                        const SizedBox(height: 14),
                        _buildInfoRow(
                          'วันที่นัดหมาย',
                          '${widget.date.day}/${widget.date.month}/${widget.date.year + 543}',
                          Icons.calendar_today_outlined,
                        ),
                        const SizedBox(height: 14),
                        _buildInfoRow('จังหวัด', widget.province,
                            Icons.location_on_outlined),
                        const SizedBox(height: 14),
                        _buildInfoRow('สรุปเหตุการณ์', widget.detail,
                            Icons.notes_outlined),
                        const SizedBox(height: 14),
                        _buildInfoRow(
                            'ข้อเรียกร้อง', widget.demand, Icons.gavel),
                        const SizedBox(height: 14),
                        _buildInfoRowImage(
                          'ภาพหลักฐาน',
                          widget.images,
                          Icons.image,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ── ค่าใช้จ่าย ──
                  _buildSectionCard(
                    title: 'ค่าใช้จ่าย',
                    icon: Icons.attach_money,
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('ค่าบริการ',
                                style: TextStyle(
                                    color: Colors.grey[500], fontSize: 13)),
                            Text(
                                // '฿${_formatAmount(_pricePerHour)}',
                                // '฿ ${_formatAmount(widget.wage)}',
                                '500',
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600, fontSize: 14)),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('เวลา',
                                style: TextStyle(
                                    color: Colors.grey[500], fontSize: 13)),
                            Text(
                                // '฿${_formatAmount(_pricePerHour)}',
                                // '฿ ${_formatAmount(widget.wage)}',
                                '60 นาที',
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600, fontSize: 14)),
                            // Row(
                            //   children: [
                            //     _HourButton(
                            //       icon: Icons.remove,
                            //       onTap: _hours > 1
                            //           ? () => setState(() => _hours--)
                            //           : null,
                            //     ),
                            //     SizedBox(
                            //       width: 40,
                            //       child: Center(
                            //         child: Text('$_hours',
                            //             style: const TextStyle(
                            //                 fontWeight: FontWeight.bold,
                            //                 fontSize: 16)),
                            //       ),
                            //     ),
                            //     _HourButton(
                            //       icon: Icons.add,
                            //       onTap: _hours < 8
                            //           ? () => setState(() => _hours++)
                            //           : null,
                            //     ),
                            //   ],
                            // ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        const Divider(height: 1, color: Color(0xFFEEF2F5)),
                        const SizedBox(height: 16),
                        const Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('ยอดรวม',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                    color: Color(0xFF1A2340))),
                            Text(
                              // '฿${_formatAmount(_total)}',
                              // '฿ ${_formatAmount(widget.wage)}',
                              '500',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 22,
                                color: Color(0xFF0262EC),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          '*ชำระเงินเมื่อค้นหาทนายความ และทนายความกดรับเคยแล้ว*',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            color: Colors.red,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ── ช่องทางชำระเงิน ──
                  _buildSectionCard(
                    title: 'ช่องทางชำระเงิน',
                    icon: Icons.payment_outlined,
                    child: GestureDetector(
                      onTap: () => setState(() => _paymentMethod = 'QR Code'),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEEF4FF),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: const Color(0xFF0262EC), width: 1.5),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.qr_code_2_outlined,
                                color: Color(0xFF0262EC), size: 24),
                            SizedBox(width: 12),
                            Text('QR Code',
                                style: TextStyle(
                                    color: Color(0xFF0262EC),
                                    fontWeight: FontWeight.w600)),
                            Spacer(),
                            Icon(Icons.check_circle,
                                color: Color(0xFF0262EC), size: 20),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Bottom Button ──
          Container(
            padding: EdgeInsets.fromLTRB(
                20, 12, 20, MediaQuery.of(context).padding.bottom + 12),
            decoration: const BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                    color: Color(0x15000000),
                    blurRadius: 10,
                    offset: Offset(0, -3))
              ],
            ),
            child: GestureDetector(
              onTap: () {
                // Navigator.push(
                //   context,
                //   MaterialPageRoute(
                //     // builder: (_) => ConsultQrPage(amount: _total),
                //     builder: (_) =>
                //         // ConsultQrPage(amount: int.parse(widget.wage)),
                //         ConsultQrPage(amount: int.parse('500')),
                //   ),
                // );
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    // builder: (_) => ConsultQrPage(amount: _total),
                    builder: (_) =>
                        // ConsultQrPage(amount: int.parse(widget.wage)),
                        ConsultMapPage(),
                  ),
                );
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
                  child: Text('ยืนยันและค้นหาทนายความ',
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 15)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HourButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;

  const _HourButton({required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color:
              onTap != null ? const Color(0xFFEEF4FF) : const Color(0xFFF5F7FA),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon,
            size: 16,
            color: onTap != null ? const Color(0xFF0262EC) : Colors.grey[300]),
      ),
    );
  }
}
