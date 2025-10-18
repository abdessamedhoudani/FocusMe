# 🚀 Guide de démarrage rapide - FocusMe

## Installation et configuration

### 1. Prérequis
- Flutter SDK (version 3.0.0 ou supérieure)
- Android Studio ou Xcode
- Un appareil physique ou émulateur

### 2. Installation des dépendances
```bash
flutter pub get
```

### 3. Génération des fichiers Hive
```bash
flutter packages pub run build_runner build
```

### 4. Lancement de l'application
```bash
flutter run
```

## 🎯 Première utilisation

### Ajouter des tâches d'exemple
1. Ouvrez l'application
2. Appuyez sur le menu (⋮) en haut à droite
3. Sélectionnez "Ajouter des tâches d'exemple"
4. Confirmez l'ajout

### Créer votre première tâche
1. Appuyez sur le bouton flottant "+" en bas à droite
2. Remplissez le titre de votre tâche
3. Ajoutez une description (optionnelle)
4. Sélectionnez la date et l'heure
5. Activez les notifications si souhaité
6. Sauvegardez

### Gérer vos tâches
- **Marquer comme terminée** : Appuyez sur la case à cocher
- **Modifier** : Appuyez sur la tâche
- **Supprimer** : Menu contextuel (⋮) → Supprimer

### Consulter les statistiques
1. Allez dans l'onglet "Statistiques"
2. Explorez les graphiques de progression
3. Consultez votre taux de completion

## 🔧 Configuration des notifications

### Android
Les permissions sont automatiquement demandées au premier lancement.

### iOS
Les permissions sont demandées lors de la première création de tâche avec notifications.

## 🎨 Personnalisation

L'application utilise Material 3 avec une palette de couleurs douces :
- **Bleu clair** pour les éléments principaux
- **Vert menthe** pour les éléments secondaires
- **Blanc cassé** pour les surfaces

## 📱 Fonctionnalités principales

### ✅ Gestion des tâches
- Création, modification, suppression
- Statut terminé/en cours
- Notifications automatiques
- Réinitialisation quotidienne

### 📊 Statistiques
- Graphiques de progression
- Taux de completion
- Historique des performances
- Filtres par période

### 🔔 Notifications
- Alertes à l'heure programmée
- Notifications de réinitialisation
- Gestion des permissions

## 🛠️ Dépannage

### Problèmes courants

#### Erreur de génération Hive
```bash
flutter clean
flutter pub get
flutter packages pub run build_runner build --delete-conflicting-outputs
```

#### Problèmes de notifications
1. Vérifiez les permissions dans les paramètres de l'appareil
2. Redémarrez l'application
3. Recréez les tâches avec notifications

#### Problèmes de base de données
```bash
flutter clean
flutter pub get
```

### Logs de débogage
```bash
flutter run --verbose
```

## 📚 Ressources

- [Documentation Flutter](https://flutter.dev/docs)
- [Material 3 Design](https://m3.material.io/)
- [Hive Documentation](https://docs.hivedb.dev/)
- [Provider Documentation](https://pub.dev/packages/provider)

## 🤝 Support

Si vous rencontrez des problèmes :
1. Vérifiez ce guide de démarrage
2. Consultez le README.md principal
3. Vérifiez les logs de débogage
4. Créez une issue sur le repository

---

**Bon focus avec FocusMe ! 🎯**
