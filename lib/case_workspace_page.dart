import 'dart:io';

import 'package:LawyerOnline/component/appbar.dart';
import 'package:LawyerOnline/component/dialog_service.dart';
import 'package:LawyerOnline/component/loading_service.dart';
import 'package:LawyerOnline/models/user_profile_store.dart';
import 'package:LawyerOnline/services/consultation_summary_service.dart';
import 'package:LawyerOnline/services/case_workspace_service.dart';
import 'package:LawyerOnline/shared/api_provider.dart';
import 'package:LawyerOnline/shared/app_typography.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class CaseWorkspacePage extends StatefulWidget {
  final String caseCode;
  final bool canEditSummary;

  const CaseWorkspacePage({
    super.key,
    required this.caseCode,
    this.canEditSummary = false,
  });

  @override
  State<CaseWorkspacePage> createState() => _CaseWorkspacePageState();
}

class _CaseWorkspacePageState extends State<CaseWorkspacePage> {
  static const _primary = Color(0xFF0262EC);

  bool _loading = true;
  CaseWorkspaceData? _data;
  final _summaryCtrl = TextEditingController();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _summaryCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final data = await CaseWorkspaceService.load(widget.caseCode);
      _summaryCtrl.text = data.summary;
      if (mounted) setState(() => _data = data);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _saveSummary() async {
    setState(() => _saving = true);
    try {
      await CaseWorkspaceService.saveSummary(
        caseCode: widget.caseCode,
        summary: _summaryCtrl.text.trim(),
        userType: '',
      );
      if (!mounted) return;
      DialogService.showSuccess(
        context,
        title: 'successTitle'.tr(),
        message: 'caseWorkspaceSummarySaved'.tr(),
      );
      await _load();
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _generateAiSummary() async {
    setState(() => _saving = true);
    try {
      final text = await ConsultationSummaryService.generate(
        widget.caseCode,
        updateBy: UserProfileStore.instance.code,
      );
      if (text != null && text.isNotEmpty) {
        _summaryCtrl.text = text;
      }
      if (!mounted) return;
      DialogService.showSuccess(
        context,
        title: 'successTitle'.tr(),
        message: 'caseWorkspaceAiGenerated'.tr(),
      );
      await _load();
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _uploadDocument() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: ImageSource.gallery);
    if (file == null) return;

    DialogService.showLoading(context);
    try {
      final url = await uploadImageX(file);
      await CaseWorkspaceService.addDocument(
        caseCode: widget.caseCode,
        name: file.name,
        url: url,
      );
      if (!mounted) return;
      Navigator.pop(context);
      await _load();
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      DialogService.showError(
        context,
        title: 'errorTitle'.tr(),
        message: e.toString(),
      );
    }
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles();
    if (result == null || result.files.isEmpty) return;
    final file = result.files.first;
    if (file.path == null) return;

    DialogService.showLoading(context);
    try {
      final url = await uploadImage(File(file.path!));
      await CaseWorkspaceService.addDocument(
        caseCode: widget.caseCode,
        name: file.name,
        url: url,
      );
      if (!mounted) return;
      Navigator.pop(context);
      await _load();
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      DialogService.showError(
        context,
        title: 'errorTitle'.tr(),
        message: e.toString(),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEEF2F5),
      appBar: appBar(
        title: 'caseWorkspaceTitle'.tr(),
        backBtn: true,
        rightBtn: false,
        backAction: () => Navigator.pop(context),
        rightAction: () {},
      ),
      body: _loading
          ? AppLoadingView(message: 'loading'.tr())
          : _data == null
              ? Center(child: Text('caseWorkspaceNotFound'.tr()))
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      _sectionTitle('caseWorkspaceTimeline'.tr()),
                      const SizedBox(height: 10),
                      ..._data!.timeline.map(_timelineTile),
                      const SizedBox(height: 20),
                      _sectionTitle('caseWorkspaceDocuments'.tr()),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _uploadDocument,
                              icon: const Icon(Icons.image_outlined, size: 18),
                              label: Text('caseWorkspaceAddImage'.tr()),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _pickFile,
                              icon: const Icon(Icons.attach_file, size: 18),
                              label: Text('caseWorkspaceAddFile'.tr()),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      if (_data!.documents.isEmpty)
                        Text('caseWorkspaceNoDocuments'.tr(),
                            style: AppTypography.hint())
                      else
                        ..._data!.documents.map(_docTile),
                      const SizedBox(height: 20),
                      _sectionTitle('caseWorkspaceSummary'.tr()),
                      const SizedBox(height: 10),
                      if (widget.canEditSummary)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: OutlinedButton.icon(
                            onPressed: _saving ? null : _generateAiSummary,
                            icon: const Icon(Icons.auto_awesome_rounded, size: 18),
                            label: Text('caseWorkspaceGenerateAi'.tr()),
                          ),
                        ),
                      TextField(
                        controller: _summaryCtrl,
                        readOnly: !widget.canEditSummary,
                        maxLines: 5,
                        decoration: InputDecoration(
                          hintText: 'caseWorkspaceSummaryHint'.tr(),
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                      if (widget.canEditSummary) ...[
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _saving ? null : _saveSummary,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _primary,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: _saving
                                ? const AppRingSpinner(
                                    color: Colors.white, size: 20)
                                : Text('saveButton'.tr(),
                                    style: AppTypography.button()),
                          ),
                        ),
                      ],
                      const SizedBox(height: 12),
                      _disclaimerCard(),
                    ],
                  ),
                ),
    );
  }

  Widget _sectionTitle(String title) => Text(
        title,
        style: AppTypography.prompt(
          fontSize: 15,
          fontWeight: FontWeight.w700,
          color: const Color(0xFF1A2340),
        ),
      );

  Widget _timelineTile(CaseTimelineEvent event) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: const BoxDecoration(
              color: _primary,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(event.title,
                    style: AppTypography.prompt(
                        fontWeight: FontWeight.w600, fontSize: 14)),
                Text(event.subtitle,
                    style: AppTypography.hint().copyWith(fontSize: 12)),
              ],
            ),
          ),
          Text(event.at,
              style: AppTypography.hint().copyWith(fontSize: 11)),
        ],
      ),
    );
  }

  Widget _docTile(CaseDocument doc) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.description_outlined, color: _primary),
      title: Text(doc.name, style: AppTypography.prompt(fontSize: 13)),
      subtitle: Text(doc.uploadedAt.split('T').first,
          style: AppTypography.hint().copyWith(fontSize: 11)),
    );
  }

  Widget _disclaimerCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8E8),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        'legalDisclaimerShort'.tr(),
        style: AppTypography.prompt(fontSize: 11, color: const Color(0xFF7A5B00)),
      ),
    );
  }
}
