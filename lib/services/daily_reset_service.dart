import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'db_service.dart';
import 'notification_service.dart';

class DailyResetService {
  static const String _lastResetKey = 'last_reset_date';
  
  // Vérifier et effectuer la réinitialisation quotidienne
  static Future<void> checkAndPerformDailyReset() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastResetDateString = prefs.getString(_lastResetKey);
      
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      
      DateTime? lastResetDate;
      if (lastResetDateString != null) {
        lastResetDate = DateTime.parse(lastResetDateString);
        lastResetDate = DateTime(lastResetDate.year, lastResetDate.month, lastResetDate.day);
      }
      
      // Vérifier si c'est un nouveau jour
      if (lastResetDate == null || lastResetDate.isBefore(today)) {
        await _performDailyReset();
        await prefs.setString(_lastResetKey, today.toIso8601String());
        
        // Programmer la notification de réinitialisation pour demain
        await NotificationService.scheduleDailyResetNotification();
      }
    } catch (e) {
      debugPrint('Erreur lors de la réinitialisation quotidienne: $e');
    }
  }
  
  // Effectuer la réinitialisation des tâches
  static Future<void> _performDailyReset() async {
    try {
      // Réinitialiser les tâches d'aujourd'hui
      await DatabaseService.resetDailyTasks();
      
      // Programmer les notifications pour les nouvelles tâches
      final todayTasks = DatabaseService.getTodayTasks();
      await NotificationService.scheduleTodayNotifications(todayTasks);
      
      debugPrint('Réinitialisation quotidienne effectuée avec succès');
    } catch (e) {
      debugPrint('Erreur lors de la réinitialisation: $e');
    }
  }
  
  // Forcer la réinitialisation (pour les tests)
  static Future<void> forceReset() async {
    try {
      await _performDailyReset();
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_lastResetKey, DateTime.now().toIso8601String());
    } catch (e) {
      debugPrint('Erreur lors de la réinitialisation forcée: $e');
    }
  }
  
  // Obtenir la date de dernière réinitialisation
  static Future<DateTime?> getLastResetDate() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastResetDateString = prefs.getString(_lastResetKey);
      
      if (lastResetDateString != null) {
        return DateTime.parse(lastResetDateString);
      }
      return null;
    } catch (e) {
      debugPrint('Erreur lors de la récupération de la date de réinitialisation: $e');
      return null;
    }
  }
  
  // Vérifier si la réinitialisation est nécessaire
  static Future<bool> isResetNeeded() async {
    try {
      final lastResetDate = await getLastResetDate();
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      
      if (lastResetDate == null) {
        return true;
      }
      
      final lastReset = DateTime(
        lastResetDate.year,
        lastResetDate.month,
        lastResetDate.day,
      );
      
      return lastReset.isBefore(today);
    } catch (e) {
      debugPrint('Erreur lors de la vérification de réinitialisation: $e');
      return false;
    }
  }
}
