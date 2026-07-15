import 'package:LawyerOnline/component/appbar.dart';
import 'package:LawyerOnline/component/dialog_service.dart';
import 'package:LawyerOnline/component/loading_service.dart';
import 'package:LawyerOnline/models/user_profile_store.dart';
import 'package:LawyerOnline/services/device_session_service.dart';
import 'package:LawyerOnline/shared/app_typography.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class DeviceSessionsPage extends StatefulWidget {
  const DeviceSessionsPage({super.key});

  @override
  State<DeviceSessionsPage> createState() => _DeviceSessionsPageState();
}

class _DeviceSessionsPageState extends State<DeviceSessionsPage> {
  bool _loading = true;
  List<DeviceSession> _sessions = [];
  String? _currentToken;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      const storage = FlutterSecureStorage();
      _currentToken = await storage.read(key: 'token');
      final userCode = UserProfileStore.instance.code;
      final sessions = await DeviceSessionService.loadSessions(
        userCode: userCode,
        currentToken: _currentToken,
      );
      if (mounted) setState(() => _sessions = sessions);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _revoke(DeviceSession session) async {
    if (session.isCurrent) return;
    final ok = await DeviceSessionService.revoke(
      userCode: UserProfileStore.instance.code,
      token: session.token,
    );
    if (!mounted) return;
    if (ok) {
      await _load();
    } else {
      DialogService.showError(
        context,
        title: 'errorTitle'.tr(),
        message: 'deviceRevokeFailed'.tr(),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: appBar(
        title: 'deviceSessionsTitle'.tr(),
        backBtn: true,
        rightBtn: false,
        backAction: () => Navigator.pop(context),
        rightAction: () {},
      ),
      body: _loading
          ? const AppLoadingView()
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: _sessions.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (_, i) {
                final s = _sessions[i];
                return Card(
                  child: ListTile(
                    leading: Icon(
                      s.platform == 'ios'
                          ? Icons.phone_iphone_rounded
                          : s.platform == 'android'
                              ? Icons.phone_android_rounded
                              : Icons.devices_rounded,
                    ),
                    title: Text(s.deviceName,
                        style: AppTypography.prompt(fontWeight: FontWeight.w600)),
                    subtitle: Text('${s.createDate} ${s.createTime}'),
                    trailing: s.isCurrent
                        ? Chip(label: Text('deviceCurrent'.tr()))
                        : TextButton(
                            onPressed: () => _revoke(s),
                            child: Text('deviceRevoke'.tr()),
                          ),
                  ),
                );
              },
            ),
    );
  }
}
