import 'dart:async';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

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
          buttonText: "ตกลง",
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
      bool isBtn = false}) {
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
          buttonText: "ปิด",
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

  /// CONFIRM
  static showConfirm(BuildContext context,
      {String title = "ยืนยัน", String message = "", Function()? onConfirm}) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.all(25),
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
                          side: const BorderSide(
                              color: Color(0xFF0262EC), width: 1),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(100),
                          ),
                        ),
                        onPressed: () => Navigator.pop(context),
                        child: const Text(
                          "ยกเลิก",
                          style: TextStyle(color: Color(0xFF0262EC)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0262EC),
                        ),
                        onPressed: () {
                          Navigator.pop(context);
                          if (onConfirm != null) onConfirm();
                        },
                        child: const Text(
                          "ยืนยัน",
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    )
                  ],
                )
              ],
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
        padding: const EdgeInsets.all(25),
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
                        const Text(
                          'กำลังเปลี่ยนเส้นทางอัตโนมัติ',
                          style: TextStyle(
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

  const _AutoCloseDialogContent(
      {required this.animationUrl,
      required this.title,
      required this.message,
      required this.seconds,
      required this.buttonColor,
      required this.onClose,
      this.isBtn = true});

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
      buttonText: "ตกลง",
      buttonColor: widget.buttonColor,
      onPressed: widget.onClose,
      isShowButton: widget.isBtn,
      countdownBadge: _buildBadge(),
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
