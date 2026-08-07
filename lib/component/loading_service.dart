import 'dart:math';
import 'package:flutter/material.dart';
import 'package:LawyerOnline/shared/app_typography.dart';

// ─────────────────────────────────────────────
// App Loading — ใช้ทั่วแอป (สีหลัก #0262EC, Prompt font)
// ─────────────────────────────────────────────
//
//  AppLoadingView()           — โหลดเต็มหน้า / body
//  AppLoadingInline()         — โหลดใน section ย่อย
//  AppLoadingCard()           — การ์ดสำหรับ dialog
//
// ─────────────────────────────────────────────

abstract final class AppLoadingColors {
  static const primary = Color(0xFF0262EC);
  static const text = Color(0xFF1A2340);
  static const muted = Color(0xFF8593A8);
  static const surface = Color(0xFFF2F6FF);
}

/// Ring spinner แบบ modern — ใช้แทน CircularProgressIndicator
class AppRingSpinner extends StatefulWidget {
  final Color color;
  final double size;

  const AppRingSpinner({
    super.key,
    this.color = AppLoadingColors.primary,
    this.size = 48,
  });

  @override
  State<AppRingSpinner> createState() => _AppRingSpinnerState();
}

/// การ์ด loading สำหรับ dialog / overlay
class AppLoadingCard extends StatelessWidget {
  final String message;
  final bool dark;

  const AppLoadingCard({
    super.key,
    required this.message,
    this.dark = false,
  });

  @override
  Widget build(BuildContext context) {
    if (dark) return _DarkLoadingCard(message: message);
    return _LightLoadingCard(message: message);
  }
}

/// Loading เต็มพื้นที่ — ใช้แทน Center(CircularProgressIndicator)
class AppLoadingView extends StatelessWidget {
  final String? message;
  final Color? color;
  final EdgeInsetsGeometry padding;
  final bool expand;
  final bool showDots;

  const AppLoadingView({
    super.key,
    this.message,
    this.color,
    this.padding = const EdgeInsets.all(32),
    this.expand = true,
    this.showDots = true,
  });

  @override
  Widget build(BuildContext context) {
    final accent = color ?? AppLoadingColors.primary;

    final content = Padding(
      padding: padding,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          AppRingSpinner(color: accent, size: 52),
          if (message != null && message!.isNotEmpty) ...[
            const SizedBox(height: 18),
            Text(
              message!,
              textAlign: TextAlign.center,
              style: AppTypography.prompt(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppLoadingColors.muted,
                height: 1.4,
              ),
            ),
          ],
          if (showDots) ...[
            const SizedBox(height: 14),
            DotsLoader(color: accent.withValues(alpha: 0.55), size: 6),
          ],
        ],
      ),
    );

    if (expand) {
      return ColoredBox(
        color: Colors.transparent,
        child: Center(child: content),
      );
    }
    return Center(child: content);
  }
}

/// Loading แบบ inline สำหรับ section / list
class AppLoadingInline extends StatelessWidget {
  final double height;
  final EdgeInsetsGeometry padding;
  final Color? color;
  final double size;

  const AppLoadingInline({
    super.key,
    this.height = 120,
    this.padding = const EdgeInsets.symmetric(vertical: 24),
    this.color,
    this.size = 34,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: SizedBox(
        height: height,
        child: Center(
          child: AppRingSpinner(
            color: color ?? AppLoadingColors.primary,
            size: size,
          ),
        ),
      ),
    );
  }
}

// ── Light / Dark loading cards (used by AppLoadingCard) ──

class _LightLoadingCard extends StatelessWidget {
  final String message;
  const _LightLoadingCard({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 140, maxWidth: 220),
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
        boxShadow: [
          BoxShadow(
            color: AppLoadingColors.primary.withValues(alpha: 0.1),
            blurRadius: 28,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const AppRingSpinner(color: AppLoadingColors.primary, size: 40),
          const SizedBox(height: 14),
          Text(
            message,
            textAlign: TextAlign.center,
            style: AppTypography.prompt(
              fontSize: 13,
              color: AppLoadingColors.muted,
              fontWeight: FontWeight.w500,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Dark card ─────────────────────────────────

class _DarkLoadingCard extends StatelessWidget {
  final String message;
  const _DarkLoadingCard({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 28),
      decoration: BoxDecoration(
        color: const Color(0xFF111111),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const AppRingSpinner(color: Colors.white, size: 48),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              fontSize: 13,
              color: Colors.white.withOpacity(0.5),
              fontWeight: FontWeight.w300,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}


// ── Ring Spinner implementation ───────────────────────

class _AppRingSpinnerState extends State<AppRingSpinner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _rotate;
  late final Animation<double> _sweep;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();

    _rotate = Tween<double>(begin: 0, end: 2 * pi).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.linear),
    );

    _sweep = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.05, end: 0.75), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 0.75, end: 0.05), weight: 50),
    ]).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (_, __) => CustomPaint(
          painter: _RingPainter(
            rotation: _rotate.value,
            sweep: _sweep.value,
            color: widget.color,
          ),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double rotation;
  final double sweep;
  final Color color;

  _RingPainter({
    required this.rotation,
    required this.sweep,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - 6) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    // Track
    canvas.drawArc(
      rect,
      0,
      2 * pi,
      false,
      Paint()
        ..color = color.withValues(alpha: 0.12)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round,
    );

    // Arc
    canvas.drawArc(
      rect,
      rotation,
      sweep * 2 * pi,
      false,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) => true;
}


// ── 3. Dots Loader ────────────────────────────

class DotsLoader extends StatefulWidget {
  final Color color;
  final double size;
  const DotsLoader({
    super.key,
    this.color = AppLoadingColors.primary,
    this.size = 8,
  });

  @override
  State<DotsLoader> createState() => _DotsLoaderState();
}

class _DotsLoaderState extends State<DotsLoader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) => Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(3, (i) {
          final delay = i * 0.15;
          final t = ((_ctrl.value - delay) % 1.0).clamp(0.0, 1.0);
          final scale = t < 0.4
              ? lerpDouble(0.6, 1.0, t / 0.4)!
              : lerpDouble(1.0, 0.6, (t - 0.4) / 0.6)!;
          final opacity = t < 0.4
              ? lerpDouble(0.3, 1.0, t / 0.4)!
              : lerpDouble(1.0, 0.3, (t - 0.4) / 0.6)!;

          return Padding(
            padding: EdgeInsets.symmetric(horizontal: widget.size * 0.4),
            child: Opacity(
              opacity: opacity,
              child: Transform.scale(
                scale: scale,
                child: Container(
                  width: widget.size,
                  height: widget.size,
                  decoration: BoxDecoration(
                    color: widget.color,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

double? lerpDouble(double a, double b, double t) => a + (b - a) * t;
