import 'package:LawyerOnline/component/dialog_service.dart';
import 'package:LawyerOnline/main.dart';
import 'package:LawyerOnline/models/user_profile_store.dart';
import 'package:LawyerOnline/services/lawyer_case_broadcast_service.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

class LawyerApplyNotificationHandler {
  static bool isLawyerApplyApproved(Map<String, dynamic> data) {
    final page = data['page']?.toString() ?? '';
    final type = data['type']?.toString() ?? '';
    return page == 'lawyer_apply_approved' || type == 'lawyer_apply_approved';
  }

  /// Reload profile from API and update UI when admin approves lawyer application.
  static Future<void> handle({bool showDialog = true}) async {
    final store = UserProfileStore.instance;
    if (!store.isLoggedIn || store.code.isEmpty) return;

    final previousType = store.userType;
    final wasPending = store.isLawyerApplyPending;
    final refreshed = await store.refreshFromApi();
    if (!refreshed) return;

    final becameLawyer =
        store.userType == 'lawyer' && (previousType != 'lawyer' || wasPending);
    if (!becameLawyer) return;

    await LawyerCaseBroadcastService.instance.sync();

    if (!showDialog) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final context = navigatorKey.currentContext;
      if (context == null || !context.mounted) return;

      DialogService.showSuccess(
        context,
        title: 'lawyerApplyApprovedTitle'.tr(),
        message: 'lawyerApplyApprovedMessage'.tr(),
      );
    });
  }
}
