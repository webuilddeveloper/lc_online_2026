import 'package:LawyerOnline/component/dialog_service.dart';
import 'package:flutter/material.dart';
import 'package:LawyerOnline/component/appbar.dart';
import 'package:easy_localization/easy_localization.dart';

import 'package:LawyerOnline/menu.dart';
import 'package:LawyerOnline/services/auth_service.dart';
import 'package:LawyerOnline/models/user_profile_store.dart';
import 'package:LawyerOnline/models/lawyer/lawyer_profile_store.dart';

class DeleteAccountPage extends StatefulWidget {
  const DeleteAccountPage({super.key});

  @override
  State<DeleteAccountPage> createState() => _DeleteAccountPageState();
}

class _DeleteAccountPageState extends State<DeleteAccountPage> {
  int? selectedReason;
  final TextEditingController otherReasonController = TextEditingController();

  // อ่านจาก UserProfileStore โดยตรง ไม่ต้องใช้ storage
  String get name => UserProfileStore.instance.name;
  String get imageUrl => UserProfileStore.instance.imageUrl;
  String get typeLogin => UserProfileStore.instance.typeLogin;
  String get email => UserProfileStore.instance.email;
  String get code => UserProfileStore.instance.code;

  @override
  void initState() {
    super.initState();
  }

  final List<String> reasons = [
    'ไม่ได้ใช้งานแพลตฟอร์มแล้ว',
    'พบแอปอื่นที่น่าสนใจกว่า',
    'กังวลเรื่องความเป็นส่วนตัว',
    'กังวลเรื่องความปลอดภัย',
    'อื่นๆ',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      appBar: appBarCustom(
        title: "ลบบัญชี",
        backBtn: true,
        backAction: () => goBack(),
        isRightWidget: false,
      ),
      extendBodyBehindAppBar: true,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                children: [
                  // const Text(
                  //   "ลบบัญชี",
                  //   style: TextStyle(
                  //     fontSize: 32,
                  //     fontWeight: FontWeight.w600,
                  //     color: Color(0xFFE61313),
                  //   ),
                  // ),
                  const SizedBox(height: 8),
                  const Text(
                    "หากคุณต้องการลบบัญชี กรุณาแจ้งให้เราทราบถึงเหตุผล เพื่อที่เราจะได้นำไปปรับปรุงบริการให้ดียิ่งขึ้น",
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF6B7280),
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    "*กรณีกู้คืนบัญชี: หากคุณลบบัญชีโดยไม่ได้ตั้งใจ หรือเปลี่ยนใจ คุณสามารถติดต่อฝ่ายบริการลูกค้าเพื่อขอความช่วยเหลือในการกู้คืนบัญชีของคุณได้ภายใน 30 วันหลังจากวันที่ลบบัญชี",
                    style: TextStyle(
                      fontSize: 14,
                      color: Color.fromARGB(255, 243, 186, 28),
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Profile Area
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF9FAFB),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFF3F4F6)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              )
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(100),
                            child: imageUrl.isEmpty
                                ? Image.asset(
                                    "assets/icons/profile.png",
                                    fit: BoxFit.cover,
                                  )
                                : typeLogin == 'local'
                                    ? Image.asset(
                                        imageUrl,
                                        fit: BoxFit.cover,
                                      )
                                    : Image.network(
                                        imageUrl,
                                        fit: BoxFit.cover,
                                        errorBuilder:
                                            (context, error, stackTrace) {
                                          return Image.asset(
                                            "assets/icons/profile.png",
                                            fit: BoxFit.cover,
                                          );
                                        },
                                      ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name.isEmpty ? "กำลังโหลด..." : name,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF111827),
                              ),
                            ),
                            Text(
                              "ID: #889210",
                              style: TextStyle(
                                fontSize: 12,
                                color: Color(0xFF9CA3AF),
                              ),
                            ),
                          ],
                        )
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Reasons
                  ...List.generate(reasons.length, (index) {
                    bool isSelected = selectedReason == index;
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          selectedReason = index;
                        });
                      },
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 4),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 16),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color(0xFFF0F7FF)
                              : Colors.transparent,
                          border: Border(
                            bottom: BorderSide(
                                color: isSelected
                                    ? const Color(0xFF3B82F6)
                                    : const Color(0xFFF3F4F6)),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              reasons[index],
                              style: TextStyle(
                                fontSize: 14,
                                color: isSelected
                                    ? const Color(0xFF0262EC)
                                    : const Color(0xFF374151),
                                fontWeight: isSelected
                                    ? FontWeight.w500
                                    : FontWeight.normal,
                              ),
                            ),
                            Radio<int>(
                              value: index,
                              groupValue: selectedReason,
                              activeColor: const Color(0xFF0262EC),
                              onChanged: (value) {
                                setState(() {
                                  selectedReason = value;
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  }),

                  // Textarea for 'อื่นๆ'
                  if (selectedReason == 4)
                    Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          TextField(
                            controller: otherReasonController,
                            maxLength: 150,
                            maxLines: 4,
                            decoration: InputDecoration(
                              hintText: "กรุณาระบุรายละเอียดเพิ่มเติม...",
                              hintStyle: const TextStyle(
                                  color: Color(0xFF9CA3AF), fontSize: 14),
                              filled: true,
                              fillColor: const Color(0xFFF9FAFB),
                              contentPadding: const EdgeInsets.all(16),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide:
                                    const BorderSide(color: Color(0xFFE5E7EB)),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide:
                                    const BorderSide(color: Color(0xFFE5E7EB)),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: const BorderSide(
                                    color: Color(0xFF9CA3AF), width: 2),
                              ),
                              counterText: "", // Hide default counter
                            ),
                            onChanged: (text) {
                              setState(() {}); // For updating character count
                            },
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "${otherReasonController.text.length}/150",
                            style: const TextStyle(
                                fontSize: 10, color: Color(0xFF9CA3AF)),
                          )
                        ],
                      ),
                    ),

                  const SizedBox(height: 32),
                ],
              ),
            ),

            // Bottom Area
            Container(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.9),
                border: const Border(top: BorderSide(color: Color(0xFFF9FAFB))),
              ),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFDF0A0A),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    elevation: 10,
                    shadowColor: Colors.black.withOpacity(0.3),
                  ),
                  onPressed: selectedReason != null
                      ? () {
                          DialogService.showConfirmDeleteAccount(
                            context,
                            onConfirm: () => _processDelete(),
                          );
                        }
                      : null,
                  child: const Text(
                    "ลบบัญชี",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  void _processDelete() async {
    // 1. แสดง Loading
    DialogService.showLoading(context);

    try {
      // เตรียมข้อมูลส่ง API
      String reasonCancel = "";
      if (selectedReason != null) {
        reasonCancel = selectedReason == 4
            ? otherReasonController.text
            : reasons[selectedReason!];
      }

      // เรียก API ยกเลิกบัญชี โดยส่ง email, code, และ reesonCancel
      await AuthService.cancelAccount(
        email: email,
        code: code,
        reesonCancel: reasonCancel,
      );

      // 3. ปิดหน้าต่าง Loading
      Navigator.pop(context);

      // 4. แสดงข้อความสำเร็จ
      DialogService.showSuccess(
        context,
        title: "ลบบัญชีสำเร็จแล้ว",
        message: "ระบบกำลังพาท่านกลับสู่หน้าหลัก...",
        onClose: () async {
          // เคลียร์ข้อมูลการเข้าสู่ระบบทั้งหมด
          await UserProfileStore.instance.resetAndClear();
          await LawyerProfileStore.instance.reset();

          // ปิด Popup
          Navigator.pop(context);

          // พาผู้ใช้กลับหน้าแรก (MenuPage) และล้างประวัติการนำทาง
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(
              builder: (context) => MenuPage(),
            ),
            (Route<dynamic> route) => false,
          );
        },
      );
    } catch (e) {
      // ปิดหน้าต่าง Loading
      Navigator.pop(context);

      // แสดงข้อความผิดพลาด
      DialogService.showError(
        context,
        title: "เกิดข้อผิดพลาด",
        message: "ไม่สามารถลบบัญชีได้ กรุณาลองใหม่อีกครั้ง",
      );
    }
  }

  void goBack() {
    Navigator.pop(context, false);
  }
}
