import 'package:LawyerOnline/component/appbar.dart';
import 'package:LawyerOnline/models/user_profile_store.dart';
import 'package:LawyerOnline/notification-detail.dart';
import 'package:LawyerOnline/services/notification_navigation_service.dart';
import 'package:LawyerOnline/shared/api_provider.dart';
import 'package:LawyerOnline/shared/app_typography.dart';
import 'package:LawyerOnline/component/loading_service.dart';
import 'package:LawyerOnline/shared/notification_store.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:hms_room_kit/hms_room_kit.dart';
import 'package:permission_handler/permission_handler.dart';

/// Mock data สำหรับ notification dropdown (ยังไม่ได้ผูก API)
List<Map<String, dynamic>> globalNotifications = [
  {
    "type": "call",
    "title": "สายที่ไม่ได้รับ",
    "detail": "คุณไม่ได้รับสายจากทนายศักดิ์สิทธิ์",
    "time": "10:19",
    "date": "today",
    "isRead": false,
    "fullDetail":
        "คุณไม่ได้รับสายจากทนายศักดิ์สิทธิ์เมื่อเวลา 10:19 น. กรุณาติดต่อกลับเมื่อสะดวก"
  },
  {
    "type": "booking",
    "title": "นัดหมายคดี",
    "detail": "คดีความกำลังจะมาถึง",
    "time": "10:20",
    "date": "today",
    "isRead": false,
    "fullDetail":
        "การนัดหมายปรึกษาคดีของคุณกับทนายศักดิ์สิทธิ์ ได้รับการยืนยันแล้ว กรุณาเตรียมเอกสารที่เกี่ยวข้องให้พร้อมก่อนถึงเวลานัดหมาย"
  },
];

class NotificationPage extends StatefulWidget {
  const NotificationPage({super.key});

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  static const _kPrimary = Color(0xFF0262EC);
  static const _kBg = Color(0xFFEEF2F5);

  List<Map<String, dynamic>> _notifications = [];
  bool _isLoading = true;

  int get unreadCount =>
      _notifications.where((n) => n['isRead'] != true).length;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    final code = UserProfileStore.instance.code;
    if (code.isEmpty) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    try {
      final result = await postDio('$server/m/notification/read', {
        'code': code,
        'skip': 0,
        'limit': 50,
      });

      if (!mounted) return;

      final raw = result['objectData'];
      final list = raw is List
          ? raw
              .whereType<Map>()
              .map((e) => Map<String, dynamic>.from(e))
              .toList()
          : <Map<String, dynamic>>[];

      setState(() {
        _notifications = list;
        _isLoading = false;
      });

      final total = result['totalData'];
      if (total != null) {
        NotificationStore.instance.setUnread(
          total is int
              ? total
              : int.tryParse(total.toString()) ?? unreadCount,
        );
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _markAllRead() async {
    if (_notifications.isEmpty) return;

    setState(() {
      for (final n in _notifications) {
        n['isRead'] = true;
      }
    });

    await NotificationStore.instance.markAllRead();
    await NotificationStore.instance.refresh();
  }

  Future<void> _markOneRead(Map<String, dynamic> item) async {
    if (item['isRead'] == true) return;

    setState(() => item['isRead'] = true);

    final code = item['code']?.toString();
    if (code != null && code.isNotEmpty) {
      try {
        await postDio('$server/m/notification/markRead', {'code': code});
        await NotificationStore.instance.refresh();
      } catch (_) {}
    }
  }

  Map<String, dynamic> _toDetailData(Map<String, dynamic> item) {
    return {
      'type': item['type'] ?? item['page'] ?? 'system',
      'title': item['title']?.toString() ?? '',
      'detail': item['body']?.toString() ?? '',
      'body': item['body']?.toString() ?? '',
      'time': _formatTime(item),
      'fullDetail': item['body']?.toString() ?? '',
      'page': item['page']?.toString() ?? '',
      'refCode': item['refCode']?.toString() ?? '',
    };
  }

  DateTime? _parseDate(Map<String, dynamic> item) {
    final raw = item['docDate'];
    if (raw is DateTime) return raw;
    if (raw is String && raw.isNotEmpty) {
      return DateTime.tryParse(raw);
    }
    final date = item['createDate']?.toString() ?? '';
    final time = item['createTime']?.toString() ?? '';
    if (date.length >= 8) {
      try {
        final y = int.parse(date.substring(0, 4));
        final m = int.parse(date.substring(4, 6));
        final d = int.parse(date.substring(6, 8));
        int h = 0, min = 0;
        if (time.length >= 4) {
          h = int.tryParse(time.substring(0, 2)) ?? 0;
          min = int.tryParse(time.substring(2, 4)) ?? 0;
        }
        return DateTime(y, m, d, h, min);
      } catch (_) {}
    }
    return null;
  }

  String _dateGroup(Map<String, dynamic> item) {
    final dt = _parseDate(item);
    if (dt == null) return 'old';

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final itemDay = DateTime(dt.year, dt.month, dt.day);
    final diff = today.difference(itemDay).inDays;

    if (diff == 0) return 'today';
    if (diff == 1) return 'yesterday';
    return 'old';
  }

  String _formatTime(Map<String, dynamic> item) {
    final dt = _parseDate(item);
    if (dt != null) {
      return DateFormat('HH:mm').format(dt);
    }
    final time = item['createTime']?.toString() ?? '';
    if (time.length >= 4) {
      return '${time.substring(0, 2)}:${time.substring(2, 4)}';
    }
    return '';
  }

  _NotificationStyle _styleFor(Map<String, dynamic> item) {
    final type = item['type']?.toString() ?? '';
    final page = item['page']?.toString() ?? '';

    if (type == 'chat_message' || page == 'chat') {
      return const _NotificationStyle(
        Icons.chat_bubble_outline_rounded,
        Color(0xFF0262EC),
        Color(0xFFE8F1FF),
      );
    }
    if (page == 'appointment_detail' ||
        page == 'case_request_detail' ||
        type.contains('case') ||
        type.contains('payment') ||
        type == 'session_end') {
      return const _NotificationStyle(
        Icons.event_available_rounded,
        Color(0xFF7C4DFF),
        Color(0xFFF0EBFF),
      );
    }
    if (type == 'lawyer_apply_approved') {
      return const _NotificationStyle(
        Icons.verified_rounded,
        Color(0xFF059669),
        Color(0xFFE8F8F1),
      );
    }
    if (page == 'community') {
      return const _NotificationStyle(
        Icons.groups_rounded,
        Color(0xFFE65100),
        Color(0xFFFFF3E8),
      );
    }
    if (type == 'call') {
      return const _NotificationStyle(
        Icons.call_end_rounded,
        Color(0xFFC62828),
        Color(0xFFFFEBEE),
      );
    }
    return const _NotificationStyle(
      Icons.notifications_none_rounded,
      Color(0xFF5B6E8A),
      Color(0xFFF1F5FB),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      appBar: appBarCustom(
        title: 'notifications'.tr(),
        backBtn: true,
        isRightWidget: unreadCount > 0,
        backAction: () => Navigator.pop(context),
        rightWidget: unreadCount > 0
            ? GestureDetector(
                onTap: _markAllRead,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFE2E8F4)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.done_all_rounded,
                          size: 14, color: _kPrimary),
                      const SizedBox(width: 4),
                      Text(
                        'markAllRead'.tr(),
                        style: AppTypography.prompt(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: _kPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            : null,
      ),
      body: _isLoading
          ? AppLoadingView(message: 'loading'.tr())
          : RefreshIndicator(
              color: _kPrimary,
              onRefresh: _loadNotifications,
              child: _notifications.isEmpty
                  ? ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [_buildEmptyState()],
                    )
                  : ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                      children: [
                        if (unreadCount > 0) ...[
                          _buildUnreadBanner(),
                          const SizedBox(height: 16),
                        ],
                        _buildSection('timeline.today'.tr(), 'today'),
                        _buildSection('timeline.yesterday'.tr(), 'yesterday'),
                        _buildSection('timeline.earlier'.tr(), 'old'),
                      ],
                    ),
            ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 80, 24, 24),
      child: Column(
        children: [
          Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              color: _kPrimary.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.notifications_none_rounded,
              size: 40,
              color: _kPrimary,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'noNotifications'.tr(),
            style: AppTypography.prompt(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1A2340),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'noNotificationsDesc'.tr(),
            textAlign: TextAlign.center,
            style: AppTypography.prompt(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUnreadBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0262EC), Color(0xFF0099FF)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: _kPrimary.withOpacity(0.25),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.mark_email_unread_rounded,
                color: Colors.white, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'unreadNotifications'.tr(),
                  style: AppTypography.prompt(
                    fontSize: 12,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
                Text(
                  '$unreadCount',
                  style: AppTypography.prompt(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, String group) {
    final items =
        _notifications.where((n) => _dateGroup(n) == group).toList();
    if (items.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 10, top: 8),
          child: Text(
            title,
            style: AppTypography.prompt(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF64748B),
            ),
          ),
        ),
        ...items.map(_buildNotificationCard),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildNotificationCard(Map<String, dynamic> item) {
    final isRead = item['isRead'] == true;
    final style = _styleFor(item);
    final time = _formatTime(item);
    final body = item['body']?.toString() ?? '';

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () async {
            await _markOneRead(item);

            final type = item['type']?.toString() ?? '';
            if (type == 'call') {
              if (!mounted) return;
              showIncomingCallOverlay(context, item['title']?.toString() ?? '');
              return;
            }

            if (!mounted) return;
            final navigated =
                await NotificationNavigationService.handle(context, item);
            if (!navigated && mounted) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      NotificationDetailPage(data: _toDetailData(item)),
                ),
              );
            }
          },
          child: Ink(
            decoration: BoxDecoration(
              color: isRead ? Colors.white : const Color(0xFFF5F9FF),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: isRead
                    ? const Color(0xFFE8EDF5)
                    : _kPrimary.withOpacity(0.25),
                width: isRead ? 1 : 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!isRead)
                  Container(
                    width: 4,
                    height: 88,
                    decoration: const BoxDecoration(
                      color: _kPrimary,
                      borderRadius: BorderRadius.horizontal(
                        left: Radius.circular(18),
                      ),
                    ),
                  ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 46,
                          height: 46,
                          decoration: BoxDecoration(
                            color: style.bg,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Icon(style.icon, color: style.color, size: 22),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Text(
                                      item['title']?.toString() ?? '',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: AppTypography.prompt(
                                        fontSize: 14,
                                        fontWeight: isRead
                                            ? FontWeight.w600
                                            : FontWeight.w700,
                                        color: const Color(0xFF1A2340),
                                      ),
                                    ),
                                  ),
                                  if (time.isNotEmpty) ...[
                                    const SizedBox(width: 8),
                                    Text(
                                      time,
                                      style: AppTypography.prompt(
                                        fontSize: 11,
                                        color: Colors.grey[500],
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              if (body.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(
                                  body,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTypography.prompt(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                    height: 1.4,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        if (!isRead) ...[
                          const SizedBox(width: 8),
                          Container(
                            width: 8,
                            height: 8,
                            margin: const EdgeInsets.only(top: 4),
                            decoration: const BoxDecoration(
                              color: _kPrimary,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> showIncomingCallOverlay(
      BuildContext context, String lawyerName) async {
    late OverlayEntry overlay;
    final player = AudioPlayer();

    await player.setReleaseMode(ReleaseMode.loop);
    await player.play(AssetSource('incoming_call.mp3'));

    final key = GlobalKey<_IncomingCallOverlayState>();

    overlay = OverlayEntry(
      builder: (context) => _IncomingCallOverlay(
        key: key,
        lawyerName: lawyerName,
        onDecline: () async {
          await player.stop();
          await key.currentState?.dismiss();
          overlay.remove();
        },
        onAccept: () async {
          await player.stop();
          await key.currentState?.dismiss();
          overlay.remove();
          if (context.mounted) _showReminderBeforeJoin(context);
        },
      ),
    );

    Overlay.of(context).insert(overlay);

    Future.delayed(const Duration(seconds: 10), () async {
      if (overlay.mounted) {
        await player.stop();
        await key.currentState?.dismiss();
        if (overlay.mounted) overlay.remove();
      }
    });
  }

  void _showReminderBeforeJoin(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('notification.pre_consultation_instruction'.tr()),
        content: Text('notification.pre_consultation_instruction_message'.tr()),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('cancel'.tr()),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();

              final statuses = await [
                Permission.camera,
                Permission.microphone,
              ].request();

              if (statuses.values.any((s) => s.isPermanentlyDenied)) {
                if (!context.mounted) return;
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: Text('permission.title'.tr()),
                    content: Text('permission.content'.tr()),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: Text('cancel'.tr()),
                      ),
                      TextButton(
                        onPressed: openAppSettings,
                        child: Text('permission.open_settings'.tr()),
                      ),
                    ],
                  ),
                );
                return;
              }

              final allGranted =
                  statuses.values.every((status) => status.isGranted);

              if (!context.mounted) return;
              if (allGranted) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => HMSPrebuilt(
                      roomCode: 'jle-wjbx-gyk',
                    ),
                  ),
                );
              } else {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: Text('notification.permission_denied_title'.tr()),
                    content:
                        Text('notification.permission_denied_content'.tr()),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: Text('confirm'.tr()),
                      ),
                    ],
                  ),
                );
              }
            },
            child: Text('notification.join_now'.tr()),
          ),
        ],
      ),
    );
  }
}

class _NotificationStyle {
  final IconData icon;
  final Color color;
  final Color bg;

  const _NotificationStyle(this.icon, this.color, this.bg);
}

class _IncomingCallOverlay extends StatefulWidget {
  final String lawyerName;
  final VoidCallback onDecline;
  final VoidCallback onAccept;

  const _IncomingCallOverlay({
    super.key,
    required this.lawyerName,
    required this.onDecline,
    required this.onAccept,
  });

  @override
  State<_IncomingCallOverlay> createState() => _IncomingCallOverlayState();
}

class _IncomingCallOverlayState extends State<_IncomingCallOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<Offset> _slide;
  late Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );
    _slide = Tween<Offset>(
      begin: const Offset(0, -0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutBack));

    _fade = Tween<double>(begin: 0, end: 1)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));

    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> dismiss() async {
    await _ctrl.animateTo(
      0,
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeInBack,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 50,
      left: 20,
      right: 20,
      child: SlideTransition(
        position: _slide,
        child: FadeTransition(
          opacity: _fade,
          child: Material(
            color: Colors.transparent,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(50),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.6),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  ClipOval(
                    child: Container(
                      padding: const EdgeInsets.all(3.0),
                      width: 45,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFAFAFA),
                        shape: BoxShape.circle,
                        border: Border.all(
                          width: 1,
                          color: const Color(0xFFDBDBDB),
                        ),
                      ),
                      child: Image.asset('assets/icons/profile.png',
                          fit: BoxFit.cover),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'notification.incoming_call'.tr(),
                          style: AppTypography.prompt(
                            color: Colors.black,
                            fontWeight: FontWeight.w400,
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          widget.lawyerName,
                          style: AppTypography.prompt(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 45,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFAFAFA),
                      shape: BoxShape.circle,
                      border:
                          Border.all(width: 1, color: const Color(0xFFDBDBDB)),
                    ),
                    child: IconButton(
                      icon: Icon(Icons.call_end, color: Colors.red.shade600),
                      onPressed: widget.onDecline,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    width: 45,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFAFAFA),
                      shape: BoxShape.circle,
                      border:
                          Border.all(width: 1, color: const Color(0xFFDBDBDB)),
                    ),
                    child: IconButton(
                      icon:
                          Icon(Icons.call, color: Colors.greenAccent.shade700),
                      onPressed: widget.onAccept,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
