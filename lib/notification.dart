import 'package:LawyerOnline/component/appbar.dart';
import 'package:LawyerOnline/notification-detail.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:hms_room_kit/hms_room_kit.dart';
import 'package:permission_handler/permission_handler.dart';

class NotificationPage extends StatefulWidget {
  const NotificationPage({Key? key}) : super(key: key);

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  List notifications = [
    // {
    //   "type": "chat",
    //   "title": "ข้อความใหม่",
    //   "detail": "คุณได้รับข้อความใหม่จากทนายศักดิ์สิทธิ์",
    //   "time": "10:20",
    //   "date": "today",
    //   "isRead": false
    // },
    {
      "type": "call",
      "title": "สายที่ไม่ได้รับ",
      "detail": "คุณไม่ได้รับสายจากทนายศักดิ์สิทธิ์",
      "time": "10:19",
      "date": "today",
      "isRead": false
    },
    {
      "type": "booking",
      "title": "นัดหมายคดี",
      "detail": "คดีความกำลังจะมาถึง",
      "time": "10:20",
      "date": "today",
      "isRead": false
    },
    // {
    //   "type": "booking",
    //   "title": "การนัดหมายใหม่",
    //   "detail": "ลูกค้าได้ทำการนัดหมาย",
    //   "time": "09:40",
    //   "date": "today",
    //   "isRead": false
    // },
    {
      "type": "finish",
      "title": "นัดหมายทนายความเสร็จสิ้น",
      "detail": "กรุณารีวิวการให้คะแนนทนายความ",
      "time": "เมื่อวาน",
      "date": "yesterday",
      "isRead": true
    },
    {
      "type": "system",
      "title": "ทนายความรับเคสแล้ว",
      "detail": "คดีของคุณมีทนายความรับเคสแล้ว",
      "time": "2 วันก่อน",
      "date": "old",
      "isRead": true
    }
  ];

  int get unreadCount =>
      notifications.where((n) => n["isRead"] == false).length;

  IconData getIcon(type) {
    switch (type) {
      case "chat":
        return Icons.chat_bubble;

      case "call":
        return Icons.call_end;

      case "booking":
        return Icons.calendar_month;

      case "payment":
        return Icons.payment;

      case "finish":
        return Icons.task_alt;

      default:
        return Icons.notifications;
    }
  }

  Future refresh() async {
    await Future.delayed(const Duration(seconds: 1));
  }

  void markAllRead() {
    setState(() {
      for (var n in notifications) {
        n["isRead"] = true;
      }
    });
  }

  Widget buildItem(item, index) {
    return Dismissible(
      key: Key(index.toString()),
      direction: DismissDirection.endToStart,
      onDismissed: (direction) {
        setState(() {
          notifications.removeAt(index);
        });
      },
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: Colors.red,
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      child: GestureDetector(
        onTap: () {
          setState(() {
            item["isRead"] = true;
            // Overlay.of(context).insert(overlay);
          });
          if (item["type"] == 'call') {
            showIncomingCallOverlay(context, "ทนายทนายศักด์สิทธิ์");
          } else {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => NotificationDetailPage(data: item),
              ),
            );
          }
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: item["isRead"] ? Colors.white : Color(0xFFBAD5FF),
            borderRadius: BorderRadius.circular(16),
            // boxShadow: const [
            //   BoxShadow(
            //     color: Colors.black12,
            //     blurRadius: 3,
            //     offset: Offset(0, 2),
            //   )
            // ],
          ),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: item["isRead"]
                  ? const Color.fromARGB(255, 206, 228, 246)
                  : Colors.white,
              child: Icon(
                getIcon(item["type"]),
                color: Colors.blue,
              ),
            ),
            title: Text(
              item["title"],
              style: TextStyle(
                fontWeight:
                    item["isRead"] ? FontWeight.normal : FontWeight.bold,
              ),
            ),
            subtitle: Text(item["detail"]),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  item["time"],
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                if (!item["isRead"])
                  Container(
                    margin: const EdgeInsets.only(top: 5),
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                        color: Colors.red, shape: BoxShape.circle),
                  )
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget buildSection(title, date) {
    List items = notifications.where((n) => n["date"] == date).toList();

    if (items.isEmpty) return const SizedBox();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 10),
          child: Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        ...items.map((item) {
          int index = notifications.indexOf(item);

          return buildItem(item, index);
        }).toList()
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // appBar: AppBar(
      //   title: Row(
      //     children: [
      //       const Text("การแจ้งเตือน"),
      //       const SizedBox(width: 10),
      //       if (unreadCount > 0)
      //         Container(
      //           padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      //           decoration: BoxDecoration(
      //             color: Colors.red,
      //             borderRadius: BorderRadius.circular(20),
      //           ),
      //           child: Text(
      //             unreadCount.toString(),
      //             style: const TextStyle(color: Colors.white, fontSize: 12),
      //           ),
      //         )
      //     ],
      //   ),
      //   actions: [
      //     IconButton(onPressed: markAllRead, icon: const Icon(Icons.done_all))
      //   ],
      // ),
      backgroundColor: const Color(0xFFEEF2F5),
      appBar: appBarCustom(
        title: "การแจ้งเตือน",
        backBtn: true,
        isRightWidget: true,
        backAction: () => goBack(),
        rightWidget: GestureDetector(
          onTap: () => {
            markAllRead(),
          },
          child: Container(
            width: 40,
            alignment: Alignment.center,
            // padding: const EdgeInsets.symmetric(
            //   horizontal: 12,
            //   vertical: 10,
            // ),
            decoration: BoxDecoration(
              color: const Color(0xFFFAFAFA),
              // borderRadius: BorderRadius.circular(22),
              shape: BoxShape.circle,
              border: Border.all(
                width: 1,
                color: const Color(0xFFDBDBDB),
              ),
            ),
            child: const Icon(
              Icons.done_all,
              size: 15,
            ),
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: refresh,
        child: ListView(
          children: [
            buildSection("วันนี้", "today"),
            buildSection("เมื่อวาน", "yesterday"),
            buildSection("ก่อนหน้านี้", "old"),
            const SizedBox(height: 20)
          ],
        ),
      ),
    );
  }

  Future<void> showIncomingCallOverlay(
      BuildContext context, String lawyerName) async {
    late OverlayEntry overlay;
    final player = AudioPlayer();

    await player.setReleaseMode(ReleaseMode.loop);
    await player.play(AssetSource('incoming_call.mp3'));

    // callback ที่ widget ด้านในจะเรียกเพื่อ dismiss พร้อม animate
    Future<void> dismiss() async {
      // บอกให้ widget เล่น animation ออก แล้วค่อย remove
      // ใช้ GlobalKey เพื่อเข้าถึง state
    }

    final key = GlobalKey<_IncomingCallOverlayState>();

    overlay = OverlayEntry(
      builder: (context) => _IncomingCallOverlay(
        key: key,
        lawyerName: lawyerName,
        onDecline: () async {
          await player.stop();
          await key.currentState?.dismiss();
          overlay.remove();
        },
        onAccept: () async {
          await player.stop();
          await key.currentState?.dismiss();
          overlay.remove();
          if (context.mounted) _showReminderBeforeJoin(context);
        },
      ),
    );

    Overlay.of(context).insert(overlay);

    // Auto dismiss ภายใน 10 วิ
    Future.delayed(const Duration(seconds: 10), () async {
      if (overlay.mounted) {
        await player.stop();
        await key.currentState?.dismiss();
        if (overlay.mounted) overlay.remove();
      }
    });
  }

  void _showReminderBeforeJoin(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("คำแนะนำก่อนเข้าห้อง"),
        content: const Text(
            "📌 กรุณาระบุชื่อในช่อง Enter Name ว่า 1234 ก่อนกด Join Now"),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text("ยกเลิก"),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop(); // ปิด dialog

              Map<Permission, PermissionStatus> statuses = await [
                Permission.camera,
                Permission.microphone,
              ].request();

              // ถ้าโดนปฏิเสธแบบถาวร (iOS จะไม่ถามซ้ำ)
              if (statuses.values.any((s) => s.isPermanentlyDenied)) {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text("ต้องเปิดการเข้าถึงใน Settings"),
                    content: const Text(
                        "กรุณาไปที่การตั้งค่า แล้วอนุญาตให้แอปเข้าถึงกล้องและไมโครโฟน"),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text("ยกเลิก"),
                      ),
                      TextButton(
                        onPressed: () {
                          openAppSettings(); // เปิดหน้า Settings
                        },
                        child: const Text("เปิดการตั้งค่า"),
                      ),
                    ],
                  ),
                );
                return;
              }

              bool allGranted =
                  statuses.values.every((status) => status.isGranted);

              if (allGranted) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => HMSPrebuilt(
                      roomCode: "jle-wjbx-gyk",
                    ),
                  ),
                );
              } else {
                // แจ้งเตือนทั่วไป
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text("การอนุญาตถูกปฏิเสธ"),
                    content: const Text(
                        "กรุณาอนุญาตให้เข้าถึงกล้องและไมโครโฟนเพื่อใช้งานวิดีโอคอล"),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text("ตกลง"),
                      ),
                    ],
                  ),
                );
              }
            },
            child: const Text("เข้าใช้งาน"),
          ),
        ],
      ),
    );
  }

  void goBack() async {
    Navigator.pop(context, false);
  }
}

class _IncomingCallOverlay extends StatefulWidget {
  final String lawyerName;
  final VoidCallback onDecline;
  final VoidCallback onAccept;

  const _IncomingCallOverlay({
    super.key,
    required this.lawyerName,
    required this.onDecline,
    required this.onAccept,
  });

  @override
  State<_IncomingCallOverlay> createState() => _IncomingCallOverlayState();
}

class _IncomingCallOverlayState extends State<_IncomingCallOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<Offset> _slide;
  late Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _slide = Tween<Offset>(
      begin: const Offset(0, -0.5), // เริ่มจากนอกจอด้านบน
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutBack));

    _fade = Tween<double>(begin: 0, end: 1)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));

    // เล่น animation เข้า
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  /// เรียกจากภายนอกเพื่อ animate ออกแล้ว resolve
  Future<void> dismiss() async {
    await _ctrl.animateTo(
      0,
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeInBack,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 50,
      left: 20,
      right: 20,
      child: SlideTransition(
        position: _slide,
        child: FadeTransition(
          opacity: _fade,
          child: Material(
            color: Colors.transparent,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(50),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.6),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  ClipOval(
                    child: Container(
                      padding: const EdgeInsets.all(3.0),
                      width: 45,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFAFAFA),
                        shape: BoxShape.circle,
                        border: Border.all(
                          width: 1,
                          color: const Color(0xFFDBDBDB),
                        ),
                      ),
                      child: Image.asset('assets/icons/profile.png',
                          fit: BoxFit.cover),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "สายเรียกเข้า",
                          style: TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.w400,
                              fontSize: 12),
                        ),
                        Text(
                          widget.lawyerName,
                          style: const TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.bold,
                              fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                  // ปุ่มวางสาย
                  Container(
                    width: 45,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFAFAFA),
                      shape: BoxShape.circle,
                      border: Border.all(
                          width: 1, color: const Color(0xFFDBDBDB)),
                    ),
                    child: IconButton(
                      icon: Icon(Icons.call_end, color: Colors.red.shade600),
                      onPressed: widget.onDecline,
                    ),
                  ),
                  const SizedBox(width: 10),
                  // ปุ่มรับสาย
                  Container(
                    width: 45,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFAFAFA),
                      shape: BoxShape.circle,
                      border: Border.all(
                          width: 1, color: const Color(0xFFDBDBDB)),
                    ),
                    child: IconButton(
                      icon: Icon(Icons.call,
                          color: Colors.greenAccent.shade700),
                      onPressed: widget.onAccept,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}