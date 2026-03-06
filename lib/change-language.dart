import 'package:LawyerOnline/component/appbar.dart';
import 'package:LawyerOnline/component/dialog_service.dart';
import 'package:flutter/material.dart';

class ChangeLanguagePage extends StatefulWidget {
  const ChangeLanguagePage({Key? key}) : super(key: key);

  @override
  State<ChangeLanguagePage> createState() => _ChangeLanguagePageState();
}

class _ChangeLanguagePageState extends State<ChangeLanguagePage> {
  String selectedLanguage = "th";

  Widget languageItem({
    required String code,
    required String title,
    required String subtitle,
    required String flag,
  }) {
    bool isSelected = selectedLanguage == code;

    return GestureDetector(
      onTap: () {
        setState(() {
          selectedLanguage = code;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue.shade50 : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? Colors.blue : Colors.grey.shade200,
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Row(
          children: [
            Text(
              flag,
              style: const TextStyle(fontSize: 28),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(
                Icons.check_circle,
                color: Colors.blue,
              )
          ],
        ),
      ),
    );
  }

  void saveLanguage() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(
              Icons.language,
              color: Colors.blue,
              size: 60,
            ),
            SizedBox(height: 16),
            Text(
              "เปลี่ยนภาษาสำเร็จ",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            SizedBox(height: 8),
            Text(
              "Language updated successfully",
              textAlign: TextAlign.center,
            )
          ],
        ),
        actions: [
          TextButton(
            child: const Text("ตกลง"),
            onPressed: () {
              Navigator.pop(context);
            },
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF6F7FB),
      appBar: appBar(
        title: "เปลี่ยนภาษา",
        backBtn: true,
        rightBtn: false,
        backAction: () => goBack(),
        rightAction: () => {},
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            languageItem(
              code: "th",
              title: "ภาษาไทย",
              subtitle: "Thai",
              flag: "🇹🇭",
            ),

            languageItem(
              code: "en",
              title: "English",
              subtitle: "English",
              flag: "🇺🇸",
            ),

            languageItem(
              code: "cn",
              title: "中文",
              subtitle: "Chinese",
              flag: "🇨🇳",
            ),

            languageItem(
              code: "jp",
              title: "日本語",
              subtitle: "Japanese",
              flag: "🇯🇵",
            ),

            const Spacer(),

            // SizedBox(
            //   width: double.infinity,
            //   height: 50,
            //   child: ElevatedButton(
            //     onPressed: saveLanguage,
            //     style: ElevatedButton.styleFrom(
            //       backgroundColor: Colors.blue,
            //       shape: RoundedRectangleBorder(
            //         borderRadius: BorderRadius.circular(14),
            //       ),
            //     ),
            //     child: const Text(
            //       "บันทึก",
            //       style: TextStyle(fontSize: 16),
            //     ),
            //   ),
            // )
            GestureDetector(
              onTap: () => {
                DialogService.showSuccess(
                  context,
                  title: "เปลี่ยนภาษาสำเร็จ",
                  message: "ระบบได้บันทึกภาษาใหม่เรียบร้อยแล้ว",
                  onClose: () {
                    Navigator.pop(context);
                  },
                ),
              },
              child: Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(vertical: 15, horizontal: 10),
                decoration: BoxDecoration(
                    color: const Color(0xFF0262EC),
                    borderRadius: BorderRadius.circular(18),
                    border:
                        Border.all(width: 1, color: const Color(0xFFDBDBDB))),
                child: const Text(
                  "ถัดไป",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void goBack() {
    Navigator.pop(context, false);
  }
}
