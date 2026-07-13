import 'package:flutter/foundation.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:LawyerOnline/services/webrtc_config.dart';
import 'package:LawyerOnline/services/webrtc_signaling_service.dart';

enum WebRtcCallState {
  idle,
  waitingPeer,
  connecting,
  connected,
  ended,
  failed,
}

/// จัดการ RTCPeerConnection + media stream
class WebRtcPeerService {
  WebRtcPeerService({
    required this.roomCode,
    required this.userId,
    required this.caseCode,
    this.peerName = '',
    required this.onStateChanged,
    required this.onRemoteStream,
  });

  final String roomCode;
  final String userId;
  final String caseCode;
  final String peerName;
  final ValueChanged<WebRtcCallState> onStateChanged;
  final ValueChanged<MediaStream> onRemoteStream;

  RTCPeerConnection? _pc;
  MediaStream? _localStream;
  WebRtcSignalingService? _signaling;
  String? _peerId;
  bool _makingOffer = false;
  bool _remoteDescriptionSet = false;
  final List<RTCIceCandidate> _pendingCandidates = [];

  MediaStream? get localStream => _localStream;
  RTCPeerConnection? get peerConnection => _pc;

  Future<void> start() async {
    onStateChanged(WebRtcCallState.connecting);

    _signaling = WebRtcSignalingService(
      roomCode: roomCode,
      userId: userId,
      caseCode: caseCode,
      peerName: peerName,
    );
    _signaling!.onSignal = _onSignal;
    await _signaling!.start();

    _localStream = await navigator.mediaDevices.getUserMedia(
      WebRtcConfig.mediaConstraints(),
    );

    _pc = await createPeerConnection(WebRtcConfig.peerConnectionConfig());
    _localStream!.getTracks().forEach((track) {
      _pc!.addTrack(track, _localStream!);
    });

    _pc!.onIceCandidate = (candidate) {
      if (candidate.candidate == null || _peerId == null) return;
      _signaling?.send(WebRtcSignal(
        action: 'ice',
        from: userId,
        candidate: candidate.toMap(),
      ));
    };

    _pc!.onTrack = (event) {
      if (event.streams.isNotEmpty) {
        onStateChanged(WebRtcCallState.connected);
        onRemoteStream(event.streams.first);
      }
    };

    _pc!.onConnectionState = (state) {
      if (state == RTCPeerConnectionState.RTCPeerConnectionStateConnected) {
        onStateChanged(WebRtcCallState.connected);
      } else if (state ==
              RTCPeerConnectionState.RTCPeerConnectionStateFailed ||
          state == RTCPeerConnectionState.RTCPeerConnectionStateDisconnected) {
        onStateChanged(WebRtcCallState.failed);
      }
    };

    onStateChanged(WebRtcCallState.waitingPeer);
    await _signaling!.send(WebRtcSignal(action: 'ready', from: userId));
  }

  Future<void> _onSignal(WebRtcSignal signal) async {
    switch (signal.action) {
      case 'ready':
        _peerId ??= signal.from;
        if (_shouldCreateOffer()) {
          await _createOffer();
        }
        break;
      case 'offer':
        _peerId = signal.from;
        await _handleOffer(signal.sdp ?? '');
        break;
      case 'answer':
        await _handleAnswer(signal.sdp ?? '');
        break;
      case 'ice':
        await _handleIce(signal.candidate);
        break;
      case 'hangup':
        onStateChanged(WebRtcCallState.ended);
        break;
    }
  }

  bool _shouldCreateOffer() {
    if (_peerId == null) return false;
    if (_makingOffer) return false;
    return userId.compareTo(_peerId!) < 0;
  }

  Future<void> _createOffer() async {
    if (_pc == null || _makingOffer) return;
    _makingOffer = true;
    try {
      final offer = await _pc!.createOffer({
        'offerToReceiveAudio': true,
        'offerToReceiveVideo': true,
      });
      await _pc!.setLocalDescription(offer);
      await _signaling?.send(WebRtcSignal(
        action: 'offer',
        from: userId,
        sdp: offer.sdp,
      ));
    } finally {
      _makingOffer = false;
    }
  }

  Future<void> _handleOffer(String sdp) async {
    if (_pc == null) return;
    await _pc!.setRemoteDescription(RTCSessionDescription(sdp, 'offer'));
    _remoteDescriptionSet = true;
    await _flushPendingCandidates();
    final answer = await _pc!.createAnswer();
    await _pc!.setLocalDescription(answer);
    await _signaling?.send(WebRtcSignal(
      action: 'answer',
      from: userId,
      sdp: answer.sdp,
    ));
  }

  Future<void> _handleAnswer(String sdp) async {
    if (_pc == null) return;
    await _pc!.setRemoteDescription(RTCSessionDescription(sdp, 'answer'));
    _remoteDescriptionSet = true;
    await _flushPendingCandidates();
  }

  Future<void> _handleIce(Map<String, dynamic>? raw) async {
    if (_pc == null || raw == null) return;
    final candidate = RTCIceCandidate(
      raw['candidate']?.toString(),
      raw['sdpMid']?.toString(),
      raw['sdpMLineIndex'] is int
          ? raw['sdpMLineIndex'] as int
          : int.tryParse(raw['sdpMLineIndex']?.toString() ?? ''),
    );
    if (!_remoteDescriptionSet) {
      _pendingCandidates.add(candidate);
      return;
    }
    await _pc!.addCandidate(candidate);
  }

  Future<void> _flushPendingCandidates() async {
    if (_pc == null) return;
    for (final c in _pendingCandidates) {
      await _pc!.addCandidate(c);
    }
    _pendingCandidates.clear();
  }

  Future<void> toggleMute(bool muted) async {
    for (final track in _localStream?.getAudioTracks() ?? []) {
      track.enabled = !muted;
    }
  }

  Future<void> toggleCamera(bool off) async {
    for (final track in _localStream?.getVideoTracks() ?? []) {
      track.enabled = !off;
    }
  }

  Future<void> switchCamera() async {
    final tracks = _localStream?.getVideoTracks() ?? [];
    if (tracks.isEmpty) return;
    await Helper.switchCamera(tracks.first);
  }

  Future<void> hangUp() async {
    await _signaling?.send(WebRtcSignal(action: 'hangup', from: userId));
    await dispose();
    onStateChanged(WebRtcCallState.ended);
  }

  Future<void> dispose() async {
    await _signaling?.stop();
    _signaling = null;
    await _localStream?.dispose();
    _localStream = null;
    await _pc?.close();
    _pc = null;
  }
}
