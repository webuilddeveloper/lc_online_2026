import 'package:LawyerOnline/component/appbar.dart';
import 'package:LawyerOnline/component/dialog_service.dart';
import 'package:LawyerOnline/component/loading_service.dart';
import 'package:LawyerOnline/services/receipt_service.dart';
import 'package:LawyerOnline/shared/app_typography.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';

class ReceiptPage extends StatefulWidget {
  final String caseCode;

  const ReceiptPage({super.key, required this.caseCode});

  @override
  State<ReceiptPage> createState() => _ReceiptPageState();
}

class _ReceiptPageState extends State<ReceiptPage> {
  bool _loading = true;
  ReceiptData? _data;
  String? _html;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final data = await ReceiptService.load(widget.caseCode);
      final html = await ReceiptService.loadHtml(widget.caseCode);
      if (mounted) {
        setState(() {
          _data = data;
          _html = html;
        });
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _download() async {
    try {
      await ReceiptService.downloadAndShare(widget.caseCode);
    } catch (_) {
      if (!mounted) return;
      DialogService.showError(
        context,
        title: 'errorTitle'.tr(),
        message: 'receiptDownloadFailed'.tr(),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: appBar(
        title: 'receiptTitle'.tr(),
        backBtn: true,
        rightBtn: _data != null,
        backAction: () => Navigator.pop(context),
        rightAction: _download,
      ),
      body: _loading
          ? const AppLoadingView()
          : _data == null
              ? Center(
                  child: Text(
                    'receiptNotAvailable'.tr(),
                    style: AppTypography.prompt(color: Colors.grey),
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (_html != null && _html!.isNotEmpty)
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Html(data: _html!),
                          ),
                        ),
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 48,
                        child: ElevatedButton.icon(
                          onPressed: _download,
                          icon: const Icon(Icons.download_rounded),
                          label: Text('receiptDownload'.tr()),
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }
}
