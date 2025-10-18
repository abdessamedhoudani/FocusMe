# FocusMe 📱

**FocusMe** est une application mobile Flutter complète pour la gestion quotidienne des tâches avec notifications automatiques et statistiques de productivité.

## 🎯 Fonctionnalités

### ✨ Gestion des tâches (CRUD)
- **Créer** : Ajouter de nouvelles tâches avec titre, description, date et heure
- **Lire** : Consulter toutes les tâches organisées par onglets (Aujourd'hui, En retard, Toutes)
- **Modifier** : Éditer les tâches existantes
- **Supprimer** : Supprimer les tâches individuellement ou en lot

### 🔔 Notifications intelligentes
- Notifications automatiques à l'heure programmée
- Gestion des permissions Android/iOS
- Notifications cliquables pour ouvrir directement la tâche

### 📊 Statistiques et graphiques
- Graphiques de progression avec `fl_chart`
- Statistiques quotidiennes, hebdomadaires et mensuelles
- Taux de réussite et analyse de productivité
- Filtres par période personnalisables

### 🎨 Interface moderne
- Design Material 3 avec palette de couleurs douces
- Animations fluides avec `flutter_animate`
- Interface responsive et intuitive
- Thème cohérent dans toute l'application

## 🏗️ Architecture

L'application suit une architecture MVVM propre et modulaire :

```
lib/
├── main.dart                 # Point d'entrée de l'application
├── models/
│   └── task.dart            # Modèle de données Task
├── services/
│   ├── db_service.dart      # Service de base de données SQLite
│   ├── notification_service.dart # Service de notifications locales
│   └── sample_data_service.dart  # Données d'exemple pour les tests
├── viewmodels/
│   └── task_viewmodel.dart  # Logique métier et gestion d'état
├── views/
│   ├── home_page.dart       # Page principale avec navigation
│   ├── add_task_page.dart   # Création/modification de tâches
│   ├── stats_page.dart      # Page des statistiques
│   └── settings_page.dart   # Paramètres de l'application
└── widgets/
    ├── task_tile.dart       # Widget pour afficher une tâche
    └── statistics_card.dart # Widgets pour les statistiques
```

## 🛠️ Technologies utilisées

- **Flutter** : Framework de développement mobile
- **Provider** : Gestion d'état
- **SQLite** : Base de données locale avec `sqflite`
- **Notifications** : `flutter_local_notifications` pour les rappels
- **Graphiques** : `fl_chart` pour les statistiques visuelles
- **Animations** : `flutter_animate` pour les transitions fluides
- **Dates** : `intl` pour la gestion des dates et heures

## 🚀 Installation et utilisation

### Prérequis
- Flutter SDK (version 3.9.2 ou supérieure)
- Android Studio / Xcode pour le développement
- Un émulateur ou appareil physique

### Installation
1. Clonez le repository :
```bash
git clone <repository-url>
cd focusme
```

2. Installez les dépendances :
```bash
flutter pub get
```

3. Lancez l'application :
```bash
flutter run
```

### Première utilisation
- L'application se lance avec des tâches d'exemple pour tester les fonctionnalités
- Vous pouvez immédiatement commencer à créer, modifier et gérer vos tâches
- Les notifications sont automatiquement programmées pour les tâches futures

## 📱 Fonctionnalités détaillées

### Gestion des tâches
- **Titre et description** : Informations détaillées pour chaque tâche
- **Date et heure** : Planification précise avec sélecteurs intégrés
- **Statuts** : En attente, Terminée, En retard
- **Filtrage** : Par date, statut, et période

### Notifications
- **Programmation automatique** : Notifications programmées à l'heure exacte
- **Gestion des permissions** : Demande automatique des permissions
- **Notifications cliquables** : Ouverture directe de la tâche concernée
- **Nettoyage automatique** : Suppression des notifications obsolètes

### Statistiques
- **Vue d'ensemble** : Nombre total de tâches créées, terminées, en retard
- **Taux de réussite** : Pourcentage de completion
- **Graphiques** : Camembert pour la répartition, courbe pour l'évolution
- **Périodes** : Filtrage par 7 jours, 30 jours, 3 mois, 6 mois ou période personnalisée

### Paramètres
- **Gestion des données** : Réinitialisation, suppression, nettoyage
- **Notifications** : Activation/désactivation des rappels
- **Données d'exemple** : Rechargement des tâches de test
- **À propos** : Informations sur l'application et aide

## 🎨 Design et UX

### Palette de couleurs
- **Couleur principale** : Bleu doux (#4A90E2)
- **Couleurs secondaires** : Dérivées automatiquement par Material 3
- **Thème** : Clair avec support pour les modes sombres futurs

### Animations
- **Transitions** : Fade-in, slide, scale pour tous les éléments
- **Interactions** : Feedback visuel sur les actions utilisateur
- **Chargement** : Indicateurs de progression élégants

### Responsive
- **Adaptation** : Interface qui s'adapte à différentes tailles d'écran
- **Navigation** : Bottom navigation avec 3 onglets principaux
- **Accessibilité** : Support des lecteurs d'écran et navigation au clavier

## 🔧 Développement

### Structure du code
- **Séparation des responsabilités** : Chaque classe a un rôle bien défini
- **Gestion d'état** : Provider pour une gestion réactive et performante
- **Services** : Logique métier isolée dans des services dédiés
- **Widgets réutilisables** : Composants modulaires et réutilisables

### Base de données
- **SQLite** : Stockage local performant et fiable
- **Migrations** : Support pour les futures mises à jour de schéma
- **Indexation** : Requêtes optimisées avec des index appropriés

### Tests
- **Données d'exemple** : Tâches pré-configurées pour tester l'interface
- **Gestion d'erreurs** : Messages d'erreur clairs et informatifs
- **Validation** : Vérification des données utilisateur

## 🚀 Déploiement

### Android
```bash
flutter build apk --release
```

### iOS
```bash
flutter build ios --release
```

## 📈 Améliorations futures

- [ ] Mode sombre
- [ ] Synchronisation cloud
- [ ] Catégories de tâches
- [ ] Rappels récurrents
- [ ] Widgets d'accueil
- [ ] Export/Import des données
- [ ] Collaboration en équipe
- [ ] Intégration calendrier

## 🤝 Contribution

Les contributions sont les bienvenues ! N'hésitez pas à :
- Signaler des bugs
- Proposer de nouvelles fonctionnalités
- Soumettre des pull requests
- Améliorer la documentation

## 📄 Licence

Ce projet est sous licence MIT. Voir le fichier LICENSE pour plus de détails.

---

**FocusMe** - Restez organisé, restez productif ! 🎯✨
