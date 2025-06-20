import 'package:file_manager/Providers/theme_notifier.dart';
import 'package:file_manager/Screens/home_screen.dart';
import 'package:file_manager/Services/shared_preference.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  await SharedPrefsService.instance.init();
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeNotifierProvider);
    const Color seedColor = Color(0xFF223344); // Midnight Blue Base

    final lightColorScheme = ColorScheme.fromSeed(
      seedColor: seedColor,
      brightness: Brightness.light,
    );

    final darkColorScheme = ColorScheme.fromSeed(
      seedColor: seedColor,
      brightness: Brightness.dark,
    );
    final RouteObserver<PageRoute> routeObserver = RouteObserver<PageRoute>();

    return MaterialApp(
      navigatorObservers: [routeObserver],
      debugShowCheckedModeBanner: false,
      themeMode: themeMode,
      theme: _buildCustomTheme(lightColorScheme, Brightness.light),
      darkTheme: _buildCustomTheme(darkColorScheme, Brightness.dark),
      home: const HomeScreen(),
    );
  }

  ThemeData _buildCustomTheme(ColorScheme scheme, Brightness brightness) {
    final base = ThemeData(brightness: brightness, useMaterial3: true);
    final isDark = brightness == Brightness.dark;

    return base.copyWith(
      colorScheme: scheme,
      scaffoldBackgroundColor: scheme.background,
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        elevation: 1,
        titleTextStyle: TextStyle(
          fontFamily: 'Poppins',
          fontWeight: FontWeight.w600,
          fontSize: 20,
          color: scheme.onSurface,
        ),
      ),
      cardTheme: CardThemeData().copyWith(
        elevation: 3,
        color: scheme.secondaryContainer,
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 6,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: scheme.surface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        modalElevation: 8,
      ),
      iconTheme: IconThemeData(color: scheme.primary),
      textTheme: base.textTheme.copyWith(
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
        textStyle: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 14,
          color: scheme.onSurface,
        ),
      ),
    );
  }
}
