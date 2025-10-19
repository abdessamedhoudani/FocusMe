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
                title: TranslationService.getTranslation(context, 'help'),
                subtitle: TranslationService.getTranslation(context, 'helpSubtitle'),
                onTap: () => _showHelpDialog(context),
              ),
              _SettingsTile(
                icon: Icons.feedback,
                title: TranslationService.getTranslation(context, 'feedback'),
                subtitle: TranslationService.getTranslation(context, 'feedbackSubtitle'),
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
        title: Text(TranslationService.getTranslation(context, 'resetTasksTitle')),
        content: Text(TranslationService.getTranslation(context, 'resetTasksMessage')),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(TranslationService.getTranslation(context, 'cancel')),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.read<TaskViewModel>().resetDailyTasks();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(TranslationService.getTranslation(context, 'resetSuccess')),
                ),
              );
            },
            child: Text(TranslationService.getTranslation(context, 'reset')),
          ),
        ],
      ),
    );
  }

  void _showDeleteCompletedDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(TranslationService.getTranslation(context, 'deleteCompletedTitle')),
        content: Text(TranslationService.getTranslation(context, 'deleteCompletedMessage')),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(TranslationService.getTranslation(context, 'cancel')),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.read<TaskViewModel>().deleteCompletedTasks();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(TranslationService.getTranslation(context, 'deleteCompletedSuccess')),
                ),
              );
            },
            child: Text(TranslationService.getTranslation(context, 'delete')),
          ),
        ],
      ),
    );
  }

  void _showDeleteAllDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(TranslationService.getTranslation(context, 'deleteAllTitle')),
        content: Text(TranslationService.getTranslation(context, 'deleteAllMessage')),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(TranslationService.getTranslation(context, 'cancel')),
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
                    ? TranslationService.getTranslation(context, 'deleteAllSuccess')
                    : TranslationService.getTranslation(context, 'deleteAllError')),
                  backgroundColor: success ? null : Colors.red,
                ),
              );
            },
            child: Text(TranslationService.getTranslation(context, 'deleteAll')),
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
        Text(TranslationService.getTranslation(context, 'aboutDescription')),
        const SizedBox(height: 16),
        Text(TranslationService.getTranslation(context, 'features')),
        Text(TranslationService.getTranslation(context, 'featureTasks')),
        Text(TranslationService.getTranslation(context, 'featureNotifications')),
        Text(TranslationService.getTranslation(context, 'featureStats')),
        Text(TranslationService.getTranslation(context, 'featureInterface')),
      ],
    );
  }

  void _showHelpDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(TranslationService.getTranslation(context, 'helpTitle')),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                TranslationService.getTranslation(context, 'createTask'),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(TranslationService.getTranslation(context, 'helpCreate1')),
              Text(TranslationService.getTranslation(context, 'helpCreate2')),
              Text(TranslationService.getTranslation(context, 'helpCreate3')),
              Text(TranslationService.getTranslation(context, 'helpCreate4')),
              const SizedBox(height: 16),
              Text(
                TranslationService.getTranslation(context, 'manageTasks'),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(TranslationService.getTranslation(context, 'helpManage1')),
              Text(TranslationService.getTranslation(context, 'helpManage2')),
              Text(TranslationService.getTranslation(context, 'helpManage3')),
              const SizedBox(height: 16),
              Text(
                TranslationService.getTranslation(context, 'helpNotifications'),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(TranslationService.getTranslation(context, 'helpNotif1')),
              Text(TranslationService.getTranslation(context, 'helpNotif2')),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(TranslationService.getTranslation(context, 'close')),
          ),
        ],
      ),
    );
  }

  void _showFeedbackDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(TranslationService.getTranslation(context, 'feedback')),
        content: Text(TranslationService.getTranslation(context, 'feedbackMessage')),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(TranslationService.getTranslation(context, 'close')),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              // TODO: Implémenter l'envoi de commentaires
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(TranslationService.getTranslation(context, 'featureToImplement')),
                ),
              );
            },
            child: Text(TranslationService.getTranslation(context, 'send')),
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
