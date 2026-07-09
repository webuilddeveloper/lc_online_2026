import 'package:LawyerOnline/component/dialog_service.dart';
import 'package:LawyerOnline/component/loading_service.dart';
import 'package:LawyerOnline/component/media_picker_sheet.dart';
import 'package:LawyerOnline/shared/api_provider.dart';
import 'package:LawyerOnline/shared/app_typography.dart';
import 'package:flutter/material.dart';
import 'package:LawyerOnline/component/appbar.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/services.dart';
import 'package:LawyerOnline/services/auth_service.dart';
import 'package:LawyerOnline/models/user_profile_store.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:LawyerOnline/shared/responsive/app_layout.dart';

class ProfileFormPage extends StatefulWidget {
  const ProfileFormPage({super.key});

  @override
  State<ProfileFormPage> createState() => _ProfileFormPageState();
}

class _ProfileFormPageState extends State<ProfileFormPage> {
  final TextEditingController firstNameController = TextEditingController();
  final TextEditingController lastNameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController emailController = TextEditingController();

  final ScrollController _scrollCtrl = ScrollController();
  final GlobalKey _firstNameKey = GlobalKey();
  final GlobalKey _lastNameKey = GlobalKey();
  final GlobalKey _phoneKey = GlobalKey();
  final GlobalKey _emailKey = GlobalKey();

  String? _firstNameError;
  String? _lastNameError;
  String? _phoneError;
  String? _emailError;

  bool isLoading = false;
  bool _pageLoading = true;

  XFile? profileImage;
  final ImagePicker picker = ImagePicker();

  static const Color _blue = Color(0xFF0262EC);
  static const Color _border = Color(0xFFECEDF0);
  static const Color _errorColor = Color(0xFFD32F2F);

  String get _userType => UserProfileStore.instance.userType;
  String get _code => UserProfileStore.instance.code;
  String _imageUrl = '';

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    firstNameController.dispose();
    lastNameController.dispose();
    phoneController.dispose();
    emailController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    final store = UserProfileStore.instance;
    await store.load();
    await store.refreshFromApi();
    if (!mounted) return;
    _loadFromStore();
    setState(() {
      _imageUrl = store.imageUrl;
      _pageLoading = false;
    });
  }

  void _loadFromStore() {
    final store = UserProfileStore.instance;
    firstNameController.text = store.firstName;
    lastNameController.text = store.lastName;
    phoneController.text = store.phone;
    emailController.text = store.email;
  }

  bool _isEmailValid(String email) =>
      RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email.trim());

  bool _isPhoneValid(String phone) =>
      phone.replaceAll(RegExp(r'\D'), '').length == 10;

  bool get _hasChanges {
    final store = UserProfileStore.instance;
    final currentImage = _imageUrl.isNotEmpty ? _imageUrl : store.imageUrl;
    return firstNameController.text.trim() != store.firstName ||
        lastNameController.text.trim() != store.lastName ||
        phoneController.text.trim() != store.phone ||
        emailController.text.trim() != store.email ||
        profileImage != null ||
        currentImage != store.imageUrl;
  }

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

  Future<void> _imgFromCamera() async {
    final image = await picker.pickImage(source: ImageSource.camera);
    if (image == null) return;
    setState(() => profileImage = image);
    await _upload(image);
  }

  Future<void> _imgFromGallery() async {
    final image = await picker.pickImage(source: ImageSource.gallery);
    if (image == null) return;
    setState(() => profileImage = image);
    await _upload(image);
  }

  Future<void> _upload(XFile image) async {
    try {
      final url = await uploadImageX(image);
      if (!mounted) return;
      setState(() => _imageUrl = url);
    } catch (e) {
      if (!mounted) return;
      DialogService.showError(
        context,
        title: 'errorTitle'.tr(),
        message: e.toString(),
      );
    }
  }

  Widget _buildAvatar() {
    ImageProvider? provider;
    if (profileImage != null) {
      provider = FileImage(File(profileImage!.path));
    } else if (_imageUrl.isNotEmpty) {
      provider = NetworkImage(_imageUrl);
    }

    return CircleAvatar(
      radius: 45,
      backgroundColor: _blue,
      backgroundImage: provider,
      child: provider == null
          ? const Icon(Icons.person, size: 45, color: Colors.white)
          : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEEF2F5),
      appBar: appBarCustom(
        title: 'editInfoTitle'.tr(),
        backBtn: true,
        backAction: () => Navigator.pop(context),
        isRightWidget: false,
      ),
      body: _pageLoading
          ? AppLoadingView(message: 'loading'.tr())
          : AppLayout(
              child: SizedBox(
                height: MediaQuery.of(context).size.height,
                child: ListView(
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
                          GestureDetector(
                            onTap: () => _showPickerImage(context),
                            child: Stack(
                              alignment: Alignment.bottomRight,
                              children: [
                                _buildAvatar(),
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
                            title: 'firstName'.tr(),
                            controller: firstNameController,
                            icon: Icons.person_outline,
                            errorText: _firstNameError,
                            onChanged: (_) =>
                                setState(() => _firstNameError = null),
                          ),
                          const SizedBox(height: 15),
                          _textField(
                            fieldKey: _lastNameKey,
                            title: 'lastName'.tr(),
                            controller: lastNameController,
                            icon: Icons.person_outline,
                            errorText: _lastNameError,
                            onChanged: (_) =>
                                setState(() => _lastNameError = null),
                          ),
                          const SizedBox(height: 15),
                          _textField(
                            fieldKey: _phoneKey,
                            title: 'phone'.tr(),
                            controller: phoneController,
                            icon: Icons.phone_outlined,
                            maxLength: 10,
                            keyboardType: TextInputType.phone,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly
                            ],
                            errorText: _phoneError,
                            onChanged: (_) =>
                                setState(() => _phoneError = null),
                          ),
                          const SizedBox(height: 15),
                          _textField(
                            fieldKey: _emailKey,
                            title: 'email'.tr(),
                            controller: emailController,
                            icon: Icons.email_outlined,
                            keyboardType: TextInputType.emailAddress,
                            errorText: _emailError,
                            onChanged: (_) =>
                                setState(() => _emailError = null),
                          ),
                          const SizedBox(height: 25),
                          _saveButton(),
                        ],
                      ),
                    )
                  ],
                ),
              ),
            ),
    );
  }

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
        Text(title, style: AppTypography.label(context)),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          maxLength: maxLength,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          onChanged: onChanged,
          style: AppTypography.field(context),
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
              borderSide: BorderSide(
                  color: errorText != null ? _errorColor : _border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                  color: errorText != null ? _errorColor : _border),
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
            hintStyle: AppTypography.hint(),
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
                child: Text(errorText, style: AppTypography.error()),
              ),
            ],
          ),
        ],
      ],
    );
  }

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
              ? const AppRingSpinner(color: Colors.white, size: 22)
              : Text('saveButton'.tr(), style: AppTypography.button()),
        ),
      ),
    );
  }

  Future<void> _onSave() async {
    final firstName = firstNameController.text.trim();
    final lastName = lastNameController.text.trim();
    final phone = phoneController.text.trim();
    final email = emailController.text.trim();
    final userType = _userType;
    final imageUrl = _imageUrl.isNotEmpty
        ? _imageUrl
        : UserProfileStore.instance.imageUrl;

    setState(() {
      _firstNameError = null;
      _lastNameError = null;
      _phoneError = null;
      _emailError = null;
    });

    GlobalKey? firstErrorKey;

    if (firstName.isEmpty) {
      _firstNameError = 'firstNameRequired'.tr();
      firstErrorKey ??= _firstNameKey;
    }
    if (lastName.isEmpty) {
      _lastNameError = 'lastNameRequired'.tr();
      firstErrorKey ??= _lastNameKey;
    }
    if (phone.isEmpty) {
      _phoneError = 'phoneRequired'.tr();
      firstErrorKey ??= _phoneKey;
    } else if (!_isPhoneValid(phone)) {
      _phoneError = 'phoneInvalid'.tr();
      firstErrorKey ??= _phoneKey;
    }
    if (email.isEmpty) {
      _emailError = 'emailRequired'.tr();
      firstErrorKey ??= _emailKey;
    } else if (!_isEmailValid(email)) {
      _emailError = 'emailInvalid'.tr();
      firstErrorKey ??= _emailKey;
    }

    if (firstErrorKey != null) {
      setState(() {});
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToKey(firstErrorKey!);
      });
      return;
    }

    setState(() => isLoading = true);

    try {
      final updated = await AuthService.updateProfile(
        code: _code,
        email: email,
        firstName: firstName,
        lastName: lastName,
        phone: phone,
        imageUrl: imageUrl,
        userType: userType,
      );

      if (updated != null) {
        await UserProfileStore.instance.applyUserModel(updated);
      } else {
        await UserProfileStore.instance.updateFromProfile(
          firstName: firstName,
          lastName: lastName,
          phone: phone,
          email: email,
          imageUrl: imageUrl,
          userType: userType,
        );
      }

      if (!mounted) return;
      setState(() => isLoading = false);

      DialogService.showSuccess(
        context,
        title: 'saveSuccessTitle'.tr(),
        message: 'saveSuccessMessage'.tr(),
        onClose: () => Navigator.pop(context),
      );
    } on EmailDuplicateException {
      if (!mounted) return;
      setState(() {
        isLoading = false;
        _emailError = 'emailDuplicate'.tr();
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToKey(_emailKey);
      });
    } on PhoneDuplicateException {
      if (!mounted) return;
      setState(() {
        isLoading = false;
        _phoneError = 'phoneDuplicate'.tr();
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToKey(_phoneKey);
      });
    } on PasswordIncorrectException catch (e) {
      if (!mounted) return;
      setState(() => isLoading = false);
      DialogService.showError(context,
          title: 'errorTitle'.tr(), message: e.message);
    } catch (e) {
      if (!mounted) return;
      setState(() => isLoading = false);
      final errorMsg = e.toString().replaceFirst('Exception: ', '');
      DialogService.showError(context,
          title: 'errorTitle'.tr(), message: errorMsg);
    }
  }

  void _showPickerImage(context) {
    MediaPickerSheet.showImageSources(
      context,
      onGallery: _imgFromGallery,
      onCamera: _imgFromCamera,
    );
  }
}
