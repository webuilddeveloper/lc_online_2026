import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:LawyerOnline/component/appbar.dart';
import 'package:LawyerOnline/component/app_dropdown.dart';
import 'package:LawyerOnline/component/media_picker_sheet.dart';
import 'package:LawyerOnline/component/loading_service.dart';
import 'package:LawyerOnline/models/user_profile_store.dart';
import 'package:LawyerOnline/models/lawyer/lawyer_profile_store.dart';
import 'package:LawyerOnline/services/auth_service.dart';
import 'package:LawyerOnline/shared/api_provider.dart';
import 'package:LawyerOnline/shared/app_typography.dart';
import 'package:LawyerOnline/widgets/profile/lawyer/lawyer_profile_widgets.dart';
import 'package:LawyerOnline/shared/responsive/res_layout.dart';
import 'package:easy_localization/easy_localization.dart';

// ══════════════════════════════════════════════════════════
//  LawyerEditProfilePage
//  หน้าแก้ไขโปรไฟล์สำหรับทนายความ
//  Style เดียวกับ LawyerOnlineList (card, chip, badge)
// ══════════════════════════════════════════════════════════

class LawyerEditProfilePage extends StatefulWidget {
  const LawyerEditProfilePage({super.key});

  @override
  State<LawyerEditProfilePage> createState() => _LawyerEditProfilePageState();
}

class _LawyerEditProfilePageState extends State<LawyerEditProfilePage>
    with TickerProviderStateMixin {
  static const _kPrimary = Color(0xFF0262EC);
  static const _kBg = Color(0xFFF5F7FA);

  // ── Controllers ──────────────────────────────────────────
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _firstNameCtrl;
  late final TextEditingController _lastNameCtrl;
  late final TextEditingController _prefixCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _emailCtrl;
  late final TextEditingController _experienceCtrl;
  late final TextEditingController _casesWonCtrl;
  late final TextEditingController _bioCtrl;
  late final TextEditingController _facebookCtrl;
  late final TextEditingController _instagramCtrl;
  late final TextEditingController _twitterCtrl;
  late final TextEditingController _linkedinCtrl;
  late final TextEditingController _titleCtrl;

  // ── State ──────────────────────────────────────────────
  bool _isAvailable = true;
  bool _isUrgentEnabled = false;
  bool _isSaving = false;
  bool _pageLoading = true;
  XFile? _pickedImage;
  String _imageUrl = '';

  List<dynamic> _specialtyOptions = [];
  final Set<String> _selectedSkillCodes = {};

  List<dynamic> _provinceList = [];
  String _selectedProvince = 'กรุงเทพมหานคร';
  String _selectedProvinceCode = '';

  // tab
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _initControllers();
    _loadProfile();
    UserProfileStore.instance.addListener(_refresh);
    LawyerProfileStore.instance.addListener(_refresh);
  }

  void _initControllers() {
    final store = UserProfileStore.instance;
    final lawyerStore = LawyerProfileStore.instance;

    _prefixCtrl = TextEditingController(text: store.prefixName);
    _firstNameCtrl = TextEditingController(text: store.firstName);
    _lastNameCtrl = TextEditingController(text: store.lastName);
    _phoneCtrl = TextEditingController(text: store.phone);
    _emailCtrl = TextEditingController(text: store.email);
    _experienceCtrl = TextEditingController(text: lawyerStore.experience);
    _casesWonCtrl = TextEditingController(text: lawyerStore.casesWon);
    _bioCtrl = TextEditingController(text: lawyerStore.bio);
    _facebookCtrl = TextEditingController(text: lawyerStore.facebook);
    _instagramCtrl = TextEditingController(text: lawyerStore.instagram);
    _twitterCtrl = TextEditingController(text: lawyerStore.twitter);
    _linkedinCtrl = TextEditingController(text: lawyerStore.linkedin);
    _titleCtrl = TextEditingController(
      text: lawyerStore.title.isEmpty ? 'ทนายความ' : lawyerStore.title,
    );

    _isAvailable = lawyerStore.isAvailable;
    _isUrgentEnabled = lawyerStore.isUrgentCaseEnabled;
    _imageUrl = store.imageUrl;
    if (lawyerStore.province.isNotEmpty) {
      _selectedProvince = lawyerStore.province;
    }
  }

  Future<void> _loadProfile() async {
    final userStore = UserProfileStore.instance;
    await userStore.load();
    await userStore.refreshFromApi();

    final user = userStore.user;
    if (user != null) {
      await LawyerProfileStore.instance.syncFromUserModel(user);
      _selectedSkillCodes
        ..clear()
        ..addAll(user.expertiseList);
      _selectedProvinceCode = user.provinceCode;
      if (user.province.isNotEmpty) {
        _selectedProvince = user.province;
      }
    }

    final subTopic = await postDio('$server/m/topic/subTopic/read', {});
    final province = await postDio('${serverLC}route/province/read', {});

    if (!mounted) return;

    _applyStoreToControllers();

    setState(() {
      _specialtyOptions = [...(subTopic['objectData'] ?? [])];
      _provinceList = [...(province['objectData'] ?? [])];
      if (_selectedProvinceCode.isEmpty && _selectedProvince.isNotEmpty) {
        final match = _provinceList.cast<Map>().firstWhere(
              (p) => p['title']?.toString() == _selectedProvince,
              orElse: () => {},
            );
        if (match.isNotEmpty) {
          _selectedProvinceCode = match['code']?.toString() ?? '';
        }
      }
      _pageLoading = false;
    });
  }

  void _applyStoreToControllers() {
    final store = UserProfileStore.instance;
    final lawyerStore = LawyerProfileStore.instance;

    _prefixCtrl.text = store.prefixName;
    _firstNameCtrl.text = store.firstName;
    _lastNameCtrl.text = store.lastName;
    _phoneCtrl.text = store.phone;
    _emailCtrl.text = store.email;
    _experienceCtrl.text = lawyerStore.experience;
    _casesWonCtrl.text = lawyerStore.casesWon;
    _bioCtrl.text = lawyerStore.bio;
    _facebookCtrl.text = lawyerStore.facebook;
    _instagramCtrl.text = lawyerStore.instagram;
    _twitterCtrl.text = lawyerStore.twitter;
    _linkedinCtrl.text = lawyerStore.linkedin;
    _titleCtrl.text =
        lawyerStore.title.isEmpty ? 'ทนายความ' : lawyerStore.title;
    _isAvailable = lawyerStore.isAvailable;
    _isUrgentEnabled = lawyerStore.isUrgentCaseEnabled;
    _imageUrl = store.imageUrl;
    if (lawyerStore.province.isNotEmpty) {
      _selectedProvince = lawyerStore.province;
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    for (final c in [
      _prefixCtrl,
      _firstNameCtrl,
      _lastNameCtrl,
      _phoneCtrl,
      _emailCtrl,
      _experienceCtrl,
      _casesWonCtrl,
      _bioCtrl,
      _facebookCtrl,
      _instagramCtrl,
      _twitterCtrl,
      _linkedinCtrl,
      _titleCtrl,
    ]) {
      c.dispose();
    }
    UserProfileStore.instance.removeListener(_refresh);
    LawyerProfileStore.instance.removeListener(_refresh);
    super.dispose();
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  Future<void> _pickImageFromGallery() async {
    final picker = ImagePicker();
    final img =
        await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (img == null) return;
    setState(() => _pickedImage = img);
    await _uploadImage(img);
  }

  Future<void> _pickImageFromCamera() async {
    final picker = ImagePicker();
    final img =
        await picker.pickImage(source: ImageSource.camera, imageQuality: 80);
    if (img == null) return;
    setState(() => _pickedImage = img);
    await _uploadImage(img);
  }

  Future<void> _uploadImage(XFile image) async {
    try {
      final url = await uploadImageX(image);
      if (!mounted) return;
      setState(() => _imageUrl = url);
    } catch (e) {
      if (!mounted) return;
      _showSnack('อัปโหลดรูปไม่สำเร็จ: $e');
    }
  }

  void _showImagePicker() {
    MediaPickerSheet.showImageSources(
      context,
      onGallery: _pickImageFromGallery,
      onCamera: _pickImageFromCamera,
    );
  }

  String? _skillTitle(String code) {
    for (final option in _specialtyOptions) {
      if (option is Map && option['code']?.toString() == code) {
        return option['title']?.toString() ?? code;
      }
    }
    return code;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedSkillCodes.isEmpty) {
      _showSnack('กรุณาเลือกความเชี่ยวชาญอย่างน้อย 1 ด้าน');
      return;
    }

    setState(() => _isSaving = true);

    try {
      final store = UserProfileStore.instance;
      final imageUrl = _imageUrl.isNotEmpty ? _imageUrl : store.imageUrl;
      final experienceYears =
          double.tryParse(_experienceCtrl.text.trim()) ?? 0;

      final updated = await AuthService.updateProfile(
        code: store.code,
        email: _emailCtrl.text.trim(),
        firstName: _firstNameCtrl.text.trim(),
        lastName: _lastNameCtrl.text.trim(),
        phone: _phoneCtrl.text.trim(),
        imageUrl: imageUrl,
        userType: 'lawyer',
        prefixName: _prefixCtrl.text.trim(),
        title: _titleCtrl.text.trim(),
        description: _bioCtrl.text.trim(),
        expertiseList: _selectedSkillCodes.toList(),
        province: _selectedProvince,
        provinceCode: _selectedProvinceCode,
        experienceYears: experienceYears,
        isAvailable: _isAvailable ? 'T' : 'F',
        isAllowCase: _isUrgentEnabled,
        facebookID: _facebookCtrl.text.trim(),
        lv0: _instagramCtrl.text.trim(),
        lv1: _twitterCtrl.text.trim(),
        lv2: _linkedinCtrl.text.trim(),
        lv3: _casesWonCtrl.text.trim(),
      );

      if (updated != null) {
        await store.applyUserModel(updated);
        await LawyerProfileStore.instance.syncFromUserModel(updated);
      } else {
        await store.updateFromProfile(
          firstName: _firstNameCtrl.text.trim(),
          lastName: _lastNameCtrl.text.trim(),
          phone: _phoneCtrl.text.trim(),
          email: _emailCtrl.text.trim(),
          imageUrl: imageUrl,
          userType: 'lawyer',
          prefixName: _prefixCtrl.text.trim(),
        );
        await LawyerProfileStore.instance.updateProfile(
          title: _titleCtrl.text.trim(),
          experience: _experienceCtrl.text.trim(),
          casesWon: _casesWonCtrl.text.trim(),
          bio: _bioCtrl.text.trim(),
          skills: _selectedSkillCodes.toList(),
          province: _selectedProvince,
          isAvailable: _isAvailable,
          isUrgentCaseEnabled: _isUrgentEnabled,
          facebook: _facebookCtrl.text.trim(),
          instagram: _instagramCtrl.text.trim(),
          twitter: _twitterCtrl.text.trim(),
          linkedin: _linkedinCtrl.text.trim(),
        );
      }

      if (!mounted) return;
      setState(() => _isSaving = false);
      _showSnack('บันทึกข้อมูลสำเร็จ', success: true);
      Navigator.pop(context);
    } on EmailDuplicateException {
      if (!mounted) return;
      setState(() => _isSaving = false);
      _showSnack('emailDuplicate'.tr());
    } on PhoneDuplicateException {
      if (!mounted) return;
      setState(() => _isSaving = false);
      _showSnack('phoneDuplicate'.tr());
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      _showSnack(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  void _showSnack(String msg, {bool success = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(children: [
        Icon(
          success ? Icons.check_circle_rounded : Icons.warning_rounded,
          color: Colors.white,
          size: 16,
        ),
        const SizedBox(width: 8),
        Expanded(child: Text(msg, style: AppTypography.prompt(fontSize: 13))),
      ]),
      backgroundColor:
          success ? const Color(0xFF059669) : const Color(0xFFC62828),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.all(16),
    ));
  }

  // ════════════════════════════════════════════════════════
  //  BUILD
  // ════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      appBar: appBarCustom(
        title: 'editInfoTitle'.tr(),
        backBtn: true,
        isRightWidget: false,
        backAction: () => Navigator.pop(context),
      ),
      body: _pageLoading
          ? AppLoadingView(message: 'loading'.tr())
          : GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        behavior: HitTestBehavior.opaque,
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth:
                  ResponsiveLayout.isDesktop(context) ? 640 : double.infinity,
            ),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  _buildPreviewCard(),
                  _buildTabBar(),
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _InfoTabContent(state: this),
                        _SkillsTabContent(state: this),
                        _buildSocialTab(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: _pageLoading ? null : _buildSaveBar(),
    );
  }

  // ── Preview Card (style เหมือน LawyerOnlineList card) ──
  Widget _buildPreviewCard() {
    final store = UserProfileStore.instance;
    final imageUrl = _pickedImage != null
        ? _imageUrl
        : (_imageUrl.isNotEmpty ? _imageUrl : store.imageUrl);

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: _kPrimary.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Avatar with edit overlay
          GestureDetector(
            onTap: _showImagePicker,
            child: Stack(
              children: [
                Container(
                  width: 62,
                  height: 62,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: _kPrimary, width: 2),
                  ),
                  child: ClipOval(
                    child: _pickedImage != null
                        ? Image.file(File(_pickedImage!.path),
                            fit: BoxFit.cover)
                        : (imageUrl.isNotEmpty && imageUrl.startsWith('http'))
                            ? Image.network(imageUrl, fit: BoxFit.cover)
                            : Image.asset('assets/icons/profile.png',
                                fit: BoxFit.cover),
                  ),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: _kPrimary,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 1.5),
                    ),
                    child: const Icon(Icons.camera_alt_rounded,
                        color: Colors.white, size: 11),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Name preview
                Text(
                  [
                    _prefixCtrl.text,
                    _firstNameCtrl.text,
                    _lastNameCtrl.text,
                  ].where((s) => s.isNotEmpty).join(' ').isEmpty
                      ? store.name
                      : [
                          _prefixCtrl.text,
                          _firstNameCtrl.text,
                          _lastNameCtrl.text
                        ].where((s) => s.isNotEmpty).join(' '),
                  style: AppTypography.prompt(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: Color(0xFF1A2340),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _titleCtrl.text.isEmpty ? 'ทนายความ' : _titleCtrl.text,
                  style: AppTypography.prompt(
                    color: Colors.grey[400],
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 6),
                Row(children: [
                  AvailabilityBadge(available: _isAvailable),
                  const SizedBox(width: 6),
                  if (_isUrgentEnabled)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF3E0),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        '⚡ รับคดีด่วน',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFFE65100),
                        ),
                      ),
                    ),
                ]),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Tab Bar ────────────────────────────────────────────
  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F4)),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          gradient: const LinearGradient(
              colors: [Color(0xFF0262EC), Color(0xFF0099FF)]),
          borderRadius: BorderRadius.circular(12),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        labelColor: Colors.white,
        unselectedLabelColor: const Color(0xFF64748B),
        labelStyle: AppTypography.prompt(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
        unselectedLabelStyle: AppTypography.prompt(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: Color(0xFF64748B),
        ),
        tabs: const [
          Tab(text: 'ข้อมูลทั่วไป'),
          Tab(text: 'ความเชี่ยวชาญ'),
          Tab(text: 'โซเชียล'),
        ],
      ),
    );
  }

  // ════════════════════════════════════════════════════════
  //  Tab 1 — ข้อมูลทั่วไป
  // ════════════════════════════════════════════════════════
  // ════════════════════════════════════════════════════════
  //  Tab 3 — โซเชียลมีเดีย
  // ════════════════════════════════════════════════════════
  Widget _buildSocialTab() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 100),
      children: [
        ProfileSectionCard(
          title: 'โซเชียลมีเดีย',
          icon: Icons.public_rounded,
          children: [
            _socialField('Facebook', _facebookCtrl,
                icon: Icons.facebook_rounded,
                iconColor: const Color(0xFF1877F2),
                hint: 'facebook.com/yourpage'),
            const SizedBox(height: 12),
            _socialField('Instagram', _instagramCtrl,
                icon: Icons.camera_alt_outlined,
                iconColor: const Color(0xFFE1306C),
                hint: '@yourinstagram'),
            const SizedBox(height: 12),
            _socialField('X (Twitter)', _twitterCtrl,
                icon: Icons.alternate_email_rounded,
                iconColor: const Color(0xFF1A2340),
                hint: '@yourtwitter'),
            const SizedBox(height: 12),
            _socialField('LinkedIn', _linkedinCtrl,
                icon: Icons.work_outline_rounded,
                iconColor: const Color(0xFF0A66C2),
                hint: 'linkedin.com/in/yourprofile'),
          ],
        ),
        const SizedBox(height: 12),

        // Social preview card (style เหมือน detail page)
        if ([_facebookCtrl, _instagramCtrl, _twitterCtrl, _linkedinCtrl]
            .any((c) => c.text.isNotEmpty))
          ProfileSectionCard(
            title: 'ตัวอย่างที่จะแสดง',
            icon: Icons.preview_rounded,
            children: [
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  if (_facebookCtrl.text.isNotEmpty)
                    _socialBadge(
                        Icons.facebook_rounded, const Color(0xFF1877F2)),
                  if (_instagramCtrl.text.isNotEmpty)
                    _socialBadge(
                        Icons.camera_alt_outlined, const Color(0xFFE1306C)),
                  if (_twitterCtrl.text.isNotEmpty)
                    _socialBadge(
                        Icons.alternate_email_rounded, const Color(0xFF1A2340)),
                  if (_linkedinCtrl.text.isNotEmpty)
                    _socialBadge(
                        Icons.work_outline_rounded, const Color(0xFF0A66C2)),
                ],
              ),
            ],
          ),
      ],
    );
  }

  // ════════════════════════════════════════════════════════
  //  Save Bar
  // ════════════════════════════════════════════════════════
  Widget _buildSaveBar() {
    return Container(
      padding: EdgeInsets.fromLTRB(
          16, 12, 16, MediaQuery.of(context).padding.bottom + 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: Row(children: [
        Expanded(
          child: GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              height: 48,
              decoration: BoxDecoration(
                color: const Color(0xFFF2F6FF),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFDDE5F4), width: 1.5),
              ),
              child: const Center(
                child: Text('ยกเลิก',
                    style: TextStyle(
                        color: Color(0xFF5B6E8A),
                        fontWeight: FontWeight.w600,
                        fontSize: 14)),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          flex: 2,
          child: GestureDetector(
            onTap: _isSaving ? null : _save,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              height: 48,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                    colors: [Color(0xFF0262EC), Color(0xFF0099FF)]),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: _kPrimary.withOpacity(0.35),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Center(
                child: _isSaving
                    ? const AppRingSpinner(color: Colors.white, size: 22)
                    : const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.save_rounded,
                              color: Colors.white, size: 16),
                          SizedBox(width: 8),
                          Text('บันทึกโปรไฟล์',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14)),
                        ],
                      ),
              ),
            ),
          ),
        ),
      ]),
    );
  }

  // ── Badge (ว่างอยู่ / ไม่ว่าง) → ใช้ AvailabilityBadge จาก shared widgets ──
  // ── _sectionCard  → ProfileSectionCard ──────────────────────────────────────
  // ── _field        → ProfileTextField ────────────────────────────────────────
  // ── _skillChipToggle / _skillChipSelected → SkillToggleChip / SkillSelectedChip

  Widget _toggleTile({
    required String label,
    required String sublabel,
    required bool value,
    required Color activeColor,
    required ValueChanged<bool> onChanged,
    Widget? badge,
  }) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color:
              value ? activeColor.withOpacity(0.06) : const Color(0xFFF8F9FB),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color:
                value ? activeColor.withOpacity(0.4) : const Color(0xFFE2E8F4),
            width: 1.5,
          ),
        ),
        child: Row(children: [
          Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              color: value ? activeColor : Colors.white,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: value ? activeColor : const Color(0xFFCCCCCC),
              ),
            ),
            child: value
                ? const Icon(Icons.check_rounded, color: Colors.white, size: 14)
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: value ? activeColor : const Color(0xFF1A2340))),
                Text(sublabel,
                    style: TextStyle(fontSize: 11, color: Colors.grey[400])),
              ],
            ),
          ),
          if (badge != null) badge,
        ]),
      ),
    );
  }

  Widget _socialField(
    String label,
    TextEditingController ctrl, {
    required IconData icon,
    required Color iconColor,
    String hint = '',
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1A2340))),
        const SizedBox(height: 6),
        TextFormField(
          controller: ctrl,
          onChanged: (_) => setState(() {}),
          style: const TextStyle(fontSize: 13),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey[400], fontSize: 12),
            prefixIcon: Container(
              margin: const EdgeInsets.all(10),
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 14, color: iconColor),
            ),
            filled: true,
            fillColor: const Color(0xFFF8F9FB),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  const BorderSide(color: Color(0xFFE2E8F4), width: 1.5),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  const BorderSide(color: Color(0xFFE2E8F4), width: 1.5),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: _kPrimary, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }

  Widget _socialBadge(IconData icon, Color color) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFFE2E8F4)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Icon(icon, color: color, size: 20),
    );
  }
}

// ══════════════════════════════════════════════════════════
//  _InfoTabContent
//  Tab 1 — ข้อมูลทั่วไป (แยกออกมาจาก _buildInfoTab)
//  รับ state เพื่อเข้าถึง controllers และ setState
// ══════════════════════════════════════════════════════════

class _InfoTabContent extends StatelessWidget {
  final _LawyerEditProfilePageState state;

  const _InfoTabContent({required this.state});

  @override
  Widget build(BuildContext context) {
    final s = state;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 100),
      children: [
        ProfileSectionCard(
          title: 'ข้อมูลส่วนตัว',
          icon: Icons.person_rounded,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 1,
                  child: ProfileTextField(
                    'คำนำหน้า',
                    s._prefixCtrl,
                    hint: 'นาย',
                    onChanged: () => s.setState(() {}),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: ProfileTextField(
                    'ชื่อ',
                    s._firstNameCtrl,
                    hint: 'ชื่อจริง',
                    required: true,
                    onChanged: () => s.setState(() {}),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ProfileTextField(
              'นามสกุล',
              s._lastNameCtrl,
              hint: 'นามสกุล',
              required: true,
              onChanged: () => s.setState(() {}),
            ),
            const SizedBox(height: 12),
            ProfileTextField(
              'ตำแหน่ง / Title',
              s._titleCtrl,
              hint: 'เช่น ทนายความอาวุโส',
              onChanged: () => s.setState(() {}),
            ),
          ],
        ),
        const SizedBox(height: 12),

        ProfileSectionCard(
          title: 'ติดต่อ',
          icon: Icons.contact_phone_rounded,
          children: [
            ProfileTextField(
              'อีเมล',
              s._emailCtrl,
              hint: 'email@example.com',
              keyboardType: TextInputType.emailAddress,
              required: true,
              onChanged: () => s.setState(() {}),
            ),
            const SizedBox(height: 12),
            ProfileTextField(
              'เบอร์โทรศัพท์',
              s._phoneCtrl,
              hint: '0812345678',
              keyboardType: TextInputType.phone,
              required: true,
              onChanged: () => s.setState(() {}),
            ),
          ],
        ),
        const SizedBox(height: 12),

        ProfileSectionCard(
          title: 'ประสบการณ์',
          icon: Icons.history_rounded,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: ProfileTextField(
                    'ประสบการณ์ (ปี)',
                    s._experienceCtrl,
                    hint: 'เช่น 11',
                    keyboardType: TextInputType.number,
                    onChanged: () => s.setState(() {}),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ProfileTextField(
                    'คดีที่ชนะ',
                    s._casesWonCtrl,
                    hint: 'เช่น 148+',
                    keyboardType: TextInputType.number,
                    onChanged: () => s.setState(() {}),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Province Dropdown
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'จังหวัดที่ให้บริการ',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A2340),
                  ),
                ),
                const SizedBox(height: 6),
                AppDropdownFilter<String>(
                  value: s._selectedProvince,
                  items: s._provinceList
                      .map(
                        (p) => DropdownMenuItem<String>(
                          value: p['title']?.toString() ?? '',
                          child: Row(
                            children: [
                              const Icon(
                                Icons.location_city_outlined,
                                size: 14,
                                color: AppDropdownStyles.primary,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                p['title']?.toString() ?? '',
                                style: AppDropdownStyles.itemStyle(),
                              ),
                            ],
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (v) {
                    if (v != null) {
                      final match = s._provinceList.cast<Map>().firstWhere(
                            (p) => p['title']?.toString() == v,
                            orElse: () => {},
                          );
                      s.setState(() {
                        s._selectedProvince = v;
                        s._selectedProvinceCode =
                            match['code']?.toString() ?? '';
                      });
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),
            ProfileTextField(
              'แนะนำตัว / Bio',
              s._bioCtrl,
              hint: 'เล่าเกี่ยวกับตัวเองและประสบการณ์...',
              maxLines: 4,
              onChanged: () => s.setState(() {}),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // ── Toggle Cards ─────────────────────────────────────
        ProfileSectionCard(
          title: 'สถานะการให้บริการ',
          icon: Icons.toggle_on_rounded,
          children: [
            s._toggleTile(
              label: 'พร้อมรับงาน',
              sublabel: 'แสดงสถานะ "ว่างอยู่" ในรายการ',
              value: s._isAvailable,
              activeColor: const Color(0xFF059669),
              onChanged: (v) => s.setState(() => s._isAvailable = v),
              badge: AvailabilityBadge(available: s._isAvailable),
            ),
            const SizedBox(height: 10),
            s._toggleTile(
              label: 'รับคดีด่วน',
              sublabel: 'ลูกค้าสามารถติดต่อได้ทันที',
              value: s._isUrgentEnabled,
              activeColor: const Color(0xFFE65100),
              onChanged: (v) => s.setState(() => s._isUrgentEnabled = v),
            ),
          ],
        ),
      ],
    );
  }
}

// ══════════════════════════════════════════════════════════
//  _SkillsTabContent
//  Tab 2 — ความเชี่ยวชาญ (แยกออกมาจาก _buildSkillsTab)
// ══════════════════════════════════════════════════════════

class _SkillsTabContent extends StatelessWidget {
  final _LawyerEditProfilePageState state;

  const _SkillsTabContent({required this.state});

  static const _kPrimary = Color(0xFF0262EC);

  @override
  Widget build(BuildContext context) {
    final s = state;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 100),
      children: [
        // Preview chips ที่เลือกแล้ว
        if (s._selectedSkillCodes.isNotEmpty) ...[
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: _kPrimary.withOpacity(0.05),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _kPrimary.withOpacity(0.2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  const Icon(Icons.gavel_rounded, size: 14, color: _kPrimary),
                  const SizedBox(width: 6),
                  Text(
                    'ความเชี่ยวชาญที่เลือก (${s._selectedSkillCodes.length})',
                    style: AppTypography.prompt(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: _kPrimary,
                    ),
                  ),
                ]),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: s._selectedSkillCodes
                      .map((code) => SkillSelectedChip(
                            skill: s._skillTitle(code) ?? code,
                            onRemove: () => s.setState(
                                () => s._selectedSkillCodes.remove(code)),
                          ))
                      .toList(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],

        ProfileSectionCard(
          title: 'เลือกความเชี่ยวชาญ',
          icon: Icons.balance_rounded,
          children: [
            Text(
              'เลือกได้หลายด้าน',
              style: AppTypography.prompt(fontSize: 11, color: Colors.grey[400]),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: s._specialtyOptions
                  .whereType<Map>()
                  .map((option) {
                    final code = option['code']?.toString() ?? '';
                    final title = option['title']?.toString() ?? code;
                    if (code.isEmpty) return const SizedBox.shrink();
                    return SkillToggleChip(
                      skill: title,
                      selected: s._selectedSkillCodes.contains(code),
                      onTap: () {
                        s.setState(() {
                          if (s._selectedSkillCodes.contains(code)) {
                            s._selectedSkillCodes.remove(code);
                          } else {
                            s._selectedSkillCodes.add(code);
                          }
                        });
                      },
                    );
                  })
                  .toList(),
            ),
          ],
        ),

        if (s._selectedSkillCodes.isEmpty) ...[
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFFEBEE),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFEF9A9A)),
            ),
            child: const Row(children: [
              Icon(Icons.warning_rounded, size: 14, color: Color(0xFFC62828)),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'กรุณาเลือกความเชี่ยวชาญอย่างน้อย 1 ด้าน',
                  style: TextStyle(fontSize: 12, color: Color(0xFFC62828)),
                ),
              ),
            ]),
          ),
        ],
      ],
    );
  }
}
