import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'nothflows_colors.dart';
import 'nothflows_typography.dart';
import 'nothflows_shapes.dart';

/// Main theme configuration for NothFlows
class NothFlowsTheme {
  NothFlowsTheme._();

  /// Configure system UI for Nothing aesthetic
  static void configureSystemUI() {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
    );

    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  }

  /// Dark theme (default for Nothing aesthetic)
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: NothFlowsColors.nothingBlack,
      fontFamily: NothFlowsTypography.primaryFont,

      // Color scheme
      colorScheme: ColorScheme.dark(
        primary: NothFlowsColors.nothingRed,
        onPrimary: NothFlowsColors.nothingWhite,
        secondary: NothFlowsColors.textSecondary,
        onSecondary: NothFlowsColors.nothingBlack,
        surface: NothFlowsColors.surfaceDark,
        onSurface: NothFlowsColors.textPrimary,
        error: NothFlowsColors.error,
        onError: NothFlowsColors.nothingWhite,
      ),

      // Text theme
      textTheme: TextTheme(
        displayLarge: NothFlowsTypography.displayLarge.copyWith(
          color: NothFlowsColors.textPrimary,
        ),
        displayMedium: NothFlowsTypography.displayMedium.copyWith(
          color: NothFlowsColors.textPrimary,
        ),
        displaySmall: NothFlowsTypography.displaySmall.copyWith(
          color: NothFlowsColors.textPrimary,
        ),
        headlineLarge: NothFlowsTypography.headingLarge.copyWith(
          color: NothFlowsColors.textPrimary,
        ),
        headlineMedium: NothFlowsTypography.headingMedium.copyWith(
          color: NothFlowsColors.textPrimary,
        ),
        headlineSmall: NothFlowsTypography.headingSmall.copyWith(
          color: NothFlowsColors.textPrimary,
        ),
        bodyLarge: NothFlowsTypography.bodyLarge.copyWith(
          color: NothFlowsColors.textPrimary,
        ),
        bodyMedium: NothFlowsTypography.bodyMedium.copyWith(
          color: NothFlowsColors.textPrimary,
        ),
        bodySmall: NothFlowsTypography.bodySmall.copyWith(
          color: NothFlowsColors.textSecondary,
        ),
        labelLarge: NothFlowsTypography.labelLarge.copyWith(
          color: NothFlowsColors.textPrimary,
        ),
        labelMedium: NothFlowsTypography.labelMedium.copyWith(
          color: NothFlowsColors.textSecondary,
        ),
        labelSmall: NothFlowsTypography.labelSmall.copyWith(
          color: NothFlowsColors.textSecondary,
        ),
      ),

      // App bar theme
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontFamily: NothFlowsTypography.primaryFont,
          fontSize: 20,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.3,
          color: NothFlowsColors.textPrimary,
        ),
        iconTheme: IconThemeData(
          color: NothFlowsColors.textPrimary,
          size: 24,
        ),
      ),

      // Elevated button theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: NothFlowsColors.nothingRed,
          foregroundColor: NothFlowsColors.nothingWhite,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: NothFlowsShapes.borderRadiusMd,
          ),
          textStyle: NothFlowsTypography.buttonLarge,
        ),
      ),

      // Text button theme
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: NothFlowsColors.textSecondary,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: NothFlowsShapes.borderRadiusMd,
          ),
          textStyle: NothFlowsTypography.buttonMedium,
        ),
      ),

      // Outlined button theme
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: NothFlowsColors.textPrimary,
          side: const BorderSide(
            color: NothFlowsColors.borderDark,
            width: 1.5,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: NothFlowsShapes.borderRadiusMd,
          ),
          textStyle: NothFlowsTypography.buttonLarge,
        ),
      ),

      // Input decoration theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: NothFlowsColors.surfaceDark,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: NothFlowsShapes.borderRadiusMd,
          borderSide: const BorderSide(color: NothFlowsColors.borderDark),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: NothFlowsShapes.borderRadiusMd,
          borderSide: const BorderSide(color: NothFlowsColors.borderDark),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: NothFlowsShapes.borderRadiusMd,
          borderSide: const BorderSide(
            color: NothFlowsColors.nothingRed,
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: NothFlowsShapes.borderRadiusMd,
          borderSide: const BorderSide(color: NothFlowsColors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: NothFlowsShapes.borderRadiusMd,
          borderSide: const BorderSide(
            color: NothFlowsColors.error,
            width: 2,
          ),
        ),
        hintStyle: NothFlowsTypography.bodyLarge.copyWith(
          color: NothFlowsColors.textTertiary,
        ),
        labelStyle: NothFlowsTypography.bodyMedium.copyWith(
          color: NothFlowsColors.textSecondary,
        ),
      ),

      // Card theme
      cardTheme: CardThemeData(
        color: NothFlowsColors.surfaceDark,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: NothFlowsShapes.borderRadiusLg,
          side: const BorderSide(color: NothFlowsColors.borderDark),
        ),
        margin: EdgeInsets.zero,
      ),

      // Bottom sheet theme
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: NothFlowsColors.surfaceDarkAlt,
        modalBackgroundColor: NothFlowsColors.surfaceDarkAlt,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(NothFlowsShapes.radiusXxl),
          ),
        ),
      ),

      // Snackbar theme
      snackBarTheme: SnackBarThemeData(
        backgroundColor: NothFlowsColors.surfaceDarkAlt,
        contentTextStyle: NothFlowsTypography.bodyMedium.copyWith(
          color: NothFlowsColors.textPrimary,
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: NothFlowsShapes.borderRadiusMd,
          side: const BorderSide(color: NothFlowsColors.borderDark),
        ),
      ),

      // Divider theme
      dividerTheme: const DividerThemeData(
        color: NothFlowsColors.borderDark,
        thickness: 1,
        space: 1,
      ),

      // Icon theme
      iconTheme: const IconThemeData(
        color: NothFlowsColors.textPrimary,
        size: 24,
      ),

      // Floating action button theme
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: NothFlowsColors.nothingRed,
        foregroundColor: NothFlowsColors.nothingWhite,
        elevation: 0,
        focusElevation: 0,
        hoverElevation: 0,
        highlightElevation: 0,
      ),

      // Dialog theme
      dialogTheme: DialogThemeData(
        backgroundColor: NothFlowsColors.surfaceDarkAlt,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: NothFlowsShapes.borderRadiusXl,
        ),
        titleTextStyle: NothFlowsTypography.headingMedium.copyWith(
          color: NothFlowsColors.textPrimary,
        ),
        contentTextStyle: NothFlowsTypography.bodyMedium.copyWith(
          color: NothFlowsColors.textSecondary,
        ),
      ),

      // List tile theme
      listTileTheme: ListTileThemeData(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: NothFlowsShapes.borderRadiusMd,
        ),
        titleTextStyle: NothFlowsTypography.bodyLarge.copyWith(
          color: NothFlowsColors.textPrimary,
          fontWeight: FontWeight.w500,
        ),
        subtitleTextStyle: NothFlowsTypography.bodySmall.copyWith(
          color: NothFlowsColors.textSecondary,
        ),
      ),

      // Switch theme
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return NothFlowsColors.nothingBlack;
          }
          return NothFlowsColors.textSecondary;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return NothFlowsColors.nothingRed;
          }
          return NothFlowsColors.borderDark;
        }),
        trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
      ),

      // Progress indicator theme
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: NothFlowsColors.nothingRed,
        linearTrackColor: NothFlowsColors.borderDark,
        circularTrackColor: NothFlowsColors.borderDark,
      ),
    );
  }

  /// Light theme (optional)
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: NothFlowsColors.surfaceLight,
      fontFamily: NothFlowsTypography.primaryFont,

      colorScheme: ColorScheme.light(
        primary: NothFlowsColors.nothingRed,
        onPrimary: NothFlowsColors.nothingWhite,
        secondary: NothFlowsColors.textSecondaryLight,
        onSecondary: NothFlowsColors.nothingWhite,
        surface: NothFlowsColors.surfaceLightAlt,
        onSurface: NothFlowsColors.textPrimaryLight,
        error: NothFlowsColors.error,
        onError: NothFlowsColors.nothingWhite,
      ),

      // ... similar structure to darkTheme with light colors
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontFamily: NothFlowsTypography.primaryFont,
          fontSize: 20,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.3,
          color: NothFlowsColors.textPrimaryLight,
        ),
        iconTheme: IconThemeData(
          color: NothFlowsColors.textPrimaryLight,
          size: 24,
        ),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: NothFlowsColors.nothingRed,
          foregroundColor: NothFlowsColors.nothingWhite,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: NothFlowsShapes.borderRadiusMd,
          ),
          textStyle: NothFlowsTypography.buttonLarge,
        ),
      ),
    );
  }
}
