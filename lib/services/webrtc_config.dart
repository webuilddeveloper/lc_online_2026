/// ICE servers สำหรับ WebRTC
abstract final class WebRtcConfig {
  static const iceServers = [
    {'urls': 'stun:stun.l.google.com:19302'},
    {'urls': 'stun:stun1.l.google.com:19302'},
    // เพิ่ม TURN server ของตัวเองใน production สำหรับเครือข่ายที่เข้มงวด
    // {
    //   'urls': 'turn:your-turn-server.com:3478',
    //   'username': 'user',
    //   'credential': 'pass',
    // },
  ];

  static Map<String, dynamic> peerConnectionConfig() => {
        'iceServers': iceServers,
        'sdpSemantics': 'unified-plan',
      };

  static Map<String, dynamic> mediaConstraints({bool video = true}) => {
        'audio': true,
        'video': video
            ? {
                'facingMode': 'user',
                'width': {'ideal': 640},
                'height': {'ideal': 480},
              }
            : false,
      };
}
