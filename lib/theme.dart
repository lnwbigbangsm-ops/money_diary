import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// ธีมของแอป: พื้นเรียบ ไม่มีเงา โทนเขียวอมฟ้า ฟอนต์ Noto Sans Thai
ThemeData buildTheme(Brightness brightness) {
  final dark = brightness == Brightness.dark;
  Color tone(int light, int darkValue) => Color(dark ? darkValue : light);

  final scheme = ColorScheme.fromSeed(
    seedColor: const Color(0xFF006B56),
    brightness: brightness,
  ).copyWith(
    surface: tone(0xFFF5F8F7, 0xFF101715),
    surfaceContainerLowest: tone(0xFFFFFFFF, 0xFF0C1210),
    surfaceContainerLow: tone(0xFFFFFFFF, 0xFF19231F),
    surfaceContainer: tone(0xFFEBF1EE, 0xFF23312B),
    surfaceContainerHigh: tone(0xFFE2EAE6, 0xFF2B3B34),
    onSurface: tone(0xFF14221D, 0xFFE9F2ED),
    onSurfaceVariant: tone(0xFF4E6259, 0xFFB3C5BC),
    outlineVariant: tone(0xFFD7E2DC, 0xFF34483F),
    primary: tone(0xFF006B56, 0xFF79E0C0),
    onPrimary: tone(0xFFFFFFFF, 0xFF00382C),
    primaryContainer: tone(0xFFD8F5E9, 0xFF173C31),
    onPrimaryContainer: tone(0xFF123B30, 0xFFDDF9EE),
    tertiary: tone(0xFF08724B, 0xFF75DBAD),
    error: tone(0xFFA33343, 0xFFFF9BA9),
  );

  // เว็บ: โหลด Noto Sans Thai จาก Google Fonts
  // มือถือ: ใช้ฟอนต์ไทยของระบบ (Android มี Noto Sans Thai ในเครื่องอยู่แล้ว) ใช้ได้แม้ไม่มีเน็ต
  final fontFamily = kIsWeb ? GoogleFonts.notoSansThai().fontFamily : null;
  final base = ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    brightness: brightness,
    fontFamily: fontFamily,
  );
  final text = base.textTheme;
  final textTheme = text
      .copyWith(
        headlineSmall:
            text.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
        titleLarge: text.titleLarge
            ?.copyWith(fontSize: 22, fontWeight: FontWeight.w700),
        titleMedium: text.titleMedium
            ?.copyWith(fontSize: 16, fontWeight: FontWeight.w600),
        titleSmall: text.titleSmall
            ?.copyWith(fontSize: 15, fontWeight: FontWeight.w600),
        bodyMedium: text.bodyMedium?.copyWith(fontSize: 15),
        bodySmall: text.bodySmall
            ?.copyWith(fontSize: 13, color: scheme.onSurfaceVariant),
      )
      .apply(bodyColor: scheme.onSurface, displayColor: scheme.onSurface);

  return base.copyWith(
    textTheme: textTheme,
    scaffoldBackgroundColor: scheme.surface,
    dividerColor: scheme.outlineVariant,
    dividerTheme:
        DividerThemeData(color: scheme.outlineVariant, space: 1, thickness: 1),
    appBarTheme: AppBarTheme(
      backgroundColor: scheme.surface,
      foregroundColor: scheme.onSurface,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: textTheme.titleLarge,
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: scheme.surfaceContainerLow,
      indicatorColor: scheme.primaryContainer,
      elevation: 0,
      height: 72,
      labelTextStyle: WidgetStatePropertyAll(
        textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w500),
      ),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: scheme.primary,
      foregroundColor: scheme.onPrimary,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: scheme.surfaceContainerLow,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: scheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: scheme.surfaceContainer,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: ButtonStyle(
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
    ),
  );
}

/// สไตล์ตัวเลขเงิน (ตัวเลขกว้างเท่ากัน อ่านง่ายเวลาเรียงกัน)
TextStyle amountStyle(BuildContext context, double size, Color color,
    {FontWeight weight = FontWeight.w700}) {
  return Theme.of(context).textTheme.titleMedium!.copyWith(
    fontSize: size,
    fontWeight: weight,
    color: color,
    height: 1.2,
    fontFeatures: const [FontFeature.tabularFigures()],
  );
}

/// สีรายรับ/รายจ่ายที่ปรับตามโหมดสว่าง/มืด
extension MoneyColors on BuildContext {
  Color get incomeColor => Theme.of(this).colorScheme.tertiary;
  Color get expenseColor => Theme.of(this).colorScheme.error;
}
