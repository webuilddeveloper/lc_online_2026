import 'package:flutter/material.dart';

// ══════════════════════════════════════════════════════════
//  lawyer_profile_widgets.dart
//  Shared widgets ระหว่าง LawyerProfileViewPage และ LawyerEditProfilePage
//
//  Contents:
//    ProfileAnimCard     – slide-up + fade-in entry card
//    ProfileSectionCard  – white card พร้อม icon + title header
//    ProfileTextField    – labeled text input พร้อม validation
//    SkillViewChip       – chip อ่านอย่างเดียว (view page)
//    SkillToggleChip     – chip กดเลือก/ยกเลิก (edit skills tab)
//    SkillSelectedChip   – chip ที่เลือกแล้ว + ปุ่ม X (edit skills tab)
//    AvailabilityBadge   – badge "ว่างอยู่" / "ไม่ว่าง"
// ══════════════════════════════════════════════════════════

const _kPrimary = Color(0xFF0262EC);

// ──────────────────────────────────────────────────────────
//  ProfileAnimCard
//  slide-up + fade-in ตาม delay (0.0–1.0)
//  มาจาก _AnimCard ใน lawyer_profile_view_page.dart
// ──────────────────────────────────────────────────────────

class ProfileAnimCard extends StatelessWidget {
  final double delay;
  final AnimationController ctrl;
  final Widget child;

  const ProfileAnimCard({
    super.key,
    required this.delay,
    required this.ctrl,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: ctrl,
      builder: (_, ch) {
        final t = Curves.easeOutCubic.transform(
          ((ctrl.value - delay) / (1 - delay)).clamp(0.0, 1.0),
        );
        return Opacity(
          opacity: t,
          child: Transform.translate(offset: Offset(0, 20 * (1 - t)), child: ch),
        );
      },
      child: child,
    );
  }
}

// ──────────────────────────────────────────────────────────
//  ProfileSectionCard
//  White card พร้อม icon badge + title + divider
//  มาจาก _sectionCard() ใน LawyerEditProfilePage
// ──────────────────────────────────────────────────────────

class ProfileSectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;

  const ProfileSectionCard({
    super.key,
    required this.title,
    required this.icon,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: _kPrimary.withOpacity(0.07),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: _kPrimary.withOpacity(0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 14, color: _kPrimary),
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1A2340),
              ),
            ),
          ]),
          const SizedBox(height: 4),
          const Divider(height: 20, color: Color(0xFFEEF2F5)),
          ...children,
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────
//  ProfileTextField
//  Labeled input พร้อม required marker และ validation
//  มาจาก _field() ใน LawyerEditProfilePage
//
//  onChanged: VoidCallback? — parent เรียก setState() เมื่อ text เปลี่ยน
//  (ใช้สำหรับ rebuild preview card ใน edit page)
// ──────────────────────────────────────────────────────────

class ProfileTextField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final String hint;
  final bool required;
  final TextInputType keyboardType;
  final int maxLines;
  final VoidCallback? onChanged;

  const ProfileTextField(
    this.label,
    this.controller, {
    super.key,
    this.hint = '',
    this.required = false,
    this.keyboardType = TextInputType.text,
    this.maxLines = 1,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            text: label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1A2340),
            ),
            children: required
                ? [
                    const TextSpan(
                      text: ' *',
                      style: TextStyle(color: Color(0xFFC62828)),
                    ),
                  ]
                : [],
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          onChanged: onChanged != null ? (_) => onChanged!() : null,
          style: const TextStyle(fontSize: 13, color: Color(0xFF1A2340)),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey[400], fontSize: 13),
            filled: true,
            fillColor: const Color(0xFFF8F9FB),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  const BorderSide(color: Color(0xFFE2E8F4), width: 1.5),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  const BorderSide(color: Color(0xFFE2E8F4), width: 1.5),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: _kPrimary, width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  const BorderSide(color: Color(0xFFC62828), width: 1.5),
            ),
          ),
          validator: required
              ? (v) =>
                  (v == null || v.trim().isEmpty) ? 'กรุณากรอก$label' : null
              : null,
        ),
      ],
    );
  }
}

// ──────────────────────────────────────────────────────────
//  SkillViewChip
//  Chip อ่านอย่างเดียว — ใช้ใน LawyerProfileViewPage
//  มาจาก inline Container ใน _buildSkillsCard()
// ──────────────────────────────────────────────────────────

class SkillViewChip extends StatelessWidget {
  final String skill;
  final Color color;

  const SkillViewChip({
    super.key,
    required this.skill,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withOpacity(0.1), color.withOpacity(0.05)],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Text(
        skill,
        style: TextStyle(
          fontSize: 12,
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────
//  SkillToggleChip
//  Chip กดเลือก/ยกเลิก — ใช้ใน _SkillsTabContent
//  มาจาก _skillChipToggle() ใน LawyerEditProfilePage
// ──────────────────────────────────────────────────────────

class SkillToggleChip extends StatelessWidget {
  final String skill;
  final bool selected;
  final VoidCallback onTap;

  const SkillToggleChip({
    super.key,
    required this.skill,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? _kPrimary.withOpacity(0.08)
              : const Color(0xFFEEF2F5),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color:
                selected ? _kPrimary.withOpacity(0.4) : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(
            Icons.gavel_outlined,
            size: 12,
            color: selected ? _kPrimary : Colors.grey[500],
          ),
          const SizedBox(width: 6),
          Text(
            skill,
            style: TextStyle(
              fontSize: 11,
              fontWeight:
                  selected ? FontWeight.w700 : FontWeight.w400,
              color:
                  selected ? _kPrimary : const Color(0xFF1A2340),
            ),
          ),
          if (selected) ...[
            const SizedBox(width: 4),
            const Icon(Icons.check_rounded, size: 11, color: _kPrimary),
          ],
        ]),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────
//  SkillSelectedChip
//  Chip ที่เลือกแล้ว + ปุ่ม X ลบ — ใช้ใน _SkillsTabContent preview
//  มาจาก _skillChipSelected() ใน LawyerEditProfilePage
// ──────────────────────────────────────────────────────────

class SkillSelectedChip extends StatelessWidget {
  final String skill;
  final VoidCallback onRemove;

  const SkillSelectedChip({
    super.key,
    required this.skill,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: _kPrimary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _kPrimary.withOpacity(0.3)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Text(
          skill,
          style: const TextStyle(
            fontSize: 11,
            color: _kPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(width: 4),
        GestureDetector(
          onTap: onRemove,
          child: const Icon(Icons.close_rounded, size: 13, color: _kPrimary),
        ),
      ]),
    );
  }
}

// ──────────────────────────────────────────────────────────
//  AvailabilityBadge
//  Badge "ว่างอยู่" / "ไม่ว่าง" — ใช้ทั้ง view และ edit page
//  มาจาก _badge() ใน LawyerEditProfilePage
// ──────────────────────────────────────────────────────────

class AvailabilityBadge extends StatelessWidget {
  final bool available;

  const AvailabilityBadge({super.key, required this.available});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: available
            ? const Color(0xFFE8F5E9)
            : const Color(0xFFFFEBEE),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        available ? 'ว่างอยู่' : 'ไม่ว่าง',
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: available
              ? const Color(0xFF2E7D32)
              : const Color(0xFFC62828),
        ),
      ),
    );
  }
}