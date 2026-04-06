import 'package:flutter/material.dart';

const kPrimaryPurple = Color(0xFF7B2FBE);
const kViolet = Color(0xFF6366F1);
const kPink = Color(0xFFE040FB);
const kPurpleLight = Color(0xFFB97AE8);
const kPurpleDark = Color(0xFF4A1875);
const kBgDark = Color(0xFF0A0A14);
const kSurfaceDark = Color(0xFF0F0F1E);
const kSurface = Color(0xFF1A1A35);
const kSurfaceElevated = Color(0xFF17172C);
const kSurfaceMuted = Color(0xFF141426);
const kStrokeSoft = Color(0x14FFFFFF);
const kStrokeStrong = Color(0x52B97AE8);
const kTextMuted = Color(0xFF7E6F9A);
const kBodyText = Color(0xFFC4B5D4);
const kCyan = Color(0xFF22D3EE);
const kDanger = Color(0xFFEF4444);
const kSuccess = Color(0xFF22C55E);
const kWarning = Color(0xFFF59E0B);
const kShadowDark = Color(0xFF04040B);
const kOverlayDark = Color(0xE6121024);

const kGradPrimary = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [kPrimaryPurple, kViolet],
);

const kGradAccent = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [kPrimaryPurple, kPink],
);

const kGradCyan = LinearGradient(
  begin: Alignment.topCenter,
  end: Alignment.bottomCenter,
  colors: [kPurpleLight, kCyan],
);

const kGradHero = LinearGradient(
  begin: Alignment.topCenter,
  end: Alignment.bottomCenter,
  colors: [Color(0xFF220A3E), kBgDark],
);

const kGradCard = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [Color(0xFF220A3E), Color(0xFF0D1B3E)],
);

const kScreenGradient = LinearGradient(
  begin: Alignment.topCenter,
  end: Alignment.bottomCenter,
  colors: [Color(0xFF0F0A20), kBgDark],
);

final shayaTheme = ThemeData(
  useMaterial3: true,
  brightness: Brightness.dark,
  scaffoldBackgroundColor: kBgDark,
  colorScheme: const ColorScheme.dark(
    primary: kPrimaryPurple,
    secondary: kViolet,
    tertiary: kPink,
    surface: kSurfaceDark,
    error: kDanger,
  ),
  fontFamily: 'Nunito',
  splashFactory: NoSplash.splashFactory,
  dividerColor: Colors.white.withValues(alpha: 0.08),
  canvasColor: kSurfaceDark,
  splashColor: Colors.white.withValues(alpha: 0.05),
  highlightColor: Colors.white.withValues(alpha: 0.03),
  pageTransitionsTheme: const PageTransitionsTheme(
    builders: {
      TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
      TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
      TargetPlatform.linux: FadeUpwardsPageTransitionsBuilder(),
      TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
      TargetPlatform.windows: FadeUpwardsPageTransitionsBuilder(),
    },
  ),
  appBarTheme: AppBarTheme(
    backgroundColor: Colors.transparent,
    elevation: 0,
    scrolledUnderElevation: 0,
    centerTitle: false,
    foregroundColor: Colors.white,
    surfaceTintColor: Colors.transparent,
    titleTextStyle: ShayaTextStyles.title,
    iconTheme: const IconThemeData(color: Colors.white),
  ),
  textTheme: TextTheme(
    headlineLarge: ShayaTextStyles.display.copyWith(fontSize: 34),
    headlineMedium: ShayaTextStyles.title.copyWith(fontSize: 24),
    headlineSmall: ShayaTextStyles.title.copyWith(fontSize: 18),
    bodyLarge: ShayaTextStyles.body.copyWith(fontSize: 16),
    bodyMedium: ShayaTextStyles.body.copyWith(fontSize: 14),
    bodySmall: ShayaTextStyles.metadata.copyWith(fontSize: 12),
    titleMedium: ShayaTextStyles.songName,
    labelLarge: ShayaTextStyles.button,
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: Colors.white.withValues(alpha: 0.05),
    contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
    prefixIconColor: kPurpleLight,
    suffixIconColor: Colors.white70,
    labelStyle: ShayaTextStyles.metadata.copyWith(color: kBodyText),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(18),
      borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(18),
      borderSide: const BorderSide(color: kPurpleLight, width: 1.4),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(18),
      borderSide: const BorderSide(color: kDanger),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(18),
      borderSide: const BorderSide(color: kDanger, width: 1.4),
    ),
    hintStyle: ShayaTextStyles.body.copyWith(color: kTextMuted),
  ),
  snackBarTheme: SnackBarThemeData(
    behavior: SnackBarBehavior.floating,
    backgroundColor: kOverlayDark,
    contentTextStyle: ShayaTextStyles.body.copyWith(color: Colors.white),
    elevation: 0,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
  ),
  dialogTheme: DialogThemeData(
    backgroundColor: kSurfaceDark,
    surfaceTintColor: Colors.transparent,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
    titleTextStyle: ShayaTextStyles.title,
    contentTextStyle: ShayaTextStyles.body,
  ),
  bottomSheetTheme: const BottomSheetThemeData(
    backgroundColor: kSurfaceDark,
    modalBackgroundColor: kSurfaceDark,
    surfaceTintColor: Colors.transparent,
    showDragHandle: true,
    dragHandleColor: Colors.white38,
  ),
  popupMenuTheme: PopupMenuThemeData(
    color: kSurfaceDark,
    surfaceTintColor: Colors.transparent,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
    textStyle: ShayaTextStyles.body.copyWith(color: Colors.white),
  ),
  textButtonTheme: TextButtonThemeData(
    style: TextButton.styleFrom(
      foregroundColor: Colors.white,
      textStyle: ShayaTextStyles.body.copyWith(
        color: Colors.white,
        fontVariations: const [FontVariation('wght', 600)],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ),
  ),
  outlinedButtonTheme: OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      foregroundColor: Colors.white,
      side: BorderSide(color: Colors.white.withValues(alpha: 0.10)),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      textStyle: ShayaTextStyles.body.copyWith(
        color: Colors.white,
        fontVariations: const [FontVariation('wght', 600)],
      ),
    ),
  ),
  filledButtonTheme: FilledButtonThemeData(
    style: FilledButton.styleFrom(
      backgroundColor: kPrimaryPurple,
      foregroundColor: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      textStyle: ShayaTextStyles.button,
    ),
  ),
  segmentedButtonTheme: SegmentedButtonThemeData(
    style: ButtonStyle(
      backgroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return kPrimaryPurple.withValues(alpha: 0.18);
        }
        return Colors.white.withValues(alpha: 0.04);
      }),
      foregroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return Colors.white;
        }
        return kBodyText;
      }),
      side: WidgetStateProperty.resolveWith(
        (states) => BorderSide(
          color: states.contains(WidgetState.selected)
              ? kStrokeStrong
              : Colors.white.withValues(alpha: 0.08),
        ),
      ),
      shape: WidgetStatePropertyAll(
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
      padding: const WidgetStatePropertyAll(
        EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      textStyle: WidgetStatePropertyAll(ShayaTextStyles.body),
    ),
  ),
  switchTheme: SwitchThemeData(
    thumbColor: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.selected)) {
        return Colors.white;
      }
      return kBodyText;
    }),
    trackColor: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.selected)) {
        return kPrimaryPurple.withValues(alpha: 0.65);
      }
      return Colors.white.withValues(alpha: 0.12);
    }),
  ),
  sliderTheme: SliderThemeData(
    activeTrackColor: kPurpleLight,
    inactiveTrackColor: Colors.white.withValues(alpha: 0.10),
    thumbColor: Colors.white,
    overlayColor: kPurpleLight.withValues(alpha: 0.12),
    trackHeight: 4,
  ),
  checkboxTheme: CheckboxThemeData(
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
    side: BorderSide(color: Colors.white.withValues(alpha: 0.16)),
    fillColor: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.selected)) {
        return kPrimaryPurple;
      }
      return Colors.transparent;
    }),
  ),
  progressIndicatorTheme: const ProgressIndicatorThemeData(color: kPurpleLight),
  listTileTheme: ListTileThemeData(
    iconColor: Colors.white70,
    textColor: Colors.white,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
  ),
);

class ShayaTextStyles {
  const ShayaTextStyles._();

  static const display = TextStyle(
    fontFamily: 'Nunito',
    color: Colors.white,
    fontSize: 30,
    height: 1.05,
    letterSpacing: -0.5,
    fontVariations: [FontVariation('wght', 900)],
  );

  static const title = TextStyle(
    fontFamily: 'Nunito',
    color: Colors.white,
    fontSize: 20,
    height: 1.1,
    letterSpacing: -0.2,
    fontVariations: [FontVariation('wght', 800)],
  );

  static const songName = TextStyle(
    fontFamily: 'Nunito',
    color: Colors.white,
    fontSize: 16,
    height: 1.1,
    fontVariations: [FontVariation('wght', 900)],
  );

  static const body = TextStyle(
    fontFamily: 'Inter',
    color: kBodyText,
    fontSize: 15,
    height: 1.45,
    fontVariations: [FontVariation('wght', 400)],
  );

  static const metadata = TextStyle(
    fontFamily: 'Inter',
    color: kTextMuted,
    fontSize: 12,
    height: 1.4,
    fontVariations: [FontVariation('wght', 400)],
  );

  static const tag = TextStyle(
    fontFamily: 'Nunito',
    color: kPurpleLight,
    fontSize: 12,
    height: 1.0,
    fontVariations: [FontVariation('wght', 700)],
  );

  static const button = TextStyle(
    fontFamily: 'Nunito',
    color: Colors.white,
    fontSize: 15,
    letterSpacing: 0.1,
    fontVariations: [FontVariation('wght', 800)],
  );

  static const routeCode = TextStyle(
    fontFamily: 'Courier New',
    color: Color(0xFF818CF8),
    fontSize: 12,
  );
}
