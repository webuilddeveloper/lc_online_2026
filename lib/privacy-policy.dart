import 'package:flutter/material.dart';
import 'package:LawyerOnline/component/appbar.dart';

class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEEF2F5),

      appBar: appBarCustom(
        title: "นโยบายความเป็นส่วนตัว",
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
              children: const [

                title("1. การเก็บข้อมูล"),
                content(
                    "แอปพลิเคชัน Lawyer Online อาจเก็บข้อมูลส่วนบุคคล "
                    "เช่น ชื่อ อีเมล เบอร์โทรศัพท์ เพื่อใช้ในการให้บริการ"),

                title("2. การใช้ข้อมูล"),
                content(
                    "ข้อมูลที่เก็บจะถูกใช้เพื่อพัฒนาการให้บริการ "
                    "และปรับปรุงประสบการณ์ของผู้ใช้งาน"),

                title("3. การเปิดเผยข้อมูล"),
                content(
                    "บริษัทจะไม่เปิดเผยข้อมูลส่วนบุคคลของผู้ใช้งาน "
                    "ให้บุคคลที่สาม เว้นแต่ได้รับความยินยอม"),

                title("4. ความปลอดภัยของข้อมูล"),
                content(
                    "เรามีมาตรการป้องกันข้อมูล เพื่อป้องกันการเข้าถึง "
                    "หรือใช้งานโดยไม่ได้รับอนุญาต"),

                title("5. สิทธิของผู้ใช้งาน"),
                content(
                    "ผู้ใช้งานสามารถขอแก้ไข หรือลบข้อมูลส่วนบุคคล "
                    "ได้ตามสิทธิที่กฎหมายกำหนด"),

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
