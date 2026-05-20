import 'dart:math';
import 'package:flutter/material.dart';

// ─────────────────────────────────────────────
// USAGE EXAMPLES
// ─────────────────────────────────────────────
//
// 1) Ring spinner dialog:
//    LoadingDialog.show(context, message: 'Loading...');
//    await Future.delayed(const Duration(seconds: 2));
//    LoadingDialog.hide(context);
//
// 2) Progress dialog:
//    LoadingDialog.showProgress(context, message: 'Uploading...');
//    // update progress from 0.0 to 1.0
//    LoadingDialog.updateProgress(0.6);
//    LoadingDialog.hide(context);
//
// 3) Inline button:
//    LoadingButton(label: 'Save changes', onPressed: () async { ... })
//
// ─────────────────────────────────────────────

// ── 1. Ring Spinner Dialog ────────────────────

class LoadingDialog {
  static OverlayEntry? _overlay;
  static final _progressNotifier = ValueNotifier<double>(0);

  static void show(
    BuildContext context, {
    String message = 'Loading...',
    bool dark = false,
  }) {
    _overlay?.remove();
    _overlay = OverlayEntry(
      builder: (_) => _LoadingOverlay(message: message, dark: dark),
    );
    Overlay.of(context).insert(_overlay!);
  }

  static void showProgress(
    BuildContext context, {
    String message = 'Uploading...',
  }) {
    _progressNotifier.value = 0;
    _overlay?.remove();
    _overlay = OverlayEntry(
      builder: (_) => _ProgressOverlay(
        message: message,
        progress: _progressNotifier,
      ),
    );
    Overlay.of(context).insert(_overlay!);
  }

  static void updateProgress(double value) {
    _progressNotifier.value = value.clamp(0.0, 1.0);
  }

  static void hide(BuildContext context) {
    _overlay?.remove();
    _overlay = null;
  }
}

// ── Overlay shell ─────────────────────────────

class _LoadingOverlay extends StatelessWidget {
  final String message;
  final bool dark;
  const _LoadingOverlay({required this.message, required this.dark});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withOpacity(0.08),
      child: Center(
        child: dark
            ? _DarkLoadingCard(message: message)
            : _LightLoadingCard(message: message),
      ),
    );
  }
}

// ── Light card ────────────────────────────────

class _LightLoadingCard extends StatelessWidget {
  final String message;
  const _LightLoadingCard({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.black.withOpacity(0.07), width: 0.5),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const _RingSpinner(color: Color(0xFF1A1A1A), size: 48),
          const SizedBox(height: 16),
          Text(
            message,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF888888),
              fontWeight: FontWeight.w400,
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
          const _RingSpinner(color: Colors.white, size: 48),
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

// ── Ring Spinner widget ───────────────────────

class _RingSpinner extends StatefulWidget {
  final Color color;
  final double size;
  const _RingSpinner({required this.color, required this.size});

  @override
  State<_RingSpinner> createState() => _RingSpinnerState();
}

class _RingSpinnerState extends State<_RingSpinner>
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
        ..color = color.withOpacity(0.1)
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

// ── 2. Progress Dialog ────────────────────────

class _ProgressOverlay extends StatelessWidget {
  final String message;
  final ValueNotifier<double> progress;
  const _ProgressOverlay({required this.message, required this.progress});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withOpacity(0.08),
      child: Center(
        child: Container(
          width: 200,
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 28),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.black.withOpacity(0.07),
              width: 0.5,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ValueListenableBuilder<double>(
                valueListenable: progress,
                builder: (_, val, __) => _CircularProgress(value: val),
              ),
              const SizedBox(height: 16),
              Text(
                message,
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF888888),
                  fontWeight: FontWeight.w400,
                ),
              ),
              const SizedBox(height: 14),
              // Linear progress bar
              ValueListenableBuilder<double>(
                valueListenable: progress,
                builder: (_, val, __) => ClipRRect(
                  borderRadius: BorderRadius.circular(1),
                  child: LinearProgressIndicator(
                    value: val,
                    minHeight: 2,
                    backgroundColor: Colors.black.withOpacity(0.07),
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      Color(0xFF1A1A1A),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CircularProgress extends StatelessWidget {
  final double value;
  const _CircularProgress({required this.value});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 72,
      height: 72,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox.expand(
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: value),
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
              builder: (_, v, __) => CircularProgressIndicator(
                value: v,
                strokeWidth: 3,
                backgroundColor: Colors.black.withOpacity(0.07),
                valueColor: const AlwaysStoppedAnimation<Color>(
                  Color(0xFF1A1A1A),
                ),
                strokeCap: StrokeCap.round,
              ),
            ),
          ),
          Text(
            '${(value * 100).round()}%',
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: Color(0xFF1A1A1A),
            ),
          ),
        ],
      ),
    );
  }
}

// ── 3. Dots Loader ────────────────────────────

class DotsLoader extends StatefulWidget {
  final Color color;
  final double size;
  const DotsLoader({
    super.key,
    this.color = const Color(0xFF1A1A1A),
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

// ── 4. Inline Loading Button ──────────────────

class LoadingButton extends StatefulWidget {
  final String label;
  final Future<void> Function() onPressed;
  const LoadingButton({
    super.key,
    required this.label,
    required this.onPressed,
  });

  @override
  State<LoadingButton> createState() => _LoadingButtonState();
}

class _LoadingButtonState extends State<LoadingButton> {
  bool _loading = false;

  Future<void> _handle() async {
    if (_loading) return;
    setState(() => _loading = true);
    try {
      await widget.onPressed();
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _handle,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 11),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(50),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_loading) ...[
              const SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                  strokeWidth: 1.5,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  strokeCap: StrokeCap.round,
                ),
              ),
              const SizedBox(width: 8),
            ],
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 150),
              child: Text(
                _loading ? 'Saving...' : widget.label,
                key: ValueKey(_loading),
                style: const TextStyle(
                  fontSize: 13,
                  color: Colors.white,
                  fontWeight: FontWeight.w400,
                  letterSpacing: 0.2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Demo Screen ───────────────────────────────

class LoadingDemoScreen extends StatelessWidget {
  const LoadingDemoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Loading widgets',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF1A1A1A),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Minimal • Modern • Flutter',
                style: TextStyle(fontSize: 13, color: Color(0xFF888888)),
              ),
              const SizedBox(height: 40),

              // Ring spinner
              _DemoTile(
                label: 'Ring spinner dialog',
                child: ElevatedButton(
                  onPressed: () async {
                    LoadingDialog.show(context, message: 'Loading...');
                    await Future.delayed(const Duration(seconds: 2));
                    if (context.mounted) LoadingDialog.hide(context);
                  },
                  style: _btnStyle(),
                  child: const Text('Show dialog'),
                ),
              ),
              const SizedBox(height: 24),

              // Dark variant
              _DemoTile(
                label: 'Dark variant',
                child: ElevatedButton(
                  onPressed: () async {
                    LoadingDialog.show(
                      context,
                      message: 'Syncing data',
                      dark: true,
                    );
                    await Future.delayed(const Duration(seconds: 2));
                    if (context.mounted) LoadingDialog.hide(context);
                  },
                  style: _btnStyle(),
                  child: const Text('Show dark'),
                ),
              ),
              const SizedBox(height: 24),

              // Progress
              _DemoTile(
                label: 'Progress dialog',
                child: ElevatedButton(
                  onPressed: () async {
                    LoadingDialog.showProgress(
                      context,
                      message: 'Uploading...',
                    );
                    for (int i = 0; i <= 100; i++) {
                      LoadingDialog.updateProgress(i / 100);
                      await Future.delayed(const Duration(milliseconds: 30));
                    }
                    await Future.delayed(const Duration(milliseconds: 300));
                    if (context.mounted) LoadingDialog.hide(context);
                  },
                  style: _btnStyle(),
                  child: const Text('Upload file'),
                ),
              ),
              const SizedBox(height: 24),

              // Dots
              _DemoTile(
                label: 'Dots loader (inline)',
                child: const DotsLoader(),
              ),
              const SizedBox(height: 24),

              // Loading button
              _DemoTile(
                label: 'Inline loading button',
                child: LoadingButton(
                  label: 'Save changes',
                  onPressed: () => Future.delayed(const Duration(seconds: 2)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  ButtonStyle _btnStyle() => ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF1A1A1A),
        foregroundColor: Colors.white,
        elevation: 0,
        textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w400),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 11),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
      );
}

class _DemoTile extends StatelessWidget {
  final String label;
  final Widget child;
  const _DemoTile({required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            letterSpacing: 0.1,
            color: Color(0xFFAAAAAA),
          ),
        ),
        const SizedBox(height: 10),
        child,
      ],
    );
  }
}
