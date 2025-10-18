import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../viewmodels/task_viewmodel.dart';
import '../services/preferences_service.dart';
import '../services/language_service.dart';
import '../services/translation_service.dart';
import '../services/notification_service.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _notificationsEnabled = true;
  bool _soundEnabled = true;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final notificationsEnabled = await PreferencesService.getNotificationsEnabled();
    final soundEnabled = await PreferencesService.getSoundEnabled();
    
    setState(() {
      _notificationsEnabled = notificationsEnabled;
      _soundEnabled = soundEnabled;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(TranslationService.getTranslation(context, 'settings')),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Section notifications
          _SettingsSection(
            title: TranslationService.getTranslation(context, 'notifications'),
            children: [
              _SettingsTile(
                icon: Icons.notifications,
                title: TranslationService.getTranslation(context, 'taskReminders'),
                subtitle: TranslationService.getTranslation(context, 'receiveNotifications'),
                trailing: Switch(
                  value: _notificationsEnabled,
                  onChanged: (value) async {
                    setState(() {
                      _notificationsEnabled = value;
                      // Si on désactive les notifications, désactiver aussi le son
                      if (!value) {
                        _soundEnabled = false;
                      }
                    });
                    await PreferencesService.setNotificationsEnabled(value);
                    // Sauvegarder aussi l'état du son si on a désactivé les notifications
                    if (!value) {
                      await PreferencesService.setSoundEnabled(false);
                    }
                  },
                ),
              ),
              _SettingsTile(
                icon: Icons.volume_up,
                title: TranslationService.getTranslation(context, 'notificationSound'),
                subtitle: TranslationService.getTranslation(context, 'enableNotificationSound'),
                trailing: Switch(
                  value: _soundEnabled && _notificationsEnabled,
                  onChanged: _notificationsEnabled ? (value) async {
                    setState(() {
                      _soundEnabled = value;
                    });
                    await PreferencesService.setSoundEnabled(value);
                  } : null,
                ),
              ),
              // Bouton de test des notifications
              _SettingsTile(
                icon: Icons.bug_report,
                title: 'Test des notifications',
                subtitle: 'Envoyer une notification de test',
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () async {
                  print('=== TEST NOTIFICATION BOUTON CLIQUÉ ===');
                  try {
                    print('Tentative d\'envoi de notification de test...');
                    await NotificationService().showImmediateNotification(
                      title: 'Test FocusMe',
                      body: 'Cette notification de test confirme que les notifications fonctionnent !',
                    );
                    print('Notification de test envoyée avec succès !');
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Notification de test envoyée !'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  } catch (e) {
                    print('Erreur lors de l\'envoi de la notification de test: $e');
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Erreur: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                  print('=== FIN TEST NOTIFICATION ===');
                },
              ),
              _SettingsTile(
                icon: Icons.schedule,
                title: 'Vérifier les notifications programmées',
                subtitle: 'Afficher les notifications en attente',
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () async {
                  print('=== VÉRIFICATION NOTIFICATIONS PROGRAMMÉES ===');
                  try {
                    await NotificationService().checkScheduledNotifications();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Vérification terminée - voir les logs'),
                        backgroundColor: Colors.blue,
                      ),
                    );
                  } catch (e) {
                    print('Erreur lors de la vérification: $e');
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Erreur: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                  print('=== FIN VÉRIFICATION ===');
                },
              ),
              _SettingsTile(
                icon: Icons.timer,
                title: 'Test notification programmée',
                subtitle: 'Programmer une notification dans 30 secondes',
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () async {
                  print('=== TEST NOTIFICATION PROGRAMMÉE ===');
                  try {
                    await NotificationService().scheduleTestNotification();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Notification de test programmée dans 30 secondes !'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  } catch (e) {
                    print('Erreur lors de la programmation: $e');
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Erreur: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                  print('=== FIN TEST NOTIFICATION PROGRAMMÉE ===');
                },
              ),
            ],
          ),
          
          const SizedBox(height: 32),
          
          // Section langue
          _SettingsSection(
            title: TranslationService.getTranslation(context, 'language'),
            children: [
              _SettingsTile(
                icon: Icons.language,
                title: TranslationService.getTranslation(context, 'selectLanguage'),
                subtitle: context.read<LanguageService>().currentLanguageName,
                onTap: () => _showLanguageDialog(context),
              ),
            ],
          ),
          
          const SizedBox(height: 32),
          
          // Section gestion des données
          _SettingsSection(
            title: TranslationService.getTranslation(context, 'dataManagement'),
            children: [
              _SettingsTile(
                icon: Icons.refresh,
                title: TranslationService.getTranslation(context, 'resetDailyTasks'),
                subtitle: TranslationService.getTranslation(context, 'markAllAsIncomplete'),
                onTap: () => _showResetDialog(context),
              ),
              _SettingsTile(
                icon: Icons.delete_sweep,
                title: TranslationService.getTranslation(context, 'deleteCompletedTasks'),
                subtitle: TranslationService.getTranslation(context, 'cleanupHistory'),
                onTap: () => _showDeleteCompletedDialog(context),
              ),
              _SettingsTile(
                icon: Icons.delete_forever,
                title: TranslationService.getTranslation(context, 'deleteAllTasks'),
                subtitle: TranslationService.getTranslation(context, 'clearAllData'),
                onTap: () => _showDeleteAllDialog(context),
              ),
            ],
          ),
          
          const SizedBox(height: 32),
          
          // Section à propos
          _SettingsSection(
            title: TranslationService.getTranslation(context, 'about'),
            children: [
              _SettingsTile(
                icon: Icons.info,
                title: TranslationService.getTranslation(context, 'version'),
                subtitle: '1.0.0',
                onTap: () => _showAboutDialog(context),
              ),
              _SettingsTile(
                icon: Icons.help,
                title: 'Aide',
                subtitle: 'Comment utiliser FocusMe',
                onTap: () => _showHelpDialog(context),
              ),
              _SettingsTile(
                icon: Icons.feedback,
                title: 'Commentaires',
                subtitle: 'Partager vos suggestions',
                onTap: () => _showFeedbackDialog(context),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showResetDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Réinitialiser les tâches'),
        content: const Text(
          'Cette action marquera toutes les tâches comme non terminées. '
          'Voulez-vous continuer ?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.read<TaskViewModel>().resetDailyTasks();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Tâches réinitialisées avec succès'),
                ),
              );
            },
            child: const Text('Réinitialiser'),
          ),
        ],
      ),
    );
  }

  void _showDeleteCompletedDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer les tâches terminées'),
        content: const Text(
          'Cette action supprimera définitivement toutes les tâches terminées. '
          'Cette action est irréversible.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.read<TaskViewModel>().deleteCompletedTasks();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Tâches terminées supprimées avec succès'),
                ),
              );
            },
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }

  void _showDeleteAllDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer toutes les tâches'),
        content: const Text(
          'Cette action supprimera définitivement TOUTES les tâches. '
          'Cette action est irréversible.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              
              // Afficher un indicateur de chargement
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (context) => const Center(
                  child: CircularProgressIndicator(),
                ),
              );
              
              final success = await context.read<TaskViewModel>().deleteAllTasks();
              
              // Fermer l'indicateur de chargement
              Navigator.of(context).pop();
              
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(success 
                    ? 'Toutes les tâches ont été supprimées'
                    : 'Erreur lors de la suppression des tâches'),
                  backgroundColor: success ? null : Colors.red,
                ),
              );
            },
            child: const Text('Supprimer tout'),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: 'FocusMe',
      applicationVersion: '1.0.0',
      applicationIcon: const Icon(
        Icons.task_alt,
        size: 64,
      ),
      children: [
        const Text(
          'FocusMe est une application de gestion des tâches quotidiennes '
          'conçue pour vous aider à rester organisé et productif.',
        ),
        const SizedBox(height: 16),
        const Text(
          'Fonctionnalités :',
        ),
        const Text('• Gestion complète des tâches (CRUD)'),
        const Text('• Notifications automatiques'),
        const Text('• Statistiques de productivité'),
        const Text('• Interface moderne et intuitive'),
      ],
    );
  }

  void _showHelpDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Comment utiliser FocusMe'),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Créer une tâche :',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text('• Appuyez sur le bouton "+" sur l\'écran principal'),
              Text('• Remplissez le titre et la description'),
              Text('• Choisissez la date et l\'heure'),
              Text('• Appuyez sur "Créer"'),
              SizedBox(height: 16),
              Text(
                'Gérer vos tâches :',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text('• Cochez les tâches terminées'),
              Text('• Appuyez sur une tâche pour voir les détails'),
              Text('• Utilisez les icônes pour modifier ou supprimer'),
              SizedBox(height: 16),
              Text(
                'Notifications :',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text('• Les notifications apparaissent à l\'heure programmée'),
              Text('• Appuyez sur la notification pour ouvrir la tâche'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  void _showFeedbackDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Commentaires'),
        content: const Text(
          'Nous apprécions vos commentaires ! '
          'Envoyez-nous vos suggestions pour améliorer FocusMe.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Fermer'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              // TODO: Implémenter l'envoi de commentaires
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Fonctionnalité à implémenter'),
                ),
              );
            },
            child: const Text('Envoyer'),
          ),
        ],
      ),
    );
  }

  void _showLanguageDialog(BuildContext context) {
    final languageService = context.read<LanguageService>();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(TranslationService.getTranslation(context, 'selectLanguage')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: LanguageService.supportedLocales.map((locale) {
            final isSelected = locale == languageService.currentLocale;
            return ListTile(
              title: Text(LanguageService.languageNames[locale.languageCode]!),
              leading: Radio<Locale>(
                value: locale,
                groupValue: languageService.currentLocale,
                onChanged: (Locale? value) {
                  if (value != null) {
                    languageService.changeLanguage(value);
                    Navigator.of(context).pop();
                  }
                },
              ),
              onTap: () {
                languageService.changeLanguage(locale);
                Navigator.of(context).pop();
              },
            );
          }).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(TranslationService.getTranslation(context, 'cancel')),
          ),
        ],
      ),
    );
  }

}

class _SettingsSection extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _SettingsSection({
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: Column(children: children),
        ),
      ],
    )
    .animate()
    .fadeIn(duration: 300.ms)
    .slideY(begin: 0.1, end: 0, duration: 300.ms);
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: trailing,
      onTap: onTap,
    );
  }
}
