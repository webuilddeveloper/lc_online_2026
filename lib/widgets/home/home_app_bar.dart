import 'package:LawyerOnline/login.dart';
import 'package:LawyerOnline/notification.dart';
import 'package:LawyerOnline/models/lawyer/lawyer_profile_store.dart';
import 'package:LawyerOnline/models/user_profile_store.dart';
import 'package:LawyerOnline/widgets/profile/profile_avatar.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:easy_localization/easy_localization.dart';

// ─── Home SliverAppBar ────────────────────────────────────────────
// รับ props ทั้งหมด ไม่มี state ของตัวเอง
// → rebuild เฉพาะเมื่อ name / imageUrl / userType / isUrgentCaseEnabled เปลี่ยน
class HomeAppBar extends StatefulWidget {
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
  State<HomeAppBar> createState() => _HomeAppBarState();
}

class _HomeAppBarState extends State<HomeAppBar> {
  @override
  void initState() {
    super.initState();
    LawyerProfileStore.instance.addListener(_onStoreChanged);
    UserProfileStore.instance.addListener(_onStoreChanged); // ← listen profile store
  }

  @override
  void dispose() {
    LawyerProfileStore.instance.removeListener(_onStoreChanged);
    UserProfileStore.instance.removeListener(_onStoreChanged); // ← cleanup
    super.dispose();
  }

  void _onStoreChanged() {
    if (mounted) setState(() {});
  }

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
                    ProfileAvatar(
                      imageUrl: UserProfileStore.instance.imageUrl,
                      typeLogin: UserProfileStore.instance.typeLogin,
                      isOnline: UserProfileStore.instance.userType == 'lawyer' && widget.isUrgentCaseEnabled,
                      onProfileTap: widget.onProfileTap,
                    ),
                    const SizedBox(width: 12),
                    // ── ชื่อ + badge (เฉพาะ logged in) ──────────
                    Expanded(
                      child: UserProfileStore.instance.typeLogin != 'null'
                          ? Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  UserProfileStore.instance.name.isNotEmpty
                                      ? UserProfileStore.instance.name
                                      : 'defaultUser'.tr(),
                                  style: GoogleFonts.prompt(
                                    color: Colors.black,
                                    fontSize: 17,
                                    fontWeight: FontWeight.w700,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                ProfileMemberBadge(
                                  userType: UserProfileStore.instance.userType,
                                  isPro: LawyerProfileStore.instance.isPro && UserProfileStore.instance.userType == 'lawyer',
                                ),
                              ],
                            )
                          : const SizedBox.shrink(),
                    ),

                    // ── ปุ่มขวาสุด: bell (login) | ปุ่มเข้าสู่ระบบ (guest) ──
                    if (UserProfileStore.instance.typeLogin != 'null')
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
                                  'login'.tr(),
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