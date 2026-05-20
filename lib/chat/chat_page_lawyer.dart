import 'dart:io';
import 'package:LawyerOnline/chat/widgets/chat_bubble.dart';
import 'package:LawyerOnline/chat/widgets/chat_input.dart';
import 'package:LawyerOnline/chat/chat_auto_pop_mixin.dart';
import 'package:LawyerOnline/component/appbar.dart';
import 'package:LawyerOnline/component/dialog_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hms_room_kit/hms_room_kit.dart';
import 'package:LawyerOnline/consult/consult_status.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:LawyerOnline/models/lawyer/lawyer_jobs_store.dart';
import 'package:LawyerOnline/menu.dart';
import 'package:easy_localization/easy_localization.dart';

class ChatPageLawyer extends StatefulWidget {
  final Map<String, dynamic> model;
  final String? jobId;
  final bool embeddedMode; // ← ใหม่: true = ซ่อน AppBar (desktop panel)

  const ChatPageLawyer({
    super.key,
    required this.model,
    this.jobId,
    this.embeddedMode = false,
  });

  @override
  State<ChatPageLawyer> createState() => _ChatPageLawyerState();
}

class _ChatPageLawyerState extends State<ChatPageLawyer>
    with AutoPopOnDesktopMixin {
  final TextEditingController _chatController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<_ChatMessage> _messages = [];
  late bool _caseSuccess;

  // ── skip auto-pop เมื่อ embeddedMode (อยู่ใน 2-panel แล้ว) ──
  @override
  void didChangeDependencies() {
    if (!widget.embeddedMode) super.didChangeDependencies();
  }

  @override
  void initState() {
    super.initState();
    _caseSuccess = widget.model['caseSuccess'] as bool? ?? false;
  }

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
      message: 'endConsultMessageLawyer'.tr(),
      onConfirm: () {
        if (widget.jobId != null)
          LawyerJobsStore.instance.updateStatus(widget.jobId!, 'done');
        setState(() => _caseSuccess = true);
        DialogService.showSuccess(
          context,
          title: 'successTitle'.tr(),
          message: 'endConsultSuccessMessage'.tr(),
          onClose: () => Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => MenuPage(pageIndex: 0)),
            (route) => false,
          ),
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
        await _callUser();
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

  Future<void> _callUser() async {
    const storage = FlutterSecureStorage();
    final name = await storage.read(key: 'name') ?? 'ทนายความ';
    await FirebaseFirestore.instance.collection('calls').add({
      'callerType': 'lawyer',
      'callerName': name,
      'receiverType': 'user',
      'status': 'ringing',
      'createdAt': FieldValue.serverTimestamp(),
    });
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('callingUser'.tr())),
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
    final clientColor = model['clientColor'] != null
        ? Color(model['clientColor'] as int)
        : const Color(0xFF0262EC);

    final actionButtons = !_caseSuccess
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
        : null;

    // ── AppBar: ซ่อนเมื่อ embeddedMode ──────────────────────
    final chatAppBar = widget.embeddedMode
        ? null
        : appBarChat(
            onBack: () => Navigator.pop(context),
            avatarWidget: Container(
              width: 44,
              height: 44,
              decoration:
                  BoxDecoration(color: clientColor, shape: BoxShape.circle),
              child: Center(
                child: Text(model['avatar'] ?? '?',
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18)),
              ),
            ),
            name: model['name'] ?? '',
            statusText: _caseSuccess
                ? null
                : (isActive ? 'activeNow'.tr() : 'notActive'.tr()),
            actions: actionButtons,
          );

    return Scaffold(
      backgroundColor: const Color(0xFFEEF2F5),
      appBar: chatAppBar as PreferredSizeWidget?,
      body: Column(
        children: [
          // ── Desktop embedded header ────────────────────────
          if (widget.embeddedMode)
            _buildEmbeddedHeader(model, isActive, clientColor, actionButtons),
          const SizedBox(height: 12),
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: _messages.length,
              itemBuilder: (_, i) => ChatBubble(
                text: _messages[i].text,
                isMe: _messages[i].isMe,
                avatarAsset: 'assets/icons/profile.png',
              ),
            ),
          ),
          _caseSuccess
              ? _buildEndedBanner()
              : ChatInput(controller: _chatController, onSend: _sendMessage),
        ],
      ),
    );
  }

  Widget _buildEmbeddedHeader(Map<String, dynamic> model, bool isActive,
      Color clientColor, Widget? actions) {
    return Container(
      height: 72,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE4E8EF))),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration:
                BoxDecoration(color: clientColor, shape: BoxShape.circle),
            child: Center(
              child: Text(model['avatar'] ?? '?',
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18)),
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
                if (!_caseSuccess)
                  Text(isActive ? 'activeNow'.tr() : 'notActive'.tr(),
                      style: const TextStyle(
                          fontSize: 12, color: Color(0xFF8593A8))),
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (actions != null) actions,
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
