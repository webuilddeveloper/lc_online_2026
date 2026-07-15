import 'dart:async';

import 'package:LawyerOnline/shared/app_typography.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Dialog รับสายวิดีโอ — ชื่อ + รูป + เสียง + สั่น
class IncomingCallDialog extends StatefulWidget {
  final String peerName;
  final String peerImageUrl;
  final VoidCallback onAccept;
  final VoidCallback onDecline;
  final Duration ringTimeout;
  final VoidCallback? onRingTimeout;

  const IncomingCallDialog({
    super.key,
    required this.peerName,
    required this.peerImageUrl,
    required this.onAccept,
    required this.onDecline,
    this.ringTimeout = const Duration(minutes: 2),
    this.onRingTimeout,
  });

  @override
  State<IncomingCallDialog> createState() => _IncomingCallDialogState();
}

class _IncomingCallDialogState extends State<IncomingCallDialog>
    with TickerProviderStateMixin {
  static const _primary = Color(0xFF0262EC);

  late final AnimationController _pulseCtrl;
  late final AnimationController _enterCtrl;
  final _player = AudioPlayer();
  Timer? _vibrateTimer;
  Timer? _ringTimeoutTimer;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
    _enterCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
    )..forward();
    _startRingtone();
    _ringTimeoutTimer = Timer(widget.ringTimeout, () {
      if (!mounted) return;
      unawaited(_stopEffects());
      widget.onRingTimeout?.call();
    });
  }

  Future<void> _startRingtone() async {
    try {
      await _player.setReleaseMode(ReleaseMode.loop);
      await _player.play(AssetSource('incoming_call.mp3'));
    } catch (_) {}
    _vibrateTimer = Timer.periodic(const Duration(milliseconds: 900), (_) {
      HapticFeedback.heavyImpact();
    });
    HapticFeedback.heavyImpact();
  }

  Future<void> _stopEffects() async {
    _vibrateTimer?.cancel();
    _vibrateTimer = null;
    try {
      await _player.stop();
    } catch (_) {}
  }

  @override
  void dispose() {
    _ringTimeoutTimer?.cancel();
    _vibrateTimer?.cancel();
    _pulseCtrl.dispose();
    _enterCtrl.dispose();
    _player.dispose();
    super.dispose();
  }

  Future<void> _handleAccept() async {
    await _stopEffects();
    if (!mounted) return;
    widget.onAccept();
  }

  Future<void> _handleDecline() async {
    await _stopEffects();
    if (!mounted) return;
    widget.onDecline();
  }

  @override
  Widget build(BuildContext context) {
    final name = widget.peerName.trim().isEmpty
        ? 'incomingCall'.tr()
        : widget.peerName.trim();

    return PopScope(
      canPop: false,
      child: Material(
        color: Colors.black.withValues(alpha: 0.55),
        child: SafeArea(
          child: FadeTransition(
            opacity: CurvedAnimation(parent: _enterCtrl, curve: Curves.easeOut),
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.92, end: 1).animate(
                CurvedAnimation(parent: _enterCtrl, curve: Curves.easeOutBack),
              ),
              child: Center(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 28),
                  padding: const EdgeInsets.fromLTRB(24, 32, 24, 28),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [
                      BoxShadow(
                        color: _primary.withValues(alpha: 0.18),
                        blurRadius: 40,
                        offset: const Offset(0, 16),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'incomingCall'.tr(),
                        style: AppTypography.prompt(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF8593A8),
                        ),
                      ),
                      const SizedBox(height: 22),
                      AnimatedBuilder(
                        animation: _pulseCtrl,
                        builder: (_, child) {
                          final t = 0.55 + (_pulseCtrl.value * 0.45);
                          return Container(
                            width: 112,
                            height: 112,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: _primary.withValues(alpha: 0.22 * t),
                                  blurRadius: 28 * t,
                                  spreadRadius: 4 * t,
                                ),
                              ],
                            ),
                            child: child,
                          );
                        },
                        child: Container(
                          width: 96,
                          height: 96,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: _primary, width: 3),
                            color: const Color(0xFFF2F6FF),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: widget.peerImageUrl.trim().isNotEmpty
                              ? CachedNetworkImage(
                                  imageUrl: widget.peerImageUrl.trim(),
                                  fit: BoxFit.cover,
                                  errorWidget: (_, __, ___) =>
                                      const Icon(Icons.person_rounded,
                                          size: 48, color: _primary),
                                )
                              : const Icon(Icons.person_rounded,
                                  size: 48, color: _primary),
                        ),
                      ),
                      const SizedBox(height: 18),
                      Text(
                        name,
                        textAlign: TextAlign.center,
                        style: AppTypography.prompt(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF1A2340),
                          height: 1.25,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'incomingVideoCallHint'.tr(),
                        textAlign: TextAlign.center,
                        style: AppTypography.prompt(
                          fontSize: 13,
                          color: const Color(0xFF8593A8),
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 28),
                      Row(
                        children: [
                          Expanded(
                            child: _ActionBtn(
                              label: 'decline'.tr(),
                              color: const Color(0xFFD32F2F),
                              icon: Icons.call_end_rounded,
                              onTap: _handleDecline,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: _ActionBtn(
                              label: 'accept'.tr(),
                              color: const Color(0xFF2E7D32),
                              icon: Icons.videocam_rounded,
                              onTap: _handleAccept,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final String label;
  final Color color;
  final IconData icon;
  final VoidCallback onTap;

  const _ActionBtn({
    required this.label,
    required this.color,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Column(
            children: [
              Icon(icon, color: Colors.white, size: 26),
              const SizedBox(height: 6),
              Text(
                label,
                style: AppTypography.prompt(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
