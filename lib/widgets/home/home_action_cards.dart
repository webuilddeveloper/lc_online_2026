import 'package:LawyerOnline/booking/topic-page.dart';
import 'package:LawyerOnline/consultation-schedule.dart';
import 'package:LawyerOnline/consult/consult.dart';
import 'package:LawyerOnline/lawyer-job-list.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:LawyerOnline/login.dart';
import 'package:easy_localization/easy_localization.dart';

const _kCard = Colors.white;
const _kAccent = Color(0xFF2F80ED);

// ─── Action Cards ─────────────────────────────────────────────────
class HomeActionCards extends StatelessWidget {
  final String typeLogin;
  final String userType;
  final bool isUrgentCaseEnabled;
  final ValueChanged<bool> onToggleUrgentCase;
  final bool isGuest;

  const HomeActionCards({
    super.key,
    required this.typeLogin,
    required this.userType,
    required this.isUrgentCaseEnabled,
    required this.onToggleUrgentCase,
    this.isGuest = false,
  });

  @override
  Widget build(BuildContext context) {
    final bool isGuest = typeLogin == 'null';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: isGuest || userType == 'user'
          ? _buildUserCards(context, isGuest: isGuest)
          : _buildLawyerCards(context),
    );
  }

  // ── User: เปิดเคส + นัดหมาย ───────────────────────────────────
  Widget _buildUserCards(BuildContext context, {bool isGuest = false}) {
    void go(Widget page) {
      if (isGuest) {
        Navigator.push(context,
            MaterialPageRoute(builder: (_) => LoginPage(isBack: true)));
      } else {
        Navigator.push(context, MaterialPageRoute(builder: (_) => page));
      }
    }

    return Row(children: [
      Expanded(
        child: _actionCard(
          title: 'openCase'.tr(),
          subtitle: 'openCaseSub'.tr(),
          iconAssets: 'assets/icons/open-case.png',
          gradientColors: [_kCard, _kCard],
          titleColor: const Color(0xFF1565C0),
          subTitleColor: const Color(0xFF1565C0),
          iconColor: const Color(0xFF1565C0),
          onTap: () => go(ConsultPage()),
        ),
      ),
      const SizedBox(width: 14),
      Expanded(
        child: _actionCard(
          title: 'bookConsult'.tr(),
          subtitle: 'bookConsultSub'.tr(),
          iconAssets: 'assets/icons/appointment-lawyer.png',
          gradientColors: [
            const Color(0xFF1565C0),
            const Color(0xFF1E88E5),
          ],
          onTap: () => go(TopicPage()),
        ),
      ),
    ]);
  }

  // ── Lawyer: สวิตช์รับเคสด่วน + ดูงาน + ตั้งเวลา ───────────────
  Widget _buildLawyerCards(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── สวิตช์รับเคสด่วน (มี flash animation) ──────────
              Expanded(
                child: _UrgentSwitchCard(
                  isUrgentCaseEnabled: isUrgentCaseEnabled,
                  onToggleUrgentCase: onToggleUrgentCase,
                ),
              ),
              const SizedBox(width: 12),
              // ── ดูงานเคสด่วน (มี bounce + glow animation) ───────
              Expanded(
                child: _UrgentJobCard(
                  isUrgentCaseEnabled: isUrgentCaseEnabled,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => LawyerJobListPage()),
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 14),

        // ── ตั้งค่าวันและเวลา ────────────────────────────────────
        _actionCard(
          title: 'ConsultationSchedule'.tr(),
          subtitle: 'subtitleConsultationSchedule'.tr(),
          icon: Icons.date_range_rounded,
          gradientColors: [_kCard, _kCard],
          titleColor: const Color(0xFF1565C0),
          subTitleColor: const Color(0xFF1565C0),
          iconColor: const Color(0xFF1565C0),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => ConsultationSchedule()),
          ),
        ),
      ],
    );
  }
}

// ─── Urgent Switch Card ───────────────────────────────────────────
// มีแสง flash เมื่อ toggle เปิด + border animate
class _UrgentSwitchCard extends StatefulWidget {
  final bool isUrgentCaseEnabled;
  final ValueChanged<bool> onToggleUrgentCase;

  const _UrgentSwitchCard({
    required this.isUrgentCaseEnabled,
    required this.onToggleUrgentCase,
  });

  @override
  State<_UrgentSwitchCard> createState() => _UrgentSwitchCardState();
}

class _UrgentSwitchCardState extends State<_UrgentSwitchCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _flashCtrl;
  late final Animation<double> _flashOpacity;

  @override
  void initState() {
    super.initState();
    _flashCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _flashOpacity = Tween<double>(begin: 0.35, end: 0.0).animate(
      CurvedAnimation(parent: _flashCtrl, curve: Curves.easeOut),
    );
  }

  @override
  void didUpdateWidget(_UrgentSwitchCard old) {
    super.didUpdateWidget(old);
    // flash เฉพาะตอนเปิด
    if (!old.isUrgentCaseEnabled && widget.isUrgentCaseEnabled) {
      _flashCtrl.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _flashCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.isUrgentCaseEnabled;
    const green = Color(0xFF059669);

    return AnimatedBuilder(
      animation: _flashCtrl,
      builder: (_, child) {
        return Stack(
          children: [
            child!,
            // ── flash overlay ──────────────────────────────────
            Positioned.fill(
              child: IgnorePointer(
                child: AnimatedOpacity(
                  opacity: 0,
                  duration: Duration.zero,
                  child: FadeTransition(
                    opacity: _flashOpacity,
                    child: Container(
                      decoration: BoxDecoration(
                        color: green.withOpacity(0.18),
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: enabled ? const Color(0xFFF0FDF7) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: enabled ? green : const Color.fromARGB(255, 209, 209, 209),
            width: enabled ? 2.0 : 1.5,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'urgentCaseSwitch'.tr(),
                    style: GoogleFonts.prompt(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: enabled
                          ? const Color(0xFF065F46)
                          : const Color(0xFF0D1B2A),
                    ),
                  ),
                ),
                SizedBox(
                  height: 30,
                  child: Switch(
                    value: enabled,
                    onChanged: widget.onToggleUrgentCase,
                    activeColor: green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: Text(
                enabled ? 'urgentCaseOn'.tr() : 'urgentCaseOff'.tr(),
                key: ValueKey(enabled),
                style: GoogleFonts.prompt(
                  fontSize: 12,
                  color: enabled ? green : Colors.grey.shade600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Urgent Job Card ──────────────────────────────────────────────
// bounce เข้า + glow เมื่อ urgentCase เปิด
class _UrgentJobCard extends StatefulWidget {
  final bool isUrgentCaseEnabled;
  final VoidCallback onTap;

  const _UrgentJobCard({
    required this.isUrgentCaseEnabled,
    required this.onTap,
  });

  @override
  State<_UrgentJobCard> createState() => _UrgentJobCardState();
}

class _UrgentJobCardState extends State<_UrgentJobCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _bounceCtrl;
  late final Animation<double> _bounceAnim;

  @override
  void initState() {
    super.initState();
    _bounceCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );

    // spring bounce: scale 0.7 → 1.08 → 0.96 → 1.0
    _bounceAnim = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 0.82)
            .chain(CurveTween(curve: Curves.easeIn)),
        weight: 15,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 0.82, end: 1.10)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 35,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.10, end: 0.96)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 25,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 0.96, end: 1.0)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 25,
      ),
    ]).animate(_bounceCtrl);
  }

  @override
  void didUpdateWidget(_UrgentJobCard old) {
    super.didUpdateWidget(old);
    if (!old.isUrgentCaseEnabled && widget.isUrgentCaseEnabled) {
      // delay เล็กน้อยให้ switch animation เล่นก่อน
      Future.delayed(const Duration(milliseconds: 120), () {
        if (mounted) _bounceCtrl.forward(from: 0);
      });
    }
  }

  @override
  void dispose() {
    _bounceCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.isUrgentCaseEnabled;

    return AnimatedBuilder(
      animation: _bounceAnim,
      builder: (_, child) => Transform.scale(
        scale: _bounceAnim.value,
        child: child,
      ),
      child: Opacity(
        opacity: enabled ? 1.0 : 0.4,
        child: MouseRegion(
          cursor: enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 350),
            curve: Curves.easeInOut,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1565C0), Color(0xFF2F80ED)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color:
                    const Color.fromARGB(255, 134, 134, 134).withOpacity(0.18),
                width: 1.5,
              ),
            ),
            child: Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(16),
              child: InkWell(
                onTap: enabled ? widget.onTap : null,
                borderRadius: BorderRadius.circular(16),
                splashColor: Colors.white.withOpacity(0.15),
                highlightColor: Colors.white.withOpacity(0.08),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.work_rounded,
                          color: Colors.white, size: 50),
                      const Spacer(),
                      const SizedBox(height: 8),
                      Text(
                        'viewUrgentJobs'.tr(),
                        style: GoogleFonts.prompt(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        'viewUrgentJobsSub'.tr(),
                        style: GoogleFonts.prompt(
                          fontSize: 11,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Pulsing Icon (กระพริบเมื่อ enabled) ─────────────────────────
class _PulsingIcon extends StatefulWidget {
  final bool enabled;
  const _PulsingIcon({required this.enabled});

  @override
  State<_PulsingIcon> createState() => _PulsingIconState();
}

class _PulsingIconState extends State<_PulsingIcon>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _scale = Tween<double>(begin: 1.0, end: 1.18).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
    if (widget.enabled) _ctrl.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(_PulsingIcon old) {
    super.didUpdateWidget(old);
    if (!old.enabled && widget.enabled) {
      _ctrl.repeat(reverse: true);
    } else if (old.enabled && !widget.enabled) {
      _ctrl.stop();
      _ctrl.reset();
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scale,
      child: const Icon(Icons.work_rounded, color: Colors.white, size: 50),
    );
  }
}

// ─── Action Card base widget ──────────────────────────────────────
Widget _actionCard({
  required String title,
  required String subtitle,
  IconData? icon,
  String iconAssets = '',
  Color? titleColor = Colors.white,
  Color? subTitleColor = Colors.white,
  Color? iconColor = Colors.white,
  required List<Color> gradientColors,
  required VoidCallback onTap,
}) {
  return MouseRegion(
    cursor: SystemMouseCursors.click,
    child: Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        splashColor: Colors.white.withOpacity(0.15),
        highlightColor: Colors.white.withOpacity(0.08),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: gradientColors,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: gradientColors.first == Colors.white
                  ? const Color(0xFFC0C0C0) // การ์ดขาว → border เทาเข้ม
                  : Colors.black.withOpacity(0.18), // การ์ดสี → border ดำโปร่ง
              width: 1,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 18),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: icon != null
                      ? Icon(icon, color: iconColor, size: 40)
                      : Image.asset(
                          iconAssets,
                          width: 18,
                          height: 18,
                          color: iconColor,
                        ),
                ),
                const SizedBox(width: 12),
                Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.prompt(
                          color: titleColor,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: GoogleFonts.prompt(
                          color: subTitleColor,
                          fontSize: 11,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
