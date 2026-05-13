import 'dart:ui';
import 'package:LawyerOnline/calendar.dart';
import 'package:LawyerOnline/home.dart';
import 'package:LawyerOnline/lawyer-online-list.dart';
import 'package:LawyerOnline/login.dart';
import 'package:LawyerOnline/message.dart';
import 'package:LawyerOnline/my-appointment.dart';
import 'package:LawyerOnline/post-list.dart';
import 'package:LawyerOnline/profile.dart';
import 'package:LawyerOnline/shared/responsive/res_layout.dart';
import 'package:LawyerOnline/shared/responsive/responsive_values.dart';
import 'package:LawyerOnline/widgets/navigation/desktop_top_nav.dart';
import 'package:flutter/material.dart';
import 'package:LawyerOnline/models/user_profile_store.dart';
import 'package:LawyerOnline/models/lawyer/lawyer_profile_store.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:permission_handler/permission_handler.dart';

// ══════════════════════════════════════════════════════════
//  MenuPage — Navigation shell
//  Mobile/Tablet → FloatingBottomNav (glass effect)
//  Desktop       → TopNav bar (ตามดีไซน์)
// ══════════════════════════════════════════════════════════

class MenuPage extends StatefulWidget {
  const MenuPage({Key? key, this.pageIndex, this.modelprofile, this.userType})
      : super(key: key);

  final int? pageIndex;
  final dynamic modelprofile;
  final String? userType;

  @override
  State<MenuPage> createState() => _MenuPageState();
}

class _MenuPageState extends State<MenuPage> {
  List<Widget> pages = [];
  int _currentPage = 0;
  DateTime? currentBackPressTime;

  String userType = '';
  String name = '';
  String imageUrl = '';
  String typeLogin = '';

  // ── Nav items config ───────────────────────────────────
  final List<NavItem> _navItems = const [
    NavItem(icon: 'assets/icons/home.png', label: 'หน้าหลัก', index: 0),
    NavItem(
        icon: 'assets/icons/message.png',
        label: 'แชท',
        index: 1,
        showBadge: true),
    NavItem(
        icon: 'assets/icons/logo-no-bg.png',
        label: 'ชุมชน',
        index: 2,
        isLogo: true,
        showBadge: true),
    NavItem(
        icon: 'assets/icons/appointment.png',
        label: 'นัดหมาย',
        index: 3,
        showBadge: true),
    NavItem(icon: 'assets/icons/profile.png', label: 'โปรไฟล์', index: 4),
  ];

  @override
  void initState() {
    super.initState();
    callRead();
    Future.delayed(Duration.zero, requestPermissions);
    // listen store — rebuild ทันทีเมื่อ profile เปลี่ยน (เช่น หลัง updateProfile)
    UserProfileStore.instance.addListener(_onStoreChanged);
  }

  @override
  void dispose() {
    UserProfileStore.instance.removeListener(_onStoreChanged);
    super.dispose();
  }

  void _onStoreChanged() {
    if (!mounted) return;
    final store = UserProfileStore.instance;
    setState(() {
      name = store.name;
      imageUrl = store.imageUrl;
      typeLogin = store.typeLogin;
      userType = store.userType.isNotEmpty ? store.userType : userType;
    });
  }

  Future<void> requestPermissions() async {
    await Permission.camera.request();
    await Permission.microphone.request();
  }

  Future<void> callRead() async {
    await UserProfileStore.instance.load();
    await LawyerProfileStore.instance.load();

    final store = UserProfileStore.instance;
    setState(() {
      userType = widget.userType?.isNotEmpty == true
          ? widget.userType!
          : store.userType;
      name = store.name;
      imageUrl = store.imageUrl;
      typeLogin = store.typeLogin;

      pages = [
        HomePage(onProfileTap: () => _onNavTap(4)),
        typeLogin != 'null' ? MessagePage() : LoginPage(isBack: false),
        CommunityPage(),
        typeLogin != 'null'
            ? userType == 'user'
                ? AppointmentListPage()
                : CalendarPage()
            : LoginPage(isBack: false),
        typeLogin != 'null' ? ProfilePage() : LoginPage(isBack: false),
      ];
      _currentPage = widget.pageIndex ?? 0;
    });
  }

  void _onNavTap(int index) => setState(() => _currentPage = index);

  Future<bool> confirmExit() {
    final now = DateTime.now();
    if (currentBackPressTime == null ||
        now.difference(currentBackPressTime!) > const Duration(seconds: 2)) {
      currentBackPressTime = now;
      Fluttertoast.showToast(msg: 'กดอีกครั้งเพื่อออก');
      return Future.value(false);
    }
    return Future.value(true);
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = ResponsiveLayout.isDesktop(context);

    return Scaffold(
      extendBody: !isDesktop,
      extendBodyBehindAppBar: false,
      backgroundColor: Colors.transparent,

      // ── Desktop TopNav ─────────────────────────────────
      appBar: isDesktop
          ? PreferredSize(
              preferredSize: Size.fromHeight(RV.appBarHeight(context)),
              child: DesktopTopNav(
                currentIndex: _currentPage,
                onTap: _onNavTap,
                navItems: _navItems,
                name: name,
                imageUrl: imageUrl,
                userType: userType,
                typeLogin: typeLogin,
              ),
            )
          : null,

      // ── Body ───────────────────────────────────────────
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: WillPopScope(
          onWillPop: confirmExit,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            transitionBuilder: (child, animation) => FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.02),
                  end: Offset.zero,
                ).animate(CurvedAnimation(
                  parent: animation,
                  curve: Curves.easeOutCubic,
                )),
                child: child,
              ),
            ),
            child: KeyedSubtree(
              key: ValueKey<int>(_currentPage),
              child: pages.isNotEmpty ? pages[_currentPage] : const SizedBox(),
            ),
          ),
        ),
      ),

      // ── Mobile/Tablet BottomNav ────────────────────────
      bottomNavigationBar: isDesktop
          ? null
          : Padding(
              padding: const EdgeInsets.all(15),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(30),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    height: 65,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF010101).withOpacity(0.50),
                      borderRadius: BorderRadius.circular(67),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.2),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: _navItems
                          .map((item) => Flexible(
                                child: _BottomNavItem(
                                  item: item,
                                  isSelected: _currentPage == item.index,
                                  showBadge:
                                      item.showBadge && typeLogin != 'null',
                                  onTap: () => _onNavTap(item.index),
                                ),
                              ))
                          .toList(),
                    ),
                  ),
                ),
              ),
            ),
    );
  }
}

// ── Mobile/Tablet bottom nav item ────────────────────────
class _BottomNavItem extends StatelessWidget {
  final NavItem item;
  final bool isSelected;
  final bool showBadge;
  final VoidCallback onTap;

  const _BottomNavItem({
    required this.item,
    required this.isSelected,
    required this.showBadge,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        padding: item.isLogo
            ? const EdgeInsets.symmetric(horizontal: 14, vertical: 5)
            : const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFFF8F9FD).withOpacity(0.9)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? const Color(0xFF085DD3).withOpacity(0.3)
                  : Colors.transparent,
              blurRadius: 12,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Image.asset(
              item.icon,
              width: item.isLogo ? 34 : 22,
              height: item.isLogo ? 34 : 22,
              color: isSelected ? const Color(0xFF085DD3) : Colors.white70,
            ),
            if (showBadge)
              Positioned(
                top: -1,
                right: 2,
                child: Container(
                  width: 7,
                  height: 7,
                  decoration: const BoxDecoration(
                    color: Color(0xFFF70C0C),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
