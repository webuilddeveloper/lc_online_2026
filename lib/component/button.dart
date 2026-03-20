import 'package:flutter/material.dart';

primaryButton({
  required String label,
  required VoidCallback onTap,
  bool enabled = true,
}) {
  return GestureDetector(
    onTap: enabled ? onTap : null,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      height: 54,
      decoration: BoxDecoration(
        gradient: enabled
            ? const LinearGradient(
                colors: [Color(0xFF0262EC), Color(0xFF0485FF)])
            : null,
        color: enabled ? null : const Color(0xFFCDD5E0),
        borderRadius: BorderRadius.circular(16),
        boxShadow: enabled
            ? [
                BoxShadow(
                  color: const Color(0xFF0262EC).withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                )
              ]
            : null,
      ),
      child: Center(
        child: Text(label,
            style: TextStyle(
              color: enabled ? Colors.white : Colors.grey[400],
              fontWeight: FontWeight.w700,
              fontSize: 15,
            )),
      ),
    ),
  );
}
