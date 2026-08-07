import 'dart:async';

import 'package:LawyerOnline/component/dialog_service.dart';
import 'package:LawyerOnline/component/loading_service.dart';
import 'package:LawyerOnline/shared/api_provider.dart';
import 'package:flutter/material.dart';
import 'package:LawyerOnline/component/appbar.dart';
import 'package:LawyerOnline/chat/chat_page_user.dart';
import 'package:LawyerOnline/chat/chat_page_lawyer.dart';
import 'package:LawyerOnline/models/chat/chat_repository.dart';
import 'package:LawyerOnline/shared/responsive/res_layout.dart';
import 'package:LawyerOnline/models/user_profile_store.dart';
import 'package:LawyerOnline/services/chat_list_preview_service.dart';
import 'package:LawyerOnline/services/notification_navigation_service.dart';
import 'package:LawyerOnline/shared/notification_store.dart';
import 'package:easy_localization/easy_localization.dart';

/*
=========================================
  Chat data ย้ายไปไว้ที่ lib/models/chat/chat_repository.dart

  Tablet/Desktop → 2-panel layout (list ซ้าย | chat ขวา) เหมือน FB Messenger
  Mobile         → navigate แบบปกติ (push)

  [FIX] เมื่อ resize จาก mobile → tablet/desktop ขณะอยู่หน้า chat:
        pop route กลับ แล้วแสดง 2-panel layout ทันที (ไม่ต้องย้อนกลับเอง)
=========================================
*/

class MessagePage extends StatefulWidget {
  const MessagePage({
    super.key,
    this.isTabActive = false,
    this.onActive,
  });

  final bool isTabActive;
  final VoidCallback? onActive;

  @override
  State<MessagePage> createState() => _MessagePageState();
}

class _MessagePageState extends State<MessagePage> {
  String _userType = '';
  List<dynamic> _conversations = [];
  bool _isLoading = true;

  // ── Desktop: track conversation ที่ถูกเลือก ──────────────
  dynamic _selectedConv;

  @override
  void initState() {
    super.initState();
    // print('----===start===----- ${widget.isTabActive}');
    _load();
    widget.onActive?.call();
  }

  @override
  void didUpdateWidget(MessagePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isTabActive && !oldWidget.isTabActive) {
      _load();
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _load() async {
    print('----===start===-----');
    await UserProfileStore.instance.load();
    final type = UserProfileStore.instance.userType;
    final userId = UserProfileStore.instance.code;
    final convs = await chatRepository.getConversations(type);

    final result = await postObjectData(
        "/m/chat/readList", {'userType': type, 'reference': userId});
    print('----======----- ${result}');
    if (result['status'] == 'S') {
      final raw = result['objectData'];
      final list = raw is List ? List<dynamic>.from(raw) : <dynamic>[];
      list.sort(_compareConversationsByRecent);
      setState(() {
        _conversations = list;
      });
      await _syncChatBadgeIfNeeded(list);
    }

    if (!mounted) return;
    setState(() {
      _userType = type;
      // _conversations = convs;

      _isLoading = false;
      // auto-select รายการแรกบน desktop
      if (convs.isNotEmpty && !ResponsiveLayout.isMobile(context)) {
        _selectedConv = convs.first;
      }
    });
  }

  int _compareConversationsByRecent(dynamic a, dynamic b) {
    final ta = _conversationTime(a);
    final tb = _conversationTime(b);
    return tb.compareTo(ta);
  }

  DateTime _conversationTime(dynamic conv) {
    if (conv is! Map) return DateTime.fromMillisecondsSinceEpoch(0);
    final map = Map<String, dynamic>.from(conv);
    return ChatListPreviewService.lastMessageAt(map) ??
        DateTime.fromMillisecondsSinceEpoch(0);
  }

  Future<void> _syncChatBadgeIfNeeded(List<dynamic> conversations) async {
    final hasUnread = conversations.any((conv) {
      if (conv is! Map) return false;
      return ChatListPreviewService.unreadCount(
            Map<String, dynamic>.from(conv),
          ) >
          0;
    });
    if (!hasUnread) {
      await NotificationStore.instance.markChatPageRead();
    }
    unawaited(NotificationStore.instance.refresh());
  }

  void _onTapConversation(dynamic conv, bool isDesktop) async {
    await UserProfileStore.instance.load();
    final myUserId = UserProfileStore.instance.code;
    final otherCode = conv['user2Model']?['code']?.toString() ?? '';

    if (otherCode.isEmpty) return;

    final ids = [myUserId, otherCode]..sort();
    final model = {
      'members': ids,
      'userA': myUserId,
      'userB': otherCode,
    };

    final result = await postObjectData('/m/chat/room/create', model);
    if (result['status'] != 'S') {
      if (!mounted) return;
      DialogService.showError(
        context,
        title: 'ผิดพลาด',
        message: 'เกิดข้อผิดพลาด กรุณาลองใหม่อีกครั้ง',
      );
      return;
    }

    final roomCode = result['objectData']?['roomCode']?.toString() ?? '';
    if (roomCode.isEmpty || !mounted) return;

    // ใช้เคสที่ยังเปิดอยู่ของห้องนี้ ไม่ใช่ caseCode เก่าใน chatRoom
    final activeCase =
        await NotificationNavigationService.resolveActiveCaseForRoom(roomCode);
    final caseCode = activeCase?['code']?.toString() ??
        result['objectData']?['caseCode']?.toString() ??
        conv['caseCode']?.toString() ??
        '';
    final caseStatus = activeCase == null
        ? -1
        : (activeCase['caseStatus'] is int
            ? activeCase['caseStatus'] as int
            : int.tryParse(activeCase['caseStatus']?.toString() ?? '') ?? -1);
    final caseSuccess = caseStatus == 4 || caseStatus == 0;

    final chatModel = _userType == 'lawyer'
        ? {
            if (activeCase != null) ...activeCase,
            'name':
                '${conv['user2Model']['firstName']} ${conv['user2Model']['lastName']}',
            'avatar': conv['user2Model']['imageUrl'],
            'caseCode': caseCode,
            'code': caseCode,
            'active': !caseSuccess,
            'caseSuccess': caseSuccess,
          }
        : {
            if (activeCase != null) ...activeCase,
            'name':
                '${conv['user2Model']['firstName']} ${conv['user2Model']['lastName']}',
            'imageUrl': conv['user2Model']['imageUrl'],
            'caseCode': caseCode,
            'code': caseCode,
            'active': !caseSuccess,
            'caseSuccess': caseSuccess,
            'lawyer': result['objectData']?['userB'],
          };

    if (isDesktop) {
      setState(() {
        _selectedConv = {
          ...conv,
          '_roomCode': roomCode,
          '_chatModel': chatModel,
        };
      });
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _userType == 'lawyer'
            ? ChatPageLawyer(
                model: chatModel,
                roomCode: roomCode,
                userId: myUserId,
              )
            : ChatPageUser(
                model: chatModel,
                roomCode: roomCode,
                userId: myUserId,
                caseCode: chatModel['caseCode']?.toString() ?? '',
              ),
      ),
    ).then((_) => _load());
  }

  // ── build ──────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    // อ่าน breakpoint จาก MediaQuery ทุกครั้งที่ build
    // → Flutter จะ rebuild อัตโนมัติเมื่อ MediaQuery เปลี่ยน
    final isMobile = ResponsiveLayout.isMobile(context);

    if (!isMobile) {
      return _buildDesktopLayout(context);
    }

    // Mobile — layout เดิม
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: appBar(
        title: 'messages'.tr(),
        backBtn: false,
        rightBtn: false,
        rightAction: () {},
      ),
      body: _isLoading
          ? AppLoadingView(message: 'loading'.tr())
          : RefreshIndicator(
              color: const Color(0xFF0262EC),
              onRefresh: _load,
              child: _conversations.isEmpty
                  ? ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        SizedBox(
                          height: MediaQuery.of(context).size.height * 0.5,
                          child: Center(
                            child: Text(
                              'noConversations'.tr(),
                              style: const TextStyle(color: Color(0xFF8593A8)),
                            ),
                          ),
                        ),
                      ],
                    )
                  : _buildList(isDesktop: false),
            ),
    );
  }

  // ── Desktop 2-panel layout ─────────────────────────────
  Widget _buildDesktopLayout(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEEF2F5),
      body: Row(
        children: [
          // ── Panel ซ้าย: รายการสนทนา ──────────────────────
          Container(
            width: ResponsiveLayout.isTablet(context) ? 260 : 320,
            decoration: const BoxDecoration(
              color: Color(0xFFFFFFFF),
              border: Border(
                right: BorderSide(color: Color(0xFFE4E8EF), width: 1),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Container(
                  height: 72,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  alignment: Alignment.centerLeft,
                  decoration: const BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: Color(0xFFE4E8EF), width: 1),
                    ),
                  ),
                  child: Text(
                    'messages'.tr(),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1A2540),
                    ),
                  ),
                ),

                // List
                Expanded(
                  child: _isLoading
                      ? AppLoadingView(message: 'loading'.tr(), expand: false)
                      : RefreshIndicator(
                          color: const Color(0xFF0262EC),
                          onRefresh: _load,
                          child: _conversations.isEmpty
                              ? ListView(
                                  physics:
                                      const AlwaysScrollableScrollPhysics(),
                                  children: [
                                    SizedBox(
                                      height: 240,
                                      child: Center(
                                        child: Text(
                                          'noConversations'.tr(),
                                          style: const TextStyle(
                                              color: Color(0xFF8593A8)),
                                        ),
                                      ),
                                    ),
                                  ],
                                )
                              : _buildList(isDesktop: true),
                        ),
                ),
              ],
            ),
          ),

          // ── Panel ขวา: หน้า chat ──────────────────────────
          Expanded(
            child: _selectedConv == null
                ? const _EmptyChat()
                : _buildChatPanel(_selectedConv!),
          ),
        ],
      ),
    );
  }

  // ── Chat panel (desktop) ───────────────────────────────
  Widget _buildChatPanel(dynamic conv) {
    final roomCode = conv['_roomCode']?.toString() ?? '';
    final chatModel = conv['_chatModel'] is Map<String, dynamic>
        ? Map<String, dynamic>.from(conv['_chatModel'] as Map)
        : {
            'name':
                '${conv['user2Model']?['firstName'] ?? ''} ${conv['user2Model']?['lastName'] ?? ''}',
            if (_userType == 'lawyer')
              'avatar': conv['user2Model']?['imageUrl'] ?? ''
            else
              'imageUrl': conv['user2Model']?['imageUrl'] ?? '',
            'active': true,
            'caseSuccess': false,
          };
    final myUserId = UserProfileStore.instance.code;

    if (roomCode.isEmpty) {
      return const _EmptyChat();
    }

    return _userType == 'lawyer'
        ? ChatPageLawyer(
            key: ValueKey(roomCode),
            model: chatModel,
            roomCode: roomCode,
            userId: myUserId,
            embeddedMode: true,
          )
        : ChatPageUser(
            key: ValueKey(roomCode),
            model: chatModel,
            roomCode: roomCode,
            userId: myUserId,
            caseCode: chatModel['caseCode']?.toString() ?? '',
            embeddedMode: true,
          );
  }

  // ── Conversation list ──────────────────────────────────
  Widget _buildList({required bool isDesktop}) {
    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? 12 : 20,
        vertical: isDesktop ? 12 : 20,
      ),
      itemCount: _conversations.length,
      separatorBuilder: (_, __) => SizedBox(height: isDesktop ? 4 : 10),
      itemBuilder: (context, index) => _ConversationItem(
        conv: _conversations[index],
        isSelected: isDesktop &&
            _selectedConv != null &&
            _selectedConv['code'] == _conversations[index]['code'],
        isDesktop: isDesktop,
        onTap: () => _onTapConversation(_conversations[index], isDesktop),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════
//  _ConversationItem
//  - ใช้ AnimatedContainer สำหรับ selected state (ไม่กระพริบ)
//  - ใช้ MouseRegion + InkWell สำหรับ hover (desktop)
// ══════════════════════════════════════════════════════════
class _ConversationItem extends StatefulWidget {
  final dynamic conv;
  final bool isSelected;
  final bool isDesktop;
  final VoidCallback onTap;

  const _ConversationItem({
    required this.conv,
    required this.isSelected,
    required this.isDesktop,
    required this.onTap,
  });

  @override
  State<_ConversationItem> createState() => _ConversationItemState();
}

class _ConversationItemState extends State<_ConversationItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final conv = Map<String, dynamic>.from(widget.conv as Map);
    final isDesktop = widget.isDesktop;
    final myUserId = UserProfileStore.instance.code;
    final unread = ChatListPreviewService.unreadCount(conv);
    final subtitle = ChatListPreviewService.subtitle(conv, myUserId);
    final subtitleBold = ChatListPreviewService.isSubtitleBold(conv, myUserId);
    final nameBold = ChatListPreviewService.isNameBold(conv);
    final headerTime = ChatListPreviewService.headerTimeLabel(conv);
    final peerName = ChatListPreviewService.peerName(conv);

    final bool showHover = _isHovered && !widget.isSelected;
    final Color bgColor;
    if (widget.isSelected && isDesktop) {
      bgColor = const Color(0xFFE8F0FE);
    } else if (showHover) {
      bgColor = const Color(0xFFF0F2F5);
    } else {
      bgColor =
          isDesktop ? const Color.fromARGB(0, 255, 255, 255) : Colors.white;
    }

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) {
        if (!widget.isSelected) setState(() => _isHovered = true);
      },
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _isHovered = false),
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: Duration(milliseconds: widget.isSelected ? 200 : 120),
          curve: Curves.easeOut,
          padding: EdgeInsets.symmetric(
            horizontal: isDesktop ? 12 : 15,
            vertical: 10,
          ),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(isDesktop ? 10 : 14),
            boxShadow: isDesktop
                ? null
                : [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // ── Avatar ─────────────────────────────────────
              Stack(
                children: [
                  (conv['user2Model']?['imageUrl']?.toString() ?? '') != ''
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(100),
                          child: Image.network(
                            conv['user2Model']['imageUrl'],
                            height: 48,
                            width: 48,
                            fit: BoxFit.cover,
                          ),
                        )
                      : ClipRRect(
                          borderRadius: BorderRadius.circular(100),
                          child: Image.asset(
                            "assets/images/profile-avatar.jpg",
                            height: 48,
                            width: 48,
                            fit: BoxFit.cover,
                          ),
                        ),
                  // if (!conv.caseSuccess)
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: const Color(0xFF00CC5E),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 1.5),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 12),

              // ── ชื่อ + ข้อความล่าสุด ────────────────────────
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            peerName,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: nameBold
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              color: const Color(0xFF1A2540),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (headerTime.isNotEmpty) ...[
                          const SizedBox(width: 4),
                          Text(
                            headerTime,
                            style: TextStyle(
                              fontSize: 11,
                              color: unread > 0
                                  ? const Color(0xFF0262EC)
                                  : const Color(0xFF8593A8),
                              fontWeight: unread > 0
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            subtitle,
                            style: TextStyle(
                              fontSize: 13,
                              color: unread > 0 && !subtitleBold
                                  ? const Color(0xFF0262EC)
                                  : const Color(0xFF8593A8),
                              fontWeight: subtitleBold
                                  ? FontWeight.w700
                                  : FontWeight.w400,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (unread > 1) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0262EC),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              unread > 99 ? '99+' : '$unread',
                              style: const TextStyle(
                                fontSize: 11,
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Empty state (ยังไม่เลือก conversation) ─────────────────
class _EmptyChat extends StatelessWidget {
  const _EmptyChat();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.chat_bubble_outline_rounded,
              size: 64, color: Color(0xFFD1D9E6)),
          const SizedBox(height: 16),
          Text(
            'selectConversation'.tr(),
            style: const TextStyle(fontSize: 16, color: Color(0xFF8593A8)),
          ),
        ],
      ),
    );
  }
}
