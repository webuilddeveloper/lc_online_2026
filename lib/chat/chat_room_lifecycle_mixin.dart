import 'package:LawyerOnline/services/chat_service.dart';
import 'package:LawyerOnline/services/webrtc_call_listener_service.dart';
import 'package:flutter/widgets.dart';

/// Clears chat-room presence when the app goes to background so push
/// notifications are delivered; restores when the user returns.
mixin ChatRoomLifecycleMixin<T extends StatefulWidget> on State<T>, WidgetsBindingObserver {
  ChatService get chatService;
  String get chatRoomCode;
  String get chatUserId;
  String get chatCaseCode => '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (chatRoomCode.isEmpty || chatUserId.isEmpty) return;

    if (state == AppLifecycleState.paused) {
      chatService.setActiveRoom(null);
      chatService.leaveRoom(chatRoomCode, chatUserId);
      WebRtcCallListenerService.instance.leaveCurrentRoom();
    } else if (state == AppLifecycleState.resumed) {
      chatService.setActiveRoom(chatRoomCode);
      chatService.joinRoom(chatRoomCode, chatUserId);
      if (chatCaseCode.isNotEmpty) {
        WebRtcCallListenerService.instance.joinRoomForChat(
          roomCode: chatRoomCode,
          caseCode: chatCaseCode,
        );
      }
    }
  }
}
