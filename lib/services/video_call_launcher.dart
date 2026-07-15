import 'dart:io';

import 'package:LawyerOnline/component/dialog_service.dart';
import 'package:LawyerOnline/models/user_profile_store.dart';
import 'package:LawyerOnline/services/pdpa_service.dart';
import 'package:LawyerOnline/services/video_call_service.dart';
import 'package:LawyerOnline/webrtc_call_page.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

/// เปิด video call WebRTC พร้อม consent + permission
class VideoCallLauncher {
  VideoCallLauncher._();

  static Future<void> join({
    required BuildContext context,
    required String caseCode,
    Map<String, dynamic>? caseData,
    String? messageRoomCode,
    String? peerName,
    String? toUserId,
    VoidCallback? onLeave,
  }) async {
    if (caseData != null) {
      final result = VideoCallService.checkJoinWindow(caseData);
      if (result != VideoCallJoinResult.allowed) {
        final window = VideoCallService.joinWindowMessage(caseData);
        final isTooLate = result == VideoCallJoinResult.tooLate;
        DialogService.showError(
          context,
          title: isTooLate
              ? 'videoCallExpiredTitle'.tr()
              : 'videoCallNotYetTitle'.tr(),
          message: isTooLate
              ? 'videoCallExpiredMessage'.tr(args: [window])
              : 'videoCallNotYetMessage'.tr(args: [window]),
        );
        return;
      }
    }

    if (!await PdpaService.hasAcceptedVideoConsent()) {
      final accepted = await _showVideoConsent(context);
      if (!accepted) return;
      await PdpaService.acceptVideoConsent();
    }

    DialogService.showConfirm(
      context,
      title: 'callReminderTitle'.tr(),
      message: 'callReminderMessage'.tr(),
      onConfirm: () async {
        if (!Platform.isIOS) {
          await Permission.camera.request();
          await Permission.microphone.request();
          final camDenied = await Permission.camera.isPermanentlyDenied;
          final micDenied = await Permission.microphone.isPermanentlyDenied;
          if (camDenied || micDenied) {
            if (!context.mounted) return;
            DialogService.showConfirm(
              context,
              title: 'permissionSettingsTitle'.tr(),
              message: 'permissionSettingsMessage'.tr(),
              onConfirm: () => openAppSettings(),
            );
            return;
          }
        }

        if (!context.mounted) return;
        final roomCode = await VideoCallService.resolveRoomCode(
          caseCode: caseCode,
          messageRoomCode: messageRoomCode,
        );
        final userId = UserProfileStore.instance.code;
        var peerId = toUserId?.trim() ?? '';
        if (peerId.isEmpty && caseData != null) {
          final a = caseData['userCode']?.toString() ?? '';
          final b = caseData['lawyer']?.toString() ?? '';
          if (a == userId) peerId = b;
          else if (b == userId) peerId = a;
        }

        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => WebRtcCallPage(
              roomCode: roomCode,
              caseCode: caseCode,
              userId: userId,
              peerName: peerName ?? '',
              toUserId: peerId,
              isInitiator: true,
            ),
          ),
        );

        onLeave?.call();
      },
    );
  }

  static Future<bool> _showVideoConsent(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: Text('videoConsentTitle'.tr()),
        content: Text('videoConsentBody'.tr()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('cancel'.tr()),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('accept'.tr()),
          ),
        ],
      ),
    );
    return result == true;
  }
}
