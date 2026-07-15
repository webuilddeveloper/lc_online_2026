// ignore_for_file: deprecated_member_use, unused_field

import 'dart:io';

import 'package:LawyerOnline/component/appbar.dart';
import 'package:LawyerOnline/component/dialog_service.dart';
import 'package:LawyerOnline/consult/consult_map.dart';
import 'package:LawyerOnline/services/case_request_service.dart';
import 'package:LawyerOnline/shared/api_provider.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

class ConsultSummaryPage extends StatefulWidget {
  // ── field ชุดใหม่ที่ตกลงกัน ──────────────────────────────────────────────
  final String topic;        // code หมวดหลัก
  final String topicTitle;   // ชื่อหมวดหลัก (display)
  final String subTopic;     // code หมวดย่อย
  final String subTopicTitle;// ชื่อหมวดย่อย (display)
  final String province;     // ชื่อจังหวัด
  final String detail;       // สรุปเหตุการณ์
  final String demand;       // ข้อเรียกร้อง
  final List<File> images;   // รูปหลักฐาน

  const ConsultSummaryPage({
    super.key,
    required this.topic,
    required this.topicTitle,
    required this.subTopic,
    required this.subTopicTitle,
    required this.province,
    required this.detail,
    required this.demand,
    required this.images,
  });

  @override
  State<ConsultSummaryPage> createState() => _ConsultSummaryPageState();
}

class _ConsultSummaryPageState extends State<ConsultSummaryPage> {
  final CaseRequestService _caseReqService = CaseRequestService();
  bool _isSubmitting = false;

  String? _extractRequestCode(dynamic res) {
    if (res['status'] != 'S') return null;

    final data = res['data'];
    if (data is Map) {
      return data['requestCode']?.toString() ?? data['code']?.toString();
    }

    final objectData = res['objectData'];
    if (objectData is Map) {
      return objectData['requestCode']?.toString() ??
          objectData['code']?.toString();
    }

    return res['requestCode']?.toString();
  }

  Future<List<String>> _uploadImages() async {
    final urls = <String>[];
    for (final file in widget.images) {
      final url = await uploadImage(file);
      if (url.isNotEmpty) urls.add(url);
    }
    return urls;
  }

  Future<void> _submitAndSearch() async {
    if (_isSubmitting) return;

    setState(() => _isSubmitting = true);
    DialogService.showLoading(context);

    try {
      double? lat;
      double? lng;

      try {
        var perm = await Geolocator.checkPermission();
        if (perm == LocationPermission.denied) {
          perm = await Geolocator.requestPermission();
        }
        if (perm == LocationPermission.whileInUse ||
            perm == LocationPermission.always) {
          final pos = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.high,
          ).timeout(const Duration(seconds: 8));
          lat = pos.latitude;
          lng = pos.longitude;
        }
      } catch (_) {}

      final imageUrlList = await _uploadImages();

      final res = await _caseReqService.createCaseRequest(
        topic: widget.topic,
        topicTitle: widget.topicTitle,
        subTopic: widget.subTopic,
        subTopicTitle: widget.subTopicTitle,
        provinceCode: widget.province,
        provinceTitle: widget.province,
        details: widget.detail,
        requirement: widget.demand,
        imageUrlList: imageUrlList,
        caseType: 2,
        lat: lat,
        lng: lng,
      );

      if (!mounted) return;
      Navigator.pop(context);
      final requestCode = _extractRequestCode(res);
      if (requestCode == null || requestCode.isEmpty) {
        _showError(res['message']?.toString() ?? 'สร้างคำขอไม่สำเร็จ');
        return;
      }

      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ConsultMapPage(
            topic: widget.topic,
            topicTitle: widget.topicTitle,
            subTopic: widget.subTopic,
            subTopicTitle: widget.subTopicTitle,
            province: widget.province,
            detail: widget.detail,
            demand: widget.demand,
            images: widget.images,
            requestCode: requestCode,
            caseType: 2,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      _showError('เกิดข้อผิดพลาด: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.red),
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
              Text(label,
                  style: TextStyle(fontSize: 11, color: Colors.grey[400])),
              const SizedBox(height: 2),
              Text(
                isEmpty ? 'ไม่ได้ระบุ' : value,
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
        ),
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
              Text(label,
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[400])),
              const SizedBox(height: 8),
              images.isEmpty
                  ? const Text(
                      'ไม่ได้แนบภาพหลักฐาน',
                      style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey,
                          fontStyle: FontStyle.italic),
                    )
                  : SizedBox(
                      height: 100,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: images.length,
                        itemBuilder: (_, index) => Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.file(images[index],
                                width: 100, height: 100, fit: BoxFit.cover),
                          ),
                        ),
                      ),
                    ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
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
          Row(children: [
            Icon(icon, color: const Color(0xFF0262EC), size: 18),
            const SizedBox(width: 8),
            Text(title,
                style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: Color(0xFF1A2340))),
          ]),
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
        title: 'สรุปรายการ',
        backBtn: true,
        rightBtn: false,
        rightAction: () {},
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
                        _buildInfoRow('ประเภทคดี', widget.topicTitle,
                            Icons.gavel_outlined),
                        const SizedBox(height: 14),
                        _buildInfoRow('ประเภทย่อย', widget.subTopicTitle,
                            Icons.folder_outlined),
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
                            'ภาพหลักฐาน', widget.images, Icons.image),
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
                            const Text('500',
                                style: TextStyle(
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
                            const Text('60 นาที',
                                style: TextStyle(
                                    fontWeight: FontWeight.w600, fontSize: 14)),
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
                            Text('500',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 22,
                                    color: Color(0xFF0262EC))),
                          ],
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          '*ชำระเงินเมื่อค้นหาทนายความ และทนายความกดรับเคสแล้ว*',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              color: Colors.red),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ── ช่องทางชำระเงิน ──
                  _buildSectionCard(
                    title: 'ช่องทางชำระเงิน',
                    icon: Icons.payment_outlined,
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
              onTap: _isSubmitting ? null : _submitAndSearch,
              child: Container(
                height: 52,
                decoration: BoxDecoration(
                  gradient: _isSubmitting
                      ? null
                      : const LinearGradient(
                          colors: [Color(0xFF0262EC), Color(0xFF0485FF)],
                        ),
                  color: _isSubmitting ? Colors.grey[300] : null,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: _isSubmitting
                      ? null
                      : [
                          BoxShadow(
                            color: const Color(0xFF0262EC).withOpacity(0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                ),
                child: Center(
                  child: Text(
                    _isSubmitting
                        ? 'กำลังส่งคำขอ...'
                        : 'ยืนยันและค้นหาทนายความ',
                    style: TextStyle(
                      color: _isSubmitting ? Colors.grey[600] : Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}