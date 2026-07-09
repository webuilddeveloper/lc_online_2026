import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppDropdownOption<T> {
  const AppDropdownOption({
    required this.value,
    required this.label,
    this.leading,
    this.enabled = true,
  });

  final T value;
  final String label;
  final Widget? leading;
  final bool enabled;
}

class AppDropdownStyles {
  AppDropdownStyles._();

  static const Color primary = Color(0xFF0262EC);
  static const Color titleColor = Color(0xFF1A2340);
  static const Color hintColor = Color(0xFF8E95A2);
  static const Color borderColor = Color(0xFFECEDF0);
  static const Color fillColor = Colors.white;
  static const Color menuColor = Colors.white;
  static const double radius = 14;

  static TextStyle labelStyle({Color? color}) => GoogleFonts.prompt(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: color ?? titleColor,
      );

  static TextStyle itemStyle({
    Color? color,
    FontWeight fontWeight = FontWeight.w500,
  }) =>
      GoogleFonts.prompt(
        fontSize: 13,
        fontWeight: fontWeight,
        color: color ?? titleColor,
      );

  static TextStyle hintTextStyle() => GoogleFonts.prompt(
        fontSize: 13,
        fontWeight: FontWeight.w400,
        color: hintColor,
      );

  static InputDecoration fieldDecoration({
    String? hint,
    IconData? prefixIcon,
    Color accentColor = primary,
    bool enabled = true,
    String? errorText,
    EdgeInsetsGeometry contentPadding =
        const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    double borderRadius = radius,
  }) {
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(borderRadius),
      borderSide: const BorderSide(color: borderColor, width: 1.5),
    );

    return InputDecoration(
      hintText: hint,
      hintStyle: hintTextStyle(),
      errorText: errorText,
      prefixIcon: prefixIcon != null
          ? Icon(prefixIcon, color: accentColor, size: 20)
          : null,
      filled: true,
      fillColor: enabled ? fillColor : const Color(0xFFF5F7FA),
      contentPadding: contentPadding,
      border: border,
      enabledBorder: border,
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(borderRadius),
        borderSide: BorderSide(color: accentColor, width: 1.5),
      ),
      disabledBorder: border,
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(borderRadius),
        borderSide: const BorderSide(color: Color(0xFFD32F2F), width: 1.5),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(borderRadius),
        borderSide: const BorderSide(color: Color(0xFFD32F2F), width: 1.5),
      ),
    );
  }

  static List<BoxShadow> elevatedShadow() => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.04),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ];

  static List<DropdownMenuItem<T>> buildItems<T>(
    List<AppDropdownOption<T>> options, {
    Color accentColor = primary,
    T? selectedValue,
  }) {
    return options
        .map(
          (option) => DropdownMenuItem<T>(
            value: option.value,
            enabled: option.enabled,
            child: _DropdownRow(
              label: option.label,
              leading: option.leading,
              selected: selectedValue == option.value,
              accentColor: accentColor,
            ),
          ),
        )
        .toList();
  }

  static List<DropdownMenuItem<String>> mapItems(
    List<dynamic> list, {
    Color accentColor = primary,
    String? selectedValue,
  }) {
    return list
        .where((e) => (e['code']?.toString() ?? '').isNotEmpty)
        .map(
          (e) => DropdownMenuItem<String>(
            value: e['code']?.toString() ?? '',
            child: Text(
              e['title']?.toString() ?? '',
              style: itemStyle(
                color: selectedValue == e['code']?.toString()
                    ? accentColor
                    : titleColor,
                fontWeight: selectedValue == e['code']?.toString()
                    ? FontWeight.w600
                    : FontWeight.w500,
              ),
            ),
          ),
        )
        .toList();
  }

  static String? safeMapValue(String? value, List<dynamic> list) {
    if (value == null || value.isEmpty) return null;
    return list.any((e) => e['code']?.toString() == value) ? value : null;
  }

  static List<DropdownMenuItem<String>> provinceTitleItems(
    List<dynamic> provinces,
    String selectedProvince, {
    Color accentColor = primary,
  }) {
    return provinces.map((p) {
      final title = p['title']?.toString() ?? '';
      final isSelected = selectedProvince == title;
      final isAll = title == 'ทั้งหมด';
      return DropdownMenuItem<String>(
        value: title,
        child: Row(
          children: [
            Icon(
              isAll ? Icons.public_rounded : Icons.location_city_outlined,
              size: 15,
              color: isSelected ? accentColor : hintColor,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                title,
                style: itemStyle(
                  color: isSelected ? accentColor : titleColor,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ),
            if (isSelected)
              Icon(Icons.check_rounded, size: 15, color: accentColor),
          ],
        ),
      );
    }).toList();
  }

  static DropdownButtonBuilder provinceTitleSelectedBuilder(
    List<dynamic> provinces,
    String selectedProvince, {
    Color accentColor = primary,
  }) {
    final active = selectedProvince != 'ทั้งหมด';
    return (_) => provinces.map((p) {
      final title = p['title']?.toString() ?? '';
      final isAll = title == 'ทั้งหมด';
      return Row(
        children: [
          Icon(
            isAll ? Icons.public_rounded : Icons.location_city_outlined,
            size: 15,
            color: active ? accentColor : hintColor,
          ),
          const SizedBox(width: 8),
          Text(
            title,
            style: itemStyle(
              color: active ? accentColor : const Color(0xFF64748B),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      );
    }).toList();
  }
}

class _DropdownRow extends StatelessWidget {
  const _DropdownRow({
    required this.label,
    this.leading,
    this.selected = false,
    this.accentColor = AppDropdownStyles.primary,
  });

  final String label;
  final Widget? leading;
  final bool selected;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (leading != null) ...[
          leading!,
          const SizedBox(width: 8),
        ],
        Expanded(
          child: Text(
            label,
            style: AppDropdownStyles.itemStyle(
              color: selected ? accentColor : AppDropdownStyles.titleColor,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class AppDropdownField<T> extends StatelessWidget {
  const AppDropdownField({
    super.key,
    required this.value,
    required this.items,
    this.onChanged,
    this.hint,
    this.prefixIcon,
    this.accentColor,
    this.enabled = true,
    this.isExpanded = true,
    this.validator,
    this.errorText,
    this.contentPadding,
    this.borderRadius = AppDropdownStyles.radius,
    this.elevated = false,
    this.menuMaxHeight,
  });

  factory AppDropdownField.fromOptions({
    Key? key,
    required T? value,
    required List<AppDropdownOption<T>> options,
    required ValueChanged<T?>? onChanged,
    String? hint,
    IconData? prefixIcon,
    Color accentColor = AppDropdownStyles.primary,
    bool enabled = true,
    bool isExpanded = true,
    FormFieldValidator<T>? validator,
    String? errorText,
    bool elevated = false,
    double? menuMaxHeight,
  }) {
    return AppDropdownField<T>(
      key: key,
      value: value,
      items: AppDropdownStyles.buildItems(
        options,
        accentColor: accentColor,
        selectedValue: value,
      ),
      onChanged: onChanged,
      hint: hint,
      prefixIcon: prefixIcon,
      accentColor: accentColor,
      enabled: enabled,
      isExpanded: isExpanded,
      validator: validator,
      errorText: errorText,
      elevated: elevated,
      menuMaxHeight: menuMaxHeight,
    );
  }

  static AppDropdownField<String> fromMaps({
    Key? key,
    required String? value,
    required List<dynamic> list,
    required ValueChanged<String?>? onChanged,
    String? hint,
    IconData? prefixIcon,
    Color accentColor = AppDropdownStyles.primary,
    bool enabled = true,
    bool isExpanded = true,
    FormFieldValidator<String>? validator,
    String? errorText,
    bool elevated = false,
  }) {
    final safeValue = AppDropdownStyles.safeMapValue(value, list);
    return AppDropdownField<String>(
      key: key,
      value: safeValue,
      items: AppDropdownStyles.mapItems(
        list,
        accentColor: accentColor,
        selectedValue: safeValue,
      ),
      onChanged: onChanged,
      hint: hint,
      prefixIcon: prefixIcon,
      accentColor: accentColor,
      enabled: enabled,
      isExpanded: isExpanded,
      validator: validator,
      errorText: errorText,
      elevated: elevated,
    );
  }

  final T? value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?>? onChanged;
  final String? hint;
  final IconData? prefixIcon;
  final Color? accentColor;
  final bool enabled;
  final bool isExpanded;
  final FormFieldValidator<T>? validator;
  final String? errorText;
  final EdgeInsetsGeometry? contentPadding;
  final double borderRadius;
  final bool elevated;
  final double? menuMaxHeight;

  @override
  Widget build(BuildContext context) {
    final color = accentColor ?? AppDropdownStyles.primary;

    final field = DropdownButtonFormField<T>(
      value: value,
      items: items,
      onChanged: enabled ? onChanged : null,
      isExpanded: isExpanded,
      validator: validator,
      menuMaxHeight: menuMaxHeight,
      icon: Icon(Icons.keyboard_arrow_down_rounded, color: color, size: 22),
      dropdownColor: AppDropdownStyles.menuColor,
      borderRadius: BorderRadius.circular(borderRadius),
      style: AppDropdownStyles.itemStyle(),
      decoration: AppDropdownStyles.fieldDecoration(
        hint: hint,
        prefixIcon: prefixIcon,
        accentColor: color,
        enabled: enabled,
        errorText: errorText,
        contentPadding: contentPadding ??
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        borderRadius: borderRadius,
      ),
    );

    if (!elevated) return field;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: AppDropdownStyles.elevatedShadow(),
      ),
      child: field,
    );
  }
}

class AppDropdownLabeledField<T> extends StatelessWidget {
  const AppDropdownLabeledField({
    super.key,
    required this.label,
    required this.value,
    required this.items,
    this.onChanged,
    this.hint,
    this.prefixIcon,
    this.isRequired = false,
    this.labelColor,
    this.accentColor,
    this.enabled = true,
    this.validator,
    this.errorText,
    this.elevated = false,
    this.spacing = 8,
  });

  static AppDropdownLabeledField<String> fromMaps({
    Key? key,
    required String label,
    required String? value,
    required List<dynamic> list,
    required ValueChanged<String?>? onChanged,
    String? hint,
    IconData? prefixIcon,
    bool isRequired = false,
    Color? labelColor,
    Color accentColor = AppDropdownStyles.primary,
    bool enabled = true,
    FormFieldValidator<String>? validator,
    String? errorText,
    bool elevated = false,
    double spacing = 8,
  }) {
    final safeValue = AppDropdownStyles.safeMapValue(value, list);
    return AppDropdownLabeledField<String>(
      key: key,
      label: label,
      value: safeValue,
      items: AppDropdownStyles.mapItems(
        list,
        accentColor: accentColor,
        selectedValue: safeValue,
      ),
      onChanged: onChanged,
      hint: hint,
      prefixIcon: prefixIcon,
      isRequired: isRequired,
      labelColor: labelColor,
      accentColor: accentColor,
      enabled: enabled,
      validator: validator,
      errorText: errorText,
      elevated: elevated,
      spacing: spacing,
    );
  }

  final String label;
  final T? value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?>? onChanged;
  final String? hint;
  final IconData? prefixIcon;
  final bool isRequired;
  final Color? labelColor;
  final Color? accentColor;
  final bool enabled;
  final FormFieldValidator<T>? validator;
  final String? errorText;
  final bool elevated;
  final double spacing;

  @override
  Widget build(BuildContext context) {
    final color = accentColor ?? AppDropdownStyles.primary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            text: label,
            style: GoogleFonts.prompt(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: labelColor ?? color,
            ),
            children: [
              if (isRequired)
                const TextSpan(
                  text: ' *',
                  style: TextStyle(color: Colors.red),
                ),
            ],
          ),
        ),
        SizedBox(height: spacing),
        AppDropdownField<T>(
          value: value,
          items: items,
          onChanged: onChanged,
          hint: hint,
          prefixIcon: prefixIcon,
          accentColor: color,
          enabled: enabled,
          validator: validator,
          errorText: errorText,
          elevated: elevated,
        ),
      ],
    );
  }
}

class AppDropdownFilter<T> extends StatelessWidget {
  const AppDropdownFilter({
    super.key,
    required this.value,
    required this.items,
    this.onChanged,
    this.isExpanded = true,
    this.isDense = false,
    this.active = false,
    this.accentColor,
    this.selectedItemBuilder,
    this.padding = const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
    this.borderRadius = 14,
    this.menuMaxHeight,
  });

  final T? value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?>? onChanged;
  final bool isExpanded;
  final bool isDense;
  final bool active;
  final Color? accentColor;
  final DropdownButtonBuilder? selectedItemBuilder;
  final EdgeInsetsGeometry padding;
  final double borderRadius;
  final double? menuMaxHeight;

  @override
  Widget build(BuildContext context) {
    final color = accentColor ?? AppDropdownStyles.primary;

    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: active ? color.withValues(alpha: 0.08) : const Color(0xFFF8F9FB),
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: active ? color.withValues(alpha: 0.4) : const Color(0xFFE2E8F4),
          width: 1.5,
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          items: items,
          onChanged: onChanged,
          isExpanded: isExpanded,
          isDense: isDense,
          menuMaxHeight: menuMaxHeight,
          selectedItemBuilder: selectedItemBuilder,
          icon: Icon(
            Icons.keyboard_arrow_down_rounded,
            color: active ? color : AppDropdownStyles.hintColor,
            size: isDense ? 18 : 20,
          ),
          dropdownColor: AppDropdownStyles.menuColor,
          borderRadius: BorderRadius.circular(borderRadius),
          style: AppDropdownStyles.itemStyle(
            color: active ? color : AppDropdownStyles.titleColor,
            fontWeight: active ? FontWeight.w600 : FontWeight.w500,
          ),
          itemHeight: isDense ? 44 : null,
        ),
      ),
    );
  }
}

class AppDropdownCompact<T> extends StatelessWidget {
  const AppDropdownCompact({
    super.key,
    required this.value,
    required this.items,
    this.onChanged,
    this.accentColor,
    this.isDense = true,
    this.padding = const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
    this.borderRadius = 12,
  });

  final T? value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?>? onChanged;
  final Color? accentColor;
  final bool isDense;
  final EdgeInsetsGeometry padding;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    final color = accentColor ?? AppDropdownStyles.primary;

    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: const Color(0xFFDDE3EE)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          items: items,
          onChanged: onChanged,
          isDense: isDense,
          icon: Icon(Icons.keyboard_arrow_down_rounded, color: color, size: 18),
          dropdownColor: AppDropdownStyles.menuColor,
          borderRadius: BorderRadius.circular(borderRadius),
          style: AppDropdownStyles.itemStyle(
            color: color,
            fontWeight: FontWeight.w600,
          ),
          itemHeight: 44,
        ),
      ),
    );
  }
}
