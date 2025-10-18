# Changelog

Toutes les modifications notables de ce projet seront documentées dans ce fichier.

Le format est basé sur [Keep a Changelog](https://keepachangelog.com/fr/1.0.0/),
et ce projet adhère au [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2024-01-01

### Ajouté
- Application Flutter complète pour la gestion des tâches quotidiennes
- Gestion complète des tâches (CRUD) avec modèle Task
- Notifications locales automatiques avec flutter_local_notifications
- Statistiques et graphiques avec fl_chart
- Réinitialisation quotidienne automatique des tâches
- Design Material 3 avec palette de couleurs douces
- Animations fluides avec flutter_animate
- Architecture MVVM avec Provider
- Stockage local avec Hive
- Support Android et iOS
- Tâches d'exemple pour la démonstration
- Gestion des permissions pour les notifications
- Interface utilisateur intuitive et responsive
- Page de statistiques avec graphiques de progression
- Page d'ajout/modification de tâches
- Widget personnalisé TaskTile avec animations
- Service de réinitialisation quotidienne
- Configuration complète pour Android et iOS
- Documentation complète (README, guides de démarrage)
- Tests unitaires de base
- Configuration d'analyse de code
- Fichiers de configuration pour le build

### Fonctionnalités principales
- ✅ Création, modification, suppression de tâches
- ✅ Notifications automatiques à l'heure programmée
- ✅ Statistiques visuelles avec graphiques
- ✅ Réinitialisation quotidienne des tâches
- ✅ Design moderne Material 3
- ✅ Animations et transitions fluides
- ✅ Gestion des permissions
- ✅ Support multi-plateforme (Android/iOS)

### Technologies utilisées
- Flutter 3.0+
- Dart 3.0+
- Provider pour la gestion d'état
- Hive pour le stockage local
- flutter_local_notifications pour les alertes
- fl_chart pour les graphiques
- flutter_animate pour les animations
- Material 3 pour le design
- intl pour l'internationalisation

### Structure du projet
```
lib/
├── main.dart                 # Point d'entrée
├── models/task.dart         # Modèle de données
├── services/                # Services (DB, notifications, reset)
├── viewmodels/task_viewmodel.dart # Logique métier
├── views/                   # Pages (home, add_task, stats, settings)
└── widgets/task_tile.dart   # Widget personnalisé
```

### Configuration
- Android : API 21+ (Android 5.0+)
- iOS : 11.0+
- Permissions configurées pour les notifications
- Assets et icônes configurés
- Build configuration complète

---

## [Unreleased]

### À venir
- Synchronisation cloud
- Catégories de tâches
- Rappels récurrents
- Mode sombre
- Widgets d'accueil
- Export des données
- Collaboration en équipe
- Thèmes personnalisables
- Notifications push
- Intégration calendrier
