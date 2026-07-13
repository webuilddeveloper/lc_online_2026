import 'package:LawyerOnline/component/appbar.dart';
import 'package:LawyerOnline/component/loading_service.dart';
import 'package:LawyerOnline/models/user_profile_store.dart';
import 'package:LawyerOnline/services/lawyer_dashboard_service.dart';
import 'package:LawyerOnline/shared/app_typography.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

class LawyerDashboardPage extends StatefulWidget {
  const LawyerDashboardPage({super.key});

  @override
  State<LawyerDashboardPage> createState() => _LawyerDashboardPageState();
}

class _LawyerDashboardPageState extends State<LawyerDashboardPage> {
  static const _primary = Color(0xFF0262EC);
  bool _loading = true;
  LawyerDashboardStats? _stats;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final code = UserProfileStore.instance.code;
      final stats = await LawyerDashboardService.loadForLawyer(code);
      if (mounted) setState(() => _stats = stats);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEEF2F5),
      appBar: appBar(
        title: 'lawyerDashboardTitle'.tr(),
        backBtn: true,
        rightBtn: false,
        backAction: () => Navigator.pop(context),
        rightAction: () {},
      ),
      body: _loading
          ? AppLoadingView(message: 'loading'.tr())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _heroCard(),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                          child: _statCard(
                        'lawyerDashboardActive'.tr(),
                        '${_stats?.activeCases ?? 0}',
                        Icons.play_circle_outline,
                        const Color(0xFF2E7D32),
                      )),
                      const SizedBox(width: 10),
                      Expanded(
                          child: _statCard(
                        'lawyerDashboardDone'.tr(),
                        '${_stats?.completedCases ?? 0}',
                        Icons.check_circle_outline,
                        _primary,
                      )),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                          child: _statCard(
                        'lawyerDashboardPending'.tr(),
                        '${_stats?.pendingCases ?? 0}',
                        Icons.hourglass_top_rounded,
                        const Color(0xFFF5A623),
                      )),
                      const SizedBox(width: 10),
                      Expanded(
                          child: _statCard(
                        'lawyerDashboardCancelled'.tr(),
                        '${_stats?.cancelledCases ?? 0}',
                        Icons.cancel_outlined,
                        const Color(0xFFD32F2F),
                      )),
                    ],
                  ),
                  const SizedBox(height: 14),
                  _panel(
                    'lawyerDashboardEarnings'.tr(),
                    '฿${(_stats?.estimatedEarnings ?? 0).toStringAsFixed(0)}',
                    Icons.payments_outlined,
                  ),
                  const SizedBox(height: 10),
                  _panel(
                    'lawyerDashboardRating'.tr(),
                    '${(_stats?.averageRating ?? 0).toStringAsFixed(1)} (${_stats?.reviewCount ?? 0})',
                    Icons.star_rounded,
                  ),
                  const SizedBox(height: 10),
                  _panel(
                    'lawyerDashboardUrgent'.tr(),
                    '${_stats?.acceptedUrgentCases ?? 0}',
                    Icons.bolt_rounded,
                  ),
                  const SizedBox(height: 10),
                  _panel(
                    'lawyerDashboardBooking'.tr(),
                    '${_stats?.acceptedBookingCases ?? 0}',
                    Icons.event_available_rounded,
                  ),
                ],
              ),
            ),
    );
  }

  Widget _heroCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0262EC), Color(0xFF02A8D1)],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('lawyerDashboardTotalCases'.tr(),
              style: AppTypography.prompt(
                  color: Colors.white70, fontSize: 13)),
          const SizedBox(height: 6),
          Text('${_stats?.totalCases ?? 0}',
              style: AppTypography.prompt(
                  color: Colors.white,
                  fontSize: 36,
                  fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }

  Widget _statCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 10),
          Text(value,
              style: AppTypography.prompt(
                  fontSize: 22, fontWeight: FontWeight.w800)),
          Text(label, style: AppTypography.hint().copyWith(fontSize: 12)),
        ],
      ),
    );
  }

  Widget _panel(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(icon, color: _primary),
          const SizedBox(width: 12),
          Expanded(
              child: Text(label,
                  style: AppTypography.prompt(fontWeight: FontWeight.w600))),
          Text(value,
              style: AppTypography.prompt(
                  fontWeight: FontWeight.w700, color: _primary)),
        ],
      ),
    );
  }
}
