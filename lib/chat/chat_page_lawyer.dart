import 'dart:io';
import 'package:LawyerOnline/chat/widgets/chat_bubble.dart';
import 'package:LawyerOnline/chat/widgets/chat_input.dart';
import 'package:LawyerOnline/chat/chat_auto_pop_mixin.dart';
import 'package:LawyerOnline/chat/chat_room_lifecycle_mixin.dart';
import 'package:LawyerOnline/component/appbar.dart';
import 'package:LawyerOnline/component/dialog_service.dart';
import 'package:LawyerOnline/models/user_profile_store.dart';
import 'package:LawyerOnline/shared/api_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:LawyerOnline/services/video_call_launcher.dart';
import 'package:LawyerOnline/services/webrtc_call_listener_service.dart';
import 'package:LawyerOnline/consult/consult_status.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:LawyerOnline/services/chat_attachment_service.dart';
import 'package:LawyerOnline/services/chat_service.dart';
import 'package:LawyerOnline/menu.dart';
import 'package:easy_localization/easy_localization.dart';

class ChatPageLawyer extends StatefulWidget {
  final Map<String, dynamic> model;
  final bool embeddedMode;
  final String roomCode;
  final String userId;

  const ChatPageLawyer({
    super.key,
    required this.model,
    this.embeddedMode = false,
    this.roomCode = '',
    this.userId = '',
  });

  @override
  State<ChatPageLawyer> createState() => _ChatPageLawyerState();
}

class _ChatPageLawyerState extends State<ChatPageLawyer>
    with AutoPopOnDesktopMixin, WidgetsBindingObserver, ChatRoomLifecycleMixin {
  final ChatService _chatService = ChatService();
  final TextEditingController _chatController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  List<Map<String, dynamic>> _messages = [];
  bool _isTyping = false;
  bool _isUploadingAttachment = false;
  String _typingUser = '';
  late String _myUserId;

  @override
  ChatService get chatService => _chatService;

  @override
  String get chatRoomCode => widget.roomCode;

  @override
  String get chatUserId => _myUserId;

  @override
  String get chatCaseCode => widget.model['code']?.toString() ?? '';

  @override
  void didChangeDependencies() {
    if (!widget.embeddedMode) super.didChangeDependencies();
  }

  @override
  void initState() {
    super.initState();
    _setupChat();
  }

  Future<void> _setupChat() async {
    await UserProfileStore.instance.load();
    _myUserId = ChatService.resolveMyUserId(widget.userId);

    await _chatService.disconnect();

    _chatService.onReceiveMessage = (message) {
      setState(() => _messages.add(ChatService.normalizeMessage(message)));
      _scrollToBottom();
    };

    _chatService.onLoadHistory = (history) {
      setState(() {
        _messages = history
            .map((e) => ChatService.normalizeMessage(e))
            .toList()
            .reversed
            .toList();
      });
      _scrollToBottom();
    };

    _chatService.onUserTyping = (userId, isTyping) {
      if (userId != _myUserId) {
        setState(() {
          _isTyping = isTyping;
          _typingUser = userId;
        });
      }
    };

    await _chatService.connect();
    await _chatService.joinRoom(widget.roomCode, _myUserId);
    _chatService.setActiveRoom(widget.roomCode);
    await _chatService.loadHistory(widget.roomCode);
    await _chatService.markAsRead(widget.roomCode, _myUserId);
    await WebRtcCallListenerService.instance.joinRoomForChat(
      roomCode: widget.roomCode,
      caseCode: chatCaseCode,
    );
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
    if (text.isEmpty || _isUploadingAttachment) return;
    _chatService.sendMessage(
      widget.roomCode,
      _myUserId,
      content: text,
    );
    _chatController.clear();
    _chatService.typing(widget.roomCode, _myUserId, false);
  }

  Future<void> _pickAttachment() async {
    if (_isUploadingAttachment) return;
    await ChatAttachmentService.showPicker(
      context: context,
      chatService: _chatService,
      roomCode: widget.roomCode,
      senderId: _myUserId,
      onUploadingChanged: (uploading) {
        if (mounted) setState(() => _isUploadingAttachment = uploading);
      },
    );
  }

  // void _endConsultation() {
  //   DialogService.showConfirm(
  //     context,
  //     title: 'endConsultTitle'.tr(),
  //     message: 'endConsultMessageUser'.tr(),
  //     onConfirm: () => updateStatusCase(),
  //   );
  // }

  Future<void> updateStatusCase() async {
    DialogService.showLoading(context);
    try {
      final param = await postDio('${server}/m/case/update', {
        'code': widget.model['code'],
        'caseStatus': 4,
      });
      if (!mounted) return;
      if (param['status'] == 'S') {
        final caseCode = widget.model['code']?.toString() ?? '';
        DialogService.showSuccess(
          context,
          title: 'successTitle'.tr(),
          message: 'endConsultSuccessMessage'.tr(),
          onClose: () => Navigator.pushAndRemoveUntil(
            context,
            // ── ส่งแค่ caseCode ──
            MaterialPageRoute(
              builder: (_) => ConsultStatusPage(caseCode: caseCode),
            ),
            (route) => false,
          ),
        );
      }
    } catch (_) {}
  }

  void _showReminderBeforeJoin() async {
    await _callUser();
    if (!mounted) return;
    VideoCallLauncher.join(
      context: context,
      caseCode: widget.model['code']?.toString() ?? '',
      caseData: widget.model is Map<String, dynamic>
          ? Map<String, dynamic>.from(widget.model as Map)
          : null,
      messageRoomCode: widget.roomCode,
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
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text('callingUser'.tr())));
  }

  @override
  void dispose() {
    _chatService.onReceiveMessage = null;
    _chatService.onLoadHistory = null;
    _chatService.onUserTyping = null;
    _chatService.onMessageRead = null;
    _chatService.setActiveRoom(null);
    _chatService.leaveRoom(widget.roomCode, _myUserId);
    WebRtcCallListenerService.instance.leaveCurrentRoom();
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
                onTap: _showReminderBeforeJoin,
              ),
            ],
          )
        : null;

    final chatAppBar = widget.embeddedMode
        ? null
        : appBarChat(
            onBack: () => Navigator.pop(context),
            avatarWidget: model['avatar'] != null && model['avatar'] != ''
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
                      child: Text(
                        (model['name'] as String? ?? '?').substring(0, 1),
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 18),
                      ),
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
          Expanded(
            child: ListView.separated(
              controller: _scrollController,
              padding: const EdgeInsets.fromLTRB(12, 20, 12, 25),
              itemCount: _messages.length,
              itemBuilder: (_, i) {
                final msg = _messages[i];
                final isMe = ChatService.isMyMessage(msg, _myUserId);
                return ChatBubble(
                  message: msg,
                  isMe: isMe,
                  avatarAsset: widget.model['avatar'],
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
                child: Text(
                  '$_typingUser กำลังพิมพ์...',
                  style: const TextStyle(
                      fontSize: 12, color: Color(0xFF8593A8)),
                ),
              ),
            ),
          caseSuccess
              ? _buildEndedBanner()
              : ChatInput(
                  controller: _chatController,
                  onSend: _sendMessage,
                  onAttach: _pickAttachment,
                  isUploading: _isUploadingAttachment,
                ),
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
              child: Text(
                (model['name'] as String? ?? '?').substring(0, 1),
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18),
              ),
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
}