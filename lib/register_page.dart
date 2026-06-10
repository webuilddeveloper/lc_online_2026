import 'dart:io';
import 'package:LawyerOnline/component/appbar.dart';
import 'package:LawyerOnline/component/dialog_service.dart';
import 'package:LawyerOnline/services/auth_service.dart';
import 'package:LawyerOnline/shared/api_provider.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:LawyerOnline/login.dart';
import 'package:LawyerOnline/shared/responsive/app_layout.dart';
import 'package:LawyerOnline/shared/responsive/res_layout.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final TextEditingController _nameCtrl = TextEditingController();
  final TextEditingController _phoneCtrl = TextEditingController();
  final TextEditingController _emailCtrl = TextEditingController();
  final TextEditingController _passwordCtrl = TextEditingController();
  final TextEditingController _confirmCtrl = TextEditingController();
  final TextEditingController lawyerNoCtrl = TextEditingController();
  final TextEditingController idCardCtrl = TextEditingController();

  final ScrollController _scrollCtrl = ScrollController();
  final GlobalKey _nameKey = GlobalKey();
  final GlobalKey _phoneKey = GlobalKey();
  final GlobalKey lawyerNoKey = GlobalKey();
  final GlobalKey _specialtyKey = GlobalKey();
  final GlobalKey _emailKey = GlobalKey();
  final GlobalKey _passwordKey = GlobalKey();
  final GlobalKey _confirmKey = GlobalKey();
  final GlobalKey _idCardKey = GlobalKey();

  String _userType = 'client';
  bool _pwVisible = false;
  bool _cfVisible = false;
  bool _agreeTerms = false;
  bool _isLoading = false;
  XFile? profileImage;
  int _pwStrength = 0;

  String? _nameError;
  String? _phoneError;
  String? _emailError;
  String? _passwordError;
  String? _confirmError;
  String? lawyerNoError;
  String? idCardError;
  bool _specialtyError = false;
  String _imageUrl = '';
  String provinceTitle = '';
  String provinceCode = '';

  List<dynamic> _specialtyOptions = [];
  Set<String> _selectedSpecialties = {};
  List<dynamic> provinceList = [];

  final ImagePicker _picker = ImagePicker();

  static const Color _blue = Color(0xFF0262EC);
  static const Color _bg = Color(0xFFEEF2F5);
  static const Color _border = Color(0xFFECEDF0);
  static const Color _errorColor = Color(0xFFD32F2F);

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
        return 'strengthWeak,'.tr();
      case 2:
        return 'strengthFair'.tr();
      case 3:
        return 'strengthGood'.tr();
      case 4:
        return 'strengthStrong'.tr();
      default:
        return '';
    }
  }

  void _scrollToKey(GlobalKey key) {
    final ctx = key.currentContext;
    if (ctx == null) return;
    Scrollable.ensureVisible(ctx,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
        alignment: 0.3);
  }

  _imgFromCamera() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.camera);
    setState(() {
      profileImage = image!;
    });
    _upload();
  }

  _imgFromGallery() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    setState(() {
      profileImage = image!;
    });
    _upload();
  }

  void _upload() async {
    if (profileImage == null) return;
    uploadImageX(profileImage!).then((res) {
      setState(() {
        _imageUrl = res;
      });
    }).catchError((err) {
      print(err);
    });
  }

  Future<void> _callReadSubTopic() async {
    final param = await postDio("${server}/m/topic/subTopic/read", {});
    setState(() {
      _specialtyOptions = [...param['objectData']];
    });
  }

  Future<void> _callReadProvince() async {
    final param = await postDio("${serverLC}route/province/read", {});

    setState(() {
      provinceList = [
        {"code": "0", "title": "เลือกจังหวัด"},
        ...param['objectData']
      ];
    });
    print(provinceList);
  }

  Future<void> _submit() async {
    setState(() {
      _nameError = null;
      _phoneError = null;
      _emailError = null;
      _passwordError = null;
      _confirmError = null;
      lawyerNoError = null;
      _specialtyError = false;
    });

    if (!_agreeTerms) {
      _showError('agreeTermsRequired'.tr());
      return;
    }

    GlobalKey? firstErrorKey;

    if (_nameCtrl.text.trim().isEmpty) {
      _nameError = 'nameRequired'.tr();
      firstErrorKey ??= _nameKey;
    } else if (_nameCtrl.text.trim().split(RegExp(r'\s+')).length < 2) {
      _nameError = 'nameTooShort'.tr();
      firstErrorKey ??= _nameKey;
    }

    if (!_isPhoneValid(_phoneCtrl.text)) {
      _phoneError = 'phoneInvalidMin'.tr();
      firstErrorKey ??= _phoneKey;
    }

    if (_userType == 'lawyer') {
      if (lawyerNoCtrl.text.trim().isEmpty) {
        lawyerNoError = 'lawyerNoRequired'.tr();
        firstErrorKey ??= lawyerNoKey;
      } else if (!_isBarNumValid(lawyerNoCtrl.text)) {
        lawyerNoError = 'lawyerNoInvalid'.tr();
        firstErrorKey ??= lawyerNoKey;
      }
      if (_selectedSpecialties.isEmpty) {
        _specialtyError = true;
        firstErrorKey ??= _specialtyKey;
      }
    }

    if (_emailCtrl.text.trim().isEmpty) {
      _emailError = 'emailRequired'.tr();
      firstErrorKey ??= _emailKey;
    } else if (!_isEmailValid(_emailCtrl.text.trim())) {
      _emailError = 'emailInvalid'.tr();
      firstErrorKey ??= _emailKey;
    }

    if (_passwordCtrl.text.isEmpty) {
      _passwordError = 'passwordRequired'.tr();
      firstErrorKey ??= _passwordKey;
    } else if (_passwordCtrl.text.length < 8) {
      _passwordError = 'passwordTooShort'.tr();
      firstErrorKey ??= _passwordKey;
    }

    if (_confirmCtrl.text.isEmpty) {
      _confirmError = 'confirmPasswordRequired'.tr();
      firstErrorKey ??= _confirmKey;
    } else if (_passwordCtrl.text != _confirmCtrl.text) {
      _confirmError = 'passwordMismatch'.tr();
      firstErrorKey ??= _confirmKey;
    }

    // if (firstErrorKey != null) {
    //   setState(() {});
    //   WidgetsBinding.instance.addPostFrameCallback((_) {
    //     _scrollToKey(firstErrorKey!);
    //   });
    //   return;
    // }

    final fullName = _nameCtrl.text.trim();
    final parts = fullName.split(RegExp(r'\s+'));
    final firstName = parts.isNotEmpty ? parts.first : '';
    final lastName = parts.length > 1 ? parts.sublist(1).join(' ') : '';
    final userType = _userType == 'lawyer' ? 'lawyer' : 'user';

    print(_selectedSpecialties.toList());
    print('======------====== ${lawyerNoCtrl.text}');

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
          lawyerNo: lawyerNoCtrl.text,
          idCard: idCardCtrl.text,
          imageUrl: _imageUrl,
          expertiseList: _selectedSpecialties.toList(),
          provinceCode: provinceCode,
          provinceTitle: provinceTitle);

      if (!mounted) return;
      setState(() => _isLoading = false);
      _showSuccess();
    } on EmailDuplicateException {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _emailError = 'emailDuplicate'.tr();
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToKey(_emailKey);
      });
    } on PhoneDuplicateException {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _phoneError = 'phoneDuplicate'.tr();
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToKey(_phoneKey);
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      final raw = error.toString().toLowerCase();
      String friendlyMsg;
      if (raw.contains('network') ||
          raw.contains('connection') ||
          raw.contains('timeout')) {
        friendlyMsg = 'networkError'.tr();
      } else if (raw.contains('server') || raw.contains('500')) {
        friendlyMsg = 'serverError'.tr();
      } else {
        friendlyMsg = 'genericError'.tr();
      }
      _showError(friendlyMsg);
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
              child: Text('ok'.tr(), style: const TextStyle(color: _blue))),
        ],
      ),
    );
  }

  void _showSuccess() {
    final pageContext = context;
    DialogService.showSuccess(
      context,
      title: "registerSuccess".tr(),
      message: "registerSuccessMessage".tr(),
      onClose: () {
        Navigator.pushAndRemoveUntil(pageContext,
            MaterialPageRoute(builder: (_) => LoginPage()), (route) => false);
      },
    );
  }

  // ── Specialty Dialog ──────────────────────────────────────────────────────────
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
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withOpacity(0.12),
                        blurRadius: 30,
                        offset: const Offset(0, 10))
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // ── Header ──
                    Container(
                      padding: const EdgeInsets.fromLTRB(24, 24, 16, 16),
                      decoration: const BoxDecoration(
                        color: Color(0xFFE8F0FE),
                        borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(28),
                            topRight: Radius.circular(28)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                                color: _blue,
                                borderRadius: BorderRadius.circular(10)),
                            child: const Icon(Icons.gavel_rounded,
                                color: Colors.white, size: 18),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('ความเชี่ยวชาญ',
                                    style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                        color: _blue)),
                                Text('เลือกได้มากกว่า 1 อย่าง',
                                    style: TextStyle(
                                        fontSize: 12,
                                        color: _blue.withOpacity(0.7))),
                              ],
                            ),
                          ),
                          GestureDetector(
                            onTap: () => Navigator.pop(ctx),
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: const BoxDecoration(
                                  color: Colors.white, shape: BoxShape.circle),
                              child: Icon(Icons.close_rounded,
                                  size: 18, color: Colors.grey.shade500),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // ── Selected Badge ──
                    if (tempSelected.isNotEmpty)
                      Container(
                        margin: const EdgeInsets.fromLTRB(20, 14, 20, 0),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: _blue.withOpacity(0.06),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: _blue.withOpacity(0.15)),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.check_circle_rounded,
                                size: 15, color: _blue),
                            const SizedBox(width: 8),
                            Text('เลือกแล้ว ${tempSelected.length} รายการ',
                                style: TextStyle(
                                    fontSize: 12,
                                    color: _blue,
                                    fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),

                    // ── Options ──
                    Flexible(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
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
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 180),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 9),
                                decoration: BoxDecoration(
                                  color: selected
                                      ? _blue
                                      : const Color(0xFFF5F7FA),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                      color: selected
                                          ? _blue
                                          : const Color(0xFFE0E3EA)),
                                  boxShadow: selected
                                      ? [
                                          BoxShadow(
                                              color: _blue.withOpacity(0.25),
                                              blurRadius: 8,
                                              offset: const Offset(0, 3))
                                        ]
                                      : [],
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (selected) ...[
                                      const Icon(Icons.check_rounded,
                                          size: 13, color: Colors.white),
                                      const SizedBox(width: 5),
                                    ],
                                    Flexible(
                                      child: Text(
                                        option['title'],
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: selected
                                              ? Colors.white
                                              : const Color(0xFF444444),
                                          fontWeight: selected
                                              ? FontWeight.w600
                                              : FontWeight.normal,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ),

                    // ── Footer ──
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () =>
                                  setDialogState(() => tempSelected.clear()),
                              child: Container(
                                height: 46,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF5F7FA),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                      color: const Color(0xFFE0E3EA)),
                                ),
                                child: Center(
                                  child: Text('ล้างทั้งหมด',
                                      style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey.shade600,
                                          fontWeight: FontWeight.w500)),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 2,
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  _selectedSpecialties.clear();
                                  _selectedSpecialties.addAll(tempSelected);
                                  if (_selectedSpecialties.isNotEmpty)
                                    _specialtyError = false;
                                });
                                Navigator.pop(ctx);
                              },
                              child: Container(
                                height: 46,
                                decoration: BoxDecoration(
                                  color: _blue,
                                  borderRadius: BorderRadius.circular(14),
                                  boxShadow: [
                                    BoxShadow(
                                        color: _blue.withOpacity(0.35),
                                        blurRadius: 12,
                                        offset: const Offset(0, 4))
                                  ],
                                ),
                                child: Center(
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.check_rounded,
                                          color: Colors.white, size: 17),
                                      const SizedBox(width: 6),
                                      Text(
                                        'เสร็จสิ้น${tempSelected.isNotEmpty ? " (${tempSelected.length})" : ""}',
                                        style: const TextStyle(
                                            fontSize: 14,
                                            color: Colors.white,
                                            fontWeight: FontWeight.w700),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
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
  void initState() {
    super.initState();
    _callReadSubTopic();
    _callReadProvince();
  }

  @override
  Widget build(BuildContext context) {
    final isWide = ResponsiveLayout.isDesktop(context);

    final personalInfoCard = _buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(child: _buildAvatarPicker()),
          const SizedBox(height: 24),
          _sectionLabel('whoAreYou'.tr()),
          const SizedBox(height: 8),
          _buildTypeSelector(),
          const SizedBox(height: 20),
          _sectionLabel('fullName'.tr()),
          const SizedBox(height: 6),
          _buildTextField(
            key: _nameKey,
            controller: _nameCtrl,
            hint: 'fullNameHint'.tr(),
            icon: Icons.person_outline_rounded,
            errorText: _nameError,
            onChanged: (_) => setState(() => _nameError = null),
          ),
          const SizedBox(height: 14),
          _sectionLabel('phone'.tr()),
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
          const SizedBox(height: 14),
          _sectionLabel('idCard'.tr()),
          const SizedBox(height: 6),
          _buildTextField(
            key: _idCardKey,
            controller: idCardCtrl,
            hint: 'idCardHint'.tr(),
            icon: Icons.assignment_ind_outlined,
            errorText: idCardError,
            onChanged: (_) => setState(() => idCardError = null),
          ),
          if (_userType == 'lawyer') ...[
            const SizedBox(height: 14),
            _sectionLabel('จังหวัด'.tr()),
            const SizedBox(height: 6),
            SizedBox(
              // height: 43,
              child: dropdownCustom(
                label: "จังหวัดที่เลือก",
                list: provinceList,
                isRequired: true,
                valueSelect: provinceCode,
                onChanged: (value) {
                  setState(() {
                    provinceCode = value!;
                    provinceTitle = provinceList
                        .firstWhere((x) => x['code'] == value)['title'];
                  });
                },
              ),
            ),
            const SizedBox(height: 14),
            _sectionLabel('lawyerNo'.tr()),
            const SizedBox(height: 6),
            _buildTextField(
              key: lawyerNoKey,
              controller: lawyerNoCtrl,
              hint: 'lawyerNoHint'.tr(),
              icon: Icons.badge_outlined,
              errorText: lawyerNoError,
              onChanged: (_) => setState(() => lawyerNoError = null),
            ),
            const SizedBox(height: 18),
            Row(
              key: _specialtyKey,
              children: [
                _sectionLabel('specialty'.tr()),
                const SizedBox(width: 8),
                if (_selectedSpecialties.isNotEmpty)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                        color: _blue, borderRadius: BorderRadius.circular(10)),
                    child: Text('${_selectedSpecialties.length}',
                        style: GoogleFonts.prompt(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w700)),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            if (_specialtyError)
              Row(
                children: [
                  Icon(Icons.error_outline_rounded,
                      size: 13, color: _errorColor),
                  const SizedBox(width: 4),
                  Text('specialtyRequired'.tr(),
                      style:
                          GoogleFonts.prompt(fontSize: 11, color: _errorColor)),
                ],
              ),
            Text('specialtyMultiple'.tr(),
                style: GoogleFonts.prompt(
                    fontSize: 11, color: Colors.grey.shade500)),
            const SizedBox(height: 10),
            _buildSpecialtyChips(),
          ],
        ],
      ),
    );

    final accountInfoCard = _buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionLabel('myAccount'.tr()),
          const SizedBox(height: 14),
          _sectionLabel('email'.tr()),
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
          _sectionLabel('password'.tr()),
          const SizedBox(height: 6),
          _buildTextField(
            key: _passwordKey,
            controller: _passwordCtrl,
            hint: 'passwordHint'.tr(),
            icon: Icons.lock_outline_rounded,
            obscure: !_pwVisible,
            suffix: IconButton(
              icon: Icon(
                  _pwVisible
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  color: Colors.grey,
                  size: 20),
              onPressed: () => setState(() => _pwVisible = !_pwVisible),
            ),
            errorText: _passwordError,
            onChanged: (v) => setState(() {
              _pwStrength = _calcStrength(v);
              _passwordError = null;
              if (_confirmCtrl.text.isNotEmpty && _confirmCtrl.text != v) {
                _confirmError = 'passwordMismatch'.tr();
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
          _sectionLabel('confirmPassword'.tr()),
          const SizedBox(height: 6),
          _buildTextField(
            key: _confirmKey,
            controller: _confirmCtrl,
            hint: 'confirmPasswordHint'.tr(),
            icon: Icons.lock_outline_rounded,
            obscure: !_cfVisible,
            suffix: IconButton(
              icon: Icon(
                  _cfVisible
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  color: Colors.grey,
                  size: 20),
              onPressed: () => setState(() => _cfVisible = !_cfVisible),
            ),
            errorText: _confirmError,
            onChanged: (v) => setState(() {
              _confirmError = v.isNotEmpty && v != _passwordCtrl.text
                  ? 'passwordMismatch'.tr()
                  : null;
            }),
          ),
        ],
      ),
    );

    final termsCard = _buildCard(
      child: _buildCheckRow(
        value: _agreeTerms,
        onChanged: (v) => setState(() => _agreeTerms = v ?? false),
        label: 'agreeTerms'.tr(),
        linkLabel: 'termsLink'.tr(),
      ),
    );

    return Scaffold(
      backgroundColor: _bg,
      appBar: appBar(
        title: "register".tr(),
        backBtn: true,
        rightBtn: false,
        backAction: () => goBack(),
        rightAction: () => {},
      ),
      body: AppLayout(
        maxWidth: 1000,
        child: ListView(
          controller: _scrollCtrl,
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 100),
          children: [
            if (isWide)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 5, child: personalInfoCard),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 4,
                    child: Column(children: [
                      accountInfoCard,
                      const SizedBox(height: 16),
                      termsCard
                    ]),
                  ),
                ],
              )
            else ...[
              personalInfoCard,
              const SizedBox(height: 16),
              accountInfoCard,
              const SizedBox(height: 16),
              termsCard,
            ],
            const SizedBox(height: 24),
            Center(
              child: SizedBox(
                width: isWide ? 400 : double.infinity,
                child: _buildSubmitButton(),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('alreadyHaveAccount'.tr(),
                    style: const TextStyle(
                        fontSize: 13, color: Color(0xFF8C8C8C))),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Text('loginLink'.tr(),
                      style: const TextStyle(
                          fontSize: 13,
                          color: _blue,
                          fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  dropdownCustom({
    required String label,
    bool isRequired = false,
    required List<dynamic> list,
    required String? valueSelect,
    required Function(String?) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DropdownButtonFormField<String>(
          value: list.any((e) => e['code'] == valueSelect) ? valueSelect : null,
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down_rounded,
              color: Colors.grey, size: 20),
          decoration: InputDecoration(
            counterText: '',
            hintText: label,
            hintStyle:
                GoogleFonts.prompt(fontSize: 14, color: Color(0xFF9E9E9E)),
            prefixIcon: const Icon(Icons.location_on_outlined,
                color: Colors.grey, size: 20),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: _border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: _border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: _blue, width: 1.5),
            ),
            fillColor: const Color(0xFFFAFAFA),
            filled: true,
          ),
          style: GoogleFonts.prompt(fontSize: 14, color: Color(0xFF1A1A2E)),
          dropdownColor: Colors.white,
          borderRadius: BorderRadius.circular(14),
          items: list.map<DropdownMenuItem<String>>((e) {
            return DropdownMenuItem<String>(
              value: e['code'],
              child: Text(
                e['title'],
                style:
                    GoogleFonts.prompt(fontSize: 14, color: Color(0xFF1A1A2E)),
              ),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ],
    );
  }

  // ── Specialty Chips ───────────────────────────────────────────────────────────
  Widget _buildSpecialtyChips() {
    if (_selectedSpecialties.isEmpty) {
      return GestureDetector(
        onTap: () => _showSpecialtyDialog(),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: _specialtyError
                ? _errorColor.withOpacity(0.04)
                : const Color(0xFFFAFAFA),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _specialtyError ? _errorColor : _border),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: _specialtyError
                      ? _errorColor.withOpacity(0.1)
                      : const Color(0xFFE8F0FE),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.add_rounded,
                    size: 18, color: _specialtyError ? _errorColor : _blue),
              ),
              const SizedBox(width: 10),
              Text(
                'เลือกความเชี่ยวชาญอย่างน้อย 1 อย่าง',
                style: GoogleFonts.prompt(
                    fontSize: 13,
                    color: _specialtyError
                        ? _errorColor
                        : const Color(0xFF8C8C8C)),
              ),
            ],
          ),
        ),
      );
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        ..._selectedSpecialties.map((code) {
          final option = _specialtyOptions.firstWhere(
            (o) => o['code'] == code,
            orElse: () => {'code': code, 'title': code},
          );
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
                color: _blue, borderRadius: BorderRadius.circular(20)),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(option['title'],
                    style: GoogleFonts.prompt(
                        fontSize: 13,
                        color: Colors.white,
                        fontWeight: FontWeight.w500)),
                const SizedBox(width: 6),
                GestureDetector(
                  onTap: () =>
                      setState(() => _selectedSpecialties.remove(code)),
                  child: const Icon(Icons.close_rounded,
                      size: 14, color: Colors.white),
                ),
              ],
            ),
          );
        }),
        GestureDetector(
          onTap: () => _showSpecialtyDialog(),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: const Color(0xFFE8F0FE),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _blue.withOpacity(0.3)),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.add_rounded, size: 15, color: _blue),
                SizedBox(width: 4),
                Text('เพิ่ม',
                    style: TextStyle(
                        fontSize: 12,
                        color: _blue,
                        fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ── Avatar Picker ─────────────────────────────────────────────────────────────
  Widget _buildAvatarPicker() {
    return GestureDetector(
      onTap: () => _showPickerImage(context),
      child: Stack(
        alignment: Alignment.bottomRight,
        children: [
          CircleAvatar(
            radius: 45,
            backgroundColor: const Color(0xFFE8F0FE),
            backgroundImage: _imageUrl != '' ? NetworkImage(_imageUrl) : null,
            child: _imageUrl == ''
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
        _typeChip('client', Icons.person_rounded, 'clientType'.tr(),
            'clientTypeSub'.tr()),
        const SizedBox(width: 10),
        _typeChip('lawyer', Icons.gavel_rounded, 'lawyerType'.tr(),
            'lawyerTypeSub'.tr()),
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
          lawyerNoError = null;
          _specialtyError = false;
        }),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            color: selected ? const Color(0xFFE8F0FE) : const Color(0xFFFAFAFA),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
                color: selected ? _blue : _border, width: selected ? 1.5 : 1),
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
  Widget _buildCheckRow(
      {required bool value,
      required ValueChanged<bool?> onChanged,
      required String label,
      String? linkLabel}) {
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
                style:
                    GoogleFonts.prompt(fontSize: 13, color: Color(0xFF555555)),
                children: [
                  TextSpan(text: label),
                  if (linkLabel != null)
                    TextSpan(
                        text: linkLabel,
                        style: const TextStyle(
                            color: _blue, fontWeight: FontWeight.w600)),
                  TextSpan(text: 'privacyPolicy'.tr()),
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
                      color: Colors.white, strokeWidth: 2.5))
              : Text('register'.tr(),
                  style: const TextStyle(
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

  Widget _sectionLabel(String text) => Text(text,
      style: GoogleFonts.prompt(
          fontSize: 13, color: _blue, fontWeight: FontWeight.w500));

  Widget _buildTextField({
    Key? key,
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
      key: key,
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
                  child: Text(errorText,
                      style: const TextStyle(
                          fontSize: 11,
                          color: _errorColor,
                          fontWeight: FontWeight.w400))),
            ],
          ),
        ],
      ],
    );
  }

  void _showPickerImage(context) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext bc) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('อัลบั้มรูปภาพ',
                    style: TextStyle(
                        fontSize: 13,
                        fontFamily: 'Kanit',
                        fontWeight: FontWeight.normal)),
                onTap: () {
                  _imgFromGallery();
                  Navigator.of(context).pop();
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_camera),
                title: const Text('กล้องถ่ายรูป',
                    style: TextStyle(
                        fontSize: 13,
                        fontFamily: 'Kanit',
                        fontWeight: FontWeight.normal)),
                onTap: () {
                  _imgFromCamera();
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    lawyerNoCtrl.dispose();
    super.dispose();
  }

  void goBack() async {
    Navigator.pop(context, false);
  }
}
