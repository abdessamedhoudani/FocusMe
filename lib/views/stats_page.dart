import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../viewmodels/task_viewmodel.dart';

class StatsPage extends StatefulWidget {
  const StatsPage({super.key});

  @override
  State<StatsPage> createState() => _StatsPageState();
}

class _StatsPageState extends State<StatsPage> with TickerProviderStateMixin {
  late TabController _tabController;
  String _selectedPeriod = 'week';
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Statistiques'),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        foregroundColor: Theme.of(context).colorScheme.onPrimaryContainer,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Theme.of(context).colorScheme.onPrimaryContainer,
          unselectedLabelColor: Theme.of(context).colorScheme.onPrimaryContainer.withOpacity(0.7),
          indicatorColor: Theme.of(context).colorScheme.onPrimaryContainer,
          tabs: const [
            Tab(icon: Icon(Icons.trending_up), text: 'Progression'),
            Tab(icon: Icon(Icons.pie_chart), text: 'Répartition'),
            Tab(icon: Icon(Icons.calendar_month), text: 'Historique'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildProgressTab(),
          _buildDistributionTab(),
          _buildHistoryTab(),
        ],
      ),
    );
  }

  Widget _buildProgressTab() {
    return Consumer<TaskViewModel>(
      builder: (context, viewModel, child) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildPeriodSelector(),
              const SizedBox(height: 24),
              _buildProgressChart(viewModel),
              const SizedBox(height: 24),
              _buildProgressStats(viewModel),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDistributionTab() {
    return Consumer<TaskViewModel>(
      builder: (context, viewModel, child) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildCompletionRateCard(viewModel),
              const SizedBox(height: 24),
              _buildTasksDistributionChart(viewModel),
              const SizedBox(height: 24),
              _buildDetailedStats(viewModel),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHistoryTab() {
    return Consumer<TaskViewModel>(
      builder: (context, viewModel, child) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDateRangeSelector(),
              const SizedBox(height: 24),
              _buildHistoryChart(viewModel),
              const SizedBox(height: 24),
              _buildHistoryList(viewModel),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPeriodSelector() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Période d\'analyse',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(
                  value: 'week',
                  label: Text('Semaine'),
                  icon: Icon(Icons.calendar_view_week),
                ),
                ButtonSegment(
                  value: 'month',
                  label: Text('Mois'),
                  icon: Icon(Icons.calendar_month),
                ),
                ButtonSegment(
                  value: 'year',
                  label: Text('Année'),
                  icon: Icon(Icons.calendar_today),
                ),
              ],
              selected: {_selectedPeriod},
              onSelectionChanged: (Set<String> selection) {
                setState(() {
                  _selectedPeriod = selection.first;
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressChart(TaskViewModel viewModel) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    final period = _getPeriodDates();
    final stats = viewModel.getStatsForPeriod(period['start']!, period['end']!);
    
    final spots = <FlSpot>[];
    int index = 0;
    
    for (var date = period['start']!; 
         date.isBefore(period['end']!.add(const Duration(days: 1))); 
         date = date.add(const Duration(days: 1))) {
      final completed = stats[date] ?? 0;
      spots.add(FlSpot(index.toDouble(), completed.toDouble()));
      index++;
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Progression des tâches terminées',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(show: true),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: true),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final date = period['start']!.add(Duration(days: value.toInt()));
                          return Text(
                            DateFormat('dd/MM').format(date),
                            style: theme.textTheme.bodySmall,
                          );
                        },
                      ),
                    ),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: true),
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: true,
                      color: colorScheme.primary,
                      barWidth: 3,
                      dotData: FlDotData(show: true),
                      belowBarData: BarAreaData(
                        show: true,
                        color: colorScheme.primary.withOpacity(0.1),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressStats(TaskViewModel viewModel) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    final period = _getPeriodDates();
    final stats = viewModel.getStatsForPeriod(period['start']!, period['end']!);
    
    final totalCompleted = stats.values.fold(0, (sum, count) => sum + count);
    final averagePerDay = stats.isNotEmpty ? totalCompleted / stats.length : 0.0;
    final bestDay = stats.isNotEmpty 
        ? stats.entries.reduce((a, b) => a.value > b.value ? a : b)
        : null;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Résumé de la période',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    'Total terminées',
                    totalCompleted.toString(),
                    Icons.check_circle,
                    colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatItem(
                    'Moyenne/jour',
                    averagePerDay.toStringAsFixed(1),
                    Icons.trending_up,
                    colorScheme.secondary,
                  ),
                ),
              ],
            ),
            if (bestDay != null) ...[
              const SizedBox(height: 16),
              _buildStatItem(
                'Meilleur jour',
                '${bestDay.value} tâches le ${DateFormat('dd/MM').format(bestDay.key)}',
                Icons.star,
                colorScheme.tertiary,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCompletionRateCard(TaskViewModel viewModel) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final completionRate = viewModel.completionRate;
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              'Taux de completion',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 120,
              child: Stack(
                children: [
                  Center(
                    child: SizedBox(
                      height: 100,
                      width: 100,
                      child: CircularProgressIndicator(
                        value: completionRate,
                        strokeWidth: 8,
                        backgroundColor: colorScheme.surfaceVariant,
                        valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
                      ),
                    ),
                  ),
                  Center(
                    child: Text(
                      '${(completionRate * 100).toInt()}%',
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${viewModel.completedTasksCount} sur ${viewModel.totalTasks} tâches',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTasksDistributionChart(TaskViewModel viewModel) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Répartition des tâches',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: PieChart(
                PieChartData(
                  sections: [
                    PieChartSectionData(
                      value: viewModel.completedTasksCount.toDouble(),
                      title: 'Terminées',
                      color: colorScheme.primary,
                      radius: 60,
                      titleStyle: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    PieChartSectionData(
                      value: viewModel.pendingTasksCount.toDouble(),
                      title: 'En cours',
                      color: colorScheme.secondary,
                      radius: 60,
                      titleStyle: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                  centerSpaceRadius: 40,
                  sectionsSpace: 2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailedStats(TaskViewModel viewModel) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Statistiques détaillées',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            _buildStatItem(
              'Tâches créées',
              viewModel.totalTasks.toString(),
              Icons.add_task,
              colorScheme.primary,
            ),
            const SizedBox(height: 12),
            _buildStatItem(
              'Tâches terminées',
              viewModel.completedTasksCount.toString(),
              Icons.check_circle,
              colorScheme.primary,
            ),
            const SizedBox(height: 12),
            _buildStatItem(
              'Tâches en cours',
              viewModel.pendingTasksCount.toString(),
              Icons.pending_actions,
              colorScheme.secondary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateRangeSelector() {
    final theme = Theme.of(context);
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Période d\'analyse',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _selectStartDate,
                    icon: const Icon(Icons.calendar_today),
                    label: Text(DateFormat('dd/MM/yyyy').format(_selectedDate)),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _selectEndDate,
                    icon: const Icon(Icons.calendar_today),
                    label: Text(DateFormat('dd/MM/yyyy').format(_selectedDate.add(const Duration(days: 7)))),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryChart(TaskViewModel viewModel) {
    // Implémentation similaire à _buildProgressChart mais pour l'historique
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Historique des performances',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            const Center(
              child: Text('Graphique d\'historique à implémenter'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryList(TaskViewModel viewModel) {
    final theme = Theme.of(context);
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Historique récent',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            const Center(
              child: Text('Liste d\'historique à implémenter'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String title, String value, IconData icon, Color color) {
    final theme = Theme.of(context);
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                Text(
                  value,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Map<String, DateTime> _getPeriodDates() {
    final now = DateTime.now();
    
    switch (_selectedPeriod) {
      case 'week':
        return {
          'start': now.subtract(const Duration(days: 7)),
          'end': now,
        };
      case 'month':
        return {
          'start': now.subtract(const Duration(days: 30)),
          'end': now,
        };
      case 'year':
        return {
          'start': now.subtract(const Duration(days: 365)),
          'end': now,
        };
      default:
        return {
          'start': now.subtract(const Duration(days: 7)),
          'end': now,
        };
    }
  }

  Future<void> _selectStartDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
    );
    
    if (date != null) {
      setState(() {
        _selectedDate = date;
      });
    }
  }

  Future<void> _selectEndDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate.add(const Duration(days: 7)),
      firstDate: _selectedDate,
      lastDate: DateTime.now(),
    );
    
    if (date != null) {
      setState(() {
        _selectedDate = date.subtract(const Duration(days: 7));
      });
    }
  }
}
