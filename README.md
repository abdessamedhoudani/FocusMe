# FocusMe 📱

Une application Flutter moderne pour la gestion quotidienne des tâches avec notifications et statistiques de productivité.

## 🎯 Fonctionnalités

### ✨ Gestion des tâches (CRUD)
- **Créer** : Ajouter de nouvelles tâches avec titre, description, date et heure
- **Lire** : Consulter la liste des tâches organisées par statut
- **Modifier** : Éditer les tâches existantes
- **Supprimer** : Supprimer les tâches avec confirmation

### 🔔 Notifications intelligentes
- Notifications automatiques à l'heure programmée
- Gestion des permissions Android/iOS
- Possibilité d'activer/désactiver les notifications par tâche
- Notifications de réinitialisation quotidienne

### 📊 Statistiques et graphiques
- Graphiques de progression avec `fl_chart`
- Taux de completion en temps réel
- Historique des performances
- Filtres par période (semaine, mois, année)

### 🔄 Réinitialisation quotidienne
- Réinitialisation automatique des tâches chaque jour
- Conservation de l'historique pour les statistiques
- Notifications de nouveau jour

### 🎨 Design moderne
- Material 3 avec palette de couleurs douces
- Animations fluides avec `flutter_animate`
- Interface intuitive et responsive
- Thème cohérent sur toute l'application

## 🏗️ Architecture

L'application suit une architecture MVVM propre et modulaire :

```
lib/
├── main.dart                 # Point d'entrée de l'application
├── models/
│   └── task.dart            # Modèle de données Task
├── services/
│   ├── db_service.dart      # Service de base de données (Hive)
│   ├── notification_service.dart # Service de notifications
│   └── daily_reset_service.dart  # Service de réinitialisation
├── viewmodels/
│   └── task_viewmodel.dart  # Logique métier et gestion d'état
├── views/
│   ├── home_page.dart       # Page principale
│   ├── add_task_page.dart   # Page d'ajout/modification
│   ├── stats_page.dart      # Page de statistiques
│   └── settings_page.dart   # Page de paramètres
└── widgets/
    └── task_tile.dart       # Widget personnalisé pour les tâches
```

## 🛠️ Technologies utilisées

- **Flutter** : Framework de développement mobile
- **Provider** : Gestion d'état
- **Hive** : Base de données locale NoSQL
- **flutter_local_notifications** : Notifications locales
- **fl_chart** : Graphiques et visualisations
- **flutter_animate** : Animations
- **intl** : Internationalisation et formatage des dates
- **Material 3** : Design system moderne

## 🚀 Installation et utilisation

### Prérequis
- Flutter SDK (version 3.0.0 ou supérieure)
- Android Studio / Xcode pour le développement
- Un appareil physique ou émulateur

### Installation
1. Clonez le repository
2. Installez les dépendances :
   ```bash
   flutter pub get
   ```
3. Générez les fichiers Hive :
   ```bash
   flutter packages pub run build_runner build
   ```
4. Lancez l'application :
   ```bash
   flutter run
   ```

### Configuration des notifications

#### Android
Les permissions sont automatiquement configurées dans `AndroidManifest.xml` :
- `RECEIVE_BOOT_COMPLETED`
- `VIBRATE`
- `WAKE_LOCK`
- `USE_EXACT_ALARM`
- `SCHEDULE_EXACT_ALARM`
- `POST_NOTIFICATIONS`

#### iOS
Les permissions sont configurées dans `Info.plist` :
- Modes d'arrière-plan pour les notifications
- Configuration des alertes

## 📱 Utilisation

### Créer une tâche
1. Appuyez sur le bouton flottant "+"
2. Remplissez le titre (obligatoire)
3. Ajoutez une description (optionnelle)
4. Sélectionnez la date et l'heure
5. Activez/désactivez les notifications
6. Sauvegardez

### Gérer les tâches
- **Marquer comme terminée** : Appuyez sur la case à cocher
- **Modifier** : Appuyez sur la tâche
- **Supprimer** : Menu contextuel → Supprimer

### Consulter les statistiques
1. Allez dans l'onglet "Statistiques"
2. Explorez les différents graphiques :
   - Progression des tâches terminées
   - Répartition des tâches
   - Historique des performances

### Tâches d'exemple
L'application inclut des tâches d'exemple pour tester les fonctionnalités :
- Réveil matinal
- Petit-déjeuner
- Exercice physique
- Travail/Études
- Pause déjeuner

## 🎨 Personnalisation

### Couleurs
L'application utilise une palette de couleurs douces :
- **Primaire** : Bleu clair (#2196F3)
- **Secondaire** : Vert menthe (#4CAF50)
- **Surface** : Blanc cassé (#FAFAFA)
- **Accents** : Violet (#9C27B0)

### Animations
Les animations sont configurées pour être fluides et non intrusives :
- Transitions entre pages
- Animations des tâches
- Effets de shimmer
- Animations de completion

## 🔧 Développement

### Structure des données
```dart
class Task {
  String id;              // Identifiant unique
  String title;           // Titre de la tâche
  String? description;    // Description optionnelle
  DateTime date;          // Date de la tâche
  DateTime time;          // Heure de la tâche
  bool isCompleted;       // Statut de completion
  DateTime createdAt;     // Date de création
  DateTime? completedAt;  // Date de completion
  bool notificationEnabled; // Notifications activées
}
```

### Services
- **DatabaseService** : Gestion des données avec Hive
- **NotificationService** : Gestion des notifications locales
- **DailyResetService** : Réinitialisation quotidienne

### Gestion d'état
Le `TaskViewModel` utilise Provider pour :
- Charger les tâches
- Gérer les opérations CRUD
- Programmer les notifications
- Calculer les statistiques

## 📈 Améliorations futures

- [ ] Synchronisation cloud
- [ ] Catégories de tâches
- [ ] Rappels récurrents
- [ ] Mode sombre
- [ ] Widgets d'accueil
- [ ] Export des données
- [ ] Collaboration en équipe

## 🤝 Contribution

Les contributions sont les bienvenues ! N'hésitez pas à :
1. Fork le projet
2. Créer une branche pour votre fonctionnalité
3. Commiter vos changements
4. Pousser vers la branche
5. Ouvrir une Pull Request

## 📄 Licence

Ce projet est sous licence MIT. Voir le fichier `LICENSE` pour plus de détails.

## 🙏 Remerciements

- Flutter team pour le framework
- Les contributeurs des packages utilisés
- La communauté Flutter pour l'inspiration

---

**FocusMe** - Restez concentré, restez productif ! 🎯
