import 'package:LawyerOnline/component/appbar.dart';
import 'package:LawyerOnline/consult/consult_status.dart';
import 'package:LawyerOnline/models/lawyer/lawyer_jobs_store.dart';
import 'package:LawyerOnline/models/user/user_case_adapter.dart';
import 'package:LawyerOnline/models/user_profile_store.dart';
import 'package:LawyerOnline/shared/api_provider.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/services.dart';
import 'package:LawyerOnline/shared/responsive/app_layout.dart';
import 'package:LawyerOnline/shared/responsive/res_layout.dart';

class CaseStatusAllPage extends StatefulWidget {
  final List<dynamic> caseList;

  const CaseStatusAllPage({Key? key, required this.caseList}) : super(key: key);

  @override
  State<CaseStatusAllPage> createState() => _CaseStatusAllPageState();
}

class _CaseStatusAllPageState extends State<CaseStatusAllPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final List<dynamic> _tabs = [
    {"label": "ทั้งหมด", "status": null},
    {"label": "รอทนาย", "status": "1"},
    {"label": "กำลังปรึกษา", "status": "3"},
    {"label": "ยกเลิก", "status": "5"},
    {"label": "เสร็จสิ้น", "status": "4"},
  ];

  @override
  void initState() {
    super.initState();
    // LawyerJobsStore.instance.addListener(_onJobsChanged);
    callReadCase();
    _tabController = TabController(length: _tabs.length, vsync: this);
  }

  @override
  void dispose() {
    LawyerJobsStore.instance.removeListener(_onJobsChanged);
    _tabController.dispose();
    super.dispose();
  }

  void _onJobsChanged() {
    if (mounted) setState(() {});
  }

  List<dynamic> _caseList = [];

  List<dynamic> _filteredList(String? status) {
    if (status == null) return _caseList;
    return _caseList.where((e) => e['status'] == status).toList();
  }

  Color _statusColor(String status) {
    switch (status) {
      case '1':
        return const Color(0xFFD97706);
      case '2':
        return const Color(0xFFFF9500);
      case '3':
        return const Color(0xFF059669);
      case '4':
        return const Color(0xFF6B7A99);
      case '5':
        return const Color(0xFFEF4444);
      default:
        return const Color(0xFF0262EC);
    }
  }

  IconData _statusIcon(String status) {
    switch (status) {
      case '1':
        return Icons.hourglass_top_rounded;
      case '2':
        return Icons.pending_actions_rounded;
      case '3':
        return Icons.chat_bubble_outline_rounded;
      case '4':
        return Icons.check_circle_outline_rounded;
      case '5':
        return Icons.cancel_outlined;
      default:
        return Icons.info_outline_rounded;
    }
  }

  Future<void> callReadCase() async {
    try {
      final param = await postDio("${server}/m/case/read", {});
      setState(() {
        _caseList = param['objectData'];
       print('=-=-=-=-=-=-=-=-=-=-= ${param}');
      });
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = ResponsiveLayout.isDesktop(context);

    return Scaffold(
      backgroundColor: isDesktop ? const Color(0xFFE9F2F9) : Colors.white,
      appBar: isDesktop
          ? null
          : appBar(
              title: "สถานะเคสทั้งหมด",
              backBtn: true,
              rightBtn: false,
              backAction: () => Navigator.pop(context),
              rightAction: () {},
            ),
      body: AppLayout(
        child: Container(
          decoration: isDesktop
              ? BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                )
              : null,
          child: Column(
            children: [
              if (isDesktop)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () {
                          HapticFeedback.lightImpact();
                          Navigator.pop(context);
                        },
                        child: Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            border: Border.all(
                                width: 1, color: const Color(0xFFDBDBDB)),
                          ),
                          child: const Icon(Icons.arrow_back_ios_new_rounded,
                              size: 18, color: Color(0xFF0F172A)),
                        ),
                      ),
                      const SizedBox(width: 14),
                      const Text(
                        'สถานะเคสทั้งหมด',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                    ],
                  ),
                ),
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
                          Text(
                            tab['label'],
                            style: GoogleFonts.prompt(),
                          ),
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
                              style: GoogleFonts.prompt(
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
                child: Container(
                  color: const Color(0xFFEEF2F5),
                  child: TabBarView(
                    controller: _tabController,
                    children: _tabs.map((tab) {
                      final list = _filteredList(tab['status']);
                      return list.isEmpty
                          ? _buildEmpty()
                          : ListView.separated(
                              padding:
                                  const EdgeInsets.fromLTRB(15, 16, 15, 30),
                              itemCount: list.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: 12),
                              itemBuilder: (context, index) =>
                                  _caseCard(list[index]),
                            );
                    }).toList(),
                  ),
                ),
              ),
            ],
          ),
        ),
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

  Map<String, dynamic>? _lawyerForConsult(Map? lawyerModel, Map model) {
    if (lawyerModel == null) return null;
    return {
      'id': model['id'],
      'jobId': model['id'],
      'code': lawyerModel['code'],
      'name': lawyerModel['name'] ?? '',
      'avatar': (lawyerModel['name'] as String? ?? 'ท').characters.first,
      'title': lawyerModel['skills'] != null &&
              (lawyerModel['skills'] as List).isNotEmpty
          ? (lawyerModel['skills'] as List).first
          : lawyerModel['experience'] ?? '',
      'rating': lawyerModel['scroll'] ?? 0,
      'imageUrl': lawyerModel['imageUrl'] ?? '',
      'appointmentDate': model['appointmentDate'],
      'appointmentTime': model['appointmentTime'],
      'active': model['jobStatus'] == 'accepted' ||
          model['jobStatus'] == 'in_session',
      'caseSuccess': model['jobStatus'] == 'done',
      'chatLocked': model['jobStatus'] == 'confirmed',
      'jobStatus': model['jobStatus'],
      'jobSource': model['jobSource'],
    };
  }

  void _openCaseDetail(Map model) {
    final jobStatus = model['jobStatus']?.toString() ?? 'pending';
    if (jobStatus == 'rejected') {
      _showRejectedCase(model);
      return;
    }
    final jobSource = model['jobSource']?.toString() ?? 'urgent';

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ConsultStatusPage(
          currentStep:
              consultStepFromJobStatus(model['caseStatus'], jobSource: model['caseType']),
          lawyer: _lawyerForConsult(model['lawyerModel'] as Map?, model),
          appointmentDate: model['appointmentDate'],
          appointmentTime: model['appointmentTime'],
          canOpenChat: jobStatus == 'accepted' ||
              jobStatus == 'confirmed' ||
              jobStatus == 'in_session' ||
              jobStatus == 'done',
          caseModel: Map<String, dynamic>.from(model),
        ),
      ),
    );
  }

  void _showRejectedCase(Map model) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.cancel_outlined, color: Color(0xFFEF4444)),
            SizedBox(width: 8),
            Expanded(child: Text('เคสถูกปฏิเสธ')),
          ],
        ),
        content: Text(
          'คำขอ "${model['category'] ?? ''}" ถูกปฏิเสธแล้ว คุณสามารถเปิดเคสใหม่หรือเลือกทนายคนอื่นได้',
          style: GoogleFonts.prompt(fontSize: 14, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'ตกลง',
              style: GoogleFonts.prompt(
                color: const Color(0xFF0262EC),
                fontWeight: FontWeight.w700,
              ),
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
    final subTopic = model['subTopic'] ?? '';
    final story = model['story'] ?? '';
    final createDate = model['createDate'] ?? '';
    final appointmentDate = model['appointmentDate'] ?? '';
    final appointmentTime = model['appointmentTime'] ?? '';
    final budget = model['budget'] ?? '';
    final lawyerModel = model['lawyerModel'] as Map?;
    final lawyerName = lawyerModel?['name'] ?? '';
    final lawyerImage = lawyerModel?['imageUrl'] ?? '';
    final experience = lawyerModel?['experience'] ?? '';
    final color = _statusColor(status);
    final icon = _statusIcon(status);

    return GestureDetector(
      onTap: () => _openCaseDetail(model),
      child: Container(
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
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
                  if (subTopic.toString().isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      subTopic,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1A2340),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
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
                  Expanded(
                    child: Row(
                      children: [
                        Icon(Icons.access_time_rounded,
                            size: 13, color: Colors.grey.shade400),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            [
                              if (appointmentDate.toString().isNotEmpty)
                                appointmentDate,
                              if (appointmentTime.toString().isNotEmpty)
                                appointmentTime,
                              if (appointmentDate.toString().isEmpty &&
                                  appointmentTime.toString().isEmpty)
                                createDate,
                            ].join(' · '),
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade400,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (budget.toString().isNotEmpty) ...[
                          const SizedBox(width: 8),
                          Text(
                            budget,
                            style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xFF0262EC),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () {
                      _openCaseDetail(model);
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
      ),
    );
  }
}
