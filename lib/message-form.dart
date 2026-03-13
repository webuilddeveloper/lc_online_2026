import 'package:LawyerOnline/component/dialog_service.dart';
import 'package:LawyerOnline/consult/consult_status.dart';
import 'package:flutter/material.dart';
import 'package:LawyerOnline/component/appbar.dart';
import 'package:hms_room_kit/hms_room_kit.dart';
import 'package:permission_handler/permission_handler.dart';

class MessageFormPage extends StatefulWidget {
  MessageFormPage({Key? key, this.model});

  dynamic model;

  @override
  State<MessageFormPage> createState() => _MessageFormPageState();
}

class _MessageFormPageState extends State<MessageFormPage> {
  final TextEditingController chatController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  final List<ChatMessage> messages = [];

  @override
  void dispose() {
    chatController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    final text = chatController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      messages.add(ChatMessage(text: text, isMe: true));
    });

    chatController.clear();

    Future.delayed(const Duration(milliseconds: 100), () {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });

    Future.delayed(const Duration(seconds: 1), () {
      setState(() {
        messages.add(ChatMessage(text: 'รับทราบครับ 👍', isMe: false));
      });
    });
  }

  // ── จบการปรึกษา → ไป ConsultStatusPage step 4 (เสร็จสิ้น) ────────
  void _endConsultation() {
    DialogService.showConfirm(
      context,
      title: "จบการปรึกษา",
      message: "คุณต้องการจบการปรึกษากับทนายความใช่หรือไม่?",
      onConfirm: () {
        // แมป model → lawyer ที่ ConsultStatusPage ต้องการ
        final lawyer = widget.model != null
            ? {
                'name'    : widget.model['name'] ?? '',
                'avatar'  : (widget.model['name'] as String? ?? 'ท')
                                .characters.first,
                'title'   : widget.model['title'] ??
                            (widget.model['skills'] != null &&
                                (widget.model['skills'] as List).isNotEmpty
                                ? (widget.model['skills'] as List).first
                                : widget.model['experience'] ?? ''),
                'rating'  : widget.model['rating'] ??
                            widget.model['scroll'] ?? 0,
                'imageUrl': widget.model['imageUrl'] ?? '',
              }
            : null;

        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (_) => ConsultStatusPage(
              currentStep     : 4,           // เสร็จสิ้น
              lawyer          : lawyer,
              appointmentDate : widget.model?['appointmentDate'],
              appointmentTime : widget.model?['appointmentTime'],
            ),
          ),
          (Route<dynamic> route) => route.isFirst,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEEF2F5),
      appBar: appBarCustom(
        title: "",
        backBtn: true,
        isRightWidget: true,
        backAction: () => goBack(),
        rightWidget: Row(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  widget.model['name'] ?? '',
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w500),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  (widget.model['active'] ?? true) ? 'Active Now' : 'Not Active',
                  style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: Color(0xFF8593A8)),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
            const SizedBox(width: 10),
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(100),
                  child: Image.asset(
                    widget.model['imageUrl'] ?? 'assets/icons/profile.png',
                    height: 48,
                    width: 48,
                    fit: BoxFit.cover,
                  ),
                ),
                (widget.model['active'] ?? true)
                    ? Positioned(
                        right: 0,
                        child: Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                              color: const Color(0xFF00CC5E),
                              borderRadius: BorderRadius.circular(100)),
                        ),
                      )
                    : const SizedBox.shrink(),
              ],
            ),
            const SizedBox(width: 10),
            // ── ปุ่ม Video Call ──────────────────────────────────
            GestureDetector(
              onTap: () => _showReminderBeforeJoin(context),
              child: Container(
                width: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: const Color(0xFFFAFAFA),
                  shape: BoxShape.circle,
                  border: Border.all(width: 1, color: const Color(0xFFDBDBDB)),
                ),
                child: const Icon(Icons.video_call_outlined, size: 20),
              ),
            ),
            const SizedBox(width: 8),
            // ── ปุ่มจบการปรึกษา ──────────────────────────────────
            GestureDetector(
              onTap: _endConsultation,
              child: Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: const Color(0xFFF0FFF4),
                  shape: BoxShape.circle,
                  border: Border.all(
                      width: 1, color: const Color(0xFF34C759)),
                ),
                child: const Icon(
                  Icons.task_alt_rounded,
                  size: 20,
                  color: Color(0xFF34C759),
                ),
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          const SizedBox(height: 20),
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(12),
              itemCount: messages.length,
              itemBuilder: (context, index) {
                final msg = messages[index];
                return Align(
                  alignment:
                      msg.isMe ? Alignment.centerRight : Alignment.centerLeft,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      !msg.isMe
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(100),
                              child: Image.asset(
                                widget.model['imageUrl'] ??
                                    'assets/icons/profile.png',
                                height: 40,
                                width: 40,
                                fit: BoxFit.cover,
                              ),
                            )
                          : const SizedBox.shrink(),
                      const SizedBox(width: 5),
                      Container(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                        constraints: BoxConstraints(
                          maxWidth: MediaQuery.of(context).size.width * 0.7,
                        ),
                        decoration: BoxDecoration(
                          color: msg.isMe
                              ? const Color(0xFF00B900)
                              : Colors.grey.shade300,
                          borderRadius: BorderRadius.only(
                            topLeft: const Radius.circular(18),
                            topRight: const Radius.circular(18),
                            bottomLeft: msg.isMe
                                ? const Radius.circular(18)
                                : const Radius.circular(4),
                            bottomRight: msg.isMe
                                ? const Radius.circular(4)
                                : const Radius.circular(18),
                          ),
                        ),
                        child: Text(
                          msg.text,
                          style: TextStyle(
                            color: msg.isMe ? Colors.white : Colors.black,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
      bottomSheet: SafeArea(
        top: false,
        child: Container(
          color: const Color(0xFFEEF2F5),
          padding: EdgeInsets.only(
              left: 15,
              right: 15,
              bottom: isKeyboardOpen(context) ? 15 : 25),
          child: TextField(
            controller: chatController,
            maxLines: null,
            keyboardType: TextInputType.multiline,
            onChanged: (value) => setState(() {}),
            onSubmitted: (value) => _sendMessage(),
            style: const TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.normal,
              fontSize: 15.00,
            ),
            decoration: InputDecoration(
              filled: true,
              fillColor: const Color(0xFFFFFFFF),
              contentPadding:
                  const EdgeInsets.fromLTRB(14.0, 10.0, 14.0, 10.0),
              hintText: "พิมพ์ข้อความ...",
              helperStyle: const TextStyle(color: Color(0xFF8593A8)),
              suffixIcon: Padding(
                padding: const EdgeInsets.fromLTRB(8, 13, 15, 13),
                child: chatController.text.isNotEmpty
                    ? GestureDetector(
                        onTap: () => _sendMessage(),
                        child: const Icon(Icons.send,
                            size: 26, color: Color(0xFF0262EC)),
                      )
                    : Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Image.asset('assets/icons/input-gallery.png',
                              width: 26, height: 26, fit: BoxFit.contain),
                          const SizedBox(width: 6),
                          Image.asset('assets/icons/input-emoji.png',
                              width: 26, height: 26, fit: BoxFit.contain),
                        ],
                      ),
              ),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18.0)),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18.0),
                borderSide: const BorderSide(color: Color(0xFF0262EC)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18.0),
                borderSide: const BorderSide(color: Color(0xFF0262EC)),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showReminderBeforeJoin(BuildContext context) {
    DialogService.showConfirm(
      context,
      title: "คำแนะนำก่อนเข้าห้อง",
      message: "กรุณาระบุชื่อในช่อง Enter Name ว่า 1234 ก่อนกด Join Now",
      onConfirm: () async {
        // request ก่อนเพื่อให้ iOS popup ถ้ายังไม่เคยอนุญาต
        await [Permission.camera, Permission.microphone].request();

        // block เฉพาะ permanentlyDenied เท่านั้น
        final camDenied = await Permission.camera.isPermanentlyDenied;
        final micDenied = await Permission.microphone.isPermanentlyDenied;

        if (camDenied || micDenied) {
          DialogService.showConfirm(
            context,
            title: "ต้องเปิดการเข้าถึงใน Settings",
            message: "กรุณาไปที่การตั้งค่า แล้วอนุญาตให้แอปเข้าถึงกล้องและไมโครโฟน",
            onConfirm: () => openAppSettings(),
          );
          return;
        }

        // เข้า HMSPrebuilt เลย — HMS มี permission flow ของตัวเองอยู่แล้ว
        final navigator = Navigator.of(context);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => HMSPrebuilt(
              roomCode: "jle-wjbx-gyk",
              onLeave: () {
                Future.delayed(const Duration(milliseconds: 300), () {
                  navigator.pushAndRemoveUntil(
                    MaterialPageRoute(
                      builder: (_) => ConsultStatusPage(currentStep: 4),
                    ),
                    (Route<dynamic> route) => route.isFirst,
                  );
                });
              },
            ),
          ),
        );
      },
    );
  }

  bool isKeyboardOpen(BuildContext context) =>
      MediaQuery.of(context).viewInsets.bottom > 0;

  void goBack() => Navigator.pop(context);
}

class ChatMessage {
  final String text;
  final bool isMe;
  ChatMessage({required this.text, required this.isMe});
}