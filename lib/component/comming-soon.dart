import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class ComingSoonPage extends StatelessWidget {
  final String title;
  final String description;
  final String lottieUrl;
  final List<Widget>? actions;

  const ComingSoonPage({
    super.key,
    this.title = "Coming Soon",
    this.description = "ฟีเจอร์นี้กำลังอยู่ในระหว่างการพัฒนา",
    required this.lottieUrl,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEEF2F5),
      body: Center(
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.fromLTRB(15, 40, 15, 40),
          children: [
            /// Card
            Container(
              padding: const EdgeInsets.all(25),
              decoration: BoxDecoration(
                // color: Colors.white,
                borderRadius: BorderRadius.circular(22),
                // boxShadow: [
                //   BoxShadow(
                //     color: Colors.black.withOpacity(.05),
                //     blurRadius: 15,
                //     offset: const Offset(0, 6),
                //   )
                // ],
              ),
              child: Column(
                children: [
                  /// Animation
                  Lottie.network(
                    lottieUrl,
                    height: 200,
                  ),

                  const SizedBox(height: 20),

                  /// Icon style เดียวกับ AboutUs
                  // Container(
                  //   width: 70,
                  //   height: 70,
                  //   decoration: BoxDecoration(
                  //     color: const Color(0xFF0262EC),
                  //     borderRadius: BorderRadius.circular(18),
                  //   ),
                  //   child: const Icon(
                  //     Icons.construction,
                  //     color: Colors.white,
                  //     size: 35,
                  //   ),
                  // ),

                  // const SizedBox(height: 20),

                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 10),

                  Text(
                    description,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 14,
                      height: 1.6,
                      color: Colors.black87,
                    ),
                  ),

                  const SizedBox(height: 25),

                  if (actions != null)
                    Wrap(
                      spacing: 12,
                      runSpacing: 10,
                      alignment: WrapAlignment.center,
                      children: actions!,
                    ),
                  const SizedBox(height: 25),

                  SizedBox(
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.zero,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: () => Navigator.pop(context),
                      child: Ink(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Color(0xFF2563EB),
                              Color(0xFF3B82F6),
                            ],
                          ),
                          borderRadius: BorderRadius.all(Radius.circular(14)),
                        ),
                        child: const Center(
                          child: Text(
                            "ย้อนกลับ",
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
