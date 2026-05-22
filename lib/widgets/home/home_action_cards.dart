import 'package:LawyerOnline/booking/topic-page.dart';
import 'package:LawyerOnline/consultation-schedule.dart';
import 'package:LawyerOnline/consult/consult.dart';
import 'package:LawyerOnline/lawyer-job-list.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:LawyerOnline/login.dart';

const _kCard = Colors.white;
const _kAccent = Color(0xFF2F80ED);

// ─── Action Cards ─────────────────────────────────────────────────
// StatelessWidget → rebuild เฉพาะเมื่อ props เปลี่ยน
// typeLogin == 'null' → ซ่อนทั้งหมด (guest)
// userType == 'user'  → เปิดเคส + นัดหมาย
// userType == 'lawyer'→ สวิตช์รับเคสด่วน + ดูงาน + ตั้งเวลา
class HomeActionCards extends StatelessWidget {
  final String typeLogin;
  final String userType;
  final bool isUrgentCaseEnabled;
  final ValueChanged<bool> onToggleUrgentCase;
  final bool isGuest;

  const HomeActionCards({
    super.key,
    required this.typeLogin,
    required this.userType,
    required this.isUrgentCaseEnabled,
    required this.onToggleUrgentCase,
    this.isGuest = false,
  });

  @override
  Widget build(BuildContext context) {
    final bool isGuest = typeLogin == 'null';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: isGuest || userType == 'user'
          ? _buildUserCards(context, isGuest: isGuest)
          : _buildLawyerCards(context),
    );
  }

  // ── User: เปิดเคส + นัดหมาย ───────────────────────────────────
  Widget _buildUserCards(BuildContext context, {bool isGuest = false}) {
    void go(Widget page) {
      if (isGuest) {
        Navigator.push(context,
            MaterialPageRoute(builder: (_) => LoginPage(isBack: true)));
      } else {
        Navigator.push(context, MaterialPageRoute(builder: (_) => page));
      }
    }

    return Row(children: [
      Expanded(
        child: _actionCard(
          title: 'เปิดเคส',
          subtitle: 'ให้ทนายรับงาน',
          iconAssets: 'assets/icons/open-case.png',
          gradientColors: [_kCard, _kCard],
          titleColor: const Color(0xFF1565C0),
          subTitleColor: const Color(0xFF1565C0),
          iconColor: const Color(0xFF1565C0),
          onTap: () => go(ConsultPage()),
        ),
      ),
      const SizedBox(width: 14),
      Expanded(
        child: _actionCard(
          title: 'นัดหมาย',
          subtitle: 'จองเวลาปรึกษา',
          iconAssets: 'assets/icons/appointment-lawyer.png',
          gradientColors: [
            const Color(0xFF1565C0),
            const Color(0xFF1E88E5),
          ],
          onTap: () => go(TopicPage()),
        ),
      ),
    ]);
  }

  // ── Lawyer: สวิตช์รับเคสด่วน + ดูงาน + ตั้งเวลา ───────────────
  Widget _buildLawyerCards(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── urgent switch + view jobs ─────────────────────────
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // สวิตช์รับเคสด่วน
              Expanded(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isUrgentCaseEnabled
                          ? const Color(0xFF059669)
                          : Colors.grey.shade300,
                      width: 1.5,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              'รับเคสด่วน',
                              style: GoogleFonts.prompt(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF0D1B2A),
                              ),
                            ),
                          ),
                          SizedBox(
                            height: 30,
                            child: Switch(
                              value: isUrgentCaseEnabled,
                              onChanged: onToggleUrgentCase,
                              activeColor: const Color(0xFF059669),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        isUrgentCaseEnabled
                            ? 'พร้อมให้คำปรึกษาเคสด่วน'
                            : 'ปิดรับเคสด่วน',
                        style: GoogleFonts.prompt(
                          fontSize: 12,
                          color: isUrgentCaseEnabled
                              ? const Color(0xFF059669)
                              : Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // ดูงานเคสด่วน
              Expanded(
                child: Opacity(
                  opacity: isUrgentCaseEnabled ? 1.0 : 0.4,
                  child: MouseRegion(
                    cursor: isUrgentCaseEnabled
                        ? SystemMouseCursors.click
                        : SystemMouseCursors.basic,
                    child: Material(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(16),
                      child: InkWell(
                        onTap: isUrgentCaseEnabled
                            ? () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) => LawyerJobListPage()),
                                )
                            : null,
                        borderRadius: BorderRadius.circular(16),
                        splashColor: Colors.white.withOpacity(0.15),
                        highlightColor: Colors.white.withOpacity(0.08),
                        child: Ink(
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [
                                Color(0xFF1565C0),
                                Color(0xFF2F80ED),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 12),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(Icons.work_rounded,
                                    color: Colors.white, size: 50),
                                const Spacer(),
                                const SizedBox(height: 8),
                                Text(
                                  'ดูงานเคสด่วน',
                                  style: GoogleFonts.prompt(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                Text(
                                  'ลูกความต้องการคำปรึกษาด่วน',
                                  style: GoogleFonts.prompt(
                                    fontSize: 11,
                                    color: Colors.white70,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 14),

        // ── ตั้งค่าวันและเวลา ────────────────────────────────────
        _actionCard(
          title: 'ตั้งค่าวันและเวลาที่สามารถนัดปรึกษาได้',
          subtitle: 'กำหนดวันและเวลาที่สามารถจองขอคำปรึกษาได้',
          icon: Icons.date_range_rounded,
          gradientColors: [_kCard, _kCard],
          titleColor: const Color(0xFF1565C0),
          subTitleColor: const Color(0xFF1565C0),
          iconColor: const Color(0xFF1565C0),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => ConsultationSchedule()),
          ),
        ),
      ],
    );
  }
}

// ─── Action Card base widget ──────────────────────────────────────
Widget _actionCard({
  required String title,
  required String subtitle,
  IconData? icon,
  String iconAssets = '',
  Color? titleColor = Colors.white,
  Color? subTitleColor = Colors.white,
  Color? iconColor = Colors.white,
  required List<Color> gradientColors,
  required VoidCallback onTap,
}) {
  return MouseRegion(
    cursor: SystemMouseCursors.click,
    child: Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        splashColor: Colors.white.withOpacity(0.15),
        highlightColor: Colors.white.withOpacity(0.08),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: gradientColors,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: _kAccent.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 2),
              )
            ],
            border: Border.all(color: const Color(0xFFE2EAF8)),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 18),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: icon != null
                      ? Icon(icon, color: iconColor, size: 40)
                      : Image.asset(
                          iconAssets,
                          width: 18,
                          height: 18,
                          color: iconColor,
                        ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.prompt(
                        color: titleColor,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: GoogleFonts.prompt(
                        color: subTitleColor,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
