import 'package:LawyerOnline/component/appbar.dart';
import 'package:LawyerOnline/models/user_profile_store.dart';
import 'package:LawyerOnline/shared/api_provider.dart';
import 'package:flutter/material.dart';

class TestPage extends StatefulWidget {
  @override
  State<TestPage> createState() => _TestPageState();
}

class _TestPageState extends State<TestPage> {
  List<dynamic> _notifications = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final param = await postDio('$server/m/notification/read', {
      'code': UserProfileStore.instance.code,
      'skip': 0,
      'limit': 50,
    });
    setState(() {
      _notifications = param['objectData'];
      _isLoading = false;
    });

    // mark all read
    await postDio('$server/m/notification/markRead', {
      'userRef': UserProfileStore.instance.code,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: appBar(title: 'การแจ้งเตือน', backBtn: true, rightBtn: false,
          backAction: () => Navigator.pop(context), rightAction: () {}),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: _notifications.length,
              itemBuilder: (_, i) {
                final n = _notifications[i];
                return ListTile(
                  leading: Icon(_iconForType(n['type'])),
                  title: Text(n['title'] ?? ''),
                  subtitle: Text(n['body'] ?? ''),
                  trailing: n['isRead'] == false
                      ? Container(width: 8, height: 8,
                          decoration: const BoxDecoration(
                              color: Color(0xFF0262EC), shape: BoxShape.circle))
                      : null,
                  onTap: () => _navigateByType(n),
                );
              },
            ),
    );
  }

  IconData _iconForType(String? type) {
    switch (type) {
      case 'case_accepted': return Icons.check_circle_outline_rounded;
      case 'case_rejected': return Icons.cancel_outlined;
      case 'session_start': return Icons.headset_mic_rounded;
      case 'chat_message': return Icons.chat_bubble_outline_rounded;
      default: return Icons.notifications_outlined;
    }
  }

  void _navigateByType(dynamic n) {
    // navigate ตาม n['page'] + n['refCode']
  }
}