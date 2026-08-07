import 'dart:async';

import 'package:LawyerOnline/services/webrtc_config.dart';
import 'package:LawyerOnline/services/webrtc_signaling_service.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_background/flutter_background.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

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
    this.toUserId = '',
    this.isInitiator = false,
    required this.onStateChanged,
    required this.onRemoteStream,
    this.onRemoteStreamRefresh,
    this.onQualityChanged,
    this.onRemoteEnded,
  });

  final String roomCode;
  final String userId;
  final String caseCode;
  final String peerName;
  final String toUserId;
  final bool isInitiator;
  final ValueChanged<WebRtcCallState> onStateChanged;
  final ValueChanged<MediaStream> onRemoteStream;
  final VoidCallback? onRemoteStreamRefresh;
  final ValueChanged<WebRtcQualityInfo>? onQualityChanged;
  final ValueChanged<String>? onRemoteEnded;

  RTCPeerConnection? _pc;
  MediaStream? _localStream;
  MediaStream? _screenStream;
  WebRtcSignalingService? _signaling;
  String? _peerId;
  bool _makingOffer = false;
  bool _remoteDescriptionSet = false;
  bool _screenSharing = false;
  bool _iceRestarting = false;
  Timer? _qualityTimer;
  Timer? _disconnectTimer;
  final List<RTCIceCandidate> _pendingRemoteCandidates = [];
  final List<RTCIceCandidate> _pendingLocalCandidates = [];
  bool _disposed = false;
  MediaStream? _remoteStream;
  WebRtcCallState _state = WebRtcCallState.idle;

  MediaStream? get localStream => _localStream;
  MediaStream? get remoteStream => _remoteStream;
  RTCPeerConnection? get peerConnection => _pc;
  bool get isScreenSharing => _screenSharing;

  void _setState(WebRtcCallState next) {
    if (_disposed || _state == next) return;
    // ไม่ให้ failed/ended ถูกทับด้วย connecting ระหว่าง teardown
    if ((_state == WebRtcCallState.ended || _state == WebRtcCallState.failed) &&
        next != WebRtcCallState.ended) {
      return;
    }
    _state = next;
    onStateChanged(next);
  }

  Future<void> start() async {
    _setState(WebRtcCallState.connecting);

    await WebRtcConfig.ensureLoaded();

    _signaling = WebRtcSignalingService(
      roomCode: roomCode,
      userId: userId,
      caseCode: caseCode,
      peerName: peerName,
      toUserId: toUserId,
      isInitiator: isInitiator,
    );
    _signaling!.onSignal = _onSignal;
    await _signaling!.start();

    _localStream = await navigator.mediaDevices.getUserMedia(
      WebRtcConfig.mediaConstraints(),
    );

    _pc = await createPeerConnection(WebRtcConfig.peerConnectionConfig());
    for (final track in _localStream!.getTracks()) {
      await _pc!.addTrack(track, _localStream!);
    }
    await _tuneVideoSender();

    _pc!.onIceCandidate = (candidate) {
      if (candidate.candidate == null || candidate.candidate!.isEmpty) return;
      if (_peerId == null) {
        _pendingLocalCandidates.add(candidate);
        return;
      }
      unawaited(_sendIce(candidate));
    };

    _pc!.onTrack = (event) {
      unawaited(_handleTrackEvent(event));
    };

    _pc!.onIceConnectionState = (state) {
      debugPrint('WebRTC iceConnectionState=$state');
      if (state == RTCIceConnectionState.RTCIceConnectionStateConnected ||
          state == RTCIceConnectionState.RTCIceConnectionStateCompleted) {
        _disconnectTimer?.cancel();
        _iceRestarting = false;
        _setState(WebRtcCallState.connected);
      } else if (state ==
          RTCIceConnectionState.RTCIceConnectionStateDisconnected) {
        _scheduleDisconnectRecovery();
      } else if (state == RTCIceConnectionState.RTCIceConnectionStateFailed) {
        unawaited(_tryIceRestart());
      }
    };

    _pc!.onConnectionState = (state) {
      debugPrint('WebRTC connectionState=$state');
      if (state == RTCPeerConnectionState.RTCPeerConnectionStateConnected) {
        _disconnectTimer?.cancel();
        _iceRestarting = false;
        _setState(WebRtcCallState.connected);
        unawaited(_tuneVideoSender());
      } else if (state ==
          RTCPeerConnectionState.RTCPeerConnectionStateFailed) {
        unawaited(_tryIceRestart());
      } else if (state ==
          RTCPeerConnectionState.RTCPeerConnectionStateDisconnected) {
        _scheduleDisconnectRecovery();
      }
    };

    _setState(WebRtcCallState.waitingPeer);
    await _signaling!.send(WebRtcSignal(action: 'ready', from: userId));
    _startQualityMonitor();
  }

  Future<void> _sendIce(RTCIceCandidate candidate) async {
    await _signaling?.send(WebRtcSignal(
      action: 'ice',
      from: userId,
      candidate: candidate.toMap(),
    ));
  }

  Future<void> _flushLocalCandidates() async {
    if (_pendingLocalCandidates.isEmpty) return;
    final pending = List<RTCIceCandidate>.from(_pendingLocalCandidates);
    _pendingLocalCandidates.clear();
    for (final c in pending) {
      await _sendIce(c);
    }
  }

  Future<void> _tuneVideoSender() async {
    final pc = _pc;
    if (pc == null) return;
    try {
      final senders = await pc.getSenders();
      for (final sender in senders) {
        if (sender.track?.kind != 'video') continue;
        final params = sender.parameters;
        final encodings = params.encodings;
        if (encodings != null && encodings.isNotEmpty) {
          for (final encoding in encodings) {
            encoding.maxBitrate = WebRtcConfig.videoMaxBitrate;
            encoding.maxFramerate = WebRtcConfig.videoMaxFramerate;
          }
        } else {
          params.encodings = [
            RTCRtpEncoding(
              maxBitrate: WebRtcConfig.videoMaxBitrate,
              maxFramerate: WebRtcConfig.videoMaxFramerate,
            ),
          ];
        }
        await sender.setParameters(params);
      }
    } catch (e) {
      debugPrint('WebRTC tuneVideoSender: $e');
    }
  }

  void _startQualityMonitor() {
    _qualityTimer?.cancel();
    if (onQualityChanged == null) return;
    _qualityTimer = Timer.periodic(const Duration(seconds: 5), (_) async {
      if (_disposed) return;
      final info = await getQualityInfo();
      onQualityChanged?.call(info);
    });
  }

  Future<WebRtcQualityInfo> getQualityInfo() async {
    if (_pc == null) {
      return const WebRtcQualityInfo(
        quality: WebRtcCallQuality.unknown,
        rttMs: 0,
        packetsLost: 0,
      );
    }

    try {
      final reports = await _pc!.getStats();
      var packetsLost = 0;
      var rttMs = 0;

      for (final report in reports) {
        if (report.type == 'inbound-rtp' && report.values['kind'] == 'video') {
          packetsLost = int.tryParse(
                report.values['packetsLost']?.toString() ?? '',
              ) ??
              packetsLost;
        }
        if (report.type == 'candidate-pair' &&
            report.values['state']?.toString() == 'succeeded') {
          final rtt = report.values['currentRoundTripTime'];
          if (rtt is num) rttMs = (rtt * 1000).round();
        }
      }

      final quality = packetsLost > 50 || rttMs > 400
          ? WebRtcCallQuality.poor
          : packetsLost > 10 || rttMs > 200
              ? WebRtcCallQuality.fair
              : WebRtcCallQuality.good;

      return WebRtcQualityInfo(
        quality: quality,
        rttMs: rttMs,
        packetsLost: packetsLost,
      );
    } catch (_) {
      return const WebRtcQualityInfo(
        quality: WebRtcCallQuality.unknown,
        rttMs: 0,
        packetsLost: 0,
      );
    }
  }

  Future<void> _onSignal(WebRtcSignal signal) async {
    switch (signal.action) {
      case 'ready':
        _peerId ??= signal.from;
        await _flushLocalCandidates();
        if (_shouldCreateOffer()) {
          await _createOffer();
        }
        break;
      case 'offer':
        _peerId = signal.from;
        await _flushLocalCandidates();
        await _handleOffer(signal.sdp ?? '');
        break;
      case 'answer':
        await _handleAnswer(signal.sdp ?? '');
        break;
      case 'ice':
        await _handleIce(signal.candidate);
        break;
      case 'hangup':
        onRemoteEnded?.call('hangup');
        _setState(WebRtcCallState.ended);
        break;
      case 'reject':
        onRemoteEnded?.call('reject');
        _setState(WebRtcCallState.ended);
        break;
      case 'screenshare':
        if (signal.enabled != true) {
          onRemoteStreamRefresh?.call();
        }
        break;
    }
  }

  Future<void> _handleTrackEvent(RTCTrackEvent event) async {
    MediaStream? stream;
    if (event.streams.isNotEmpty) {
      stream = event.streams.first;
    } else {
      final track = event.track;
      stream = _remoteStream ?? await createLocalMediaStream('remote');
      final existing =
          stream.getTracks().any((t) => t.id == track.id);
      if (!existing) {
        await stream.addTrack(track);
      }
    }
    _bindRemoteStream(stream);
    _setState(WebRtcCallState.connected);
  }

  void _bindRemoteStream(MediaStream stream) {
    _remoteStream = stream;
    for (final track in stream.getVideoTracks()) {
      track.onEnded = () {
        if (_disposed ||
            _state == WebRtcCallState.ended ||
            _state == WebRtcCallState.failed) {
          return;
        }
        debugPrint('WebRTC remote video track ended — refresh display');
        onRemoteStreamRefresh?.call();
      };
    }
    onRemoteStream(stream);
  }

  Future<void> _rennegotiateAfterTrackChange() async {
    if (_pc == null || _peerId == null) return;

    await _signaling?.send(WebRtcSignal(
      action: 'screenshare',
      from: userId,
      enabled: _screenSharing,
    ));

    try {
      if (isInitiator) {
        await _createOffer();
      } else {
        // ฝั่งรับขอ initiator ส่ง offer ใหม่หลังเปลี่ยน track
        await _signaling?.send(WebRtcSignal(action: 'ready', from: userId));
      }
    } catch (e) {
      debugPrint('WebRTC renegotiate after track change: $e');
    }
  }

  void _scheduleDisconnectRecovery() {
    _disconnectTimer?.cancel();
    // ICE หลุดชั่วคราวบ่อย — รอแล้วยิง iceRestart ก่อนตัดสาย
    _disconnectTimer = Timer(const Duration(seconds: 5), () {
      if (_disposed) return;
      unawaited(_tryIceRestart());
    });
  }

  Future<void> _tryIceRestart() async {
    if (_disposed || _pc == null || _iceRestarting) return;
    if (!isInitiator) {
      // ฝั่งรับรอ offer ใหม่จาก initiator
      _disconnectTimer?.cancel();
      _disconnectTimer = Timer(const Duration(seconds: 12), () {
        if (_disposed) return;
        if (_state != WebRtcCallState.connected) {
          _setState(WebRtcCallState.failed);
        }
      });
      return;
    }

    _iceRestarting = true;
    debugPrint('WebRTC attempting ICE restart');
    try {
      final offer = await _pc!.createOffer({
        'offerToReceiveAudio': true,
        'offerToReceiveVideo': true,
        'iceRestart': true,
      });
      await _pc!.setLocalDescription(offer);
      await _signaling?.send(WebRtcSignal(
        action: 'offer',
        from: userId,
        sdp: offer.sdp,
      ));
      _disconnectTimer?.cancel();
      _disconnectTimer = Timer(const Duration(seconds: 12), () {
        if (_disposed) return;
        if (_state != WebRtcCallState.connected) {
          _setState(WebRtcCallState.failed);
        }
      });
    } catch (e) {
      debugPrint('WebRTC iceRestart error: $e');
      _setState(WebRtcCallState.failed);
    } finally {
      _iceRestarting = false;
    }
  }

  bool _shouldCreateOffer() {
    if (_peerId == null) return false;
    if (_makingOffer) return false;
    return isInitiator;
  }

  Future<void> _createOffer({bool iceRestart = false}) async {
    if (_pc == null || _makingOffer) return;
    _makingOffer = true;
    try {
      final offer = await _pc!.createOffer({
        'offerToReceiveAudio': true,
        'offerToReceiveVideo': true,
        if (iceRestart) 'iceRestart': true,
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
    if (_pc == null || sdp.isEmpty) return;
    await _pc!.setRemoteDescription(RTCSessionDescription(sdp, 'offer'));
    _remoteDescriptionSet = true;
    await _flushPendingRemoteCandidates();
    final answer = await _pc!.createAnswer();
    await _pc!.setLocalDescription(answer);
    await _signaling?.send(WebRtcSignal(
      action: 'answer',
      from: userId,
      sdp: answer.sdp,
    ));
  }

  Future<void> _handleAnswer(String sdp) async {
    if (_pc == null || sdp.isEmpty) return;
    await _pc!.setRemoteDescription(RTCSessionDescription(sdp, 'answer'));
    _remoteDescriptionSet = true;
    await _flushPendingRemoteCandidates();
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
      _pendingRemoteCandidates.add(candidate);
      return;
    }
    try {
      await _pc!.addCandidate(candidate);
    } catch (e) {
      debugPrint('WebRTC addCandidate: $e');
    }
  }

  Future<void> _flushPendingRemoteCandidates() async {
    if (_pc == null) return;
    final pending = List<RTCIceCandidate>.from(_pendingRemoteCandidates);
    _pendingRemoteCandidates.clear();
    for (final c in pending) {
      try {
        await _pc!.addCandidate(c);
      } catch (e) {
        debugPrint('WebRTC flushCandidate: $e');
      }
    }
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

  /// Returns error message on failure, null on success.
  Future<String?> toggleScreenShare() async {
    if (_pc == null) return 'webrtcShareFailed'.tr();

    try {
      if (_screenSharing) {
        final tracks = _localStream?.getVideoTracks() ?? [];
        final cameraTrack = tracks.isNotEmpty ? tracks.first : null;
        final senders = await _pc!.getSenders();
        for (final sender in senders) {
          if (sender.track?.kind == 'video' && cameraTrack != null) {
            cameraTrack.enabled = true;
            await sender.replaceTrack(cameraTrack);
          }
        }
        final screenTracks = _screenStream?.getTracks() ?? [];
        for (final t in screenTracks) {
          await t.stop();
        }
        await _screenStream?.dispose();
        _screenStream = null;
        _screenSharing = false;
        await _stopScreenShareForeground();
        await _tuneVideoSender();
        await _rennegotiateAfterTrackChange();
        return null;
      }

      // Android 14+: MediaProjection permission → FGS → getDisplayMedia
      if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
        final granted = await Helper.requestCapturePermission();
        if (!granted) {
          debugPrint('screen share permission denied');
          return 'webrtcShareDenied'.tr();
        }
        final ready = await _startScreenShareForeground();
        if (!ready) {
          return 'webrtcShareFailed'.tr();
        }
        await Future<void>.delayed(const Duration(milliseconds: 300));
      }

      _screenStream = await navigator.mediaDevices.getDisplayMedia({
        'video': {
          'mandatory': {
            'minWidth': 640,
            'minHeight': 480,
            'maxFrameRate': 30,
          },
        },
        'audio': false,
      });
      final screenTracks = _screenStream?.getVideoTracks() ?? [];
      final screenTrack = screenTracks.isNotEmpty ? screenTracks.first : null;
      if (screenTrack == null) {
        await _screenStream?.dispose();
        _screenStream = null;
        await _stopScreenShareForeground();
        return 'webrtcShareFailed'.tr();
      }

      screenTrack.onEnded = () {
        if (_screenSharing) {
          toggleScreenShare();
        }
      };

      final senders = await _pc!.getSenders();
      var replaced = false;
      for (final sender in senders) {
        if (sender.track?.kind == 'video') {
          await sender.replaceTrack(screenTrack);
          replaced = true;
        }
      }
      if (!replaced) {
        await _pc!.addTrack(screenTrack, _screenStream!);
      }
      _screenSharing = true;
      await _tuneVideoSender();
      await _rennegotiateAfterTrackChange();
      return null;
    } catch (e, st) {
      debugPrint('toggleScreenShare error: $e\n$st');
      try {
        await _screenStream?.dispose();
      } catch (_) {}
      _screenStream = null;
      _screenSharing = false;
      await _stopScreenShareForeground();
      return 'webrtcShareFailed'.tr();
    }
  }

  Future<bool> _startScreenShareForeground() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      return true;
    }
    try {
      const androidConfig = FlutterBackgroundAndroidConfig(
        notificationTitle: 'LC Online',
        notificationText: 'กำลังแชร์หน้าจอ',
        notificationImportance: AndroidNotificationImportance.normal,
        notificationIcon:
            AndroidResource(name: 'ic_launcher', defType: 'mipmap'),
        shouldRequestBatteryOptimizationsOff: false,
      );
      final ok = await FlutterBackground.initialize(androidConfig: androidConfig);
      if (!ok) return false;
      if (!FlutterBackground.isBackgroundExecutionEnabled) {
        return await FlutterBackground.enableBackgroundExecution();
      }
      return true;
    } catch (e, st) {
      debugPrint('screen share FGS error: $e\n$st');
      return false;
    }
  }

  Future<void> _stopScreenShareForeground() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return;
    try {
      if (FlutterBackground.isBackgroundExecutionEnabled) {
        await FlutterBackground.disableBackgroundExecution();
      }
    } catch (e) {
      debugPrint('stop screen share FGS error: $e');
    }
  }

  Future<void> hangUp() async {
    try {
      await _signaling?.send(WebRtcSignal(action: 'hangup', from: userId));
    } catch (_) {}
    // แจ้ง ended ก่อน dispose — หลัง dispose จะบล็อก _setState
    _state = WebRtcCallState.ended;
    onStateChanged(WebRtcCallState.ended);
    await dispose();
  }

  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    _disconnectTimer?.cancel();
    _disconnectTimer = null;
    _qualityTimer?.cancel();
    _qualityTimer = null;
    _pendingLocalCandidates.clear();
    _pendingRemoteCandidates.clear();
    await _signaling?.stop();
    _signaling = null;
    _screenSharing = false;
    await _stopScreenShareForeground();
    try {
      await _screenStream?.dispose();
    } catch (_) {}
    _screenStream = null;
    try {
      for (final t in _localStream?.getTracks() ?? []) {
        await t.stop();
      }
      await _localStream?.dispose();
    } catch (_) {}
    _localStream = null;
    try {
      await _pc?.close();
    } catch (_) {}
    _pc = null;
  }
}
