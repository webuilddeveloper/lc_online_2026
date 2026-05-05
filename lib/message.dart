import 'package:flutter/material.dart';
import 'package:LawyerOnline/component/appbar.dart';
import 'package:LawyerOnline/chat/chat_page_user.dart';
import 'package:LawyerOnline/chat/chat_page_lawyer.dart';
import 'package:LawyerOnline/models/chat/chat_repository.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';


/*
=========================================
  Chat data ย้ายไปไว้ที่ lib/models/chat/chat_repository.dart

  chat_repository.dart ทำหน้าที่เป็น Repository Pattern —
  เป็นตัวกลางระหว่าง UI กับ data source

 
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

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    const storage = FlutterSecureStorage();
    final type = await storage.read(key: 'userType') ?? '';

    // ✅ ดึงจาก repository — สลับ Mock/Firestore ได้ที่ chat_repository.dart
    final convs = await chatRepository.getConversations(type);

    if (!mounted) return;
    setState(() {
      _userType = type;
      _conversations = convs;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEEF2F5),
      appBar: appBar(
        title: 'กล่องข้อความ',
        backBtn: false,
        rightBtn: false,
        rightAction: () {},
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _conversations.isEmpty
              ? const Center(
                  child: Text('ยังไม่มีการสนทนา',
                      style: TextStyle(color: Color(0xFF8593A8))))
              : Column(
                  children: [
                    const SizedBox(height: 20),
                    Expanded(child: _buildList()),
                  ],
                ),
    );
  }

  Widget _buildList() {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: _conversations.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) =>
          _conversationItem(_conversations[index]),
    );
  }

  Widget _conversationItem(Conversation conv) {
    return GestureDetector(
      onTap: () => Navigator.push(
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
                  jobId: conv.id, // ✅ ส่ง jobId ให้ updateStatus ได้
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
      ).then((_) => _load()), // ✅ reload หลังกลับมา เผื่อ status เปลี่ยน
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
        decoration: BoxDecoration(
          color: const Color.fromARGB(255, 251, 253, 255),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
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
            // ── Avatar ─────────────────────────────────
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
                // ── online dot ───────────────────────
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
            const SizedBox(width: 15),

            // ── ชื่อ + ข้อความล่าสุด ──────────────────
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        conv.name,
                        style: const TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w500),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        conv.lastChatDate,
                        style: const TextStyle(
                            fontSize: 12, color: Color(0xFF8593A8)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // ── "จบการสนทนา" ถ้า caseSuccess ──
                      // conv.caseSuccess
                          // ? const Text(
                          //     'จบการสนทนาแล้ว',
                          //     style: TextStyle(
                          //         fontSize: 13,
                          //         color: Color(0xFF8593A8),
                          //         fontStyle: FontStyle.italic),
                          //   )
                          // :
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
    );
  }
}

// import 'package:flutter/material.dart';
// import 'package:LawyerOnline/component/appbar.dart';
// import 'package:LawyerOnline/message-form.dart';
// import 'package:LawyerOnline/chat/chat_page_user.dart';
// import 'package:LawyerOnline/chat/chat_page_lawyer.dart';
// import 'package:flutter_secure_storage/flutter_secure_storage.dart';

// class MessagePage extends StatefulWidget {
//   const MessagePage({super.key});

//   @override
//   State<MessagePage> createState() => _MessagePageState();
// }

// class _MessagePageState extends State<MessagePage> {
//   String _userType = '';

//   List<dynamic> lawyerOnlineList = [
//     {
//       "code": "0",
//       "name": "ศักดิ์สิทธิ์ พิพากษ์",
//       "imageUrl": "assets/images/lawyer-avatar-1.png",
//       "active": true,
//       "lastChat": "มีเอกสารที่เกี่ยวข้องมั้ยครับ",
//       "lastChatDate": "14:28",
//       "unreadCount": 1,
//       "caseSuccess": false
//     },
//     {
//       "code": "1",
//       "name": "ธนากร นิติศักดิ์",
//       "imageUrl": "assets/images/lawyer-avatar-2.png",
//       "active": false,
//       "lastChat": "ได้รับแล้วครับ",
//       "lastChatDate": "yesterday",
//       "unreadCount": 3,
//       "caseSuccess": false
//     },
//     {
//       "code": "2",
//       "name": "อาริย์ ศิษย์กฎหมาย",
//       "imageUrl": "assets/images/lawyer-avatar-4.png",
//       "active": false,
//       "lastChat": "ขอบคุณค่ะ",
//       "lastChatDate": "yesterday",
//       "unreadCount": 0,
//       "caseSuccess": true
//     },
//     {
//       "code": "3",
//       "name": "Sachin K",
//       "imageUrl": "assets/images/lawyer-avatar-5.png",
//       "active": false,
//       "lastChat": "Yeah, sure.",
//       "lastChatDate": "07/18/2022",
//       "unreadCount": 0,
//       "caseSuccess": true
//     },
//   ];

//   @override
//   void initState() {
//     super.initState();
//     _loadUserType();
//   }

//   Future<void> _loadUserType() async {
//     const storage = FlutterSecureStorage();
//     final type = await storage.read(key: 'userType') ?? '';
//     setState(() => _userType = type);
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: const Color(0xFFEEF2F5),
//       appBar: appBar(
//         title: "กล่องข้อความ",
//         backBtn: false,
//         rightBtn: false,
//         rightAction: () => {},
//       ),
//       body: Container(
//         child: Column(
//           children: [
//             const SizedBox(
//               height: 20,
//             ),
//             Expanded(child: _buildLawyerOnline()),
//           ],
//         ),
//       ),
//     );
//   }

//   _buildLawyerOnline() {
//     return ListView.separated(
//       padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
//       itemCount: lawyerOnlineList.length,
//       itemBuilder: (context, index) =>
//           _lawyerOnlineItem(lawyerOnlineList[index], onTap: () => {}),
//       separatorBuilder: (BuildContext context, int index) => const SizedBox(
//         height: 10,
//       ),
//     );
//   }

//   _lawyerOnlineItem(dynamic model, {Function? onTap}) {
//     return GestureDetector(
//       onTap: () {
//         Navigator.push(
//           context,
//           MaterialPageRoute(
//             builder: (context) => _userType == 'lawyer'
//                 ? ChatPageLawyer(model: model) //  lawyer
//                 : ChatPageUser(model: model), // user
//           ),
//         );
//       },
//       child: Container(
//         padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
//         decoration: BoxDecoration(
//             // color: Colors.white,
//             borderRadius: BorderRadius.circular(6)),
//         child: IntrinsicHeight(
//           child: Row(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             mainAxisAlignment: MainAxisAlignment.spaceBetween,
//             children: [
//               Stack(
//                 children: [
//                   ClipRRect(
//                     borderRadius: BorderRadius.circular(100),
//                     child: Image.asset(
//                       model['imageUrl'] ?? '',
//                       height: 48,
//                       width: 48,
//                       fit: BoxFit.cover,
//                     ),
//                   ),
//                   model['active']
//                       ? Positioned(
//                           right: 0,
//                           child: Container(
//                             width: 12,
//                             height: 12,
//                             decoration: BoxDecoration(
//                                 color: const Color(0xFF00CC5E),
//                                 borderRadius: BorderRadius.circular(100)),
//                             alignment: Alignment.center,
//                           ),
//                         )
//                       : Container(),
//                 ],
//               ),
//               const SizedBox(width: 15),
//               Expanded(
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                   children: [
//                     Row(
//                       mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                       children: [
//                         Text(
//                           model['name'] ?? '',
//                           style: const TextStyle(
//                             fontSize: 14,
//                             fontWeight: FontWeight.w500,
//                           ),
//                           maxLines: 1,
//                           overflow: TextOverflow.ellipsis,
//                         ),
//                         Text(
//                           model['lastChatDate'] ?? '',
//                           style: const TextStyle(
//                             fontSize: 12,
//                             color: Color(0xFF8593A8),
//                           ),
//                           maxLines: 1,
//                           overflow: TextOverflow.ellipsis,
//                         ),
//                       ],
//                     ),
//                     Row(
//                       mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                       children: [
//                         Text(
//                           model['lastChat'] ?? '',
//                           style: TextStyle(
//                               fontSize: 14,
//                               color: model['unreadCount'] > 0
//                                   ? Colors.black
//                                   : Color(0xFF8593A8),
//                               fontWeight: model['unreadCount'] > 0
//                                   ? FontWeight.w600
//                                   : FontWeight.w400),
//                           maxLines: 1,
//                           overflow: TextOverflow.ellipsis,
//                         ),
//                         model['unreadCount'] > 0
//                             ? Container(
//                                 width: 20,
//                                 height: 20,
//                                 decoration: BoxDecoration(
//                                     color: const Color(0xFF0262EC),
//                                     borderRadius: BorderRadius.circular(100)),
//                                 alignment: Alignment.center,
//                                 child: Text(
//                                   model['unreadCount'].toString(),
//                                   style: const TextStyle(
//                                     fontSize: 12,
//                                     color: Color(0xFFF6FBFF),
//                                   ),
//                                   maxLines: 1,
//                                   overflow: TextOverflow.ellipsis,
//                                 ),
//                               )
//                             : Container()
//                       ],
//                     ),
//                   ],
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   void goBack() async {
//     Navigator.pop(context, false);
//   }
// }