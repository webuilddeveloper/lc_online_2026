import 'package:flutter/material.dart';
import 'package:LawyerOnline/component/appbar.dart';

class TermsPage extends StatelessWidget {
  const TermsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEEF2F5),

      appBar: appBarCustom(
        title: "เงื่อนไขการใช้งาน",
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

                title("1. การยอมรับเงื่อนไข"),
                content(
                    "การเข้าใช้งานแอปพลิเคชัน Lawyer Online ถือว่าผู้ใช้งานยอมรับ "
                    "เงื่อนไขและข้อตกลงทั้งหมดที่ระบุไว้ในเอกสารนี้"),

                title("2. การใช้งานบริการ"),
                content(
                    "ผู้ใช้งานสามารถใช้บริการเพื่อขอคำปรึกษาด้านกฎหมาย "
                    "นัดหมายทนายความ และรับข้อมูลทางกฎหมายผ่านระบบ"),

                title("3. ความรับผิดชอบของผู้ใช้งาน"),
                content(
                    "ผู้ใช้งานต้องให้ข้อมูลที่ถูกต้อง และไม่ใช้ระบบในทางที่ผิด "
                    "หรือผิดกฎหมาย"),

                title("4. ข้อจำกัดความรับผิด"),
                content(
                    "ทีมพัฒนาไม่รับผิดชอบต่อความเสียหายที่เกิดจากการใช้ข้อมูล "
                    "หรือคำปรึกษาที่ได้รับผ่านแอปพลิเคชัน"),

                title("5. การเปลี่ยนแปลงเงื่อนไข"),
                content(
                    "บริษัทขอสงวนสิทธิ์ในการแก้ไขเงื่อนไขการใช้งาน "
                    "โดยไม่ต้องแจ้งให้ทราบล่วงหน้า"),

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
