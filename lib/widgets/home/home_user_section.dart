import 'package:LawyerOnline/appointment-details-lawyer.dart';
import 'package:LawyerOnline/appointment-details.dart';
import 'package:LawyerOnline/case-status-all.dart';
import 'package:LawyerOnline/models/user/user_case_adapter.dart';
import 'package:LawyerOnline/law_type_all_page.dart';
import 'package:LawyerOnline/lawyer-online-details.dart';
import 'package:LawyerOnline/lawyer-online-list.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:LawyerOnline/login.dart';
import 'package:LawyerOnline/component/loading_service.dart';
import 'package:easy_localization/easy_localization.dart';
import 'dart:math' as math;
import 'package:LawyerOnline/shared/responsive/res_layout.dart';
import 'package:LawyerOnline/shared/responsive/responsive_values.dart';

// ─── Status helpers ───────────────────────────────────────────────
dynamic _buildLawyerForConsult(Map? m, Map caseModel) {
  if (m == null) return null;
  return {
    'id': caseModel['id'],
    'jobId': caseModel['id'],
    'code': m['code'],
    'name': m['name'] ?? '',
    'avatar': (m['name'] as String? ?? 'ท').characters.first,
    'title': (m['skills'] as List?)?.isNotEmpty == true
        ? (m['skills'] as List).first
        : m['experience'] ?? '',
    'rating': m['scroll'] ?? 0,
    'imageUrl': m['imageUrl'] ?? '',
    'appointmentDate': caseModel['appointmentDate'],
    'appointmentTime': caseModel['appointmentTime'],
    'active': caseModel['jobStatus'] == 'accepted' ||
        caseModel['jobStatus'] == 'in_session',
    'caseSuccess': caseModel['jobStatus'] == 'done',
    'chatLocked': caseModel['jobStatus'] == 'confirmed',
    'jobStatus': caseModel['jobStatus'],
    'jobSource': caseModel['jobSource'],
  };
}

const _kPrimary = Color(0xFF0262EC);
const _kAccent = Color(0xFF2F80ED);
const _kGold = Color(0xFFF5A623);
const _kCard = Colors.white;
const _kText = Color(0xFF0D1B2A);
const _kSub = Color(0xFF6B7A99);

Widget _lawyerCardImage(String url) {
  if (url.isEmpty || url.startsWith('assets/')) {
    return Image.asset(
      url.isEmpty ? 'assets/images/lawyer-avatar-1.png' : url,
      height: 100,
      width: double.infinity,
      fit: BoxFit.cover,
    );
  }
  return CachedNetworkImage(
    imageUrl: url,
    height: 100,
    width: double.infinity,
    fit: BoxFit.cover,
    memCacheWidth: 320,
    placeholder: (_, __) => Container(
      height: 100,
      color: Colors.grey.shade200,
    ),
    errorWidget: (_, __, ___) => Container(
      height: 100,
      color: Colors.grey.shade200,
      child: const Icon(Icons.person, color: Colors.grey),
    ),
  );
}

// ─── User Dashboard ───────────────────────────────────────────────
// รวม: case status list, law categories, lawyer online, new lawyers
// StatelessWidget → rebuild เฉพาะเมื่อ props เปลี่ยนเท่านั้น
class HomeUserSection extends StatelessWidget {
  final List<dynamic> cases;
  final List<Map<String, dynamic>> lawCategories;
  final List<dynamic> lawyers;
  final List<dynamic> newLawyers;
  final bool isGuest;
  final bool isLoadingLawyers;
  final String? lawyerLoadError;
  final VoidCallback? onAppointmentClosed;

  const HomeUserSection(
      {super.key,
      required this.cases,
      required this.lawCategories,
      required this.lawyers,
      required this.newLawyers,
      this.isGuest = false,
      this.isLoadingLawyers = false,
      this.lawyerLoadError,
      this.onAppointmentClosed});

  void _guardedNavigate(BuildContext context, Widget page) {
    if (isGuest) {
      Navigator.push(
          context, MaterialPageRoute(builder: (_) => LoginPage(isBack: true)));
    } else {
      Navigator.push(context, MaterialPageRoute(builder: (_) => page));
    }
  }

  void _openPage(BuildContext context, Widget page) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => page));
  }

  Widget _buildLawyersForYouSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader(
          context,
          title: 'lawyersForYou'.tr(),
          onMore: () => _openPage(context, LawyerOnlineList()),
        ),
        if (isLoadingLawyers)
          _loadingState()
        else if ((lawyerLoadError ?? '').isNotEmpty)
          _emptyState(lawyerLoadError!)
        else if (lawyers.isNotEmpty)
          _buildLawyerList(context, lawyers, publicAccess: true)
        else
          _emptyState('noLawyers'.tr()),
        // const SizedBox(height: 20),
      ],
    );
  }

  void _showRejectedCase(BuildContext context, Map model) {
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
                color: _kPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Case Status (แสดงเฉพาะเมื่อ login แล้ว) ───────────────
        if (!isGuest) ...[
          _sectionHeader(context,
              title: 'caseStatus'.tr(),
              onMore: () => {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => CaseListPage(),
                      ),
                    ).then((_) {
                      // ✅ เมื่อ pop กลับมา เรียก callback
                      if (onAppointmentClosed != null) {
                        onAppointmentClosed!();
                        debugPrint('✅ Callback triggered after pop');
                      }
                    }),
                  }),
          if (cases.isNotEmpty)
            _buildCaseStatusList(context)
          else
            _emptyState('noCases'.tr()),
          const SizedBox(height: 20),
        ],
        // ── Law Categories ───────────────────────────────────────
        _sectionHeader(
          context,
          title: 'lawCategories'.tr(),
          onMore: () => _guardedNavigate(context, LawTypeAllPage()),
        ),
        const SizedBox(height: 8),
        _buildLawCategories(context),
        const SizedBox(height: 30),

        // ── หมอความสำหรับคุณ (guest โชว์ก่อนหมวดกฎหมาย) ─────────────
        if (isGuest) _buildLawyersForYouSection(context),

        // ── Lawyers For You (login แล้ว) ─────────────────────────
        if (!isGuest) _buildLawyersForYouSection(context),

        // ── New Lawyers ──────────────────────────────────────────
        _sectionHeader(
          context,
          title: 'trendingLawyers'.tr(),
          onMore: () => _guardedNavigate(context, LawyerOnlineList()),
        ),
        if (isLoadingLawyers)
          _loadingState()
        else if ((lawyerLoadError ?? '').isNotEmpty)
          _emptyState(lawyerLoadError!)
        else if (newLawyers.isNotEmpty)
          _buildLawyerList(context, newLawyers)
        else
          _emptyState('noTrendingLawyers'.tr()),
        const SizedBox(height: 20),
      ],
    );
  }

  // ── Section header with "ดูทั้งหมด" ──────────────────────────────
  Widget _sectionHeader(
    BuildContext context, {
    required String title,
    VoidCallback? onMore,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 0, 18, 6),
      child: Row(
        children: [
          Text(
            title,
            style: GoogleFonts.prompt(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: _kText,
            ),
          ),
          const Spacer(),
          if (onMore != null)
            GestureDetector(
              onTap: onMore,
              child: Text(
                'viewAll'.tr(),
                style: GoogleFonts.prompt(
                  fontSize: 12,
                  color: _kAccent,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ── Case Status List ──────────────────────────────────────────────
  Widget _buildCaseStatusList(BuildContext context) {
    return SizedBox(
      height: 146, // เพิ่ม 16px ให้ shadow ไม่โดน clip
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(
            18, 8, 18, 12), // top/bottom ให้ shadow หายใจได้
        itemCount: cases.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (_, i) => _caseStatusItem(context, cases[i]),
      ),
    );
  }

  Widget _emptyState(String message) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 18),
      child: Center(
        child: Text(
          message,
          style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
        ),
      ),
    );
  }

  Widget _loadingState() {
    return const AppLoadingInline(height: 72, size: 28);
  }

  Widget _caseStatusItem(BuildContext context, dynamic model) {
    final status = model['caseStatus'];
    final s = _statusStyle(status);
    final lawyerModel = model['lawyerModel'] as Map?;
    final lawyerName = lawyerModel?['name'] ?? '';
    final lawyerImage = lawyerModel?['imageUrl'] ?? '';
    final category = model['category'] ?? '';
    final statusText = model['statusText'] ?? '';

    // คำนวณความกว้างของการ์ดให้พอดีกับหน้าจอ
    final screenW = MediaQuery.of(context).size.width;
    final isDesktop = ResponsiveLayout.isDesktop(context);
    final isTablet = ResponsiveLayout.isTablet(context);

    // ความกว้างของกรอบเนื้อหา
    final actualContentW =
        isDesktop ? math.min(screenW, RV.maxContentWidth(context)) : screenW;

    double cardW;
    if (isDesktop || isTablet) {
      // Desktop/Tablet: แบ่ง 2 คอลัมน์ให้พอดีกรอบ
      cardW = (actualContentW - (18 * 2) - 12) / 2;
    } else {
      // Mobile: กว้าง 72% เพื่อให้เห็นว่าเลื่อนได้
      cardW = screenW * 0.72;
    }

    return GestureDetector(
      onTap: () {
        final jobStatus = model['jobStatus']?.toString();
        if (jobStatus == 'rejected') {
          _showRejectedCase(context, model);
          return;
        }
        final caseMap = model is Map<String, dynamic>
            ? model
            : Map<String, dynamic>.from(model as Map);
        // _guardedNavigate(
        //   context,
        //   AppointmentDetails(
        //     appointment: UserCaseAdapter.forAppointmentDetails(caseMap),
        //   ),

        // );
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AppointmentDetails(appointment: model),
          ),
        ).then((_) {
          // ✅ เมื่อ pop กลับมา เรียก callback
          if (onAppointmentClosed != null) {
            onAppointmentClosed!();
            debugPrint('✅ Callback triggered after pop');
          }
        });
      },
      child: Container(
        width: cardW,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: _kCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xFFD6D5D5),
            width: 1,
          ),
        ),
        child: Row(children: [
          Container(
            width: 4,
            height: double.infinity,
            decoration: BoxDecoration(
              color: s.color,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          // const SizedBox(width: 12),
          // ClipRRect(
          //   borderRadius: BorderRadius.circular(10),
          //   child: Image.network(lawyerImage,
          //       width: 48, height: 48, fit: BoxFit.cover),
          // ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(model['lawyerName'],
                    style: GoogleFonts.prompt(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: _kText,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Text(model['topicTitle'],
                    style: GoogleFonts.prompt(fontSize: 11, color: _kText),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Text(model['subTopicTitle'],
                    style: GoogleFonts.prompt(fontSize: 11, color: _kSub),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 6),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: s.bg,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(s.icon, size: 11, color: s.color),
                    const SizedBox(width: 4),
                    Text(
                        model['caseStatus'] == 1
                            ? 'รอทนายยืนยัน'
                            : model['caseStatus'] == 2
                                ? 'รอปรึกษาทนาย'
                                : model['caseStatus'] == 3
                                    ? 'กำลังปรึกาาทนายความ'
                                    : model['caseStatus'] == 4
                                        ? 'เสร็จสิ้น'
                                        : 'ยกเลิกเคสแล้ว',
                        style: GoogleFonts.prompt(
                          fontSize: 12,
                          color: s.color,
                          fontWeight: FontWeight.w600,
                        )),
                  ]),
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right_rounded,
              size: 18, color: Colors.grey.shade400),
        ]),
      ),
    );
  }

  // ── Law Categories ────────────────────────────────────────────────
  Widget _buildLawCategories(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: Row(
        children: lawCategories
            .map((cat) => Expanded(
                  child: _lawCategoryItem(
                    context,
                    title: cat['title']!,
                    icon: cat['icon']!,
                    onTap: () => _guardedNavigate(
                      context,
                      LawyerOnlineList(topic: cat['topic']),
                    ),
                  ),
                ))
            .toList(),
      ),
    );
  }

  Widget _lawCategoryItem(
    BuildContext context, {
    required String title,
    required String icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _kCard,
              shape: BoxShape.circle,
              border: Border.all(
                color: const Color(0xFFD6D5D5),
                width: 1,
              ),
            ),
            child: Image.asset(icon,
                height: 34, fit: BoxFit.contain, color: _kPrimary),
          ),
          const SizedBox(height: 8),
          Text(title,
              style: GoogleFonts.prompt(
                  fontSize: 10.5, color: _kText, height: 1.4),
              textAlign: TextAlign.center),
        ],
      ),
    );
  }

  // ── Lawyer Card List ──────────────────────────────────────────────
  Widget _buildLawyerList(
    BuildContext context,
    List<dynamic> list, {
    bool publicAccess = false,
  }) {
    return SizedBox(
      height: 226, // เพิ่ม 16px ให้ shadow ด้านล่างไม่โดน clip
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(
            18, 4, 18, 16), // bottom 16 = พื้นที่ shadow
        itemCount: list.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (_, i) => _lawyerCard(
          context,
          list[i],
          onTap: () {
            final page = LawyerOnlineDetails(code: list[i]['code']);
            if (publicAccess) {
              _openPage(context, page);
            } else {
              _guardedNavigate(context, page);
            }
          },
        ),
      ),
    );
  }

  Widget _lawyerCard(BuildContext context, Map model, {VoidCallback? onTap}) {
    final isFree = (model['cost'] ?? '') == 'Free';
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 148,
        decoration: BoxDecoration(
          color: _kCard,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: const Color(0xFFD6D5D5),
            width: 0.6,
          ),
        ),
        child: Column(
          children: [
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(18)),
              child: Stack(children: [
                _lawyerCardImage(model['imageUrl'] ?? ''),
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    height: 40,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.5)
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 6,
                  left: 8,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: isFree ? const Color(0xFF059669) : _kPrimary,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      isFree ? 'free'.tr() : '฿${model['cost']}',
                      style: GoogleFonts.prompt(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ]),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${model['firstName']} ${model['lastName']}',
                      style: GoogleFonts.prompt(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: _kText,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Row(children: [
                    const Icon(Icons.star_rounded, size: 13, color: _kGold),
                    const SizedBox(width: 3),
                    Text('${model['scroll'] ?? 0}',
                        style: GoogleFonts.prompt(
                          fontSize: 11,
                          color: _kText,
                          fontWeight: FontWeight.w600,
                        )),
                    const SizedBox(width: 6),
                    const Icon(Icons.work_outline_rounded,
                        size: 11, color: _kSub),
                    const SizedBox(width: 3),
                    Text(model['experience'] ?? '',
                        style: GoogleFonts.prompt(fontSize: 10, color: _kSub)),
                  ]),
                  const SizedBox(height: 6),
                  // for (var i = 0; i < model['expertiseData'].length < 3 ? 3; i++)
                  ListView.builder(
                    physics: ClampingScrollPhysics(),
                    padding: EdgeInsets.zero,
                    shrinkWrap: true,
                    itemCount: model['expertiseData'].length > 3
                        ? 3
                        : model['expertiseData'].length,
                    itemBuilder: (context, index) {
                      return Text(
                        model['expertiseData'][index]['title'],
                        style:
                            GoogleFonts.prompt(fontSize: 9.5, color: _kAccent),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      );
                    },
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Status style helper ──────────────────────────────────────────
class _StatusStyle {
  final Color color;
  final Color bg;
  final IconData icon;
  const _StatusStyle(this.color, this.bg, this.icon);
}

_StatusStyle _statusStyle(int status) {
  switch (status) {
    case 1:
      return _StatusStyle(const Color(0xFF0262EC), const Color(0xFFEBF2FF),
          Icons.pending_outlined);
    case 2:
      return _StatusStyle(const Color(0xFFD97706), const Color(0xFFFFF8EC),
          Icons.hourglass_top_rounded);
    case 3:
      return _StatusStyle(const Color(0xFF059669), const Color(0xFFECFDF5),
          Icons.chat_bubble_outline_rounded);
    case 4:
      return _StatusStyle(const Color(0xFF6B7A99), const Color(0xFFF4F6FB),
          Icons.check_circle_outline_rounded);
    case 0:
      return _StatusStyle(const Color(0xFFEF4444), const Color(0xFFFFF1F2),
          Icons.cancel_outlined);
    default:
      return _StatusStyle(const Color(0xFF6B7A99), const Color(0xFFF4F6FB),
          Icons.info_outline_rounded);
  }
}
