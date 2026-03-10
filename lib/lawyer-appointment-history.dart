import 'package:LawyerOnline/appointment-history-detail.dart';
import 'package:flutter/material.dart';
import 'package:LawyerOnline/component/appbar.dart';
import 'appointment-details.dart';

class LawyerAppointmentHistoryPage extends StatefulWidget {
  const LawyerAppointmentHistoryPage({super.key});

  @override
  State<LawyerAppointmentHistoryPage> createState() => _LawyerAppointmentHistoryState();
}

class _LawyerAppointmentHistoryState extends State<LawyerAppointmentHistoryPage> {
  List<dynamic> lawyerOnlineList = [
    {
      "code": "0",
      "name": "ศักดิ์สิทธิ์ พิพากษ์",
      "imageUrl": "assets/images/lawyer-avatar-1.png",
      "caseType": "คดีมรดกทุกประเภท",
      "subCaseType": "ฟ้องร้องมรดก",
      "appointmentDate": "28/03/2026",
      "appointmentTime": "11.00 - 14.00",
      "createDate": "01/02/2026",
      "status": "1",
      "statusText": "ยืนยันการจอง",
      "title": "ขอฟ้องร้องมรดกพี่น้อง ครั้งที่ 2",
      "details":
          "ต้องการฟ้องร้องพี่น้องที่โกงเงินมรดกอย่าตั้งใจเป็นเวลานานไม่แบ่งใครเป็นมรดก"
    },
    {
      "code": "1",
      "name": "ธนากร นิติศักดิ์",
      "imageUrl": "assets/images/lawyer-avatar-2.png",
      "caseType": "คดีมรดกทุกประเภท",
      "subCaseType": "ฟ้องร้องมรดก",
      "appointmentDate": "28/03/2026",
      "appointmentTime": "11.00 - 14.00",
      "createDate": "05/02/2026",
      "status": "0",
      "statusText": "รอการยืนยัน",
      "title": "ขอฟ้องร้องมรดกพี่น้อง ครั้งที่ 2",
      "details":
          "ต้องการฟ้องร้องพี่น้องที่โกงเงินมรดกอย่าตั้งใจเป็นเวลานานไม่แบ่งใครเป็นมรดก"
    }
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEEF2F5),
      appBar: appBar(
        title: "ประวัตินัดหมาย",
        backBtn: true,
        rightBtn: false,
        backAction: () => goBack(),
        rightAction: () {},
      ),
      body: Column(
        children: [
          Expanded(child: _buildAppointmentList()),
        ],
      ),
    );
  }

  _buildAppointmentList() {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 20),
      itemCount: lawyerOnlineList.length,
      itemBuilder: (context, index) => _appointmentItem(
        lawyerOnlineList[index],
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AppointmentHistoryDetail(
                model: lawyerOnlineList[index],
              ),
            ),
          );
        },
      ),
      separatorBuilder: (context, index) => const SizedBox(height: 15),
    );
  }

  _appointmentItem(dynamic model, {Function? onTap}) {
    return GestureDetector(
      onTap: () => onTap!(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: IntrinsicHeight(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              /// HEADER
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  /// Avatar
                  ClipRRect(
                    borderRadius: BorderRadius.circular(100),
                    child: Image.asset(
                      model['imageUrl'],
                      height: 50,
                      width: 50,
                      fit: BoxFit.cover,
                    ),
                  ),

                  const SizedBox(width: 15),

                  /// Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [

                        Text(
                          model['name'],
                          style: const TextStyle(
                              fontSize: 14, fontWeight: FontWeight.w600),
                        ),

                        Text(
                          model['caseType'],
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color.fromARGB(255, 109, 109, 111),
                          ),
                        ),

                        const SizedBox(height: 3),

                        Text(
                          "${model['appointmentDate']}  ${model['appointmentTime']}",
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color.fromARGB(255, 109, 109, 111),
                          ),
                        ),
                      ],
                    ),
                  ),

                  /// STATUS
                  Row(
                    children: [
                      Container(
                        width: 9,
                        height: 9,
                        decoration: BoxDecoration(
                          color: model['status'] == '0'
                              ? const Color.fromARGB(255, 240, 216, 39)
                              : model['status'] == '1'
                                  ? const Color.fromARGB(255, 255, 132, 9)
                                  : model['status'] == '2'
                                      ? const Color(0xFF34C759)
                                      : Colors.red,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        model['statusText'] ?? '',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 10),

              /// TITLE
              Text(
                model['title'],
                style: const TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w500),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),

              const SizedBox(height: 6),

              /// DETAILS
              Text(
                model['details'],
                style: const TextStyle(fontSize: 14),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void goBack() {
    Navigator.pop(context);
  }
}