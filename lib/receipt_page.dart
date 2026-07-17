import 'package:LawyerOnline/component/dialog_service.dart';
import 'package:LawyerOnline/component/loading_service.dart';
import 'package:LawyerOnline/services/receipt_service.dart';
import 'package:LawyerOnline/shared/app_typography.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ReceiptPage extends StatefulWidget {
  final String caseCode;

  const ReceiptPage({super.key, required this.caseCode});

  @override
  State<ReceiptPage> createState() => _ReceiptPageState();
}

class _ReceiptPageState extends State<ReceiptPage> {
  static const _primary = Color(0xFF0262EC);
  static const _ink = Color(0xFF17223B);
  static const _muted = Color(0xFF718096);
  static const _line = Color(0xFFE8EEF6);
  static const _background = Color(0xFFF5F8FC);

  bool _loading = true;
  bool _downloading = false;
  ReceiptData? _data;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final data = await ReceiptService.load(widget.caseCode);
      if (mounted) {
        setState(() => _data = data);
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _download() async {
    final data = _data;
    if (data == null || _downloading) return;
    setState(() => _downloading = true);
    try {
      await ReceiptService.downloadAndShare(widget.caseCode, data: data);
    } catch (_) {
      if (!mounted) return;
      DialogService.showError(
        context,
        title: 'errorTitle'.tr(),
        message: 'receiptDownloadFailed'.tr(),
      );
    } finally {
      if (mounted) setState(() => _downloading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        leadingWidth: 64,
        leading: Padding(
          padding: const EdgeInsets.only(left: 16),
          child: _circleButton(
            icon: Icons.arrow_back_ios_new_rounded,
            onTap: () => Navigator.pop(context),
          ),
        ),
        centerTitle: true,
        title: Text(
          'receiptTitle'.tr(),
          style: AppTypography.prompt(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: _ink,
          ),
        ),
        actions: [
          if (_data != null)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: _circleButton(
                icon: Icons.ios_share_rounded,
                onTap: _downloading ? null : _download,
              ),
            ),
        ],
      ),
      body: _loading
          ? const AppLoadingView()
          : _data == null
              ? _emptyState()
              : _receiptBody(_data!),
      bottomNavigationBar: _data == null
          ? null
          : SafeArea(
              top: false,
              child: Container(
                padding: const EdgeInsets.fromLTRB(18, 12, 18, 14),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  border: Border(top: BorderSide(color: _line)),
                ),
                child: SizedBox(
                  height: 54,
                  child: ElevatedButton(
                    onPressed: _downloading ? null : _download,
                    style: ElevatedButton.styleFrom(
                      elevation: 0,
                      backgroundColor: _primary,
                      disabledBackgroundColor: _primary.withOpacity(.55),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: _downloading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.4,
                              color: Colors.white,
                            ),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.picture_as_pdf_rounded,
                                size: 21,
                              ),
                              const SizedBox(width: 9),
                              Text(
                                'ดาวน์โหลดเป็นไฟล์ PDF',
                                style: AppTypography.button(fontSize: 15),
                              ),
                            ],
                          ),
                  ),
                ),
              ),
            ),
    );
  }

  Widget _receiptBody(ReceiptData data) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 28),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _headerCard(data),
              const SizedBox(height: 16),
              _sectionCard(
                title: 'ข้อมูลการชำระเงิน',
                icon: Icons.account_balance_wallet_rounded,
                children: [
                  _detailRow('เลขที่ใบเสร็จ', data.receiptNo, canCopy: true),
                  _divider(),
                  _detailRow('ออกเมื่อ', data.issuedAt),
                  _divider(),
                  _detailRow('ช่องทางชำระ', _payTypeLabel(data.payType)),
                  _divider(),
                  _detailRow('วันที่ชำระ', _display(data.payDate)),
                ],
              ),
              const SizedBox(height: 16),
              _sectionCard(
                title: 'รายละเอียดการปรึกษา',
                icon: Icons.gavel_rounded,
                children: [
                  _detailRow('รหัสเคส', data.caseCode, canCopy: true),
                  _divider(),
                  _detailRow('ลูกความ', _display(data.userName)),
                  _divider(),
                  _detailRow('ทนายความ', _display(data.lawyerName)),
                  _divider(),
                  _detailRow('หัวข้อ', _display(data.topicTitle)),
                  if (data.subTopicTitle.trim().isNotEmpty) ...[
                    _divider(),
                    _detailRow('หัวข้อย่อย', data.subTopicTitle),
                  ],
                  _divider(),
                  _detailRow('วันนัดหมาย', _display(data.caseDate)),
                  _divider(),
                  _detailRow(
                    'เวลา',
                    '${_display(data.startTime)} - ${_display(data.endTime)}',
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFEEF6FF),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.verified_user_outlined,
                      color: _primary,
                      size: 19,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'เอกสารนี้ออกโดยระบบ Lawyer Online สำหรับอ้างอิงการชำระเงิน',
                        style: AppTypography.prompt(
                          fontSize: 11.5,
                          height: 1.45,
                          color: const Color(0xFF476582),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _headerCard(ReceiptData data) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0262EC), Color(0xFF087FF5)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: _primary.withOpacity(.22),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -32,
            top: -42,
            child: Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(.08),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      padding: const EdgeInsets.all(6),
                      child: Image.asset(
                        'assets/icons/logo.png',
                        fit: BoxFit.contain,
                      ),
                    ),
                    const SizedBox(width: 13),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'ใบเสร็จรับเงิน',
                            style: AppTypography.prompt(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            data.receiptNo,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.prompt(
                              fontSize: 11.5,
                              color: Colors.white.withOpacity(.78),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(.16),
                        borderRadius: BorderRadius.circular(99),
                        border: Border.all(
                          color: Colors.white.withOpacity(.2),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.check_circle_rounded,
                            color: Color(0xFFB7F7D0),
                            size: 14,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            'ชำระแล้ว',
                            style: AppTypography.prompt(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 28),
                Text(
                  'ยอดชำระสุทธิ',
                  style: AppTypography.prompt(
                    fontSize: 12,
                    color: Colors.white.withOpacity(.76),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '฿${_formatAmount(data.price)}',
                  style: AppTypography.prompt(
                    fontSize: 30,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    height: 1.2,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.fromLTRB(17, 17, 17, 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _line),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF263A5A).withOpacity(.05),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFFEEF6FF),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(icon, color: _primary, size: 19),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Text(
                  title,
                  style: AppTypography.prompt(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                    color: _ink,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 9),
          ...children,
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value, {bool canCopy = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 11),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 112,
            child: Text(
              label,
              style: AppTypography.prompt(fontSize: 11.5, color: _muted),
            ),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: AppTypography.prompt(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: _ink,
                height: 1.4,
              ),
            ),
          ),
          if (canCopy) ...[
            const SizedBox(width: 6),
            InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () {
                Clipboard.setData(ClipboardData(text: value));
                ScaffoldMessenger.of(context)
                  ..hideCurrentSnackBar()
                  ..showSnackBar(
                    SnackBar(
                      content: Text(
                        'คัดลอกแล้ว',
                        style: AppTypography.prompt(
                          fontSize: 12,
                          color: Colors.white,
                        ),
                      ),
                      behavior: SnackBarBehavior.floating,
                      duration: const Duration(seconds: 1),
                    ),
                  );
              },
              child: const Padding(
                padding: EdgeInsets.all(4),
                child: Icon(Icons.copy_rounded, size: 14, color: _muted),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _divider() => const Divider(height: 1, color: _line);

  Widget _circleButton({
    required IconData icon,
    required VoidCallback? onTap,
  }) {
    return Material(
      color: const Color(0xFFF1F5FA),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 40,
          height: 40,
          child: Icon(icon, size: 18, color: _ink),
        ),
      ),
    );
  }

  Widget _emptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 76,
              height: 76,
              decoration: const BoxDecoration(
                color: Color(0xFFEEF6FF),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.receipt_long_outlined,
                size: 34,
                color: _primary,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'receiptNotAvailable'.tr(),
              textAlign: TextAlign.center,
              style: AppTypography.prompt(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: _ink,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'ใบเสร็จจะแสดงหลังจากระบบยืนยันการชำระเงินแล้ว',
              textAlign: TextAlign.center,
              style: AppTypography.prompt(fontSize: 11.5, color: _muted),
            ),
          ],
        ),
      ),
    );
  }

  String _display(String value) => value.trim().isEmpty ? '-' : value;

  String _formatAmount(String raw) {
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

  String _payTypeLabel(String raw) {
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
