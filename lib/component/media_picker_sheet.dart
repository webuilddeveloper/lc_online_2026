import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class MediaPickerOption {
  const MediaPickerOption({
    required this.icon,
    required this.label,
    required this.onTap,
    this.iconColor,
    this.backgroundColor,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? iconColor;
  final Color? backgroundColor;
}

class MediaPickerSheet {
  static const Color primary = Color(0xFF0262EC);

  static Future<void> show(
    BuildContext context, {
    String? title,
    required List<MediaPickerOption> options,
    bool showCancel = true,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => _MediaPickerSheetBody(
        title: title,
        options: options,
        showCancel: showCancel,
      ),
    );
  }

  static Future<void> showImageSources(
    BuildContext context, {
    required VoidCallback onCamera,
    required VoidCallback onGallery,
    String? title,
  }) {
    return show(
      context,
      title: title ?? 'addImages'.tr(),
      options: [
        MediaPickerOption(
          icon: Icons.photo_library_rounded,
          label: 'gallery'.tr(),
          backgroundColor: const Color(0xFFE8F1FD),
          iconColor: primary,
          onTap: onGallery,
        ),
        MediaPickerOption(
          icon: Icons.camera_alt_rounded,
          label: 'camera'.tr(),
          backgroundColor: const Color(0xFFEEF2F5),
          iconColor: primary,
          onTap: onCamera,
        ),
      ],
    );
  }

  static Future<void> showDocumentSources(
    BuildContext context, {
    required VoidCallback onImages,
    required VoidCallback onFiles,
    String? title,
  }) {
    return show(
      context,
      title: title ?? 'lawyerApplyUpload'.tr(),
      options: [
        MediaPickerOption(
          icon: Icons.photo_library_rounded,
          label: 'lawyerApplyPickImage'.tr(),
          backgroundColor: const Color(0xFFE8F1FD),
          iconColor: primary,
          onTap: onImages,
        ),
        MediaPickerOption(
          icon: Icons.folder_open_rounded,
          label: 'lawyerApplyPickFile'.tr(),
          backgroundColor: const Color(0xFFFFF4E5),
          iconColor: const Color(0xFFE65100),
          onTap: onFiles,
        ),
      ],
    );
  }

  static Future<void> showChatSources(
    BuildContext context, {
    required VoidCallback onCamera,
    required VoidCallback onGallery,
    required VoidCallback onFiles,
    String? title,
  }) {
    return show(
      context,
      title: title ?? 'chatAttachTitle'.tr(),
      options: [
        MediaPickerOption(
          icon: Icons.camera_alt_rounded,
          label: 'camera'.tr(),
          backgroundColor: const Color(0xFFEEF2F5),
          iconColor: primary,
          onTap: onCamera,
        ),
        MediaPickerOption(
          icon: Icons.photo_library_rounded,
          label: 'gallery'.tr(),
          backgroundColor: const Color(0xFFE8F1FD),
          iconColor: primary,
          onTap: onGallery,
        ),
        MediaPickerOption(
          icon: Icons.folder_open_rounded,
          label: 'lawyerApplyPickFile'.tr(),
          backgroundColor: const Color(0xFFFFF4E5),
          iconColor: const Color(0xFFE65100),
          onTap: onFiles,
        ),
      ],
    );
  }
}

class _MediaPickerSheetBody extends StatelessWidget {
  const _MediaPickerSheetBody({
    required this.options,
    this.title,
    this.showCancel = true,
  });

  final String? title;
  final List<MediaPickerOption> options;
  final bool showCancel;

  static const _titleColor = Color(0xFF1A1A2E);
  static const _borderColor = Color(0xFFECEDF0);

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 24,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: EdgeInsets.fromLTRB(20, 12, 20, bottomInset > 0 ? 8 : 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFDDE1E8),
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
                if (title != null && title!.isNotEmpty) ...[
                  const SizedBox(height: 18),
                  Text(
                    title!,
                    style: GoogleFonts.prompt(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      color: _titleColor,
                    ),
                  ),
                ] else
                  const SizedBox(height: 12),
                const SizedBox(height: 18),
                Row(
                  children: [
                    for (var i = 0; i < options.length; i++) ...[
                      if (i > 0) const SizedBox(width: 12),
                      Expanded(child: _OptionTile(option: options[i])),
                    ],
                  ],
                ),
                if (showCancel) ...[
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    style: TextButton.styleFrom(
                      minimumSize: const Size.fromHeight(44),
                      foregroundColor: const Color(0xFF8E95A2),
                    ),
                    child: Text(
                      'cancel'.tr(),
                      style: GoogleFonts.prompt(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _OptionTile extends StatelessWidget {
  const _OptionTile({required this.option});

  final MediaPickerOption option;

  @override
  Widget build(BuildContext context) {
    final iconColor = option.iconColor ?? MediaPickerSheet.primary;
    final iconBg = option.backgroundColor ?? const Color(0xFFE8F1FD);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          Navigator.pop(context);
          option.onTap();
        },
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: _MediaPickerSheetBody._borderColor),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(option.icon, color: iconColor, size: 28),
              ),
              const SizedBox(height: 10),
              Text(
                option.label,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.prompt(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: _MediaPickerSheetBody._titleColor,
                  height: 1.25,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
