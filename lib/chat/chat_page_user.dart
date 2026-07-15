import 'package:LawyerOnline/chat/widgets/chat_bubble.dart';
import 'package:LawyerOnline/chat/widgets/chat_input.dart';
import 'package:LawyerOnline/chat/chat_auto_pop_mixin.dart';
import 'package:LawyerOnline/chat/chat_room_lifecycle_mixin.dart';
import 'package:LawyerOnline/component/appbar.dart';
import 'package:LawyerOnline/component/dialog_service.dart';
import 'package:LawyerOnline/component/loading_service.dart';
import 'package:LawyerOnline/consult/consult_status.dart';
import 'package:LawyerOnline/models/lawyer/lawyer_jobs_store.dart';
import 'package:LawyerOnline/models/user_profile_store.dart';
import 'package:LawyerOnline/services/chat_attachment_service.dart';
import 'package:LawyerOnline/services/chat_service.dart';
import 'package:LawyerOnline/services/notification_navigation_service.dart';
import 'package:LawyerOnline/shared/api_provider.dart';
import 'package:flutter/material.dart';
import 'package:LawyerOnline/services/video_call_launcher.dart';
import 'package:LawyerOnline/services/video_call_service.dart';
import 'package:LawyerOnline/services/webrtc_call_listener_service.dart';
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
    with AutoPopOnDesktopMixin, WidgetsBindingObserver, ChatRoomLifecycleMixin {
  final ChatService _chatService = ChatService();
  final TextEditingController _chatController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  List<Map<String, dynamic>> _messages = [];
  bool _isTyping = false;
  String _typingUser = '';
  bool _isLoading = true;
  bool _isUploadingAttachment = false;
  dynamic _caseData = {};
  late String _myUserId;

  @override
  ChatService get chatService => _chatService;

  @override
  String get chatRoomCode => widget.roomCode;

  @override
  String get chatUserId => _myUserId;

  @override
  String get chatCaseCode => widget.caseCode.isNotEmpty
      ? widget.caseCode
      : widget.model['code']?.toString() ?? '';

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
    // ใช้ caseCode ที่รับมาตรงๆ ก่อน ถ้าไม่มีค่อย fallback ไปหาใน model
    var code = widget.caseCode.isNotEmpty
        ? widget.caseCode
        : widget.model['code']?.toString() ??
            widget.model['caseCode']?.toString() ??
            '';
    if (code.isEmpty && widget.roomCode.isNotEmpty) {
      final active =
          await NotificationNavigationService.resolveActiveCaseForRoom(
              widget.roomCode);
      if (active != null && mounted) {
        setState(() {
          _caseData = active;
          _isLoading = false;
        });
        return;
      }
    }
    if (code.isEmpty) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }
    try {
      final param = await postDio('${server}/m/case/read', {'code': code});
      if (mounted) {
        var data = param['objectData'] is List
            ? (param['objectData'] as List).first
            : param['objectData'] ?? {};
        Map<String, dynamic> caseMap = data is Map
            ? Map<String, dynamic>.from(data)
            : <String, dynamic>{};

        // ถ้าเคสนี้จบแล้ว แต่ห้องเดียวกันมีเคสใหม่ที่ยังเปิด → ใช้เคสใหม่
        final status = caseMap['caseStatus'];
        final statusInt = status is int
            ? status
            : int.tryParse(status?.toString() ?? '') ?? -1;
        if ((statusInt == 4 || statusInt == 0) &&
            widget.roomCode.isNotEmpty) {
          final active =
              await NotificationNavigationService.resolveActiveCaseForRoom(
                  widget.roomCode);
          if (active != null) caseMap = active;
        }

        setState(() {
          _caseData = caseMap;
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

  Map<String, dynamic> get _caseMap {
    if (_caseData is Map<String, dynamic>) {
      return Map<String, dynamic>.from(_caseData as Map);
    }
    if (_caseData is Map) {
      return Map<String, dynamic>.from(_caseData as Map);
    }
    return <String, dynamic>{};
  }

  bool get _canInteract {
    final caseStatus = _asCaseStatus(_caseMap['caseStatus']);
    if (caseStatus == 4 || caseStatus == 0) return false;
    return VideoCallService.canChatAndCall(_caseMap);
  }

  int _asCaseStatus(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
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

  // caseCode สำหรับนำทางไป ConsultStatusPage
  void _endConsultation() {
    DialogService.showConfirm(
      context,
      title: 'endConsultTitle'.tr(),
      message: 'endConsultMessageUser'.tr(),
      onConfirm: () async {
        final param = await postDio('${server}/m/case/update', {
          'code': widget.model['caseCode'],
          'caseStatus': 4,
          'isReview': false,
          'lawyer': widget.model['lawyer']
        });
        if (!mounted) return;
        print('------>>> ${param}');
        if (param['status'] == 'S') {
          await _chatService.disconnect();
          Navigator.pushAndRemoveUntil(
            context,
            // ── ส่งแค่ caseCode ──
            MaterialPageRoute(
              builder: (_) => ConsultStatusPage(caseCode: widget.caseCode),
            ),
            (route) => route.isFirst,
          );
        }
        print('------>>> ${widget.caseCode}');
      },
    );
  }

  void _showReminderBeforeJoin() {
    if (!_canInteract) return;
    VideoCallLauncher.join(
      context: context,
      caseCode: widget.caseCode,
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
    LawyerJobsStore.instance.removeListener(() {});
    _chatController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return _buildLoadingState();

    final caseMap = _caseMap;
    final caseStatus = _asCaseStatus(caseMap['caseStatus']);
    final caseSuccess = caseStatus == 4;
    final joinResult = VideoCallService.checkJoinWindow(caseMap);
    final canInteract = !caseSuccess && joinResult == VideoCallJoinResult.allowed;
    final waitingForWindow =
        !caseSuccess && joinResult == VideoCallJoinResult.tooEarly;
    final windowExpired =
        !caseSuccess && joinResult == VideoCallJoinResult.tooLate;
    final imageUrl = widget.model['imageUrl'] as String? ?? '';
    final appointmentDate = caseMap['caseDate']?.toString() ?? '';
    final appointmentTime =
        '${caseMap['startTime'] ?? ''} ${caseMap['endTime'] ?? ''}'.trim();

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
            statusText: caseSuccess
                ? null
                : (windowExpired || waitingForWindow
                    ? 'chatWindowHistoryOnly'.tr()
                    : 'activeNow'.tr()),
            actions: canInteract
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
            _buildEmbeddedHeader(caseSuccess, canInteract, waitingForWindow,
                imageUrl, appointmentDate, appointmentTime),
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
          if (_isTyping && canInteract)
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
      bool caseSuccess,
      bool canInteract,
      bool waitingForWindow,
      String imageUrl,
      String date,
      String time) {
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
                  Text(
                      canInteract
                          ? 'activeNow'.tr()
                          : (waitingForWindow
                              ? 'chatWindowWaitingTitle'.tr()
                              : 'chatWindowHistoryOnly'.tr()),
                      style: const TextStyle(
                          fontSize: 12, color: Color(0xFF8593A8))),
              ],
            ),
          ),
          if (canInteract) ...[
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

  Widget _buildLoadingState() {
    return Scaffold(
      backgroundColor: const Color(0xFFEEF2F5),
      body: AppLoadingView(message: 'loading'.tr()),
    );
  }
}