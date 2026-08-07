import 'package:LawyerOnline/component/appbar.dart';
import 'package:LawyerOnline/consult/consult_status.dart';
import 'package:LawyerOnline/services/case_request_service.dart';
import 'package:LawyerOnline/services/case_service.dart';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:easy_localization/easy_localization.dart';

class ConsultQrPage extends StatefulWidget {
  final int amount;
  final dynamic lawyer;

  // ── field ชุดใหม่ที่ตกลงกัน ──────────────────────────────────────────────
  final String? topic;
  final String? topicTitle;
  final String? subTopic;
  final String? subTopicTitle;
  final String? province;
  final String? detail;
  final String? demand;

  // ประเภทเคส: 1=นัดล่วงหน้า, 2=ด่วน
  final int caseType;

  // broadcast flow: requestCode != null
  // direct flow: requestCode == null
  final String? requestCode;
  final dynamic paymentInfo;

  const ConsultQrPage({
    super.key,
    required this.amount,
    required this.lawyer,
    this.topic,
    this.topicTitle,
    this.subTopic,
    this.subTopicTitle,
    this.province,
    this.detail,
    this.demand,
    this.caseType = 2,
    this.requestCode,
    this.paymentInfo,
  });

  @override
  State<ConsultQrPage> createState() => _ConsultQrPageState();
}

class _ConsultQrPageState extends State<ConsultQrPage> {
  bool _isProcessing = false;
  final CaseRequestService _caseReqService = CaseRequestService();

  String _generatePromptPayPayload(int amount) {
    final amountStr = amount.toDouble().toStringAsFixed(2);
    const phoneNumber = '0812345678';
    return '00020101021129370016A000000677010111011300668'
        '${phoneNumber.replaceFirst('0', '')}'
        '5303764540${amountStr}5802TH5920LawyerOnline Payment6304';
  }

  String _formatAmount(int amount) => amount
      .toString()
      .replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');

  Future<void> _onPaymentConfirmed() async {
    setState(() => _isProcessing = true);
    try {
      String caseCode;

      if (widget.requestCode != null) {
        final result = await _caseReqService.confirmPayment(
          requestCode: widget.requestCode!,
          price: widget.amount.toString(),
        );

        // ✅ log ดูค่าจริงจาก API

        if (result['success'] != true) {
          throw Exception(
            result['message']?.toString() ?? 'consultConfirmPaymentFailed'.tr(),
          );
        }

        final caseMap = result['case'];

        // ✅ รองรับทั้ง Map และ String
        if (caseMap is Map) {
          caseCode = caseMap['code']?.toString() ?? '';
        } else if (caseMap is String) {
          caseCode = caseMap;
        } else {
          caseCode = '';
        }

        // ✅ ถ้า caseCode ยังว่าง ลอง parse จาก objectData โดยตรง
        if (caseCode.isEmpty) {
          final raw = result['objectData'];
          if (raw is Map) {
            caseCode = raw['code']?.toString() ?? '';
          }
        }

        if (caseCode.isEmpty) {
          throw Exception('consultNoCaseAfterPay'.tr());
        }
      } else {
        final lawyerMap =
            Map<String, dynamic>.from((widget.lawyer as Map?) ?? {});
        caseCode = await CaseService.createAppointmentCase(
          lawyerCode: lawyerMap['code']?.toString() ?? '',
          topic: widget.topic ?? '',
          topicTitle: widget.topicTitle ?? '',
          subTopic: widget.subTopic ?? '',
          subTopicTitle: widget.subTopicTitle ?? '',
          province: widget.province ?? '',
          detail: widget.detail ?? '',
          demand: widget.demand ?? '',
          caseType: widget.caseType,
        );

        if (caseCode.isEmpty) {
          throw Exception('consultCannotCreateCase'.tr());
        }
      }

      if (!mounted) return;

      // ✅ navigate เฉพาะเมื่อ caseCode ไม่ว่าง
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => ConsultStatusPage(caseCode: caseCode),
        ),
      );
    } catch (e) {
      print('❌ _onPaymentConfirmed error: $e');
      if (!mounted) return;
      setState(() => _isProcessing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: const Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final payload = _generatePromptPayPayload(widget.amount);

    return Scaffold(
      backgroundColor: const Color(0xFFEEF2F5),
      appBar: appBar(
        title: 'consultPaymentTitle'.tr(),
        backBtn: true,
        rightBtn: false,
        rightAction: () {},
        backAction: () => Navigator.pop(context),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(children: [
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
                    offset: const Offset(0, 4))
              ],
            ),
            child: Column(children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                decoration: BoxDecoration(
                    color: const Color(0xFFEEF4FF),
                    borderRadius: BorderRadius.circular(12)),
                child: const Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.qr_code_2_outlined,
                      color: Color(0xFF0262EC), size: 20),
                  SizedBox(width: 8),
                  Text('PromptPay',
                      style: TextStyle(
                          color: Color(0xFF0262EC),
                          fontWeight: FontWeight.bold,
                          fontSize: 16)),
                ]),
              ),
              const SizedBox(height: 24),
              QrImageView(
                data: payload,
                version: QrVersions.auto,
                size: 220,
                eyeStyle: const QrEyeStyle(
                    eyeShape: QrEyeShape.square, color: Color(0xFF0262EC)),
                dataModuleStyle: const QrDataModuleStyle(
                    dataModuleShape: QrDataModuleShape.square,
                    color: Color(0xFF1A2340)),
              ),
              const SizedBox(height: 20),
              const Divider(color: Color(0xFFEEF2F5)),
              const SizedBox(height: 16),
              Text('amountDue'.tr(),
                  style: TextStyle(color: Colors.grey[400], fontSize: 13)),
              const SizedBox(height: 6),
              Text('฿${_formatAmount(widget.amount)}',
                  style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0262EC))),
            ]),
          ),
          const SizedBox(height: 20),
          GestureDetector(
            onTap: _isProcessing ? null : _onPaymentConfirmed,
            child: Container(
              height: 52,
              decoration: BoxDecoration(
                gradient: _isProcessing
                    ? null
                    : const LinearGradient(
                        colors: [Color(0xFF0262EC), Color(0xFF0485FF)]),
                color: _isProcessing ? Colors.grey[300] : null,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Center(
                child: _isProcessing
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : Text('consultCheckPayment'.tr(),
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 15)),
              ),
            ),
          ),
        ]),
      ),
    );
  }
}
