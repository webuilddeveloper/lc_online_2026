import 'dart:io';
import 'package:LawyerOnline/component/appbar.dart';
import 'package:LawyerOnline/component/app_dropdown.dart';
import 'package:LawyerOnline/consult/consult_sum.dart';
import 'package:LawyerOnline/models/location/province_model.dart';
import 'package:LawyerOnline/services/thailand_location_service.dart';
import 'package:LawyerOnline/shared/api_provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:LawyerOnline/shared/responsive/app_layout.dart';
import 'package:easy_localization/easy_localization.dart';

class ConsultPage extends StatefulWidget {
  const ConsultPage({super.key});

  @override
  State<ConsultPage> createState() => _ConsultPageState();
}

class _ConsultPageState extends State<ConsultPage> {
  dynamic _selectedTopic;
  dynamic _selectedSubCase;
  bool isLoadingLawyers = true;

  String? _selectedProvince;
  String? _selectedProvinceCode;
  String? _selectedDistrict;
  String? _selectedDistrictCode;

  final TextEditingController _detailController = TextEditingController();
  final TextEditingController _demandController = TextEditingController();

  List<File> _selectedImages = [];
  final ImagePicker _picker = ImagePicker();

  List<dynamic> _caseTypeList = [];
  List<ProvinceModel> _provinceOptions = [];
  List<DistrictModel> _districtOptions = [];
  bool _loadingProvinces = true;

  Future<void> _loadProvinces() async {
    setState(() => _loadingProvinces = true);
    final list = await ThailandLocationService.provinces();
    if (!mounted) return;
    setState(() {
      _provinceOptions = list;
      _loadingProvinces = false;
      if (_selectedProvince == null && list.isNotEmpty) {
        _selectedProvince = list.first.title;
        _selectedProvinceCode = list.first.code;
      }
    });
    if (_selectedProvinceCode != null) {
      await _loadDistricts(_selectedProvinceCode!);
    }
  }

  Future<void> _loadDistricts(String provinceCode) async {
    final list = await ThailandLocationService.districts(provinceCode);
    if (!mounted) return;
    setState(() {
      _districtOptions = list;
      _selectedDistrict = null;
      _selectedDistrictCode = null;
    });
  }

  Future<void> readTopic() async {
    setState(() => isLoadingLawyers = true);
    try {
      final param = await postDio('${server}/m/topic/read', {});
      if (!mounted) return;
      setState(() {
        _caseTypeList = param['objectData'] ?? [];
        isLoadingLawyers = false;
      });
    } catch (_) {
      if (mounted) setState(() => isLoadingLawyers = false);
    }
  }

  List<Map<String, dynamic>> get _subCases {
    if (_selectedTopic == null) return [];
    final raw = _selectedTopic!['subTopics'] ?? _selectedTopic!['subCase'];
    if (raw == null || raw is! List) return [];
    return (raw as List<dynamic>)
        .whereType<Map<String, dynamic>>()
        .where((s) => (s['title'] as String? ?? '').trim().isNotEmpty)
        .toList();
  }

  bool get _hasSubCase => _subCases.isNotEmpty;

  bool get _canSubmit {
    if (_selectedTopic == null) return false;
    if (_hasSubCase && _selectedSubCase == null) return false;
    if (_selectedProvince == null) return false;
    if (_detailController.text.trim().isEmpty) return false;
    return true;
  }

  Future<void> _pickImages() async {
    final List<XFile> images = await _picker.pickMultiImage();
    if (images.isNotEmpty) {
      setState(() {
        _selectedImages.addAll(images.map((e) => File(e.path)));
      });
    }
  }

  @override
  void initState() {
    super.initState();
    readTopic();
    _loadProvinces();
  }

  @override
  void dispose() {
    _detailController.dispose();
    _demandController.dispose();
    super.dispose();
  }

   Widget _loadingState() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const topicColor = Color(0xFF0262EC);

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      behavior: HitTestBehavior.opaque,
      child: Scaffold(
        backgroundColor: const Color(0xFFEEF2F5),
        appBar: appBar(
          title: 'consultOnlineTitle'.tr(),
          backBtn: true,
          rightBtn: false,
          rightAction: () {},
          backAction: () => Navigator.pop(context, false),
        ),
        body: AppLayout(
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      _buildHeaderCard(),
                      const SizedBox(height: 16),
                      if (isLoadingLawyers)
                        _loadingState()
                      else
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 10,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildTopicField(),
                              const SizedBox(height: 20),
                              if (_selectedTopic != null && _hasSubCase) ...[
                                _buildSubCaseField(topicColor),
                                const SizedBox(height: 20),
                              ],
                              _buildDropdownField(
                                label: 'province'.tr(),
                                hint: _loadingProvinces
                                    ? 'loading'.tr()
                                    : 'selectProvince'.tr(),
                                icon: Icons.location_on_outlined,
                                value: _selectedProvince,
                                items: _provinceOptions
                                    .map((p) => p.title)
                                    .toList(),
                                onChanged: (val) {
                                  final province = _provinceOptions.firstWhere(
                                    (p) => p.title == val,
                                    orElse: () =>
                                        const ProvinceModel(code: '', title: ''),
                                  );
                                  setState(() {
                                    _selectedProvince = val;
                                    _selectedProvinceCode = province.code;
                                  });
                                  if (province.code.isNotEmpty) {
                                    _loadDistricts(province.code);
                                  }
                                },
                              ),
                              if (_districtOptions.isNotEmpty) ...[
                                const SizedBox(height: 20),
                                _buildDropdownField(
                                  label: 'district'.tr(),
                                  hint: 'selectDistrict'.tr(),
                                  icon: Icons.map_outlined,
                                  value: _selectedDistrict,
                                  items: _districtOptions
                                      .map((d) => d.title)
                                      .toList(),
                                  onChanged: (val) {
                                    final district =
                                        _districtOptions.firstWhere(
                                      (d) => d.title == val,
                                      orElse: () => const DistrictModel(
                                          code: '', title: '', provinceCode: ''),
                                    );
                                    setState(() {
                                      _selectedDistrict = val;
                                      _selectedDistrictCode = district.code;
                                    });
                                  },
                                ),
                              ],
                              const SizedBox(height: 20),
                              _buildTextArea(
                                label: 'consultEventSummary'.tr(),
                                hint:
                                    'consultEventHint'.tr(),
                                controller: _detailController,
                              ),
                              const SizedBox(height: 20),
                              _buildTextArea(
                                label: 'consultDemand'.tr(),
                                hint:
                                    'consultDemandHint'.tr(),
                                controller: _demandController,
                              ),
                              const SizedBox(height: 20),
                              _buildImageField(),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              _buildBottomButton(topicColor),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0262EC), Color(0xFF0485FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child:
              const Icon(Icons.balance_outlined, color: Colors.white, size: 24),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('consultBasicInfo'.tr(),
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16)),
              const SizedBox(height: 2),
              Text('consultBasicInfoHint'.tr(),
                  style: TextStyle(color: Colors.white70, fontSize: 12)),
            ],
          ),
        ),
      ]),
    );
  }

  Widget _buildTopicField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'consultTopicType'.tr(),
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1A2340),
          ),
        ),
        const SizedBox(height: 10),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            childAspectRatio: 1,
          ),
          itemCount: _caseTypeList.length,
          itemBuilder: (_, i) {
            final item = _caseTypeList[i];
            final isSelected = _selectedTopic?['code'] == item['code'];
            return GestureDetector(
              onTap: () => setState(() {
                _selectedTopic = item;
                _selectedSubCase = null;
              }),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFF0262EC).withOpacity(0.1)
                      : const Color(0xFFF8F9FB),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isSelected
                        ? const Color(0xFF0262EC)
                        : const Color(0xFFE2E8F4),
                    width: isSelected ? 1.5 : 1,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: const Color(0xFF0262EC).withOpacity(0.2),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          )
                        ]
                      : [],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _topicImage(item['imageUrl']?.toString() ?? ''),
                    const SizedBox(height: 5),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Text(
                        item['title']?.toString() ?? '',
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight:
                              isSelected ? FontWeight.w700 : FontWeight.w500,
                          color: isSelected
                              ? const Color(0xFF0262EC)
                              : const Color(0xFF5B6E8A),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _topicImage(String imageUrl, {double size = 50}) {
    final url = imageUrl.trim();
    if (url.isEmpty) {
      return Icon(Icons.gavel_rounded,
          size: size * 0.7, color: const Color(0xFF94A3B8));
    }
    if (url.startsWith('assets/')) {
      return Image.asset(url, width: size, height: size, fit: BoxFit.contain);
    }
    return CachedNetworkImage(
      imageUrl: url,
      width: size,
      height: size,
      fit: BoxFit.contain,
      memCacheWidth: 160,
      placeholder: (_, __) => SizedBox(
        width: size,
        height: size,
        child: const Center(
          child: SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      ),
      errorWidget: (_, __, ___) => Icon(Icons.gavel_rounded,
          size: size * 0.7, color: const Color(0xFF94A3B8)),
    );
  }

  Widget _buildSubCaseField(Color topicColor) {
    final rawSubs = _selectedTopic['subTopics'] ?? _selectedTopic['subCase'];
    final subTopics = (rawSubs is List ? rawSubs : <dynamic>[])
        .whereType<Map>()
        .map((s) => Map<String, dynamic>.from(s))
        .where((s) => (s['title']?.toString().trim() ?? '').isNotEmpty)
        .toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('subTopicLabel'.tr(),
            style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1A2340))),
        const SizedBox(height: 8),
        AppDropdownField<String>(
          value: _selectedSubCase?['code']?.toString(),
          hint: 'selectSubTopic'.tr(),
          prefixIcon: Icons.subdirectory_arrow_right_rounded,
          items: subTopics
              .map(
                (s) => DropdownMenuItem<String>(
                  value: s['code']?.toString() ?? '',
                  child: Text(
                    s['title']?.toString() ?? '',
                    style: AppDropdownStyles.itemStyle(),
                  ),
                ),
              )
              .toList(),
          onChanged: (val) {
            final sub = subTopics.firstWhere(
              (s) => s['code']?.toString() == val,
              orElse: () => <String, dynamic>{},
            );
            setState(() => _selectedSubCase = sub.isEmpty ? null : sub);
          },
        ),
      ],
    );
  }

  Widget _buildDropdownField({
    required String label,
    required String hint,
    required IconData icon,
    required String? value,
    required List<String> items,
    required void Function(String?) onChanged,
    bool enabled = true,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1A2340))),
        const SizedBox(height: 8),
        AppDropdownField<String>(
          value: value,
          hint: hint,
          prefixIcon: icon,
          enabled: enabled,
          items: items
              .map(
                (e) => DropdownMenuItem<String>(
                  value: e,
                  child: Text(e, style: AppDropdownStyles.itemStyle()),
                ),
              )
              .toList(),
          onChanged: enabled ? onChanged : null,
        ),
      ],
    );
  }

  Widget _buildTextArea({
    required String label,
    required String hint,
    required TextEditingController controller,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1A2340))),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLines: 4,
          maxLength: 500,
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle:
                TextStyle(color: Colors.grey[400], fontSize: 13, height: 1.5),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.all(16),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide:
                  const BorderSide(color: Color(0xFFEEF2F5), width: 1.5),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide:
                  const BorderSide(color: Color(0xFFEEF2F5), width: 1.5),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide:
                  const BorderSide(color: Color(0xFF0262EC), width: 1.5),
            ),
            counterStyle: TextStyle(color: Colors.grey[400], fontSize: 11),
          ),
        ),
      ],
    );
  }

  Widget _buildImageField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('consultAttachEvidence'.tr(),
            style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1A2340))),
        const SizedBox(height: 8),
        SizedBox(
          height: 140,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                ..._selectedImages.asMap().entries.map((entry) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Stack(children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.file(entry.value,
                            width: 140, height: 140, fit: BoxFit.cover),
                      ),
                      Positioned(
                        right: 4,
                        top: 4,
                        child: GestureDetector(
                          onTap: () => setState(
                              () => _selectedImages.removeAt(entry.key)),
                          child: Container(
                            decoration: const BoxDecoration(
                                color: Colors.black54, shape: BoxShape.circle),
                            padding: const EdgeInsets.all(3),
                            child: const Icon(Icons.close,
                                color: Colors.white, size: 14),
                          ),
                        ),
                      ),
                    ]),
                  );
                }),
                GestureDetector(
                  onTap: _pickImages,
                  child: DottedBorder(
                    borderType: BorderType.RRect,
                    radius: const Radius.circular(12),
                    color: const Color(0xFFEEF2F5),
                    strokeWidth: 1.5,
                    child: Container(
                      width: 140,
                      height: 140,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.add_a_photo, color: Colors.grey),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomButton(Color topicColor) {
    return Container(
      padding: EdgeInsets.fromLTRB(
          20, 12, 20, MediaQuery.of(context).padding.bottom + 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
              color: Color(0x15000000), blurRadius: 10, offset: Offset(0, -3))
        ],
      ),
      child: GestureDetector(
        onTap: _canSubmit
            ? () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ConsultSummaryPage(
                      // ── field ชุดใหม่ที่ตกลงกัน ──
                      topic: _selectedTopic!['code']?.toString() ?? '',
                      topicTitle: _selectedTopic!['title']?.toString() ?? '',
                      subTopic: _selectedSubCase?['code']?.toString() ?? '',
                      subTopicTitle:
                          _selectedSubCase?['title']?.toString() ?? '',
                      province: _selectedProvince!,
                      detail: _detailController.text.trim(),
                      demand: _demandController.text.trim(),
                      images: _selectedImages,
                    ),
                  ),
                );
              }
            : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: 52,
          decoration: BoxDecoration(
            gradient: _canSubmit
                ? const LinearGradient(
                    colors: [Color(0xFF0262EC), Color(0xFF0485FF)])
                : null,
            color: _canSubmit ? null : const Color(0xFFCDD5E0),
            borderRadius: BorderRadius.circular(14),
            boxShadow: _canSubmit
                ? [
                    BoxShadow(
                      color: const Color(0xFF0262EC).withOpacity(0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    )
                  ]
                : null,
          ),
          child: Center(
            child: Text(
              'next'.tr(),
              style: TextStyle(
                color: _canSubmit ? Colors.white : Colors.grey[400],
                fontWeight: FontWeight.w700,
                fontSize: 15,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
