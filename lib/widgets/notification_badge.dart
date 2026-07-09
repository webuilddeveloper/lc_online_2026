import 'package:flutter/material.dart';

class NotificationBadgeDot extends StatelessWidget {
  const NotificationBadgeDot({
    super.key,
    required this.count,
    this.size = 8,
    this.showCount = false,
    this.top,
    this.right,
  });

  final int count;
  final double size;
  final bool showCount;
  final double? top;
  final double? right;

  @override
  Widget build(BuildContext context) {
    if (count <= 0) return const SizedBox.shrink();

    if (showCount) {
      final label = count > 99 ? '99+' : count.toString();
      return Positioned(
        top: top ?? 4,
        right: right ?? 4,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
          constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
          decoration: BoxDecoration(
            color: const Color(0xFFF70C0C),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.white, width: 1.5),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.w700,
              height: 1,
            ),
          ),
        ),
      );
    }

    return Positioned(
      top: top ?? 6,
      right: right ?? 6,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: const Color(0xFFF70C0C),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 1.5),
        ),
      ),
    );
  }
}
