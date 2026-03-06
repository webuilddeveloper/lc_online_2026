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
              "https://assets10.lottiefiles.com/packages/lf20_jbrw3hcz.json",
          title: title,
          message: message,
          buttonText: "ปิด",
          buttonColor: Colors.red,
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
                        onPressed: () => Navigator.pop(context),
                        child: const Text(
                          "ยกเลิก",
                          style: TextStyle(
                            color: Colors.white
                          ),
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
                          style: TextStyle(
                            color: Colors.white
                          ),
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

  /// COMMON LAYOUT
  static Widget _dialogLayout(
    BuildContext context, {
    required String animationUrl,
    required String title,
    required String message,
    required String buttonText,
    required Color buttonColor,
    required Function() onPressed,
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
                style: const TextStyle(
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 25),
              SizedBox(
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
                  child: Text(
                    buttonText,
                    style: TextStyle(
                            color: Colors.white
                          ),
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
