import 'package:flutter/material.dart';

class LawTypeDetailPage extends StatelessWidget {
  final dynamic data;

  const LawTypeDetailPage({super.key, this.data});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(data["title"]),
        backgroundColor: const Color(0xFF0262EC),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [

            /// HEADER
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(30),
              color: const Color(0xFF0262EC),
              child: Column(
                children: [
                  Image.asset(
                    data["icon"],
                    width: 70,
                    color: Colors.white,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    data["title"],
                    style: const TextStyle(
                      fontSize: 22,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            /// DESCRIPTION
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                data["desc"],
                style: const TextStyle(fontSize: 16),
              ),
            ),

            const SizedBox(height: 30),

            /// BUTTON
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0262EC),
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: () {},
                child: const Text(
                  "ปรึกษาทนายในหมวดนี้",
                  style: TextStyle(fontSize: 16),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
