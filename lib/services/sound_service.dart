import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'translation_service.dart';

class SoundService {
  static final SoundService _instance = SoundService._internal();
  factory SoundService() => _instance;
  SoundService._internal();

  // IDs des sons système Android disponibles
  static const List<String> systemSoundIds = [
    'default',
    'notification',
    'alarm',
    'ringtone',
    'media_button_click',
    'keyboard_click',
    'camera_click',
    'voice_assistant_start',
    'voice_assistant_end',
    'game_complete',
    'game_pause',
    'game_resume',
    'notification_sound',
  ];

  // Plus besoin de stockage local - on utilise seulement les sons système Android

  // Obtenir le nom traduit d'une sonnerie
  static String getSoundName(BuildContext context, String soundId) {
    switch (soundId) {
      case 'default':
        return 'Son par défaut';
      case 'notification':
        return 'Notification';
      case 'alarm':
        return 'Alarme';
      case 'ringtone':
        return 'Sonnerie';
      case 'media_button_click':
        return 'Clic média';
      case 'keyboard_click':
        return 'Clic clavier';
      case 'camera_click':
        return 'Clic appareil photo';
      case 'voice_assistant_start':
        return 'Assistant vocal (début)';
      case 'voice_assistant_end':
        return 'Assistant vocal (fin)';
      case 'game_complete':
        return 'Jeu terminé';
      case 'game_pause':
        return 'Jeu en pause';
      case 'game_resume':
        return 'Jeu reprend';
      case 'notification_sound':
        return 'Son de notification';
      default:
        return 'Son inconnu';
    }
  }

  // Obtenir la liste des sonneries disponibles (seulement les sons système)
  static List<String> getAvailableSoundIds() {
    return [...systemSoundIds];
  }

  // Obtenir la liste des sons système Android
  static List<String> getSystemSoundIds() {
    return systemSoundIds;
  }

  // Les sons personnalisés ne sont plus supportés - utilisation des sons système uniquement

  // Obtenir l'URI de la sonnerie (pour les notifications) - maintenant seulement les sons système
  static String? getSoundUri(String soundId) {
    // Tous les sons sont maintenant des sons système Android
    if (systemSoundIds.contains(soundId)) {
      return soundId; // Retourner directement l'ID du son système
    }
    return 'notification'; // Fallback vers le son système par défaut
  }

  // Jouer un aperçu de la sonnerie (pour les tests)
  static Future<void> playSoundPreview(String soundId) async {
    try {
      // Pour l'instant, on utilise juste un bip système
      // Dans une vraie app, on pourrait jouer un aperçu de la sonnerie
      await SystemSound.play(SystemSoundType.click);
    } catch (e) {
      print('Erreur lors de la lecture de l\'aperçu: $e');
    }
  }

  // Initialiser le service (plus besoin de charger des sons personnalisés)
  static Future<void> initialize() async {
    // Les sons système ne nécessitent pas d'initialisation
    print('SoundService initialisé avec ${systemSoundIds.length} sons système Android');
  }

  // Vérifier si un son est système (maintenant tous les sons sont système)
  static bool isSystemSound(String soundId) {
    return systemSoundIds.contains(soundId);
  }
}
