import 'package:LawyerOnline/services/notification_navigation_service.dart';
import 'package:LawyerOnline/shared/app_typography.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:LawyerOnline/component/appbar.dart';

class NotificationDetailPage extends StatelessWidget {
  final Map data;

  const NotificationDetailPage({super.key, required this.data});

  static const _kPrimary = Color(0xFF0262EC);

  IconData _iconForType(String? type, String? page) {
    if (type == 'chat_message' || page == 'chat') {
      return Icons.chat_bubble_outline_rounded;
    }
    if (page == 'appointment_detail' || page == 'case_request_detail') {
      return Icons.event_available_rounded;
    }
    if (type == 'lawyer_apply_approved') {
      return Icons.verified_rounded;
    }
    switch (type) {
      case 'booking':
        return Icons.calendar_month_rounded;
      case 'payment':
        return Icons.payment_rounded;
      case 'finish':
        return Icons.task_alt_rounded;
      default:
        return Icons.notifications_none_rounded;
    }
  }

  Color _accentForType(String? type, String? page) {
    if (type == 'chat_message' || page == 'chat') return _kPrimary;
    if (page == 'appointment_detail' || page == 'case_request_detail') {
      return const Color(0xFF7C4DFF);
    }
    if (type == 'lawyer_apply_approved') return const Color(0xFF059669);
    return _kPrimary;
  }

  String _typeLabel(String? type, String? page) {
    if (type == 'chat_message' || page == 'chat') return 'ข้อความ';
    if (page == 'appointment_detail' || page == 'case_request_detail') {
      return 'การนัดหมาย';
    }
    if (type == 'lawyer_apply_approved') return 'ระบบ';
    switch (type) {
      case 'chat':
        return 'ข้อความ';
      case 'booking':
        return 'การนัดหมาย';
      case 'payment':
        return 'การชำระเงิน';
      case 'finish':
        return 'เสร็จสิ้น';
      default:
        return 'การแจ้งเตือนระบบ';
    }
  }

  String _readBody() {
    return data['body']?.toString() ??
        data['detail']?.toString() ??
        data['fullDetail']?.toString() ??
        '';
  }

  @override
  Widget build(BuildContext context) {
    final payload = Map<String, dynamic>.from(data);
    final type = payload['type']?.toString();
    final page = payload['page']?.toString();
    final accent = _accentForType(type, page);
    final body = _readBody();

    return Scaffold(
      backgroundColor: const Color(0xFFEEF2F5),
      appBar: appBarCustom(
        title: 'notificationDetail'.tr(),
        backBtn: true,
        isRightWidget: false,
        backAction: () => Navigator.pop(context),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(.05),
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: accent.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Icon(
                    _iconForType(type, page),
                    color: accent,
                    size: 34,
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  data['title']?.toString() ?? '',
                  textAlign: TextAlign.center,
                  style: AppTypography.prompt(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1A2340),
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: accent.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _typeLabel(type, page),
                    style: AppTypography.prompt(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: accent,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFE8EDF5)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'notificationDetail'.tr(),
                  style: AppTypography.prompt(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: const Color(0xFF1A2340),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  body,
                  style: AppTypography.prompt(
                    fontSize: 15,
                    color: const Color(0xFF334155),
                    height: 1.5,
                  ),
                ),
                if ((data['time']?.toString() ?? '').isNotEmpty) ...[
                  const SizedBox(height: 18),
                  const Divider(height: 1),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(Icons.access_time_rounded,
                          size: 16, color: Colors.grey[500]),
                      const SizedBox(width: 6),
                      Text(
                        data['time']?.toString() ?? '',
                        style: AppTypography.prompt(
                          color: Colors.grey[600],
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 24),
          if (NotificationNavigationService.canNavigate(payload)) ...[
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  final navigated =
                      await NotificationNavigationService.handle(context, payload);
                  if (navigated && context.mounted) {
                    Navigator.pop(context);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: accent,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Text(
                  'ดูรายละเอียด',
                  style: AppTypography.button(color: Colors.white),
                ),
              ),
            ),
            const SizedBox(height: 10),
          ],
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: _kPrimary,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: Text(
                'ok'.tr(),
                style: AppTypography.button(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
