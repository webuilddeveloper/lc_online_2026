import 'dart:io';

import 'package:LawyerOnline/component/appbar.dart';
import 'package:LawyerOnline/component/app_dropdown.dart';
import 'package:LawyerOnline/component/dialog_service.dart';
import 'package:LawyerOnline/component/media_picker_sheet.dart';
import 'package:LawyerOnline/models/user_profile_store.dart';
import 'package:LawyerOnline/services/auth_service.dart';
import 'package:LawyerOnline/shared/api_provider.dart';
import 'package:LawyerOnline/shared/responsive/app_layout.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

class _LawyerDocument {
  final String name;
  final String? path;
  final String? extension;

  const _LawyerDocument({
    required this.name,
    required this.path,
    this.extension,
  });

  factory _LawyerDocument.fromXFile(XFile file) {
    final parts = file.name.split('.');
    return _LawyerDocument(
      name: file.name,
      path: file.path,
      extension: parts.length > 1 ? parts.last.toLowerCase() : null,
    );
  }

  factory _LawyerDocument.fromPlatformFile(PlatformFile file) {
    return _LawyerDocument(
      name: file.name,
      path: file.path,
      extension: file.extension?.toLowerCase(),
    );
  }

  String get fileType {
    final ext = (extension ?? name.split('.').last).toLowerCase();
    if (['jpg', 'jpeg', 'png', 'gif', 'webp'].contains(ext)) return 'image';
    if (ext == 'pdf') return 'pdf';
    if (['doc', 'docx'].contains(ext)) return 'word';
    if (['xls', 'xlsx'].contains(ext)) return 'excel';
    return 'other';
  }
}

class LawyerApplyPage extends StatefulWidget {
  const LawyerApplyPage({super.key});

  @override
  State<LawyerApplyPage> createState() => _LawyerApplyPageState();
}

class _LawyerApplyPageState extends State<LawyerApplyPage> {
  final TextEditingController _lawyerNoCtrl = TextEditingController();
  final GlobalKey _lawyerNoKey = GlobalKey();
  final GlobalKey _specialtyKey = GlobalKey();
  final GlobalKey _documentKey = GlobalKey();
  final ImagePicker _picker = ImagePicker();

  static const Color _blue = Color(0xFF0262EC);
  static const Color _bg = Color(0xFFEEF2F5);
  static const Color _border = Color(0xFFECEDF0);
  static const Color _errorColor = Color(0xFFD32F2F);

  bool _isLoading = false;
  String? _lawyerNoError;
  bool _specialtyError = false;
  bool _documentError = false;
  bool _provinceError = false;
  String provinceTitle = '';
  String provinceCode = '';

  List<dynamic> _specialtyOptions = [];
  Set<String> _selectedSpecialties = {};
  List<dynamic> provinceList = [];
  final List<_LawyerDocument> _documents = [];

  bool _isBarNumValid(String b) => RegExp(r'^\d+/\d{4}$').hasMatch(b.trim());

  @override
  void initState() {
    super.initState();
    _loadOptions();
  }

  Future<void> _loadOptions() async {
    final subTopic = await postDio("${server}/m/topic/subTopic/read", {});
    final province = await postDio("${serverLC}route/province/read", {});
    if (!mounted) return;
    setState(() {
      _specialtyOptions = [...(subTopic['objectData'] ?? [])];
      provinceList = [
        {"code": "0", "title": "เลือกจังหวัด"},
        ...(province['objectData'] ?? []),
      ];
    });
  }

  Future<void> _showDocumentPicker() async {
    await MediaPickerSheet.showDocumentSources(
      context,
      onImages: _pickImages,
      onFiles: _pickFiles,
    );
  }

  Future<void> _pickImages() async {
    final images = await _picker.pickMultiImage();
    if (images.isEmpty) return;
    setState(() {
      _documents.addAll(images.map(_LawyerDocument.fromXFile));
      _documentError = false;
    });
  }

  Future<void> _pickFiles() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
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
    setState(() {
      _documents.addAll(
        result.files
            .where((f) => f.path != null && f.path!.isNotEmpty)
            .map(_LawyerDocument.fromPlatformFile),
      );
      _documentError = false;
    });
  }

  Future<List<String>> _uploadDocuments() async {
    final urls = <String>[];
    for (final doc in _documents) {
      if (doc.path == null || doc.path!.isEmpty) continue;
      final url = await uploadImage(File(doc.path!));
      urls.add(url);
    }
    return urls;
  }

  Future<void> _submit() async {
    setState(() {
      _lawyerNoError = null;
      _specialtyError = false;
      _documentError = false;
      _provinceError = false;
    });

    GlobalKey? firstErrorKey;

    if (_lawyerNoCtrl.text.trim().isEmpty) {
      _lawyerNoError = 'lawyerNoRequired'.tr();
      firstErrorKey ??= _lawyerNoKey;
    } else if (!_isBarNumValid(_lawyerNoCtrl.text)) {
      _lawyerNoError = 'lawyerNoInvalid'.tr();
      firstErrorKey ??= _lawyerNoKey;
    }

    if (provinceCode.isEmpty || provinceCode == '0') {
      _provinceError = true;
      firstErrorKey ??= _lawyerNoKey;
    }

    if (_selectedSpecialties.isEmpty) {
      _specialtyError = true;
      firstErrorKey ??= _specialtyKey;
    }

    if (_documents.isEmpty) {
      _documentError = true;
      firstErrorKey ??= _documentKey;
    }

    if (firstErrorKey != null) {
      setState(() {});
      return;
    }

    final store = UserProfileStore.instance;
    setState(() => _isLoading = true);
    try {
      final documentUrls = await _uploadDocuments();
      await AuthService.applyLawyer(
        code: store.code,
        email: store.email,
        firstName: store.firstName,
        lastName: store.lastName,
        phone: store.phone,
        lawyerNo: _lawyerNoCtrl.text.trim(),
        expertiseList: _selectedSpecialties.toList(),
        provinceCode: provinceCode,
        provinceTitle: provinceTitle,
        documentList: documentUrls,
      );

      await store.setLawyerApplyPending(true);

      if (!mounted) return;
      setState(() => _isLoading = false);
      _showSuccessDialog();
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showError(e.toString());
    }
  }

  void _showError(String msg) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('registerAlert'.tr()),
        content: Text(msg),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('ok'.tr(), style: const TextStyle(color: _blue)),
          ),
        ],
      ),
    );
  }

  void _showSuccessDialog() {
    DialogService.showSuccess(
      context,
      title: 'lawyerApplySuccessTitle'.tr(),
      message: 'lawyerApplySuccessMessage'.tr(),
      onClose: () => Navigator.pop(context, true),
    );
  }

  void _showSpecialtyDialog() {
    final Set<String> tempSelected = Set.from(_selectedSpecialties);
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.4),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return Dialog(
              backgroundColor: Colors.transparent,
              insetPadding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(28),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              'specialty'.tr(),
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: _blue,
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.pop(ctx),
                            icon: const Icon(Icons.close_rounded),
                          ),
                        ],
                      ),
                    ),
                    Flexible(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _specialtyOptions
                              .where((o) => o['code'] != '0')
                              .map((option) {
                            final selected =
                                tempSelected.contains(option['code']);
                            return GestureDetector(
                              onTap: () {
                                setDialogState(() {
                                  if (selected) {
                                    tempSelected.remove(option['code']);
                                  } else {
                                    tempSelected.add(option['code']);
                                  }
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 9),
                                decoration: BoxDecoration(
                                  color: selected ? _blue : const Color(0xFFF5F7FA),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: selected ? _blue : const Color(0xFFE0E3EA),
                                  ),
                                ),
                                child: Text(
                                  option['title'],
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: selected
                                        ? Colors.white
                                        : const Color(0xFF444444),
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _blue,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          onPressed: () {
                            setState(() {
                              _selectedSpecialties
                                ..clear()
                                ..addAll(tempSelected);
                              if (_selectedSpecialties.isNotEmpty) {
                                _specialtyError = false;
                              }
                            });
                            Navigator.pop(ctx);
                          },
                          child: Text('ok'.tr(), style: TextStyle(color: Colors.white,),),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: appBar(
        title: 'applyAsLawyer'.tr(),
        backBtn: true,
        rightBtn: false,
        backAction: () => Navigator.pop(context),
        rightAction: () {},
      ),
      body: AppLayout(
        maxWidth: 720,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 100),
          children: [
            _buildCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'lawyerApplyDescription'.tr(),
                    style: GoogleFonts.prompt(
                      fontSize: 13,
                      color: const Color(0xFF666666),
                    ),
                  ),
                  const SizedBox(height: 20),
                  _sectionLabel('จังหวัด'.tr()),
                  const SizedBox(height: 6),
                  AppDropdownField.fromMaps(
                    value: provinceCode,
                    list: provinceList,
                    hint: 'เลือกจังหวัด',
                    prefixIcon: Icons.location_on_outlined,
                    errorText: _provinceError ? 'provinceRequired'.tr() : null,
                    onChanged: (value) {
                      setState(() {
                        provinceCode = value ?? '';
                        provinceTitle = provinceList.firstWhere(
                            (x) => x['code'] == value,
                            orElse: () => {'title': ''})['title'];
                        _provinceError = false;
                      });
                    },
                  ),
                  if (_provinceError) ...[
                    const SizedBox(height: 4),
                    Text(
                      'provinceRequired'.tr(),
                      style: GoogleFonts.prompt(
                        fontSize: 11,
                        color: _errorColor,
                      ),
                    ),
                  ],
                  const SizedBox(height: 14),
                  _sectionLabel('lawyerNo'.tr()),
                  const SizedBox(height: 6),
                  TextField(
                    key: _lawyerNoKey,
                    controller: _lawyerNoCtrl,
                    decoration: _inputDecoration('lawyerNoHint'.tr(),
                        icon: Icons.badge_outlined,
                        errorText: _lawyerNoError),
                    onChanged: (_) => setState(() => _lawyerNoError = null),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    key: _specialtyKey,
                    children: [
                      _sectionLabel('specialty'.tr()),
                      const SizedBox(width: 8),
                      if (_selectedSpecialties.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: _blue,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '${_selectedSpecialties.length}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                    ],
                  ),
                  if (_specialtyError) ...[
                    const SizedBox(height: 4),
                    Text(
                      'specialtyRequired'.tr(),
                      style: GoogleFonts.prompt(
                        fontSize: 11,
                        color: _errorColor,
                      ),
                    ),
                  ],
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 6,
                    runSpacing: 0,
                    children: [
                      ..._selectedSpecialties.map((code) {
                        final option = _specialtyOptions.firstWhere(
                          (o) => o['code'] == code,
                          orElse: () => {'code': code, 'title': code},
                        );
                        return Chip(
                          label: Text(option['title']),
                          color: WidgetStateProperty.all<Color?>(Colors.white),
                          side: BorderSide(color: _blue.withOpacity(0.2)),
                          deleteIcon: const Icon(Icons.close, size: 16),
                          onDeleted: () =>
                              setState(() => _selectedSpecialties.remove(code)),
                        );
                      }),
                      ActionChip(
                        avatar: const Icon(Icons.add, size: 16, color: _blue),
                        label: Text('add'.tr()),
                        color: WidgetStateProperty.all<Color?>(Colors.white),
                        onPressed: _showSpecialtyDialog,
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _sectionLabel('lawyerApplyDocuments'.tr()),
                  const SizedBox(height: 6),
                  Text(
                    'lawyerApplyDocumentsHint'.tr(),
                    style: GoogleFonts.prompt(
                      fontSize: 11,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 10),
                  GestureDetector(
                    key: _documentKey,
                    onTap: _showDocumentPicker,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      decoration: BoxDecoration(
                        color: _documentError
                            ? _errorColor.withOpacity(0.04)
                            : const Color(0xFFFAFAFA),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: _documentError ? _errorColor : _border,
                        ),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            Icons.upload_file_rounded,
                            color: _documentError ? _errorColor : _blue,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'lawyerApplyUpload'.tr(),
                            style: TextStyle(
                              color: _documentError ? _errorColor : _blue,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (_documentError) ...[
                    const SizedBox(height: 4),
                    Text(
                      'lawyerApplyDocumentsRequired'.tr(),
                      style: GoogleFonts.prompt(
                        fontSize: 11,
                        color: _errorColor,
                      ),
                    ),
                  ],
                  if (_documents.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _documents.asMap().entries.map((entry) {
                        final index = entry.key;
                        final doc = entry.value;
                        return Stack(
                          children: [
                            _buildDocumentPreview(doc),
                            Positioned(
                              top: 0,
                              right: 0,
                              child: GestureDetector(
                                onTap: () => setState(() {
                                  _documents.removeAt(index);
                                }),
                                child: Container(
                                  decoration: const BoxDecoration(
                                    color: Colors.black54,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.close,
                                    size: 16,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _blue,
                  minimumSize: const Size.fromHeight(52),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: _isLoading ? null : _submit,
                child: _isLoading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.5,
                        ),
                      )
                    : Text(
                        'applyAsLawyer'.tr(),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDocumentPreview(_LawyerDocument doc) {
    const size = 88.0;

    Widget content;
    Color bgColor;

    switch (doc.fileType) {
      case 'image':
        content = Image.file(
          File(doc.path!),
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => const Icon(Icons.image_outlined),
        );
        bgColor = Colors.grey.shade200;
        break;
      case 'pdf':
        content = const Icon(Icons.picture_as_pdf, size: 36, color: Colors.red);
        bgColor = Colors.red.shade50;
        break;
      case 'word':
        content =
            const Icon(Icons.description, size: 36, color: Colors.blue);
        bgColor = Colors.blue.shade50;
        break;
      case 'excel':
        content =
            const Icon(Icons.table_chart, size: 36, color: Colors.green);
        bgColor = Colors.green.shade50;
        break;
      default:
        content = const Icon(Icons.insert_drive_file,
            size: 36, color: Colors.grey);
        bgColor = Colors.grey.shade100;
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _border),
      ),
      child: doc.fileType == 'image'
          ? ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: content,
            )
          : Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                content,
                const SizedBox(height: 4),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: Text(
                    doc.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.prompt(fontSize: 9),
                  ),
                ),
              ],
            ),
    );
  }

  InputDecoration _inputDecoration(String hint,
      {IconData? icon, String? errorText}) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: icon != null ? Icon(icon, size: 20) : null,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: errorText != null ? _errorColor : _border,
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: errorText != null ? _errorColor : _border,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: errorText != null ? _errorColor : _blue,
          width: 1.5,
        ),
      ),
      fillColor: errorText != null
          ? _errorColor.withOpacity(0.04)
          : const Color(0xFFFAFAFA),
      filled: true,
    );
  }

  Widget _buildCard({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.05),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _sectionLabel(String text) => Text(
        text,
        style: GoogleFonts.prompt(
          fontSize: 13,
          color: _blue,
          fontWeight: FontWeight.w500,
        ),
      );

  @override
  void dispose() {
    _lawyerNoCtrl.dispose();
    super.dispose();
  }
}
