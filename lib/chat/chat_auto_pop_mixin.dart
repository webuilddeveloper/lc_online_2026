import 'package:flutter/material.dart';
import 'package:LawyerOnline/shared/responsive/res_layout.dart';

// ══════════════════════════════════════════════════════════
//  AutoPopOnDesktopMixin
//
//  ใส่ใน State ของ ChatPage ที่ push เป็น route แบบ mobile
//  เมื่อผู้ใช้ขยายจอจาก mobile → tablet/desktop
//  mixin นี้จะ pop route ทิ้งอัตโนมัติ
//  → MessagePage จะ rebuild เป็น 2-panel layout เอง
//
//  วิธีใช้:
//    class _ChatPageLawyerState extends State<ChatPageLawyer>
//        with AutoPopOnDesktopMixin { ... }
// ══════════════════════════════════════════════════════════
mixin AutoPopOnDesktopMixin<T extends StatefulWidget> on State<T> {
  bool _wasMobile = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final isMobile = ResponsiveLayout.isMobile(context);

    // เปลี่ยนจาก mobile → tablet/desktop และยังอยู่ใน route (ไม่ใช่ embeddedMode)
    if (_wasMobile && !isMobile) {
      _wasMobile = false;
      // pop หลัง frame ปัจจุบัน build เสร็จ
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }
      });
    } else {
      _wasMobile = isMobile;
    }
  }
}
