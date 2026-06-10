import 'dart:ui';
import 'package:LawyerOnline/component/dialog_service.dart';
import 'package:LawyerOnline/login.dart';
import 'package:LawyerOnline/menu.dart';
import 'package:LawyerOnline/notification.dart';
import 'package:LawyerOnline/notification_dropdown.dart';
import 'package:LawyerOnline/shared/responsive/responsive_values.dart';
import 'package:LawyerOnline/models/lawyer/lawyer_profile_store.dart';
import 'package:LawyerOnline/subscribe/subscribe_theme.dart';
import 'package:LawyerOnline/models/user_profile_store.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

// ══════════════════════════════════════════════════════════
//  NavItem — model สำหรับ nav item แต่ละตัว
// ══════════════════════════════════════════════════════════
class NavItem {
  final String icon;
  final String label;
  final int index;
  final bool showBadge;
  final bool isLogo;

  const NavItem({
    required this.icon,
    required this.label,
    required this.index,
    this.showBadge = false,
    this.isLogo = false,
  });
}

// ══════════════════════════════════════════════════════════
//  DesktopTopNav — TopNav bar สำหรับ Desktop
//  ใช้งาน:
//    appBar: PreferredSize(
//      preferredSize: Size.fromHeight(RV.appBarHeight(context)),
//      child: DesktopTopNav(...),
//    )
// ══════════════════════════════════════════════════════════
class DesktopTopNav extends StatefulWidget {
  final int currentIndex;
  final Function(int) onTap;
  final List<NavItem> navItems;
  final String name;
  final String imageUrl;
  final String userType;
  final String typeLogin;

  const DesktopTopNav({
    Key? key,
    required this.currentIndex,
    required this.onTap,
    required this.navItems,
    required this.name,
    required this.imageUrl,
    required this.userType,
    required this.typeLogin,
  }) : super(key: key);

  @override
  State<DesktopTopNav> createState() => _DesktopTopNavState();
}

class _DesktopTopNavState extends State<DesktopTopNav>
    with TickerProviderStateMixin {
  // ── Pulse ring (วนซ้ำตลอด) ──────────────────────────────────────
  late final AnimationController _pulseCtrl;
  late final Animation<double> _pulseScale;
  late final Animation<double> _pulseOpacity;

  // ── Burst (one-shot เมื่อ toggle เปิด) ─────────────────────────
  late final AnimationController _burstCtrl;
  late final Animation<double> _burstScale;
  late final Animation<double> _burstOpacity;

  bool _prevUrgent = false;

  @override
  void initState() {
    super.initState();

    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );
    _pulseScale = Tween<double>(begin: 1.0, end: 1.55).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeOut),
    );
    _pulseOpacity = Tween<double>(begin: 0.65, end: 0.0).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeOut),
    );

    _burstCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _burstScale = Tween<double>(begin: 1.0, end: 1.9).animate(
      CurvedAnimation(parent: _burstCtrl, curve: Curves.easeOut),
    );
    _burstOpacity = Tween<double>(begin: 0.7, end: 0.0).animate(
      CurvedAnimation(parent: _burstCtrl, curve: Curves.easeOut),
    );

    LawyerProfileStore.instance.addListener(_onStoreChanged);

    _prevUrgent = LawyerProfileStore.instance.isUrgentCaseEnabled;
    _syncUrgentAnimation(_prevUrgent, burst: false);
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _burstCtrl.dispose();
    LawyerProfileStore.instance.removeListener(_onStoreChanged);
    super.dispose();
  }

  void _syncUrgentAnimation(bool enabled, {bool burst = false}) {
    if (enabled) {
      _pulseCtrl.repeat();
      if (burst) _burstCtrl.forward(from: 0);
    } else {
      _pulseCtrl.stop();
      _pulseCtrl.reset();
    }
  }

  void _onStoreChanged() {
    if (!mounted) return;
    final urgent = LawyerProfileStore.instance.isUrgentCaseEnabled;
    if (urgent != _prevUrgent) {
      _syncUrgentAnimation(urgent, burst: true);
      _prevUrgent = urgent;
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final isUrgentCaseEnabled = LawyerProfileStore.instance.isUrgentCaseEnabled;
    final isPro =
        LawyerProfileStore.instance.isPro && widget.userType == 'lawyer';

    final currentIndex = widget.currentIndex;
    final onTap = widget.onTap;
    final navItems = widget.navItems;
    final name = widget.name;
    final imageUrl = widget.imageUrl;
    final userType = widget.userType;
    final typeLogin = widget.typeLogin;

    return Container(
      color: Colors.white,
      padding: EdgeInsets.symmetric(
        horizontal: RV.pagePadding(context),
        vertical: 12,
      ),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            // ── Logo ──────────────────────────────────────
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset(
                  'assets/icons/logo-no-bg.png',
                  width: 32,
                  height: 32,
                  color: const Color(0xFF0262EC),
                ),
                const SizedBox(width: 8),
                const Text(
                  'LC Online',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0262EC),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 32),

            // ── Nav items (กลาง) ──────────────────────────
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: navItems
                        .map((item) => DesktopNavItem(
                              item: item,
                              isSelected: currentIndex == item.index,
                              showBadge: item.showBadge && typeLogin != 'null',
                              onTap: () => onTap(item.index),
                            ))
                        .toList(),
                  ),
                ),
              ),
            ),

            // ── Avatar + ชื่อ + role (ขวาสุด) ────────────
            if (typeLogin != 'null') ...[
              // ── bell ──────────────────────────────────
              PopupMenuButton<String>(
                offset: const Offset(0, 50),
                color: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                tooltip: "notifications".tr(),
                itemBuilder: (_) => [
                  const PopupMenuItem(
                    enabled: false,
                    padding: EdgeInsets.all(12),
                    child: SizedBox(
                      width: 350,
                      height: 400,
                      child: NotificationDropdownContent(),
                    ),
                  ),
                ],
                child: Container(
                  width: 40,
                  height: 40,
                  margin: const EdgeInsets.only(right: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1565C0).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: const Color(0xFF1565C0).withOpacity(0.2)),
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Image.asset('assets/icons/bell-2.png',
                          width: 22,
                          height: 22,
                          color: const Color(0xFF1565C0)),
                      Positioned(
                        top: 8,
                        right: 9,
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                              color: Color(0xFFF70C0C), shape: BoxShape.circle),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ── ชื่อ + badge ──────────────────────────
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 150),
                child: Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF3CD),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFF5A623)),
                ),
                child: Text(
                  userType == 'lawyer'
                      ? 'role.lawyer'.tr()
                      : 'role.client'.tr(),
                  style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFFF5A623),
                      fontWeight: FontWeight.w600),
                ),
              ),
              if (isPro) ...[
                const SizedBox(width: 8),
                const ProBadge(fontSize: 10),
              ],
              const SizedBox(width: 12),

              // ── Avatar + วงเขียว ──────────────────────
              PopupMenuButton<String>(
                offset: const Offset(0, 50),
                color: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                onSelected: (value) async {
                  if (value == 'profile') {
                    onTap(4);
                  } else if (value == 'logout') {
                    DialogService.showConfirmLogout(
                      context,
                      title: "confirmLogoutTitle".tr(),
                      message: "confirmLogoutMessage".tr(),
                      onConfirm: () async {
                        await UserProfileStore.instance.resetAndClear();
                        await LawyerProfileStore.instance.reset();
                        if (context.mounted) {
                          Navigator.of(context).pushAndRemoveUntil(
                            MaterialPageRoute(builder: (_) => MenuPage()),
                            (route) => false,
                          );
                        }
                      },
                    );
                  }
                },
                itemBuilder: (_) => [
                  PopupMenuItem(
                    value: 'profile',
                    child: Row(
                      children: [
                        const Icon(Icons.person_outline_rounded,
                            size: 18, color: Color(0xFF0262EC)),
                        const SizedBox(width: 10),
                        Text('profile'.tr(),
                            style: const TextStyle(
                                fontSize: 14, fontWeight: FontWeight.w500)),
                      ],
                    ),
                  ),
                  const PopupMenuDivider(),
                  PopupMenuItem(
                    value: 'logout',
                    child: Row(
                      children: [
                        const Icon(Icons.logout_rounded,
                            size: 18, color: Color(0xFFEF4444)),
                        const SizedBox(width: 10),
                        Text('logout'.tr(),
                            style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFFEF4444))),
                      ],
                    ),
                  ),
                ],
                child: _UrgentAvatarRing(
                  urgentOn: isUrgentCaseEnabled,
                  pulseScale: _pulseScale,
                  pulseOpacity: _pulseOpacity,
                  burstScale: _burstScale,
                  burstOpacity: _burstOpacity,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                        ),
                        child: ClipOval(
                          child: imageUrl.isNotEmpty && imageUrl != 'null'
                              ? Image.network(imageUrl, fit: BoxFit.cover)
                              : Image.asset('assets/icons/profile.png',
                                  fit: BoxFit.cover),
                        ),
                      ),
                      if (isUrgentCaseEnabled)
                        Positioned(
                          bottom: -2,
                          right: -2,
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              color: const Color(0xFF059669),
                              shape: BoxShape.circle,
                              border:
                                  Border.all(color: Colors.white, width: 1.5),
                            ),
                            child: const Icon(Icons.balance_rounded,
                                color: Colors.white, size: 12),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ] else
              TextButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => LoginPage(isBack: true)),
                ),
                child: Text('login'.tr()),
              ),
         
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════
//  _UrgentAvatarRing — pulse / burst / static ring wrapper
//  ครอบ avatar โดยไม่แตะ ProfileAvatar
// ══════════════════════════════════════════════════════════
class _UrgentAvatarRing extends StatelessWidget {
  final bool urgentOn;
  final Animation<double> pulseScale;
  final Animation<double> pulseOpacity;
  final Animation<double> burstScale;
  final Animation<double> burstOpacity;
  final Widget child;

  const _UrgentAvatarRing({
    required this.urgentOn,
    required this.pulseScale,
    required this.pulseOpacity,
    required this.burstScale,
    required this.burstOpacity,
    required this.child,
  });

  static const _green = Color(0xFF059669);
  // ขนาด avatar ใน DesktopTopNav คือ 40×40
  static const double _size = 40;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: _size + 24,
      height: _size + 24,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          // ── burst (one-shot เมื่อ toggle เปิด) ─────────────
          if (urgentOn)
            AnimatedBuilder(
              animation: burstScale,
              builder: (_, __) => Opacity(
                opacity: burstOpacity.value,
                child: Transform.scale(
                  scale: burstScale.value,
                  child: Container(
                    width: _size,
                    height: _size,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: _green, width: 3),
                    ),
                  ),
                ),
              ),
            ),

          // ── pulse วง 1 (วนซ้ำ) ─────────────────────────────
          if (urgentOn)
            AnimatedBuilder(
              animation: pulseScale,
              builder: (_, __) => Opacity(
                opacity: pulseOpacity.value,
                child: Transform.scale(
                  scale: pulseScale.value,
                  child: Container(
                    width: _size,
                    height: _size,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: _green, width: 2.5),
                    ),
                  ),
                ),
              ),
            ),

          // ── pulse วง 2 (offset phase 50% → double wave) ─────
          if (urgentOn)
            AnimatedBuilder(
              animation: pulseScale,
              builder: (_, __) {
                final t = (pulseScale.value - 1.0) / 0.55;
                final shifted = ((t + 0.5) % 1.0);
                final scale2 = 1.0 + shifted * 0.55;
                final opacity2 = (1.0 - shifted) * 0.55;
                return Opacity(
                  opacity: opacity2.clamp(0.0, 1.0),
                  child: Transform.scale(
                    scale: scale2,
                    child: Container(
                      width: _size,
                      height: _size,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: _green, width: 2),
                      ),
                    ),
                  ),
                );
              },
            ),

          // ── static green border คงที่ ───────────────────────
          if (urgentOn)
            Container(
              width: _size + 4,
              height: _size + 4,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: _green.withOpacity(0.85),
                  width: 2.5,
                ),
              ),
            ),

          // ── avatar จริง ────────────────────────────────────
          child,
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════
//  DesktopNavItem — nav item แต่ละตัวใน TopNav
// ══════════════════════════════════════════════════════════
class DesktopNavItem extends StatelessWidget {
  final NavItem item;
  final bool isSelected;
  final bool showBadge;
  final VoidCallback onTap;

  const DesktopNavItem({
    Key? key,
    required this.item,
    required this.isSelected,
    required this.showBadge,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final bool showText = screenWidth >= 1250;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          splashColor: const Color(0xFF0262EC).withOpacity(0.1),
          highlightColor: const Color(0xFF0262EC).withOpacity(0.06),
          child: Ink(
            decoration: BoxDecoration(
              color: isSelected
                  ? const Color(0xFF0262EC).withOpacity(0.08)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Container(
              margin: EdgeInsets.symmetric(horizontal: showText ? 6 : 12),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          Image.asset(
                            item.icon,
                            width: item.isLogo ? 36 : 28,
                            height: item.isLogo ? 36 : 28,
                            color: isSelected
                                ? const Color(0xFF0262EC)
                                : const Color(0xFF666666),
                          ),
                          if (showBadge)
                            Positioned(
                              top: 0,
                              right: 2,
                              child: Container(
                                width: 10,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: Color(0xFFF70C0C),
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                        ],
                      ),
                      if (showText) ...[
                        const SizedBox(width: 8),
                        Text(
                          item.label,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight:
                                isSelected ? FontWeight.w700 : FontWeight.w400,
                            color: isSelected
                                ? const Color(0xFF0262EC)
                                : const Color(0xFF666666),
                            height: 1.0,
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (!showText) ...[
                    const SizedBox(height: 4),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      width: isSelected ? 5 : 0,
                      height: isSelected ? 5 : 0,
                      decoration: const BoxDecoration(
                        color: Color(0xFF0262EC),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
