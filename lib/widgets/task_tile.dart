import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../models/task.dart';

class TaskTile extends StatelessWidget {
  final Task task;
  final VoidCallback onTap;
  final VoidCallback onToggle;
  final VoidCallback onDelete;
  final bool isSelected;

  const TaskTile({
    super.key,
    required this.task,
    required this.onTap,
    required this.onToggle,
    required this.onDelete,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      elevation: isSelected ? 8 : 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: isSelected 
            ? BorderSide(color: colorScheme.primary, width: 2)
            : BorderSide.none,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Checkbox
              _buildCheckbox(colorScheme),
              const SizedBox(width: 16),
              
              // Contenu principal
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildTitle(theme),
                    if (task.description != null && task.description!.isNotEmpty)
                      _buildDescription(theme),
                    const SizedBox(height: 8),
                    _buildTimeAndStatus(theme),
                  ],
                ),
              ),
              
              // Actions
              _buildActions(context, colorScheme),
            ],
          ),
        ),
      ),
    ).animate(target: isSelected ? 1 : 0)
        .scale(begin: 1.0, end: 1.02, duration: 200.ms)
        .shimmer(
          color: colorScheme.primary.withOpacity(0.1),
          duration: 1500.ms,
        );
  }

  Widget _buildCheckbox(ColorScheme colorScheme) {
    return GestureDetector(
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
                color: colorScheme.onPrimary,
                size: 16,
              )
            : null,
      ),
    ).animate(target: task.isCompleted ? 1 : 0)
        .scale(begin: 0.8, end: 1.0, duration: 200.ms)
        .then()
        .shimmer(
          color: colorScheme.primary.withOpacity(0.3),
          duration: 800.ms,
        );
  }

  Widget _buildTitle(ThemeData theme) {
    return Text(
      task.title,
      style: theme.textTheme.titleMedium?.copyWith(
        decoration: task.isCompleted ? TextDecoration.lineThrough : null,
        color: task.isCompleted 
            ? theme.colorScheme.onSurfaceVariant
            : theme.colorScheme.onSurface,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _buildDescription(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Text(
        task.description!,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
          decoration: task.isCompleted ? TextDecoration.lineThrough : null,
        ),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _buildTimeAndStatus(ThemeData theme) {
    final timeFormat = DateFormat('HH:mm');
    final isOverdue = task.isOverdue && !task.isCompleted;
    
    return Row(
      children: [
        Icon(
          Icons.access_time,
          size: 16,
          color: isOverdue 
              ? theme.colorScheme.error
              : theme.colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: 4),
        Text(
          timeFormat.format(task.time),
          style: theme.textTheme.bodySmall?.copyWith(
            color: isOverdue 
                ? theme.colorScheme.error
                : theme.colorScheme.onSurfaceVariant,
            fontWeight: isOverdue ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
        const SizedBox(width: 8),
        if (task.notificationEnabled)
          Icon(
            Icons.notifications_active,
            size: 16,
            color: theme.colorScheme.primary,
          ),
        if (isOverdue) ...[
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: theme.colorScheme.errorContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              'En retard',
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onErrorContainer,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildActions(BuildContext context, ColorScheme colorScheme) {
    return PopupMenuButton<String>(
      icon: Icon(
        Icons.more_vert,
        color: colorScheme.onSurfaceVariant,
      ),
      onSelected: (value) {
        switch (value) {
          case 'delete':
            _showDeleteConfirmation(context);
            break;
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 'delete',
          child: Row(
            children: [
              Icon(
                Icons.delete_outline,
                color: colorScheme.error,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Supprimer',
                style: TextStyle(color: colorScheme.error),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer la tâche'),
        content: Text('Êtes-vous sûr de vouloir supprimer "${task.title}" ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop();
              onDelete();
            },
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }
}

// Widget pour afficher une tâche dans une liste avec animation
class AnimatedTaskTile extends StatefulWidget {
  final Task task;
  final VoidCallback onTap;
  final VoidCallback onToggle;
  final VoidCallback onDelete;
  final bool isSelected;

  const AnimatedTaskTile({
    super.key,
    required this.task,
    required this.onTap,
    required this.onToggle,
    required this.onDelete,
    this.isSelected = false,
  });

  @override
  State<AnimatedTaskTile> createState() => _AnimatedTaskTileState();
}

class _AnimatedTaskTileState extends State<AnimatedTaskTile>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: TaskTile(
            task: widget.task,
            onTap: () {
              _animationController.forward().then((_) {
                _animationController.reverse();
                widget.onTap();
              });
            },
            onToggle: widget.onToggle,
            onDelete: widget.onDelete,
            isSelected: widget.isSelected,
          ),
        );
      },
    );
  }
}
