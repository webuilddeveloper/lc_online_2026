import 'package:LawyerOnline/component/dialog_service.dart';
import 'package:flutter/material.dart';
import 'package:LawyerOnline/component/appbar.dart';
import 'package:lottie/lottie.dart';

class ChangePasswordPage extends StatefulWidget {
  const ChangePasswordPage({super.key});

  @override
  State<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();

  bool hidePassword = true;
  bool hideConfirmPassword = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEEF2F5),
      appBar: appBarCustom(
        title: "เปลี่ยนรหัสผ่าน",
        backBtn: true,
        backAction: () => goBack(),
        isRightWidget: false,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(.08),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                )
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 10),
                passwordField(
                  title: "รหัสผ่านใหม่",
                  hint: "กรุณากรอกรหัสผ่านใหม่",
                  controller: passwordController,
                  hide: hidePassword,
                  toggle: () {
                    setState(() {
                      hidePassword = !hidePassword;
                    });
                  },
                ),
                const SizedBox(height: 20),
                passwordField(
                  title: "ยืนยันรหัสผ่านใหม่",
                  hint: "กรุณากรอกยืนยันรหัสผ่านใหม่",
                  controller: confirmPasswordController,
                  hide: hideConfirmPassword,
                  toggle: () {
                    setState(() {
                      hideConfirmPassword = !hideConfirmPassword;
                    });
                  },
                ),
                const SizedBox(height: 30),
                changePasswordButton(),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget passwordField(
      {String title = "",
      String? hint = "",
      TextEditingController? controller,
      bool hide = true,
      Function()? toggle}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Color(0xFF0262EC)),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          obscureText: hide,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            filled: true,
            fillColor: const Color(0xFFF7F8FA),
            suffixIcon: IconButton(
              icon: Icon(
                hide ? Icons.visibility_off : Icons.visibility,
                color: Colors.grey,
              ),
              onPressed: toggle,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ],
    );
  }

  Widget changePasswordButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF0262EC),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          elevation: 2,
        ),
        onPressed: () {
          if (passwordController.text.isEmpty ||
              confirmPasswordController.text.isEmpty) {
            showDialog(
              context: context,
              builder: (context) => const AlertDialog(
                content: Text("กรุณากรอกรหัสผ่านให้ครบ"),
              ),
            );

            return;
          }

          if (passwordController.text != confirmPasswordController.text) {
            showDialog(
              context: context,
              builder: (context) => const AlertDialog(
                content: Text("รหัสผ่านไม่ตรงกัน"),
              ),
            );

            return;
          }

          DialogService.showSuccess(
            context,
            title: "เปลี่ยนรหัสผ่านสำเร็จ",
            message: "ระบบได้บันทึกรหัสผ่านใหม่เรียบร้อยแล้ว",
            onClose: () {
              Navigator.pop(context);
            },
          );
        },
        child: const Text(
          "เปลี่ยนรหัสผ่าน",
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  void goBack() {
    Navigator.pop(context, false);
  }
}
