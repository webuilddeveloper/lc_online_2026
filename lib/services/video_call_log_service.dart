import 'dart:convert';

import 'package:LawyerOnline/services/chat_service.dart';
import 'package:easy_localization/easy_localization.dart';

class VideoCallLogData {
  const VideoCallLogData({
    required this.initiatedBy,
    required this.durationSeconds,
  });

  final String initiatedBy;
  final int durationSeconds;

  factory VideoCallLogData.fromMessage(Map<String, dynamic> message) {
    final raw = message['content']?.toString() ?? '';
    if (raw.isEmpty) {
      return const VideoCallLogData(initiatedBy: '', durationSeconds: 0);
    }
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      return VideoCallLogData(
        initiatedBy: map['initiatedBy']?.toString() ?? '',
        durationSeconds: int.tryParse(
              map['durationSeconds']?.toString() ?? '',
            ) ??
            0,
      );
    } catch (_) {
      return const VideoCallLogData(initiatedBy: '', durationSeconds: 0);
    }
  }
}

/// บันทึกประวัติวิดีโอคอลลงแชท (ฝั่งที่เริ่มโทรเท่านั้น)
class VideoCallLogService {
  VideoCallLogService._();

  static Future<void> logCall({
    required String roomCode,
    required String initiatedBy,
    required int durationSeconds,
  }) async {
    if (roomCode.isEmpty || initiatedBy.isEmpty) return;

    final payload = jsonEncode({
      'initiatedBy': initiatedBy,
      'durationSeconds': durationSeconds,
    });

    final chat = ChatService();
    try {
      await chat.connect();
      await chat.sendMessage(
        roomCode,
        initiatedBy,
        content: payload,
        type: 'video_call',
      );
    } catch (_) {
      // ไม่ block การวางสายถ้าบันทึกแชทไม่สำเร็จ
    } finally {
      await chat.disconnect();
    }
  }

  static String formatDuration(int seconds) {
    if (seconds <= 0) return 'chatVideoCallNoConnect'.tr();
    final minutes = seconds ~/ 60;
    final remain = seconds % 60;
    if (minutes == 0) {
      return 'chatVideoCallDurationSecondsOnly'.tr(args: ['$remain']);
    }
    if (remain == 0) {
      return 'chatVideoCallDurationMinutes'.tr(args: ['$minutes']);
    }
    return 'chatVideoCallDurationMinutesSeconds'.tr(
      args: ['$minutes', '$remain'],
    );
  }

  static String bubbleTitle({
    required VideoCallLogData data,
    required bool isMe,
  }) {
    if (isMe) return 'chatVideoCallYouStarted'.tr();
    return 'chatVideoCallPeerStarted'.tr();
  }
}
