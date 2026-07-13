import 'package:LawyerOnline/privacy-policy.dart';
import 'package:LawyerOnline/services/pdpa_service.dart';
import 'package:LawyerOnline/shared/app_typography.dart';
import 'package:LawyerOnline/terms.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

class PdpaConsentPage extends StatefulWidget {
  final VoidCallback onAccepted;

  const PdpaConsentPage({super.key, required this.onAccepted});

  @override
  State<PdpaConsentPage> createState() => _PdpaConsentPageState();
}

class _PdpaConsentPageState extends State<PdpaConsentPage> {
  bool _acceptedPdpa = false;
  bool _acceptedDisclaimer = false;

  bool get _canContinue => _acceptedPdpa && _acceptedDisclaimer;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 12),
              Text(
                'pdpaTitle'.tr(),
                style: AppTypography.prompt(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF1A2340),
                ),
              ),
              const SizedBox(height: 8),
              Text('pdpaSubtitle'.tr(), style: AppTypography.hint()),
              const SizedBox(height: 24),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      _checkTile(
                        value: _acceptedPdpa,
                        title: 'pdpaConsentLabel'.tr(),
                        subtitle: 'pdpaConsentDesc'.tr(),
                        onChanged: (v) => setState(() => _acceptedPdpa = v),
                        onLink: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const PrivacyPolicyPage(),
                          ),
                        ),
                        linkLabel: 'privacyPolicy'.tr(),
                      ),
                      const SizedBox(height: 12),
                      _checkTile(
                        value: _acceptedDisclaimer,
                        title: 'legalDisclaimerTitle'.tr(),
                        subtitle: 'legalDisclaimerBody'.tr(),
                        onChanged: (v) =>
                            setState(() => _acceptedDisclaimer = v),
                        onLink: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const TermsPage(),
                          ),
                        ),
                        linkLabel: 'terms'.tr(),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _canContinue ? _accept : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0262EC),
                    disabledBackgroundColor: Colors.grey.shade300,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text('pdpaAccept'.tr(), style: AppTypography.button()),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _accept() async {
    await PdpaService.acceptPdpa();
    await PdpaService.acceptDisclaimer();
    widget.onAccepted();
  }

  Widget _checkTile({
    required bool value,
    required String title,
    required String subtitle,
    required ValueChanged<bool> onChanged,
    required VoidCallback onLink,
    required String linkLabel,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF2F6FF),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            value: value,
            activeColor: const Color(0xFF0262EC),
            onChanged: (v) => onChanged(v ?? false),
            title: Text(title,
                style: AppTypography.prompt(fontWeight: FontWeight.w600)),
            subtitle: Text(subtitle, style: AppTypography.hint()),
            controlAffinity: ListTileControlAffinity.leading,
          ),
          TextButton(onPressed: onLink, child: Text(linkLabel)),
        ],
      ),
    );
  }
}
