import 'package:LawyerOnline/main.dart';
import 'package:LawyerOnline/services/webrtc_call_session.dart';
import 'package:LawyerOnline/services/webrtc_peer_service.dart';
import 'package:LawyerOnline/webrtc_call_page.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

/// Floating in-app PiP bubble while call stays connected.
class WebRtcCallPipBubble {
  WebRtcCallPipBubble._();

  static OverlayEntry? _entry;

  static bool get isShowing => _entry != null;

  static void show() {
    if (_entry != null) return;
    final overlay = navigatorKey.currentState?.overlay;
    if (overlay == null) return;

    _entry = OverlayEntry(
      builder: (_) => const _PipBubbleHost(),
    );
    overlay.insert(_entry!);
  }

  static void hide() {
    _entry?.remove();
    _entry = null;
  }
}

class _PipBubbleHost extends StatefulWidget {
  const _PipBubbleHost();

  @override
  State<_PipBubbleHost> createState() => _PipBubbleHostState();
}

class _PipBubbleHostState extends State<_PipBubbleHost> {
  Offset _offset = const Offset(16, 120);

  void _expand() {
    final session = WebRtcCallSession.instance;
    if (!session.isActive || session.isFullScreenOpen) return;
    session.prepareExpand();
    session.markFullScreenOpening();
    navigatorKey.currentState?.push(
      MaterialPageRoute(
        builder: (_) => WebRtcCallPage(
          roomCode: session.roomCode,
          caseCode: session.caseCode,
          userId: session.userId,
          peerName: session.peerName,
          toUserId: session.toUserId,
          isInitiator: session.isInitiator,
          reuseSession: true,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final session = WebRtcCallSession.instance;
    final size = MediaQuery.sizeOf(context);
    final bubbleW = 120.0;
    final bubbleH = 180.0;

    return Positioned(
      left: _offset.dx.clamp(8.0, size.width - bubbleW - 8),
      top: _offset.dy.clamp(48.0, size.height - bubbleH - 48),
      child: GestureDetector(
        onPanUpdate: (d) {
          setState(() {
            _offset += d.delta;
          });
        },
        onTap: _expand,
        child: Material(
          elevation: 8,
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: SizedBox(
              width: bubbleW,
              height: bubbleH,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  const ColoredBox(color: Color(0xFF0D1B2A)),
                  ValueListenableBuilder<bool>(
                    valueListenable: session.hasRemote,
                    builder: (_, hasRemote, __) {
                      if (!hasRemote || !session.renderersReady) {
                        return const Center(
                          child: SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Color(0xFF0262EC),
                            ),
                          ),
                        );
                      }
                      return RTCVideoView(
                        session.remoteRenderer,
                        objectFit:
                            RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                        placeholderBuilder: (_) =>
                            const ColoredBox(color: Color(0xFF0D1B2A)),
                      );
                    },
                  ),
                  Positioned(
                    left: 6,
                    right: 6,
                    bottom: 6,
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            session.peerName.isNotEmpty
                                ? session.peerName
                                : 'appointmentInfo.videoCall'.tr(),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: () => session.hangUp(),
                          child: const CircleAvatar(
                            radius: 14,
                            backgroundColor: Color(0xFFD32F2F),
                            child: Icon(
                              Icons.call_end_rounded,
                              color: Colors.white,
                              size: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Positioned(
                    top: 6,
                    left: 6,
                    child: ValueListenableBuilder<WebRtcCallState>(
                      valueListenable: session.state,
                      builder: (_, s, __) {
                        final connected = s == WebRtcCallState.connected;
                        return Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: connected
                                ? Colors.greenAccent
                                : Colors.orangeAccent,
                            shape: BoxShape.circle,
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
