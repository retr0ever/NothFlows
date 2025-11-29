import 'package:flutter/material.dart';
import '../theme/nothflows_colors.dart';
import '../theme/nothflows_typography.dart';
import '../theme/nothflows_shapes.dart';

/// Custom text field widget following Nothing design language
class NothTextField extends StatelessWidget {
  final TextEditingController? controller;
  final String? hintText;
  final String? labelText;
  final String? errorText;
  final bool obscureText;
  final bool enabled;
  final bool autofocus;
  final int? minLines;
  final int? maxLines;
  final int? maxLength;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final Widget? suffixIcon;
  final Widget? prefixIcon;
  final FocusNode? focusNode;
  final Color? focusColor;
  final String? semanticLabel;
  final String? semanticHint;

  const NothTextField({
    super.key,
    this.controller,
    this.hintText,
    this.labelText,
    this.errorText,
    this.obscureText = false,
    this.enabled = true,
    this.autofocus = false,
    this.minLines,
    this.maxLines,
    this.maxLength,
    this.keyboardType,
    this.textInputAction,
    this.onChanged,
    this.onSubmitted,
    this.suffixIcon,
    this.prefixIcon,
    this.focusNode,
    this.focusColor,
    this.semanticLabel,
    this.semanticHint,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final effectiveFocusColor = focusColor ?? NothFlowsColors.nothingRed;

    Widget textField = TextField(
      controller: controller,
      obscureText: obscureText,
      enabled: enabled,
      autofocus: autofocus,
      minLines: minLines,
      maxLines: maxLines ?? (minLines != null ? null : 1),
      maxLength: maxLength,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      focusNode: focusNode,
      style: NothFlowsTypography.bodyLarge.copyWith(
        color: isDark
            ? NothFlowsColors.textPrimary
            : NothFlowsColors.textPrimaryLight,
        height: 1.5,
      ),
      cursorColor: effectiveFocusColor,
      decoration: InputDecoration(
        hintText: hintText,
        labelText: labelText,
        errorText: errorText,
        hintStyle: NothFlowsTypography.bodyLarge.copyWith(
          color: isDark
              ? NothFlowsColors.textTertiary
              : NothFlowsColors.textTertiaryLight,
        ),
        labelStyle: NothFlowsTypography.bodyMedium.copyWith(
          color: isDark
              ? NothFlowsColors.textSecondary
              : NothFlowsColors.textSecondaryLight,
        ),
        errorStyle: NothFlowsTypography.caption.copyWith(
          color: NothFlowsColors.error,
        ),
        filled: true,
        fillColor: isDark
            ? NothFlowsColors.surfaceDark
            : NothFlowsColors.surfaceLightAlt,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: NothFlowsShapes.borderRadiusMd,
          borderSide: BorderSide(
            color: isDark
                ? NothFlowsColors.borderDark
                : NothFlowsColors.borderLight,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: NothFlowsShapes.borderRadiusMd,
          borderSide: BorderSide(
            color: isDark
                ? NothFlowsColors.borderDark
                : NothFlowsColors.borderLight,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: NothFlowsShapes.borderRadiusMd,
          borderSide: BorderSide(
            color: effectiveFocusColor,
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: NothFlowsShapes.borderRadiusMd,
          borderSide: const BorderSide(
            color: NothFlowsColors.error,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: NothFlowsShapes.borderRadiusMd,
          borderSide: const BorderSide(
            color: NothFlowsColors.error,
            width: 2,
          ),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: NothFlowsShapes.borderRadiusMd,
          borderSide: BorderSide(
            color: (isDark
                    ? NothFlowsColors.borderDark
                    : NothFlowsColors.borderLight)
                .withOpacity(0.5),
          ),
        ),
        suffixIcon: suffixIcon,
        prefixIcon: prefixIcon,
        counterText: '',
      ),
    );

    // Wrap with Semantics if accessibility labels provided
    if (semanticLabel != null || semanticHint != null) {
      textField = Semantics(
        label: semanticLabel,
        hint: semanticHint,
        textField: true,
        child: textField,
      );
    }

    return textField;
  }
}
