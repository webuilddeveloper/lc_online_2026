import 'package:LawyerOnline/component/appbar.dart';
import 'package:LawyerOnline/consult/consult_status.dart';
import 'package:flutter/material.dart';

class CaseStatusAllPage extends StatefulWidget {
  final List<dynamic> caseList;

  const CaseStatusAllPage({Key? key, required this.caseList}) : super(key: key);

  @override
  State<CaseStatusAllPage> createState() => _CaseStatusAllPageState();
}

class _CaseStatusAllPageState extends State<CaseStatusAllPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final List<Map<String, dynamic>> _tabs = [
    {"label": "ทั้งหมด", "status": null},
    {"label": "กำลังปรึกษา", "status": "1"},
    {"label": "เสร็จสิ้น", "status": "3"},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  List<dynamic> _filteredList(String? status) {
    if (status == null) return widget.caseList;
    return widget.caseList.where((e) => e['status'] == status).toList();
  }

  Color _statusColor(String status) {
    switch (status) {
      case '1':
        return const Color(0xFFEF4444);
      case '2':
        return const Color(0xFFFF9500);
      case '3':
        return const Color(0xFF0262EC);
      default:
        return const Color(0xFF34C759);
    }
  }

  IconData _statusIcon(String status) {
    switch (status) {
      case '1':
        return Icons.info_outline_rounded;
      case '2':
        return Icons.pending_actions_rounded;
      case '3':
        return Icons.pending_actions_rounded;
      default:
        return Icons.check_circle_outline_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEEF2F5),
      appBar: appBar(
        title: "สถานะเคสทั้งหมด",
        backBtn: true,
        rightBtn: false,
        backAction: () => Navigator.pop(context),
        rightAction: () {},
      ),
      body: Column(
        children: [
          // ── Tab Bar ──────────────────────────────────────────
          Container(
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              labelColor: const Color(0xFF0262EC),
              unselectedLabelColor: const Color(0xFF8E8E93),
              labelStyle: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
              unselectedLabelStyle: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w400,
              ),
              indicatorColor: const Color(0xFF0262EC),
              indicatorWeight: 3,
              indicatorSize: TabBarIndicatorSize.label,
              tabs: _tabs.map((tab) {
                final count = _filteredList(tab['status']).length;
                return Tab(
                  child: Row(
                    children: [
                      Text(tab['label']),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEEF2F5),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '$count',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF8E8E93),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),

          // ── Tab Views ─────────────────────────────────────────
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: _tabs.map((tab) {
                final list = _filteredList(tab['status']);
                return list.isEmpty
                    ? _buildEmpty()
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(15, 16, 15, 30),
                        itemCount: list.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: 12),
                        itemBuilder: (context, index) =>
                            _caseCard(list[index]),
                      );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.folder_open_rounded,
              size: 60, color: Colors.grey.shade300),
          const SizedBox(height: 12),
          Text(
            'ไม่พบเคส',
            style: TextStyle(
              fontSize: 15,
              color: Colors.grey.shade400,
            ),
          ),
        ],
      ),
    );
  }

  Widget _caseCard(Map model) {
    final status = model['status']?.toString() ?? '0';
    final statusText = model['statusText'] ?? '';
    final category = model['category'] ?? '';
    final story = model['story'] ?? '';
    final createDate = model['createDate'] ?? '';
    final lawyerModel = model['lawyerModel'] as Map?;
    final lawyerName = lawyerModel?['name'] ?? '';
    final lawyerImage = lawyerModel?['imageUrl'] ?? '';
    final experience = lawyerModel?['experience'] ?? '';
    final color = _statusColor(status);
    final icon = _statusIcon(status);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header: ทนาย + status ──────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: Row(
              children: [
                // รูปทนาย
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.asset(
                    lawyerImage,
                    width: 48,
                    height: 48,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(width: 12),

                // ชื่อ + ประสบการณ์
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        lawyerName,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        experience,
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                ),

                // Status badge
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(icon, size: 12, color: color),
                      const SizedBox(width: 4),
                      Text(
                        statusText,
                        style: TextStyle(
                          fontSize: 11,
                          color: color,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── Divider ───────────────────────────────────────
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Divider(height: 1, color: Color(0xFFF0F0F0)),
          ),

          // ── Category tag ──────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F0FE),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                category,
                style: const TextStyle(
                  fontSize: 11,
                  color: Color(0xFF0262EC),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),

          const SizedBox(height: 10),

          // ── Story preview ─────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              story,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade700,
                height: 1.5,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),

          // ── Footer: วันที่ + ปุ่ม ─────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.access_time_rounded,
                        size: 13, color: Colors.grey.shade400),
                    const SizedBox(width: 4),
                    Text(
                      createDate,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade400,
                      ),
                    ),
                  ],
                ),
                GestureDetector(
                  onTap: () {
                    final lawyerModel = model['lawyerModel'] as Map?;

                    // แมป field จาก caseList → ConsultStatusPage
                    final lawyerForConsult = lawyerModel != null
                        ? {
                            'name': lawyerModel['name'] ?? '',
                            // ConsultStatusPage ใช้ 'avatar' เป็น initials text
                            'avatar': (lawyerModel['name'] as String? ?? 'ท')
                                .characters
                                .first,
                            // 'title' = ความเชี่ยวชาญ ใช้ skills ตัวแรก หรือ experience
                            'title': lawyerModel['skills'] != null &&
                                    (lawyerModel['skills'] as List).isNotEmpty
                                ? (lawyerModel['skills'] as List).first
                                : lawyerModel['experience'] ?? '',
                            // 'rating' = scroll ใน lawyerModel
                            'rating': lawyerModel['scroll'] ?? 0,
                            // เก็บ imageUrl ไว้ด้วยเผื่อใช้ในอนาคต
                            'imageUrl': lawyerModel['imageUrl'] ?? '',
                          }
                        : null;

                    // แปลง status string → currentStep int
                    // status: "1"=กำลังปรึกษา, "2"=กำลังดำเนินการ, "3"=เสร็จสิ้น
                    // currentStep: 0=ส่งคำขอ, 1=รอยืนยัน, 2=ยืนยันแล้ว, 3=กำลังปรึกษา, 4=เสร็จสิ้น
                    final statusToStep = {
                      '3': 3, // กำลังปรึกษา
                      '2': 2, // กำลังดำเนินการ → ยืนยันแล้ว
                      '4': 4, // เสร็จสิ้น
                    };
                    final currentStep = statusToStep[
                            model['status']?.toString() ?? '1'] ??
                        3;

                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ConsultStatusPage(
                          currentStep: currentStep,
                          lawyer: lawyerForConsult,
                          appointmentDate: model['appointmentDate'],
                          appointmentTime: model['appointmentTime'],
                        ),
                      ),
                    );
                    print(currentStep);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0262EC),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'ดูรายละเอียด',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}