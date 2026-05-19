import 'package:LawyerOnline/notification-detail.dart';
import 'package:LawyerOnline/notification_desktop_detail.dart';
import 'package:LawyerOnline/notification.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

class NotificationDropdownContent extends StatefulWidget {
  const NotificationDropdownContent({Key? key}) : super(key: key);

  @override
  State<NotificationDropdownContent> createState() => _NotificationDropdownContentState();
}

class _NotificationDropdownContentState extends State<NotificationDropdownContent> {
  List<Map<String, dynamic>> get notifications => globalNotifications;

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

  void markAllRead() {
    setState(() {
      for (var n in notifications) {
        n["isRead"] = true;
      }
    });
  }

  Widget buildItem(item, index) {
    return GestureDetector(
      onTap: () {
        setState(() {
          item["isRead"] = true;
        });
        Navigator.pop(context); // ปิด dropdown
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) {
              final isDesktop = MediaQuery.of(context).size.width >= 1024;
              if (isDesktop) {
                return NotificationDesktopDetailPage(initialData: item);
              } else {
                return NotificationDetailPage(data: item);
              }
            },
          ),
        );
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        margin: const EdgeInsets.symmetric(vertical: 4),
        decoration: BoxDecoration(
          color: item["isRead"] ? Colors.transparent : const Color(0xFFBAD5FF).withOpacity(0.3),
          borderRadius: BorderRadius.circular(12),
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
          leading: CircleAvatar(
            backgroundColor: item["isRead"]
                ? const Color(0xFFEEF2F5)
                : Colors.white,
            child: Icon(
              getIcon(item["type"]),
              color: Colors.blue,
              size: 20,
            ),
          ),
          title: Text(
            item["title"],
            style: TextStyle(
              fontSize: 14,
              fontWeight:
                  item["isRead"] ? FontWeight.normal : FontWeight.bold,
            ),
          ),
          subtitle: Text(
            item["detail"],
            style: const TextStyle(fontSize: 12),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                item["time"],
                style: const TextStyle(fontSize: 10, color: Colors.grey),
              ),
              if (!item["isRead"])
                Container(
                  margin: const EdgeInsets.only(top: 4),
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                      color: Colors.red, shape: BoxShape.circle),
                )
            ],
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
          padding: const EdgeInsets.fromLTRB(4, 10, 4, 6),
          child: Text(
            title,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Text(
                  "notifications".tr(),
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 8),
                if (unreadCount > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      unreadCount.toString(),
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  )
              ],
            ),
            IconButton(
              onPressed: markAllRead,
              icon: const Icon(Icons.done_all, size: 20),
              tooltip: "notification.allRead".tr(),
            )
          ],
        ),
        const Divider(),
        // List
        Expanded(
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              buildSection("timeline.today".tr(), "today"),
              buildSection("timeline.yesterday".tr(), "yesterday"),
              buildSection("timeline.earlier".tr(), "earlier"),
            ],
          ),
        ),
        const Divider(height: 1),
        // See all button
        SizedBox(
          width: double.infinity,
          child: TextButton(
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
            onPressed: () {
              Navigator.pop(context); // ปิด dropdown
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) {
                    final isDesktop = MediaQuery.of(context).size.width >= 1024;
                    if (isDesktop) {
                      return const NotificationDesktopDetailPage();
                    } else {
                      return const NotificationPage();
                    }
                  },
                ),
              );
            },
            child:  Text("notification.listAll".tr(), style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
        )
      ],
    );
  }
}
