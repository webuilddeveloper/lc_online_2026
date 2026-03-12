import 'package:LawyerOnline/component/appbar.dart';
import 'package:LawyerOnline/lawyer-online-list.dart';
import 'package:flutter/material.dart';
import 'law_type_detail_page.dart';

class LawTypeAllPage extends StatelessWidget {
  LawTypeAllPage({super.key});

  final List lawTypes = [
    {
      "code": "0",
      "title": "กฏหมายแพ่งและอาญา",
      "icon": "assets/icons/law-type-1.png",
      "desc": "เกี่ยวกับคดีอาญา เช่น ลักทรัพย์ ทำร้ายร่างกาย",
      "lawType": "กฏหมายแพ่งและอาญา"
    },
    {
      "code": "1",
      "title": "กฎหมายครอบครัว",
      "icon": "assets/icons/law-type-2.png",
      "desc": "คดีแพ่ง เช่น หนี้สิน สัญญา",
      "lawType": "กฏหมายครอบครัว"
    },
    {
      "code": "2",
      "title": "กฎหมายบริษัท",
      "icon": "assets/icons/law-type-3.png",
      "desc": "บริษัท หุ้นส่วน ธุรกิจ",
      "lawType": "กฏหมายแรงงาน"
    },
    {
      "code": "3",
      "title": "กฎหมายธุรกิจ",
      "icon": "assets/icons/law-type-4.png",
      "desc": "บริษัท หุ้นส่วน ธุรกิจ",
      "lawType": "ธุรกิจและการค้า"
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEEF2F5),
      appBar: appBarCustom(
        title: "ประเภทกฎหมายทั้งหมด",
        backBtn: true,
        isRightWidget: false,
        backAction: () => Navigator.pop(context),
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: lawTypes.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: 1.1,
        ),
        itemBuilder: (context, index) {
          final item = lawTypes[index];

          return GestureDetector(
            onTap: () {
              // Navigator.push(
              //   context,
              //   MaterialPageRoute(
              //     builder: (_) => LawTypeDetailPage(data: item),
              //   ),
              // );
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => LawyerOnlineList(
                    lawType: item['lawType'],
                  ),
                ),
              );
            },
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(.08),
                    blurRadius: 10,
                  )
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    item["icon"],
                    width: 50,
                    color: Color(0xFF0262EC),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    item["title"],
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  )
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
