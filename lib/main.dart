import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
// import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'viewmodels/task_viewmodel.dart';
import 'services/language_service.dart';
import 'services/notification_service.dart';
import 'services/sound_service.dart';
import 'services/audio_service.dart';
import 'views/home_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialiser les services
  await SoundService.initialize();
  
  runApp(const FocusMeApp());
}

class FocusMeApp extends StatelessWidget {
  const FocusMeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => TaskViewModel()),
        ChangeNotifierProvider(create: (context) => LanguageService()),
      ],
      child: Consumer<LanguageService>(
        builder: (context, languageService, child) {
          return MaterialApp(
            title: 'FocusMe',
            debugShowCheckedModeBanner: false,
            theme: _buildTheme(),
            home: const _AppInitializer(),
            // Configuration de l'internationalisation
            locale: languageService.currentLocale,
            supportedLocales: LanguageService.supportedLocales,
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
          );
        },
      ),
    );
  }

  ThemeData _buildTheme() {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF4ECDC4), // Teal/vert principal du logo
        brightness: Brightness.light,
      ).copyWith(
        // Couleurs personnalisées basées sur le logo
        primary: const Color(0xFF4ECDC4), // Teal/vert principal
        secondary: const Color(0xFFFF6B6B), // Rouge du logo
        tertiary: const Color(0xFFFFD93D), // Jaune du logo
        surface: const Color(0xFFF5E6D3), // Beige du fond du logo
        surfaceContainer: const Color(0xFFE8F5E8), // Vert très clair
        onSurface: const Color(0xFF2C3E50), // Texte foncé
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onTertiary: const Color(0xFF2C3E50),
      ),
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        elevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
          statusBarBrightness: Brightness.light,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
    );
  }
}

class _AppInitializer extends StatefulWidget {
  const _AppInitializer();

  @override
  State<_AppInitializer> createState() => _AppInitializerState();
}

class _AppInitializerState extends State<_AppInitializer> {
  @override
  void initState() {
    super.initState();
    // Initialiser la langue sauvegardée au démarrage
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<LanguageService>().loadSavedLanguage();
    });
  }

  @override
  Widget build(BuildContext context) {
    return const HomePage();
  }
}
