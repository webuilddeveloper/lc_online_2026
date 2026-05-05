import 'dart:io';
import 'package:LawyerOnline/chat/widgets/chat_bubble.dart';
import 'package:LawyerOnline/chat/widgets/chat_input.dart';
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

// ══════════════════════════════════════════════════════════
//  ChatPageLawyer — หน้าแชทฝั่ง Lawyer
//  - แชทกับลูกความ
//  - กดปุ่ม video call → แจ้ง Firestore + เปิด HMS
//  - กดปุ่มจบงาน → success dialog → กลับหน้าก่อน
// ══════════════════════════════════════════════════════════

class ChatPageLawyer extends StatefulWidget {
  /// model ของลูกความที่ทนายกำลังแชทด้วย
  /// ต้องการ: name, avatar (ตัวอักษร), clientColor, active, caseSuccess
  final Map<String, dynamic> model;
  final String? jobId;
  const ChatPageLawyer({
    super.key,
    required this.model,
    this.jobId,
  });

  @override
  State<ChatPageLawyer> createState() => _ChatPageLawyerState();
}

class _ChatPageLawyerState extends State<ChatPageLawyer> {
  final TextEditingController _chatController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<_ChatMessage> _messages = [];
  late bool _caseSuccess;

  @override
  void initState() {
    super.initState();
    _caseSuccess = widget.model['caseSuccess'] as bool? ?? false;
  }

  // ── ส่งข้อความ ────────────────────────────────────────
  void _sendMessage() {
    final text = _chatController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _messages.add(_ChatMessage(text: text, isMe: true));
    });

    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });

    // TODO: ส่งจริงผ่าน Firestore
    // mock reply ชั่วคราว
    Future.delayed(const Duration(seconds: 1), () {
      if (!mounted) return;
      setState(() {
        _messages.add(_ChatMessage(text: 'รับทราบครับ 👍', isMe: false));
      });
    });
  }

  // ── จบงาน (ฝั่งทนาย) ──────────────────────────────────
  void _endConsultation() {
    DialogService.showConfirm(
      context,
      title: 'จบการปรึกษา',
      message: 'คุณต้องการจบการปรึกษากับลูกความใช่หรือไม่?',
      onConfirm: () {
        // ✅ อัปเดต status เป็น done
        if (widget.jobId != null) {
          LawyerJobsStore.instance.updateStatus(widget.jobId!, 'done');
        }

        setState(() => _caseSuccess = true);

        DialogService.showSuccess(
          context,
          title: 'สำเร็จ',
          message: 'สถานะงานกับลูกความเสร็จสิ้นเรียบร้อย',
          onClose: () => Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => MenuPage(pageIndex: 0)),
            (route) => false,
          ),
        );
      },
    );
  }

  // ── Video Call + แจ้ง Firestore ───────────────────────
  void _showReminderBeforeJoin() {
    DialogService.showConfirm(
      context,
      title: 'คำแนะนำก่อนเข้าห้อง',
      message: 'กรุณาระบุชื่อในช่อง Enter Name ว่า 1234 ก่อนกด Join Now',
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
              title: 'ต้องเปิดการเข้าถึงใน Settings',
              message:
                  'กรุณาไปที่การตั้งค่า แล้วอนุญาตให้แอปเข้าถึงกล้องและไมโครโฟน',
              onConfirm: () => openAppSettings(),
            );
            return;
          }
        }

        // ✅ แจ้ง user ก่อนเข้าห้อง — อยู่ใน onConfirm แล้ว
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
                      builder: (_) => ConsultStatusPage(currentStep: 4),
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
      const SnackBar(content: Text('📞 กำลังโทรหาผู้ใช้...')),
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

    return Scaffold(
      backgroundColor: const Color(0xFFEEF2F5),
      appBar: appBarChat(
        onBack: () => Navigator.pop(context),
        avatarWidget: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(color: clientColor, shape: BoxShape.circle),
          child: Center(
            child: Text(model['avatar'] ?? '?',
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18)),
          ),
        ),
        name: model['name'] ?? '',
        statusText:
            _caseSuccess ? null : (isActive ? 'Active Now' : 'Not Active'),
        actions: !_caseSuccess
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
                      onTap: _endConsultation),
                ],
              )
            : null,
      ),
      body: Column(
        children: [
          const SizedBox(height: 12),
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: _messages.length,
              itemBuilder: (_, i) => ChatBubble(
                text: _messages[i].text,
                isMe: _messages[i].isMe,
                // ลูกความใช้ avatar ตัวอักษร — ChatBubble ใช้ image
                // TODO: เปลี่ยนเป็น avatar widget แบบตัวอักษรได้ในอนาคต
                avatarAsset: 'assets/icons/profile.png',
              ),
            ),
          ),
          _caseSuccess
              ? _buildEndedBanner()
              : ChatInput(
                  controller: _chatController,
                  onSend: _sendMessage,
                ),
        ],
      ),
      // bottomSheet:
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
        top: 12,
        bottom: MediaQuery.of(context).padding.bottom + 12,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Color(0xFFEEF2F5), width: 1.5),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F5F5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.lock_outline_rounded,
                    size: 16, color: Color(0xFF8593A8)),
                SizedBox(width: 6),
                Text(
                  'จบการสนทนาแล้ว',
                  style: TextStyle(
                    fontSize: 13,
                    color: Color(0xFF8593A8),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatMessage {
  final String text;
  final bool isMe;
  _ChatMessage({required this.text, required this.isMe});
}
