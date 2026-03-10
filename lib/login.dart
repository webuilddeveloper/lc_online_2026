import 'package:LawyerOnline/change-password.dart';
import 'package:LawyerOnline/component/dialog_service.dart';
import 'package:LawyerOnline/menu.dart';
import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage>
    with SingleTickerProviderStateMixin {
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  final storage = const FlutterSecureStorage();

  bool remember = false;
  bool obscure = true;

  late AnimationController controller;
  late Animation<double> fade;

  @override
  void initState() {
    super.initState();

    controller = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800));

    fade = CurvedAnimation(parent: controller, curve: Curves.easeOut);

    controller.forward();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FadeTransition(
        opacity: fade,
        child: Stack(
          children: [
            /// 🔵 Background
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0xFF0F172A),
                    Color(0xFF1E293B),
                    Color(0xFF334155)
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),

            SafeArea(
              child: Column(
                children: [
                  const SizedBox(height: 40),

                  /// 🔹 Logo
                  const Icon(
                    Icons.gavel,
                    color: Colors.white,
                    size: 60,
                  ),

                  const SizedBox(height: 12),

                  const Text(
                    'หมอความออนไลน์',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),

                  const SizedBox(height: 6),

                  const Text(
                    'ปรึกษากฎหมายได้ทุกที่',
                    style: TextStyle(color: Colors.white70),
                  ),

                  const SizedBox(height: 40),

                  /// 🔹 Login Card
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(30),
                        ),
                        boxShadow: [
                          BoxShadow(
                            blurRadius: 30,
                            color: Colors.black26,
                          )
                        ],
                      ),
                      child: ListView(
                        physics: const BouncingScrollPhysics(),
                        children: [
                          const Text(
                            "เข้าสู่ระบบ",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                            ),
                          ),

                          const SizedBox(height: 30),

                          /// Username
                          TextField(
                            controller: usernameController,
                            decoration: InputDecoration(
                              prefixIcon: const Icon(Icons.person_outline),
                              labelText: "ชื่อผู้ใช้",
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                          ),

                          const SizedBox(height: 16),

                          /// Password
                          TextField(
                            controller: passwordController,
                            obscureText: obscure,
                            decoration: InputDecoration(
                              prefixIcon: const Icon(Icons.lock_outline),
                              labelText: "รหัสผ่าน",
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  obscure
                                      ? Icons.visibility_off
                                      : Icons.visibility,
                                ),
                                onPressed: () {
                                  setState(() {
                                    obscure = !obscure;
                                  });
                                },
                              ),
                            ),
                          ),

                          const SizedBox(height: 12),

                          /// Remember
                          Row(
                            children: [
                              // Checkbox(
                              //   value: remember,
                              //   activeColor: Colors.blue,
                              //   onChanged: (v) {
                              //     setState(() {
                              //       remember = v!;
                              //     });
                              //   },
                              // ),
                              // const Text("Remember me"),
                              const Spacer(),
                              TextButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => ChangePasswordPage(),
                                    ),
                                  );
                                },
                                child: const Text("ลืมรหัสผ่าน"),
                              )
                            ],
                          ),

                          const SizedBox(height: 20),

                          /// 🔹 Login Button
                          SizedBox(
                            height: 50,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                padding: EdgeInsets.zero,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              onPressed: login,
                              child: Ink(
                                decoration: const BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Color(0xFF2563EB),
                                      Color(0xFF3B82F6),
                                    ],
                                  ),
                                  borderRadius:
                                      BorderRadius.all(Radius.circular(14)),
                                ),
                                child: const Center(
                                  child: Text(
                                    "เข้าสู่ระบบ",
                                    style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white),
                                  ),
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 20),

                          /// Divider
                          // Row(
                          //   children: const [
                          //     Expanded(child: Divider()),
                          //     Padding(
                          //       padding: EdgeInsets.symmetric(horizontal: 10),
                          //       child: Text("หรือ"),
                          //     ),
                          //     Expanded(child: Divider()),
                          //   ],
                          // ),

                          // const SizedBox(height: 20),

                          // /// Demo user
                          // const Center(
                          //   child: Text(
                          //     "Demo Login\nlawyer / lawyer\nuser / user",
                          //     textAlign: TextAlign.center,
                          //     style: TextStyle(color: Colors.grey),
                          //   ),
                          // ),
                        ],
                      ),
                    ),
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  login() async {
    if (usernameController.text == "lawyer" &&
        passwordController.text == "lawyer") {
      await storage.write(key: 'userType', value: 'lawyer');

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => MenuPage(userType: "lawyer"),
        ),
      );
    } else if (usernameController.text == "user" &&
        passwordController.text == "user") {
      await storage.write(key: 'userType', value: 'user');

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => MenuPage(userType: "user"),
        ),
      );
    } else {
      // AwesomeDialog(
      //   context: context,
      //   dialogType: DialogType.warning,
      //   title: "ไม่พบผู้ใช้",
      //   desc: "ชื่อผู้ใช้หรือรหัสผ่านไม่ถูกต้อง",
      //   btnOkOnPress: () {},
      // ).show();

      DialogService.showError(
        context,
        title: "ไม่พบผู้ใช้",
        message: "ชื่อผู้ใช้หรือรหัสผ่านไม่ถูกต้อง",
        // onClose: () {
        //   // Navigator.pop(context);
        //   // final navigator = Navigator.of(context);
        //   Navigator.of(context).pushAndRemoveUntil(
        //     MaterialPageRoute(
        //       builder: (context) => MenuPage(),
        //     ),
        //     (Route<dynamic> route) => route.isFirst,
        //   );
        // },
      );
    }
  }
}
