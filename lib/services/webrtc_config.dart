import 'package:LawyerOnline/shared/api_provider.dart';

/// ICE servers สำหรับ WebRTC — โหลดจาก API ได้
abstract final class WebRtcConfig {
  static List<Map<String, dynamic>> _iceServers = [
    {'urls': 'stun:stun.l.google.com:19302'},
    {'urls': 'stun:stun1.l.google.com:19302'},
  ];

  static Future<void> ensureLoaded() async {
    try {
      final result = await postDio('${server}/m/video/config', {});
      if (result['status'] != 'S') return;
      final raw = result['objectData']?['iceServers'];
      if (raw is! List || raw.isEmpty) return;

      final parsed = <Map<String, dynamic>>[];
      for (final item in raw) {
        if (item is! Map) continue;
        final map = Map<String, dynamic>.from(item);
        if (map['urls'] != null) parsed.add(map);
      }
      if (parsed.isNotEmpty) _iceServers = parsed;
    } catch (_) {}
  }

  static Map<String, dynamic> peerConnectionConfig() => {
        'iceServers': _iceServers,
        'sdpSemantics': 'unified-plan',
        'bundlePolicy': 'max-bundle',
        'rtcpMuxPolicy': 'require',
        'iceCandidatePoolSize': 4,
      };

  /// ความละเอียดต่ำ + fps จำกัด — ลดอาการค้างบนมือถือ
  static Map<String, dynamic> mediaConstraints({bool video = true}) => {
        'audio': {
          'echoCancellation': true,
          'noiseSuppression': true,
          'autoGainControl': true,
        },
        'video': video
            ? {
                'facingMode': 'user',
                'width': {'ideal': 480, 'max': 640},
                'height': {'ideal': 360, 'max': 480},
                'frameRate': {'ideal': 20, 'max': 24},
              }
            : false,
      };

  static const int videoMaxBitrate = 450000; // ~450 kbps
  static const int videoMaxFramerate = 20;
}

enum WebRtcCallQuality { good, fair, poor, unknown }

class WebRtcQualityInfo {
  const WebRtcQualityInfo({
    required this.quality,
    required this.rttMs,
    required this.packetsLost,
  });

  final WebRtcCallQuality quality;
  final int rttMs;
  final int packetsLost;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WebRtcQualityInfo &&
          quality == other.quality &&
          rttMs == other.rttMs &&
          packetsLost == other.packetsLost;

  @override
  int get hashCode => Object.hash(quality, rttMs, packetsLost);
}
