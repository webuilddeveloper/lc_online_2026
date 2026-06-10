import 'dart:async';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:LawyerOnline/shared/responsive/responsive_values.dart';
import 'package:easy_localization/easy_localization.dart';

class DialogService {
  /// SUCCESS
  static showSuccess(BuildContext context,
      {String title = "สำเร็จ", String message = "", Function()? onClose}) {
    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierLabel: "success",
      barrierColor: Colors.black.withOpacity(.4),
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, animation, secondaryAnimation) {
        return _dialogLayout(
          context,
          animationUrl:
              "https://assets10.lottiefiles.com/packages/lf20_jbrw3hcz.json",
          title: title,
          message: message,
          buttonText: "ok".tr(),
          buttonColor: const Color(0xFF0262EC),
          onPressed: () {
            Navigator.pop(context);
            if (onClose != null) onClose();
          },
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return Transform.scale(
          scale: Curves.easeOutBack.transform(animation.value),
          child: child,
        );
      },
    );
  }

  /// ✅ SUCCESS + AUTO CLOSE พร้อม countdown
  static showAutoClose(BuildContext context,
      {String title = "สำเร็จ",
      String message = "",
      int seconds = 5,
      String animationUrl =
          "https://assets10.lottiefiles.com/packages/lf20_jbrw3hcz.json",
      Color buttonColor = const Color(0xFF0262EC),
      Function()? onClose,
      bool isBtn = true}) {
    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierLabel: "autoClose",
      barrierColor: Colors.black.withOpacity(.4),
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (ctx, animation, secondaryAnimation) {
        return _AutoCloseDialogContent(
          animationUrl: animationUrl,
          title: title,
          message: message,
          seconds: seconds,
          buttonColor: buttonColor,
          isBtn: isBtn,
          isShowCountdown: false,
          onClose: () {
            Navigator.pop(ctx);
            if (onClose != null) onClose();
          },
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return Transform.scale(
          scale: Curves.easeOutBack.transform(animation.value),
          child: child,
        );
      },
    );
  }

  /// ERROR
  static showError(BuildContext context,
      {String title = "เกิดข้อผิดพลาด", String message = ""}) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: "error",
      barrierColor: Colors.black.withOpacity(.4),
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, animation, secondaryAnimation) {
        return _dialogLayout(
          context,
          animationUrl:
              "https://assets6.lottiefiles.com/packages/lf20_bhw1ul4g.json",
          title: title,
          message: message,
          buttonText: "close".tr(),
          buttonColor: const Color(0xFF0262EC),
          onPressed: () => Navigator.pop(context),
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return Transform.scale(
          scale: Curves.easeOutBack.transform(animation.value),
          child: child,
        );
      },
    );
  }

  /// CONFIRM DELETE ACCOUNT
  static showConfirmDeleteAccount(BuildContext context,
      {required Function(String) onConfirm}) {
    final TextEditingController passwordController = TextEditingController();
    bool obscureText = true;
    String? errorMsg;

    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.5),
      builder: (BuildContext context) {
        return StatefulBuilder(builder: (context, setState) {
          return Dialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            insetPadding:
                const EdgeInsets.symmetric(horizontal: 30, vertical: 24),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: RV.dialogMaxWidth(context),
                minWidth: RV.dialogMinWidth(context),
              ),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 25, vertical: 35),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.delete_outline_rounded,
                      size: 60,
                      color: Colors.red,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      "confirmDeleteTitle".tr(),
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      "confirmDeleteDesc".tr(),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      controller: passwordController,
                      obscureText: obscureText,
                      onChanged: (val) {
                        if (errorMsg != null) setState(() => errorMsg = null);
                      },
                      decoration: InputDecoration(
                        hintText: 'passwordPlaceholder'.tr(),
                        errorText: errorMsg,
                        prefixIcon:
                            const Icon(Icons.lock_outline, color: Colors.grey),
                        suffixIcon: IconButton(
                          icon: Icon(
                              obscureText
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                              color: Colors.grey),
                          onPressed: () {
                            setState(() {
                              obscureText = !obscureText;
                            });
                          },
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 16),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                              color: errorMsg != null
                                  ? Colors.red
                                  : const Color(0xFFECEDF0)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                              color: errorMsg != null
                                  ? Colors.red
                                  : const Color(0xFFECEDF0)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: errorMsg != null
                                ? Colors.red
                                : const Color(0xFF0262EC),
                            width: 1.5,
                          ),
                        ),
                        fillColor: errorMsg != null
                            ? Colors.red.withOpacity(0.04)
                            : const Color(0xFFFAFAFA),
                        filled: true,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size(0, 55),
                              side: const BorderSide(
                                  color: Color(0xFF0262EC), width: 1),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(100),
                              ),
                            ),
                            onPressed: () => Navigator.pop(context),
                            child: Text(
                              "cancel".tr(),
                              style: const TextStyle(
                                color: Color(0xFF0262EC),
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              minimumSize: const Size(0, 55),
                              backgroundColor: const Color(0xD2FF0000),
                            ),
                            onPressed: () {
                              if (passwordController.text.trim().isEmpty) {
                                setState(() => errorMsg = "กรุณากรอกรหัสผ่าน");
                                return;
                              }
                              Navigator.pop(context);
                              onConfirm(passwordController.text.trim());
                            },
                            child: Text(
                              "deleteAccount".tr(),
                              style: const TextStyle(
                                color: Color(0xFFFFFFFF),
                                fontSize: 16,
                              ),
                            ),
                          ),
                        )
                      ],
                    )
                  ],
                ),
              ),
            ),
          );
        });
      },
    );
  }

  /// CONFIRM
  static showConfirm(BuildContext context,
      {String title = "ยืนยัน", String message = "", Function()? onConfirm}) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          insetPadding:
              const EdgeInsets.symmetric(horizontal: 30, vertical: 24),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: RV.dialogMaxWidth(context),
              minWidth: RV.dialogMinWidth(context),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 35),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.help_outline,
                    size: 60,
                    color: Colors.orange,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    title,
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    message,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(0, 55),
                            side: const BorderSide(
                                color: Color(0xFF0262EC), width: 1),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(100),
                            ),
                          ),
                          onPressed: () => Navigator.pop(context),
                          child: const Text(
                            "ยกเลิก",
                            style: TextStyle(
                              color: Color(0xFF0262EC),
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size(0, 55),
                            backgroundColor: const Color(0xFF0262EC),
                          ),
                          onPressed: () {
                            Navigator.pop(context);
                            if (onConfirm != null) onConfirm();
                          },
                          child: const Text(
                            "ยืนยัน",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      )
                    ],
                  )
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// CONFIRM AcceptJob
  static showConfirmAcceptJob(BuildContext context,
      {String title = "ยืนยัน", String message = "", Function()? onConfirm}) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          insetPadding:
              const EdgeInsets.symmetric(horizontal: 30, vertical: 24),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: RV.dialogMaxWidth(context),
              minWidth: RV.dialogMinWidth(context),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 35),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.help_outline_outlined,
                    size: 60,
                    color: Colors.orange.shade600,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    title,
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    message,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(0, 55),
                            side: const BorderSide(
                                color: Color(0xFF0262EC), width: 1),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(100),
                            ),
                          ),
                          onPressed: () => Navigator.pop(context),
                          child: const Text(
                            "ยกเลิก",
                            style: TextStyle(
                              color: Color(0xFF0262EC),
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size(0, 55),
                            backgroundColor: const Color(0xFF0262EC),
                          ),
                          onPressed: () {
                            Navigator.pop(context);
                            if (onConfirm != null) onConfirm();
                          },
                          child: const Text(
                            "ยืนยัน",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      )
                    ],
                  )
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// CONFIRM RejectJob
  static showConfirmRejectJob(BuildContext context,
      {String title = "ยืนยัน", String message = "", Function()? onConfirm}) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          insetPadding:
              const EdgeInsets.symmetric(horizontal: 30, vertical: 24),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: RV.dialogMaxWidth(context),
              minWidth: RV.dialogMinWidth(context),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 35),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.cancel_outlined,
                    size: 60,
                    color: Color.fromARGB(255, 212, 3, 3),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    title,
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    message,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(0, 55),
                            side: const BorderSide(
                                color: Color(0xFF0262EC), width: 1),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(100),
                            ),
                          ),
                          onPressed: () => Navigator.pop(context),
                          child: const Text(
                            "ยกเลิก",
                            style: TextStyle(
                              color: Color(0xFF0262EC),
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size(0, 55),
                            backgroundColor: const Color(0xFF0262EC),
                          ),
                          onPressed: () {
                            Navigator.pop(context);
                            if (onConfirm != null) onConfirm();
                          },
                          child: const Text(
                            "ยืนยัน",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      )
                    ],
                  )
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// CONFIRM LOGOUT
  static showConfirmLogout(BuildContext context,
      {String title = "ยืนยัน", String message = "", Function()? onConfirm}) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          insetPadding:
              const EdgeInsets.symmetric(horizontal: 30, vertical: 24),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: RV.dialogMaxWidth(context),
              minWidth: RV.dialogMinWidth(context),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 35),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.logout,
                    size: 60,
                    color: Colors.red,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    title,
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    message,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(0, 55),
                            side: const BorderSide(
                                color: Color(0xFF0262EC), width: 1),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(100),
                            ),
                          ),
                          onPressed: () => Navigator.pop(context),
                          child: const Text(
                            "ไม่",
                            style: TextStyle(
                              color: Color(0xFF0262EC),
                              fontSize: 16,

                              // fontWeight: FontWeight.w600
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size(0, 55),
                            backgroundColor: const Color(0xD2FF0000),
                          ),
                          onPressed: () {
                            Navigator.pop(context);
                            if (onConfirm != null) onConfirm();
                          },
                          child: const Text(
                            "ออกจากระบบ",
                            style: TextStyle(
                              color: Color(0xFFFFFFFF),
                              fontSize: 16,
                              // fontWeight: FontWeight.w600
                            ),
                          ),
                        ),
                      )
                    ],
                  )
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// LOADING
  static showLoading(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return const Center(
          child: CircularProgressIndicator(),
        );
      },
    );
  }

  /// COMMON LAYOUT — ใช้ร่วมกันทั้ง showSuccess, showError, showAutoClose
  static Widget _dialogLayout(
    BuildContext context, {
    required String animationUrl,
    required String title,
    required String message,
    required String buttonText,
    required Color buttonColor,
    required Function() onPressed,
    bool isShowButton = true,
    Widget? countdownBadge, // ✅ เพิ่ม optional param สำหรับ countdown
  }) {
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 30),
        constraints: BoxConstraints(
          maxWidth: RV.dialogMaxWidth(context),
          minWidth: RV.dialogMinWidth(context),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 35),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(25),
        ),
        child: Material(
          color: Colors.transparent,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                height: 120,
                child: Lottie.network(animationUrl),
              ),
              const SizedBox(height: 10),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 25),
              isShowButton
                  ? SizedBox(
                      width: double.infinity,
                      height: 45,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: buttonColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        onPressed: onPressed,
                        // ✅ ถ้ามี countdownBadge ให้แสดงข้างๆ ปุ่ม
                        child: countdownBadge == null
                            ? Text(
                                buttonText,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              )
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    buttonText,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  countdownBadge,
                                ],
                              ),
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        countdownBadge!,
                        const SizedBox(width: 10),
                        Text(
                          'redirecting'.tr(),
                          style: const TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
            ],
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════
//  _AutoCloseDialogContent — StatefulWidget จัดการ countdown
// ══════════════════════════════════════════════════════════

class _AutoCloseDialogContent extends StatefulWidget {
  final String animationUrl;
  final String title;
  final String message;
  final int seconds;
  final Color buttonColor;
  final VoidCallback onClose;
  final bool isBtn;
  final bool isShowCountdown;

  const _AutoCloseDialogContent(
      {required this.animationUrl,
      required this.title,
      required this.message,
      required this.seconds,
      required this.buttonColor,
      required this.onClose,
      this.isBtn = true,
      this.isShowCountdown = true});

  @override
  State<_AutoCloseDialogContent> createState() =>
      _AutoCloseDialogContentState();
}

class _AutoCloseDialogContentState extends State<_AutoCloseDialogContent>
    with SingleTickerProviderStateMixin {
  late int _remaining;
  Timer? _timer;
  late AnimationController _progressCtrl;

  @override
  void initState() {
    super.initState();
    _remaining = widget.seconds;

    // AnimationController วิ่ง 1.0 → 0.0 ตลอด duration
    _progressCtrl = AnimationController(
      vsync: this,
      duration: Duration(seconds: widget.seconds),
      value: 1.0,
    )..reverse();

    // นับถอยหลังทุก 1 วินาที
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      setState(() => _remaining--);
      if (_remaining <= 0) {
        t.cancel();
        widget.onClose();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _progressCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DialogService._dialogLayout(
      context,
      animationUrl: widget.animationUrl,
      title: widget.title,
      message: widget.message,
      buttonText: "ok".tr(),
      buttonColor: widget.buttonColor,
      onPressed: widget.onClose,
      isShowButton: widget.isBtn,
      countdownBadge: widget.isShowCountdown ? _buildBadge() : Container(),
    );
  }

  Widget _buildBadge() {
    return AnimatedBuilder(
      animation: _progressCtrl,
      builder: (_, __) => SizedBox(
        width: 28,
        height: 28,
        child: Stack(
          alignment: Alignment.center,
          children: [
            CircularProgressIndicator(
              value: _progressCtrl.value,
              strokeWidth: 2.5,
              backgroundColor: Colors.black.withOpacity(0.35),
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
            ),
            Text(
              '$_remaining',
              style: const TextStyle(
                color: Colors.black,
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
