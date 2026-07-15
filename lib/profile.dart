import 'package:LawyerOnline/page_exam.dart';
import 'package:LawyerOnline/shared/responsive/res_layout.dart';
import 'package:LawyerOnline/about-us.dart';
import 'package:LawyerOnline/change-password.dart';
import 'package:LawyerOnline/delete-account.dart';
import 'package:LawyerOnline/device_sessions_page.dart';
import 'package:LawyerOnline/referral_page.dart';
import 'package:LawyerOnline/favorite-lawyers.dart';
import 'package:LawyerOnline/menu.dart';
import 'package:LawyerOnline/subscribe/lawyer-subscrile.dart';
import 'package:LawyerOnline/subscribe/subscribe_theme.dart';
import 'package:LawyerOnline/notification-settings.dart';
import 'package:LawyerOnline/profile-form.dart';
import 'package:LawyerOnline/lawyer-profile-view.dart';
import 'package:LawyerOnline/lawyer-edit-profile.dart';
import 'package:LawyerOnline/lawyer_apply_page.dart';
import 'package:LawyerOnline/lawyer_apply_status_page.dart';
import 'package:LawyerOnline/lawyer_dashboard_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:LawyerOnline/component/appbar.dart';
import 'package:LawyerOnline/consultation-schedule.dart';
import 'package:LawyerOnline/component/dialog_service.dart';
import 'package:LawyerOnline/models/user_profile_store.dart';
import 'package:LawyerOnline/models/lawyer/lawyer_profile_store.dart';
import 'package:LawyerOnline/widgets/profile/profile_avatar.dart';
import 'package:easy_localization/easy_localization.dart';

class ProfilePage extends StatefulWidget {
  ProfilePage({Key? key, this.userType, this.name, this.imageUrl});

  final String? userType;
  final String? name;
  final String? imageUrl;

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  String get userType => UserProfileStore.instance.userType;
  String get name => UserProfileStore.instance.name;
  String get imageUrl => UserProfileStore.instance.imageUrl;
  String get typeLogin => UserProfileStore.instance.typeLogin;
  bool get _isLawyerApplyPending => UserProfileStore.instance.isLawyerApplyPending;

  bool get _isPro => LawyerProfileStore.instance.isPro && userType == 'lawyer';

  @override
  void initState() {
    super.initState();
    LawyerProfileStore.instance.addListener(_onStoreChanged);
    UserProfileStore.instance.addListener(_onStoreChanged);
  }

  @override
  void dispose() {
    LawyerProfileStore.instance.removeListener(_onStoreChanged);
    UserProfileStore.instance.removeListener(_onStoreChanged);
    super.dispose();
  }

  void _onStoreChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEEF2F5),
      appBar: appBar(
        title: "profile".tr(),
        backBtn: false,
        rightBtn: false,
        backAction: () => goBack(),
        rightAction: () => {},
      ),
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth:
                ResponsiveLayout.isDesktop(context) ? 560 : double.infinity,
          ),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
            children: [
              const SizedBox(height: 20),
              profileMenuCard(),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget profileMenuCard() {
    return Stack(
      alignment: Alignment.topCenter,
      children: [
        // CARD
        Container(
          margin: const EdgeInsets.only(top: 50),
          padding: const EdgeInsets.fromLTRB(0, 60, 0, 20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, -4),
              )
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // ชื่อ
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF0262EC),
                    ),
                  ),
                  if (_isPro) ...[
                    const SizedBox(width: 6),
                    const ProBadge(fontSize: 10),
                  ],
                ],
              ),

              const SizedBox(height: 20),
              Padding(
                padding:
                    const EdgeInsets.symmetric(vertical: 7, horizontal: 20),
                child: Text(
                  'myAccount'.tr(),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              if (userType == 'lawyer')
                menuItem(
                  title: 'lawyerProfile'.tr(),
                  onTap: () => {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const LawyerProfileViewPage(),
                      ),
                    ),
                  },
                ),
              menuItem(
                title: 'editInformation'.tr(),
                onTap: () => {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => userType == 'lawyer'
                          ? const LawyerEditProfilePage()
                          : const ProfileFormPage(),
                    ),
                  ),
                },
              ),

              menuItem(
                title: 'changePassword'.tr(),
                onTap: () => {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ChangePasswordPage(),
                    ),
                  ),
                },
              ),

              if (userType == 'user' && typeLogin != 'null')
                _isLawyerApplyPending
                    ? Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 8),
                        child: GestureDetector(
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const LawyerApplyStatusPage(),
                            ),
                          ),
                          child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF8E8),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: const Color(0xFFF5A623).withOpacity(0.4),
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.hourglass_top_rounded,
                                size: 18,
                                color: Color(0xFFF5A623),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'lawyerApplyPendingMessage'.tr(),
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF7A5B00),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                    : menuItem(
                        title: 'applyAsLawyer'.tr(),
                        onTap: () async {
                          final applied = await Navigator.push<bool>(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const LawyerApplyPage(),
                            ),
                          );
                          if (applied == true && mounted) setState(() {});
                        },
                        titleStyle: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF0262EC),
                          fontWeight: FontWeight.w600,
                        ),
                        trailing: const Icon(
                          Icons.gavel_rounded,
                          size: 18,
                          color: Color(0xFF0262EC),
                        ),
                      ),

              userType == "user"
                  ? Column(
                      children: [
                        const SizedBox(height: 20),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              vertical: 7, horizontal: 20),
                          child: Text(
                            'yourActivity'.tr(),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                      ],
                    )
                  : Container(),

              userType != "lawyer"
                  ? menuItem(
                      title: 'likes'.tr(),
                      onTap: () => {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => FavoriteLawyersPage(),
                          ),
                        ),
                      },
                    )
                  : Container(),

              userType == "lawyer"
                  ? menuItem(
                      title: 'lawyerDashboardTitle'.tr(),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const LawyerDashboardPage(),
                        ),
                      ),
                      titleStyle: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF0262EC),
                        fontWeight: FontWeight.w600,
                      ),
                      trailing: const Icon(
                        Icons.analytics_outlined,
                        size: 18,
                        color: Color(0xFF0262EC),
                      ),
                    )
                  : Container(),
              userType == "lawyer"
                  ? menuItem(
                      title: 'upgradetolawyerpro'.tr(),
                      onTap: () => {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const SubscribePage(),
                          ),
                        ),
                      },
                      titleStyle: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF1F2937),
                      ),
                      trailing: const Icon(
                        Icons.balance,
                        size: 18,
                        color: Color(0xFFF5A623),
                      ),
                    )
                  : Container(),
              const SizedBox(height: 20),

              Padding(
                padding:
                    const EdgeInsets.symmetric(vertical: 7, horizontal: 20),
                child: Text(
                  'settings'.tr(),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              userType != "user"
                  ? menuItem(
                      title: 'ConsultationSchedule'.tr(),
                      onTap: () => {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ConsultationSchedule(),
                          ),
                        ),
                      },
                    )
                  : Container(),

              menuItem(
                  title: 'notifications'.tr(),
                  onTap: () => {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                const NotificationSettingPage(),
                          ),
                        ),
                      }),
              menuItem(
                title: 'changelanguage'.tr(),
                onTap: () => {showLanguagePicker(context)},
              ),
              menuItem(
                title: 'referralTitle'.tr(),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ReferralPage()),
                ),
              ),
              menuItem(
                title: 'deviceSessionsTitle'.tr(),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const DeviceSessionsPage()),
                ),
              ),
              menuItem(
                title: 'aboutUs'.tr(),
                onTap: () => {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AboutUsPage(),
                    ),
                  ),
                },
              ),
              menuItem(
                title: 'deleteAccount'.tr(),
                titleStyle: const TextStyle(
                  fontSize: 12,
                  color: Colors.red,
                ),
                onTap: () => {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => DeleteAccountPage(),
                    ),
                  ),
                },
              ),
              const SizedBox(height: 20),
              GestureDetector(
                onTap: () => _confirmLogout(),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          vertical: 10, horizontal: 30),
                      decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(
                            width: 1,
                            color: const Color(0xFFDF0A0A),
                          )),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.logout,
                            size: 16,
                            color: Color(0xFFDF0A0A),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            "logout".tr(),
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFFDF0A0A),
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),

        // AVATAR ลอยครึ่งการ์ด
        Positioned(
          top: 0,
          child: ProfileAvatar(
            imageUrl: imageUrl,
            typeLogin: typeLogin,
            size: 100,
          ),
        ),
      ],
    );
  }

  menuItem({
    required String title,
    Function? onTap,
    TextStyle? titleStyle,
    Widget? trailing,
  }) {
    return GestureDetector(
      onTap: () => onTap!(),
      child: Container(
        color: Colors.white,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: titleStyle ??
                          const TextStyle(
                            fontSize: 12,
                          ),
                    ),
                  ),
                  if (trailing != null) ...[
                    trailing,
                    const SizedBox(width: 8),
                  ],
                  const Icon(
                    Icons.arrow_forward_ios,
                    size: 12,
                    color: Color(0xFF0262EC),
                  )
                ],
              ),
            ),
            const Divider(
              color: Color(0xFFD9D9D9),
            )
          ],
        ),
      ),
    );
  }

  void goBack() async {
    Navigator.pop(context, false);
  }

  void _confirmLogout() {
    DialogService.showConfirmLogout(
      context,
      title: 'confirmLogoutTitle'.tr(),
      message: 'confirmLogoutMessage'.tr(),
      onConfirm: () => logout(),
    );
  }

  logout() async {
    await UserProfileStore.instance.resetAndClear();
    if (!mounted) return;
    await Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (context) => MenuPage(),
      ),
      (Route<dynamic> route) => false,
    );
  }
}
