import 'package:LawyerOnline/component/dialog_service.dart';
import 'package:flutter/material.dart';
import 'package:LawyerOnline/component/appbar.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:LawyerOnline/menu.dart';

class DeleteAccountPage extends StatefulWidget {
  const DeleteAccountPage({super.key});

  @override
  State<DeleteAccountPage> createState() => _DeleteAccountPageState();
}

class _DeleteAccountPageState extends State<DeleteAccountPage> {
  int? selectedReason;
  final TextEditingController otherReasonController = TextEditingController();
  final storage = const FlutterSecureStorage();

  String name = "";
  String imageUrl = "";
  String typeLogin = "";

  @override
  void initState() {
    callRead();
    super.initState();
  }

  callRead() async {
    var imageProfile =
        await storage.read(key: 'imageUrlSocial') ?? 'assets/icons/profile.png';
    var nameProfile = await storage.read(key: 'name');
    var type = await storage.read(key: 'typeLogin');

    setState(() {
      name = nameProfile ?? "";
      imageUrl = imageProfile ?? "";
      typeLogin = type ?? "";
    });
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
        title: "",
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
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                children: [
                  const Text(
                    "ลบบัญชี",
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF111827),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "หากคุณต้องการลบบัญชี กรุณาแจ้งให้เราทราบถึงเหตุผล เพื่อที่เราจะได้นำไปปรับปรุงบริการให้ดียิ่งขึ้น",
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFF6B7280),
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
                                        errorBuilder: (context, error, stackTrace) {
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
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        decoration: BoxDecoration(
                          color: isSelected ? const Color(0xFFF0F7FF) : Colors.transparent,
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
                                color: isSelected ? const Color(0xFF0262EC): const Color(0xFF374151),
                                fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
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
                              hintStyle: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 14),
                              filled: true,
                              fillColor: const Color(0xFFF9FAFB),
                              contentPadding: const EdgeInsets.all(16),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: const BorderSide(color: Color(0xFF9CA3AF), width: 2),
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
                            style: const TextStyle(fontSize: 10, color: Color(0xFF9CA3AF)),
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
                  onPressed: selectedReason != null ? _showConfirmModal : null,
                  child: const Text(
                    "ลบ",
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

  void _showConfirmModal() {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.5),
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 24),
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(32),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 32, 24, 16),
                  child: Column(
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: const BoxDecoration(
                          color: Color(0xFFFFF9E6),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Container(
                            width: 56,
                            height: 56,
                            decoration: const BoxDecoration(
                              color: Color(0xFFDF0A0A),
                              shape: BoxShape.circle,
                            ),
                            child: const Center(
                              child: Text(
                                "?",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        "คุณแน่ใจหรือไม่?",
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF111827),
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        "คุณต้องการลบบัญชีของคุณอย่างถาวรใช่หรือไม่",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        "การยืนยันลบบัญชีจะส่งผลให้ข้อมูลทั้งหมดหายไป (ข้อมูลส่วนตัว, การเป็นสมาชิก, และอื่นๆ)",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 11,
                          fontStyle: FontStyle.italic,
                          color: Color(0xFF9CA3AF),
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  decoration: const BoxDecoration(
                    border: Border(top: BorderSide(color: Color(0xFFF3F4F6))),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () {
                            Navigator.pop(context);
                            _processDelete();
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 20),
                            decoration: const BoxDecoration(
                              color: Color(0xFFDF0A0A),
                              borderRadius: BorderRadius.only(
                                bottomLeft: Radius.circular(32),
                              ),
                            ),
                            child: const Center(
                              child: Text(
                                "ลบ",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: InkWell(
                          onTap: () {
                            Navigator.pop(context);
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 20),
                            child: const Center(
                              child: Text(
                                "เก็บบัญชีไว้",
                                style: TextStyle(
                                  color: Color(0xFF3B82F6),
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _processDelete() async {
    // 1. แสดง Loading
    DialogService.showLoading(context);

    try {
      // 2. เตรียมข้อมูลส่ง API
      String reason = "";
      if (selectedReason != null) {
        reason = selectedReason == 4 ? otherReasonController.text : reasons[selectedReason!];
      }
      
      // TODO: ใส่โค้ดเรียก API ลบบัญชีที่นี่
      // ตัวอย่าง: var response = await apiProvider.deleteAccount(reason: reason);
      
      // จำลองการดีเลย์ของ API 2 วินาที (ลบออกเมื่อต่อ API จริง)
      await Future.delayed(const Duration(seconds: 2));

      // 3. ปิดหน้าต่าง Loading
      Navigator.pop(context);

      // 4. แสดงข้อความสำเร็จ
      DialogService.showSuccess(
        context,
        title: "ลบบัญชีสำเร็จแล้ว",
        message: "ระบบกำลังพาท่านกลับสู่หน้าหลัก...",
        onClose: () async {
          // เคลียร์ข้อมูลการเข้าสู่ระบบทั้งหมด
          await storage.deleteAll();
          
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
