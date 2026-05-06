import 'package:LawyerOnline/shared/responsive/res_layout.dart';
import 'package:LawyerOnline/shared/responsive/responsive_values.dart';
import 'package:flutter/material.dart';

// ══════════════════════════════════════════════════════════
//  AppLayout — wrapper หลักที่ทุกหน้าใช้
//
//  Mobile/Tablet → แสดง child ตรงๆ
//  Desktop       → จำกัดความกว้าง + center content
//
//  วิธีใช้:
//  body: AppLayout(child: YourContent())
// ══════════════════════════════════════════════════════════

class AppLayout extends StatelessWidget {
  final Widget child;

  /// ถ้า true จะ center content บน desktop
  final bool centerContent;

  /// override maxWidth (ถ้าไม่ระบุใช้ค่าจาก RV)
  final double? maxWidth;

  const AppLayout({
    super.key,
    required this.child,
    this.centerContent = true,
    this.maxWidth,
  });

  @override
  Widget build(BuildContext context) {
    // Mobile/Tablet → ไม่ทำอะไร
    if (!ResponsiveLayout.isDesktop(context)) return child;

    // Desktop → จำกัดความกว้าง
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: maxWidth ?? RV.maxContentWidth(context),
        ),
        child: child,
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════
//  AppLayoutScaffold — Scaffold พร้อม layout สำเร็จรูป
//  ใช้แทน Scaffold ปกติ จัดการ TopNav/BottomNav อัตโนมัติ
//
//  วิธีใช้:
//  return AppLayoutScaffold(
//    topNav: TopNavBar(...),       // แสดงบน desktop
//    bottomNav: BottomNavBar(...), // แสดงบน mobile/tablet
//    body: YourContent(),
//  );
// ══════════════════════════════════════════════════════════

class AppLayoutScaffold extends StatelessWidget {
  final Widget body;
  final PreferredSizeWidget? appBar;
  final Widget? topNav;       // desktop top navigation
  final Widget? bottomNav;    // mobile/tablet bottom navigation
  final Color? backgroundColor;

  const AppLayoutScaffold({
    super.key,
    required this.body,
    this.appBar,
    this.topNav,
    this.bottomNav,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDesktop = ResponsiveLayout.isDesktop(context);

    return Scaffold(
      backgroundColor: backgroundColor,
      // desktop ใช้ topNav แทน appBar
      appBar: isDesktop && topNav != null
          ? PreferredSize(
              preferredSize: Size.fromHeight(RV.appBarHeight(context)),
              child: topNav!,
            )
          : appBar,
      // mobile/tablet ใช้ bottomNav
      bottomNavigationBar:
          !isDesktop && bottomNav != null ? bottomNav : null,
      body: AppLayout(child: body),
    );
  }
}