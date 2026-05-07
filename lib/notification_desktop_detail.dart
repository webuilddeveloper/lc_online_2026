import 'package:flutter/material.dart';

class NotificationDesktopDetailPage extends StatefulWidget {
  final Map<String, dynamic>? initialData;

  const NotificationDesktopDetailPage({Key? key, this.initialData}) : super(key: key);

  @override
  State<NotificationDesktopDetailPage> createState() =>
      _NotificationDesktopDetailPageState();
}

class _NotificationDesktopDetailPageState
    extends State<NotificationDesktopDetailPage> {
  Map<String, dynamic>? selectedItem;

  // Mock data matching the UI image
  List<Map<String, dynamic>> notifications = [
    {
      "type": "booking",
      "title": "นัดหมายปรึกษาทนายความ",
      "detail": "ทนายศักดิ์สิทธิ์",
      "time": "09:00",
      "date": "วันนี้",
      "isRead": false,
      "fullDetail": "การนัดหมายปรึกษาคดีของคุณกับทนายศักดิ์สิทธิ์ ได้รับการยืนยันแล้ว กรุณาเตรียมเอกสารที่เกี่ยวข้องให้พร้อมก่อนถึงเวลานัดหมาย"
    },
    {
      "type": "system",
      "title": "อัปเดตสถานะคำร้อง",
      "detail": "ระบบอัตโนมัติ",
      "time": "08:15",
      "date": "วันนี้",
      "isRead": true,
      "fullDetail": "คำร้องของคุณได้รับการอัปเดตสถานะเรียบร้อยแล้ว สามารถตรวจสอบรายละเอียดเพิ่มเติมได้ในหน้าติดตามสถานะ"
    },
    {
      "type": "document",
      "title": "เอกสารของคุณถูกดาวน์โหลด",
      "detail": "คุณรินรดา (ผู้ช่วยทนาย)",
      "time": "16:45",
      "date": "15 พ.ค. 2569",
      "isRead": true,
      "fullDetail": "เอกสารสำเนาคำฟ้องที่คุณอัปโหลดไว้ ถูกดาวน์โหลดโดย คุณรินรดา (ผู้ช่วยทนาย) เพื่อนำไปดำเนินการต่อเรียบร้อยแล้ว"
    },
    {
      "type": "system",
      "title": "ยินดีต้อนรับสู่ LegalApp",
      "detail": "Support Team",
      "time": "10:00",
      "date": "14 พ.ค. 2569",
      "isRead": true,
      "fullDetail": "ยินดีต้อนรับเข้าสู่บริการ LawyerOnline ของเรา หากมีข้อสงสัยหรือต้องการความช่วยเหลือ สามารถติดต่อทีมซัพพอร์ตได้ตลอด 24 ชั่วโมง"
    }
  ];

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
                const Text(
                  'รายการทั้งหมด',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF374151),
                  ),
                ),
                InkWell(
                  onTap: markAllRead,
                  child: const Text(
                    'อ่านทั้งหมด',
                    style: TextStyle(
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
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                            color: isSelected ? const Color(0xFFF3F4F6) : Colors.white,
                            border: const Border(
                              bottom: BorderSide(color: Color(0xFFF3F4F6), width: 1),
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
                                              fontWeight: isRead ? FontWeight.w500 : FontWeight.bold,
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
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: isRead ? Colors.white : const Color(0xFFEFF6FF),
                                      border: Border.all(
                                        color: isRead ? const Color(0xFFE5E7EB) : const Color(0xFFBFDBFE),
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      isRead ? 'อ่านแล้ว' : 'ใหม่',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: isRead ? const Color(0xFF9CA3AF) : const Color(0xFF0262EC),
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
              const Text(
                'เลือกข้อความเพื่อดูรายละเอียด',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF374151),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'ข้อความแจ้งเตือนสำคัญเกี่ยวกับเคสของคุณจะแสดงที่นี่',
                style: TextStyle(
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
            selectedItem!["title"] ?? 'ไม่มีหัวข้อ',
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
                '${selectedItem!["date"]} เวลา ${selectedItem!["time"]}',
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
            selectedItem!["fullDetail"] ?? selectedItem!["detail"] ?? 'ไม่มีรายละเอียดเพิ่มเติม',
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
        title: const Text(
          'แจ้งเตือน',
          style: TextStyle(
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
