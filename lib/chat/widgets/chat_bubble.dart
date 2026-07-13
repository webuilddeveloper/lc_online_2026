import 'package:LawyerOnline/component/gallery_view.dart';
import 'package:LawyerOnline/component/link_url_in.dart';
import 'package:LawyerOnline/services/chat_attachment_service.dart';
import 'package:LawyerOnline/services/video_call_log_service.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

class ChatBubble extends StatelessWidget {
  final Map<String, dynamic> message;
  final bool isMe;
  final String avatarAsset;

  const ChatBubble({
    super.key,
    required this.message,
    required this.isMe,
    this.avatarAsset = '',
  });

  @override
  Widget build(BuildContext context) {
    final type = ChatAttachmentService.readType(message);
    final fileUrl = ChatAttachmentService.readFileUrl(message);
    final text = ChatAttachmentService.readDisplayText(message);

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(100),
              child: avatarAsset.isNotEmpty
                  ? Image.network(
                      avatarAsset,
                      height: 36,
                      width: 36,
                      fit: BoxFit.cover,
                    )
                  : Image.asset(
                      'assets/icons/profile.png',
                      height: 36,
                      width: 36,
                      fit: BoxFit.cover,
                    ),
            ),
            const SizedBox(width: 10),
          ],
          Flexible(
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 2),
              padding: EdgeInsets.symmetric(
                horizontal: type == 'image' ? 6 : 14,
                vertical: type == 'image' ? 6 : 10,
              ),
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.7,
              ),
              decoration: BoxDecoration(
                color: isMe ? const Color(0xFF0262EC) : Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(18),
                  topRight: const Radius.circular(18),
                  bottomLeft: isMe
                      ? const Radius.circular(18)
                      : const Radius.circular(4),
                  bottomRight: isMe
                      ? const Radius.circular(4)
                      : const Radius.circular(18),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: _buildContent(context, type, fileUrl, text),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    String type,
    String fileUrl,
    String text,
  ) {
    if (type == 'image' && fileUrl.isNotEmpty) {
      return GestureDetector(
        onTap: () => _openImage(context, fileUrl),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: CachedNetworkImage(
            imageUrl: fileUrl,
            width: 220,
            fit: BoxFit.cover,
            placeholder: (_, __) => Container(
              width: 220,
              height: 160,
              color: const Color(0xFFEEF2F5),
              child: const Center(
                child: SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            ),
            errorWidget: (_, __, ___) => Container(
              width: 220,
              height: 120,
              color: const Color(0xFFEEF2F5),
              alignment: Alignment.center,
              child: Icon(
                Icons.broken_image_outlined,
                color: isMe ? Colors.white70 : Colors.grey,
              ),
            ),
          ),
        ),
      );
    }

    if (type == 'video_call') {
      return _buildVideoCallContent(isMe);
    }

    if (type == 'file' && fileUrl.isNotEmpty) {
      return InkWell(
        onTap: () => launchInWebViewWithJavaScript(fileUrl),
        borderRadius: BorderRadius.circular(12),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.insert_drive_file_rounded,
              color: isMe ? Colors.white : const Color(0xFF0262EC),
              size: 22,
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    text,
                    style: TextStyle(
                      color: isMe ? Colors.white : const Color(0xFF1A2340),
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    'chatOpenFile'.tr(),
                    style: TextStyle(
                      color: isMe ? Colors.white70 : const Color(0xFF8593A8),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Text(
      text,
      style: TextStyle(
        color: isMe ? Colors.white : const Color(0xFF1A2340),
        fontSize: 13,
        height: 1.4,
      ),
    );
  }

  Widget _buildVideoCallContent(bool isMe) {
    final data = VideoCallLogData.fromMessage(message);
    final title = VideoCallLogService.bubbleTitle(data: data, isMe: isMe);
    final duration = VideoCallLogService.formatDuration(data.durationSeconds);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.video_call_rounded,
          color: isMe ? Colors.white : const Color(0xFF0262EC),
          size: 22,
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: isMe ? Colors.white : const Color(0xFF1A2340),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                duration,
                style: TextStyle(
                  color: isMe ? Colors.white70 : const Color(0xFF8593A8),
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _openImage(BuildContext context, String fileUrl) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => GalleryView(
          imageUrl: [fileUrl],
          imageProvider: [CachedNetworkImageProvider(fileUrl)],
        ),
      ),
    );
  }
}
