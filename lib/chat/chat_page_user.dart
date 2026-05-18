import 'dart:io';
import 'package:LawyerOnline/chat/widgets/chat_bubble.dart';
import 'package:LawyerOnline/chat/widgets/chat_input.dart';
import 'package:LawyerOnline/component/appbar.dart';
import 'package:LawyerOnline/component/dialog_service.dart';
import 'package:LawyerOnline/consult/consult_status.dart';
import 'package:flutter/material.dart';
import 'package:hms_room_kit/hms_room_kit.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:easy_localization/easy_localization.dart';

class ChatPageUser extends StatefulWidget {
  final Map<String, dynamic> model;
  final bool embeddedMode; // ← ใหม่: true = ซ่อน AppBar (desktop panel)

  const ChatPageUser({
    super.key,
    required this.model,
    this.embeddedMode = false,
  });

  @override
  State<ChatPageUser> createState() => _ChatPageUserState();
}

class _ChatPageUserState extends State<ChatPageUser> {
  final TextEditingController _chatController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<_ChatMessage> _messages = [];

  void _sendMessage() {
    final text = _chatController.text.trim();
    if (text.isEmpty) return;
    setState(() => _messages.add(_ChatMessage(text: text, isMe: true)));
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
    Future.delayed(const Duration(seconds: 1), () {
      if (!mounted) return;
      setState(() =>
          _messages.add(_ChatMessage(text: 'รับทราบครับ 👍', isMe: false)));
    });
  }

  void _endConsultation() {
    DialogService.showConfirm(
      context,
      title: 'endConsultTitle'.tr(),
      message: 'endConsultMessageUser'.tr(),
      onConfirm: () {
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
    _chatController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final model = widget.model;
    final isActive = model['active'] as bool? ?? true;
    final caseSuccess = model['caseSuccess'] as bool? ?? false;
    final imageUrl = model['imageUrl'] as String? ?? '';

    // ── AppBar: ซ่อนเมื่อ embeddedMode (desktop panel มี header ของตัวเอง) ──
    final chatAppBar = widget.embeddedMode
        ? null
        : appBarChat(
            onBack: () => Navigator.pop(context),
            avatarWidget: ClipRRect(
              borderRadius: BorderRadius.circular(100),
              child: Image.asset(
                imageUrl.isNotEmpty ? imageUrl : 'assets/icons/profile.png',
                height: 44,
                width: 44,
                fit: BoxFit.cover,
              ),
            ),
            name: model['name'] ?? '',
            statusText:
                caseSuccess ? null : (isActive ? 'activeNow'.tr() : 'notActive'.tr()),
            actions: !caseSuccess
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
          // ── Desktop embedded header (แทน AppBar) ─────────────
          if (widget.embeddedMode)
            _buildEmbeddedHeader(model, isActive, caseSuccess, imageUrl),
          const SizedBox(height: 12),
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: _messages.length,
              itemBuilder: (_, i) => ChatBubble(
                text: _messages[i].text,
                isMe: _messages[i].isMe,
                avatarAsset:
                    imageUrl.isNotEmpty ? imageUrl : 'assets/icons/profile.png',
              ),
            ),
          ),
          caseSuccess
              ? _buildEndedBanner()
              : ChatInput(controller: _chatController, onSend: _sendMessage),
        ],
      ),
    );
  }

  // ── Header สำหรับ desktop panel (แทน AppBar) ──────────────
  Widget _buildEmbeddedHeader(Map<String, dynamic> model, bool isActive,
      bool caseSuccess, String imageUrl) {
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
          if (!caseSuccess) ...[
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
            Icon(Icons.lock_outline_rounded,
                size: 16, color: Color(0xFF8593A8)),
            SizedBox(width: 6),
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
}

class _ChatMessage {
  final String text;
  final bool isMe;
  _ChatMessage({required this.text, required this.isMe});
}
