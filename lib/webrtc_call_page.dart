import 'package:LawyerOnline/component/appbar.dart';
import 'package:LawyerOnline/consult/consult_status.dart';
import 'package:LawyerOnline/services/video_call_log_service.dart';
import 'package:LawyerOnline/services/webrtc_call_listener_service.dart';
import 'package:LawyerOnline/services/webrtc_peer_service.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

class WebRtcCallPage extends StatefulWidget {
  final String roomCode;
  final String caseCode;
  final String userId;
  final String peerName;
  final bool isInitiator;

  const WebRtcCallPage({
    super.key,
    required this.roomCode,
    required this.caseCode,
    required this.userId,
    this.peerName = '',
    this.isInitiator = false,
  });

  @override
  State<WebRtcCallPage> createState() => _WebRtcCallPageState();
}

class _WebRtcCallPageState extends State<WebRtcCallPage> {
  static const _primary = Color(0xFF0262EC);

  late final WebRtcPeerService _peer;
  final _localRenderer = RTCVideoRenderer();
  final _remoteRenderer = RTCVideoRenderer();

  WebRtcCallState _state = WebRtcCallState.idle;
  bool _muted = false;
  bool _cameraOff = false;
  bool _renderersReady = false;
  bool _logged = false;
  DateTime? _connectedAt;

  @override
  void initState() {
    super.initState();
    WebRtcCallListenerService.instance.setInCallPage(true);
    _peer = WebRtcPeerService(
      roomCode: widget.roomCode,
      userId: widget.userId,
      caseCode: widget.caseCode,
      peerName: widget.peerName,
      onStateChanged: (s) {
        if (s == WebRtcCallState.connected && _connectedAt == null) {
          _connectedAt = DateTime.now();
        }
        if (mounted) setState(() => _state = s);
        if (s == WebRtcCallState.ended) _leaveCall();
      },
      onRemoteStream: (stream) {
        _remoteRenderer.srcObject = stream;
        if (mounted) setState(() {});
      },
    );
    _init();
  }

  Future<void> _init() async {
    await _localRenderer.initialize();
    await _remoteRenderer.initialize();
    if (!mounted) return;
    setState(() => _renderersReady = true);

    await _peer.start();
    _localRenderer.srcObject = _peer.localStream;
    if (mounted) setState(() {});
  }

  Future<void> _leaveCall() async {
    await _saveCallLog();
    await _peer.dispose();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => ConsultStatusPage(caseCode: widget.caseCode),
      ),
      (route) => route.isFirst,
    );
  }

  Future<void> _saveCallLog() async {
    if (_logged || !widget.isInitiator) return;
    _logged = true;

    final seconds = _connectedAt == null
        ? 0
        : DateTime.now().difference(_connectedAt!).inSeconds;

    await VideoCallLogService.logCall(
      roomCode: widget.roomCode,
      initiatedBy: widget.userId,
      durationSeconds: seconds,
    );
  }

  @override
  void dispose() {
    WebRtcCallListenerService.instance.setInCallPage(false);
    _peer.dispose();
    _localRenderer.dispose();
    _remoteRenderer.dispose();
    super.dispose();
  }

  String get _statusText => switch (_state) {
        WebRtcCallState.waitingPeer => 'webrtcWaitingPeer'.tr(),
        WebRtcCallState.connecting => 'webrtcConnecting'.tr(),
        WebRtcCallState.connected => 'webrtcConnected'.tr(),
        WebRtcCallState.failed => 'webrtcFailed'.tr(),
        _ => 'webrtcConnecting'.tr(),
      };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1B2A),
      appBar: appBar(
        title: widget.peerName.isNotEmpty
            ? widget.peerName
            : 'appointmentInfo.videoCall'.tr(),
        backBtn: false,
        rightBtn: false,
        backAction: () {},
        rightAction: () {},
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: _renderersReady && _remoteRenderer.srcObject != null
                ? RTCVideoView(
                    _remoteRenderer,
                    objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                  )
                : Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const CircularProgressIndicator(color: _primary),
                        const SizedBox(height: 16),
                        Text(
                          _statusText,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
          if (_renderersReady && _peer.localStream != null)
            Positioned(
              top: 16,
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
                  child: RTCVideoView(
                    _localRenderer,
                    mirror: true,
                    objectFit:
                        RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                  ),
                ),
              ),
            ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 32,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _controlBtn(
                  icon: _muted ? Icons.mic_off_rounded : Icons.mic_rounded,
                  label: 'webrtcMute'.tr(),
                  onTap: () {
                    setState(() => _muted = !_muted);
                    _peer.toggleMute(_muted);
                  },
                ),
                const SizedBox(width: 16),
                _controlBtn(
                  icon: Icons.cameraswitch_rounded,
                  label: 'webrtcSwitch'.tr(),
                  onTap: () => _peer.switchCamera(),
                ),
                const SizedBox(width: 16),
                _controlBtn(
                  icon: _cameraOff
                      ? Icons.videocam_off_rounded
                      : Icons.videocam_rounded,
                  label: 'webrtcCamera'.tr(),
                  onTap: () {
                    setState(() => _cameraOff = !_cameraOff);
                    _peer.toggleCamera(_cameraOff);
                  },
                ),
                const SizedBox(width: 24),
                _controlBtn(
                  icon: Icons.call_end_rounded,
                  label: 'webrtcEnd'.tr(),
                  color: const Color(0xFFD32F2F),
                  onTap: () => _peer.hangUp(),
                ),
              ],
            ),
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
