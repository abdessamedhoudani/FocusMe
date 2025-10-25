import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../viewmodels/task_viewmodel.dart';
import '../widgets/task_tile.dart';
import '../services/translation_service.dart';
import '../models/task.dart';
import 'add_task_page.dart';
import 'stats_page.dart';
import 'settings_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  late TabController _tabController;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    
    // Initialiser le ViewModel
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TaskViewModel>().initialize();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: IndexedStack(
          index: _currentIndex,
          children: const [
            _TasksTab(),
            _StatsTab(),
            _SettingsTab(),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.task_alt),
            label: TranslationService.getTranslation(context, 'today'),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.analytics),
            label: TranslationService.getTranslation(context, 'statistics'),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.settings),
            label: TranslationService.getTranslation(context, 'settings'),
          ),
        ],
      ),
      floatingActionButton: _currentIndex == 0
          ? FloatingActionButton.extended(
              onPressed: () => _navigateToAddTask(),
              icon: const Icon(Icons.add),
              label: Text(TranslationService.getTranslation(context, 'addTask')),
            )
          : null,
    );
  }

  void _navigateToAddTask() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const AddTaskPage(),
      ),
    );
  }
}

class _TasksTab extends StatelessWidget {
  const _TasksTab();

  @override
  Widget build(BuildContext context) {
    return Consumer<TaskViewModel>(
      builder: (context, viewModel, child) {
        // Afficher l'interface même pendant le chargement
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
                  TranslationService.getTranslation(context, 'error'),
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                Text(
                  viewModel.error!,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => viewModel.loadAllTasks(),
                  child: Text(TranslationService.getTranslation(context, 'retry')),
                ),
              ],
            ),
          );
        }

        return DefaultTabController(
          length: 3,
          child: Column(
            children: [
              // Header avec résumé
              _buildHeader(context, viewModel),
              
              // Tabs
              TabBar(
                tabs: [
                  Tab(text: TranslationService.getTranslation(context, 'today')),
                  Tab(text: TranslationService.getTranslation(context, 'overdue')),
                  Tab(text: TranslationService.getTranslation(context, 'all')),
                ],
              ),
              
              // Contenu des tabs
              Expanded(
                child: TabBarView(
                  children: [
                    _buildTodayTasks(context, viewModel),
                    _buildOverdueTasks(context, viewModel),
                    _buildAllTasks(context, viewModel),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context, TaskViewModel viewModel) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colorScheme.primary.withOpacity(0.1), // Teal/vert très clair
            colorScheme.secondary.withOpacity(0.05), // Rouge très clair
            colorScheme.tertiary.withOpacity(0.1), // Jaune très clair
          ],
          stops: const [0.0, 0.5, 1.0],
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'FocusMe',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onPrimaryContainer,
                ),
              ),
              const Spacer(),
              SvgPicture.asset(
                'assets/images/logo.svg',
                width: 32,
                height: 32,
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          Row(
            children: [
              Expanded(
                child: Text(
                  viewModel.getTodaySummaryTranslated(context),
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: colorScheme.onPrimaryContainer,
                  ),
                ),
              ),
              if (viewModel.isLoading)
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
            ],
          ),
          
          const SizedBox(height: 8),
          
          Text(
            viewModel.getMotivationalMessageTranslated(context),
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onPrimaryContainer.withOpacity(0.8),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Barre de progression
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: viewModel.todayTasks.isEmpty 
                  ? 0.0 
                  : viewModel.todayCompletedTasks / viewModel.todayTasks.length,
              backgroundColor: colorScheme.onPrimaryContainer.withOpacity(0.2),
              valueColor: AlwaysStoppedAnimation<Color>(
                colorScheme.onPrimaryContainer,
              ),
              minHeight: 8,
            ),
          ),
        ],
      ),
    )
    .animate()
    .fadeIn(duration: 500.ms)
    .slideY(begin: -0.1, end: 0, duration: 500.ms);
  }

  Widget _buildTodayTasks(BuildContext context, TaskViewModel viewModel) {
    return TaskList(
      tasks: viewModel.todayTasks,
      onTaskTap: null, // Supprimé le dialogue d'infos
      onTaskToggle: (task) => viewModel.toggleTaskCompletion(task.id),
      onTaskEdit: (task) => _navigateToEditTask(context, task),
      onTaskDelete: (task) => _showDeleteDialog(context, task),
      emptyMessage: TranslationService.getTranslation(context, 'noTasksToday'),
    );
  }

  Widget _buildOverdueTasks(BuildContext context, TaskViewModel viewModel) {
    return TaskList(
      tasks: viewModel.overdueTasks,
      onTaskTap: null, // Supprimé le dialogue d'infos
      onTaskToggle: (task) => viewModel.toggleTaskCompletion(task.id),
      onTaskEdit: (task) => _navigateToEditTask(context, task),
      onTaskDelete: (task) => _showDeleteDialog(context, task),
      showDate: true, // Afficher la date pour les tâches en retard
      emptyMessage: TranslationService.getTranslation(context, 'noOverdueTasks'),
    );
  }

  Widget _buildAllTasks(BuildContext context, TaskViewModel viewModel) {
    return TaskList(
      tasks: viewModel.tasks,
      onTaskTap: null, // Supprimé le dialogue d'infos
      onTaskToggle: (task) => viewModel.toggleTaskCompletion(task.id),
      onTaskEdit: (task) => _navigateToEditTask(context, task),
      onTaskDelete: (task) => _showDeleteDialog(context, task),
      showDate: true,
      emptyMessage: TranslationService.getTranslation(context, 'noTasks'),
    );
  }

  // Méthode _showTaskDetails supprimée - plus de dialogue d'infos au clic

  void _navigateToEditTask(BuildContext context, task) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => AddTaskPage(task: task),
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, task) {
    final isRecurringTask = task.recurrence != TaskRecurrence.none;
    
    if (isRecurringTask) {
      // Dialogue pour tâches récurrentes avec choix
      showDialog(
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
              onPressed: () => Navigator.of(context).pop(),
              child: Text(TranslationService.getTranslation(context, 'cancel')),
            ),
            // "Cette seule fois" est l'option par défaut (mise en évidence)
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                context.read<TaskViewModel>().deleteTask(task.id, deleteAllOccurrences: false);
              },
              child: Text(TranslationService.getTranslation(context, 'thisTimeOnly')),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                context.read<TaskViewModel>().deleteTask(task.id, deleteAllOccurrences: true);
              },
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.error,
              ),
              child: Text(TranslationService.getTranslation(context, 'allOccurrences')),
            ),
          ],
        ),
      );
    } else {
      // Dialogue simple pour tâches non récurrentes
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(TranslationService.getTranslation(context, 'deleteTaskTitle')),
          content: Text(TranslationService.getTranslation(context, 'deleteTaskMessage').replaceAll('{title}', task.title)),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(TranslationService.getTranslation(context, 'cancel')),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                context.read<TaskViewModel>().deleteTask(task.id);
              },
              child: Text(TranslationService.getTranslation(context, 'delete')),
            ),
          ],
        ),
      );
    }
  }
}

class _StatsTab extends StatelessWidget {
  const _StatsTab();

  @override
  Widget build(BuildContext context) {
    return const StatsPage();
  }
}

class _SettingsTab extends StatelessWidget {
  const _SettingsTab();

  @override
  Widget build(BuildContext context) {
    return const SettingsPage();
  }
}
