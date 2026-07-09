import 'package:LawyerOnline/component/appbar.dart';
import 'package:LawyerOnline/component/dialog_service.dart';
import 'package:LawyerOnline/component/loading_service.dart';
import 'package:LawyerOnline/shared/notification_settings_store.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:LawyerOnline/shared/responsive/app_layout.dart';

class NotificationSettingPage extends StatefulWidget {
  const NotificationSettingPage({Key? key}) : super(key: key);

  @override
  State<NotificationSettingPage> createState() =>
      _NotificationSettingPageState();
}

class _NotificationSettingPageState extends State<NotificationSettingPage> {
  final _store = NotificationSettingsStore.instance;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    await _store.load();
    if (mounted) setState(() => _loading = false);
  }

  Widget buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required Function(bool) onChanged,
    IconData? icon,
    bool enabled = true,
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
        onChanged: enabled ? onChanged : null,
        activeColor: const Color(0xFF0262EC),
        inactiveTrackColor: Colors.white,
        inactiveThumbColor: Colors.black,
        secondary: Icon(icon, color: enabled ? Colors.blue : Colors.grey),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: enabled ? Colors.black : Colors.grey,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w400,
            color: enabled ? Colors.black54 : Colors.grey,
          ),
        ),
      ),
    );
  }

  Future<void> _saveSettings() async {
    await _store.save();
    if (!mounted) return;
    DialogService.showSuccess(
      context,
      title: "saveSuccess".tr(),
      message: "notificationSettingsMessage".tr(),
      onClose: () => Navigator.pop(context),
    );
  }

  @override
  Widget build(BuildContext context) {
    final masterOn = _store.masterEnabled;

    return Scaffold(
      backgroundColor: const Color(0xffF6F7FB),
      appBar: appBarCustom(
        title: "notificationSettingsTitle".tr(),
        backBtn: true,
        backAction: () => goBack(),
        isRightWidget: false,
      ),
      body: _loading
          ? AppLoadingView(message: 'loading'.tr())
          : AppLayout(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    buildSwitchTile(
                      title: "enableNotification".tr(),
                      subtitle: "enableAllNotificationDesc".tr(),
                      value: _store.masterEnabled,
                      icon: Icons.notifications,
                      onChanged: (value) {
                        setState(() => _store.update(masterEnabled: value));
                      },
                    ),
                    buildSwitchTile(
                      title: "message".tr(),
                      subtitle: "messageDesc".tr(),
                      value: _store.messageEnabled,
                      icon: Icons.message,
                      enabled: masterOn,
                      onChanged: (value) {
                        setState(() => _store.update(messageEnabled: value));
                      },
                    ),
                    buildSwitchTile(
                      title: "appointment".tr(),
                      subtitle: "appointmentDesc".tr(),
                      value: _store.appointmentEnabled,
                      icon: Icons.event,
                      enabled: masterOn,
                      onChanged: (value) {
                        setState(
                            () => _store.update(appointmentEnabled: value));
                      },
                    ),
                    buildSwitchTile(
                      title: "system".tr(),
                      subtitle: "systemDesc".tr(),
                      value: _store.systemEnabled,
                      icon: Icons.settings,
                      enabled: masterOn,
                      onChanged: (value) {
                        setState(() => _store.update(systemEnabled: value));
                      },
                    ),
                    const SizedBox(height: 8),
                    buildSwitchTile(
                      title: "sound".tr(),
                      subtitle: "soundDesc".tr(),
                      value: _store.soundEnabled,
                      icon: Icons.volume_up,
                      enabled: masterOn,
                      onChanged: (value) {
                        setState(() => _store.update(soundEnabled: value));
                      },
                    ),
                    buildSwitchTile(
                      title: "vibration".tr(),
                      subtitle: "vibrationDesc".tr(),
                      value: _store.vibrationEnabled,
                      icon: Icons.vibration,
                      enabled: masterOn,
                      onChanged: (value) {
                        setState(() => _store.update(vibrationEnabled: value));
                      },
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: _saveSettings,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                            vertical: 15, horizontal: 10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0262EC),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                              width: 1, color: const Color(0xFFDBDBDB)),
                        ),
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
            ),
    );
  }

  void goBack() {
    Navigator.pop(context);
  }
}
