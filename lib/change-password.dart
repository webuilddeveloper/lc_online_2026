import 'package:LawyerOnline/component/dialog_service.dart';
import 'package:LawyerOnline/services/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:LawyerOnline/component/appbar.dart';
import 'package:LawyerOnline/models/user_profile_store.dart';
import 'package:easy_localization/easy_localization.dart';

class ChangePasswordPage extends StatefulWidget {
  const ChangePasswordPage({super.key});

  @override
  State<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
  final TextEditingController oldPasswordController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();

  bool hideOldPassword = true;
  bool hidePassword = true;
  bool hideConfirmPassword = true;

  String code = "";

  /// สถานะการตรวจสอบรหัสผ่านใหม่
  bool get _isNewPasswordFilled => passwordController.text.isNotEmpty;
  bool get _isConfirmFilled => confirmPasswordController.text.isNotEmpty;
  bool get _isPasswordMatch =>
      _isNewPasswordFilled &&
      _isConfirmFilled &&
      passwordController.text == confirmPasswordController.text;
  bool get _isPasswordMismatch =>
      _isNewPasswordFilled &&
      _isConfirmFilled &&
      passwordController.text != confirmPasswordController.text;

  /// ปุ่มกดได้เมื่อกรอกครบทุกช่อง + รหัสใหม่ตรงกัน
  bool get _isFormValid =>
      oldPasswordController.text.isNotEmpty && _isPasswordMatch;

  @override
  void initState() {
    super.initState();
    _loadUserData();

    // listener สำหรับ real-time validation
    passwordController.addListener(() => setState(() {}));
    confirmPasswordController.addListener(() => setState(() {}));
    oldPasswordController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    oldPasswordController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    final codeProfile = UserProfileStore.instance.code;
    setState(() {
      code = codeProfile;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEEF2F5),
      appBar: appBarCustom(
        title: 'changePasswordTitle'.tr(),
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
                  title: 'oldPassword'.tr(),
                  hint: 'oldPasswordHint'.tr(),
                  controller: oldPasswordController,
                  hide: hideOldPassword,
                  toggle: () {
                    setState(() {
                      hideOldPassword = !hideOldPassword;
                    });
                  },
                ),
                const SizedBox(height: 20),
                passwordField(
                  title: 'newPassword'.tr(),
                  hint: 'newPasswordHint'.tr(),
                  controller: passwordController,
                  hide: hidePassword,
                  borderColor: _getBorderColor(isNewPassword: true),
                  toggle: () {
                    setState(() {
                      hidePassword = !hidePassword;
                    });
                  },
                ),
                const SizedBox(height: 20),
                passwordField(
                  title: 'confirmNewPassword'.tr(),
                  hint: 'confirmNewPasswordHint'.tr(),
                  controller: confirmPasswordController,
                  hide: hideConfirmPassword,
                  borderColor: _getBorderColor(isNewPassword: false),
                  toggle: () {
                    setState(() {
                      hideConfirmPassword = !hideConfirmPassword;
                    });
                  },
                ),

                // ข้อความแจ้งสถานะ
                if (_isPasswordMatch)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Row(
                      children: [
                        const Icon(Icons.check_circle,
                            color: Color(0xFF22C55E), size: 16),
                        const SizedBox(width: 6),
                        Text(
                          'passwordMatch'.tr(),
                          style: const TextStyle(
                            color: Color(0xFF22C55E),
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                if (_isPasswordMismatch)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Row(
                      children: [
                        const Icon(Icons.error,
                            color: Color(0xFFEF4444), size: 16),
                        const SizedBox(width: 6),
                        Text(
                          'passwordMismatch'.tr(),
                          style: const TextStyle(
                            color: Color(0xFFEF4444),
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
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

  /// กำหนดสีกรอบตามสถานะ
  Color? _getBorderColor({required bool isNewPassword}) {
    if (!_isNewPasswordFilled || !_isConfirmFilled) return null;
    if (_isPasswordMatch) return const Color(0xFF22C55E);
    return const Color(0xFFEF4444);
  }

  Widget passwordField({
    String title = "",
    String? hint = "",
    TextEditingController? controller,
    bool hide = true,
    Color? borderColor,
    Function()? toggle,
  }) {
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
              borderSide: borderColor != null
                  ? BorderSide(color: borderColor, width: 2)
                  : BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: borderColor != null
                  ? BorderSide(color: borderColor, width: 2)
                  : BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: borderColor != null
                  ? BorderSide(color: borderColor, width: 2)
                  : const BorderSide(color: Color(0xFF0262EC), width: 2),
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
          backgroundColor:
              _isFormValid ? const Color(0xFF0262EC) : Colors.grey[300],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          elevation: _isFormValid ? 2 : 0,
        ),
        onPressed: _isFormValid ? () => _processChangePassword() : null,
        child: Text(
          'changePasswordButton'.tr(),
          style: TextStyle(
            color: _isFormValid ? Colors.white : Colors.grey[500],
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  /// เรียก API เปลี่ยนรหัสผ่าน
  void _processChangePassword() async {
    DialogService.showLoading(context);

    try {
      await AuthService.changePassword(
        code: code,
        password: oldPasswordController.text,
        newPassword: passwordController.text,
      );

      Navigator.pop(context);

      DialogService.showSuccess(
        context,
        title: 'changePasswordSuccessTitle'.tr(),
        message: 'changePasswordSuccessMessage'.tr(),
        onClose: () {
          Navigator.pop(context);
        },
      );
    } catch (e) {
      Navigator.pop(context);

      final errorMsg = e.toString();
      if (errorMsg.contains('รหัสผ่านไม่ถูกต้อง')) {
        DialogService.showError(
          context,
          title: 'oldPasswordWrongTitle'.tr(),
          message: 'oldPasswordWrongMessage'.tr(),
        );
      } else {
        DialogService.showError(
          context,
          title: 'errorTitle'.tr(),
          message: 'changePasswordErrorMessage'.tr(),
        );
      }
    }
  }

  void goBack() {
    Navigator.pop(context, false);
  }
}
