import 'dart:async';
import 'dart:ui';

import 'package:LawyerOnline/calendar.dart';
import 'package:LawyerOnline/case-status-all.dart';
import 'package:LawyerOnline/home.dart';
import 'package:LawyerOnline/login.dart';
import 'package:LawyerOnline/message.dart';
import 'package:LawyerOnline/post-list.dart';
import 'package:LawyerOnline/profile.dart';
import 'package:LawyerOnline/shared/responsive/res_layout.dart';
import 'package:LawyerOnline/shared/responsive/responsive_values.dart';
import 'package:LawyerOnline/widgets/navigation/desktop_top_nav.dart';
import 'package:LawyerOnline/widgets/notification_badge.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:LawyerOnline/models/user_profile_store.dart';
import 'package:LawyerOnline/models/lawyer/lawyer_profile_store.dart';
import 'package:LawyerOnline/services/lawyer_case_broadcast_service.dart';
import 'package:LawyerOnline/services/location_service.dart';
import 'package:LawyerOnline/services/webrtc_call_listener_service.dart';
import 'package:LawyerOnline/shared/notification_store.dart';
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

class _MenuPageState extends State<MenuPage> with SingleTickerProviderStateMixin {
  static const _tabSpring = SpringDescription(
    mass: 1,
    stiffness: 80,
    damping: 22,
  );

  late final AnimationController _tabAnimCtrl;
  Timer? _lawyerBroadcastDebounce;

  int _currentPage = 0;
  double _slideDirection = 1.0;
  DateTime? currentBackPressTime;

  String userType = '';
  String name = '';
  String imageUrl = '';
  String typeLogin = '';

  // ── Nav items config ───────────────────────────────────
  List<NavItem> get _navItems => [
        NavItem(icon: 'assets/icons/home.png', label: 'navHome'.tr(), index: 0),
        NavItem(
            icon: 'assets/icons/message.png',
            label: 'navChat'.tr(),
            index: 1,
            showBadge: true),
        NavItem(
            icon: 'assets/icons/logo-no-bg.png',
            label: 'navCommunity'.tr(),
            index: 2,
            isLogo: true,
            showBadge: true),
        NavItem(
            icon: 'assets/icons/appointment.png',
            label: 'navAppointment'.tr(),
            index: 3,
            showBadge: true),
        NavItem(
            icon: 'assets/icons/profile.png',
            label: 'navProfile'.tr(),
            index: 4),
      ];

  @override
  void initState() {
    super.initState();
    _tabAnimCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );
    _tabAnimCtrl.value = 1.0;

    callRead();
    Future.delayed(Duration.zero, requestPermissions);
    UserProfileStore.instance.addListener(_onStoreChanged);
    LawyerProfileStore.instance.addListener(_syncLawyerBroadcast);
    NotificationStore.instance.addListener(_onNotificationChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _syncLawyerBroadcast();
      WebRtcCallListenerService.instance.startGlobal();
    });
  }

  @override
  void dispose() {
    _tabAnimCtrl.dispose();
    _lawyerBroadcastDebounce?.cancel();
    UserProfileStore.instance.removeListener(_onStoreChanged);
    LawyerProfileStore.instance.removeListener(_syncLawyerBroadcast);
    NotificationStore.instance.removeListener(_onNotificationChanged);
    LawyerCaseBroadcastService.instance.stop();
    WebRtcCallListenerService.instance.stop();
    super.dispose();
  }

  void _syncUrgentLocationService() {
    if (UserProfileStore.instance.userType != 'lawyer') return;
    if (LawyerProfileStore.instance.isUrgentCaseEnabled) {
      LocationService.startPeriodicUpdate();
    } else {
      LocationService.stopPeriodicUpdate();
    }
  }

  void _syncLawyerBroadcast() {
    _lawyerBroadcastDebounce?.cancel();
    _lawyerBroadcastDebounce = Timer(const Duration(milliseconds: 400), () {
      LawyerCaseBroadcastService.instance.sync();
    });
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
    if (store.isLoggedIn) {
      NotificationStore.instance.refresh();
      WebRtcCallListenerService.instance.startGlobal();
    } else {
      NotificationStore.instance.clearUnread();
      WebRtcCallListenerService.instance.stop();
    }
  }

  void _onNotificationChanged() {
    if (mounted) setState(() {});
  }

  Future<void> requestPermissions() async {
    await Permission.camera.request();
    await Permission.microphone.request();
  }

  Future<void> callRead() async {
    await UserProfileStore.instance.load();
    if (UserProfileStore.instance.isLawyerApplyPending) {
      await UserProfileStore.instance.refreshFromApi();
    }
    if (UserProfileStore.instance.isLoggedIn) {
      await NotificationStore.instance.refresh();
    }
    await LawyerProfileStore.instance.load();
    if (UserProfileStore.instance.userType == 'lawyer' &&
        UserProfileStore.instance.isLoggedIn) {
      await UserProfileStore.instance.refreshFromApi();
      _syncUrgentLocationService();
    }

    final store = UserProfileStore.instance;
    setState(() {
      userType = widget.userType?.isNotEmpty == true
          ? widget.userType!
          : store.userType;
      name = store.name;
      imageUrl = store.imageUrl;
      typeLogin = store.typeLogin;
      _currentPage = widget.pageIndex ?? 0;
    });
    _syncLawyerBroadcast();
  }

  Widget _tabChild(int index) {
  switch (index) {
    case 0:
      return HomePage(
        key: const ValueKey(0),
        onProfileTap: () => _onNavTap(4),
        isTabActive: _currentPage == 0,
      );
    case 1:
      return typeLogin != 'null'
          ? MessagePage(
              key: const ValueKey(1),
              isTabActive: _currentPage == 1,
            )
          : LoginPage(
              key: const ValueKey(1),
              isBack: false,
            );
    case 2:
      return CommunityPage(key: const ValueKey(2),);
    case 3:
      if (typeLogin != 'null') {
        return userType == 'lawyer'
            ? CalendarPage(
                key: ValueKey('tab3_lawyer'),
                isTabActive: _currentPage == 3,
              )
            : CaseListPage(
                key: ValueKey('tab3_user'),
                isTabActive: _currentPage == 3,
              );
      }
      return LoginPage(
        key: const ValueKey(3),
        isBack: false,
      );
    case 4:
      return typeLogin != 'null'
          ? ProfilePage(key: const ValueKey(4),)
          : LoginPage(
              key: const ValueKey(4),
              isBack: false,
            );
    default:
      return HomePage(
        key: const ValueKey(0),
        onProfileTap: () => _onNavTap(4),
        isTabActive: _currentPage == 0,
      );
  }
}

  void _playTabTransition() {
    _tabAnimCtrl.stop();
    _tabAnimCtrl.value = 0;
    _tabAnimCtrl.animateWith(
      SpringSimulation(_tabSpring, 0, 1, 0),
    );
  }

  Widget _buildAnimatedTabBody() {
    return AnimatedBuilder(
      animation: _tabAnimCtrl,
      builder: (context, child) {
        final t = _tabAnimCtrl.value.clamp(0.0, 1.0);
        final dx = _slideDirection * 5 * (1 - t);
        final dy = 1.5 * (1 - t);
        return Transform.translate(
          offset: Offset(dx, dy),
          child: child,
        );
      },
      child: RepaintBoundary(
        child: IndexedStack(
          index: _currentPage,
          sizing: StackFit.expand,
          children: List.generate(_navItems.length, (index) {
            return TickerMode(
              enabled: index == _currentPage,
              child: _tabChild(index),
            );
          }),
        ),
      ),
    );
  }

  void _onNavTap(int index) {
    if (index == _currentPage) return;
    _slideDirection = index > _currentPage ? 1.0 : -1.0;
    setState(() => _currentPage = index);
    _playTabTransition();
    if (UserProfileStore.instance.isLoggedIn) {
      NotificationStore.instance.refresh();
    }
  }

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
          child: _buildAnimatedTabBody(),
        ),
      ),

      // ── Mobile/Tablet BottomNav ────────────────────────
      bottomNavigationBar: isDesktop
          ? null
          : Padding(
              padding: const EdgeInsets.fromLTRB(15, 10, 15, 20),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(35),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    height: 75,
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
                          .map((item) => Expanded(
                                child: _BottomNavItem(
                                  item: item,
                                  isSelected: _currentPage == item.index,
                                  badgeCount: typeLogin != 'null'
                                      ? NotificationStore.instance
                                          .badgeCountForNavIndex(item.index)
                                      : 0,
                                  showBadgeSlot: item.showBadge,
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
  final bool showBadgeSlot;
  final int badgeCount;
  final VoidCallback onTap;

  const _BottomNavItem({
    required this.item,
    required this.isSelected,
    required this.showBadgeSlot,
    required this.badgeCount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Center(
        // ← ใส่ Center หุ้มเพื่อให้ AnimatedContainer อยู่กลาง
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutCubic,
          // ลบ width/height: double.infinity ออก ← ให้ขนาดพอดีกับเนื้อหา
          padding: item.isLogo
              ? const EdgeInsets.symmetric(horizontal: 8, vertical: 8)
              : const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? const Color(0xFFF8F9FD).withOpacity(0.9)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(30),
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
              if (showBadgeSlot)
                NotificationBadgeDot(
                  count: badgeCount,
                  size: 7,
                  top: -1,
                  right: -2,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
