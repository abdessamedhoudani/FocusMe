import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageService extends ChangeNotifier {
  static const String _languageKey = 'selected_language';
  
  Locale _currentLocale = const Locale('fr'); // Français par défaut
  
  Locale get currentLocale => _currentLocale;
  
  // Langues supportées
  static const List<Locale> supportedLocales = [
    Locale('fr', ''), // Français
    Locale('en', ''), // Anglais
    Locale('ar', ''), // Arabe
  ];
  
  // Noms des langues
  static const Map<String, String> languageNames = {
    'fr': 'Français',
    'en': 'English',
    'ar': 'العربية',
  };
  
  // Charger la langue sauvegardée
  Future<void> loadSavedLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    final savedLanguage = prefs.getString(_languageKey);
    
    if (savedLanguage != null) {
      _currentLocale = Locale(savedLanguage);
    }
    notifyListeners();
  }
  
  // Changer la langue
  Future<void> changeLanguage(Locale locale) async {
    if (supportedLocales.contains(locale)) {
      _currentLocale = locale;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_languageKey, locale.languageCode);
      notifyListeners();
    }
  }
  
  // Obtenir le nom de la langue actuelle
  String get currentLanguageName {
    return languageNames[_currentLocale.languageCode] ?? 'Français';
  }
  
  // Vérifier si la langue actuelle est RTL (Right-to-Left)
  bool get isRTL {
    return _currentLocale.languageCode == 'ar';
  }
}
