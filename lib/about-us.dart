import 'package:LawyerOnline/privacy-policy.dart';
import 'package:LawyerOnline/terms.dart';
import 'package:flutter/material.dart';
import 'package:LawyerOnline/component/appbar.dart';

class AboutUsPage extends StatelessWidget {
  const AboutUsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEEF2F5),
      appBar: appBarCustom(
        title: "เกี่ยวกับเรา",
        backBtn: true,
        backAction: () => Navigator.pop(context),
        isRightWidget: false,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(15, 20, 15, 40),
        children: [
          /// App Info Card
          Container(
            padding: const EdgeInsets.all(25),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(.05),
                  blurRadius: 15,
                  offset: const Offset(0, 6),
                )
              ],
            ),
            child: Column(
              children: [
                /// App Logo
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: const Color(0xFF0262EC),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(
                    Icons.gavel,
                    color: Colors.white,
                    size: 40,
                  ),
                ),

                const SizedBox(height: 15),

                const Text(
                  "Lawyer Online",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 5),

                const Text(
                  "Version 1.0.0",
                  style: TextStyle(
                    color: Colors.grey,
                  ),
                ),

                const SizedBox(height: 20),

                const Text(
                  "แอปพลิเคชันสำหรับให้คำปรึกษากฎหมายออนไลน์ "
                  "ช่วยให้ผู้ใช้งานสามารถติดต่อทนายความ นัดหมาย "
                  "และขอคำปรึกษาด้านกฎหมายได้สะดวก รวดเร็ว "
                  "ทุกที่ทุกเวลา",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.6,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),

          /// Contact Card
          // Container(
          //   padding: const EdgeInsets.all(20),
          //   decoration: BoxDecoration(
          //     color: Colors.white,
          //     borderRadius: BorderRadius.circular(22),
          //     boxShadow: [
          //       BoxShadow(
          //         color: Colors.black.withOpacity(.05),
          //         blurRadius: 15,
          //         offset: const Offset(0, 6),
          //       )
          //     ],
          //   ),
          //   child: Column(
          //     children: [

          //       menuItem(
          //         icon: Icons.language,
          //         title: "เว็บไซต์",
          //         value: "www.lawyeronline.com",
          //       ),

          //       const Divider(),

          //       menuItem(
          //         icon: Icons.email_outlined,
          //         title: "อีเมล",
          //         value: "support@lawyeronline.com",
          //       ),

          //       const Divider(),

          //       menuItem(
          //         icon: Icons.phone_outlined,
          //         title: "เบอร์โทร",
          //         value: "02-123-4567",
          //       ),

          //     ],
          //   ),
          // ),

          const SizedBox(height: 20),

          /// Policy Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(.05),
                  blurRadius: 15,
                  offset: const Offset(0, 6),
                )
              ],
            ),
            child: Column(
              children: [
                menuItem(
                  icon: Icons.privacy_tip_outlined,
                  title: "นโยบายความเป็นส่วนตัว",
                  value: "",
                  onTap: () => {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const PrivacyPolicyPage(),
                            ),
                          ),
                        }
                ),
                const Divider(),
                menuItem(
                    icon: Icons.description_outlined,
                    title: "เงื่อนไขการใช้งาน",
                    value: "",
                    onTap: () => {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const TermsPage(),
                            ),
                          ),
                        }),
              ],
            ),
          ),

          const SizedBox(height: 30),

          /// Copyright
          const Center(
            child: Text(
              "© 2026 Lawyer Online\nAll rights reserved",
              textAlign: TextAlign.center,
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

  Widget menuItem(
      {required IconData icon,
      required String title,
      required String value,
      Function? onTap}) {
    return GestureDetector(
      onTap: () => onTap!(),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: const Color(0xFFE8F1FF),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: const Color(0xFF0262EC)),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 13,
            ),
          )
        ],
      ),
    );
  }
}
