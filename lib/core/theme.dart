import 'package:flutter/material.dart';

const kPrimaryPurple = Color(0xFF7B2FBE);
const kViolet = Color(0xFF6366F1);
const kPink = Color(0xFFE040FB);
const kPurpleLight = Color(0xFFB97AE8);
const kPurpleDark = Color(0xFF4A1875);
const kBgDark = Color(0xFF0A0A14);
const kSurfaceDark = Color(0xFF0F0F1E);
const kSurface = Color(0xFF1A1A35);
const kTextMuted = Color(0xFF7E6F9A);
const kBodyText = Color(0xFFC4B5D4);
const kCyan = Color(0xFF22D3EE);
const kDanger = Color(0xFFEF4444);

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
  brightness: Brightness.dark,
  scaffoldBackgroundColor: kBgDark,
  colorScheme: const ColorScheme.dark(
    primary: kPrimaryPurple,
    secondary: kViolet,
    tertiary: kPink,
    surface: kSurface,
  ),
  fontFamily: 'Nunito',
  splashFactory: NoSplash.splashFactory,
  appBarTheme: const AppBarTheme(
    backgroundColor: Colors.transparent,
    elevation: 0,
    centerTitle: false,
    foregroundColor: Colors.white,
  ),
  textTheme: TextTheme(
    headlineLarge: ShayaTextStyles.display.copyWith(fontSize: 32),
    headlineMedium: ShayaTextStyles.title.copyWith(fontSize: 22),
    headlineSmall: ShayaTextStyles.title.copyWith(fontSize: 18),
    bodyLarge: ShayaTextStyles.body.copyWith(fontSize: 16),
    bodyMedium: ShayaTextStyles.body.copyWith(fontSize: 14),
    bodySmall: ShayaTextStyles.metadata.copyWith(fontSize: 12),
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: Colors.white.withValues(alpha: 0.04),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide(color: kPrimaryPurple.withValues(alpha: 0.25)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: kPurpleLight),
    ),
    hintStyle: ShayaTextStyles.body.copyWith(color: kTextMuted),
  ),
);

class ShayaTextStyles {
  const ShayaTextStyles._();

  static const display = TextStyle(
    fontFamily: 'Nunito',
    color: Colors.white,
    fontSize: 28,
    fontVariations: [FontVariation('wght', 900)],
  );

  static const title = TextStyle(
    fontFamily: 'Nunito',
    color: Colors.white,
    fontSize: 20,
    fontVariations: [FontVariation('wght', 800)],
  );

  static const songName = TextStyle(
    fontFamily: 'Nunito',
    color: Colors.white,
    fontSize: 16,
    fontVariations: [FontVariation('wght', 900)],
  );

  static const body = TextStyle(
    fontFamily: 'Inter',
    color: kBodyText,
    fontSize: 14,
    fontVariations: [FontVariation('wght', 400)],
  );

  static const metadata = TextStyle(
    fontFamily: 'Inter',
    color: kTextMuted,
    fontSize: 12,
    fontVariations: [FontVariation('wght', 400)],
  );

  static const tag = TextStyle(
    fontFamily: 'Nunito',
    color: kPurpleLight,
    fontSize: 11,
    fontVariations: [FontVariation('wght', 700)],
  );

  static const routeCode = TextStyle(
    fontFamily: 'Courier New',
    color: Color(0xFF818CF8),
    fontSize: 12,
  );
}
