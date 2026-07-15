import 'dart:io';

import 'package:LawyerOnline/shared/api_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

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

  static Future<void> downloadAndShare(String caseCode) async {
    final html = await loadHtml(caseCode);
    if (html == null || html.isEmpty) return;

    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/receipt_$caseCode.html');
    await file.writeAsString(html, flush: true);

    await Share.shareXFiles(
      [XFile(file.path)],
      subject: 'ใบเสร็จ $caseCode',
    );
  }
}
