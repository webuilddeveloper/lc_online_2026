import 'dart:io';
import 'package:LawyerOnline/chat/widgets/chat_bubble.dart';
import 'package:LawyerOnline/chat/widgets/chat_input.dart';
import 'package:LawyerOnline/chat/chat_auto_pop_mixin.dart';
import 'package:LawyerOnline/component/appbar.dart';
import 'package:LawyerOnline/component/dialog_service.dart';
import 'package:LawyerOnline/consult/consult_status.dart';
import 'package:LawyerOnline/models/lawyer/lawyer_jobs_store.dart';
import 'package:LawyerOnline/services/chat_service.dart';
import 'package:flutter/material.dart';
import 'package:hms_room_kit/hms_room_kit.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:easy_localization/easy_localization.dart';

class ChatPageUser extends StatefulWidget {
  final Map<String, dynamic> model;
  final bool embeddedMode;
  final String roomCode;
  final String userId;

  const ChatPageUser({
    super.key,
    required this.model,
    this.embeddedMode = false,
    this.roomCode = "",
    this.userId = "",
  });

  @override
  State<ChatPageUser> createState() => _ChatPageUserState();
}

class _ChatPageUserState extends State<ChatPageUser>
    with AutoPopOnDesktopMixin {
  final ChatService _chatService = ChatService();
  final TextEditingController _chatController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  // ✅ เปลี่ยนจาก List<_ChatMessage> → Map
  List<Map<String, dynamic>> _messages = [];
  bool _isTyping = false;
  String _typingUser = "";

  @override
  void initState() {
    super.initState();
    // LawyerJobsStore.instance.addListener(_handleStoreChanged);
    _setupChat();
  }

  void _handleStoreChanged() {
    if (mounted) setState(() {});
  }

  // ── skip auto-pop เมื่อ embeddedMode (อยู่ใน 2-panel แล้ว) ──
  @override
  void didChangeDependencies() {
    if (!widget.embeddedMode) super.didChangeDependencies();
  }

  // ✅ Logic จาก ChatPage
  Future<void> _setupChat() async {
    // ✅ ตัด connection เก่าทิ้งก่อนเสมอ
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

  // ✅ ใช้ ChatService จริง
  void _sendMessage() {
    final text = _chatController.text.trim();
    if (text.isEmpty) return;
    _chatService.sendMessage(widget.roomCode, widget.userId, text);
    _chatController.clear();
    _chatService.typing(widget.roomCode, widget.userId, false);
  }

  void _endConsultation() {
    DialogService.showConfirm(
      context,
      title: 'endConsultTitle'.tr(),
      message: 'endConsultMessageUser'.tr(),
      onConfirm: () {
        final jobId = widget.model['jobId']?.toString() ??
            widget.model['id']?.toString() ??
            '';
        if (jobId.isNotEmpty) {
          // LawyerJobsStore.instance.updateStatus(jobId, 'done');
        }
        final lawyer = {
          'name': widget.model['name'] ?? '',
          'avatar': (widget.model['name'] as String? ?? 'ท').characters.first,
          'title': widget.model['title'] ??
              (widget.model['skills'] != null &&
                      (widget.model['skills'] as List).isNotEmpty
                  ? (widget.model['skills'] as List).first
                  : widget.model['experience'] ?? ''),
          'rating': widget.model['rating'] ?? widget.model['scroll'] ?? 0,
          'imageUrl': widget.model['imageUrl'] ?? '',
        };
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (_) => ConsultStatusPage(
              currentStep: 4,
              lawyer: lawyer,
              appointmentDate: widget.model['appointmentDate'],
              appointmentTime: widget.model['appointmentTime'],
            ),
          ),
          (route) => route.isFirst,
        );
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
                    MaterialPageRoute(
                        builder: (_) => ConsultStatusPage(currentStep: 4)),
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
    _chatService.leaveRoom(widget.roomCode, widget.userId); // ✅ เพิ่ม
    LawyerJobsStore.instance.removeListener(_handleStoreChanged);
    _chatController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Map<String, dynamic> _currentModel() {
    final merged = Map<String, dynamic>.from(widget.model);
    final jobId = merged['jobId']?.toString() ?? merged['id']?.toString() ?? '';
    if (jobId.isEmpty) return merged;

    Map<String, dynamic>? latestJob;
    for (final job in LawyerJobsStore.instance.jobs) {
      if (job['id']?.toString() == jobId) {
        latestJob = job;
        break;
      }
    }
    if (latestJob == null) return merged;

    final status = latestJob['status']?.toString() ?? 'pending';
    final jobSource = (latestJob['jobSource'] ?? 'urgent').toString();
    merged['jobStatus'] = status;
    merged['jobSource'] = jobSource;
    merged['appointmentDate'] = latestJob['date'] ?? merged['appointmentDate'];
    merged['appointmentTime'] = latestJob['time'] ?? merged['appointmentTime'];
    merged['active'] = status == 'accepted' || status == 'in_session';
    merged['chatLocked'] = status == 'confirmed';
    merged['caseSuccess'] = status == 'done';
    return merged;
  }

  @override
  Widget build(BuildContext context) {
    final model = _currentModel();
    final isActive = model['active'] as bool? ?? true;
    final caseSuccess = model['caseSuccess'] as bool? ?? false;
    final chatLocked = model['chatLocked'] as bool? ?? false;
    final imageUrl = model['imageUrl'] as String? ?? '';
    final appointmentDate = model['appointmentDate'] as String? ?? '';
    final appointmentTime = model['appointmentTime'] as String? ?? '';

    final chatAppBar = widget.embeddedMode
        ? null
        : appBarChat(
            onBack: () => Navigator.pop(context),
            avatarWidget: ClipRRect(
              borderRadius: BorderRadius.circular(100),
              child: Image.network(
                imageUrl.isNotEmpty ? imageUrl : 'assets/icons/profile.png',
                height: 44,
                width: 44,
                fit: BoxFit.cover,
              ),
            ),
            name: model['name'] ?? '',
            statusText: caseSuccess
                ? null
                : (isActive ? 'activeNow'.tr() : 'notActive'.tr()),
            actions: !caseSuccess && !chatLocked
                ? Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
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
                model, isActive, caseSuccess, chatLocked, imageUrl),
          // const SizedBox(height: 12),
          Expanded(
            child: ListView.separated(
              controller: _scrollController,
              padding: const EdgeInsets.fromLTRB(12, 20, 12, 25),
              itemCount: _messages.length,
              itemBuilder: (_, i) {
                final msg = _messages[i];
                final isMe = msg['senderId'] == widget.userId; // ✅
                return ChatBubble(
                  text: msg['content'] ?? '',
                  isMe: isMe,
                  avatarAsset: imageUrl
                );
              },
              separatorBuilder: (context, index) => _messages[index]['senderId'] != _messages[index+1]['senderId'] ? const SizedBox(height: 10,) : const SizedBox(),
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

  Widget _buildEmbeddedHeader(Map<String, dynamic> model, bool isActive,
      bool caseSuccess, bool chatLocked, String imageUrl) {
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
            child: Image.asset(
              imageUrl.isNotEmpty ? imageUrl : 'assets/icons/profile.png',
              height: 44,
              width: 44,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(model['name'] ?? '',
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                if (!caseSuccess)
                  Text(isActive ? 'activeNow'.tr() : 'notActive'.tr(),
                      style: const TextStyle(
                          fontSize: 12, color: Color(0xFF8593A8))),
              ],
            ),
          ),
          const SizedBox(width: 8),
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
        border: Border(top: BorderSide(color: Color(0xFFEEF2F5), width: 1.5)),
      ),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
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

  // banner แสดงเมื่อรอถึงวันนัด (status == confirmed)
  Widget _buildLockedBanner(String date, String time) {
    final hasSchedule = date.isNotEmpty || time.isNotEmpty;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(
          top: 12, bottom: MediaQuery.of(context).padding.bottom + 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFEEF2F5), width: 1.5)),
      ),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: const Color(0xFFF0F6FF),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFF0262EC).withOpacity(0.2)),
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
                  const Text(
                    'รอถึงวันนัด เพื่อเปิดห้องสนทนา',
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0262EC)),
                  ),
                  if (hasSchedule) ...
                    [
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
}
// ✅ ลบ class _ChatMessage ออกแล้ว ไม่จำเป็นอีกต่อไป
