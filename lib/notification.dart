import 'package:LawyerOnline/component/appbar.dart';
import 'package:LawyerOnline/notification-detail.dart';
import 'package:flutter/material.dart';

class NotificationPage extends StatefulWidget {
  const NotificationPage({Key? key}) : super(key: key);

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  List notifications = [
    // {
    //   "type": "chat",
    //   "title": "นัดหมายคดี",
    //   "detail": "คดีความกำลังจะมาถึง",
    //   "time": "10:20",
    //   "date": "today",
    //   "isRead": false
    // },
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
          });
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => NotificationDetailPage(data: item),
            ),
          );
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

  void goBack() async {
    Navigator.pop(context, false);
  }
}
