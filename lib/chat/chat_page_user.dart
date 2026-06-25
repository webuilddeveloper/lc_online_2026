import 'dart:io';
import 'package:LawyerOnline/chat/widgets/chat_bubble.dart';
import 'package:LawyerOnline/chat/widgets/chat_input.dart';
import 'package:LawyerOnline/chat/chat_auto_pop_mixin.dart';
import 'package:LawyerOnline/component/appbar.dart';
import 'package:LawyerOnline/component/dialog_service.dart';
import 'package:LawyerOnline/consult/consult_status.dart';
import 'package:LawyerOnline/models/lawyer/lawyer_jobs_store.dart';
import 'package:LawyerOnline/services/chat_service.dart';
import 'package:LawyerOnline/shared/api_provider.dart';
import 'package:flutter/material.dart';
import 'package:hms_room_kit/hms_room_kit.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:easy_localization/easy_localization.dart';

class ChatPageUser extends StatefulWidget {
  final Map<String, dynamic> model;
  final bool embeddedMode;
  final String roomCode;
  final String userId;
  final String caseCode; // ✅ รับ caseCode แยกต่างหาก

  const ChatPageUser({
    super.key,
    required this.model,
    this.embeddedMode = false,
    this.roomCode = '',
    this.userId = '',
    this.caseCode = '',
  });

  @override
  State<ChatPageUser> createState() => _ChatPageUserState();
}

class _ChatPageUserState extends State<ChatPageUser>
    with AutoPopOnDesktopMixin {
  final ChatService _chatService = ChatService();
  final TextEditingController _chatController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  List<Map<String, dynamic>> _messages = [];
  bool _isTyping = false;
  String _typingUser = '';
  bool _isLoading = true;
  dynamic _caseData = {};

  @override
  void initState() {
    super.initState();
    _setupChat();
  }

  @override
  void didChangeDependencies() {
    if (!widget.embeddedMode) super.didChangeDependencies();
  }

  Future<void> _setupChat() async {
    await _chatService.disconnect();

    _chatService.onReceiveMessage = (message) {
      setState(() => _messages.add(message));
      _scrollToBottom();
    };

    _chatService.onLoadHistory = (history) {
      setState(() {
        _messages = history
            .map((e) => e as Map<String, dynamic>)
            .toList()
            .reversed
            .toList();
      });
      _scrollToBottom();
    };

    _chatService.onUserTyping = (userId, isTyping) {
      if (userId != widget.userId) {
        setState(() {
          _isTyping = isTyping;
          _typingUser = userId;
        });
      }
    };

    await _chatService.connect();
    await _chatService.joinRoom(widget.roomCode, widget.userId);
    await _chatService.loadHistory(widget.roomCode);
    await _chatService.markAsRead(widget.roomCode, widget.userId);
    await _loadCase();
  }

  Future<void> _loadCase() async {
    // ใช้ caseCode ที่รับมาตรงๆ ก่อน ถ้าไม่มีค่อย fallback ไปหาใน model
    final code = widget.caseCode.isNotEmpty
        ? widget.caseCode
        : widget.model['code']?.toString() ?? '';
    if (code.isEmpty) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }
    try {
      final param = await postDio('${server}/m/case/read', {'code': code});
      if (mounted) {
        setState(() {
          _caseData = param['objectData'] is List
              ? (param['objectData'] as List).first
              : param['objectData'] ?? {};
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _sendMessage() {
    final text = _chatController.text.trim();
    if (text.isEmpty) return;
    _chatService.sendMessage(widget.roomCode, widget.userId, text);
    _chatController.clear();
    _chatService.typing(widget.roomCode, widget.userId, false);
  }

  // caseCode สำหรับนำทางไป ConsultStatusPage
  String get _caseCode =>
      widget.caseCode.isNotEmpty
          ? widget.caseCode
          : _caseData['code']?.toString() ?? '';

  void _endConsultation() {
    DialogService.showConfirm(
      context,
      title: 'endConsultTitle'.tr(),
      message: 'endConsultMessageUser'.tr(),
      onConfirm: () async {
        final param = await postDio('${server}/m/case/update', {
          'code': _caseCode,
          'caseStatus': 4,
          'isReview': false,
        });
        if (!mounted) return;
        print('------>>> ${param}');
        if (param['status'] == 'S') {
          await _chatService.disconnect();
          Navigator.pushAndRemoveUntil(
            context,
            // ── ส่งแค่ caseCode ──
            MaterialPageRoute(
              builder: (_) => ConsultStatusPage(caseCode: _caseCode),
            ),
            (route) => route.isFirst,
          );
        }
      },
    );
  }

  void _showReminderBeforeJoin() {
    DialogService.showConfirm(
      context,
      title: 'callReminderTitle'.tr(),
      message: 'callReminderMessage'.tr(),
      onConfirm: () async {
        if (!Platform.isIOS) {
          await Permission.camera.request();
          await Permission.microphone.request();
          final camDenied = await Permission.camera.isPermanentlyDenied;
          final micDenied = await Permission.microphone.isPermanentlyDenied;
          if (camDenied || micDenied) {
            if (!mounted) return;
            DialogService.showConfirm(
              context,
              title: 'permissionSettingsTitle'.tr(),
              message: 'permissionSettingsMessage'.tr(),
              onConfirm: () => openAppSettings(),
            );
            return;
          }
        }
        if (!mounted) return;
        final navigator = Navigator.of(context);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => HMSPrebuilt(
              roomCode: 'jle-wjbx-gyk',
              onLeave: () {
                Future.delayed(const Duration(milliseconds: 300), () {
                  navigator.pushAndRemoveUntil(
                    // ── ส่งแค่ caseCode ──
                    MaterialPageRoute(
                      builder: (_) => ConsultStatusPage(caseCode: _caseCode),
                    ),
                    (route) => route.isFirst,
                  );
                });
              },
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _chatService.onReceiveMessage = null;
    _chatService.onLoadHistory = null;
    _chatService.onUserTyping = null;
    _chatService.onMessageRead = null;
    _chatService.leaveRoom(widget.roomCode, widget.userId);
    LawyerJobsStore.instance.removeListener(() {});
    _chatController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return _buildLoadingState();

    final caseStatus = _caseData['caseStatus'] as int? ?? 0;
    final caseSuccess = caseStatus == 4;
    final chatLocked = caseStatus == 2;
    final imageUrl = widget.model['imageUrl'] as String? ?? '';
    final appointmentDate = _caseData['caseDate']?.toString() ?? '';
    final appointmentTime =
        '${_caseData['startTime'] ?? ''} ${_caseData['endTime'] ?? ''}'.trim();

    final chatAppBar = widget.embeddedMode
        ? null
        : appBarChat(
            onBack: () => Navigator.pop(context),
            avatarWidget: ClipRRect(
              borderRadius: BorderRadius.circular(100),
              child: imageUrl.isNotEmpty
                  ? Image.network(imageUrl,
                      height: 44, width: 44, fit: BoxFit.cover)
                  : Image.asset('assets/icons/profile.png',
                      height: 44, width: 44, fit: BoxFit.cover),
            ),
            name: widget.model['name'] ?? '',
            statusText: caseSuccess ? null : 'activeNow'.tr(),
            actions: !caseSuccess && !chatLocked
                ? Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _iconBtn(
                        icon: Icons.video_call_outlined,
                        onTap: _showReminderBeforeJoin,
                      ),
                      const SizedBox(width: 8),
                      _iconBtn(
                        icon: Icons.task_alt_rounded,
                        color: const Color(0xFF34C759),
                        bgColor: const Color(0xFFF0FFF4),
                        borderColor: const Color(0xFF34C759),
                        onTap: _endConsultation,
                      ),
                    ],
                  )
                : null,
          );

    return Scaffold(
      backgroundColor: const Color(0xFFEEF2F5),
      appBar: chatAppBar as PreferredSizeWidget?,
      body: Column(
        children: [
          if (widget.embeddedMode)
            _buildEmbeddedHeader(
                caseSuccess, chatLocked, imageUrl, appointmentDate, appointmentTime),
          Expanded(
            child: ListView.separated(
              controller: _scrollController,
              padding: const EdgeInsets.fromLTRB(12, 20, 12, 25),
              itemCount: _messages.length,
              itemBuilder: (_, i) {
                final msg = _messages[i];
                final isMe = msg['senderId'] == widget.userId;
                return ChatBubble(
                  text: msg['content'] ?? '',
                  isMe: isMe,
                  avatarAsset: imageUrl,
                );
              },
              separatorBuilder: (_, index) =>
                  _messages[index]['senderId'] !=
                          _messages[index + 1]['senderId']
                      ? const SizedBox(height: 10)
                      : const SizedBox(),
            ),
          ),
          if (_isTyping)
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text('$_typingUser กำลังพิมพ์...',
                    style: const TextStyle(
                        fontSize: 12, color: Color(0xFF8593A8))),
              ),
            ),
          if (caseSuccess)
            _buildEndedBanner()
          else if (chatLocked)
            _buildLockedBanner(appointmentDate, appointmentTime)
          else
            ChatInput(controller: _chatController, onSend: _sendMessage),
        ],
      ),
    );
  }

  Widget _buildEmbeddedHeader(bool caseSuccess, bool chatLocked,
      String imageUrl, String date, String time) {
    return Container(
      height: 72,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE4E8EF))),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(100),
            child: imageUrl.isNotEmpty
                ? Image.network(imageUrl,
                    height: 44, width: 44, fit: BoxFit.cover)
                : Image.asset('assets/icons/profile.png',
                    height: 44, width: 44, fit: BoxFit.cover),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.model['name'] ?? '',
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                if (!caseSuccess)
                  Text('activeNow'.tr(),
                      style: const TextStyle(
                          fontSize: 12, color: Color(0xFF8593A8))),
              ],
            ),
          ),
          if (!caseSuccess && !chatLocked) ...[
            _iconBtn(
                icon: Icons.video_call_outlined,
                onTap: _showReminderBeforeJoin),
            const SizedBox(width: 8),
            _iconBtn(
              icon: Icons.task_alt_rounded,
              color: const Color(0xFF34C759),
              bgColor: const Color(0xFFF0FFF4),
              borderColor: const Color(0xFF34C759),
              onTap: _endConsultation,
            ),
          ],
        ],
      ),
    );
  }

  Widget _iconBtn({
    required IconData icon,
    Color color = const Color(0xFF555555),
    Color bgColor = const Color(0xFFFAFAFA),
    Color borderColor = const Color(0xFFDBDBDB),
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: bgColor,
          shape: BoxShape.circle,
          border: Border.all(width: 1, color: borderColor),
        ),
        child: Icon(icon, size: 20, color: color),
      ),
    );
  }

  Widget _buildEndedBanner() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(
          top: 12, bottom: MediaQuery.of(context).padding.bottom + 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        border:
            Border(top: BorderSide(color: Color(0xFFEEF2F5), width: 1.5)),
      ),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20),
        padding:
            const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
        decoration: BoxDecoration(
            color: const Color(0xFFF5F5F5),
            borderRadius: BorderRadius.circular(12)),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.lock_outline_rounded,
                size: 16, color: Color(0xFF8593A8)),
            const SizedBox(width: 6),
            Text('conversationEnded'.tr(),
                style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF8593A8),
                    fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }

  Widget _buildLockedBanner(String date, String time) {
    final hasSchedule = date.isNotEmpty || time.isNotEmpty;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(
          top: 12, bottom: MediaQuery.of(context).padding.bottom + 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        border:
            Border(top: BorderSide(color: Color(0xFFEEF2F5), width: 1.5)),
      ),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding:
            const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: const Color(0xFFF0F6FF),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: const Color(0xFF0262EC).withOpacity(0.2)),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: const Color(0xFF0262EC).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.lock_clock_rounded,
                  size: 18, color: Color(0xFF0262EC)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('รอถึงวันนัด เพื่อเปิดห้องสนทนา',
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF0262EC))),
                  if (hasSchedule) ...[
                    const SizedBox(height: 3),
                    Text(
                      [
                        if (date.isNotEmpty) date,
                        if (time.isNotEmpty) time,
                      ].join(' • '),
                      style: const TextStyle(
                          fontSize: 12, color: Color(0xFF5B6E8A)),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Scaffold(
      backgroundColor: Color(0xFFEEF2F5),
      body: Center(
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
    );
  }
}