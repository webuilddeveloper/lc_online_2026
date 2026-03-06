import 'package:flutter/material.dart';
import 'package:LawyerOnline/component/appbar.dart';

class NotificationDetailPage extends StatelessWidget {
  final Map data;

  const NotificationDetailPage({super.key, required this.data});

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

  String getTypeName(type) {
    switch (type) {
      case "chat":
        return "ข้อความ";

      case "booking":
        return "การนัดหมาย";

      case "payment":
        return "การชำระเงิน";

      case "finish":
        return "เสร็จสิ้น";

      default:
        return "การแจ้งเตือนระบบ";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEEF2F5),

      appBar: appBarCustom(
        title: "รายละเอียดแจ้งเตือน",
        backBtn: true,
        isRightWidget: false,
        backAction: () => Navigator.pop(context),
      ),

      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [

          /// ICON
          Center(
            child: Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                getIcon(data["type"]),
                color: Colors.blue,
                size: 40,
              ),
            ),
          ),

          const SizedBox(height: 20),

          /// TITLE
          Center(
            child: Text(
              data["title"],
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          const SizedBox(height: 8),

          /// TYPE
          Center(
            child: Text(
              getTypeName(data["type"]),
              style: const TextStyle(
                color: Colors.grey,
              ),
            ),
          ),

          const SizedBox(height: 30),

          /// DETAIL CARD
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(.05),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                )
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                const Text(
                  "รายละเอียด",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),

                const SizedBox(height: 10),

                Text(
                  data["detail"],
                  style: const TextStyle(
                    fontSize: 15,
                    color: Colors.black87,
                  ),
                ),

                const SizedBox(height: 20),

                const Divider(),

                const SizedBox(height: 10),

                Row(
                  children: [

                    const Icon(
                      Icons.access_time,
                      size: 18,
                      color: Colors.grey,
                    ),

                    const SizedBox(width: 6),

                    Text(
                      data["time"],
                      style: const TextStyle(
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 30),

          /// ACTION BUTTON
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF0262EC),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: const Text(
              "กลับ",
              style: TextStyle(
                fontSize: 16,
                color: Colors.white
              ),
            ),
          )
        ],
      ),
    );
  }
}
