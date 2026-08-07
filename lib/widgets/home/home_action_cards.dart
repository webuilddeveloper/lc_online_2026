import 'package:LawyerOnline/booking/topic-page.dart';
import 'package:LawyerOnline/consultation-schedule.dart';
import 'package:LawyerOnline/consult/consult.dart';
import 'package:LawyerOnline/lawyer-job-list.dart';
import 'package:LawyerOnline/widgets/home/home_theme.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:LawyerOnline/login.dart';
import 'package:easy_localization/easy_localization.dart';

const _kCard = HomeTheme.card;
const _kAccent = HomeTheme.primary;

// ─── Action Cards ─────────────────────────────────────────────────
class HomeActionCards extends StatelessWidget {
  final String typeLogin;
  final String userType;
  final bool isUrgentCaseEnabled;
  final bool isPro;
  final String urgentCaseScope;
  final ValueChanged<bool> onToggleUrgentCase;
  final ValueChanged<String> onUrgentCaseScopeChanged;
  final bool isGuest;

  const HomeActionCards({
    super.key,
    required this.typeLogin,
    required this.userType,
    required this.isUrgentCaseEnabled,
    this.isPro = false,
    this.urgentCaseScope = 'expertise',
    required this.onToggleUrgentCase,
    required this.onUrgentCaseScopeChanged,
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

    return Column(
      children: [
        SizedBox(
          height: 136,
          child: Row(
            children: [
              Expanded(
                child: _userPrimaryAction(
                  title: 'openCase'.tr(),
                  subtitle: 'openCaseSub'.tr(),
                  iconAssets: 'assets/icons/open-case.png',
                  gradient: const [Color(0xFFDC2626), Color(0xFFF97316)],
                  glowColor: const Color(0xFFEF4444),
                  onTap: () => go(ConsultPage()),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _userPrimaryAction(
                  title: 'bookConsult'.tr(),
                  subtitle: 'bookConsultSub'.tr(),
                  iconAssets: 'assets/icons/appointment-lawyer.png',
                  gradient: const [Color(0xFF1D4ED8), Color(0xFF06B6D4)],
                  glowColor: HomeTheme.primary,
                  onTap: () => go(TopicPage()),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
      ],
    );
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

        if (isPro && isUrgentCaseEnabled) ...[
          const SizedBox(height: 12),
          _UrgentCaseScopeSelector(
            scope: urgentCaseScope,
            onChanged: onUrgentCaseScopeChanged,
          ),
        ],

        const SizedBox(height: 14),

        // ── ตั้งค่าวันและเวลา ────────────────────────────────────
        _actionCard(
          title: 'ConsultationSchedule'.tr(),
          subtitle: 'subtitleConsultationSchedule'.tr(),
          icon: Icons.calendar_month_rounded,
          accent: HomeTheme.primary,
          accentSoft: HomeTheme.primary.withValues(alpha: 0.08),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => ConsultationSchedule()),
          ),
        ),
      ],
    );
  }
}

class _UrgentCaseScopeSelector extends StatelessWidget {
  final String scope;
  final ValueChanged<String> onChanged;

  const _UrgentCaseScopeSelector({
    required this.scope,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFF),
        borderRadius: HomeTheme.brCardMd,
        border: Border.all(color: const Color(0xFFD6E4FF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'urgentCaseScopeTitle'.tr(),
            style: GoogleFonts.prompt(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF1E3A8A),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _scopeChip(
                  label: 'urgentCaseScopeExpertise'.tr(),
                  selected: scope != 'all',
                  onTap: () => onChanged('expertise'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _scopeChip(
                  label: 'urgentCaseScopeAll'.tr(),
                  selected: scope == 'all',
                  onTap: () => onChanged('all'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _scopeChip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF0262EC) : Colors.white,
          borderRadius: BorderRadius.circular(HomeTheme.radiusChip),
          border: Border.all(
            color: selected ? const Color(0xFF0262EC) : const Color(0xFFD6E4FF),
          ),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: GoogleFonts.prompt(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : const Color(0xFF334155),
          ),
        ),
      ),
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
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: enabled ? const Color(0xFFF0FDF7) : Colors.white,
          borderRadius: HomeTheme.brCardMd,
          border: Border.all(
            color: enabled ? green : HomeTheme.line,
            width: enabled ? 2.0 : 1,
          ),
          boxShadow: enabled ? HomeTheme.softShadow(tint: green, y: 6) : null,
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
              duration: const Duration(milliseconds: 450),
              child: Text(
                enabled ? 'urgentCaseOn'.tr() : 'urgentCaseOff'.tr(),
                // key: ValueKey(enabled),
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
              borderRadius: HomeTheme.brCardMd,
              border: Border.all(
                color: enabled
                    ? Colors.white.withValues(alpha: 0.25)
                    : HomeTheme.line,
                width: 1,
              ),
              boxShadow: enabled
                  ? HomeTheme.glowShadow(const Color(0xFF1565C0))
                  : null,
            ),
            child: Material(
              color: Colors.transparent,
              borderRadius: HomeTheme.brCardMd,
              child: InkWell(
                onTap: enabled ? widget.onTap : null,
                borderRadius: HomeTheme.brCardMd,
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

// ─── ปุ่มหลักฝั่งผู้ใช้ (เท่ากัน + เด่น) ─────────────────────────
Widget _userPrimaryAction({
  required String title,
  required String subtitle,
  required String iconAssets,
  required List<Color> gradient,
  required Color glowColor,
  required VoidCallback onTap,
}) {
  // เน้น "มุมโค้งเข้าโค้งกรอบ" + ลดความเข้มของสีพื้นหลัง
  const radius = 24.0;
  final gradientColors =
      gradient.map((c) => c.withValues(alpha: 0.90)).toList(growable: false);
  final glow = glowColor.withValues(alpha: 0.18);

  return Material(
    color: Colors.transparent,
    borderRadius: const BorderRadius.all(Radius.circular(radius)),
    child: InkWell(
      onTap: onTap,
      borderRadius: const BorderRadius.all(Radius.circular(radius)),
      splashColor: Colors.white.withValues(alpha: 0.2),
      highlightColor: Colors.white.withValues(alpha: 0.1),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: gradientColors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: const BorderRadius.all(Radius.circular(radius)),
          boxShadow: [
            BoxShadow(
              color: glow,
              blurRadius: 4,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(HomeTheme.radiusCardSm),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.35),
                    width: 1.2,
                  ),
                ),
                child: Center(
                  child: Image.asset(
                    iconAssets,
                    width: 26,
                    height: 26,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                title,
                textAlign: TextAlign.center,
                style: GoogleFonts.prompt(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  height: 1.15,
                  letterSpacing: -0.2,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: GoogleFonts.prompt(
                  color: Colors.white.withValues(alpha: 0.88),
                  fontSize: 11,
                  height: 1.25,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

// ─── Action Card — ฝั่งทนาย / ตั้งเวลา ───────────────────────────
Widget _actionCard({
  required String title,
  required String subtitle,
  IconData? icon,
  String iconAssets = '',
  Color accent = HomeTheme.primary,
  Color? accentSoft,
  bool isHero = false,
  required VoidCallback onTap,
}) {
  final soft = accentSoft ?? accent.withValues(alpha: 0.1);
  final titleColor = isHero ? Colors.white : HomeTheme.ink;
  final subColor =
      isHero ? Colors.white.withValues(alpha: 0.85) : HomeTheme.slate;
  final iconColor = isHero ? Colors.white : accent;

  return Material(
    color: Colors.transparent,
    borderRadius: HomeTheme.brCardLg,
    child: InkWell(
      onTap: onTap,
      borderRadius: HomeTheme.brCardLg,
      child: Ink(
        decoration: isHero
            ? BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1D4ED8), Color(0xFF06B6D4)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: HomeTheme.brCardLg,
                boxShadow: HomeTheme.glowShadow(HomeTheme.primary),
              )
            : HomeTheme.cardDecoration(
                radius: HomeTheme.radiusCardLg,
                color: HomeTheme.card,
                borderColor: accent.withValues(alpha: 0.15),
                shadowTint: accent,
              ),
        child: Stack(
          children: [
            if (!isHero)
              Positioned(
                left: 0,
                top: 14,
                bottom: 14,
                child: Container(
                  width: 4,
                  decoration: BoxDecoration(
                    color: accent,
                    borderRadius: const BorderRadius.horizontal(
                      right: Radius.circular(HomeTheme.radiusChip),
                    ),
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 14, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color:
                          isHero ? Colors.white.withValues(alpha: 0.2) : soft,
                      borderRadius: HomeTheme.brCardSm,
                      border: isHero
                          ? Border.all(
                              color: Colors.white.withValues(alpha: 0.25))
                          : null,
                    ),
                    child: Center(
                      child: icon != null
                          ? Icon(icon, color: iconColor, size: 22)
                          : Image.asset(
                              iconAssets,
                              width: 22,
                              height: 22,
                              color: iconColor,
                            ),
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.prompt(
                          color: titleColor,
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          height: 1.2,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        subtitle,
                        style: GoogleFonts.prompt(
                          color: subColor,
                          fontSize: 11,
                          height: 1.3,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
