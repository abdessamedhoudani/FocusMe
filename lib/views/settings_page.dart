import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/task_viewmodel.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Paramètres'),
        backgroundColor: colorScheme.primaryContainer,
        foregroundColor: colorScheme.onPrimaryContainer,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSection(
            context,
            'Données',
            [
              _buildListTile(
                context,
                icon: Icons.add_task,
                title: 'Ajouter des tâches d\'exemple',
                subtitle: 'Créer des tâches de démonstration',
                onTap: () => _addSampleTasks(context),
              ),
              _buildListTile(
                context,
                icon: Icons.cleaning_services,
                title: 'Nettoyer les anciennes tâches',
                subtitle: 'Supprimer les tâches de plus de 30 jours',
                onTap: () => _cleanupOldTasks(context),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildSection(
            context,
            'Application',
            [
              _buildListTile(
                context,
                icon: Icons.info,
                title: 'À propos',
                subtitle: 'FocusMe v1.0.0',
                onTap: () => _showAboutDialog(context),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSection(BuildContext context, String title, List<Widget> children) {
    final theme = Theme.of(context);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 16, bottom: 8),
          child: Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.primary,
            ),
          ),
        ),
        Card(
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _buildListTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    
    return ListTile(
      leading: Icon(icon, color: theme.colorScheme.primary),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }

  Future<void> _addSampleTasks(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ajouter des tâches d\'exemple'),
        content: const Text(
          'Cela va créer des tâches de démonstration pour aujourd\'hui. '
          'Voulez-vous continuer ?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Ajouter'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await context.read<TaskViewModel>().addSampleTasks();
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Tâches d\'exemple ajoutées avec succès'),
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erreur: $e'),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      }
    }
  }

  Future<void> _cleanupOldTasks(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nettoyer les anciennes tâches'),
        content: const Text(
          'Cela va supprimer toutes les tâches de plus de 30 jours. '
          'Cette action est irréversible. Voulez-vous continuer ?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await context.read<TaskViewModel>().cleanupOldTasks();
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Nettoyage terminé avec succès'),
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erreur: $e'),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      }
    }
  }

  void _showAboutDialog(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: 'FocusMe',
      applicationVersion: '1.0.0',
      applicationIcon: const Icon(
        Icons.task_alt,
        size: 48,
      ),
      children: [
        const Text(
          'FocusMe est une application de gestion de tâches quotidiennes '
          'avec notifications et statistiques de productivité.',
        ),
        const SizedBox(height: 16),
        const Text(
          'Fonctionnalités :',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const Text('• Gestion complète des tâches (CRUD)'),
        const Text('• Notifications automatiques'),
        const Text('• Statistiques et graphiques'),
        const Text('• Réinitialisation quotidienne'),
        const Text('• Design moderne Material 3'),
      ],
    );
  }
}
