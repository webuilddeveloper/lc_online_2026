import 'package:LawyerOnline/case-status-all.dart';
import 'package:LawyerOnline/consult/consult_status.dart';
import 'package:LawyerOnline/law_type_all_page.dart';
import 'package:LawyerOnline/lawyer-online-details.dart';
import 'package:LawyerOnline/lawyer-online-list.dart';
import 'package:LawyerOnline/menu.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:LawyerOnline/login.dart';
import 'package:easy_localization/easy_localization.dart';

// ─── Status helpers ───────────────────────────────────────────────
int _statusToStep(String status) => status == '4' ? 4 : 3;

dynamic _buildLawyerForConsult(Map? m) {
  if (m == null) return null;
  return {
    'name': m['name'] ?? '',
    'avatar': (m['name'] as String? ?? 'ท').characters.first,
    'title': (m['skills'] as List?)?.isNotEmpty == true
        ? (m['skills'] as List).first
        : m['experience'] ?? '',
    'rating': m['scroll'] ?? 0,
    'imageUrl': m['imageUrl'] ?? '',
  };
}

const _kPrimary = Color(0xFF0262EC);
const _kAccent = Color(0xFF2F80ED);
const _kGold = Color(0xFFF5A623);
const _kCard = Colors.white;
const _kText = Color(0xFF0D1B2A);
const _kSub = Color(0xFF6B7A99);

// ─── User Dashboard ───────────────────────────────────────────────
// รวม: case status list, law categories, lawyer online, new lawyers
// StatelessWidget → rebuild เฉพาะเมื่อ props เปลี่ยนเท่านั้น
class HomeUserSection extends StatelessWidget {
  final List<dynamic> cases;
  final List<Map<String, dynamic>> lawCategories;
  final List<dynamic> lawyers;
  final List<dynamic> newLawyers;
  final bool isGuest;

  const HomeUserSection({
    super.key,
    required this.cases,
    required this.lawCategories,
    required this.lawyers,
    required this.newLawyers,
    this.isGuest = false,
  });

  void _guardedNavigate(BuildContext context, Widget page) {
    if (isGuest) {
      Navigator.push(
          context, MaterialPageRoute(builder: (_) => LoginPage(isBack: true)));
    } else {
      Navigator.push(context, MaterialPageRoute(builder: (_) => page));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Case Status ──────────────────────────────────────────
        _sectionHeader(
          context,
          title: 'caseStatus'.tr(),
          onMore: () =>
              _guardedNavigate(context, CaseStatusAllPage(caseList: cases)),
        ),
        if (cases.isNotEmpty)
          _buildCaseStatusList(context)
        else
          _emptyState('noCases'.tr()),
        const SizedBox(height: 20),

        // ── Law Categories ───────────────────────────────────────
        _sectionHeader(
          context,
          title: 'lawCategories'.tr(),
          onMore: () => _guardedNavigate(context, LawTypeAllPage()),
        ),
        const SizedBox(height: 8),
        _buildLawCategories(context),
        const SizedBox(height: 20),

        // ── Lawyers For You ──────────────────────────────────────
        _sectionHeader(
          context,
          title: 'lawyersForYou'.tr(),
          onMore: () => _guardedNavigate(context, LawyerOnlineList()),
        ),
        if (lawyers.isNotEmpty)
          _buildLawyerList(context, lawyers)
        else
          _emptyState('noLawyers'.tr()),
        const SizedBox(height: 20),

        // ── New Lawyers ──────────────────────────────────────────
        _sectionHeader(
          context,
          title: 'trendingLawyers'.tr(),
          onMore: () => _guardedNavigate(context, LawyerOnlineList()),
        ),
        if (newLawyers.isNotEmpty)
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
      height: 130,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(18, 15, 18, 15),
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

  Widget _caseStatusItem(BuildContext context, Map model) {
    final status = model['status']?.toString() ?? '1';
    final s = _statusStyle(status);
    final lawyerModel = model['lawyerModel'] as Map?;
    final lawyerName = lawyerModel?['name'] ?? '';
    final lawyerImage = lawyerModel?['imageUrl'] ?? '';
    final category = model['category'] ?? '';
    final statusText = model['statusText'] ?? '';

    return GestureDetector(
      onTap: () => _guardedNavigate(
        context,
        ConsultStatusPage(
          currentStep: _statusToStep(status),
          lawyer: _buildLawyerForConsult(lawyerModel),
          appointmentDate: model['appointmentDate'],
          appointmentTime: model['appointmentTime'],
        ),
      ),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.72,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: _kCard,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.07),
              blurRadius: 12,
              offset: const Offset(0, 3),
            )
          ],
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
          const SizedBox(width: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.asset(lawyerImage,
                width: 48, height: 48, fit: BoxFit.cover),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(lawyerName,
                    style: GoogleFonts.prompt(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: _kText,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Text(category,
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
                    Text(statusText,
                        style: GoogleFonts.prompt(
                          fontSize: 10,
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
              boxShadow: [
                BoxShadow(
                  color: _kAccent.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                )
              ],
              border: Border.all(color: const Color(0xFFE2EAF8)),
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
  Widget _buildLawyerList(BuildContext context, List<dynamic> list) {
    return SizedBox(
      height: 210,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(18, 4, 18, 15),
        itemCount: list.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (_, i) => _lawyerCard(
          context,
          list[i],
          onTap: () => _guardedNavigate(
              context, LawyerOnlineDetails(code: list[i]['code'])),
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
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 14,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Column(
          children: [
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(18)),
              child: Stack(children: [
                Image.asset(model['imageUrl'] ?? '',
                    height: 100, width: double.infinity, fit: BoxFit.cover),
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
                      isFree
                          ? 'free'.tr()
                          : '฿${model['cost']}${model['costUnit']}',
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
                  Text(model['name'] ?? '',
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
                  Text(
                    (model['skills'] as List?)?.isNotEmpty == true
                        ? (model['skills'] as List).first
                        : '',
                    style: GoogleFonts.prompt(fontSize: 9.5, color: _kAccent),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
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

// ─── Status style helper ──────────────────────────────────────────
class _StatusStyle {
  final Color color;
  final Color bg;
  final IconData icon;
  const _StatusStyle(this.color, this.bg, this.icon);
}

_StatusStyle _statusStyle(String status) {
  switch (status) {
    case '1':
      return _StatusStyle(const Color(0xFF0262EC), const Color(0xFFEBF2FF),
          Icons.pending_outlined);
    case '2':
      return _StatusStyle(const Color(0xFFD97706), const Color(0xFFFFF8EC),
          Icons.hourglass_top_rounded);
    case '3':
      return _StatusStyle(const Color(0xFF059669), const Color(0xFFECFDF5),
          Icons.chat_bubble_outline_rounded);
    case '4':
      return _StatusStyle(const Color(0xFF6B7A99), const Color(0xFFF4F6FB),
          Icons.check_circle_outline_rounded);
    default:
      return _StatusStyle(const Color(0xFF6B7A99), const Color(0xFFF4F6FB),
          Icons.info_outline_rounded);
  }
}
