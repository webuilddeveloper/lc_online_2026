import 'package:LawyerOnline/component/appbar.dart';
import 'package:LawyerOnline/component/dialog_service.dart';
import 'package:LawyerOnline/component/loading_service.dart';
import 'package:LawyerOnline/models/user_profile_store.dart';
import 'package:LawyerOnline/services/referral_service.dart';
import 'package:LawyerOnline/shared/app_typography.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ReferralPage extends StatefulWidget {
  const ReferralPage({super.key});

  @override
  State<ReferralPage> createState() => _ReferralPageState();
}

class _ReferralPageState extends State<ReferralPage> {
  bool _loading = true;
  ReferralStats? _stats;
  final _applyCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _applyCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final code = UserProfileStore.instance.code;
      final stats = await ReferralService.loadStats(code);
      if (mounted) setState(() => _stats = stats);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _applyCode() async {
    final code = _applyCtrl.text.trim();
    if (code.isEmpty) return;
    final ok = await ReferralService.applyCode(
      referralCode: code,
      newUserCode: UserProfileStore.instance.code,
    );
    if (!mounted) return;
    if (ok) {
      DialogService.showSuccess(
        context,
        title: 'successTitle'.tr(),
        message: 'referralApplySuccess'.tr(),
      );
    } else {
      DialogService.showError(
        context,
        title: 'errorTitle'.tr(),
        message: 'referralApplyFailed'.tr(),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: appBar(
        title: 'referralTitle'.tr(),
        backBtn: true,
        rightBtn: false,
        backAction: () => Navigator.pop(context),
        rightAction: () {},
      ),
      body: _loading
          ? const AppLoadingView()
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('referralYourCode'.tr(),
                              style: AppTypography.prompt(
                                  fontWeight: FontWeight.w700, fontSize: 14)),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  _stats?.referralCode ?? '-',
                                  style: AppTypography.prompt(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w800,
                                    color: const Color(0xFF0262EC),
                                  ),
                                ),
                              ),
                              IconButton(
                                onPressed: () {
                                  final c = _stats?.referralCode ?? '';
                                  if (c.isEmpty) return;
                                  Clipboard.setData(ClipboardData(text: c));
                                },
                                icon: const Icon(Icons.copy_rounded),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'referralStats'.tr(namedArgs: {
                              'invites': '${_stats?.totalInvites ?? 0}',
                              'rewards': '${_stats?.totalRewards ?? 0}',
                            }),
                            style: AppTypography.prompt(
                                fontSize: 13, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text('referralApplyTitle'.tr(),
                      style: AppTypography.prompt(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _applyCtrl,
                    decoration: InputDecoration(
                      hintText: 'referralApplyHint'.tr(),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: _applyCode,
                    child: Text('referralApplyBtn'.tr()),
                  ),
                ],
              ),
            ),
    );
  }
}
