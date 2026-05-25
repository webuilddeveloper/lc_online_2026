import 'package:LawyerOnline/change-password.dart';
import 'package:LawyerOnline/component/comming-soon.dart';
import 'package:LawyerOnline/component/dialog_service.dart';
import 'package:LawyerOnline/component/loading_service.dart';
import 'package:LawyerOnline/menu.dart';
import 'package:LawyerOnline/register_page.dart';
import 'package:LawyerOnline/services/auth_service.dart';
import 'package:LawyerOnline/shared/apple_firebase.dart';
import 'package:LawyerOnline/shared/line.dart';
import 'package:LawyerOnline/shared/notification-service.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:LawyerOnline/models/user_model.dart';
import 'package:LawyerOnline/models/user_profile_store.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:LawyerOnline/shared/responsive/app_layout.dart';
import 'package:LawyerOnline/shared/responsive/res_layout.dart';

class LoginPage extends StatefulWidget {
  final bool isBack;
  LoginPage({super.key, this.isBack = false});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with TickerProviderStateMixin {
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  final storage = const FlutterSecureStorage();

  bool remember = false;
  bool obscure = true;

  late AnimationController controller;
  late Animation<double> fade;

  bool isLoading = false;

  // late final AnimationController _controllerAnimation = AnimationController(
  //   duration: const Duration(seconds: 1),
  //   vsync: this,
  // )..repeat(reverse: true);
  // late final Animation<Offset> _offsetAnimation = Tween<Offset>(
  //   begin: const Offset(2, 0),
  //   end: const Offset(-0.2, 0),
  // ).animate(
  //   CurvedAnimation(
  //     parent: _controllerAnimation,
  //     curve: Curves.elasticOut,
  //   ),
  // );

  late final AnimationController _controllerAnimationCardLogin =
      AnimationController(
    duration: const Duration(milliseconds: 1800),
    vsync: this,
  )..repeat(reverse: true);
  late final Animation<Offset> _animationDialog = Tween<Offset>(
    begin: const Offset(0, 0.7),
    end: const Offset(0, 0),
  ).animate(
    CurvedAnimation(
      parent: _controllerAnimationCardLogin,
      curve: Curves.elasticOut,
    ),
  );

  late final AnimationController _controllerAnimationLoginSocial =
      AnimationController(
    duration: const Duration(milliseconds: 1800),
    vsync: this,
  )..repeat(reverse: true);
  late final Animation<Offset> _animationLoginSocial = Tween<Offset>(
    begin: const Offset(0, -0.7),
    end: const Offset(0, 0),
  ).animate(
    CurvedAnimation(
      parent: _controllerAnimationLoginSocial,
      curve: Curves.elasticOut,
    ),
  );

  // late final Animation<double> _animationDialog = CurvedAnimation(
  //     parent: _controllerAnimationDialog,
  //     curve: Curves.easeInOutBack,
  //     reverseCurve: Curves.elasticIn
  //     );

  @override
  void initState() {
    super.initState();
    controller = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800));
    fade = CurvedAnimation(parent: controller, curve: Curves.easeOut);
    controller.forward();

    Future.delayed(const Duration(milliseconds: 1800), () {
      _controllerAnimationLoginSocial.stop();
      _controllerAnimationCardLogin.stop();
    });
    // Future.delayed(const Duration(seconds: 0), () {
    //   _dialog();
    // });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF061B4A),
      body: FadeTransition(
        opacity: fade,
        child: Container(
          decoration: const BoxDecoration(
            color: Color(0xFF061B4A),
          ),
          child: AppLayout(
            maxWidth: 500,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(15, 15, 15, 0),
                child: ListView(
                  shrinkWrap: ResponsiveLayout.isDesktop(context),
              children: [
                const SizedBox(height: 20),

                /// 🔹 Login Card
                SlideTransition(
                  position: _animationDialog,
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.all(Radius.circular(40)),
                      boxShadow: [
                        BoxShadow(
                          blurRadius: 20,
                          color: Color.fromARGB(146, 0, 0, 0),
                        )
                      ],
                    ),
                    child: Stack(
                      children: [
                        Column(
                          // physics: const BouncingScrollPhysics(),
                          children: [
                            Image.asset(
                              "assets/icons/logo.png",
                              width: 120,
                              height: 120,
                            ),

                            const SizedBox(height: 12),

                            Text(
                              'appTitle'.tr(),
                              style: const TextStyle(
                                color: Colors.black,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1,
                              ),
                              textAlign: TextAlign.center,
                            ),

                            const SizedBox(height: 15),
                            // const Text(
                            //   "เข้าสู่ระบบ",
                            //   textAlign: TextAlign.left,
                            //   style: TextStyle(
                            //     fontSize: 20,
                            //     fontWeight: FontWeight.bold,
                            //   ),
                            // ),

                            // const SizedBox(height: 10),

                            /// Username
                            TextField(
                              controller: usernameController,
                              decoration: InputDecoration(
                                prefixIcon: const Icon(Icons.person_outline),
                                labelText: "username".tr(),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                            ),

                            const SizedBox(height: 15),

                            /// Password
                            TextField(
                              controller: passwordController,
                              obscureText: obscure,
                              decoration: InputDecoration(
                                prefixIcon: const Icon(Icons.lock_outline),
                                labelText: "passwordPlaceholder".tr(),
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

                            const SizedBox(height: 5),

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
                                TextButton(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            const RegisterPage(),
                                      ),
                                    );
                                  },
                                  child: Text("register".tr()),
                                ),
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
                                  child: Text("forgotPassword".tr()),
                                )
                              ],
                            ),

                            const SizedBox(height: 20),

                            /// 🔹 Login Button
                            SizedBox(
                              height: 50,
                              child: GestureDetector(
                                onTap: () {
                                  !isLoading ? login() : null;
                                },
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: isLoading
                                        ? Colors.grey.shade100
                                        : const Color(0xFF2563EB),
                                    // gradient: LinearGradient(
                                    //   colors: [
                                    //     Color(0xFF2563EB),
                                    //     Color(0xFF3B82F6),
                                    //   ],
                                    // ),
                                    borderRadius: const BorderRadius.all(
                                      Radius.circular(14),
                                    ),
                                  ),
                                  child: Center(
                                    child: isLoading
                                        ? const DotsLoader(
                                            color: Color(0xFF0262EC),
                                          )
                                        : Text(
                                            "login".tr(),
                                            style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                                color: isLoading
                                                    ? Colors.grey
                                                    : Colors.white),
                                          ),
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(height: 20),

                            SizedBox(
                              height: 50,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  padding: EdgeInsets.zero,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                                onPressed: () {
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
                                child: Container(
                                  decoration: const BoxDecoration(
                                    color: Color(0xFF040651),
                                    borderRadius:
                                        BorderRadius.all(Radius.circular(14)),
                                  ),
                                  child: Center(
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        // assets/icons/thaiid.png
                                        Image.asset(
                                          'assets/icons/thaiid.png',
                                          width: 42,
                                          height: 42,
                                        ),
                                        const SizedBox(width: 5),
                                        Text(
                                          'loginWithThaiID'.tr(),
                                          style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        widget.isBack
                            ? Positioned(
                                top: 0,
                                left: 0,
                                child: GestureDetector(
                                  onTap: () => goBack(),
                                  child: Container(
                                    // width: 0,
                                    alignment: Alignment.center,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 10,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFAFAFA),
                                      // borderRadius: BorderRadius.circular(22),
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        width: 1,
                                        color: const Color(0xFFDBDBDB),
                                      ),
                                    ),
                                    child: const Icon(
                                      Icons.arrow_back_ios_new,
                                      size: 15,
                                    ),
                                  ),
                                ),
                              )
                            : const SizedBox(),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                Row(
                  children: [
                    const Expanded(child: Divider()),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: Text(
                        'or'.tr(),
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                    const Expanded(child: Divider()),
                  ],
                ),

                const SizedBox(height: 20),

                /// Login Social
                SlideTransition(
                  position: _animationLoginSocial,
                  child: Center(
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
                                    builder: (context) => const ComingSoonPage(
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
                                    builder: (context) => const ComingSoonPage(
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
                                    builder: (context) => const ComingSoonPage(
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
                          // const SizedBox(width: 15),
                          // socialItem(
                          //   icon: "assets/icons/thaiid.png",
                          //   isThaiid: true,
                          //   action: () {
                          //     Navigator.push(
                          //       context,
                          //       MaterialPageRoute(
                          //         builder: (context) =>
                          //             const ComingSoonPage(
                          //           title: "Comming Soon",
                          //           lottieUrl:
                          //               "https://assets7.lottiefiles.com/packages/lf20_kkflmtur.json",
                          //         ),
                          //       ),
                          //     );
                          //   },
                          // ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          ),
          ),
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
          // borderRadius: BorderRadius.circular(16.8),
          shape: BoxShape.circle,
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

      await NotificationService.saveFcmToken(
        await FirebaseMessaging.instance.getToken() ?? '',
      );

      // ── setUser → persist + broadcast ──
      await UserProfileStore.instance.setUser(
        UserModel(
          code: obj.userProfile!.userId,
          userType: 'user',
          firstName: obj.userProfile!.displayName,
          lastName: '',
          email: userEmail.toString(),
          phone: '',
          imageUrl: obj.userProfile!.pictureUrl?.isNotEmpty == true
              ? obj.userProfile!.pictureUrl!
              : '',
          category: 'Line',
          isActive: true,
          status: '',
          prefixName: '',
          facebookID: '',
          googleID: '',
          lineID: obj.userProfile!.userId,
          line: '',
          sex: '',
          address: '',
          idcard: '',
        ),
        typeLogin: 'social',
      );

      if (!mounted) return;
      // ปิด Loading
      Navigator.pop(context);

      await Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => MenuPage(),
        ),
      );
    } catch (e) {
      DialogService.showError(
        context,
        title: "loginFailed".tr(),
        message: "genericError".tr(),
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
    setState(() {
      isLoading = true;
    });

    try {
      final session = await AuthService.loginSession(
        usernameController.text.trim(),
        passwordController.text,
        'guest',
      );
      final user = session.user;
      // ── setUser → persist ทุก field + broadcast ให้ทุก widget ทราบทันที ──
      // ถ้า imageUrl ว่างใช้ default avatar แทน
      final userWithAvatar = user.imageUrl.isNotEmpty
          ? user
          : user.copyWith(imageUrl: 'assets/images/profile-avatar.jpg');

      await UserProfileStore.instance.setUser(
        userWithAvatar,
        typeLogin: 'local',
        authToken: session.token,
      );

      // if (!mounted) return;
      // Navigator.pushReplacement(
      //   context,
      //   MaterialPageRoute(
      //     builder: (_) => MenuPage(userType: user.userType),
      //   ),
      // );
    } catch (error) {
      setState(() {
        isLoading = false;
      });
      DialogService.showError(
        context,
        title: 'loginFailed'.tr(),
        message: error.toString(),
      );
    }
  }

  void goBack() async {
    Navigator.pop(context, false);
  }
}
