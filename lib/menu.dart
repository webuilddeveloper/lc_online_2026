import 'dart:async';
import 'dart:ui';

import 'package:LawyerOnline/services/home_refresh_service.dart';
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
//  Mobile/Tablet → Liquid Glass floating bottom bar
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
    // กดแท็บเดิมซ้ำ — refresh เฉพาะหน้าแรก (intentional pull-like)
    if (index == _currentPage) {
      if (index == 0) {
        HomeRefreshService.instance.requestRefresh();
      }
      return;
    }
    _slideDirection = index > _currentPage ? 1.0 : -1.0;
    setState(() => _currentPage = index);
    _playTabTransition();
    // สลับมาหน้าแรก: HomePage.didUpdateWidget จะ refresh เอง — ไม่ยิงซ้ำที่นี่
    if (UserProfileStore.instance.isLoggedIn) {
      NotificationStore.instance.refresh();
    }
  }

  Future<bool> confirmExit() {
    final now = DateTime.now();
    if (currentBackPressTime == null ||
        now.difference(currentBackPressTime!) > const Duration(seconds: 2)) {
      currentBackPressTime = now;
      Fluttertoast.showToast(msg: 'pressBackAgainToExit'.tr());
      return Future.value(false);
    }
    return Future.value(true);
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = ResponsiveLayout.isDesktop(context);
    final bottomInset = MediaQuery.paddingOf(context).bottom;

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

      // ── Mobile/Tablet BottomNav — Liquid Glass ──────────
      bottomNavigationBar: isDesktop
          ? null
          : _LiquidGlassBottomBar(
              items: _navItems,
              currentIndex: _currentPage,
              bottomInset: bottomInset,
              badgeCountFor: (index) => typeLogin != 'null'
                  ? NotificationStore.instance.badgeCountForNavIndex(index)
                  : 0,
              onTap: _onNavTap,
            ),
    );
  }
}

// ══════════════════════════════════════════════════════════
//  Liquid Glass Bottom Bar — iOS-inspired frosted capsule
// ══════════════════════════════════════════════════════════

class _LiquidGlassBottomBar extends StatelessWidget {
  static const _primary = Color(0xFF085DD3);
  static const _inkMuted = Color(0xFF64748B);
  static const _barHeight = 70.0;
  static const _radius = 35.0;

  // Soft saturation boost behind the frost — makes refracted colors pop.
  static final _glassBackdrop = ImageFilter.compose(
    outer: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
    inner: const ColorFilter.matrix(<double>[
      1.15, -0.05, -0.05, 0, 6,
      -0.05, 1.15, -0.05, 0, 6,
      -0.05, -0.05, 1.20, 0, 10,
      0, 0, 0, 1, 0,
    ]),
  );

  final List<NavItem> items;
  final int currentIndex;
  final double bottomInset;
  final int Function(int index) badgeCountFor;
  final ValueChanged<int> onTap;

  const _LiquidGlassBottomBar({
    required this.items,
    required this.currentIndex,
    required this.bottomInset,
    required this.badgeCountFor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const radius = _radius;
    const primary = _primary;

    return Padding(
      padding: EdgeInsets.fromLTRB(16, 8, 16, 10 + bottomInset),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(radius),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0F172A).withValues(alpha: 0.14),
              blurRadius: 36,
              offset: const Offset(0, 16),
              spreadRadius: -6,
            ),
            BoxShadow(
              color: primary.withValues(alpha: 0.12),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
            BoxShadow(
              color: Colors.white.withValues(alpha: 0.55),
              blurRadius: 8,
              offset: const Offset(0, -1),
              spreadRadius: -2,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(radius),
          child: BackdropFilter(
            filter: _glassBackdrop,
            child: SizedBox(
              height: _LiquidGlassBottomBar._barHeight,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Ultra-light frost — lets page colors bleed through
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.white.withValues(alpha: 0.42),
                          const Color(0xFFE8F1FF).withValues(alpha: 0.28),
                          const Color(0xFFD6E4FF).withValues(alpha: 0.22),
                          Colors.white.withValues(alpha: 0.34),
                        ],
                        stops: const [0.0, 0.35, 0.7, 1.0],
                      ),
                    ),
                  ),

                  // Iridescent color wash (เหลื่อมสี)
                  IgnorePointer(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: const Alignment(-1.2, -0.8),
                          end: const Alignment(1.2, 1.0),
                          colors: [
                            const Color(0xFF60A5FA).withValues(alpha: 0.18),
                            const Color(0xFFA78BFA).withValues(alpha: 0.10),
                            const Color(0xFF34D399).withValues(alpha: 0.08),
                            const Color(0xFF38BDF8).withValues(alpha: 0.14),
                          ],
                          stops: const [0.0, 0.35, 0.65, 1.0],
                        ),
                      ),
                    ),
                  ),

                  // Soft caustic blobs
                  IgnorePointer(
                    child: Stack(
                      children: [
                        Positioned(
                          left: -20,
                          top: -28,
                          child: _GlassBlob(
                            size: 90,
                            color: Colors.white.withValues(alpha: 0.55),
                          ),
                        ),
                        Positioned(
                          right: 40,
                          top: -18,
                          child: _GlassBlob(
                            size: 70,
                            color: const Color(0xFF93C5FD)
                                .withValues(alpha: 0.35),
                          ),
                        ),
                        Positioned(
                          right: -10,
                          bottom: -30,
                          child: _GlassBlob(
                            size: 80,
                            color: const Color(0xFFC4B5FD)
                                .withValues(alpha: 0.28),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Static diagonal gloss
                  IgnorePointer(
                    child: Transform.rotate(
                      angle: -0.55,
                      child: Align(
                        alignment: const Alignment(-0.35, 0),
                        child: Container(
                          width: 56,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                              colors: [
                                Colors.white.withValues(alpha: 0.0),
                                Colors.white.withValues(alpha: 0.22),
                                Colors.white.withValues(alpha: 0.0),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Top specular rim
                  const IgnorePointer(
                    child: Align(
                      alignment: Alignment.topCenter,
                      child: FractionallySizedBox(
                        heightFactor: 0.45,
                        widthFactor: 1,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Color(0xA6FFFFFF),
                                Color(0x33FFFFFF),
                                Color(0x00FFFFFF),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Bottom refraction edge
                  IgnorePointer(
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      child: FractionallySizedBox(
                        heightFactor: 0.28,
                        widthFactor: 1,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                              colors: [
                                primary.withValues(alpha: 0.10),
                                Colors.transparent,
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Glass edge (Fresnel)
                  DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(radius),
                      border: Border.all(
                        width: 1.4,
                        color: Colors.white.withValues(alpha: 0.72),
                      ),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.white.withValues(alpha: 0.35),
                          Colors.white.withValues(alpha: 0.05),
                          Colors.white.withValues(alpha: 0.22),
                        ],
                      ),
                      backgroundBlendMode: BlendMode.softLight,
                    ),
                  ),

                  // Inner rim
                  Padding(
                    padding: const EdgeInsets.all(1),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(radius - 1),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.35),
                          width: 0.6,
                        ),
                      ),
                    ),
                  ),

                  // Sliding liquid pill + items
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 6,
                    ),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final count = items.length;
                        final itemW = constraints.maxWidth / count;
                        final pillH = constraints.maxHeight;
                        return Stack(
                          children: [
                            AnimatedPositioned(
                              duration: const Duration(milliseconds: 420),
                              curve: Curves.easeOutCubic,
                              left: currentIndex * itemW + 2,
                              width: itemW - 4,
                              top: 0,
                              height: pillH,
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(26),
                                child: BackdropFilter(
                                  filter: ImageFilter.blur(
                                    sigmaX: 8,
                                    sigmaY: 8,
                                  ),
                                  child: DecoratedBox(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(26),
                                      gradient: LinearGradient(
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                        colors: [
                                          Colors.white.withValues(alpha: 0.78),
                                          const Color(0xFFEFF6FF)
                                              .withValues(alpha: 0.55),
                                          Colors.white.withValues(alpha: 0.68),
                                        ],
                                      ),
                                      border: Border.all(
                                        color:
                                            Colors.white.withValues(alpha: 0.85),
                                        width: 1,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color:
                                              primary.withValues(alpha: 0.22),
                                          blurRadius: 16,
                                          offset: const Offset(0, 4),
                                        ),
                                        BoxShadow(
                                          color: Colors.white
                                              .withValues(alpha: 0.9),
                                          blurRadius: 2,
                                          offset: const Offset(0, -1),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Row(
                              children: [
                                for (final item in items)
                                  Expanded(
                                    child: _LiquidGlassNavItem(
                                      item: item,
                                      isSelected: currentIndex == item.index,
                                      badgeCount: badgeCountFor(item.index),
                                      showBadgeSlot: item.showBadge,
                                      onTap: () => onTap(item.index),
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        );
                      },
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
}

class _GlassBlob extends StatelessWidget {
  final double size;
  final Color color;

  const _GlassBlob({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            color,
            color.withValues(alpha: 0),
          ],
        ),
      ),
    );
  }
}

class _LiquidGlassNavItem extends StatelessWidget {
  final NavItem item;
  final bool isSelected;
  final bool showBadgeSlot;
  final int badgeCount;
  final VoidCallback onTap;

  const _LiquidGlassNavItem({
    required this.item,
    required this.isSelected,
    required this.showBadgeSlot,
    required this.badgeCount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final iconSize = item.isLogo ? 30.0 : 22.0;
    final color = isSelected
        ? _LiquidGlassBottomBar._primary
        : _LiquidGlassBottomBar._inkMuted;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Center(
        child: AnimatedScale(
          scale: isSelected ? 1.08 : 1.0,
          duration: const Duration(milliseconds: 320),
          curve: Curves.easeOutBack,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              AnimatedOpacity(
                opacity: isSelected ? 1 : 0.82,
                duration: const Duration(milliseconds: 220),
                child: Image.asset(
                  item.icon,
                  width: iconSize,
                  height: iconSize,
                  color: item.isLogo && !isSelected ? null : color,
                  colorBlendMode:
                      item.isLogo && !isSelected ? null : BlendMode.srcIn,
                ),
              ),
              if (showBadgeSlot)
                NotificationBadgeDot(
                  count: badgeCount,
                  size: 7,
                  top: -2,
                  right: -4,
                ),
            ],
          ),
        ),
      ),
    );
  }
}