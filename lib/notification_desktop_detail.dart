import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:LawyerOnline/notification.dart';

class NotificationDesktopDetailPage extends StatefulWidget {
  final Map<String, dynamic>? initialData;

  const NotificationDesktopDetailPage({Key? key, this.initialData})
      : super(key: key);

  @override
  State<NotificationDesktopDetailPage> createState() =>
      _NotificationDesktopDetailPageState();
}

class _NotificationDesktopDetailPageState
    extends State<NotificationDesktopDetailPage> {
  Map<String, dynamic>? selectedItem;

  List<Map<String, dynamic>> get notifications => globalNotifications;

  @override
  void initState() {
    super.initState();
    selectedItem = widget.initialData;
  }

  void markAllRead() {
    setState(() {
      for (var n in notifications) {
        n["isRead"] = true;
      }
    });
  }

  Widget _buildLeftPane() {
    // Group notifications by date
    Map<String, List<Map<String, dynamic>>> grouped = {};
    for (var n in notifications) {
      grouped.putIfAbsent(n["date"], () => []).add(n);
    }

    return Container(
      width: 350,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          right: BorderSide(color: Color(0xFFE5E7EB), width: 1),
        ),
      ),
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'notification.allItems'.tr(),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF374151),
                  ),
                ),
                InkWell(
                  onTap: markAllRead,
                  child: Text(
                    "notification.allRead".tr(),
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF0262EC),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFE5E7EB)),
          // List
          Expanded(
            child: ListView.builder(
              itemCount: grouped.keys.length,
              itemBuilder: (context, index) {
                String date = grouped.keys.elementAt(index);
                List<Map<String, dynamic>> items = grouped[date]!;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Section Header
                    Container(
                      width: double.infinity,
                      color: const Color(0xFFF9FAFB),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      child: Text(
                        date,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF6B7280),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    // Items
                    ...items.map((item) {
                      bool isSelected = selectedItem == item;
                      bool isRead = item["isRead"] == true;

                      return InkWell(
                        onTap: () {
                          setState(() {
                            item["isRead"] = true;
                            selectedItem = item;
                          });
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: isSelected
                                ? const Color(0xFFF3F4F6)
                                : Colors.white,
                            border: const Border(
                              bottom: BorderSide(
                                  color: Color(0xFFF3F4F6), width: 1),
                            ),
                          ),
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Flexible(
                                          child: Text(
                                            item["title"],
                                            style: TextStyle(
                                              fontSize: 15,
                                              fontWeight: isRead
                                                  ? FontWeight.w500
                                                  : FontWeight.bold,
                                              color: const Color(0xFF111827),
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        if (!isRead) ...[
                                          const SizedBox(width: 6),
                                          Container(
                                            width: 8,
                                            height: 8,
                                            decoration: const BoxDecoration(
                                              color: Color(0xFF0262EC),
                                              shape: BoxShape.circle,
                                            ),
                                          ),
                                        ]
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      item["detail"],
                                      style: const TextStyle(
                                        fontSize: 13,
                                        color: Color(0xFF6B7280),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    item["time"],
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF9CA3AF),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: isRead
                                          ? Colors.white
                                          : const Color(0xFFEFF6FF),
                                      border: Border.all(
                                        color: isRead
                                            ? const Color(0xFFE5E7EB)
                                            : const Color(0xFFBFDBFE),
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      isRead
                                          ? 'notification.msg.read'.tr()
                                          : 'notification.msg.new'.tr(),
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: isRead
                                            ? const Color(0xFF9CA3AF)
                                            : const Color(0xFF0262EC),
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRightPane() {
    if (selectedItem == null) {
      return Container(
        color: const Color(0xFFF9FAFB),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'assets/icons/bell-2.png',
                width: 80,
                height: 80,
                color: const Color(0xFFFDE68A), // Light yellowish for bell icon
              ),
              const SizedBox(height: 24),
              Text(
                'notification.common.tapForDetail'.tr(),
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF374151),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'notification.common.emptyCaseAlerts'.tr(),
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF9CA3AF),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            selectedItem!["title"] ?? 'notification.common.noSubject'.tr(),
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.access_time, size: 16, color: Color(0xFF6B7280)),
              const SizedBox(width: 8),
              Text(
                '${selectedItem!["date"]} ${'notification.common.time'.tr()} ${selectedItem!["time"]}',
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF6B7280),
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          const Divider(color: Color(0xFFE5E7EB)),
          const SizedBox(height: 32),
          Text(
            selectedItem!["fullDetail"] ??
                selectedItem!["detail"] ??
                'notification.common.noDetails'.tr(),
            style: const TextStyle(
              fontSize: 16,
              height: 1.6,
              color: Color(0xFF374151),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          'notifications'.tr(),
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF111827),
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF111827),
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            color: const Color(0xFFE5E7EB),
            height: 1,
          ),
        ),
      ),
      body: Row(
        children: [
          _buildLeftPane(),
          Expanded(child: _buildRightPane()),
        ],
      ),
    );
  }
}
