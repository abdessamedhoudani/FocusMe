import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../viewmodels/task_viewmodel.dart';
import '../models/task.dart';
import '../widgets/task_tile.dart';
import 'add_task_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  late TabController _tabController;
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            _buildSliverAppBar(context),
            _buildDateSelector(context),
            _buildStatsHeader(context),
          ];
        },
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildTasksList(context),
            _buildCompletedTasksList(context),
          ],
        ),
      ),
      floatingActionButton: _buildFloatingActionButton(context),
      bottomNavigationBar: _buildBottomNavigationBar(context),
    );
  }

  Widget _buildSliverAppBar(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return SliverAppBar(
      expandedHeight: 120,
      floating: false,
      pinned: true,
      backgroundColor: colorScheme.primaryContainer,
      foregroundColor: colorScheme.onPrimaryContainer,
      flexibleSpace: FlexibleSpaceBar(
        title: Text(
          'FocusMe',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: colorScheme.onPrimaryContainer,
          ),
        ),
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                colorScheme.primaryContainer,
                colorScheme.primaryContainer.withOpacity(0.8),
              ],
            ),
          ),
          child: Center(
            child: Icon(
              Icons.task_alt,
              size: 60,
              color: colorScheme.onPrimaryContainer.withOpacity(0.3),
            ),
          ),
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: () => context.read<TaskViewModel>().refresh(),
        ),
        PopupMenuButton<String>(
          onSelected: (value) {
            switch (value) {
              case 'sample':
                context.read<TaskViewModel>().addSampleTasks();
                break;
              case 'cleanup':
                context.read<TaskViewModel>().cleanupOldTasks();
                break;
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'sample',
              child: Row(
                children: [
                  Icon(Icons.add_task),
                  SizedBox(width: 8),
                  Text('Ajouter des exemples'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'cleanup',
              child: Row(
                children: [
                  Icon(Icons.cleaning_services),
                  SizedBox(width: 8),
                  Text('Nettoyer les anciennes tâches'),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDateSelector(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: colorScheme.shadow.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(
              Icons.calendar_today,
              color: colorScheme.primary,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Date sélectionnée',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    DateFormat('EEEE, d MMMM yyyy', 'fr_FR').format(_selectedDate),
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            FilledButton.icon(
              onPressed: _selectDate,
              icon: const Icon(Icons.edit_calendar),
              label: const Text('Changer'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsHeader(BuildContext context) {
    return Consumer<TaskViewModel>(
      builder: (context, viewModel, child) {
        final theme = Theme.of(context);
        final colorScheme = theme.colorScheme;
        final selectedDateTasks = viewModel.selectedDateTasks;
        final completedCount = selectedDateTasks.where((t) => t.isCompleted).length;
        final totalCount = selectedDateTasks.length;
        final completionRate = totalCount > 0 ? completedCount / totalCount : 0.0;

        return SliverToBoxAdapter(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  colorScheme.primaryContainer,
                  colorScheme.secondaryContainer,
                ],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    context,
                    'Tâches',
                    '$completedCount/$totalCount',
                    Icons.task_alt,
                    colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatCard(
                    context,
                    'Progression',
                    '${(completionRate * 100).toInt()}%',
                    Icons.trending_up,
                    colorScheme.secondary,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    final theme = Theme.of(context);
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTasksList(BuildContext context) {
    return Consumer<TaskViewModel>(
      builder: (context, viewModel, child) {
        if (viewModel.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (viewModel.error != null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 64,
                  color: Theme.of(context).colorScheme.error,
                ),
                const SizedBox(height: 16),
                Text(
                  viewModel.error!,
                  style: Theme.of(context).textTheme.bodyLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () => viewModel.refresh(),
                  child: const Text('Réessayer'),
                ),
              ],
            ),
          );
        }

        final tasks = viewModel.selectedDateTasks.where((t) => !t.isCompleted).toList();
        
        if (tasks.isEmpty) {
          return _buildEmptyState(
            context,
            'Aucune tâche en cours',
            'Ajoutez une nouvelle tâche pour commencer',
            Icons.task_alt_outlined,
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.only(top: 16),
          itemCount: tasks.length,
          itemBuilder: (context, index) {
            final task = tasks[index];
            return AnimatedTaskTile(
              key: ValueKey(task.id),
              task: task,
              onTap: () => _editTask(context, task),
              onToggle: () => viewModel.toggleTaskCompletion(task.id),
              onDelete: () => viewModel.deleteTask(task.id),
            );
          },
        );
      },
    );
  }

  Widget _buildCompletedTasksList(BuildContext context) {
    return Consumer<TaskViewModel>(
      builder: (context, viewModel, child) {
        final tasks = viewModel.selectedDateTasks.where((t) => t.isCompleted).toList();
        
        if (tasks.isEmpty) {
          return _buildEmptyState(
            context,
            'Aucune tâche terminée',
            'Terminez vos tâches pour les voir ici',
            Icons.check_circle_outline,
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.only(top: 16),
          itemCount: tasks.length,
          itemBuilder: (context, index) {
            final task = tasks[index];
            return AnimatedTaskTile(
              key: ValueKey(task.id),
              task: task,
              onTap: () => _editTask(context, task),
              onToggle: () => viewModel.toggleTaskCompletion(task.id),
              onDelete: () => viewModel.deleteTask(task.id),
            );
          },
        );
      },
    );
  }

  Widget _buildEmptyState(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 80,
            color: colorScheme.onSurfaceVariant.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: theme.textTheme.headlineSmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingActionButton(BuildContext context) {
    return FloatingActionButton.extended(
      onPressed: () => _addTask(context),
      icon: const Icon(Icons.add),
      label: const Text('Nouvelle tâche'),
    );
  }

  Widget _buildBottomNavigationBar(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: TabBar(
        controller: _tabController,
        labelColor: colorScheme.primary,
        unselectedLabelColor: colorScheme.onSurfaceVariant,
        indicatorColor: colorScheme.primary,
        tabs: const [
          Tab(
            icon: Icon(Icons.pending_actions),
            text: 'En cours',
          ),
          Tab(
            icon: Icon(Icons.check_circle),
            text: 'Terminées',
          ),
        ],
      ),
    );
  }

  Future<void> _selectDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    
    if (date != null) {
      setState(() {
        _selectedDate = date;
      });
      context.read<TaskViewModel>().setSelectedDate(date);
    }
  }

  void _addTask(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const AddTaskPage(),
      ),
    );
  }

  void _editTask(BuildContext context, Task task) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => AddTaskPage(task: task),
      ),
    );
  }
}
