import 'dart:io';
import 'package:LawyerOnline/component/appbar.dart';
import 'package:LawyerOnline/services/auth_service.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:LawyerOnline/login.dart';

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

  // ── Scroll ────────────────────────────────────────────────────────────────────
  // ใช้ ScrollController + GlobalKey เพื่อ scroll ไปตำแหน่ง error
  final ScrollController _scrollCtrl = ScrollController();
  final GlobalKey _nameKey = GlobalKey();
  final GlobalKey _phoneKey = GlobalKey();
  final GlobalKey _barNumKey = GlobalKey();
  final GlobalKey _specialtyKey = GlobalKey();
  final GlobalKey _emailKey = GlobalKey();
  final GlobalKey _passwordKey = GlobalKey();
  final GlobalKey _confirmKey = GlobalKey();

  // ── State ─────────────────────────────────────────────────────────────────────
  String _userType = 'client';
  bool _pwVisible = false;
  bool _cfVisible = false;
  bool _agreeTerms = false;
  bool _isLoading = false;
  File? _profileImage;
  int _pwStrength = 0;

  // Error state สำหรับแต่ละ field
  String? _nameError;
  String? _phoneError;
  String? _emailError;
  String? _passwordError;
  String? _confirmError;
  String? _barNumError;
  bool _specialtyError = false; // ใช้ bool เพราะเป็น chip ไม่ใช่ TextField

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
  static const Color _errorColor = Color(0xFFD32F2F);

  // ── Validation helpers ────────────────────────────────────────────────────────
  bool _isEmailValid(String e) =>
      RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(e);

  bool _isPhoneValid(String p) => p.replaceAll(RegExp(r'\D'), '').length >= 9;

  bool _isBarNumValid(String b) => RegExp(r'^\d+/\d{4}$').hasMatch(b.trim());

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

  // ── Scroll to key ─────────────────────────────────────────────────────────────
  // เรียกฟังก์ชันนี้พร้อม GlobalKey ของ field ที่ error
  // จะ scroll หน้าจอลงไปให้ field นั้นอยู่ที่ประมาณ 30% จากบนจอ
  void _scrollToKey(GlobalKey key) {
    final ctx = key.currentContext;
    if (ctx == null) return;
    Scrollable.ensureVisible(
      ctx,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
      alignment: 0.3,
    );
  }

  // ── Image ─────────────────────────────────────────────────────────────────────
  Future<void> _pickImage() async {
    final XFile? img = await _picker.pickImage(source: ImageSource.gallery);
    if (img != null) setState(() => _profileImage = File(img.path));
  }

  // ── Submit ────────────────────────────────────────────────────────────────────
  Future<void> _submit() async {
    // ล้าง error ทั้งหมดก่อน validate ใหม่
    setState(() {
      _nameError = null;
      _phoneError = null;
      _emailError = null;
      _passwordError = null;
      _confirmError = null;
      _barNumError = null;
      _specialtyError = false;
    });

    // ตรวจ terms ก่อน (ใช้ dialog เพราะไม่มี field)
    if (!_agreeTerms) {
      _showError('กรุณายอมรับข้อตกลงการใช้งาน');
      return;
    }

    // validate ทุก field พร้อมกัน
    // เก็บ GlobalKey แรกที่ error ไว้เพื่อ scroll ไป
    GlobalKey? firstErrorKey;

    if (_nameCtrl.text.trim().isEmpty) {
      _nameError = 'กรุณากรอกชื่อ - นามสกุล';
      firstErrorKey ??= _nameKey;
    } else if (_nameCtrl.text.trim().split(RegExp(r'\s+')).length < 2) {
      _nameError = 'กรุณากรอกทั้งชื่อและนามสกุล';
      firstErrorKey ??= _nameKey;
    }

    if (!_isPhoneValid(_phoneCtrl.text)) {
      _phoneError = 'เบอร์โทรศัพท์ไม่ถูกต้อง (ต้องมีอย่างน้อย 9 หลัก)';
      firstErrorKey ??= _phoneKey;
    }

    if (_userType == 'lawyer') {
      if (_barNumCtrl.text.trim().isEmpty) {
        _barNumError = 'กรุณากรอกเลขทะเบียนทนายความ';
        firstErrorKey ??= _barNumKey;
      } else if (!_isBarNumValid(_barNumCtrl.text)) {
        _barNumError = 'รูปแบบไม่ถูกต้อง เช่น 12345/2565';
        firstErrorKey ??= _barNumKey;
      }

      if (_selectedSpecialties.isEmpty) {
        _specialtyError = true;
        firstErrorKey ??= _specialtyKey;
      }
    }

    if (_emailCtrl.text.trim().isEmpty) {
      _emailError = 'กรุณากรอกอีเมล';
      firstErrorKey ??= _emailKey;
    } else if (!_isEmailValid(_emailCtrl.text.trim())) {
      _emailError = 'รูปแบบอีเมลไม่ถูกต้อง';
      firstErrorKey ??= _emailKey;
    }

    if (_passwordCtrl.text.isEmpty) {
      _passwordError = 'กรุณากรอกรหัสผ่าน';
      firstErrorKey ??= _passwordKey;
    } else if (_passwordCtrl.text.length < 8) {
      _passwordError = 'รหัสผ่านต้องมีอย่างน้อย 8 ตัวอักษร';
      firstErrorKey ??= _passwordKey;
    }

    if (_confirmCtrl.text.isEmpty) {
      _confirmError = 'กรุณายืนยันรหัสผ่าน';
      firstErrorKey ??= _confirmKey;
    } else if (_passwordCtrl.text != _confirmCtrl.text) {
      _confirmError = 'รหัสผ่านไม่ตรงกัน';
      firstErrorKey ??= _confirmKey;
    }

    if (firstErrorKey != null) {
      setState(() {});
      // รอให้ setState render เสร็จก่อน แล้วค่อย scroll
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToKey(firstErrorKey!);
      });
      return;
    }

    final fullName = _nameCtrl.text.trim();
    final parts = fullName.split(RegExp(r'\s+'));
    final firstName = parts.isNotEmpty ? parts.first : '';
    final lastName = parts.length > 1 ? parts.sublist(1).join(' ') : '';
    final userType = _userType == 'lawyer' ? 'lawyer' : 'user';

    setState(() => _isLoading = true);
    try {
      await AuthService.register(
        firstName: firstName,
        lastName: lastName,
        userType: userType,
        phone: _phoneCtrl.text.trim(),
        email: _emailCtrl.text.trim(),
        password: _passwordCtrl.text,
        confirmPassword: _confirmCtrl.text,
      );

      if (!mounted) return;
      setState(() => _isLoading = false);
      _showSuccess();
    } catch (error) {
      if (!mounted) return;
      setState(() => _isLoading = false);

      final raw = error.toString().toLowerCase();

      if (raw.contains('already in use') ||
          raw.contains('email') && raw.contains('exist')) {
        setState(() => _emailError = 'อีเมลนี้ถูกใช้งานแล้ว กรุณาใช้อีเมลอื่น');
        // scroll ไปช่องอีเมลด้วย
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _scrollToKey(_emailKey);
        });
        return;
      } else if (raw.contains('phone') &&
          (raw.contains('exist') || raw.contains('use'))) {
        setState(() => _phoneError = 'เบอร์โทรศัพท์นี้ถูกใช้งานแล้ว');
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _scrollToKey(_phoneKey);
        });
        return;
      }

      String friendlyMsg;
      if (raw.contains('network') ||
          raw.contains('connection') ||
          raw.contains('timeout')) {
        friendlyMsg = 'ไม่สามารถเชื่อมต่อได้ กรุณาตรวจสอบอินเทอร์เน็ต';
      } else if (raw.contains('server') || raw.contains('500')) {
        friendlyMsg = 'เกิดข้อผิดพลาดจากเซิร์ฟเวอร์ กรุณาลองใหม่อีกครั้ง';
      } else {
        friendlyMsg = 'เกิดข้อผิดพลาด กรุณาลองใหม่อีกครั้ง';
      }
      _showError(friendlyMsg);
    }
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
    // เก็บ context ของ page ไว้ก่อน (ไม่ใช่ context ของ dialog)
    final pageContext = context;

    showDialog(
      context: pageContext,
      barrierDismissible: false,
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
              Navigator.pop(pageContext); // ปิด dialog
              Navigator.pushAndRemoveUntil(
                pageContext,
                MaterialPageRoute(builder: (_) => LoginPage()),
                (route) => false, // ล้าง stack ทั้งหมด
              );
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
        controller: _scrollCtrl, // ผูก ScrollController
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 100),
        children: [
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
                  key: _nameKey, // ผูก GlobalKey
                  controller: _nameCtrl,
                  hint: 'ชื่อและนามสกุลจริง',
                  icon: Icons.person_outline_rounded,
                  errorText: _nameError,
                  onChanged: (_) => setState(() => _nameError = null),
                ),
                const SizedBox(height: 14),

                _sectionLabel('เบอร์โทรศัพท์ *'),
                const SizedBox(height: 6),
                _buildTextField(
                  key: _phoneKey,
                  controller: _phoneCtrl,
                  hint: '08X-XXX-XXXX',
                  icon: Icons.phone_outlined,
                  keyboardType: TextInputType.phone,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  maxLength: 10,
                  errorText: _phoneError,
                  onChanged: (_) => setState(() => _phoneError = null),
                ),

                // ── lawyer-only fields ─────────────────────────────────────────
                if (_userType == 'lawyer') ...[
                  const SizedBox(height: 14),
                  _sectionLabel('เลขทะเบียนทนายความ *'),
                  const SizedBox(height: 6),
                  _buildTextField(
                    key: _barNumKey,
                    controller: _barNumCtrl,
                    hint: 'เช่น 12345/2565',
                    icon: Icons.badge_outlined,
                    errorText: _barNumError,
                    onChanged: (_) => setState(() => _barNumError = null),
                  ),
                  const SizedBox(height: 18),

                  // ── MULTI-SELECT SPECIALTY ──────────────────────────────────
                  Row(
                    key: _specialtyKey, // ผูก GlobalKey ที่แถว label
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
                  // แสดง error text ใต้ label ถ้ายังไม่ได้เลือก
                  if (_specialtyError)
                    Row(
                      children: const [
                        Icon(Icons.error_outline_rounded,
                            size: 13, color: _errorColor),
                        SizedBox(width: 4),
                        Text(
                          'กรุณาเลือกความเชี่ยวชาญอย่างน้อย 1 ด้าน',
                          style: TextStyle(fontSize: 11, color: _errorColor),
                        ),
                      ],
                    ),
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
                  key: _emailKey,
                  controller: _emailCtrl,
                  hint: 'example@email.com',
                  icon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                  errorText: _emailError,
                  onChanged: (_) => setState(() => _emailError = null),
                ),
                const SizedBox(height: 14),
                _sectionLabel('รหัสผ่าน *'),
                const SizedBox(height: 6),
                _buildTextField(
                  key: _passwordKey,
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
                  errorText: _passwordError,
                  onChanged: (v) => setState(() {
                    _pwStrength = _calcStrength(v);
                    _passwordError = null;
                    if (_confirmCtrl.text.isNotEmpty &&
                        _confirmCtrl.text != v) {
                      _confirmError = 'รหัสผ่านไม่ตรงกัน';
                    } else {
                      _confirmError = null;
                    }
                  }),
                ),
                if (_passwordCtrl.text.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  _buildStrengthBar(),
                ],
                const SizedBox(height: 14),
                _sectionLabel('ยืนยันรหัสผ่าน *'),
                const SizedBox(height: 6),
                _buildTextField(
                  key: _confirmKey,
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
                  errorText: _confirmError,
                  onChanged: (v) => setState(() {
                    _confirmError = v.isNotEmpty && v != _passwordCtrl.text
                        ? 'รหัสผ่านไม่ตรงกัน'
                        : null;
                  }),
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
                _specialtyError = false; // clear error ทันทีที่เลือก
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
                // chip เปลี่ยนเป็น border แดงเมื่อ specialtyError
                color: _specialtyError && !selected
                    ? _errorColor
                    : (selected ? _blue : _border),
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
        _typeChip('client', Icons.person_rounded, 'ลูกความ', 'ปรึกษา / หาทนาย'),
        const SizedBox(width: 10),
        _typeChip('lawyer', Icons.gavel_rounded, 'ทนายความ', 'รับเคส'),
      ],
    );
  }

  Widget _typeChip(String value, IconData icon, String label, String sub) {
    final selected = _userType == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() {
          _userType = value;
          _selectedSpecialties.clear();
          _barNumError = null;
          _specialtyError = false;
        }),
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
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 52,
        decoration: BoxDecoration(
          color: _isLoading ? _blue.withOpacity(0.7) : _blue,
          borderRadius: BorderRadius.circular(14),
          boxShadow: _isLoading
              ? []
              : [
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
    Key? key, // รับ GlobalKey เพื่อให้ scroll มาหาได้
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool obscure = false,
    Widget? suffix,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    int? maxLength,
    ValueChanged<String>? onChanged,
    String? errorText,
  }) {
    return Column(
      key: key, // ผูก key ที่ Column ครอบทั้ง TextField + error text
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
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
            prefixIcon: Icon(icon,
                color: errorText != null ? _errorColor : Colors.grey, size: 20),
            suffixIcon: suffix,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                    color: errorText != null ? _errorColor : _border)),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                    color: errorText != null ? _errorColor : _border)),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                    color: errorText != null ? _errorColor : _blue,
                    width: 1.5)),
            fillColor: errorText != null
                ? _errorColor.withOpacity(0.04)
                : const Color(0xFFFAFAFA),
            filled: true,
          ),
        ),
        if (errorText != null) ...[
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.error_outline_rounded,
                  size: 13, color: _errorColor),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  errorText,
                  style: const TextStyle(
                      fontSize: 11,
                      color: _errorColor,
                      fontWeight: FontWeight.w400),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  @override
  void dispose() {
    _scrollCtrl.dispose(); // dispose ScrollController ด้วย
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
