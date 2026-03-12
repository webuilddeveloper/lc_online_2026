import 'package:LawyerOnline/component/dialog_service.dart';
import 'package:flutter/material.dart';
import 'package:LawyerOnline/component/appbar.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';

class ProfileFormPage extends StatefulWidget {
  const ProfileFormPage({super.key});

  @override
  State<ProfileFormPage> createState() => _ProfileFormPageState();
}

class _ProfileFormPageState extends State<ProfileFormPage>
    with SingleTickerProviderStateMixin {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController emailController = TextEditingController();

  bool isLoading = false;

  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  File? profileImage;
  final ImagePicker picker = ImagePicker();
  final storage = FlutterSecureStorage();

  String userType = "";
  String name = "";
  String imageUrl = '';
  String typeLogin = "";

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 400));

    _scaleAnimation =
        CurvedAnimation(parent: _controller, curve: Curves.elasticOut);
    callRead();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Email Validation
  bool isEmailValid(String email) {
    return RegExp(
            r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+")
        .hasMatch(email);
  }

  /// Phone Validation
  bool isPhoneValid(String phone) {
    return phone.length >= 9;
  }

  Future pickImage() async {
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      setState(() {
        profileImage = File(image.path);
      });
    }
  }

  callRead() async {
    var userType = await storage.read(key: 'userType');
    var imageProfile = await storage.read(key: 'imageUrlSocial');
    var nameProfile = await storage.read(key: 'name');
    var type = await storage.read(key: 'typeLogin');
    setState(() {
      this.userType = userType.toString();
      name = nameProfile.toString();
      imageUrl = imageProfile.toString();
      typeLogin = type.toString();
      nameController.text = name.toString();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEEF2F5),
      appBar: appBarCustom(
        title: "ข้อมูลส่วนตัว",
        backBtn: true,
        backAction: () => goBack(),
        isRightWidget: false,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(15, 20, 15, 100),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(.05),
                  blurRadius: 15,
                  offset: const Offset(0, 6),
                )
              ],
            ),
            child: Column(
              children: [
                /// Profile Image
                GestureDetector(
                  onTap: pickImage,
                  child: Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      CircleAvatar(
                        radius: 45,
                        backgroundColor: const Color(0xFF0262EC),
                        backgroundImage:
                            (typeLogin == 'local' && profileImage == null)
                                ? AssetImage(imageUrl)
                                : profileImage != null
                                    ? FileImage(profileImage!)
                                    : NetworkImage(imageUrl),
                        child: imageUrl != ''
                            ? null
                            : profileImage == null
                                ? const Icon(Icons.person,
                                    size: 45, color: Colors.white)
                                : null,
                      ),
                      // ClipRRect(
                      //   borderRadius: BorderRadius.circular(100),
                      //   child: typeLogin == 'local'
                      //       ? Image.asset(
                      //           imageUrl,
                      //           fit: BoxFit.cover,
                      //           width: 100,
                      //           height: 100,
                      //         )
                      //       : Image.network(
                      //           imageUrl,
                      //           fit: BoxFit.cover,
                      //           width: 100,
                      //           height: 100,
                      //         ),
                      // ),
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(
                          color: Color(0xFF0262EC),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.camera_alt,
                          size: 16,
                          color: Colors.white,
                        ),
                      )
                    ],
                  ),
                ),

                const SizedBox(height: 25),
                textField(
                  title: "ชื่อ - นามสกุล",
                  controller: nameController,
                  icon: Icons.person_outline,
                ),

                const SizedBox(height: 15),

                textField(
                  title: "เบอร์โทรศัพท์",
                  controller: phoneController,
                  icon: Icons.phone_outlined,
                ),

                const SizedBox(height: 15),

                textField(
                  title: "อีเมล",
                  controller: emailController,
                  icon: Icons.email_outlined,
                ),

                const SizedBox(height: 25),

                saveButton(),
              ],
            ),
          )
        ],
      ),
    );
  }

  /// TEXT FIELD
  Widget textField({
    required String title,
    required TextEditingController controller,
    required IconData icon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 13,
            color: Color(0xFF0262EC),
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: Colors.grey),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFECEDF0)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFECEDF0)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF0262EC)),
            ),
            fillColor: const Color(0xFFFAFAFA),
            filled: true,
          ),
        ),
      ],
    );
  }

  /// SAVE BUTTON
  Widget saveButton() {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () async {
        if (nameController.text.isEmpty ||
            phoneController.text.isEmpty ||
            emailController.text.isEmpty) {
          // showError("กรุณากรอกข้อมูลให้ครบ");
          DialogService.showError(
            context,
            title: "กรุณากรอกข้อมูลให้ครบ",
            message: "",
          );
          return;
        }

        if (!isPhoneValid(phoneController.text)) {
          DialogService.showError(
            context,
            title: "เบอร์โทรไม่ถูกต้อง",
            message: "",
          );
          return;
        }

        if (!isEmailValid(emailController.text)) {
          DialogService.showError(
            context,
            title: "อีเมลไม่ถูกต้อง",
            message: "",
          );
          return;
        }

        setState(() {
          isLoading = true;
        });

        await Future.delayed(const Duration(seconds: 1));

        setState(() {
          isLoading = false;
        });

        DialogService.showSuccess(
          context,
          title: "บันทึกข้อมูลแล้ว",
          message: "ระบบได้บันทึกข้อมูลเรียบร้อยแล้ว",
          onClose: () {
            Navigator.pop(context);
          },
        );
      },
      child: Container(
        height: 50,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: Color(0xFF0262EC),
          // gradient: const LinearGradient(
          //   colors: [
          //     Color(0xFF0262EC),
          //     Color(0xFF4DA3FF),
          //   ],
          // ),
        ),
        child: Center(
          child: isLoading
              ? const CircularProgressIndicator(color: Colors.white)
              : const Text(
                  "บันทึกข้อมูล",
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16),
                ),
        ),
      ),
    );
  }

  void showError(String msg) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text("แจ้งเตือน"),
          content: Text(msg),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("ตกลง"),
            )
          ],
        );
      },
    );
  }

  void goBack() {
    Navigator.pop(context);
  }
}
