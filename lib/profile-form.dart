import 'package:LawyerOnline/component/dialog_service.dart';
import 'package:flutter/material.dart';
import 'package:LawyerOnline/component/appbar.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/services.dart';
import 'package:LawyerOnline/services/auth_service.dart'; // EmailDuplicateException อยู่ในไฟล์นี้
import 'package:LawyerOnline/models/user_profile_store.dart';

class ProfileFormPage extends StatefulWidget {
  const ProfileFormPage({super.key});

  @override
  State<ProfileFormPage> createState() => _ProfileFormPageState();
}

class _ProfileFormPageState extends State<ProfileFormPage>
    with SingleTickerProviderStateMixin {
  // ── controllers ──────────────────────────────────────────────────────
  final TextEditingController firstNameController = TextEditingController();
  final TextEditingController lastNameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController emailController = TextEditingController();

  // ── scroll ───────────────────────────────────────────────────────────
  final ScrollController _scrollCtrl = ScrollController();
  final GlobalKey _firstNameKey = GlobalKey();
  final GlobalKey _lastNameKey = GlobalKey();
  final GlobalKey _phoneKey = GlobalKey();
  final GlobalKey _emailKey = GlobalKey();

  // ── inline error state ───────────────────────────────────────────────
  String? _firstNameError;
  String? _lastNameError;
  String? _phoneError;
  String? _emailError;

  bool isLoading = false;

  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  File? profileImage;
  final ImagePicker picker = ImagePicker();

  static const Color _blue = Color(0xFF0262EC);
  static const Color _border = Color(0xFFECEDF0);
  static const Color _errorColor = Color(0xFFD32F2F);

  // ── อ่านค่าจาก UserProfileStore โดยตรง ────────────────────────────
  String get _userType => UserProfileStore.instance.userType;
  String get _typeLogin => UserProfileStore.instance.typeLogin;
  String get _code => UserProfileStore.instance.code;
  String get _storedImageUrl => UserProfileStore.instance.imageUrl;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 400));
    _scaleAnimation =
        CurvedAnimation(parent: _controller, curve: Curves.elasticOut);
    _loadFromStore();
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    _controller.dispose();
    firstNameController.dispose();
    lastNameController.dispose();
    phoneController.dispose();
    emailController.dispose();
    super.dispose();
  }

  // ── โหลดค่าจาก UserProfileStore ────────────────────────────────────
  void _loadFromStore() {
    final store = UserProfileStore.instance;
    firstNameController.text = store.firstName;
    lastNameController.text = store.lastName;
    phoneController.text = store.phone;
    emailController.text = store.email;
  }

  // ── validation helpers ───────────────────────────────────────────────
  bool _isEmailValid(String email) {
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) return false;
    
    // เช็คค่ายอีเมลที่อนุญาต (สามารถเพิ่ม/ลดได้ตามต้องการ)
    final validDomains = [
      'gmail.com',
      'hotmail.com',
      'outlook.com',
      'yahoo.com',
      'icloud.com',
      'live.com',
    ];
    final domain = email.split('@').last.toLowerCase();
    return validDomains.contains(domain);
  }

  // เบอร์ต้องครบ 10 หลักพอดี เหมือน register
  bool _isPhoneValid(String phone) =>
      phone.replaceAll(RegExp(r'\D'), '').length == 10;

  bool get _hasChanges {
    final store = UserProfileStore.instance;
    return firstNameController.text.trim() != store.firstName ||
        lastNameController.text.trim() != store.lastName ||
        phoneController.text.trim() != store.phone ||
        emailController.text.trim() != store.email ||
        profileImage != null;
  }

  // ── scroll to key ────────────────────────────────────────────────────
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

  Future<void> pickImage() async {
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        profileImage = File(image.path);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEEF2F5),
      appBar: appBarCustom(
        title: "แก้ไขข้อมูลส่วนตัว",
        backBtn: true,
        backAction: () => Navigator.pop(context),
        isRightWidget: false,
      ),
      body: ListView(
        controller: _scrollCtrl,
        padding: const EdgeInsets.fromLTRB(15, 20, 15, 100),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(.05),
                  blurRadius: 15,
                  offset: const Offset(0, 6),
                )
              ],
            ),
            child: Column(
              children: [
                /// Profile Image
                GestureDetector(
                  onTap: pickImage,
                  child: Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      CircleAvatar(
                        radius: 45,
                        backgroundColor: _blue,
                        backgroundImage: profileImage != null
                            ? FileImage(profileImage!) as ImageProvider
                            : _storedImageUrl.isEmpty
                                ? null
                                : _typeLogin == 'local'
                                    ? AssetImage(_storedImageUrl)
                                        as ImageProvider
                                    : NetworkImage(_storedImageUrl),
                        child: _storedImageUrl.isEmpty && profileImage == null
                            ? const Icon(Icons.person,
                                size: 45, color: Colors.white)
                            : null,
                      ),
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(
                          color: _blue,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.camera_alt,
                          size: 16,
                          color: Colors.white,
                        ),
                      )
                    ],
                  ),
                ),

                const SizedBox(height: 25),

                _textField(
                  fieldKey: _firstNameKey,
                  title: "ชื่อ *",
                  controller: firstNameController,
                  icon: Icons.person_outline,
                  errorText: _firstNameError,
                  onChanged: (_) => setState(() => _firstNameError = null),
                ),
                const SizedBox(height: 15),
                _textField(
                  fieldKey: _lastNameKey,
                  title: "นามสกุล *",
                  controller: lastNameController,
                  icon: Icons.person_outline,
                  errorText: _lastNameError,
                  onChanged: (_) => setState(() => _lastNameError = null),
                ),
                const SizedBox(height: 15),
                _textField(
                  fieldKey: _phoneKey,
                  title: "เบอร์โทรศัพท์ * (10 หลัก)",
                  controller: phoneController,
                  icon: Icons.phone_outlined,
                  maxLength: 10,
                  keyboardType: TextInputType.phone,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  errorText: _phoneError,
                  onChanged: (_) => setState(() => _phoneError = null),
                ),
                const SizedBox(height: 15),
                _textField(
                  fieldKey: _emailKey,
                  title: "อีเมล *",
                  controller: emailController,
                  icon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                  errorText: _emailError,
                  onChanged: (_) => setState(() => _emailError = null),
                ),

                const SizedBox(height: 25),
                _saveButton(),
              ],
            ),
          )
        ],
      ),
    );
  }

  // ── TEXT FIELD ──────────────────────────────────────────────────────
  Widget _textField({
    required GlobalKey fieldKey,
    required String title,
    required TextEditingController controller,
    required IconData icon,
    int? maxLength,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    String? errorText,
    ValueChanged<String>? onChanged,
  }) {
    return Column(
      key: fieldKey,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 13,
            color: _blue,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          maxLength: maxLength,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          onChanged: onChanged,
          decoration: InputDecoration(
            counterText: '',
            prefixIcon: Icon(
              icon,
              color: errorText != null ? _errorColor : Colors.grey,
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  BorderSide(color: errorText != null ? _errorColor : _border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  BorderSide(color: errorText != null ? _errorColor : _border),
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
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  // ── SAVE BUTTON ─────────────────────────────────────────────────────
  Widget _saveButton() {
    final canSave = _hasChanges && !isLoading;

    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: canSave ? _onSave : null,
      child: Container(
        height: 50,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: canSave ? _blue : Colors.grey.shade400,
        ),
        child: Center(
          child: isLoading
              ? const CircularProgressIndicator(color: Colors.white)
              : const Text(
                  "บันทึกข้อมูล",
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16),
                ),
        ),
      ),
    );
  }

  // ── SAVE LOGIC ──────────────────────────────────────────────────────
  Future<void> _onSave() async {
    final firstName = firstNameController.text.trim();
    final lastName = lastNameController.text.trim();
    final phone = phoneController.text.trim();
    final email = emailController.text.trim();
    final userType = _userType;

    // ── ล้าง error ทั้งหมดก่อน validate ──────────────────────────────
    setState(() {
      _firstNameError = null;
      _lastNameError = null;
      _phoneError = null;
      _emailError = null;
    });

    // ── validate ทุก field พร้อมกัน เก็บ key แรกที่ error ──────────
    GlobalKey? firstErrorKey;

    if (firstName.isEmpty) {
      _firstNameError = 'กรุณากรอกชื่อ';
      firstErrorKey ??= _firstNameKey;
    }

    if (lastName.isEmpty) {
      _lastNameError = 'กรุณากรอกนามสกุล';
      firstErrorKey ??= _lastNameKey;
    }

    if (phone.isEmpty) {
      _phoneError = 'กรุณากรอกเบอร์โทรศัพท์';
      firstErrorKey ??= _phoneKey;
    } else if (!_isPhoneValid(phone)) {
      _phoneError = 'เบอร์โทรศัพท์ต้องมี 10 หลัก';
      firstErrorKey ??= _phoneKey;
    }

    if (email.isEmpty) {
      _emailError = 'กรุณากรอกอีเมล';
      firstErrorKey ??= _emailKey;
    } else if (!_isEmailValid(email)) {
      _emailError = 'รูปแบบอีเมลไม่ถูกต้อง';
      firstErrorKey ??= _emailKey;
    }

    // ── ถ้ามี error → setState แล้ว scroll ไป field แรก ─────────────
    if (firstErrorKey != null) {
      setState(() {});
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToKey(firstErrorKey!);
      });
      return;
    }

    setState(() => isLoading = true);

    try {
      await AuthService.updateProfile(
        code: _code,
        email: email,
        firstName: firstName,
        lastName: lastName,
        phone: phone,
        imageUrl: _storedImageUrl,
        userType: userType, // ✅ ส่ง userType เดิมไปด้วยเสมอ
      );

      // ── อัปเดต store → persist + broadcast ให้ทุก widget ทราบทันที ──
      await UserProfileStore.instance.updateFromProfile(
        firstName: firstName,
        lastName: lastName,
        phone: phone,
        email: email,
        userType: userType, // ✅ ส่ง userType เดิมไปด้วยเสมอ
      );

      if (!mounted) return;
      setState(() => isLoading = false);

      DialogService.showSuccess(
        context,
        title: "บันทึกข้อมูลแล้ว",
        message: "ระบบได้บันทึกข้อมูลเรียบร้อยแล้ว",
        onClose: () => Navigator.pop(context),
      );
    } on EmailDuplicateException catch (e) {
      // ── AuthService ตรวจ server message แล้วส่ง EmailDuplicateException มา ──
      // จับ type ได้แน่นอน ไม่ต้อง guess keyword อีกต่อไป
      if (!mounted) return;
      setState(() {
        isLoading = false;
        _emailError = e.message;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToKey(_emailKey);
      });
    } on PhoneDuplicateException catch (e) {
      // ── AuthService ตรวจ server message แล้วส่ง PhoneDuplicateException มา ──
      if (!mounted) return;
      setState(() {
        isLoading = false;
        _phoneError = e.message;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToKey(_phoneKey);
      });
    } on PasswordIncorrectException catch (e) {
      if (!mounted) return;
      setState(() {
        isLoading = false;
      });
      DialogService.showError(context, title: "รหัสผ่านไม่ถูกต้อง", message: e.message);
    } catch (e) {
      if (!mounted) return;
      setState(() => isLoading = false);
      final errorMsg = e.toString().replaceFirst('Exception: ', '');
      DialogService.showError(context,
          title: "เกิดข้อผิดพลาด", message: errorMsg);
    }
  }
}
