import 'package:LawyerOnline/models/lawyer/lawyer_jobs_store.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// ══════════════════════════════════════════════════════════
//  ChatRepository — abstraction layer ระหว่าง UI กับ data
//
//  ตอนนี้ใช้ MockChatRepository
//  พอพร้อมเชื่อม Firestore → เปลี่ยนเป็น FirestoreChatRepository
//  ที่บรรทัดสุดท้ายของไฟล์นี้ (final ChatRepository chatRepository = ...)
//  UI (message.dart, chat_page_user/lawyer) ไม่ต้องแก้เลย
  // - getConversations() → ดึงรายการแชท
  // - getMessages()      → stream ข้อความ realtime
  // - sendMessage()      → ส่งข้อความ
  // - endConversation()  → จบการสนทนา
// ══════════════════════════════════════════════════════════

// ── Model ──────────────────────────────────────────────────────
class Conversation {
  final String id;
  final String name;
  final String avatar;       // ตัวอักษรหรือ imageUrl
  final bool avatarIsImage;  // true = imageUrl, false = ตัวอักษร
  final int clientColor;
  final String lastChat;
  final String lastChatDate;
  final int unreadCount;
  final bool caseSuccess;    // true = จบงานแล้ว ปิดแชท

  const Conversation({
    required this.id,
    required this.name,
    required this.avatar,
    this.avatarIsImage = false,
    this.clientColor = 0xFF0262EC,
    this.lastChat = '',
    this.lastChatDate = '',
    this.unreadCount = 0,
    this.caseSuccess = false,
  });
}

class ChatMessage {
  final String id;
  final String text;
  final bool isMe;
  final DateTime createdAt;

  const ChatMessage({
    required this.id,
    required this.text,
    required this.isMe,
    required this.createdAt,
  });
}

// ── Abstract ────────────────────────────────────────────────────
abstract class ChatRepository {
  /// ดึงรายการแชทของ user หรือ lawyer
  Future<List<Conversation>> getConversations(String userType);

  /// stream ข้อความ realtime (ใช้ใน chat page)
  Stream<List<ChatMessage>> getMessages(String conversationId, String myUserId);

  /// ส่งข้อความ
  Future<void> sendMessage(String conversationId, String text, String senderId);

  /// จบการสนทนา — เปลี่ยน status เป็น done
  Future<void> endConversation(String conversationId);
}

// ── Mock (ใช้ตอนนี้) ────────────────────────────────────────────
class MockChatRepository implements ChatRepository {
  // mock messages ต่อ conversation
  final Map<String, List<ChatMessage>> _mockMessages = {};

  @override
  Future<List<Conversation>> getConversations(String userType) async {
    if (userType == 'lawyer') {
      // ✅ ดึงจาก LawyerJobsStore — เฉพาะงานที่รับแล้วหรือจบแล้ว
      return LawyerJobsStore.instance.jobs
          .where((j) => j['status'] == 'accepted' || j['status'] == 'done')
          .map((j) => Conversation(
                id: j['id'] as String,
                name: j['clientName'] as String,
                avatar: j['clientAvatar'] as String,
                avatarIsImage: false,
                clientColor: j['clientColor'] as int,
                lastChat: j['subTopic'] as String? ?? '',
                lastChatDate: j['requestedAt'] as String? ?? '',
                unreadCount: 0,
                caseSuccess: j['status'] == 'done', // ✅ จบแล้ว = ปิดแชท
              ))
          .toList();
    }

    // ฝั่ง user — mock ไปก่อน รอเชื่อม Firestore
    return [
      const Conversation(
        id: 'conv-001',
        name: 'ศักดิ์สิทธิ์ พิพากษ์',
        avatar: 'assets/images/lawyer-avatar-1.png',
        avatarIsImage: true,
        lastChat: 'มีเอกสารที่เกี่ยวข้องมั้ยครับ',
        lastChatDate: '14:28',
        unreadCount: 1,
        caseSuccess: false,
      ),
      const Conversation(
        id: 'conv-002',
        name: 'ธนากร นิติศักดิ์',
        avatar: 'assets/images/lawyer-avatar-2.png',
        avatarIsImage: true,
        lastChat: 'ได้รับแล้วครับ',
        lastChatDate: 'yesterday',
        unreadCount: 3,
        caseSuccess: false,
      ),
      const Conversation(
        id: 'conv-003',
        name: 'อาริย์ ศิษย์กฎหมาย',
        avatar: 'assets/images/lawyer-avatar-4.png',
        avatarIsImage: true,
        lastChat: 'ขอบคุณค่ะ',
        lastChatDate: 'yesterday',
        unreadCount: 0,
        caseSuccess: true, // จบแล้ว
      ),
    ];
  }

  @override
  Stream<List<ChatMessage>> getMessages(
      String conversationId, String myUserId) {
    // คืน stream จาก in-memory list
    final msgs = _mockMessages[conversationId] ?? [];
    return Stream.value(msgs);
  }

  @override
  Future<void> sendMessage(
      String conversationId, String text, String senderId) async {
    final msg = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      text: text,
      isMe: true,
      createdAt: DateTime.now(),
    );
    _mockMessages.putIfAbsent(conversationId, () => []).add(msg);

    // mock auto-reply
    await Future.delayed(const Duration(seconds: 1));
    final reply = ChatMessage(
      id: '${DateTime.now().millisecondsSinceEpoch}_reply',
      text: 'รับทราบครับ 👍',
      isMe: false,
      createdAt: DateTime.now(),
    );
    _mockMessages[conversationId]!.add(reply);
  }

  @override
  Future<void> endConversation(String conversationId) async {
    // อัปเดต LawyerJobsStore
    LawyerJobsStore.instance.updateStatus(conversationId, 'done');
  }
}

// ── Firestore (สลับใช้เมื่อพร้อม) ─────────────────────────────
class FirestoreChatRepository implements ChatRepository {
  final _db = FirebaseFirestore.instance;

  @override
  Future<List<Conversation>> getConversations(String userType) async {
    final snapshot = await _db
        .collection('conversations')
        .where('participants', arrayContains: userType)
        .orderBy('updatedAt', descending: true)
        .get();

    return snapshot.docs.map((d) {
      final data = d.data();
      return Conversation(
        id: d.id,
        name: data['name'] as String? ?? '',
        avatar: data['avatar'] as String? ?? '',
        avatarIsImage: data['avatarIsImage'] as bool? ?? false,
        clientColor: data['clientColor'] as int? ?? 0xFF0262EC,
        lastChat: data['lastMessage'] as String? ?? '',
        lastChatDate: data['updatedAt']?.toString() ?? '',
        unreadCount: data['unreadCount'] as int? ?? 0,
        caseSuccess: data['status'] == 'done',
      );
    }).toList();
  }

  @override
  Stream<List<ChatMessage>> getMessages(
      String conversationId, String myUserId) {
    return _db
        .collection('conversations')
        .doc(conversationId)
        .collection('messages')
        .orderBy('createdAt')
        .snapshots()
        .map((s) => s.docs
            .map((d) => ChatMessage(
                  id: d.id,
                  text: d['text'] as String,
                  isMe: d['senderId'] == myUserId,
                  createdAt: (d['createdAt'] as Timestamp).toDate(),
                ))
            .toList());
  }

  @override
  Future<void> sendMessage(
      String conversationId, String text, String senderId) async {
    final ref = _db.collection('conversations').doc(conversationId);
    await ref.collection('messages').add({
      'text': text,
      'senderId': senderId,
      'createdAt': FieldValue.serverTimestamp(),
    });
    // อัปเดต lastMessage
    await ref.update({
      'lastMessage': text,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<void> endConversation(String conversationId) async {
    await _db.collection('conversations').doc(conversationId).update({
      'status': 'done',
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}


final ChatRepository chatRepository = MockChatRepository();
// final ChatRepository chatRepository = FirestoreChatRepository();