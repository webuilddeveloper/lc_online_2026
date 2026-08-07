import 'dart:async';

import 'package:LawyerOnline/services/webrtc_call_session.dart';
import 'package:LawyerOnline/services/webrtc_config.dart';
import 'package:LawyerOnline/services/webrtc_peer_service.dart';
import 'package:LawyerOnline/services/webrtc_pip_channel.dart';
import 'package:LawyerOnline/services/webrtc_system_ui.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

class WebRtcCallPage extends StatefulWidget {
  final String roomCode;
  final String caseCode;
  final String userId;
  final String peerName;
  final String toUserId;
  final bool isInitiator;
  final bool reuseSession;

  const WebRtcCallPage({
    super.key,
    required this.roomCode,
    required this.caseCode,
    required this.userId,
    this.peerName = '',
    this.toUserId = '',
    this.isInitiator = false,
    this.reuseSession = false,
  });

  @override
  State<WebRtcCallPage> createState() => _WebRtcCallPageState();
}

class _WebRtcCallPageState extends State<WebRtcCallPage>
    with WidgetsBindingObserver {
  static const _primary = Color(0xFF0262EC);

  final _session = WebRtcCallSession.instance;
  bool _minimizing = false;
  bool _pipSupported = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    _session.setFullScreenOpen(true);
    WebRtcPipChannel.bind();
    WebRtcPipChannel.onUserLeaveHint = _onUserLeaveHint;
    WebRtcPipChannel.onPipModeChanged = _onPipModeChanged;
    unawaited(_bootstrap());
  }

  Future<void> _bootstrap() async {
    _pipSupported = await WebRtcPipChannel.isSupported();
    if (!widget.reuseSession || !_session.isActive) {
      await _session.start(
        roomCode: widget.roomCode,
        caseCode: widget.caseCode,
        userId: widget.userId,
        peerName: widget.peerName,
        toUserId: widget.toUserId,
        isInitiator: widget.isInitiator,
      );
    } else {
      final local = _session.peer?.localStream;
      if (local != null) _session.attachLocal(local);
    }
    if (mounted) setState(() {});
  }

  void _onUserLeaveHint() {
    if (!_session.isActive || _session.isMinimized.value) return;
    if (_pipSupported) {
      unawaited(WebRtcPipChannel.enterPip());
    }
  }

  void _onPipModeChanged(bool inPip) {
    _session.isSystemPip.value = inPip;
    if (mounted) setState(() {});
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _session.isActive) {
      final remote = _session.remoteRenderer.srcObject;
      final local =
          _session.localRenderer.srcObject ?? _session.peer?.localStream;
      if (remote != null) _session.attachRemote(remote);
      if (local != null) _session.attachLocal(local);
    }
  }

  Future<void> _minimize() async {
    if (_minimizing || !_session.isActive) return;
    _minimizing = true;
    await _session.minimizeToBubble();
  }

  Future<void> _toggleScreenShare() async {
    final peer = _session.peer;
    if (peer == null) return;
    final err = await peer.toggleScreenShare();
    _session.screenSharing.value = peer.isScreenSharing;
    if (!peer.isScreenSharing) {
      final local = peer.localStream;
      if (local != null) _session.attachLocal(local, force: true);
    }
    if (err != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(err)),
      );
    }
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    if (identical(WebRtcPipChannel.onUserLeaveHint, _onUserLeaveHint)) {
      WebRtcPipChannel.onUserLeaveHint = null;
    }
    if (identical(WebRtcPipChannel.onPipModeChanged, _onPipModeChanged)) {
      WebRtcPipChannel.onPipModeChanged = null;
    }
    // Keep call alive when minimizing; only clear full-screen flag.
    if (!_minimizing) {
      _session.setFullScreenOpen(false);
    }
    unawaited(WebRtcSystemUi.restoreAfterCall());
    super.dispose();
  }

  String get _statusText => switch (_session.state.value) {
        WebRtcCallState.waitingPeer => 'webrtcWaitingPeer'.tr(),
        WebRtcCallState.connecting => 'webrtcConnecting'.tr(),
        WebRtcCallState.connected => 'webrtcConnected'.tr(),
        WebRtcCallState.failed => 'webrtcFailed'.tr(),
        _ => 'webrtcConnecting'.tr(),
      };

  @override
  Widget build(BuildContext context) {
    final inSystemPip = _session.isSystemPip.value;
    final topPad = MediaQuery.paddingOf(context).top;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        unawaited(_minimize());
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF0D1B2A),
        body: Stack(
          children: [
            Positioned.fill(
              child: ValueListenableBuilder<bool>(
                valueListenable: _session.hasRemote,
                builder: (_, hasRemote, __) {
                  if (_session.renderersReady && hasRemote) {
                    return const ColoredBox(color: Color(0xFF0D1B2A));
                  }
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const CircularProgressIndicator(color: _primary),
                        const SizedBox(height: 16),
                        ValueListenableBuilder<WebRtcCallState>(
                          valueListenable: _session.state,
                          builder: (_, __, ___) => Text(
                            _statusText,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            ValueListenableBuilder<bool>(
              valueListenable: _session.hasRemote,
              builder: (_, hasRemote, __) {
                if (!_session.renderersReady || !hasRemote) {
                  return const SizedBox.shrink();
                }
                return Positioned.fill(
                  child: _StableRtcView(
                    renderer: _session.remoteRenderer,
                    mirror: false,
                  ),
                );
              },
            ),
            if (!inSystemPip)
              ValueListenableBuilder<bool>(
                valueListenable: _session.hasLocal,
                builder: (_, hasLocal, __) {
                  if (!_session.renderersReady || !hasLocal) {
                    return const SizedBox.shrink();
                  }
                  return Positioned(
                    top: topPad + 56,
                    right: 16,
                    width: 110,
                    height: 150,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.white24),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: _StableRtcView(
                          renderer: _session.localRenderer,
                          mirror: true,
                        ),
                      ),
                    ),
                  );
                },
              ),
            if (!inSystemPip) ...[
              Positioned(
                top: topPad + 8,
                left: 8,
                right: 8,
                child: Row(
                  children: [
                    IconButton(
                      onPressed: _minimize,
                      icon: const Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: Colors.white,
                        size: 28,
                      ),
                      tooltip: 'webrtcMinimize'.tr(),
                    ),
                    Expanded(
                      child: Text(
                        widget.peerName.isNotEmpty
                            ? widget.peerName
                            : 'appointmentInfo.videoCall'.tr(),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    if (_pipSupported)
                      IconButton(
                        onPressed: () => WebRtcPipChannel.enterPip(),
                        icon: const Icon(
                          Icons.picture_in_picture_alt_rounded,
                          color: Colors.white70,
                          size: 22,
                        ),
                        tooltip: 'webrtcPip'.tr(),
                      )
                    else
                      const SizedBox(width: 48),
                  ],
                ),
              ),
              Positioned(
                top: topPad + 52,
                left: 16,
                child: ValueListenableBuilder<WebRtcQualityInfo>(
                  valueListenable: _session.quality,
                  builder: (_, quality, __) => _qualityBadge(quality),
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 32,
                child: _controls(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _controls() {
    return ValueListenableBuilder<bool>(
      valueListenable: _session.muted,
      builder: (_, muted, __) {
        return ValueListenableBuilder<bool>(
          valueListenable: _session.cameraOff,
          builder: (_, cameraOff, __) {
            return ValueListenableBuilder<bool>(
              valueListenable: _session.screenSharing,
              builder: (_, sharing, __) {
                return Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _controlBtn(
                      icon: muted
                          ? Icons.mic_off_rounded
                          : Icons.mic_rounded,
                      label: 'webrtcMute'.tr(),
                      onTap: () {
                        _session.muted.value = !muted;
                        _session.peer?.toggleMute(_session.muted.value);
                      },
                    ),
                    const SizedBox(width: 16),
                    _controlBtn(
                      icon: Icons.cameraswitch_rounded,
                      label: 'webrtcSwitch'.tr(),
                      onTap: () async {
                        await _session.peer?.switchCamera();
                        final local = _session.peer?.localStream;
                        if (local != null) _session.attachLocal(local);
                      },
                    ),
                    const SizedBox(width: 16),
                    _controlBtn(
                      icon: sharing
                          ? Icons.stop_screen_share_rounded
                          : Icons.screen_share_rounded,
                      label: 'webrtcShare'.tr(),
                      onTap: _toggleScreenShare,
                    ),
                    const SizedBox(width: 16),
                    _controlBtn(
                      icon: cameraOff
                          ? Icons.videocam_off_rounded
                          : Icons.videocam_rounded,
                      label: 'webrtcCamera'.tr(),
                      onTap: () {
                        _session.cameraOff.value = !cameraOff;
                        _session.peer
                            ?.toggleCamera(_session.cameraOff.value);
                      },
                    ),
                    const SizedBox(width: 24),
                    _controlBtn(
                      icon: Icons.call_end_rounded,
                      label: 'webrtcEnd'.tr(),
                      color: const Color(0xFFD32F2F),
                      onTap: () => _session.hangUp(),
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _qualityBadge(WebRtcQualityInfo quality) {
    final (color, label) = switch (quality.quality) {
      WebRtcCallQuality.good => (Colors.greenAccent, 'webrtcQualityGood'.tr()),
      WebRtcCallQuality.fair => (Colors.orangeAccent, 'webrtcQualityFair'.tr()),
      WebRtcCallQuality.poor => (Colors.redAccent, 'webrtcQualityPoor'.tr()),
      _ => (Colors.white54, 'webrtcQualityUnknown'.tr()),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black45,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.network_check_rounded, color: color, size: 16),
          const SizedBox(width: 6),
          Text(
            quality.rttMs > 0 ? '$label · ${quality.rttMs}ms' : label,
            style: TextStyle(color: color, fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _controlBtn({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color color = _primary,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Material(
          color: color,
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onTap,
            child: SizedBox(
              width: 52,
              height: 52,
              child: Icon(icon, color: Colors.white),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(label,
            style: const TextStyle(color: Colors.white70, fontSize: 11)),
      ],
    );
  }
}

/// แยกวิดีโอออกจาก parent rebuild เพื่อลดอาการค้าง
class _StableRtcView extends StatefulWidget {
  final RTCVideoRenderer renderer;
  final bool mirror;

  const _StableRtcView({
    required this.renderer,
    required this.mirror,
  });

  @override
  State<_StableRtcView> createState() => _StableRtcViewState();
}

class _StableRtcViewState extends State<_StableRtcView>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return RepaintBoundary(
      child: RTCVideoView(
        widget.renderer,
        mirror: widget.mirror,
        objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
        placeholderBuilder: (_) => const ColoredBox(color: Color(0xFF0D1B2A)),
      ),
    );
  }
}
