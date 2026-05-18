import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:LawyerOnline/component/appbar.dart';
import 'package:LawyerOnline/models/user_profile_store.dart';
import 'package:LawyerOnline/models/lawyer/lawyer_profile_store.dart';
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
  XFile? _pickedImage;

  // skills chips
  final List<String> _allSkills = [
    'อาญาและอาชญากรรม',
    'ครอบครัวและมรดก',
    'หนี้สินและการเงิน',
    'ธุรกิจและบริษัท',
    'แรงงานและการจ้างงาน',
    'ประกันภัยและผู้บริโภค',
    'ทรัพย์สินและที่ดิน',
    'ฟ้องศาล เรียกค่าเสียหาย',
    'คดีออนไลน์และเทคโนโลยี',
    'อื่นๆและระหว่างประเทศ',
  ];
  final List<String> _selectedSkills = [];

  // province
  final List<String> _provinces = [
    'กรุงเทพมหานคร',
    'เชียงใหม่',
    'ขอนแก่น',
    'ชลบุรี',
    'ภูเก็ต',
    'นนทบุรี',
    'สมุทรปราการ',
    'อื่นๆ',
  ];
  String _selectedProvince = 'กรุงเทพมหานคร';

  // tab
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

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
        text: lawyerStore.title.isEmpty ? 'ทนายความ' : lawyerStore.title);

    _isAvailable = lawyerStore.isAvailable;
    _isUrgentEnabled = lawyerStore.isUrgentCaseEnabled;
    if (lawyerStore.skills.isNotEmpty) {
      _selectedSkills.addAll(lawyerStore.skills);
    }
    if (lawyerStore.province.isNotEmpty) {
      _selectedProvince = lawyerStore.province;
    }

    UserProfileStore.instance.addListener(_refresh);
    LawyerProfileStore.instance.addListener(_refresh);
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

  // ── Pick Image ─────────────────────────────────────────
  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final img =
        await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (img != null) setState(() => _pickedImage = img);
  }

  // ── Save ───────────────────────────────────────────────
  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedSkills.isEmpty) {
      _showSnack('กรุณาเลือกความเชี่ยวชาญอย่างน้อย 1 ด้าน');
      return;
    }
    setState(() => _isSaving = true);

    await UserProfileStore.instance.updateFromProfile(
      firstName: _firstNameCtrl.text.trim(),
      lastName: _lastNameCtrl.text.trim(),
      phone: _phoneCtrl.text.trim(),
      email: _emailCtrl.text.trim(),
      userType: 'lawyer',
    );

    await LawyerProfileStore.instance.updateProfile(
      title: _titleCtrl.text.trim(),
      experience: _experienceCtrl.text.trim(),
      casesWon: _casesWonCtrl.text.trim(),
      bio: _bioCtrl.text.trim(),
      skills: List.from(_selectedSkills),
      province: _selectedProvince,
      isAvailable: _isAvailable,
      isUrgentCaseEnabled: _isUrgentEnabled,
      facebook: _facebookCtrl.text.trim(),
      instagram: _instagramCtrl.text.trim(),
      twitter: _twitterCtrl.text.trim(),
      linkedin: _linkedinCtrl.text.trim(),
    );

    setState(() => _isSaving = false);
    if (!mounted) return;
    _showSnack('บันทึกข้อมูลสำเร็จ', success: true);
    Navigator.pop(context);
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
        Expanded(child: Text(msg, style: const TextStyle(fontSize: 13))),
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
        title: 'แก้ไขโปรไฟล์',
        backBtn: true,
        isRightWidget: false,
        backAction: () => Navigator.pop(context),
      ),
      body: GestureDetector(
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
                        _buildInfoTab(),
                        _buildSkillsTab(),
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
      bottomNavigationBar: _buildSaveBar(),
    );
  }

  // ── Preview Card (style เหมือน LawyerOnlineList card) ──
  Widget _buildPreviewCard() {
    final store = UserProfileStore.instance;
    final imageUrl = _pickedImage != null ? '' : store.imageUrl;

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
            onTap: _pickImage,
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
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: Color(0xFF1A2340),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _titleCtrl.text.isEmpty ? 'ทนายความ' : _titleCtrl.text,
                  style: TextStyle(color: Colors.grey[400], fontSize: 12),
                ),
                const SizedBox(height: 6),
                Row(children: [
                  _badge(_isAvailable),
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
        labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
        unselectedLabelStyle:
            const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
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
  Widget _buildInfoTab() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 100),
      children: [
        _sectionCard(
          title: 'ข้อมูลส่วนตัว',
          icon: Icons.person_rounded,
          children: [
            _fieldRow([
              Expanded(
                  flex: 1, child: _field('คำนำหน้า', _prefixCtrl, hint: 'นาย')),
              const SizedBox(width: 10),
              Expanded(
                  flex: 2,
                  child: _field('ชื่อ', _firstNameCtrl,
                      hint: 'ชื่อจริง', required: true)),
            ]),
            const SizedBox(height: 12),
            _field('นามสกุล', _lastNameCtrl, hint: 'นามสกุล', required: true),
            const SizedBox(height: 12),
            _field('ตำแหน่ง / Title', _titleCtrl, hint: 'เช่น ทนายความอาวุโส'),
          ],
        ),
        const SizedBox(height: 12),

        _sectionCard(
          title: 'ติดต่อ',
          icon: Icons.contact_phone_rounded,
          children: [
            _field('อีเมล', _emailCtrl,
                hint: 'email@example.com',
                keyboardType: TextInputType.emailAddress,
                required: true),
            const SizedBox(height: 12),
            _field('เบอร์โทรศัพท์', _phoneCtrl,
                hint: '0812345678',
                keyboardType: TextInputType.phone,
                required: true),
          ],
        ),
        const SizedBox(height: 12),

        _sectionCard(
          title: 'ประสบการณ์',
          icon: Icons.history_rounded,
          children: [
            _fieldRow([
              Expanded(
                child: _field('ประสบการณ์ (ปี)', _experienceCtrl,
                    hint: 'เช่น 11', keyboardType: TextInputType.number),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _field('คดีที่ชนะ', _casesWonCtrl,
                    hint: 'เช่น 148+', keyboardType: TextInputType.number),
              ),
            ]),
            const SizedBox(height: 12),
            // Province Dropdown (style เหมือน filter sheet)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('จังหวัดที่ให้บริการ',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1A2340))),
                const SizedBox(height: 6),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8F9FB),
                    borderRadius: BorderRadius.circular(12),
                    border:
                        Border.all(color: const Color(0xFFE2E8F4), width: 1.5),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedProvince,
                      isExpanded: true,
                      icon: Icon(Icons.keyboard_arrow_down_rounded,
                          color: Colors.grey[400], size: 20),
                      items: _provinces
                          .map((p) => DropdownMenuItem<String>(
                                value: p,
                                child: Row(children: [
                                  Icon(Icons.location_city_outlined,
                                      size: 14, color: _kPrimary),
                                  const SizedBox(width: 8),
                                  Text(p,
                                      style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500,
                                          color: Color(0xFF1A2340))),
                                ]),
                              ))
                          .toList(),
                      onChanged: (v) {
                        if (v != null) setState(() => _selectedProvince = v);
                      },
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _field('แนะนำตัว / Bio', _bioCtrl,
                hint: 'เล่าเกี่ยวกับตัวเองและประสบการณ์...', maxLines: 4),
          ],
        ),
        const SizedBox(height: 12),

        // ── Toggle Cards (style badge เหมือน list) ──────────
        _sectionCard(
          title: 'สถานะการให้บริการ',
          icon: Icons.toggle_on_rounded,
          children: [
            _toggleTile(
              label: 'พร้อมรับงาน',
              sublabel: 'แสดงสถานะ "ว่างอยู่" ในรายการ',
              value: _isAvailable,
              activeColor: const Color(0xFF059669),
              onChanged: (v) => setState(() => _isAvailable = v),
              badge: _badge(_isAvailable),
            ),
            const SizedBox(height: 10),
            _toggleTile(
              label: 'รับคดีด่วน',
              sublabel: 'ลูกค้าสามารถติดต่อได้ทันที',
              value: _isUrgentEnabled,
              activeColor: const Color(0xFFE65100),
              onChanged: (v) => setState(() => _isUrgentEnabled = v),
            ),
          ],
        ),
      ],
    );
  }

  // ════════════════════════════════════════════════════════
  //  Tab 2 — ความเชี่ยวชาญ
  // ════════════════════════════════════════════════════════
  Widget _buildSkillsTab() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 100),
      children: [
        // Preview chips (style เหมือน lawyer card)
        if (_selectedSkills.isNotEmpty) ...[
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
                  Text('ความเชี่ยวชาญที่เลือก (${_selectedSkills.length})',
                      style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: _kPrimary)),
                ]),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _selectedSkills
                      .map((s) => _skillChipSelected(s))
                      .toList(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],

        _sectionCard(
          title: 'เลือกความเชี่ยวชาญ',
          icon: Icons.balance_rounded,
          children: [
            Text('เลือกได้หลายด้าน',
                style: TextStyle(fontSize: 11, color: Colors.grey[400])),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _allSkills.map((s) => _skillChipToggle(s)).toList(),
            ),
          ],
        ),

        if (_selectedSkills.isEmpty) ...[
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFFEBEE),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFEF9A9A)),
            ),
            child: Row(children: [
              const Icon(Icons.warning_rounded,
                  size: 14, color: Color(0xFFC62828)),
              const SizedBox(width: 8),
              const Expanded(
                child: Text('กรุณาเลือกความเชี่ยวชาญอย่างน้อย 1 ด้าน',
                    style: TextStyle(fontSize: 12, color: Color(0xFFC62828))),
              ),
            ]),
          ),
        ],
      ],
    );
  }

  // ════════════════════════════════════════════════════════
  //  Tab 3 — โซเชียลมีเดีย
  // ════════════════════════════════════════════════════════
  Widget _buildSocialTab() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 100),
      children: [
        _sectionCard(
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
          _sectionCard(
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
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2),
                      )
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

  // ════════════════════════════════════════════════════════
  //  Reusable Widgets (เหมือน style LawyerOnlineList)
  // ════════════════════════════════════════════════════════

  Widget _sectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: _kPrimary.withOpacity(0.07),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: _kPrimary.withOpacity(0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 14, color: _kPrimary),
            ),
            const SizedBox(width: 8),
            Text(title,
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1A2340))),
          ]),
          const SizedBox(height: 4),
          const Divider(height: 20, color: Color(0xFFEEF2F5)),
          ...children,
        ],
      ),
    );
  }

  Widget _field(
    String label,
    TextEditingController controller, {
    String hint = '',
    bool required = false,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            text: label,
            style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1A2340)),
            children: required
                ? [
                    const TextSpan(
                        text: ' *', style: TextStyle(color: Color(0xFFC62828)))
                  ]
                : [],
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          onChanged: (_) => setState(() {}),
          style: const TextStyle(fontSize: 13, color: Color(0xFF1A2340)),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey[400], fontSize: 13),
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
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  const BorderSide(color: Color(0xFFC62828), width: 1.5),
            ),
          ),
          validator: required
              ? (v) =>
                  (v == null || v.trim().isEmpty) ? 'กรุณากรอก$label' : null
              : null,
        ),
      ],
    );
  }

  Widget _fieldRow(List<Widget> children) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: children,
    );
  }

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

  Widget _skillChipToggle(String skill) {
    final selected = _selectedSkills.contains(skill);
    return GestureDetector(
      onTap: () {
        setState(() {
          if (selected) {
            _selectedSkills.remove(skill);
          } else {
            _selectedSkills.add(skill);
          }
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color:
              selected ? _kPrimary.withOpacity(0.08) : const Color(0xFFEEF2F5),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected ? _kPrimary.withOpacity(0.4) : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.gavel_outlined,
              size: 12, color: selected ? _kPrimary : Colors.grey[500]),
          const SizedBox(width: 6),
          Text(skill,
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
                  color: selected ? _kPrimary : const Color(0xFF1A2340))),
          if (selected) ...[
            const SizedBox(width: 4),
            Icon(Icons.check_rounded, size: 11, color: _kPrimary),
          ],
        ]),
      ),
    );
  }

  Widget _skillChipSelected(String skill) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: _kPrimary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _kPrimary.withOpacity(0.3)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Text(skill,
            style: const TextStyle(
                fontSize: 11, color: _kPrimary, fontWeight: FontWeight.w600)),
        const SizedBox(width: 4),
        GestureDetector(
          onTap: () => setState(() => _selectedSkills.remove(skill)),
          child: const Icon(Icons.close_rounded, size: 13, color: _kPrimary),
        ),
      ]),
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

  // ── Badge (ว่างอยู่ / ไม่ว่าง) — เหมือน LawyerOnlineList ──
  Widget _badge(bool ok) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: ok ? const Color(0xFFE8F5E9) : const Color(0xFFFFEBEE),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          ok ? 'ว่างอยู่' : 'ไม่ว่าง',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: ok ? const Color(0xFF2E7D32) : const Color(0xFFC62828),
          ),
        ),
      );
}
