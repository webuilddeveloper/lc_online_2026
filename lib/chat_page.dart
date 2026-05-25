// pages/chat_page.dart
import 'package:LawyerOnline/services/chat_service.dart';
import 'package:flutter/material.dart';

class ChatPage extends StatefulWidget {
  final String roomCode;
  final String userId;

  const ChatPage({required this.roomCode, required this.userId, super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final ChatService _chatService = ChatService();
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  List<Map<String, dynamic>> _messages = [];
  bool _isTyping = false;
  String _typingUser = "";

  @override
  void initState() {
    super.initState();
    _setupChat();
  }

  Future<void> _setupChat() async {
    // ตั้งค่า callbacks
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

    // เชื่อมต่อ → JoinRoom → LoadHistory ตามลำดับ
    await _chatService.connect();
    await _chatService.joinRoom(widget.roomCode, widget.userId);
    await _chatService.loadHistory(widget.roomCode); // ✅ เรียกหลัง joinRoom
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  Future<void> _sendMessage() async {
    if (_textController.text.isEmpty) return;

    await _chatService.sendMessage(
      widget.roomCode,
      widget.userId,
      _textController.text,
    );
    _textController.clear();
  }

  @override
  void dispose() {
    _chatService.leaveRoom(widget.roomCode, widget.userId);
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Chat")),
      body: Column(
        children: [
          // แสดง messages
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              itemCount: _messages.length,
              itemBuilder: (_, index) {
                final msg = _messages[index];
                final isMe = msg['senderId'] == widget.userId;
                return Align(
                  alignment:
                      isMe ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.all(8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isMe ? Colors.blue : Colors.grey[300],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      msg['content'] ?? '',
                      style: TextStyle(
                        color: isMe ? Colors.white : Colors.black,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // แสดงสถานะกำลังพิมพ์
          if (_isTyping)
            Padding(
              padding: const EdgeInsets.all(8),
              child: Text("$_typingUser กำลังพิมพ์..."),
            ),

          // กล่องพิมพ์ข้อความ
          Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _textController,
                    onChanged: (text) {
                      _chatService.typing(
                        widget.roomCode,
                        widget.userId,
                        text.isNotEmpty,
                      );
                    },
                    decoration: const InputDecoration(
                      hintText: "พิมพ์ข้อความ...",
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.send, color: Colors.blue),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
