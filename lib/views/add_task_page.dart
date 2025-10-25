import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/task.dart';
import '../models/category.dart';
import '../viewmodels/task_viewmodel.dart';
import '../services/translation_service.dart';
import '../services/category_service.dart';

class AddTaskPage extends StatefulWidget {
  final Task? task;

  const AddTaskPage({super.key, this.task});

  @override
  State<AddTaskPage> createState() => _AddTaskPageState();
}

class _AddTaskPageState extends State<AddTaskPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();
  bool _isLoading = false;
  bool _notificationsEnabled = true;
  TaskRecurrence _selectedRecurrence = TaskRecurrence.none;
  String? _selectedCategoryId;
  List<Category> _categories = [];
  final CategoryService _categoryService = CategoryService();

  bool get isEditing => widget.task != null;

  @override
  void initState() {
    super.initState();
    if (isEditing) {
      _titleController.text = widget.task!.title;
      _descriptionController.text = widget.task!.description ?? '';
      _selectedDate = widget.task!.date;
      _selectedTime = widget.task!.time;
      _notificationsEnabled = widget.task!.notificationsEnabled;
      _selectedRecurrence = widget.task!.recurrence;
      _selectedCategoryId = widget.task!.categoryId;
    }
    _loadCategories();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    try {
      final categories = await _categoryService.getAllCategories();
      setState(() {
        _categories = categories;
      });
    } catch (e) {
      print('Erreur lors du chargement des catégories: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? TranslationService.getTranslation(context, 'editTask') : TranslationService.getTranslation(context, 'addTask')),
        actions: [
          if (isEditing)
            IconButton(
              onPressed: _deleteTask,
              icon: const Icon(Icons.delete),
              tooltip: TranslationService.getTranslation(context, 'delete'),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Titre
              Text(
                TranslationService.getTranslation(context, 'taskTitle'),
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(
                  hintText: TranslationService.getTranslation(context, 'taskTitle'),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.title),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return TranslationService.getTranslation(context, 'titleRequired');
                  }
                  return null;
                },
                textInputAction: TextInputAction.next,
                enableInteractiveSelection: true,
              ),
              
              const SizedBox(height: 24),
              
              // Description
              Text(
                TranslationService.getTranslation(context, 'taskDescription'),
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  hintText: TranslationService.getTranslation(context, 'taskDescription'),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.description),
                ),
                maxLines: 3,
                textInputAction: TextInputAction.done,
                enableInteractiveSelection: true,
              ),
              
              const SizedBox(height: 24),
              
              // Catégorie
              _buildCategorySelector(),
              
              const SizedBox(height: 24),
              
              // Date et heure
              Row(
                children: [
                  Expanded(
                    child: _dateTimeSelector(
                      label: TranslationService.getTranslation(context, 'date'),
                      icon: Icons.calendar_today,
                      value: _formatDate(context, _selectedDate),
                      onTap: _selectDate,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _dateTimeSelector(
                      label: TranslationService.getTranslation(context, 'time'),
                      icon: Icons.access_time,
                      value: _formatTime(_selectedTime),
                      onTap: _selectTime,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 24),
              
              // Section récurrence
              _buildRecurrenceSelector(),
              
              const SizedBox(height: 24),
              
              // Paramètres de notification
              _buildNotificationSettings(),
              
              const SizedBox(height: 32),
              
              // Boutons d'action
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(TranslationService.getTranslation(context, 'cancel')),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _saveTask,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(isEditing ? TranslationService.getTranslation(context, 'edit') : TranslationService.getTranslation(context, 'save')),
                    ),
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
    .slideY(begin: 0.1, end: 0, duration: 300.ms);
  }

  Widget _dateTimeSelector({
    required String label,
    required IconData icon,
    required String value,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: colorScheme.outline),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: colorScheme.primary,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    value,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.arrow_drop_down,
                  color: colorScheme.onSurface.withOpacity(0.6),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _selectDate() async {
    final selectedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (selectedDate != null) {
      setState(() {
        _selectedDate = selectedDate;
      });
    }
  }

  Future<void> _selectTime() async {
    final selectedTime = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaleFactor: 1.0,
          ),
          child: child!,
        );
      },
    );

    if (selectedTime != null) {
      setState(() {
        _selectedTime = selectedTime;
      });
    }
  }

  Widget _buildCategorySelector() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          TranslationService.getTranslation(context, 'category'),
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: _showCategoryDialog,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: colorScheme.outline),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.category,
                  color: colorScheme.primary,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _getSelectedCategoryName(),
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.arrow_drop_down,
                  color: colorScheme.onSurface.withOpacity(0.6),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  String _getSelectedCategoryName() {
    if (_selectedCategoryId == null) {
      return TranslationService.getTranslation(context, 'noCategory');
    }
    
    final category = _categories.firstWhere(
      (cat) => cat.id == _selectedCategoryId,
      orElse: () => Category.create(name: '', color: Colors.grey),
    );
    
    return category.name.isNotEmpty ? category.name : TranslationService.getTranslation(context, 'noCategory');
  }

  void _showCategoryDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(TranslationService.getTranslation(context, 'selectCategory')),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Option "Aucune catégorie"
              ListTile(
                leading: Icon(
                  Icons.category_outlined,
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                ),
                title: Text(TranslationService.getTranslation(context, 'noCategory')),
                onTap: () {
                  setState(() {
                    _selectedCategoryId = null;
                  });
                  Navigator.of(context).pop();
                },
                selected: _selectedCategoryId == null,
              ),
              const Divider(),
              // Liste des catégories
              ..._categories.map((category) => ListTile(
                leading: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: category.color.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: category.color, width: 2),
                  ),
                  child: Icon(
                    Icons.category,
                    color: category.color,
                    size: 16,
                  ),
                ),
                title: Text(category.name),
                subtitle: category.description != null && category.description!.isNotEmpty
                    ? Text(
                        category.description!,
                        style: Theme.of(context).textTheme.bodySmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      )
                    : null,
                onTap: () {
                  setState(() {
                    _selectedCategoryId = category.id;
                  });
                  Navigator.of(context).pop();
                },
                selected: _selectedCategoryId == category.id,
              )),
            ],
          ),
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

  Future<void> _saveTask() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final viewModel = context.read<TaskViewModel>();
      bool success;
      bool? updateAllOccurrences;

      if (isEditing) {
        final originalTask = widget.task!;
        final updatedTask = originalTask.copyWith(
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim().isEmpty 
              ? null 
              : _descriptionController.text.trim(),
          date: _selectedDate,
          time: _selectedTime,
          notificationsEnabled: _notificationsEnabled,
          soundEnabled: _notificationsEnabled, // Toujours activé si les notifications sont activées
          vibrationEnabled: _notificationsEnabled, // Toujours activé si les notifications sont activées
          customSoundUri: null, // Utiliser le son système par défaut
          recurrence: _selectedRecurrence,
          categoryId: _selectedCategoryId,
        );

        // Vérifier si c'est une tâche récurrente et s'il y a des changements significatifs
        bool shouldAskUser = originalTask.recurrence != TaskRecurrence.none && 
                           _hasSignificantChanges(originalTask, updatedTask);

        if (shouldAskUser) {
          // Demander à l'utilisateur ce qu'il veut faire
          final updateChoice = await _showUpdateRecurringDialog();
          if (updateChoice == null) {
            setState(() {
              _isLoading = false;
            });
            return; // L'utilisateur a annulé
          }
          updateAllOccurrences = updateChoice;
          success = await viewModel.updateTask(updatedTask, updateAllOccurrences: updateChoice);
        } else {
          // Mise à jour normale (pas de récurrence ou changements mineurs)
          success = await viewModel.updateTask(updatedTask);
        }
      } else {
        success = await viewModel.addTask(
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim().isEmpty 
              ? null 
              : _descriptionController.text.trim(),
          date: _selectedDate,
          time: _selectedTime,
          notificationsEnabled: _notificationsEnabled,
          soundEnabled: _notificationsEnabled, // Toujours activé si les notifications sont activées
          vibrationEnabled: _notificationsEnabled, // Toujours activé si les notifications sont activées
          customSoundUri: null, // Utiliser le son système par défaut
          recurrence: _selectedRecurrence,
          categoryId: _selectedCategoryId,
        );
      }

      if (success && mounted) {
        Navigator.of(context).pop();
        
        String message;
        if (isEditing) {
          if (updateAllOccurrences == true) {
            message = TranslationService.getTranslation(context, 'editAllSuccess');
          } else {
            message = TranslationService.getTranslation(context, 'editSuccess');
          }
        } else {
          message = TranslationService.getTranslation(context, 'saveSuccess');
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: Theme.of(context).colorScheme.primary,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${TranslationService.getTranslation(context, 'error')}: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _deleteTask() async {
    final task = widget.task!;
    final isRecurringTask = task.recurrence != TaskRecurrence.none;
    
    bool? confirmed;
    bool deleteAllOccurrences = false;
    
    if (isRecurringTask) {
      // Dialogue pour tâches récurrentes avec choix
      final result = await showDialog<Map<String, bool>>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(TranslationService.getTranslation(context, 'deleteRecurringTitle')),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(TranslationService.getTranslation(context, 'deleteRecurringMessage').replaceAll('{title}', task.title)),
              const SizedBox(height: 16),
              Text(TranslationService.getTranslation(context, 'deleteRecurringChoice')),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(null),
              child: Text(TranslationService.getTranslation(context, 'cancel')),
            ),
            // "Cette seule fois" est l'option par défaut (mise en évidence)
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop({
                'confirmed': true, 
                'deleteAllOccurrences': false
              }),
              child: Text(TranslationService.getTranslation(context, 'thisTimeOnly')),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop({
                'confirmed': true, 
                'deleteAllOccurrences': true
              }),
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.error,
              ),
              child: Text(TranslationService.getTranslation(context, 'allOccurrences')),
            ),
          ],
        ),
      );
      
      if (result != null) {
        confirmed = result['confirmed'];
        deleteAllOccurrences = result['deleteAllOccurrences'] ?? false;
      }
    } else {
      // Dialogue simple pour tâches non récurrentes
      confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(TranslationService.getTranslation(context, 'deleteTaskTitle')),
          content: Text(
            TranslationService.getTranslation(context, 'deleteTaskMessage').replaceAll('{title}', task.title),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(TranslationService.getTranslation(context, 'cancel')),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(TranslationService.getTranslation(context, 'delete')),
            ),
          ],
        ),
      );
    }

    if (confirmed == true && mounted) {
      final success = await context.read<TaskViewModel>().deleteTask(
        task.id, 
        deleteAllOccurrences: deleteAllOccurrences
      );
      if (success) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(deleteAllOccurrences 
              ? TranslationService.getTranslation(context, 'deleteAllOccurrencesSuccess')
              : TranslationService.getTranslation(context, 'deleteSuccess')
            ),
            backgroundColor: Theme.of(context).colorScheme.primary,
          ),
        );
      }
    }
  }

  String _formatDate(BuildContext context, DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final taskDate = DateTime(date.year, date.month, date.day);
    
    if (taskDate == today) {
      return TranslationService.getTranslation(context, 'today');
    } else if (taskDate == today.add(const Duration(days: 1))) {
      return TranslationService.getTranslation(context, 'tomorrow');
    } else if (taskDate == today.subtract(const Duration(days: 1))) {
      return TranslationService.getTranslation(context, 'yesterday');
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  String _formatTime(TimeOfDay time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  Widget _buildNotificationSettings() {
    return SwitchListTile(
      title: Text(TranslationService.getTranslation(context, 'enableNotifications')),
      subtitle: Text(TranslationService.getTranslation(context, 'receiveNotifications')),
      value: _notificationsEnabled,
      onChanged: (value) {
        setState(() {
          _notificationsEnabled = value;
        });
      },
    );
  }

  Widget _buildRecurrenceSelector() {
    final theme = Theme.of(context);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          TranslationService.getTranslation(context, 'recurrence'),
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            border: Border.all(
              color: theme.colorScheme.outline.withOpacity(0.3),
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<TaskRecurrence>(
              value: _selectedRecurrence,
              isExpanded: true,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              onChanged: (TaskRecurrence? newValue) {
                if (newValue != null) {
                  setState(() {
                    _selectedRecurrence = newValue;
                  });
                }
              },
              items: TaskRecurrence.values.map<DropdownMenuItem<TaskRecurrence>>((TaskRecurrence value) {
                return DropdownMenuItem<TaskRecurrence>(
                  value: value,
                  child: Row(
                    children: [
                      Icon(
                        _getRecurrenceIcon(value),
                        size: 20,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 12),
                      Text(_getRecurrenceDisplayName(context, value)),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ),
        // Affichage du nombre de tâches qui seront créées
        if (_selectedRecurrence != TaskRecurrence.none) ...[
          const SizedBox(height: 8),
          Text(
            _getRecurrenceInfo(context),
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ],
    );
  }

  String _getRecurrenceInfo(BuildContext context) {
    switch (_selectedRecurrence) {
      case TaskRecurrence.none:
        return '';
      case TaskRecurrence.daily:
        return TranslationService.getTranslation(context, 'recurrenceDailyInfo');
      case TaskRecurrence.weekly:
        return TranslationService.getTranslation(context, 'recurrenceWeeklyInfo');
      case TaskRecurrence.monthly:
        return TranslationService.getTranslation(context, 'recurrenceMonthlyInfo');
      case TaskRecurrence.yearly:
        return TranslationService.getTranslation(context, 'recurrenceYearlyInfo');
    }
  }

  String _getRecurrenceDisplayName(BuildContext context, TaskRecurrence recurrence) {
    switch (recurrence) {
      case TaskRecurrence.none:
        return TranslationService.getTranslation(context, 'recurrenceNone');
      case TaskRecurrence.daily:
        return TranslationService.getTranslation(context, 'recurrenceDaily');
      case TaskRecurrence.weekly:
        return TranslationService.getTranslation(context, 'recurrenceWeekly');
      case TaskRecurrence.monthly:
        return TranslationService.getTranslation(context, 'recurrenceMonthly');
      case TaskRecurrence.yearly:
        return TranslationService.getTranslation(context, 'recurrenceYearly');
    }
  }

  IconData _getRecurrenceIcon(TaskRecurrence recurrence) {
    switch (recurrence) {
      case TaskRecurrence.none:
        return Icons.clear;
      case TaskRecurrence.daily:
        return Icons.repeat;
      case TaskRecurrence.weekly:
        return Icons.date_range;
      case TaskRecurrence.monthly:
        return Icons.calendar_month;
      case TaskRecurrence.yearly:
        return Icons.event;
    }
  }

  // Vérifier s'il y a des changements significatifs qui méritent de poser la question
  bool _hasSignificantChanges(Task original, Task updated) {
    // Vérifier les changements qui affectent toutes les occurrences
    return original.title != updated.title ||
           original.description != updated.description ||
           original.time != updated.time ||
           original.notificationsEnabled != updated.notificationsEnabled ||
           original.recurrence != updated.recurrence;
    // Note: on n'inclut pas la date car elle est spécifique à chaque occurrence
  }

  // Afficher le dialogue pour demander à l'utilisateur ce qu'il veut modifier
  Future<bool?> _showUpdateRecurringDialog() async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(TranslationService.getTranslation(context, 'modifyRecurringTitle')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(TranslationService.getTranslation(context, 'modifyRecurringMessage').replaceAll('{title}', _titleController.text.trim())),
            const SizedBox(height: 16),
            Text(TranslationService.getTranslation(context, 'modifyRecurringChoice')),
            const SizedBox(height: 8),
            Text(
              TranslationService.getTranslation(context, 'modifyRecurringExplanation'),
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(null),
            child: Text(TranslationService.getTranslation(context, 'cancel')),
          ),
          // "Cette seule fois" est l'option par défaut (mise en évidence)
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(TranslationService.getTranslation(context, 'thisTimeOnly')),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: Text(TranslationService.getTranslation(context, 'allOccurrences')),
          ),
        ],
      ),
    );
  }

}
