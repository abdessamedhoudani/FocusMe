import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/task.dart';
import '../services/translation_service.dart';

class TaskTile extends StatelessWidget {
  final Task task;
  final VoidCallback? onTap;
  final VoidCallback? onToggle;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final bool showDate;

  const TaskTile({
    super.key,
    required this.task,
    this.onTap,
    this.onToggle,
    this.onEdit,
    this.onDelete,
    this.showDate = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      elevation: task.isCompleted ? 1 : 3,
      color: _getCardColor(colorScheme),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Checkbox
              GestureDetector(
                onTap: onToggle,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: task.isCompleted 
                        ? colorScheme.primary 
                        : Colors.transparent,
                    border: Border.all(
                      color: task.isCompleted 
                          ? colorScheme.primary 
                          : colorScheme.outline,
                      width: 2,
                    ),
                  ),
                  child: task.isCompleted
                      ? Icon(
                          Icons.check,
                          size: 16,
                          color: colorScheme.onPrimary,
                        )
                      : null,
                ),
              ),
              
              const SizedBox(width: 16),
              
              // Contenu de la tâche
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Titre
                    Text(
                      task.title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        decoration: task.isCompleted 
                            ? TextDecoration.lineThrough 
                            : null,
                        color: task.isCompleted 
                            ? colorScheme.onSurface.withOpacity(0.6)
                            : colorScheme.onSurface,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    
                    // Description (si présente)
                    if (task.description != null && task.description!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        task.description!,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurface.withOpacity(0.7),
                          decoration: task.isCompleted 
                              ? TextDecoration.lineThrough 
                              : null,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    
                    const SizedBox(height: 8),
                    
                    // Informations de date et heure
                    Row(
                      children: [
                        Icon(
                          Icons.access_time,
                          size: 16,
                          color: _getTimeColor(colorScheme),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _formatTime(),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: _getTimeColor(colorScheme),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        
                        if (showDate) ...[
                          const SizedBox(width: 8),
                          Icon(
                            Icons.calendar_today,
                            size: 16,
                            color: colorScheme.onSurface.withOpacity(0.6),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _formatDate(),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurface.withOpacity(0.6),
                            ),
                          ),
                        ],
                      ],
                    ),
                    
                    // Statut de retard
                    if (task.isOverdue && !task.isCompleted) ...[
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: colorScheme.errorContainer,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.warning,
                              size: 12,
                              color: colorScheme.onErrorContainer,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              TranslationService.getTranslation(context, 'overdue'),
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: colorScheme.onErrorContainer,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              
              // Actions
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (onEdit != null)
                    IconButton(
                      onPressed: onEdit,
                      icon: Icon(
                        Icons.edit,
                        color: colorScheme.onSurface.withOpacity(0.6),
                      ),
                      tooltip: 'Modifier',
                    ),
                  
                  if (onDelete != null)
                    IconButton(
                      onPressed: onDelete,
                      icon: Icon(
                        Icons.delete,
                        color: colorScheme.error,
                      ),
                      tooltip: 'Supprimer',
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    )
    .animate()
    .fadeIn(duration: 300.ms)
    .slideX(begin: 0.1, end: 0, duration: 300.ms);
  }

  Color _getCardColor(ColorScheme colorScheme) {
    if (task.isCompleted) {
      // Vert très doux pour les tâches terminées
      return const Color(0xFFE8F5E8); // Vert très clair
    } else if (task.isOverdue) {
      // Rouge très doux pour les tâches en retard
      return const Color(0xFFFFEBEE); // Rouge très clair
    } else {
      // Orange doux pour les tâches en cours
      return const Color(0xFFFFE0B2); // Orange plus visible
    }
  }

  Color _getTimeColor(ColorScheme colorScheme) {
    if (task.isCompleted) {
      return colorScheme.onSurface.withOpacity(0.5);
    } else if (task.isOverdue) {
      return colorScheme.error;
    } else {
      return colorScheme.primary;
    }
  }

  String _formatTime() {
    final hour = task.time.hour.toString().padLeft(2, '0');
    final minute = task.time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  String _formatDate() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final taskDate = DateTime(task.date.year, task.date.month, task.date.day);
    
    if (taskDate == today) {
      return 'Aujourd\'hui';
    } else if (taskDate == today.add(const Duration(days: 1))) {
      return 'Demain';
    } else if (taskDate == today.subtract(const Duration(days: 1))) {
      return 'Hier';
    } else {
      return '${task.date.day}/${task.date.month}/${task.date.year}';
    }
  }
}

// Widget pour afficher une liste de tâches
class TaskList extends StatelessWidget {
  final List<Task> tasks;
  final Function(Task)? onTaskTap;
  final Function(Task)? onTaskToggle;
  final Function(Task)? onTaskEdit;
  final Function(Task)? onTaskDelete;
  final bool showDate;
  final String? emptyMessage;

  const TaskList({
    super.key,
    required this.tasks,
    this.onTaskTap,
    this.onTaskToggle,
    this.onTaskEdit,
    this.onTaskDelete,
    this.showDate = false,
    this.emptyMessage,
  });

  @override
  Widget build(BuildContext context) {
    if (tasks.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.task_alt,
              size: 64,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
            ),
            const SizedBox(height: 16),
            Text(
              emptyMessage ?? 'Aucune tâche',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(top: 8, bottom: 80), // Ajouter un padding en bas pour éviter la superposition avec le FAB
      itemCount: tasks.length,
      itemBuilder: (context, index) {
        final task = tasks[index];
        return TaskTile(
          task: task,
          onTap: onTaskTap != null ? () => onTaskTap!(task) : null,
          onToggle: onTaskToggle != null ? () => onTaskToggle!(task) : null,
          onEdit: onTaskEdit != null ? () => onTaskEdit!(task) : null,
          onDelete: onTaskDelete != null ? () => onTaskDelete!(task) : null,
          showDate: showDate,
        );
      },
    );
  }
}
