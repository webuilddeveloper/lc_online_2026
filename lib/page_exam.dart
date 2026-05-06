import 'package:LawyerOnline/shared/responsive/res_layout.dart';
import 'package:flutter/material.dart';

class PageExam extends StatefulWidget {
  const PageExam({super.key});

  @override
  State<PageExam> createState() => _PageExamState();
}

class _PageExamState extends State<PageExam> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ResponsiveLayout(
        // หน้าจอสำหรับมือถือ
        mobileBody: Container(
          color: Colors.blue[100],
          child: const Center(child: Text('Mobile Layout', style: TextStyle(fontSize: 20))),
        ),
        // หน้าจอสำหรับแท็บเล็ต (ถ้าไม่ใส่จะใช้ mobileBody แทน)
        tabletBody: Container(
          color: Colors.green[100],
          child: const Center(child: Text('Tablet Layout', style: TextStyle(fontSize: 20))),
        ),
        // หน้าจอสำหรับ Desktop/Web
        desktopBody: Container(
          color: Colors.red[100],
          child: const Center(child: Text('Desktop Layout', style: TextStyle(fontSize: 20))),
        ),
      ),
    );
  }
}