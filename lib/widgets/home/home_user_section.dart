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
import 'package:LawyerOnline/widgets/home/home_theme.dart';
import 'package:LawyerOnline/shared/api_provider.dart';

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
  static Future<List<Map<String, dynamic>>>? _lawCategoriesApiFuture;

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

  /// หน้าแรกแสดง 4 หมวด เริ่มจากรายการที่ 2 (index 1)
  static List<Map<String, dynamic>> _homeLawCategoryItems(
    List<Map<String, dynamic>> source,
  ) {
    if (source.isEmpty) return const [];
    const showCount = 4;
    final start = source.length > 1 ? 1 : 0;
    final result = <Map<String, dynamic>>[];
    for (var i = 0; i < showCount; i++) {
      if (source.length == 1) {
        result.add(source[0]);
        break;
      }
      result.add(source[(start + i) % source.length]);
    }
    return result;
  }

  static String _caseField(Map<String, dynamic> data, List<String> keys) {
    for (final key in keys) {
      final value = data[key]?.toString().trim() ?? '';
      if (value.isNotEmpty && value != '-') return value;
    }
    return '';
  }

  static Map<String, dynamic> _normalizeCasePreview(dynamic model) {
    final raw = model is Map<String, dynamic>
        ? Map<String, dynamic>.from(model)
        : Map<String, dynamic>.from(model as Map);
    final data = UserCaseAdapter.forAppointmentDetails(raw);

    var topic = _caseField(data, const [
      'topicTitle',
      'topic',
      'category',
      'caseTypeTitle',
    ]);
    final subTopic = _caseField(data, const [
      'subTopicTitle',
      'subTopic',
      'subCaseType',
    ]);
    final caseDate = _caseField(data, const [
      'caseDate',
      'appointmentDate',
      'case_date',
      'date',
    ]);
    final startTime = _caseField(data, const ['startTime', 'start_time']);
    final endTime = _caseField(data, const ['endTime', 'end_time']);
    var timeRange = _caseField(data, const ['appointmentTime']);
    if (timeRange.isEmpty && (startTime.isNotEmpty || endTime.isNotEmpty)) {
      timeRange = '$startTime - $endTime'.replaceAll(RegExp(r'\s*-\s*$'), '');
    }
    final details = _caseField(data, const [
      'story',
      'details',
      'requirement',
      'detail',
    ]);
    if (topic.isEmpty && details.isNotEmpty) {
      topic = details.length > 48 ? '${details.substring(0, 48)}…' : details;
    }
    final code = _caseField(data, const ['code', 'id', '_id']);
    var lawyerName = _caseField(data, const ['lawyerName', 'name']);
    final status = data['caseStatus'];
    final s = status is int
        ? status
        : int.tryParse(status?.toString() ?? '') ?? -1;
    if (lawyerName.isEmpty) {
      lawyerName = s == 1 ? 'รอทนายยืนยัน' : 'ไม่ระบุ';
    }

    return {
      'topic': topic,
      'subTopic': subTopic,
      'caseDate': caseDate,
      'timeRange': timeRange,
      'code': code,
      'lawyerName': lawyerName,
    };
  }

  Widget _caseDetailChip(IconData icon, String text, Color color) {
    final label = text.trim();
    if (label.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, size: 11, color: color),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.prompt(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: _kText,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Future<List<Map<String, dynamic>>> _fetchLawCategoriesFromApi() async {
    try {
      final param = await postDio('$server/m/topic/read', {});
      final objectData = param is Map ? param['objectData'] : null;
      if (objectData is! List) return lawCategories;

      // ให้กลับมาอยู่รูปแบบเดียวกับเดิม (title/icon/topic)
      return objectData
          .whereType<Map>()
          .map((e) {
            final title = e['title']?.toString().trim() ?? '';
            final code = e['code']?.toString().trim() ?? '';
            final imageUrl = e['imageUrl']?.toString().trim() ?? '';
            if (title.isEmpty) return <String, dynamic>{};
            return <String, dynamic>{
              'title': title,
              'icon': imageUrl,
              // ใช้ code ถ้ามี เพื่อให้หน้าจองจับคู่ topic ได้ชัวร์
              'topic': code.isNotEmpty ? code : title,
              'topicTitle': title,
            };
          })
          .where((m) => (m['title']?.toString().trim() ?? '').isNotEmpty)
          .toList(growable: false);
    } catch (_) {
      return lawCategories;
    }
  }

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
        HomeSectionHeader(
          title: 'lawyersForYou'.tr(),
          icon: Icons.person_search_rounded,
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
        // ── Case Status (แสดงเมื่อ login แล้ว และมีนัดหมาย/เคสด่วน) ─
        if (!isGuest && cases.isNotEmpty) ...[
          HomeSectionHeader(
            title: 'caseStatus'.tr(),
            icon: Icons.folder_open_rounded,
            onMore: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => CaseListPage(),
                ),
              ).then((_) {
                if (onAppointmentClosed != null) {
                  onAppointmentClosed!();
                  debugPrint('✅ Callback triggered after pop');
                }
              });
            },
          ),
          _buildCaseStatusList(context),
          const SizedBox(height: 20),
        ],
        // ── Law Categories ───────────────────────────────────────
        HomeSectionHeader(
          title: 'lawCategories'.tr(),
          icon: Icons.category_rounded,
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
        HomeSectionHeader(
          title: 'trendingLawyers'.tr(),
          icon: Icons.local_fire_department_rounded,
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

  // ── Case Status List ──────────────────────────────────────────────
  Widget _buildCaseStatusList(BuildContext context) {
    return SizedBox(
      height: 220,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(18, 8, 18, 12),
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

  bool _isUrgentCase(dynamic model) {
    final value = model is Map
        ? (model['caseType'] ??
            model['CaseType'] ??
            model['case_type'] ??
            model['type'])
        : null;
    if (value == 2 || value == '2' || value == 2.0) return true;
    if (value == 1 || value == '1' || value == 1.0) return false;
    if (value is num) return value.toInt() == 2;
    final text = value?.toString().trim().toLowerCase() ?? '';
    if (text == '2' ||
        text == 'urgent' ||
        text.contains('ด่วน') ||
        text == 'broadcast') {
      return true;
    }
    return false;
  }

  String _statusLabel(dynamic status) {
    final s = status is int
        ? status
        : int.tryParse(status?.toString() ?? '') ?? -1;
    switch (s) {
      case 1:
        return 'รอทนายยืนยัน';
      case 2:
        return 'รอปรึกษาทนาย';
      case 3:
        return 'กำลังปรึกษาทนายความ';
      case 4:
        return 'เสร็จสิ้น';
      case 0:
        return 'ยกเลิกเคสแล้ว';
      default:
        return 'ไม่ทราบสถานะ';
    }
  }

  Widget _caseStatusItem(BuildContext context, dynamic model) {
    final status = model['caseStatus'];
    final s = _statusStyle(status);
    final isUrgent = _isUrgentCase(model);
    final typeColor =
        isUrgent ? const Color(0xFFDC2626) : const Color(0xFF0262EC);

    final screenW = MediaQuery.of(context).size.width;
    final isDesktop = ResponsiveLayout.isDesktop(context);
    final isTablet = ResponsiveLayout.isTablet(context);
    final actualContentW =
        isDesktop ? math.min(screenW, RV.maxContentWidth(context)) : screenW;

    final double cardW;
    if (isDesktop || isTablet) {
      cardW = (actualContentW - (18 * 2) - 12) / 2;
    } else {
      cardW = screenW * 0.78;
    }

    final preview = _normalizeCasePreview(model);
    final lawyerName = preview['lawyerName'] as String;
    final topic = preview['topic'] as String;
    final subTopic = preview['subTopic'] as String;
    final caseDate = preview['caseDate'] as String;
    final timeRange = preview['timeRange'] as String;
    final caseCode = preview['code'] as String;

    return GestureDetector(
      onTap: () {
        final jobStatus = model['jobStatus']?.toString();
        if (jobStatus == 'rejected') {
          _showRejectedCase(context, model);
          return;
        }
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AppointmentDetails(
              appointment: UserCaseAdapter.forAppointmentDetails(
                model is Map<String, dynamic>
                    ? Map<String, dynamic>.from(model)
                    : Map<String, dynamic>.from(model as Map),
              ),
            ),
          ),
        ).then((_) {
          if (onAppointmentClosed != null) {
            onAppointmentClosed!();
          }
        });
      },
      child: Container(
        width: cardW,
        decoration: HomeTheme.cardDecoration(
          radius: HomeTheme.radiusCardLg,
          color: _kCard,
          borderColor: typeColor.withValues(alpha: 0.22),
          shadowTint: typeColor,
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // แถบประเภทเต็มความกว้าง — มองเห็นทันที
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              color: typeColor,
              child: Row(
                children: [
                  Icon(
                    isUrgent
                        ? Icons.bolt_rounded
                        : Icons.event_available_rounded,
                    size: 14,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      isUrgent
                          ? 'caseTypeUrgent'.tr()
                          : 'caseTypeBooking'.tr(),
                      style: GoogleFonts.prompt(
                        fontSize: 12,
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          lawyerName,
                          style: GoogleFonts.prompt(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: _kText,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: s.bg,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(s.icon, size: 11, color: s.color),
                            const SizedBox(width: 4),
                            Text(
                              _statusLabel(status),
                              style: GoogleFonts.prompt(
                                fontSize: 10,
                                color: s.color,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (topic.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.label_outline_rounded,
                            size: 12, color: typeColor),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            topic,
                            style: GoogleFonts.prompt(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: _kText,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                  if (subTopic.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Padding(
                      padding: const EdgeInsets.only(left: 16),
                      child: Text(
                        subTopic,
                        style: GoogleFonts.prompt(fontSize: 10, color: _kSub),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                  if (!isUrgent && (caseDate.isNotEmpty || timeRange.isNotEmpty))
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Row(
                        children: [
                          if (caseDate.isNotEmpty)
                            Expanded(
                              child: _caseDetailChip(
                                Icons.calendar_today_rounded,
                                caseDate,
                                typeColor,
                              ),
                            ),
                          if (caseDate.isNotEmpty && timeRange.isNotEmpty)
                            const SizedBox(width: 6),
                          if (timeRange.isNotEmpty)
                            Expanded(
                              child: _caseDetailChip(
                                Icons.access_time_rounded,
                                timeRange,
                                typeColor,
                              ),
                            ),
                        ],
                      ),
                    ),
                  if (caseCode.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      '# $caseCode',
                      style: GoogleFonts.prompt(
                        fontSize: 10,
                        color: Colors.grey.shade400,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Law Categories ────────────────────────────────────────────────
  Widget _buildLawCategories(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _lawCategoriesApiFuture ??=
          _fetchLawCategoriesFromApi(),
      builder: (context, snapshot) {
        final apiData = snapshot.data;
        final source = (apiData != null && apiData.isNotEmpty)
            ? apiData
            : lawCategories;
        final items = _homeLawCategoryItems(source);

        return SizedBox(
          height: 112,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: items.asMap().entries.map((entry) {
                final i = entry.key;
                final v = entry.value;
              final title = v['title']?.toString() ?? '';
              final icon = v['icon']?.toString() ?? '';
              final topic = v['topic']?.toString() ?? title;
              final topicTitle = v['topicTitle']?.toString() ?? title;

              return Expanded(
                child: _lawCategoryItem(
                  context,
                  index: i,
                  title: title,
                  icon: icon,
                  onTap: () => _guardedNavigate(
                    context,
                    LawyerOnlineList(
                      topic: topicTitle.isNotEmpty ? topicTitle : topic,
                    ),
                  ),
                ),
              );
              }).toList(),
            ),
          ),
        );
      },
    );
  }

  Widget _lawCategoryItem(
    BuildContext context, {
    required int index,
    required String title,
    required String icon,
    required VoidCallback onTap,
  }) {
    final bg = HomeTheme.categoryTints[index % HomeTheme.categoryTints.length];
    final fg =
        HomeTheme.categoryIconColors[index % HomeTheme.categoryIconColors.length];

    final iconUrl = icon.trim();
    final fallbackIcon =
        'assets/icons/law-type-${(index % 4) + 1}.png';
    final isNetwork = iconUrl.startsWith('http');

    Widget buildIcon() {
      if (iconUrl.isEmpty) {
        return Image.asset(
          fallbackIcon,
          width: 36,
          height: 36,
          fit: BoxFit.contain,
          color: fg,
        );
      }
      if (isNetwork) {
        // รูปจาก API เป็นภาพสีจริง — อย่าใส่ color tint (จะกลายเป็นสีทึบ)
        return CachedNetworkImage(
          imageUrl: iconUrl,
          width: 40,
          height: 40,
          fit: BoxFit.cover,
          memCacheWidth: 120,
          placeholder: (_, __) => Center(
            child: SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: fg.withValues(alpha: 0.5),
              ),
            ),
          ),
          errorWidget: (_, __, ___) => Image.asset(
            fallbackIcon,
            width: 36,
            height: 36,
            fit: BoxFit.contain,
            color: fg,
          ),
        );
      }
      return Image.asset(
        iconUrl,
        width: 36,
        height: 36,
        fit: BoxFit.contain,
        color: fg,
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: HomeTheme.brCardMd,
          child: Container(
            decoration: HomeTheme.cardDecoration(
              radius: HomeTheme.radiusCardMd,
              color: bg,
              borderColor: fg.withValues(alpha: 0.15),
              shadowTint: fg,
              shadows: [
                BoxShadow(
                  color: fg.withValues(alpha: 0.08),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
              child: Column(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.75),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: buildIcon(),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: Text(
                      title.replaceAll('\n', ' '),
                      style: GoogleFonts.prompt(
                        fontSize: 10.5,
                        color: HomeTheme.ink,
                        fontWeight: FontWeight.w700,
                        height: 1.25,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
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
        decoration: HomeTheme.cardDecoration(
          radius: HomeTheme.radiusCardLg,
          color: _kCard,
          shadowTint: HomeTheme.primary,
        ),
        child: Column(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(HomeTheme.radiusCardLg),
              ),
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
