import 'dart:io';
import 'package:LawyerOnline/chat/widgets/chat_bubble.dart';
import 'package:LawyerOnline/chat/widgets/chat_input.dart';
import 'package:LawyerOnline/chat/chat_auto_pop_mixin.dart';
import 'package:LawyerOnline/component/appbar.dart';
import 'package:LawyerOnline/component/dialog_service.dart';
import 'package:LawyerOnline/models/user_profile_store.dart';
import 'package:LawyerOnline/shared/api_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hms_room_kit/hms_room_kit.dart';
import 'package:LawyerOnline/consult/consult_status.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:LawyerOnline/models/lawyer/lawyer_jobs_store.dart';
import 'package:LawyerOnline/services/chat_service.dart';
import 'package:LawyerOnline/menu.dart';
import 'package:easy_localization/easy_localization.dart';

class ChatPageLawyer extends StatefulWidget {
  final Map<String, dynamic> model;
  final bool embeddedMode;
  final String roomCode; // ✅ เพิ่ม
  final String userId; // ✅ เพิ่ม

  const ChatPageLawyer({
    super.key,
    required this.model,
    this.embeddedMode = false,
    this.roomCode = '', // ✅ เพิ่ม
    this.userId = '', // ✅ เพิ่ม
  });

  @override
  State<ChatPageLawyer> createState() => _ChatPageLawyerState();
}

class _ChatPageLawyerState extends State<ChatPageLawyer>
    with AutoPopOnDesktopMixin {
  final ChatService _chatService = ChatService(); // ✅ เพิ่ม
  final TextEditingController _chatController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  // ✅ เปลี่ยนจาก List<_ChatMessage> → Map
  List<Map<String, dynamic>> _messages = [];
  bool _isTyping = false;
  String _typingUser = "";
  // bool _caseSuccess;

  @override
  void didChangeDependencies() {
    if (!widget.embeddedMode) super.didChangeDependencies();
  }

  @override
  void initState() {
    super.initState();
    // _caseSuccess = widget.model['caseSuccess'] as bool? ?? false;
    _setupChat(); // ✅ เพิ่ม
  }

  // ✅ เหมือน ChatPageUser
  // Future<void> _setupChat() async {
  //   // ✅ ตัด connection เก่าทิ้งก่อนเสมอ
  //   await _chatService.disconnect();

  //   _chatService.onReceiveMessage = (message) {
  //     setState(() => _messages.add(message));
  //     _scrollToBottom();
  //   };

  //   _chatService.onLoadHistory = (history) {
  //     setState(() {
  //       _messages = history
  //           .map((e) => e as Map<String, dynamic>)
  //           .toList()
  //           .reversed
  //           .toList();
  //     });
  //     _scrollToBottom();
  //   };

  //   _chatService.onUserTyping = (userId, isTyping) {
  //     if (userId != widget.userId) {
  //       setState(() {
  //         _isTyping = isTyping;
  //         _typingUser = userId;
  //       });
  //     }
  //   };

  //   await _chatService.connect();
  //   await _chatService.joinRoom(widget.roomCode, widget.userId);
  //   await _chatService.loadHistory(widget.roomCode);
  //   await _chatService.markAsRead(widget.roomCode, widget.userId);
  // }

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
        updateStatusCase();
        // final jobId = widget.model['jobId']?.toString() ??
        //     widget.model['id']?.toString() ??
        //     '';
        // if (jobId.isNotEmpty) {
        //   // LawyerJobsStore.instance.updateStatus(jobId, 'done');
        // }
        // final lawyer = {
        //   'name': widget.model['name'] ?? '',
        //   'avatar': (widget.model['name'] as String? ?? 'ท').characters.first,
        //   'title': widget.model['title'] ??
        //       (widget.model['skills'] != null &&
        //               (widget.model['skills'] as List).isNotEmpty
        //           ? (widget.model['skills'] as List).first
        //           : widget.model['experience'] ?? ''),
        //   'rating': widget.model['rating'] ?? widget.model['scroll'] ?? 0,
        //   'imageUrl': widget.model['imageUrl'] ?? '',
        // };
        // Navigator.pushAndRemoveUntil(
        //   context,
        //   MaterialPageRoute(
        //     builder: (_) => ConsultStatusPage(
        //       currentStep: 4,
        //       lawyer: lawyer,
        //       appointmentDate: widget.model['appointmentDate'],
        //       appointmentTime: widget.model['appointmentTime'],
        //     ),
        //   ),
        //   (route) => route.isFirst,
        // );
      },
    );
  }

  Future<void> updateStatusCase() async {
    DialogService.showLoading(context);
    final lawyerCode = UserProfileStore.instance.code;
    try {
      dynamic model = {"code": widget.model['code'], "caseStatus": 4};
      final param = await postDio("${server}/m/case/update", model);
      setState(() {
        if (param['status'] == 'S') {
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
        }
        // appointmentList = param['objectData'];
        // _lawyerAppointments = param['objectData'];
        // _isLoadingAppointments = false;
        print('>>>>>>>>>>>>>>>>>> ${param}');
      });
    } catch (_) {
      // if (!mounted) return;
      // final fallbackAppointments =
      //     LawyerJobsStore.instance.bookingAppointmentsForLawyer(lawyerCode);
      setState(() {
        // _lawyerAppointments = fallbackAppointments;
        // _apiBookingJobs = const [];
        // _appointmentLoadError =
        //     fallbackAppointments.isEmpty ? 'genericError'.tr() : null;
        // _isLoadingAppointments = false;
      });
    }
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
    _chatService.onReceiveMessage = null;
    _chatService.onLoadHistory = null;
    _chatService.onUserTyping = null;
    _chatService.onMessageRead = null;
    _chatService.leaveRoom(widget.roomCode, widget.userId); // ✅ เพิ่ม
    _chatController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final model = widget.model;
    final isActive = model['active'] as bool? ?? true;
    final caseSuccess = model['caseSuccess'] as bool? ?? false;
    final clientColor = model['clientColor'] != null
        ? Color(model['clientColor'] as int)
        : const Color(0xFF0262EC);

    final actionButtons = !caseSuccess
        ? Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _iconBtn(
                  icon: Icons.video_call_outlined,
                  onTap: _showReminderBeforeJoin),
              // const SizedBox(width: 8),
              // _iconBtn(
              //   icon: Icons.task_alt_rounded,
              //   color: const Color(0xFF34C759),
              //   bgColor: const Color(0xFFF0FFF4),
              //   borderColor: const Color(0xFF34C759),
              //   onTap: _endConsultation,
              // ),
            ],
          )
        : null;

    final chatAppBar = widget.embeddedMode
        ? null
        : appBarChat(
            onBack: () => Navigator.pop(context),
            avatarWidget: model['avatar'] != ""
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(100),
                    child: Image.network(
                      model['avatar'],
                      height: 44,
                      width: 44,
                      fit: BoxFit.cover,
                    ),
                  )
                : Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                        color: clientColor, shape: BoxShape.circle),
                    child: Center(
                      child: Text(model['avatar'] ?? '?',
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 18)),
                    ),
                  ),
            name: model['name'] ?? '',
            statusText: caseSuccess
                ? null
                : (isActive ? 'activeNow'.tr() : 'notActive'.tr()),
            actions: actionButtons,
          );

    return Scaffold(
      backgroundColor: const Color(0xFFEEF2F5),
      appBar: chatAppBar as PreferredSizeWidget?,
      body: Column(
        children: [
          if (widget.embeddedMode)
            _buildEmbeddedHeader(
                model, isActive, clientColor, actionButtons, caseSuccess),
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
                  avatarAsset: widget.model['avatar'],
                );
              },
              separatorBuilder: (context, index) => _messages[index]
                          ['senderId'] !=
                      _messages[index + 1]['senderId']
                  ? const SizedBox(
                      height: 10,
                    )
                  : const SizedBox(),
            ),
          ),

          // ✅ Typing indicator
          if (_isTyping)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "$_typingUser กำลังพิมพ์...",
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF8593A8),
                  ),
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

  Widget _buildEmbeddedHeader(
    Map<String, dynamic> model,
    bool isActive,
    Color clientColor,
    Widget? actions,
    bool caseSuccess,
  ) {
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
                if (caseSuccess)
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
}
// ✅ ลบ class _ChatMessage ออกแล้ว ไม่จำเป็นอีกต่อไป
