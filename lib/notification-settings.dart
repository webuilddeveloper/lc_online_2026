import 'package:LawyerOnline/component/appbar.dart';
import 'package:LawyerOnline/component/dialog_service.dart';
import 'package:easy_localization/easy_localization.dart';
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
        // activeTrackColor: Colors.amber,
        inactiveTrackColor: Colors.white,
        inactiveThumbColor: Colors.black,
        // trackOutlineColor: WidgetStateProperty.all(Colors.blue),
        secondary: Icon(icon, color: Colors.blue),
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w400,
          ),
        ),
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
          children: [
            const Icon(
              Icons.notifications_active,
              color: Colors.green,
              size: 60,
            ),
            const SizedBox(height: 16),
            Text(
              "saveSuccess".tr(),
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "notificationSettingsMessage".tr(),
              textAlign: TextAlign.center,
            )
          ],
        ),
        actions: [
          TextButton(
            child: Text("ok".tr()),
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
      appBar: appBarCustom(
        title: "notificationSettingsTitle".tr(),
        backBtn: true,
        backAction: () => goBack(),
        isRightWidget: false,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            buildSwitchTile(
              title: "enableNotification".tr(),
              subtitle: "enableAllNotificationDesc".tr(),
              value: masterNotification,
              icon: Icons.notifications,
              onChanged: (value) {
                setState(() {
                  masterNotification = value;
                });
              },
            ),
            buildSwitchTile(
              title: "message".tr(),
              subtitle: "messageDesc".tr(),
              value: messageNotification,
              icon: Icons.message,
              onChanged: (value) {
                setState(() {
                  messageNotification = value;
                });
              },
            ),
            buildSwitchTile(
              title: "appointment".tr(),
              subtitle: "appointmentDesc".tr(),
              value: promotionNotification,
              icon: Icons.local_offer,
              onChanged: (value) {
                setState(() {
                  promotionNotification = value;
                });
              },
            ),
            buildSwitchTile(
              title: "system".tr(),
              subtitle: "systemDesc".tr(),
              value: systemNotification,
              icon: Icons.settings,
              onChanged: (value) {
                setState(() {
                  systemNotification = value;
                });
              },
            ),
            buildSwitchTile(
              title: "sound".tr(),
              subtitle: "soundDesc".tr(),
              value: sound,
              icon: Icons.volume_up,
              onChanged: (value) {
                setState(() {
                  sound = value;
                });
              },
            ),
            buildSwitchTile(
              title: "vibration".tr(),
              subtitle: "vibrationDesc".tr(),
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
                  title: "saveSuccess".tr(),
                  message: "saveSuccessMessage".tr(),
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
                child: Text(
                  "saveButton".tr(),
                  style: const TextStyle(
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

  void goBack() {
    Navigator.pop(context);
  }
}
