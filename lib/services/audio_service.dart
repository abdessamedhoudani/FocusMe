import 'dart:io';
import 'package:flutter/services.dart';
import 'package:audioplayers/audioplayers.dart';

class AudioService {
  static final AudioService _instance = AudioService._internal();
  factory AudioService() => _instance;
  AudioService._internal();

  final AudioPlayer _audioPlayer = AudioPlayer();

  // Jouer un son personnalisé
  Future<void> playCustomSound(String filePath) async {
    try {
      print('Lecture du son personnalisé: $filePath');
      
      // Vérifier si le fichier existe
      final file = File(filePath);
      if (!await file.exists()) {
        print('Fichier audio non trouvé: $filePath');
        return;
      }

      // Jouer le fichier audio
      await _audioPlayer.play(DeviceFileSource(filePath));
      print('Son personnalisé joué avec succès');
    } catch (e) {
      print('Erreur lors de la lecture du son personnalisé: $e');
      // En cas d'erreur, jouer un son système par défaut
      await SystemSound.play(SystemSoundType.click);
    }
  }

  // Jouer un son par défaut
  Future<void> playDefaultSound() async {
    try {
      print('Lecture du son par défaut');
      await SystemSound.play(SystemSoundType.click);
    } catch (e) {
      print('Erreur lors de la lecture du son par défaut: $e');
    }
  }

  // Arrêter la lecture
  Future<void> stopSound() async {
    try {
      await _audioPlayer.stop();
    } catch (e) {
      print('Erreur lors de l\'arrêt du son: $e');
    }
  }

  // Libérer les ressources
  Future<void> dispose() async {
    try {
      await _audioPlayer.dispose();
    } catch (e) {
      print('Erreur lors de la libération des ressources audio: $e');
    }
  }
}
