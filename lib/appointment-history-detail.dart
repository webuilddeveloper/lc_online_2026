import 'package:flutter/material.dart';
import 'package:LawyerOnline/component/appbar.dart';

class AppointmentHistoryDetail extends StatelessWidget {
  final dynamic model;

  const AppointmentHistoryDetail({super.key, required this.model});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEEF2F5),
      appBar: appBar(
        title: "รายละเอียดนัดหมาย",
        backBtn: true,
        rightBtn: false,
        backAction: () => Navigator.pop(context),
        rightAction: () {},
      ),
      body: Padding(
        padding: const EdgeInsets.all(25),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
              color: Colors.white, borderRadius: BorderRadius.circular(20)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                model['name'],
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Text("ประเภทคดี : ${model['caseType']}"),
              const SizedBox(height: 5),
              Text(
                  "วันนัดหมาย : ${model['appointmentDate']} ${model['appointmentTime']}"),
              const SizedBox(height: 20),
              const Text(
                "รายละเอียด",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Text(model['details']),
              // const Spacer(),
              // Row(
              //   children: [
              //     Expanded(
              //       child: ElevatedButton.icon(
              //         icon: const Icon(Icons.chat),
              //         label: const Text("แชท"),
              //         onPressed: () {},
              //       ),
              //     ),
              //     const SizedBox(width: 10),
              //     Expanded(
              //       child: ElevatedButton.icon(
              //         icon: const Icon(Icons.video_call),
              //         label: const Text("Video Call"),
              //         onPressed: () {},
              //       ),
              //     ),
              //   ],
              // )
            ],
          ),
        ),
      ),
    );
  }
}
