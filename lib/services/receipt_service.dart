import 'dart:typed_data';

import 'package:LawyerOnline/shared/api_provider.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class ReceiptData {
  const ReceiptData({
    required this.receiptNo,
    required this.caseCode,
    required this.userName,
    required this.lawyerName,
    required this.topicTitle,
    required this.subTopicTitle,
    required this.price,
    required this.payType,
    required this.payDate,
    required this.caseDate,
    required this.startTime,
    required this.endTime,
    required this.issuedAt,
  });

  final String receiptNo;
  final String caseCode;
  final String userName;
  final String lawyerName;
  final String topicTitle;
  final String subTopicTitle;
  final String price;
  final String payType;
  final String payDate;
  final String caseDate;
  final String startTime;
  final String endTime;
  final String issuedAt;

  factory ReceiptData.fromJson(Map<String, dynamic> json) => ReceiptData(
        receiptNo: json['receiptNo']?.toString() ?? '',
        caseCode: json['caseCode']?.toString() ?? '',
        userName: json['userName']?.toString() ?? '',
        lawyerName: json['lawyerName']?.toString() ?? '',
        topicTitle: json['topicTitle']?.toString() ?? '',
        subTopicTitle: json['subTopicTitle']?.toString() ?? '',
        price: json['price']?.toString() ?? '',
        payType: json['payType']?.toString() ?? '',
        payDate: json['payDate']?.toString() ?? '',
        caseDate: json['caseDate']?.toString() ?? '',
        startTime: json['startTime']?.toString() ?? '',
        endTime: json['endTime']?.toString() ?? '',
        issuedAt: json['issuedAt']?.toString() ?? '',
      );
}

class ReceiptService {
  ReceiptService._();

  static const _logoAsset = 'assets/icons/logo.png';

  static Future<ReceiptData?> load(String caseCode) async {
    final result = await postDio('${server}/m/receipt/read', {
      'caseCode': caseCode,
    });
    if (result['status'] != 'S') return null;
    final raw = result['objectData'];
    if (raw is! Map) return null;
    return ReceiptData.fromJson(Map<String, dynamic>.from(raw));
  }

  static Future<String?> loadHtml(String caseCode) async {
    final result = await postDio('${server}/m/receipt/html', {
      'caseCode': caseCode,
    });
    if (result['status'] != 'S') return null;
    return result['objectData']?['html']?.toString();
  }

  static Future<Uint8List> generatePdf(ReceiptData data) async {
    final regular = await PdfGoogleFonts.notoSansThaiRegular();
    final semibold = await PdfGoogleFonts.notoSansThaiSemiBold();
    final bold = await PdfGoogleFonts.notoSansThaiBold();
    final logoBytes =
        (await rootBundle.load(_logoAsset)).buffer.asUint8List();
    final logoImage = pw.MemoryImage(logoBytes);
    final document = pw.Document(
      title: 'ใบเสร็จ ${data.receiptNo}',
      author: 'Lawyer Online',
    );

    const primary = PdfColor.fromInt(0xFF0262EC);
    const ink = PdfColor.fromInt(0xFF17223B);
    const muted = PdfColor.fromInt(0xFF718096);
    const line = PdfColor.fromInt(0xFFE8EEF6);
    const softBlue = PdfColor.fromInt(0xFFF2F7FF);

    pw.TextStyle text(
      double size, {
      PdfColor color = ink,
      pw.Font? font,
    }) =>
        pw.TextStyle(font: font ?? regular, fontSize: size, color: color);

    pw.Widget row(String label, String value) => pw.Padding(
          padding: const pw.EdgeInsets.symmetric(vertical: 7),
          child: pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.SizedBox(
                width: 118,
                child: pw.Text(label, style: text(10, color: muted)),
              ),
              pw.Expanded(
                child: pw.Text(
                  value.trim().isEmpty ? '-' : value,
                  style: text(10.5, font: semibold),
                ),
              ),
            ],
          ),
        );

    document.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(36),
        theme: pw.ThemeData.withFont(base: regular, bold: bold),
        footer: (context) => pw.Container(
          padding: const pw.EdgeInsets.only(top: 12),
          decoration: const pw.BoxDecoration(
            border: pw.Border(top: pw.BorderSide(color: line, width: .7)),
          ),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('Lawyer Online', style: text(8.5, color: muted)),
              pw.Text(
                'หน้า ${context.pageNumber}/${context.pagesCount}',
                style: text(8.5, color: muted),
              ),
            ],
          ),
        ),
        build: (_) => [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Row(
                children: [
                  pw.Container(
                    width: 42,
                    height: 42,
                    decoration: pw.BoxDecoration(
                      color: PdfColors.white,
                      borderRadius: pw.BorderRadius.circular(12),
                    ),
                    padding: const pw.EdgeInsets.all(5),
                    child: pw.Image(
                      logoImage,
                      fit: pw.BoxFit.contain,
                    ),
                  ),
                  pw.SizedBox(width: 12),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'LAWYER ONLINE',
                        style: text(15, color: primary, font: bold),
                      ),
                      pw.Text(
                        'บริการปรึกษากฎหมายออนไลน์',
                        style: text(9, color: muted),
                      ),
                    ],
                  ),
                ],
              ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text('ใบเสร็จรับเงิน', style: text(20, font: bold)),
                  pw.SizedBox(height: 4),
                  pw.Text(data.receiptNo, style: text(9.5, color: primary)),
                ],
              ),
            ],
          ),
          pw.SizedBox(height: 26),
          pw.Container(
            padding: const pw.EdgeInsets.all(18),
            decoration: pw.BoxDecoration(
              color: softBlue,
              borderRadius: pw.BorderRadius.circular(14),
              border: pw.Border.all(color: line),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('สถานะการชำระเงิน', style: text(9, color: muted)),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      'ชำระเงินเรียบร้อย',
                      style: text(12, color: primary, font: bold),
                    ),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text('ยอดชำระสุทธิ', style: text(9, color: muted)),
                    pw.SizedBox(height: 3),
                    pw.Text(
                      '฿${_formatAmount(data.price)}',
                      style: text(22, color: primary, font: bold),
                    ),
                  ],
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 22),
          pw.Text('ข้อมูลการชำระเงิน', style: text(12, font: bold)),
          pw.SizedBox(height: 7),
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 14, vertical: 5),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: line),
              borderRadius: pw.BorderRadius.circular(12),
            ),
            child: pw.Column(
              children: [
                row('เลขที่ใบเสร็จ', data.receiptNo),
                pw.Divider(color: line, height: 1),
                row('ออกเมื่อ', data.issuedAt),
                pw.Divider(color: line, height: 1),
                row('ช่องทางชำระ', _payTypeLabel(data.payType)),
                pw.Divider(color: line, height: 1),
                row('วันที่ชำระ', data.payDate),
              ],
            ),
          ),
          pw.SizedBox(height: 20),
          pw.Text('รายละเอียดการปรึกษา', style: text(12, font: bold)),
          pw.SizedBox(height: 7),
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 14, vertical: 5),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: line),
              borderRadius: pw.BorderRadius.circular(12),
            ),
            child: pw.Column(
              children: [
                row('รหัสเคส', data.caseCode),
                pw.Divider(color: line, height: 1),
                row('ลูกความ', data.userName),
                pw.Divider(color: line, height: 1),
                row('ทนายความ', data.lawyerName),
                pw.Divider(color: line, height: 1),
                row('หัวข้อ', data.topicTitle),
                pw.Divider(color: line, height: 1),
                row('หัวข้อย่อย', data.subTopicTitle),
                pw.Divider(color: line, height: 1),
                row('วันนัดหมาย', data.caseDate),
                pw.Divider(color: line, height: 1),
                row('เวลา', '${data.startTime} - ${data.endTime}'),
              ],
            ),
          ),
          pw.SizedBox(height: 24),
          pw.Center(
            child: pw.Text(
              'เอกสารนี้ออกโดยระบบ Lawyer Online สำหรับอ้างอิงการชำระเงิน',
              style: text(8.5, color: muted),
            ),
          ),
        ],
      ),
    );

    return document.save();
  }

  static Future<void> downloadAndShare(
    String caseCode, {
    ReceiptData? data,
  }) async {
    final receipt = data ?? await load(caseCode);
    if (receipt == null) {
      throw StateError('Receipt not available');
    }
    final bytes = await generatePdf(receipt);
    final safeNo = receipt.receiptNo.replaceAll(RegExp(r'[^A-Za-z0-9_-]'), '_');
    await Printing.sharePdf(
      bytes: bytes,
      filename: '$safeNo.pdf',
    );
  }

  static String _formatAmount(String raw) {
    final value = double.tryParse(raw.replaceAll(',', '').trim());
    if (value == null) return raw.isEmpty ? '0.00' : raw;
    final fixed = value.toStringAsFixed(2);
    final parts = fixed.split('.');
    final chars = parts.first.split('').reversed.toList();
    final groups = <String>[];
    for (var i = 0; i < chars.length; i += 3) {
      groups.add(chars.skip(i).take(3).toList().reversed.join());
    }
    return '${groups.reversed.join(',')}.${parts.last}';
  }

  static String _payTypeLabel(String raw) {
    switch (raw.trim().toLowerCase()) {
      case 'promptpay':
        return 'พร้อมเพย์';
      case 'credit_card':
      case 'card':
        return 'บัตรเครดิต/เดบิต';
      default:
        return raw.isEmpty ? '-' : raw;
    }
  }
}
