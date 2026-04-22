import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class CommunityPage extends StatefulWidget {
  const CommunityPage({super.key});

  @override
  State<CommunityPage> createState() => _CommunityPageState();
}

class _CommunityPageState extends State<CommunityPage>
    with SingleTickerProviderStateMixin {
  final _firestore = FirebaseFirestore.instance;
  final _storage = const FlutterSecureStorage();
  String _userName = '';
  String _userType = '';

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final name = await _storage.read(key: 'name') ?? 'ผู้ใช้งาน';
    final type = await _storage.read(key: 'userType') ?? 'user';
    setState(() {
      _userName = name;
      _userType = type;
    });
  }

  void _showPostDialog() {
    final controller = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _PostBottomSheet(
        userName: _userName,
        userType: _userType,
        onPost: (text) async {
          if (text.trim().isEmpty) return;
          await _firestore.collection('community_posts').add({
            'text': text.trim(),
            'authorName': _userName,
            'authorType': _userType,
            'likes': [],
            'commentCount': 0,
            'createdAt': FieldValue.serverTimestamp(),
          });
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FB),
      body: CustomScrollView(
        slivers: [
          // ── App Bar ──────────────────────────────────────────────
          SliverAppBar(
            expandedHeight: 110,
            pinned: true,
            backgroundColor: const Color(0xFF061B4A),
            flexibleSpace: const FlexibleSpaceBar(
              titlePadding:
                  EdgeInsets.only(left: 20, bottom: 14),
              title: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'ชุมชน',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'ปรึกษาปัญหากฎหมายกับชุมชน',
                    style: TextStyle(
                      color: Colors.white60,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: TextButton.icon(
                  onPressed: _showPostDialog,
                  style: TextButton.styleFrom(
                    backgroundColor: const Color(0xFF0262EC),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 6),
                  ),
                  icon: const Icon(Icons.edit_outlined,
                      color: Colors.white, size: 15),
                  label: const Text(
                    'โพสต์',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600),
                  ),
                ),
              )
            ],
          ),

          // ── Post List ─────────────────────────────────────────────
          StreamBuilder<QuerySnapshot>(
            stream: _firestore
                .collection('community_posts')
                .orderBy('createdAt', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SliverFillRemaining(
                  child: Center(
                    child: CircularProgressIndicator(
                        color: Color(0xFF0262EC)),
                  ),
                );
              }

              final docs = snapshot.data?.docs ?? [];

              if (docs.isEmpty) {
                return SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.forum_outlined,
                            size: 64,
                            color: Colors.grey.shade300),
                        const SizedBox(height: 12),
                        Text(
                          'ยังไม่มีโพสต์\nเป็นคนแรกที่ตั้งคำถาม!',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.grey.shade400,
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final doc = docs[index];
                    return _PostCard(
                      doc: doc,
                      currentUser: _userName,
                      currentUserType: _userType,
                    );
                  },
                  childCount: docs.length,
                ),
              );
            },
          ),
        ],
      ),

      // ── FAB ──────────────────────────────────────────────────────
      // floatingActionButton: FloatingActionButton.extended(
      //   onPressed: _showPostDialog,
      //   backgroundColor: const Color(0xFF0262EC),
      //   icon: const Icon(Icons.edit_outlined, color: Colors.white),
      //   label: const Text(
      //     'โพสต์ปัญหา',
      //     style: TextStyle(
      //         color: Colors.white, fontWeight: FontWeight.w600),
      //   ),
      // ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// POST CARD
// ─────────────────────────────────────────────────────────────────────────────
class _PostCard extends StatelessWidget {
  final QueryDocumentSnapshot doc;
  final String currentUser;
  final String currentUserType;

  const _PostCard({
    required this.doc,
    required this.currentUser,
    required this.currentUserType,
  });

  String _timeAgo(Timestamp? ts) {
    if (ts == null) return '';
    final diff = DateTime.now().difference(ts.toDate());
    if (diff.inMinutes < 1) return 'เมื่อกี้';
    if (diff.inHours < 1) return '${diff.inMinutes} นาทีที่แล้ว';
    if (diff.inDays < 1) return '${diff.inHours} ชั่วโมงที่แล้ว';
    if (diff.inDays < 30) return '${diff.inDays} วันที่แล้ว';
    return '${ts.toDate().day}/${ts.toDate().month}/${ts.toDate().year + 543}';
  }

  Future<void> _toggleLike(BuildContext context) async {
    HapticFeedback.lightImpact();
    final likes = List<String>.from(doc['likes'] ?? []);
    if (likes.contains(currentUser)) {
      likes.remove(currentUser);
    } else {
      likes.add(currentUser);
    }
    await FirebaseFirestore.instance
        .collection('community_posts')
        .doc(doc.id)
        .update({'likes': likes});
  }

  @override
  Widget build(BuildContext context) {
    final data = doc.data() as Map<String, dynamic>;
    final likes = List<String>.from(data['likes'] ?? []);
    final isLiked = likes.contains(currentUser);
    final authorType = data['authorType'] ?? 'user';
    final isLawyer = authorType == 'lawyer';

    return Container(
      margin: const EdgeInsets.fromLTRB(14, 8, 14, 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF061B4A).withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ──────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Row(
              children: [
                // Avatar
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: isLawyer
                        ? const Color(0xFF0262EC).withOpacity(0.1)
                        : const Color(0xFFF4F6FB),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isLawyer
                          ? const Color(0xFF0262EC).withOpacity(0.3)
                          : Colors.grey.shade200,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      (data['authorName'] ?? '?')
                          .substring(0, 1),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isLawyer
                            ? const Color(0xFF0262EC)
                            : Colors.grey.shade600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            data['authorName'] ?? 'ไม่ทราบชื่อ',
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                              color: Color(0xFF1A1A2E),
                            ),
                          ),
                          if (isLawyer) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFF0262EC),
                                borderRadius:
                                    BorderRadius.circular(20),
                              ),
                              child: const Text(
                                'ทนายความ',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      Text(
                        _timeAgo(data['createdAt'] as Timestamp?),
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade400,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── Content ─────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
            child: Text(
              data['text'] ?? '',
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF2D2D2D),
                height: 1.55,
              ),
            ),
          ),

          // ── Divider ─────────────────────────────────────────────
          Divider(height: 1, color: Colors.grey.shade100),

          // ── Actions ─────────────────────────────────────────────
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            child: Row(
              children: [
                // Like
                _ActionButton(
                  icon: isLiked
                      ? Icons.favorite_rounded
                      : Icons.favorite_border_rounded,
                  label: '${likes.length}',
                  color: isLiked
                      ? Colors.red.shade400
                      : Colors.grey.shade500,
                  onTap: () => _toggleLike(context),
                ),
                // Comment
                _ActionButton(
                  icon: Icons.chat_bubble_outline_rounded,
                  label: '${data['commentCount'] ?? 0}',
                  color: Colors.grey.shade500,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => _CommentPage(
                          postId: doc.id,
                          postText: data['text'] ?? '',
                          currentUser: currentUser,
                          currentUserType: currentUserType,
                        ),
                      ),
                    );
                  },
                ),
                const Spacer(),
                // Share button (optional)
                _ActionButton(
                  icon: Icons.ios_share_rounded,
                  label: '',
                  color: Colors.grey.shade400,
                  onTap: () {},
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ACTION BUTTON
// ─────────────────────────────────────────────────────────────────────────────
class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Row(
          children: [
            Icon(icon, size: 20, color: color),
            if (label.isNotEmpty) ...[
              const SizedBox(width: 5),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  color: color,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// POST BOTTOM SHEET
// ─────────────────────────────────────────────────────────────────────────────
class _PostBottomSheet extends StatefulWidget {
  final String userName;
  final String userType;
  final Future<void> Function(String text) onPost;

  const _PostBottomSheet({
    required this.userName,
    required this.userType,
    required this.onPost,
  });

  @override
  State<_PostBottomSheet> createState() => _PostBottomSheetState();
}

class _PostBottomSheetState extends State<_PostBottomSheet> {
  final _controller = TextEditingController();
  bool _isPosting = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Title
            Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: const Color(0xFF0262EC).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      widget.userName.substring(0, 1),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0262EC),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.userName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      'โพสต์แบบสาธารณะ',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 14),

            // Input
            TextField(
              controller: _controller,
              maxLines: 5,
              maxLength: 500,
              autofocus: true,
              decoration: InputDecoration(
                hintText:
                    'ปัญหาที่ต้องการปรึกษา เช่น เรื่องสัญญา, ที่ดิน, หนี้สิน...',
                hintStyle:
                    TextStyle(color: Colors.grey.shade400, fontSize: 14),
                border: InputBorder.none,
                counterStyle: TextStyle(
                    color: Colors.grey.shade400, fontSize: 11),
              ),
              onChanged: (_) => setState(() {}),
            ),

            const SizedBox(height: 10),

            // Post button
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      _controller.text.trim().isNotEmpty
                          ? const Color(0xFF0262EC)
                          : Colors.grey.shade200,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
                onPressed: _controller.text.trim().isEmpty || _isPosting
                    ? null
                    : () async {
                        setState(() => _isPosting = true);
                        await widget.onPost(_controller.text);
                        if (mounted) Navigator.pop(context);
                      },
                child: _isPosting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Text(
                        'โพสต์',
                        style: TextStyle(
                          color: _controller.text.trim().isNotEmpty
                              ? Colors.white
                              : Colors.grey.shade400,
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// COMMENT PAGE
// ─────────────────────────────────────────────────────────────────────────────
class _CommentPage extends StatefulWidget {
  final String postId;
  final String postText;
  final String currentUser;
  final String currentUserType;

  const _CommentPage({
    required this.postId,
    required this.postText,
    required this.currentUser,
    required this.currentUserType,
  });

  @override
  State<_CommentPage> createState() => _CommentPageState();
}

class _CommentPageState extends State<_CommentPage> {
  final _controller = TextEditingController();
  final _firestore = FirebaseFirestore.instance;
  bool _isSending = false;

  Future<void> _sendComment() async {
    if (_controller.text.trim().isEmpty) return;
    setState(() => _isSending = true);

    final batch = _firestore.batch();

    // เพิ่ม comment
    final commentRef = _firestore
        .collection('community_posts')
        .doc(widget.postId)
        .collection('comments')
        .doc();

    batch.set(commentRef, {
      'text': _controller.text.trim(),
      'authorName': widget.currentUser,
      'authorType': widget.currentUserType,
      'createdAt': FieldValue.serverTimestamp(),
    });

    // อัปเดต commentCount
    batch.update(
      _firestore.collection('community_posts').doc(widget.postId),
      {'commentCount': FieldValue.increment(1)},
    );

    await batch.commit();
    _controller.clear();
    setState(() => _isSending = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FB),
      appBar: AppBar(
        backgroundColor: const Color(0xFF061B4A),
        foregroundColor: Colors.white,
        title: const Text(
          'ความคิดเห็น',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
        ),
        elevation: 0,
      ),
      body: Column(
        children: [
          // ── Original post ──────────────────────────────────────
          Container(
            width: double.infinity,
            color: Colors.white,
            padding: const EdgeInsets.all(16),
            child: Text(
              widget.postText,
              style: const TextStyle(
                  fontSize: 14, color: Color(0xFF2D2D2D), height: 1.5),
            ),
          ),
          Divider(height: 1, color: Colors.grey.shade200),

          // ── Comments ───────────────────────────────────────────
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('community_posts')
                  .doc(widget.postId)
                  .collection('comments')
                  .orderBy('createdAt', descending: false)
                  .snapshots(),
              builder: (context, snapshot) {
                final comments = snapshot.data?.docs ?? [];
                if (comments.isEmpty) {
                  return Center(
                    child: Text(
                      'ยังไม่มีความคิดเห็น\nเป็นคนแรกที่แสดงความคิดเห็น!',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          color: Colors.grey.shade400, fontSize: 14),
                    ),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(14),
                  itemCount: comments.length,
                  itemBuilder: (context, index) {
                    final data =
                        comments[index].data() as Map<String, dynamic>;
                    final isLawyer = data['authorType'] == 'lawyer';
                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 34,
                            height: 34,
                            decoration: BoxDecoration(
                              color: isLawyer
                                  ? const Color(0xFF0262EC)
                                      .withOpacity(0.1)
                                  : Colors.grey.shade100,
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                (data['authorName'] ?? '?')
                                    .substring(0, 1),
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  color: isLawyer
                                      ? const Color(0xFF0262EC)
                                      : Colors.grey.shade600,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      data['authorName'] ?? '',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 13,
                                      ),
                                    ),
                                    if (isLawyer) ...[
                                      const SizedBox(width: 6),
                                      Container(
                                        padding:
                                            const EdgeInsets.symmetric(
                                                horizontal: 6,
                                                vertical: 2),
                                        decoration: BoxDecoration(
                                          color:
                                              const Color(0xFF0262EC),
                                          borderRadius:
                                              BorderRadius.circular(20),
                                        ),
                                        child: const Text(
                                          'ทนายความ',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 9,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  data['text'] ?? '',
                                  style: const TextStyle(
                                      fontSize: 13,
                                      color: Color(0xFF2D2D2D),
                                      height: 1.4),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),

          // ── Input ──────────────────────────────────────────────
          Container(
            color: Colors.white,
            padding: EdgeInsets.only(
              left: 14,
              right: 14,
              top: 10,
              bottom: MediaQuery.of(context).padding.bottom + 10,
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(
                      hintText: 'เขียนความคิดเห็น...',
                      hintStyle: TextStyle(
                          color: Colors.grey.shade400, fontSize: 13),
                      filled: true,
                      fillColor: const Color(0xFFF4F6FB),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(22),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _isSending ? null : _sendComment,
                  child: Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: _controller.text.trim().isNotEmpty
                          ? const Color(0xFF0262EC)
                          : Colors.grey.shade200,
                      shape: BoxShape.circle,
                    ),
                    child: _isSending
                        ? const Padding(
                            padding: EdgeInsets.all(10),
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : Icon(
                            Icons.send_rounded,
                            color:
                                _controller.text.trim().isNotEmpty
                                    ? Colors.white
                                    : Colors.grey.shade400,
                            size: 20,
                          ),
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