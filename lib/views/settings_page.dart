import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:url_launcher/url_launcher.dart';
import '../viewmodels/task_viewmodel.dart';
import '../services/preferences_service.dart';
import '../services/language_service.dart';
import '../services/translation_service.dart';
import '../services/notification_service.dart';
import 'categories_page.dart';

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
          
          // Section catégories
          _SettingsSection(
            title: TranslationService.getTranslation(context, 'categories'),
            children: [
              _SettingsTile(
                icon: Icons.category,
                title: TranslationService.getTranslation(context, 'manageCategories'),
                subtitle: TranslationService.getTranslation(context, 'manageCategoriesSubtitle'),
                onTap: () => _navigateToCategories(context),
              ),
              _SettingsTile(
                icon: Icons.refresh,
                title: TranslationService.getTranslation(context, 'resetDefaultCategories'),
                subtitle: TranslationService.getTranslation(context, 'resetDefaultCategoriesSubtitle'),
                onTap: () => _showResetCategoriesDialog(context),
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
              _SettingsTile(
                icon: Icons.cleaning_services,
                title: TranslationService.getTranslation(context, 'cleanupDuplicates'),
                subtitle: TranslationService.getTranslation(context, 'removeDuplicateTasks'),
                onTap: () => _showCleanupDuplicatesDialog(context),
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

  void _navigateToCategories(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const CategoriesPage(),
      ),
    );
  }

  void _showResetCategoriesDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(TranslationService.getTranslation(context, 'resetDefaultCategories')),
        content: Text(TranslationService.getTranslation(context, 'resetDefaultCategoriesMessage')),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(TranslationService.getTranslation(context, 'cancel')),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await _resetDefaultCategories(context);
            },
            child: Text(TranslationService.getTranslation(context, 'reset')),
          ),
        ],
      ),
    );
  }

  Future<void> _resetDefaultCategories(BuildContext context) async {
    try {
      // Obtenir la langue actuelle
      final languageService = Provider.of<LanguageService>(context, listen: false);
      final currentLanguage = languageService.currentLocale.languageCode;
      
      // Réinitialiser les catégories avec la langue actuelle
      await context.read<TaskViewModel>().initializeCategoriesWithLanguage(currentLanguage);
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(TranslationService.getTranslation(context, 'categoriesResetSuccess')),
            backgroundColor: Theme.of(context).colorScheme.primary,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${TranslationService.getTranslation(context, 'error')}: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
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
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(
              Icons.task_alt,
              size: 32,
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('FocusMe'),
                Text(
                  '1.0.0',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(TranslationService.getTranslation(context, 'aboutDescription')),
              const SizedBox(height: 16),
              Text(
                TranslationService.getTranslation(context, 'features'),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(TranslationService.getTranslation(context, 'featureTasks')),
              Text(TranslationService.getTranslation(context, 'featureNotifications')),
              Text(TranslationService.getTranslation(context, 'featureStats')),
              Text(TranslationService.getTranslation(context, 'featureInterface')),
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
    final feedbackController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(TranslationService.getTranslation(context, 'feedback')),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(TranslationService.getTranslation(context, 'feedbackMessage')),
              const SizedBox(height: 16),
              TextField(
                controller: feedbackController,
                maxLines: 5,
                decoration: InputDecoration(
                  hintText: TranslationService.getTranslation(context, 'feedbackHint'),
                  border: const OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(TranslationService.getTranslation(context, 'cancel')),
          ),
          ElevatedButton(
            onPressed: () => _sendFeedback(context, feedbackController.text),
            child: Text(TranslationService.getTranslation(context, 'send')),
          ),
        ],
      ),
    );
  }

  void _sendFeedback(BuildContext context, String feedback) async {
    Navigator.of(context).pop();
    
    if (feedback.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(TranslationService.getTranslation(context, 'feedbackEmpty')),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
    }

    // Créer le sujet et le corps de l'email
    final subject = TranslationService.getTranslation(context, 'feedbackEmailSubject');
    final emailBody = '''
${TranslationService.getTranslation(context, 'feedbackEmailBody')}

---
${feedback.trim()}
---

${TranslationService.getTranslation(context, 'appInfo')}:
- App: FocusMe v1.0.0
- Platform: ${Theme.of(context).platform.name}
- Date: ${DateTime.now().toIso8601String()}
    ''';

    try {
      // Créer l'URL mailto
      final Uri emailUri = Uri(
        scheme: 'mailto',
        path: 'abdessamed.houdani@gmail.com',
        query: _encodeQueryParameters(<String, String>{
          'subject': subject,
          'body': emailBody,
        }),
      );

      // Tenter d'ouvrir l'application email
      if (await canLaunchUrl(emailUri)) {
        await launchUrl(emailUri);
        
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(TranslationService.getTranslation(context, 'feedbackEmailOpened')),
              backgroundColor: Theme.of(context).colorScheme.primary,
            ),
          );
        }
      } else {
        // Si l'ouverture échoue, copier dans le presse-papiers comme fallback
        await _fallbackCopyToClipboard(context, subject, emailBody);
      }
    } catch (e) {
      // En cas d'erreur, utiliser le fallback
      await _fallbackCopyToClipboard(context, subject, emailBody);
    }
  }

  String _encodeQueryParameters(Map<String, String> params) {
    return params.entries
        .map((MapEntry<String, String> e) =>
            '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
        .join('&');
  }

  Future<void> _fallbackCopyToClipboard(BuildContext context, String subject, String emailBody) async {
    try {
      final fullContent = '''
Email à: abdessamed.houdani@gmail.com
Sujet: $subject

$emailBody
      ''';
      
      await Clipboard.setData(ClipboardData(text: fullContent));
      
      if (context.mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(TranslationService.getTranslation(context, 'feedbackFallbackTitle')),
            content: Text(TranslationService.getTranslation(context, 'feedbackFallbackMessage')),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(TranslationService.getTranslation(context, 'ok')),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${TranslationService.getTranslation(context, 'error')}: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
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

  void _showCleanupDuplicatesDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(TranslationService.getTranslation(context, 'cleanupDuplicates')),
        content: Text(TranslationService.getTranslation(context, 'cleanupDuplicatesMessage')),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(TranslationService.getTranslation(context, 'cancel')),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              try {
                await context.read<TaskViewModel>().cleanupDuplicateTasks();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(TranslationService.getTranslation(context, 'cleanupDuplicatesSuccess')),
                      backgroundColor: Theme.of(context).colorScheme.primary,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${TranslationService.getTranslation(context, 'error')}: $e'),
                      backgroundColor: Theme.of(context).colorScheme.error,
                    ),
                  );
                }
              }
            },
            child: Text(TranslationService.getTranslation(context, 'cleanup')),
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
