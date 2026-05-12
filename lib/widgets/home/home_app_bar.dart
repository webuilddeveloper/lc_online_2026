import 'package:LawyerOnline/login.dart';
import 'package:LawyerOnline/notification.dart';
import 'package:LawyerOnline/page_exam.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

const _kPrimary = Color(0xFF0262EC);
const _kGold = Color(0xFFF5A623);

// ─── Home SliverAppBar ────────────────────────────────────────────
// รับ props ทั้งหมด ไม่มี state ของตัวเอง
// → rebuild เฉพาะเมื่อ name / imageUrl / userType / isUrgentCaseEnabled เปลี่ยน
class HomeAppBar extends StatelessWidget {
  final String name;
  final String imageUrl;
  final String userType;
  final String typeLogin;
  final bool isUrgentCaseEnabled;
  final VoidCallback? onProfileTap;

  const HomeAppBar({
    super.key,
    required this.name,
    required this.imageUrl,
    required this.userType,
    required this.typeLogin,
    required this.isUrgentCaseEnabled,
    this.onProfileTap,
  });

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      pinned: true,
      floating: false,
      snap: false,
      expandedHeight: 100,
      collapsedHeight: 100,
      toolbarHeight: 10,
      backgroundColor: const Color.fromARGB(255, 233, 242, 249),
      surfaceTintColor: Colors.transparent,
      shadowColor: Colors.black.withOpacity(0.7),
      elevation: 0,
      scrolledUnderElevation: 6,
      automaticallyImplyLeading: false,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      flexibleSpace: FlexibleSpaceBar(
        collapseMode: CollapseMode.pin,
        background: Stack(
          fit: StackFit.expand,
          children: [
            // ── watermark icons ──────────────────────────────────
            Positioned(
              right: 20,
              bottom: 0,
              child: Icon(
                Icons.gavel_rounded,
                color: const Color(0xFF1565C0).withOpacity(0.06),
                size: 100,
              ),
            ),
            Positioned(
              left: 5,
              bottom: -20,
              child: Icon(
                Icons.balance,
                color: const Color(0xFF1565C0).withOpacity(0.06),
                size: 150,
              ),
            ),
            // ── content ──────────────────────────────────────────
            SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    _HomeAvatar(
                      imageUrl: imageUrl,
                      typeLogin: typeLogin,
                      userType: userType,
                      isUrgentCaseEnabled: isUrgentCaseEnabled,
                      onProfileTap: onProfileTap,
                    ),
                    const SizedBox(width: 12),
                    // ── ชื่อ + badge (เฉพาะ logged in) ──────────
                    Expanded(
                      child: typeLogin != 'null'
                          ? Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  name.isNotEmpty ? name : 'ผู้ใช้งาน',
                                  style: GoogleFonts.prompt(
                                    color: Colors.black,
                                    fontSize: 17,
                                    fontWeight: FontWeight.w700,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                _HomeMemberBadge(userType: userType),
                              ],
                            )
                          : const SizedBox.shrink(),
                    ),

                    // ── ปุ่มขวาสุด: bell (login) | ปุ่มเข้าสู่ระบบ (guest) ──
                    if (typeLogin != 'null')
                      // ── Bell ───────────────────────────────────
                      MouseRegion(
                        cursor: SystemMouseCursors.click,
                        child: Material(
                          color: Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                          child: InkWell(
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => NotificationPage()),
                            ),
                            borderRadius: BorderRadius.circular(12),
                            splashColor:
                                const Color(0xFF1565C0).withOpacity(0.15),
                            highlightColor:
                                const Color(0xFF1565C0).withOpacity(0.08),
                            child: Ink(
                              width: 42,
                              height: 42,
                              decoration: BoxDecoration(
                                color: const Color(0xFF1565C0).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color:
                                      const Color(0xFF1565C0).withOpacity(0.2),
                                ),
                              ),
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  Image.asset(
                                    'assets/icons/bell-2.png',
                                    width: 25,
                                    height: 25,
                                    color: const Color(0xFF1565C0),
                                  ),
                                  Positioned(
                                    top: 8,
                                    right: 9,
                                    child: Container(
                                      width: 9,
                                      height: 9,
                                      decoration: const BoxDecoration(
                                        color: Color.fromARGB(255, 247, 12, 12),
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      )
                    else
                      // ── ปุ่มเข้าสู่ระบบ (guest) ────────────────
                      MouseRegion(
                        cursor: SystemMouseCursors.click,
                        child: Material(
                          color: Colors.transparent,
                          borderRadius: BorderRadius.circular(18),
                          child: InkWell(
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => LoginPage(isBack: true),
                              ),
                            ),
                            borderRadius: BorderRadius.circular(18),
                            splashColor: Colors.white.withOpacity(0.2),
                            highlightColor: Colors.white.withOpacity(0.1),
                            child: Ink(
                              decoration: BoxDecoration(
                                color: const Color(0xFF0262EC),
                                borderRadius: BorderRadius.circular(18),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF0262EC)
                                        .withOpacity(0.35),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                    vertical: 10, horizontal: 20),
                                child: Text(
                                  'เข้าสู่ระบบ',
                                  style: GoogleFonts.prompt(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
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
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Avatar ───────────────────────────────────────────────────────
class _HomeAvatar extends StatelessWidget {
  final String imageUrl;
  final String typeLogin;
  final String userType;
  final bool isUrgentCaseEnabled;
  final VoidCallback? onProfileTap;

  const _HomeAvatar({
    required this.imageUrl,
    required this.typeLogin,
    required this.userType,
    required this.isUrgentCaseEnabled,
    this.onProfileTap,
  });

  @override
  Widget build(BuildContext context) {
    final isOnline = userType == 'lawyer' && isUrgentCaseEnabled;

    return MouseRegion(
      cursor: onProfileTap != null
          ? SystemMouseCursors.click
          : SystemMouseCursors.basic,
      child: GestureDetector(
        onTap: onProfileTap,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isOnline
                          ? const Color(0xFF059669)
                          : _kPrimary.withOpacity(1),
                      width: isOnline ? 2.5 : 1,
                    ),
                    boxShadow: isOnline
                        ? [
                            BoxShadow(
                              color: const Color(0xFF059669).withOpacity(0.4),
                              blurRadius: 6,
                              spreadRadius: 1,
                            )
                          ]
                        : [],
                  ),
                  child: Center(
                    child: SizedBox(
                      width: 42,
                      height: 42,
                      child: ClipOval(
                        child: imageUrl.isNotEmpty
                            ? typeLogin == 'social'
                                ? Image.network(imageUrl, fit: BoxFit.cover)
                                : Image.asset(imageUrl, fit: BoxFit.cover)
                            : Padding(
                                padding: const EdgeInsets.all(3.0),
                                child: Image.asset('assets/icons/profile.png',
                                    fit: BoxFit.cover),
                              ),
                      ),
                    ),
                  ),
                ),
                // const SizedBox(
                //   width: 10,
                // ),
                // GestureDetector(
                //   onTap: () {
                //     // Navigator.push(
                //     //   context,
                //     //   MaterialPageRoute(
                //     //     builder: (_) => PageExam(),
                //     //   ),
                //     // );
                //     showLanguagePicker(context);
                //   },
                //   child: const Icon(
                //     Icons.visibility,
                //     size: 20,
                //   ),
                // ),

                // Image.asset('assets/icons/profile.png', fit: BoxFit.cover),
              ],
            ),
            if (isOnline)
              Positioned(
                bottom: -4,
                right: -4,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: const Color(0xFF059669),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 1.5),
                  ),
                  child: const Icon(
                    Icons.balance_rounded,
                    color: Colors.white,
                    size: 14,
                  ),
                ),
              ),
          ],
        ), // Stack
      ), // GestureDetector
    ); // MouseRegion
  }
}

// ─── Member Badge ─────────────────────────────────────────────────
class _HomeMemberBadge extends StatelessWidget {
  final String userType;
  const _HomeMemberBadge({required this.userType});

  @override
  Widget build(BuildContext context) {
    final label = userType == 'lawyer' ? 'หมอความ' : 'บุคคลทั่วไป';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _kGold),
      ),
      child: Text(
        label,
        style: GoogleFonts.prompt(
          color: _kGold,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

// ─── AppBar Overlay Painter ───────────────────────────────────────
class AppBarOverlayPainter extends CustomPainter {
  const AppBarOverlayPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final ringPaint = Paint()..style = PaintingStyle.stroke;
    final c = Offset(size.width * 0.90, size.height * 0.16);
    for (final r in [140.0, 100.0, 60.0]) {
      canvas.drawCircle(
          c,
          r,
          ringPaint
            ..color = Colors.white.withOpacity(0.09)
            ..strokeWidth = 0.8);
    }
    canvas.drawCircle(c, 24, Paint()..color = Colors.white.withOpacity(0.05));

    const gold = Color(0xFFF5A623);
    final cg = Offset(size.width * 0.10, size.height * 0.94);
    for (final r in [80.0, 46.0]) {
      canvas.drawCircle(
          cg,
          r,
          ringPaint
            ..color = gold.withOpacity(0.13)
            ..strokeWidth = 0.8);
    }
    canvas.drawCircle(cg, 18, Paint()..color = gold.withOpacity(0.06));

    final diagPaint = Paint()
      ..color = Colors.white.withOpacity(0.04)
      ..strokeWidth = 0.7;
    for (int i = 0; i < 6; i++) {
      canvas.drawLine(
        Offset(i * 80.0, size.height),
        Offset(i * 80.0 + size.height, 0),
        diagPaint,
      );
    }

    final hPaint = Paint()
      ..color = Colors.white.withOpacity(0.03)
      ..strokeWidth = 0.6;
    for (double y = 64; y < size.height; y += 64) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), hPaint);
    }

    final dotW = Paint()..color = Colors.white.withOpacity(0.13);
    for (int r = 0; r < 3; r++) {
      for (int col = 0; col < 4; col++) {
        canvas.drawCircle(Offset(44 + col * 16.0, 38 + r * 16.0), 1.8, dotW);
      }
    }

    final dotG = Paint()..color = gold.withOpacity(0.18);
    for (int r = 0; r < 2; r++) {
      for (int col = 0; col < 4; col++) {
        canvas.drawCircle(
          Offset(size.width - 92 + col * 16.0, size.height - 62 + r * 16.0),
          1.8,
          dotG,
        );
      }
    }

    canvas.drawLine(
      Offset(30, size.height - 24),
      Offset(200, size.height - 24),
      Paint()
        ..color = gold.withOpacity(0.22)
        ..strokeWidth = 0.8,
    );
    canvas.drawLine(
      Offset(30, size.height - 24),
      Offset(80, size.height - 24),
      Paint()
        ..color = gold.withOpacity(0.55)
        ..strokeWidth = 1.4,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}
