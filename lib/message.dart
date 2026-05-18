import 'package:flutter/material.dart';
import 'package:LawyerOnline/component/appbar.dart';
import 'package:LawyerOnline/chat/chat_page_user.dart';
import 'package:LawyerOnline/chat/chat_page_lawyer.dart';
import 'package:LawyerOnline/models/chat/chat_repository.dart';
import 'package:LawyerOnline/shared/responsive/res_layout.dart';
import 'package:LawyerOnline/models/user_profile_store.dart';
import 'package:easy_localization/easy_localization.dart';

/*
=========================================
  Chat data ย้ายไปไว้ที่ lib/models/chat/chat_repository.dart

  Tablet/Desktop → 2-panel layout (list ซ้าย | chat ขวา) เหมือน FB Messenger
  Mobile         → navigate แบบปกติ (push)
=========================================
*/

class MessagePage extends StatefulWidget {
  const MessagePage({super.key});

  @override
  State<MessagePage> createState() => _MessagePageState();
}

class _MessagePageState extends State<MessagePage> {
  String _userType = '';
  List<Conversation> _conversations = [];
  bool _isLoading = true;

  // ── Desktop: track conversation ที่ถูกเลือก ──────────────
  Conversation? _selectedConv;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    // ใช้ UserProfileStore แทน FlutterSecureStorage โดยตรง
    // เพราะมี _SafeStorage wrapper ป้องกัน OperationError บน Web แล้ว
    await UserProfileStore.instance.load();
    final type = UserProfileStore.instance.userType;
    final convs = await chatRepository.getConversations(type);

    if (!mounted) return;
    setState(() {
      _userType = type;
      _conversations = convs;
      _isLoading = false;
      // auto-select รายการแรกบน desktop
      if (convs.isNotEmpty) _selectedConv = convs.first;
    });
  }

  void _onTapConversation(Conversation conv, bool isDesktop) {
    if (isDesktop) {
      setState(() => _selectedConv = conv);
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => _userType == 'lawyer'
              ? ChatPageLawyer(
                  model: {
                    'name': conv.name,
                    'avatar': conv.avatar,
                    'clientColor': conv.clientColor,
                    'active': !conv.caseSuccess,
                    'caseSuccess': conv.caseSuccess,
                  },
                  jobId: conv.id,
                )
              : ChatPageUser(
                  model: {
                    'name': conv.name,
                    'imageUrl': conv.avatar,
                    'active': !conv.caseSuccess,
                    'caseSuccess': conv.caseSuccess,
                  },
                ),
        ),
      ).then((_) => _load());
    }
  }

  // ── build ──────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
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
          ? const Center(child: CircularProgressIndicator())
          : _conversations.isEmpty
              ? Center(
                  child: Text('noConversations'.tr(),
                      style: const TextStyle(color: Color(0xFF8593A8))))
              : Column(
                  children: [
                    const SizedBox(height: 20),
                    Expanded(child: _buildList(isDesktop: false)),
                  ],
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
                      ? const Center(child: CircularProgressIndicator())
                      : _conversations.isEmpty
                          ? Center(
                              child: Text('noConversations'.tr(),
                                  style: const TextStyle(
                                      color: Color(0xFF8593A8))))
                          : _buildList(isDesktop: true),
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
  Widget _buildChatPanel(Conversation conv) {
    final model = _userType == 'lawyer'
        ? {
            'name': conv.name,
            'avatar': conv.avatar,
            'clientColor': conv.clientColor,
            'active': !conv.caseSuccess,
            'caseSuccess': conv.caseSuccess,
          }
        : {
            'name': conv.name,
            'imageUrl': conv.avatar,
            'active': !conv.caseSuccess,
            'caseSuccess': conv.caseSuccess,
          };

    return _userType == 'lawyer'
        ? ChatPageLawyer(
            key: ValueKey(conv.id),
            model: model,
            jobId: conv.id,
            embeddedMode: true,
          )
        : ChatPageUser(
            key: ValueKey(conv.id),
            model: model,
            embeddedMode: true,
          );
  }

  // ── Conversation list ──────────────────────────────────
  Widget _buildList({required bool isDesktop}) {
    return ListView.separated(
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? 12 : 20,
        vertical: isDesktop ? 12 : 0,
      ),
      itemCount: _conversations.length,
      separatorBuilder: (_, __) => SizedBox(height: isDesktop ? 4 : 10),
      itemBuilder: (context, index) => _ConversationItem(
        conv: _conversations[index],
        isSelected: isDesktop && _selectedConv?.id == _conversations[index].id,
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
//  - ไม่ใช้ AnimationController + ColorTween เพราะทำให้กระพริบ
// ══════════════════════════════════════════════════════════
class _ConversationItem extends StatefulWidget {
  final Conversation conv;
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
    final conv = widget.conv;
    final isDesktop = widget.isDesktop;

    // ── สีพื้นหลัง ─────────────────────────────────────────
    // selected ชนะเสมอ — hover จะไม่แสดงถ้า isSelected = true
    final bool showHover = _isHovered && !widget.isSelected;
    final Color bgColor;
    if (widget.isSelected && isDesktop) {
      bgColor = const Color(0xFFE8F0FE); // สีฟ้าอ่อนเมื่อเลือก
    } else if (showHover) {
      bgColor = const Color(0xFFF0F2F5);
    } else {
      // bgColor = isDesktop ? Colors.transparent : Colors.white;
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
                  conv.avatarIsImage
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(100),
                          child: Image.asset(
                            conv.avatar,
                            height: 48,
                            width: 48,
                            fit: BoxFit.cover,
                          ),
                        )
                      : Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: Color(conv.clientColor),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              conv.avatar,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 20,
                              ),
                            ),
                          ),
                        ),
                  // online dot
                  if (!conv.caseSuccess)
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
                            conv.name,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: conv.unreadCount > 0
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          conv.lastChatDate,
                          style: const TextStyle(
                              fontSize: 11, color: Color(0xFF8593A8)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            conv.lastChat,
                            style: TextStyle(
                              fontSize: 13,
                              color: conv.unreadCount > 0
                                  ? Colors.black
                                  : const Color(0xFF8593A8),
                              fontWeight: conv.unreadCount > 0
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (conv.unreadCount > 0)
                          Container(
                            width: 20,
                            height: 20,
                            decoration: BoxDecoration(
                              color: const Color(0xFF0262EC),
                              borderRadius: BorderRadius.circular(100),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              conv.unreadCount.toString(),
                              style: const TextStyle(
                                  fontSize: 12, color: Colors.white),
                            ),
                          ),
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
          Icon(Icons.chat_bubble_outline_rounded,
              size: 64, color: Color(0xFFD1D9E6)),
          SizedBox(height: 16),
          Text(
            'selectConversation'.tr(),
            style: const TextStyle(fontSize: 16, color: Color(0xFF8593A8)),
          ),
        ],
      ),
    );
  }
}
