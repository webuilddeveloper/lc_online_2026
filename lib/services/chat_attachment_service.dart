import 'dart:io';

import 'package:LawyerOnline/component/media_picker_sheet.dart';
import 'package:LawyerOnline/services/chat_service.dart';
import 'package:LawyerOnline/shared/api_provider.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class ChatAttachmentService {
  static final ImagePicker _picker = ImagePicker();

  static String readType(Map<String, dynamic> message) =>
      message['type']?.toString() ?? 'text';

  static String readFileUrl(Map<String, dynamic> message) {
    final fileUrl = message['fileUrl']?.toString() ?? '';
    if (fileUrl.isNotEmpty) return fileUrl;
    final type = readType(message);
    if (type == 'image' || type == 'file') {
      final content = message['content']?.toString() ?? '';
      if (content.startsWith('http')) return content;
    }
    return '';
  }

  static String readFileName(Map<String, dynamic> message) =>
      message['fileName']?.toString() ?? '';

  static String readDisplayText(Map<String, dynamic> message) {
    final type = readType(message);
    if (type == 'image') return '';
    if (type == 'file') {
      final name = readFileName(message);
      return name.isNotEmpty ? name : 'chatAttachmentFile'.tr();
    }
    return message['content']?.toString() ?? '';
  }

  static Future<void> showPicker({
    required BuildContext context,
    required ChatService chatService,
    required String roomCode,
    required String senderId,
    required ValueChanged<bool> onUploadingChanged,
  }) async {
    await MediaPickerSheet.showChatSources(
      context,
      onCamera: () => _pickAndSend(
        context: context,
        chatService: chatService,
        roomCode: roomCode,
        senderId: senderId,
        onUploadingChanged: onUploadingChanged,
        source: _AttachmentSource.camera,
      ),
      onGallery: () => _pickAndSend(
        context: context,
        chatService: chatService,
        roomCode: roomCode,
        senderId: senderId,
        onUploadingChanged: onUploadingChanged,
        source: _AttachmentSource.gallery,
      ),
      onFiles: () => _pickAndSend(
        context: context,
        chatService: chatService,
        roomCode: roomCode,
        senderId: senderId,
        onUploadingChanged: onUploadingChanged,
        source: _AttachmentSource.file,
      ),
    );
  }

  static Future<void> _pickAndSend({
    required BuildContext context,
    required ChatService chatService,
    required String roomCode,
    required String senderId,
    required ValueChanged<bool> onUploadingChanged,
    required _AttachmentSource source,
  }) async {
    try {
      File? file;
      String fileName = '';
      var type = 'file';

      switch (source) {
        case _AttachmentSource.camera:
          final image = await _picker.pickImage(
            source: ImageSource.camera,
            imageQuality: 80,
          );
          if (image == null || image.path.isEmpty) return;
          file = File(image.path);
          fileName = image.name;
          type = 'image';
          break;
        case _AttachmentSource.gallery:
          final image = await _picker.pickImage(
            source: ImageSource.gallery,
            imageQuality: 80,
          );
          if (image == null || image.path.isEmpty) return;
          file = File(image.path);
          fileName = image.name;
          type = 'image';
          break;
        case _AttachmentSource.file:
          final result = await FilePicker.platform.pickFiles(
            allowMultiple: false,
            type: FileType.custom,
            allowedExtensions: [
              'jpg',
              'jpeg',
              'png',
              'gif',
              'webp',
              'pdf',
              'doc',
              'docx',
            ],
          );
          if (result == null || result.files.isEmpty) return;
          final picked = result.files.first;
          if (picked.path == null || picked.path!.isEmpty) return;
          file = File(picked.path!);
          fileName = picked.name;
          final ext = (picked.extension ?? picked.name.split('.').last)
              .toLowerCase();
          type = ['jpg', 'jpeg', 'png', 'gif', 'webp'].contains(ext)
              ? 'image'
              : 'file';
          break;
      }

      onUploadingChanged(true);
      final fileUrl = await uploadImage(file);
      await chatService.sendMessage(
        roomCode,
        senderId,
        content: '',
        type: type,
        fileUrl: fileUrl,
        fileName: fileName,
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('chatUploadFailed'.tr())),
        );
      }
    } finally {
      onUploadingChanged(false);
    }
  }
}

enum _AttachmentSource { camera, gallery, file }
