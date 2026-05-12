import 'dart:io';
import 'package:LawyerOnline/component/appbar.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  // ── Controllers ───────────────────────────────────────────────────────────────
  final TextEditingController _nameCtrl = TextEditingController();
  final TextEditingController _phoneCtrl = TextEditingController();
  final TextEditingController _emailCtrl = TextEditingController();
  final TextEditingController _passwordCtrl = TextEditingController();
  final TextEditingController _confirmCtrl = TextEditingController();
  final TextEditingController _barNumCtrl = TextEditingController();

  // ── State ─────────────────────────────────────────────────────────────────────
  String _userType = 'client';
  bool _pwVisible = false;
  bool _cfVisible = false;
  bool _agreeTerms = false;
  bool _isLoading = false;
  File? _profileImage;
  int _step = 1;
  int _pwStrength = 0;

  // ── Specialty multi-select ────────────────────────────────────────────────────
  final List<String> _specialtyOptions = [
    'กฎหมายแรงงาน',
    'กฎหมายแพ่งและพาณิชย์',
    'คดีอาญา',
    'กฎหมายครอบครัว',
    'อสังหาริมทรัพย์',
    'กฎหมายธุรกิจ',
    'คดีไซเบอร์',
    'ประกันภัยและผู้บริโภค',
    'หนี้สินและการเงิน',
    'อื่นๆ',
  ];
  final Set<String> _selectedSpecialties = {};

  final ImagePicker _picker = ImagePicker();

  static const Color _blue = Color(0xFF0262EC);
  static const Color _bg = Color(0xFFEEF2F5);
  static const Color _border = Color(0xFFECEDF0);

  dynamic model = {};

  // ── Validation ────────────────────────────────────────────────────────────────
  bool _isEmailValid(String e) =>
      RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(e);

  bool _isPhoneValid(String p) => p.replaceAll(RegExp(r'\D'), '').length >= 9;

  int _calcStrength(String pw) {
    int s = 0;
    if (pw.length >= 8) s++;
    if (RegExp(r'[A-Z]').hasMatch(pw)) s++;
    if (RegExp(r'[0-9]').hasMatch(pw)) s++;
    if (RegExp(r'[^A-Za-z0-9]').hasMatch(pw)) s++;
    return s;
  }

  Color _strengthColor() {
    switch (_pwStrength) {
      case 1:
        return Colors.red;
      case 2:
        return Colors.orange;
      case 3:
        return Colors.lightGreen;
      case 4:
        return const Color(0xFF1D9E75);
      default:
        return Colors.transparent;
    }
  }

  String _strengthLabel() {
    switch (_pwStrength) {
      case 1:
        return 'อ่อนมาก';
      case 2:
        return 'พอใช้';
      case 3:
        return 'ดี';
      case 4:
        return 'แข็งแกร่ง';
      default:
        return '';
    }
  }

  // ── Image ─────────────────────────────────────────────────────────────────────
  Future<void> _pickImage() async {
    final XFile? img = await _picker.pickImage(source: ImageSource.gallery);
    if (img != null) setState(() => _profileImage = File(img.path));
  }

  // ── Submit ────────────────────────────────────────────────────────────────────
  Future<void> _submit() async {
    if (!_agreeTerms) {
      _showError('กรุณายอมรับข้อตกลงการใช้งาน');
      return;
    }
    if (_nameCtrl.text.trim().isEmpty) {
      _showError('กรุณากรอกชื่อ - นามสกุล');
      return;
    }
    if (!_isPhoneValid(_phoneCtrl.text)) {
      _showError('เบอร์โทรศัพท์ไม่ถูกต้อง');
      return;
    }
    if (_userType == 'lawyer' && _barNumCtrl.text.trim().isEmpty) {
      _showError('กรุณากรอกเลขทะเบียนทนายความ');
      return;
    }
    if (_userType == 'lawyer' && _selectedSpecialties.isEmpty) {
      _showError('กรุณาเลือกความเชี่ยวชาญอย่างน้อย 1 ด้าน');
      return;
    }
    if (!_isEmailValid(_emailCtrl.text)) {
      _showError('อีเมลไม่ถูกต้อง');
      return;
    }
    if (_passwordCtrl.text.length < 8) {
      _showError('รหัสผ่านต้องมีอย่างน้อย 8 ตัวอักษร');
      return;
    }
    if (_passwordCtrl.text != _confirmCtrl.text) {
      _showError('รหัสผ่านไม่ตรงกัน');
      return;
    }

    setState(() => _isLoading = true);
    await Future.delayed(const Duration(seconds: 2));
    setState(() => _isLoading = false);
    if (!mounted) return;
    _showSuccess();
  }

  void _showError(String msg) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('แจ้งเตือน'),
        content: Text(msg),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ตกลง', style: TextStyle(color: _blue)),
          ),
        ],
      ),
    );
  }

  void _showSuccess() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.check_circle_rounded, color: Color(0xFF1D9E75)),
            SizedBox(width: 8),
            Text('สมัครสมาชิกแล้ว'),
          ],
        ),
        content: const Text('บัญชีของคุณถูกสร้างเรียบร้อยแล้ว'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('เริ่มต้นใช้งาน', style: TextStyle(color: _blue)),
          ),
        ],
      ),
    );
  }

  // ── BUILD ─────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: appBar(
        title: "profile".tr(),
        backBtn: true,
        rightBtn: false,
        backAction: () => goBack(),
        rightAction: () => {},
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 100),
        children: [
          // _buildHeroBanner(),
          // const SizedBox(height: 16),
          // _buildStepIndicator(),
          // const SizedBox(height: 16),

          // ── Card: ข้อมูลส่วนตัว ─────────────────────────────────────────────
          _buildCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(child: _buildAvatarPicker()),
                const SizedBox(height: 24),

                _sectionLabel('คุณคือ'),
                const SizedBox(height: 8),
                _buildTypeSelector(),
                const SizedBox(height: 20),

                _sectionLabel('ชื่อ - นามสกุล *'),
                const SizedBox(height: 6),
                _buildTextField(
                  controller: _nameCtrl,
                  hint: 'ชื่อและนามสกุลจริง',
                  icon: Icons.person_outline_rounded,
                ),
                const SizedBox(height: 14),

                _sectionLabel('เบอร์โทรศัพท์ *'),
                const SizedBox(height: 6),
                _buildTextField(
                  controller: _phoneCtrl,
                  hint: '08X-XXX-XXXX',
                  icon: Icons.phone_outlined,
                  keyboardType: TextInputType.phone,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  maxLength: 10,
                ),

                // ── lawyer-only fields ─────────────────────────────────────────
                if (_userType == 'lawyer') ...[
                  const SizedBox(height: 14),
                  _sectionLabel('เลขทะเบียนทนายความ *'),
                  const SizedBox(height: 6),
                  _buildTextField(
                    controller: _barNumCtrl,
                    hint: 'เช่น 12345/2565',
                    icon: Icons.badge_outlined,
                  ),
                  const SizedBox(height: 18),

                  // ── MULTI-SELECT SPECIALTY ────────────────────────────────────
                  Row(
                    children: [
                      _sectionLabel('ความเชี่ยวชาญ *'),
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
                                fontWeight: FontWeight.w700),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'เลือกได้หลายด้าน',
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                  ),
                  const SizedBox(height: 10),
                  _buildSpecialtyChips(),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ── Card: บัญชีผู้ใช้ ───────────────────────────────────────────────
          _buildCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _sectionLabel('ข้อมูลบัญชี'),
                const SizedBox(height: 14),
                _sectionLabel('อีเมล *'),
                const SizedBox(height: 6),
                _buildTextField(
                  controller: _emailCtrl,
                  hint: 'example@email.com',
                  icon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 14),
                _sectionLabel('รหัสผ่าน *'),
                const SizedBox(height: 6),
                _buildTextField(
                  controller: _passwordCtrl,
                  hint: 'อย่างน้อย 8 ตัวอักษร',
                  icon: Icons.lock_outline_rounded,
                  obscure: !_pwVisible,
                  suffix: IconButton(
                    icon: Icon(
                      _pwVisible
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      color: Colors.grey,
                      size: 20,
                    ),
                    onPressed: () => setState(() => _pwVisible = !_pwVisible),
                  ),
                  onChanged: (v) =>
                      setState(() => _pwStrength = _calcStrength(v)),
                ),
                if (_passwordCtrl.text.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  _buildStrengthBar(),
                ],
                const SizedBox(height: 14),
                _sectionLabel('ยืนยันรหัสผ่าน *'),
                const SizedBox(height: 6),
                _buildTextField(
                  controller: _confirmCtrl,
                  hint: 'กรอกรหัสผ่านอีกครั้ง',
                  icon: Icons.lock_outline_rounded,
                  obscure: !_cfVisible,
                  suffix: IconButton(
                    icon: Icon(
                      _cfVisible
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      color: Colors.grey,
                      size: 20,
                    ),
                    onPressed: () => setState(() => _cfVisible = !_cfVisible),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ── Card: Terms ──────────────────────────────────────────────────────
          _buildCard(
            child: _buildCheckRow(
              value: _agreeTerms,
              onChanged: (v) => setState(() => _agreeTerms = v ?? false),
              label: 'ฉันยอมรับ ',
              linkLabel: 'ข้อกำหนดการใช้งาน',
            ),
          ),
          const SizedBox(height: 24),

          _buildSubmitButton(),
          const SizedBox(height: 16),

          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('มีบัญชีแล้ว? ',
                  style: TextStyle(fontSize: 13, color: Color(0xFF8C8C8C))),
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: const Text('เข้าสู่ระบบ',
                    style: TextStyle(
                        fontSize: 13,
                        color: _blue,
                        fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Multi-select Specialty Chips ──────────────────────────────────────────────
  Widget _buildSpecialtyChips() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _specialtyOptions.map((option) {
        final selected = _selectedSpecialties.contains(option);
        return GestureDetector(
          onTap: () {
            setState(() {
              if (selected) {
                _selectedSpecialties.remove(option);
              } else {
                _selectedSpecialties.add(option);
              }
            });
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: selected ? _blue : const Color(0xFFFAFAFA),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: selected ? _blue : _border,
                width: selected ? 1.5 : 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (selected) ...[
                  const Icon(Icons.check_rounded,
                      size: 14, color: Colors.white),
                  const SizedBox(width: 5),
                ],
                Text(
                  option,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                    color: selected ? Colors.white : const Color(0xFF444444),
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  // ── Hero Banner ───────────────────────────────────────────────────────────────
  Widget _buildHeroBanner() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _blue,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
              color: _blue.withOpacity(.25),
              blurRadius: 16,
              offset: const Offset(0, 6))
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('สร้างบัญชีใหม่',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text('ปรึกษาทนายความได้ทุกที่ทุกเวลา',
                    style: TextStyle(
                        color: Colors.white.withOpacity(.75), fontSize: 12)),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 6,
                  children: ['ฟรีครั้งแรก', 'ทนาย 200+', '24 ชม.']
                      .map((t) => Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(.15),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(t,
                                style: const TextStyle(
                                    color: Colors.white, fontSize: 11)),
                          ))
                      .toList(),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(.15),
              shape: BoxShape.circle,
            ),
            child:
                const Icon(Icons.gavel_rounded, color: Colors.white, size: 28),
          ),
        ],
      ),
    );
  }

  // ── Step Indicator ────────────────────────────────────────────────────────────
  Widget _buildStepIndicator() {
    return Row(
      children: [
        _stepDot(1, 'ข้อมูลส่วนตัว'),
        _stepLine(),
        _stepDot(2, 'บัญชีผู้ใช้'),
        _stepLine(),
        _stepDot(3, 'เสร็จสิ้น'),
      ],
    );
  }

  Widget _stepDot(int n, String label) {
    final active = _step >= n;
    return Column(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
              color: active ? _blue : const Color(0xFFD8DCE0),
              shape: BoxShape.circle),
          child: Center(
            child: Text('$n',
                style: TextStyle(
                    color: active ? Colors.white : const Color(0xFF8C8C8C),
                    fontSize: 12,
                    fontWeight: FontWeight.w600)),
          ),
        ),
        const SizedBox(height: 4),
        Text(label,
            style: TextStyle(
                fontSize: 10,
                color: active ? _blue : const Color(0xFF8C8C8C),
                fontWeight: active ? FontWeight.w600 : FontWeight.normal)),
      ],
    );
  }

  Widget _stepLine() => Expanded(
        child: Container(
          height: 2,
          margin: const EdgeInsets.only(bottom: 20),
          decoration: BoxDecoration(
              color: _blue.withOpacity(.2),
              borderRadius: BorderRadius.circular(1)),
        ),
      );

  // ── Avatar Picker ─────────────────────────────────────────────────────────────
  Widget _buildAvatarPicker() {
    return GestureDetector(
      onTap: _pickImage,
      child: Stack(
        alignment: Alignment.bottomRight,
        children: [
          CircleAvatar(
            radius: 45,
            backgroundColor: const Color(0xFFE8F0FE),
            backgroundImage: _profileImage != null
                ? FileImage(_profileImage!) as ImageProvider
                : null,
            child: _profileImage == null
                ? const Icon(Icons.person_rounded, size: 45, color: _blue)
                : null,
          ),
          Container(
            padding: const EdgeInsets.all(6),
            decoration:
                const BoxDecoration(color: _blue, shape: BoxShape.circle),
            child: const Icon(Icons.camera_alt_rounded,
                size: 15, color: Colors.white),
          ),
        ],
      ),
    );
  }

  // ── Type Selector ─────────────────────────────────────────────────────────────
  Widget _buildTypeSelector() {
    return Row(
      children: [
        _typeChip(
          'client',
          Icons.person_rounded,
          'ลูกความ',
          'ปรึกษา / หาทนาย',
          onTap: (value) {
            setState(
              () {
                model['userType'] = value;
              },
            );
          },
        ),
        const SizedBox(width: 10),
        _typeChip(
          'lawyer',
          Icons.gavel_rounded,
          'ทนายความ',
          'รับเคส',
          onTap: (value) {
            setState(
              () {
                model['userType'] = value;
              },
            );
          },
        ),
      ],
    );
  }

  Widget _typeChip(String value, IconData icon, String label, String sub,
      {Function? onTap}) {
    final selected = _userType == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => {
          onTap!(_userType),
          setState(
            () {
              _userType = value;
              // ล้าง specialty เมื่อ switch type
              _selectedSpecialties.clear();
            },
          ),
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            color: selected ? const Color(0xFFE8F0FE) : const Color(0xFFFAFAFA),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected ? _blue : _border,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 22, color: selected ? _blue : Colors.grey),
              const SizedBox(height: 6),
              Text(label,
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: selected ? _blue : const Color(0xFF1A1A2E))),
              Text(sub,
                  style:
                      const TextStyle(fontSize: 10, color: Color(0xFF8C8C8C))),
            ],
          ),
        ),
      ),
    );
  }

  // ── Strength Bar ──────────────────────────────────────────────────────────────
  Widget _buildStrengthBar() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(2),
          child: LinearProgressIndicator(
            value: _pwStrength / 4,
            backgroundColor: const Color(0xFFECEDF0),
            valueColor: AlwaysStoppedAnimation(_strengthColor()),
            minHeight: 4,
          ),
        ),
        const SizedBox(height: 4),
        Text(_strengthLabel(),
            style: TextStyle(fontSize: 11, color: _strengthColor())),
      ],
    );
  }

  // ── Check Row ─────────────────────────────────────────────────────────────────
  Widget _buildCheckRow({
    required bool value,
    required ValueChanged<bool?> onChanged,
    required String label,
    String? linkLabel,
  }) {
    return Row(
      children: [
        Checkbox(
          value: value,
          onChanged: onChanged,
          activeColor: _blue,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
          side: const BorderSide(color: Color(0xFFD0D0D0)),
        ),
        Expanded(
          child: GestureDetector(
            onTap: () => onChanged(!value),
            child: RichText(
              text: TextSpan(
                style: const TextStyle(fontSize: 13, color: Color(0xFF555555)),
                children: [
                  TextSpan(text: label),
                  if (linkLabel != null)
                    TextSpan(
                      text: linkLabel,
                      style: const TextStyle(
                          color: _blue, fontWeight: FontWeight.w600),
                    ),
                  const TextSpan(text: ' และนโยบายความเป็นส่วนตัว'),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ── Submit Button ─────────────────────────────────────────────────────────────
  Widget _buildSubmitButton() {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: _isLoading ? null : _submit,
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          color: _blue,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
                color: _blue.withOpacity(.3),
                blurRadius: 12,
                offset: const Offset(0, 5))
          ],
        ),
        child: Center(
          child: _isLoading
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2.5),
                )
              : const Text('สมัครสมาชิก',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      letterSpacing: .3)),
        ),
      ),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────────
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
              offset: const Offset(0, 6))
        ],
      ),
      child: child,
    );
  }

  Widget _sectionLabel(String text) => Text(
        text,
        style: const TextStyle(
            fontSize: 13, color: _blue, fontWeight: FontWeight.w500),
      );

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool obscure = false,
    Widget? suffix,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    int? maxLength,
    ValueChanged<String>? onChanged,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      maxLength: maxLength,
      onChanged: onChanged,
      decoration: InputDecoration(
        counterText: '',
        hintText: hint,
        hintStyle: const TextStyle(fontSize: 14, color: Color(0xFF9E9E9E)),
        prefixIcon: Icon(icon, color: Colors.grey, size: 20),
        suffixIcon: suffix,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: _border)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: _border)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: _blue, width: 1.5)),
        fillColor: const Color(0xFFFAFAFA),
        filled: true,
      ),
    );
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    _barNumCtrl.dispose();
    super.dispose();
  }

  void goBack() async {
    Navigator.pop(context, false);
  }
}
