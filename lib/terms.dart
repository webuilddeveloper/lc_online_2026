import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:LawyerOnline/component/appbar.dart';

class TermsPage extends StatelessWidget {
  const TermsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEEF2F5),
      appBar: appBarCustom(
        title: "terms".tr(),
        backBtn: true,
        backAction: () => Navigator.pop(context),
        isRightWidget: false,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(15, 20, 15, 40),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: cardStyle(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                title("terms_of_service.section_1_title".tr()),
                content("terms_of_service.section_1_content".tr()),
                title("terms_of_service.section_2_title".tr()),
                content("terms_of_service.section_2_content".tr()),
                title("terms_of_service.section_3_title".tr()),
                content("terms_of_service.section_3_content".tr()),
                title("terms_of_service.section_4_title".tr()),
                content("terms_of_service.section_4_content".tr()),
                title("terms_of_service.section_5_title".tr()),
                content("terms_of_service.section_5_content".tr()),
              ],
            ),
          ),
          const SizedBox(height: 30),
          const Center(
            child: Text(
              "อัปเดตล่าสุด: 2026",
              style: TextStyle(
                color: Colors.grey,
                fontSize: 12,
              ),
            ),
          )
        ],
      ),
    );
  }

  static BoxDecoration cardStyle() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(22),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(.05),
          blurRadius: 15,
          offset: const Offset(0, 6),
        )
      ],
    );
  }
}

class title extends StatelessWidget {
  final String text;

  const title(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 15, bottom: 6),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Color(0xFF0262EC),
        ),
      ),
    );
  }
}

class content extends StatelessWidget {
  final String text;

  const content(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        height: 1.6,
        fontSize: 14,
      ),
    );
  }
}
