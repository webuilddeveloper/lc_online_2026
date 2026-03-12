import 'package:LawyerOnline/change-password.dart';
import 'package:LawyerOnline/component/comming-soon.dart';
import 'package:LawyerOnline/component/dialog_service.dart';
import 'package:LawyerOnline/menu.dart';
import 'package:LawyerOnline/shared/apple_firebase.dart';
import 'package:LawyerOnline/shared/line.dart';
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
              bottom: false,
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
                                      builder: (context) =>
                                          const ChangePasswordPage(),
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

                          //  Divider
                          const Row(
                            children: [
                              Expanded(child: Divider()),
                              Padding(
                                padding: EdgeInsets.symmetric(horizontal: 10),
                                child: Text("หรือ"),
                              ),
                              Expanded(child: Divider()),
                            ],
                          ),

                          const SizedBox(height: 20),

                          /// Demo user
                          Center(
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: [
                                  socialItem(
                                      icon: "assets/icons/facebook.png",
                                      action: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                const ComingSoonPage(
                                              title: "Comming Soon",
                                              lottieUrl:
                                                  "https://assets7.lottiefiles.com/packages/lf20_kkflmtur.json",
                                            ),
                                          ),
                                        );
                                      }),
                                  const SizedBox(width: 15),
                                  // socialItem(
                                  //     icon: "assets/icons/ig.png",
                                  //     action: () {}),
                                  // const SizedBox(width: 15),
                                  // socialItem(
                                  //     icon: "assets/icons/x.png",
                                  //     action: () {}),
                                  // const SizedBox(width: 15),
                                  socialItem(
                                      icon: "assets/icons/apple.png",
                                      action: () {
                                        // pressApple();

                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                const ComingSoonPage(
                                              title: "Comming Soon",
                                              lottieUrl:
                                                  "https://assets7.lottiefiles.com/packages/lf20_kkflmtur.json",
                                            ),
                                          ),
                                        );
                                      }),
                                  const SizedBox(width: 15),
                                  socialItem(
                                      icon: "assets/icons/google.png",
                                      action: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                const ComingSoonPage(
                                              title: "Comming Soon",
                                              lottieUrl:
                                                  "https://assets7.lottiefiles.com/packages/lf20_kkflmtur.json",
                                            ),
                                          ),
                                        );
                                      }),
                                  const SizedBox(width: 15),
                                  socialItem(
                                    icon: "assets/icons/line.png",
                                    isLine: true,
                                    action: () {
                                      pressLine();
                                    },
                                  ),
                                  const SizedBox(width: 15),
                                  socialItem(
                                    icon: "assets/icons/thaiid.png",
                                    isThaiid: true,
                                    action: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              const ComingSoonPage(
                                            title: "Comming Soon",
                                            lottieUrl:
                                                "https://assets7.lottiefiles.com/packages/lf20_kkflmtur.json",
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ),
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

  Widget socialItem(
      {String? icon,
      Function? action,
      bool isLine = false,
      bool isThaiid = false}) {
    return GestureDetector(
      onTap: () => action?.call(),
      child: Container(
        width: 42,
        height: 42,
        alignment: Alignment.center,
        // padding: const EdgeInsets.symmetric(
        //   horizontal: 12,
        //   vertical: 10,
        // ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16.8),
          border: Border.all(
            width: 1,
            color: const Color(0xFFDBDBDB),
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Image.asset(
            icon ?? '',
            width: isThaiid
                ? 42
                : isLine
                    ? 25
                    : 18,
            height: isThaiid
                ? 42
                : isLine
                    ? 25
                    : 18,
          ),
        ),
      ),
    );
  }

  pressLine() async {
    try {
      // เรียก LINE LOGIN ก่อน
      var obj = await loginLine();

      // เมื่อกลับมาที่แอพแล้วค่อยโชว์ Loading
      DialogService.showLoading(context);

      final idToken = obj.accessToken.idToken;
      final userEmail = (idToken != null) ? idToken['email'] ?? '' : '';

      if (obj != null) {
        var model = {
          "username": (userEmail != '') ? userEmail : obj.userProfile!.userId,
          "email": userEmail,
          "imageUrl": (obj.userProfile!.pictureUrl != '')
              ? obj.userProfile!.pictureUrl
              : '',
          "firstName": obj.userProfile!.displayName,
          "lastName": '',
          "lineID": obj.userProfile!.userId
        };

        await storage.write(
          key: 'categorySocial',
          value: 'Line',
        );

        await storage.write(
          key: 'userType',
          value: 'user',
        );

        await storage.write(
          key: 'imageUrlSocial',
          value: (obj.userProfile!.pictureUrl != '')
              ? obj.userProfile!.pictureUrl
              : '',
        );

        await storage.write(
          key: 'name',
          value: '${model['firstName']} ${model['lastName']}',
        );

        await storage.write(
          key: 'typeLogin',
          value: 'social',
        );

        // ปิด Loading
        Navigator.pop(context);

        await Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => MenuPage(),
          ),
        );
      } else {
        DialogService.showError(
          context,
          title: "เข้าสู่ระบบไม่สำเร็จ",
          message: "กรุณาลองใหม่อีกครั้ง\nหรือเลือกเข้าสู่ระบบช่องทางอื่นแทน",
        );
      }
    } catch (e) {
      DialogService.showError(
        context,
        title: "เข้าสู่ระบบไม่สำเร็จ",
        message: "กรุณาลองใหม่อีกครั้ง\nหรือเลือกเข้าสู่ระบบช่องทางอื่นแทน",
      );
    }
  }

  pressApple() async {
    var obj = await signInWithApple();
    var model = {
      "username": obj!.user?.email ?? obj.user?.uid,
      "email": obj.user?.email ?? '',
      "imageUrl": '',
      "firstName": obj.user?.email,
      "lastName": '',
      "appleID": obj.user?.uid
    };
    print(
        "---------------------------------------------------------------------");
    print(model);
    print(
        "---------------------------------------------------------------------");
    // Dio dio = Dio();
    // var response = await dio.post(
    //   '${server}m/v2/register/apple/login',
    //   data: model,
    // );
    // createStorageApp(
    //   model: response.data['objectData'],
    //   category: 'apple',
    // );
    // if (obj != null) {
    //   Navigator.pushReplacement(
    //     context,
    //     MaterialPageRoute(
    //       builder: (context) => MenuV4(),
    //     ),
    //   );
    // }
  }

  login() async {
    if (usernameController.text == "lawyer" &&
        passwordController.text == "lawyer") {
      await storage.write(key: 'userType', value: 'lawyer');
      await storage.write(
        key: 'name',
        value: 'ศักดิ์สิทธิ์ พิพากษ์',
      );
      await storage.write(
        key: 'imageUrlSocial',
        value: 'assets/images/lawyer-avatar-1.png',
      );
      await storage.write(
        key: 'typeLogin',
        value: 'local',
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => MenuPage(userType: "lawyer"),
        ),
      );
    } else if (usernameController.text == "user" &&
        passwordController.text == "user") {
      await storage.write(key: 'userType', value: 'user');
      await storage.write(
        key: 'name',
        value: 'ออกแบบ ทดลอง',
      );
      await storage.write(
        key: 'imageUrlSocial',
        value: 'assets/images/profile-avatar.jpg',
      );
      await storage.write(
        key: 'typeLogin',
        value: 'local',
      );
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
