import 'package:LawyerOnline/chat/widgets/chat_bubble.dart';
import 'package:LawyerOnline/chat/widgets/chat_input.dart';
import 'package:LawyerOnline/chat/chat_auto_pop_mixin.dart';
import 'package:LawyerOnline/chat/chat_room_lifecycle_mixin.dart';
import 'package:LawyerOnline/component/appbar.dart';
import 'package:LawyerOnline/component/dialog_service.dart';
import 'package:LawyerOnline/models/user_profile_store.dart';
import 'package:LawyerOnline/shared/api_provider.dart';
import 'package:flutter/material.dart';
import 'package:LawyerOnline/services/video_call_launcher.dart';
import 'package:LawyerOnline/services/video_call_service.dart';
import 'package:LawyerOnline/services/webrtc_call_listener_service.dart';
import 'package:LawyerOnline/services/notification_navigation_service.dart';
import 'package:LawyerOnline/consult/consult_status.dart';
import 'package:LawyerOnline/services/chat_attachment_service.dart';
import 'package:LawyerOnline/services/chat_service.dart';
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
  Map<String, dynamic> _caseData = {};

  @override
  ChatService get chatService => _chatService;

  @override
  String get chatRoomCode => widget.roomCode;

  @override
  String get chatUserId => _myUserId;

  @override
  String get chatCaseCode {
    final code = widget.model['code']?.toString() ?? '';
    if (code.isNotEmpty) return code;
    return widget.model['caseCode']?.toString() ?? '';
  }

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
    await _loadCase();
  }

  Future<void> _loadCase() async {
    var code = chatCaseCode;
    if (code.isEmpty && widget.roomCode.isNotEmpty) {
      final active =
          await NotificationNavigationService.resolveActiveCaseForRoom(
              widget.roomCode);
      if (active != null && mounted) {
        setState(() => _caseData = active);
        return;
      }
    }
    if (code.isEmpty) return;
    try {
      final param = await postDio('${server}/m/case/read', {'code': code});
      if (!mounted) return;
      final raw = param['objectData'] is List
          ? (param['objectData'] as List).first
          : param['objectData'];
      if (raw is Map) {
        var caseMap = Map<String, dynamic>.from(raw);
        final status = _asStatus(caseMap['caseStatus']);
        if ((status == 4 || status == 0) && widget.roomCode.isNotEmpty) {
          final active =
              await NotificationNavigationService.resolveActiveCaseForRoom(
                  widget.roomCode);
          if (active != null) caseMap = active;
        }
        setState(() => _caseData = caseMap);
      }
    } catch (_) {}
  }

  void _scrollToBottom({int retry = 0}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      final max = _scrollController.position.maxScrollExtent;

      // บางครั้งค่า maxScrollExtent ยังไม่อัปเดตตอนเฟรมแรก
      if (max <= 0 && retry < 3 && _messages.isNotEmpty) {
        _scrollToBottom(retry: retry + 1);
        return;
      }

      try {
        _scrollController.animateTo(
          max,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      } catch (_) {
        try {
          _scrollController.jumpTo(max);
        } catch (_) {}
      }
    });
  }

  Map<String, dynamic> get _caseMap {
    final merged = Map<String, dynamic>.from(widget.model);
    if (_caseData.isNotEmpty) {
      merged.addAll(_caseData);
      // คงชื่อ/avatar จาก chat model
      if (widget.model['name'] != null) merged['name'] = widget.model['name'];
      if (widget.model['avatar'] != null) {
        merged['avatar'] = widget.model['avatar'];
      }
      // สถานะจาก API เป็นหลัก — อย่าใช้ caseSuccess ค้างจากเคสเก่า
      final status = _asStatus(merged['caseStatus']);
      merged['caseSuccess'] = status == 4 || status == 0;
      if (merged['code'] == null || merged['code'].toString().isEmpty) {
        merged['code'] = widget.model['code'] ?? widget.model['caseCode'];
      }
    }
    return merged;
  }

  bool get _canInteract {
    final status = _asStatus(_caseMap['caseStatus']);
    if (status == 4 || status == 0) return false;
    if (_caseData.isEmpty &&
        (widget.model['caseSuccess'] as bool? ?? false)) {
      return false;
    }
    return VideoCallService.canChatAndCall(_caseMap);
  }

  int _asStatus(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? -1;
  }

  void _sendMessage() {
    if (!_canInteract) return;
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
    if (!_canInteract || _isUploadingAttachment) return;
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

  void _showReminderBeforeJoin() {
    if (!_canInteract) return;
    VideoCallLauncher.join(
      context: context,
      caseCode: widget.model['code']?.toString() ?? '',
      caseData: _caseMap,
      messageRoomCode: widget.roomCode,
      peerName: widget.model['name']?.toString() ?? '',
      onLeave: _rejoinChatAfterCall,
    );
  }

  Future<void> _rejoinChatAfterCall() async {
    if (!mounted || widget.roomCode.isEmpty) return;
    try {
      await _chatService.connect();
      await _chatService.joinRoom(widget.roomCode, _myUserId);
      _chatService.setActiveRoom(widget.roomCode);
      _chatService.onReceiveMessage = (message) {
        if (!mounted) return;
        setState(() => _messages.add(ChatService.normalizeMessage(message)));
        _scrollToBottom();
      };
      await WebRtcCallListenerService.instance.joinRoomForChat(
        roomCode: widget.roomCode,
        caseCode: chatCaseCode,
      );
    } catch (_) {}
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
    final caseMap = _caseMap;
    final isActive = model['active'] as bool? ?? true;
    final caseSuccess = (_asStatus(caseMap['caseStatus']) == 4) ||
        (_asStatus(caseMap['caseStatus']) == 0) ||
        ((_caseData.isEmpty) && (model['caseSuccess'] as bool? ?? false));
    final joinResult = VideoCallService.checkJoinWindow(caseMap);
    final canInteract =
        !caseSuccess && joinResult == VideoCallJoinResult.allowed;
    final waitingForWindow =
        !caseSuccess && joinResult == VideoCallJoinResult.tooEarly;
    final windowExpired =
        !caseSuccess && joinResult == VideoCallJoinResult.tooLate;
    final appointmentDate = caseMap['caseDate']?.toString() ??
        caseMap['appointmentDate']?.toString() ??
        '';
    final appointmentTime =
        '${caseMap['startTime'] ?? ''} ${caseMap['endTime'] ?? ''}'.trim();
    final clientColor = model['clientColor'] != null
        ? Color(model['clientColor'] as int)
        : const Color(0xFF0262EC);

    final actionButtons = canInteract
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
                : (canInteract
                    ? (isActive ? 'activeNow'.tr() : 'notActive'.tr())
                    : (waitingForWindow
                        ? 'chatWindowWaitingTitle'.tr()
                        : 'chatWindowHistoryOnly'.tr())),
            actions: actionButtons,
          );

    return Scaffold(
      backgroundColor: const Color(0xFFEEF2F5),
      appBar: chatAppBar as PreferredSizeWidget?,
      body: Column(
        children: [
          if (widget.embeddedMode)
            _buildEmbeddedHeader(
                model, isActive, clientColor, actionButtons, caseSuccess,
                canInteract: canInteract,
                waitingForWindow: waitingForWindow),
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
                  currentUserId: _myUserId,
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
          if (_isTyping && canInteract)
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
          if (caseSuccess)
            _buildEndedBanner()
          else if (waitingForWindow)
            _buildLockedBanner(appointmentDate, appointmentTime)
          else if (windowExpired)
            _buildExpiredBanner()
          else
            ChatInput(
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
    bool caseSuccess, {
    bool canInteract = false,
    bool waitingForWindow = false,
  }) {
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
                  Text(
                      canInteract
                          ? (isActive
                              ? 'activeNow'.tr()
                              : 'notActive'.tr())
                          : (waitingForWindow
                              ? 'chatWindowWaitingTitle'.tr()
                              : 'chatWindowHistoryOnly'.tr()),
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
                  Text('chatWindowWaitingTitle'.tr(),
                      style: const TextStyle(
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

  Widget _buildExpiredBanner() {
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
          color: const Color(0xFFFFF6F0),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: const Color(0xFFE87B3A).withOpacity(0.25)),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: const Color(0xFFE87B3A).withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.history_toggle_off_rounded,
                  size: 18, color: Color(0xFFE87B3A)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('chatWindowExpiredTitle'.tr(),
                      style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFFC45A1A))),
                  const SizedBox(height: 3),
                  Text('chatWindowExpiredMessage'.tr(),
                      style: const TextStyle(
                          fontSize: 12, color: Color(0xFF8A6A55))),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}