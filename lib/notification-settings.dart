import 'package:LawyerOnline/component/dialog_service.dart';
import 'package:flutter/material.dart';

class NotificationSettingPage extends StatefulWidget {
  const NotificationSettingPage({Key? key}) : super(key: key);

  @override
  State<NotificationSettingPage> createState() =>
      _NotificationSettingPageState();
}

class _NotificationSettingPageState extends State<NotificationSettingPage> {
  bool masterNotification = true;
  bool messageNotification = true;
  bool promotionNotification = false;
  bool systemNotification = true;
  bool sound = true;
  bool vibration = false;

  Widget buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required Function(bool) onChanged,
    IconData? icon,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: SwitchListTile(
        value: value,
        onChanged: onChanged,
        activeColor: Color(0xFF0262EC),
        secondary: Icon(icon, color: Colors.blue),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(subtitle),
      ),
    );
  }

  void saveSetting() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(
              Icons.notifications_active,
              color: Colors.green,
              size: 60,
            ),
            SizedBox(height: 16),
            Text(
              "บันทึกสำเร็จ",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            SizedBox(height: 8),
            Text(
              "ตั้งค่าการแจ้งเตือนเรียบร้อยแล้ว",
              textAlign: TextAlign.center,
            )
          ],
        ),
        actions: [
          TextButton(
            child: const Text("ตกลง"),
            onPressed: () {
              Navigator.pop(context);
            },
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF6F7FB),
      appBar: AppBar(
        title: const Text("ตั้งค่าการแจ้งเตือน"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            buildSwitchTile(
              title: "เปิดการแจ้งเตือน",
              subtitle: "เปิดหรือปิดการแจ้งเตือนทั้งหมด",
              value: masterNotification,
              icon: Icons.notifications,
              onChanged: (value) {
                setState(() {
                  masterNotification = value;
                });
              },
            ),
            buildSwitchTile(
              title: "ข้อความ",
              subtitle: "แจ้งเตือนเมื่อมีข้อความใหม่",
              value: messageNotification,
              icon: Icons.message,
              onChanged: (value) {
                setState(() {
                  messageNotification = value;
                });
              },
            ),
            buildSwitchTile(
              title: "นัดหมาย",
              subtitle: "แจ้งเตือนเกี่ยวกับการทัดหมาย",
              value: promotionNotification,
              icon: Icons.local_offer,
              onChanged: (value) {
                setState(() {
                  promotionNotification = value;
                });
              },
            ),
            buildSwitchTile(
              title: "การแจ้งเตือนระบบ",
              subtitle: "แจ้งเตือนเกี่ยวกับระบบ",
              value: systemNotification,
              icon: Icons.settings,
              onChanged: (value) {
                setState(() {
                  systemNotification = value;
                });
              },
            ),
            buildSwitchTile(
              title: "เสียงแจ้งเตือน",
              subtitle: "เปิดเสียงเมื่อมีการแจ้งเตือน",
              value: sound,
              icon: Icons.volume_up,
              onChanged: (value) {
                setState(() {
                  sound = value;
                });
              },
            ),
            buildSwitchTile(
              title: "สั่น",
              subtitle: "สั่นเมื่อมีการแจ้งเตือน",
              value: vibration,
              icon: Icons.vibration,
              onChanged: (value) {
                setState(() {
                  vibration = value;
                });
              },
            ),
            const Spacer(),
            GestureDetector(
              onTap: () => {
                DialogService.showSuccess(
                  context,
                  title: "บันทึกแล้ว",
                  message: "ระบบได้บันทึกการตั้งค่าเรียบร้อยแล้ว",
                  onClose: () {
                    Navigator.pop(context);
                  },
                ),
              },
              child: Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(vertical: 15, horizontal: 10),
                decoration: BoxDecoration(
                    color: const Color(0xFF0262EC),
                    borderRadius: BorderRadius.circular(18),
                    border:
                        Border.all(width: 1, color: const Color(0xFFDBDBDB))),
                child: const Text(
                  "บันทึก",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
