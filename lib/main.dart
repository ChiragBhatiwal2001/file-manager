import 'package:file_manager/Screens/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    const Color seedColor = Color(0xFF223344); // Midnight Blue Base

    final lightColorScheme = ColorScheme.fromSeed(
      seedColor: seedColor,
      brightness: Brightness.light,
    );

    final darkColorScheme = ColorScheme.fromSeed(
      seedColor: seedColor,
      brightness: Brightness.dark,
    );

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.system,
      theme: _buildCustomTheme(lightColorScheme, Brightness.light),
      darkTheme: _buildCustomTheme(darkColorScheme, Brightness.dark),
      home: const HomeScreen(),
    );
  }

  ThemeData _buildCustomTheme(ColorScheme scheme, Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: isDark
          ? scheme.background
          : scheme.surfaceVariant.withOpacity(0.97),
      fontFamily: 'Poppins',
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        elevation: 1,
        titleTextStyle: TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 20,
          color: scheme.onSurface,
        ),
      ),
      cardTheme: CardThemeData().copyWith(
        elevation: 4,
        color: scheme.secondaryContainer.withOpacity(isDark ? 0.8 : 1.0),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 6,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: scheme.surface.withOpacity(0.95),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        modalElevation: 8,
      ),
      iconTheme: IconThemeData(color: scheme.primary),
      textTheme: TextTheme(
        bodyLarge: TextStyle(fontSize: 16, color: scheme.onSurface),
        bodyMedium: TextStyle(fontSize: 14, color: scheme.onSurfaceVariant),
        titleLarge: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: scheme.primary,
        ),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: scheme.surface,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: TextStyle(fontFamily: 'Poppins', color: scheme.onSurface),
      ),
    );
  }
}
