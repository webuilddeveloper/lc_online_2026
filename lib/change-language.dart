import 'package:LawyerOnline/component/appbar.dart';
import 'package:LawyerOnline/component/dialog_service.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ChangeLanguagePage extends StatefulWidget {
  const ChangeLanguagePage({Key? key}) : super(key: key);

  @override
  State<ChangeLanguagePage> createState() => _ChangeLanguagePageState();
}

class _ChangeLanguagePageState extends State<ChangeLanguagePage> {
  // FIX: ย้าย _storage เข้ามาใน class (เดิมอยู่นอก class เป็น top-level variable)
  final _storage = const FlutterSecureStorage();

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

  @override
  void initState() {
    super.initState();
    selectedLanguage = context.locale.languageCode;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF6F7FB),
      appBar: appBar(
        // FIX: ใช้ translation key แทน hardcoded Thai
        title: 'changelanguage'.tr(),
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
            GestureDetector(
              onTap: () async {
                await context.setLocale(Locale(selectedLanguage));
                await _storage.write(
                    key: 'appLanguage', value: selectedLanguage);
                // FIX: ใช้ translation key แทน hardcoded Thai strings
                DialogService.showSuccess(
                  context,
                  title: 'changePasswordSuccessTitle'.tr(),
                  message: 'saveSuccessMessage'.tr(),
                  onClose: () {
                    Navigator.pop(context);
                  },
                );
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
                // FIX: ใช้ translation key แทน hardcoded "ถัดไป"
                child: Text(
                  'confirm'.tr(),
                  style: const TextStyle(
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
