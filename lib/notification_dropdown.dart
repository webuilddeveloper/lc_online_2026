import 'package:LawyerOnline/notification_desktop_detail.dart';
import 'package:LawyerOnline/notification.dart';
import 'package:LawyerOnline/services/notification_list_service.dart';
import 'package:LawyerOnline/services/notification_navigation_service.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

class NotificationDropdownContent extends StatefulWidget {
  const NotificationDropdownContent({super.key});

  @override
  State<NotificationDropdownContent> createState() =>
      _NotificationDropdownContentState();
}

class _NotificationDropdownContentState
    extends State<NotificationDropdownContent> {
  List<Map<String, dynamic>> _notifications = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final list = await NotificationListService.load();
    if (!mounted) return;
    setState(() {
      _notifications = list;
      _isLoading = false;
    });
  }

  int get unreadCount =>
      _notifications.where((n) => n['isRead'] != true).length;

  IconData getIcon(dynamic type) {
    switch (type) {
      case 'chat':
      case 'chat_message':
        return Icons.chat_bubble;
      case 'booking':
        return Icons.calendar_month;
      case 'payment':
        return Icons.payment;
      case 'finish':
        return Icons.task_alt;
      default:
        return Icons.notifications;
    }
  }

  Future<void> markAllRead() async {
    await NotificationListService.markAllRead(_notifications);
    if (!mounted) return;
    setState(() {});
  }

  Widget buildItem(Map<String, dynamic> item) {
    return GestureDetector(
      onTap: () async {
        await NotificationListService.markOneRead(item);
        if (!mounted) return;
        setState(() {});
        Navigator.pop(context);
        final isDesktop = MediaQuery.of(context).size.width >= 1024;
        if (isDesktop) {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => NotificationDesktopDetailPage(initialData: item),
            ),
          );
        } else {
          NotificationNavigationService.handlePayload(item);
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        margin: const EdgeInsets.symmetric(vertical: 4),
        decoration: BoxDecoration(
          color: item['isRead'] == true
              ? Colors.transparent
              : const Color(0xFFBAD5FF).withOpacity(0.3),
          borderRadius: BorderRadius.circular(12),
        ),
        child: ListTile(
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
          leading: CircleAvatar(
            backgroundColor: item['isRead'] == true
                ? const Color(0xFFEEF2F5)
                : Colors.white,
            child: Icon(
              getIcon(item['type']),
              color: Colors.blue,
              size: 20,
            ),
          ),
          title: Text(
            item['title']?.toString() ?? '',
            style: TextStyle(
              fontSize: 14,
              fontWeight:
                  item['isRead'] == true ? FontWeight.normal : FontWeight.bold,
            ),
          ),
          subtitle: Text(
            item['detail']?.toString() ?? '',
            style: const TextStyle(fontSize: 12),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                item['time']?.toString() ?? '',
                style: const TextStyle(fontSize: 10, color: Colors.grey),
              ),
              if (item['isRead'] != true)
                Container(
                  margin: const EdgeInsets.only(top: 4),
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildSection(String title, String date) {
    final items =
        _notifications.where((n) => n['date']?.toString() == date).toList();
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
        ...items.map(buildItem),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Text(
                  'notifications'.tr(),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 8),
                if (unreadCount > 0)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      unreadCount.toString(),
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ),
              ],
            ),
            IconButton(
              onPressed: markAllRead,
              icon: const Icon(Icons.done_all, size: 20),
              tooltip: 'notification.allRead'.tr(),
            ),
          ],
        ),
        const Divider(),
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _notifications.isEmpty
                  ? Center(
                      child: Text(
                        'notification.empty'.tr(),
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    )
                  : ListView(
                      padding: EdgeInsets.zero,
                      children: [
                        buildSection('timeline.today'.tr(), 'today'),
                        buildSection('timeline.yesterday'.tr(), 'yesterday'),
                        buildSection('timeline.earlier'.tr(), 'earlier'),
                      ],
                    ),
        ),
        const Divider(height: 1),
        SizedBox(
          width: double.infinity,
          child: TextButton(
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) {
                    final isDesktop = MediaQuery.of(context).size.width >= 1024;
                    if (isDesktop) {
                      return const NotificationDesktopDetailPage();
                    }
                    return const NotificationPage();
                  },
                ),
              );
            },
            child: Text(
              'notification.listAll'.tr(),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ],
    );
  }
}
