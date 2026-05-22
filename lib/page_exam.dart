import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

// รายการภาษาที่รองรับ
const _langs = [
  {'code': 'th', 'name': 'ภาษาไทย', 'flag': '🇹🇭'},
  {'code': 'en', 'name': 'English', 'flag': '🇺🇸'},
];

// เรียกจากที่ไหนก็ได้
final _storage = FlutterSecureStorage();

void showLanguagePicker(BuildContext context) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => _LanguagePicker(),
  );
}

class _LanguagePicker extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final currentCode = context.locale.languageCode;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // handle bar
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'selectLanguage'.tr(),
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 16),

            // รายการภาษา
            ..._langs.map((lang) {
              final isSelected = lang['code'] == currentCode;
              return GestureDetector(
                onTap: () async {
                  // เปลี่ยนภาษา — easy_localization บันทึกให้อัตโนมัติ
                  await context.setLocale(Locale(lang['code']!));
                  await _storage.write(key: 'appLanguage', value: lang['code']);
                  if (context.mounted) Navigator.pop(context);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.only(bottom: 10),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFF1A1A2E).withOpacity(0.06)
                        : Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isSelected
                          ? const Color(0xFF1A1A2E)
                          : Colors.grey.shade200,
                      width: isSelected ? 1.5 : 1,
                    ),
                  ),
                  child: Row(children: [
                    Text(lang['flag']!, style: const TextStyle(fontSize: 24)),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        lang['name']!,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight:
                              isSelected ? FontWeight.w700 : FontWeight.w500,
                          color: const Color(0xFF1A1A2E),
                        ),
                      ),
                    ),
                    if (isSelected)
                      Container(
                        width: 24,
                        height: 24,
                        decoration: const BoxDecoration(
                          color: Color(0xFF1A1A2E),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.check_rounded,
                            color: Colors.white, size: 14),
                      ),
                  ]),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
