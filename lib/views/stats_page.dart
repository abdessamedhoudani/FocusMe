import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../viewmodels/task_viewmodel.dart';
import '../widgets/statistics_card.dart';
import '../services/translation_service.dart';

class StatsPage extends StatefulWidget {
  const StatsPage({super.key});

  @override
  State<StatsPage> createState() => _StatsPageState();
}

class _StatsPageState extends State<StatsPage> {
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();
  String? _selectedPreset = 'days30';
  bool _isLoading = false;
  Map<String, dynamic> _statistics = {};
  List<Map<String, dynamic>> _dailyStats = [];

  @override
  void initState() {
    super.initState();
    _loadStatistics();
    
    // Écouter les changements du TaskViewModel
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final viewModel = context.read<TaskViewModel>();
      viewModel.addListener(_onTaskViewModelChanged);
    });
  }

  @override
  void dispose() {
    // Nettoyer l'écouteur
    final viewModel = context.read<TaskViewModel>();
    viewModel.removeListener(_onTaskViewModelChanged);
    super.dispose();
  }

  void _onTaskViewModelChanged() {
    // Actualiser les statistiques quand les tâches changent
    if (mounted) {
      _loadStatistics();
    }
  }

  Future<void> _loadStatistics() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final viewModel = context.read<TaskViewModel>();
      final stats = await viewModel.getStatistics(
        startDate: _startDate,
        endDate: _endDate,
      );
      final dailyStats = await viewModel.getDailyStatistics(
        startDate: _startDate,
        endDate: _endDate,
      );

      if (mounted) {
        setState(() {
          _statistics = stats;
          _dailyStats = dailyStats;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors du chargement: $e'),
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

  /// Vérifie si les dates actuelles correspondent à un preset
  String? _getPresetForDateRange(DateTime start, DateTime end) {
    final now = DateTime.now();
    final nowNormalized = DateTime(now.year, now.month, now.day);
    final startNormalized = DateTime(start.year, start.month, start.day);
    final endNormalized = DateTime(end.year, end.month, end.day);

    // Vérifier si la date de fin est aujourd'hui
    if (endNormalized != nowNormalized) {
      return null;
    }

    // Calculer la différence en jours
    final daysDifference = nowNormalized.difference(startNormalized).inDays;

    // Vérifier les presets exacts
    switch (daysDifference) {
      case 6: // 7 jours incluant aujourd'hui
        return 'days7';
      case 29: // 30 jours incluant aujourd'hui
        return 'days30';
      default:
        // Pour les mois, vérifier si les dates correspondent exactement 
        // à ce que génère la sélection de preset
        if (_isDays30Preset(startNormalized, nowNormalized)) {
          return 'days30';
        } else if (_isDays7Preset(startNormalized, nowNormalized)) {
          return 'days7';
        } else if (_is3MonthsPreset(start, now)) {
          return 'months3';
        } else if (_is6MonthsPreset(start, now)) {
          return 'months6';
        }
        return null;
    }
  }

  bool _isDays7Preset(DateTime start, DateTime end) {
    final expectedStart = end.subtract(const Duration(days: 7));
    return _isSameDay(start, expectedStart);
  }

  bool _isDays30Preset(DateTime start, DateTime end) {
    final expectedStart = end.subtract(const Duration(days: 30));
    return _isSameDay(start, expectedStart);
  }

  bool _is3MonthsPreset(DateTime start, DateTime end) {
    final expectedStart = DateTime(end.year, end.month - 3, end.day);
    return _isSameDay(start, expectedStart);
  }

  bool _is6MonthsPreset(DateTime start, DateTime end) {
    final expectedStart = DateTime(end.year, end.month - 6, end.day);
    return _isSameDay(start, expectedStart);
  }

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year && 
           date1.month == date2.month && 
           date1.day == date2.day;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(TranslationService.getTranslation(context, 'statistics')),
        actions: [
          IconButton(
            onPressed: _loadStatistics,
            icon: const Icon(Icons.refresh),
            tooltip: 'Actualiser',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadStatistics,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Sélecteur de période
                    DateRangeSelector(
                      startDate: _startDate,
                      endDate: _endDate,
                      onDateRangeChanged: (start, end) {
                        setState(() {
                          _startDate = start;
                          _endDate = end;
                          // Vérifier si les nouvelles dates correspondent à un preset
                          _selectedPreset = _getPresetForDateRange(start, end);
                        });
                        _loadStatistics();
                      },
                      onPresetSelected: (preset) {
                        setState(() {
                          _selectedPreset = preset;
                        });
                      },
                      presetRanges: const ['days7', 'days30', 'months3', 'months6'],
                      selectedPreset: _selectedPreset,
                    ),
                    
                    const SizedBox(height: 32),
                    
                    // Cartes de statistiques
                    _buildStatisticsCards(),
                    
                    const SizedBox(height: 32),
                    
                    // Graphique de progression
                    _buildProgressChart(),
                    
                    const SizedBox(height: 32),
                    
                    // Graphique quotidien
                    _buildDailyChart(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildStatisticsCards() {
    final totalCreated = _statistics['totalCreated'] ?? 0;
    final totalCompleted = _statistics['totalCompleted'] ?? 0;
    final totalOverdue = _statistics['totalOverdue'] ?? 0;
    final completionRate = totalCreated > 0 ? (totalCompleted / totalCreated) * 100 : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          TranslationService.getTranslation(context, 'periodSummary'),
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1.2,
          children: [
            StatisticsCard(
              title: TranslationService.getTranslation(context, 'tasksCreated'),
              value: totalCreated.toString(),
              icon: Icons.add_task,
              color: Theme.of(context).colorScheme.primary,
            ),
            StatisticsCard(
              title: TranslationService.getTranslation(context, 'tasksCompleted'),
              value: totalCompleted.toString(),
              icon: Icons.check_circle,
              color: Theme.of(context).colorScheme.tertiary,
            ),
            StatisticsCard(
              title: TranslationService.getTranslation(context, 'successRate'),
              value: '${completionRate.round()}%',
              icon: Icons.trending_up,
              color: Theme.of(context).colorScheme.secondary,
            ),
            StatisticsCard(
              title: TranslationService.getTranslation(context, 'overdueTasks'),
              value: totalOverdue.toString(),
              icon: Icons.warning,
              color: Theme.of(context).colorScheme.error,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildProgressChart() {
    final totalCreated = _statistics['totalCreated'] ?? 0;
    final totalCompleted = _statistics['totalCompleted'] ?? 0;
    final totalOverdue = _statistics['totalOverdue'] ?? 0;
    final pending = totalCreated - totalCompleted - totalOverdue;

    if (totalCreated == 0) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          TranslationService.getTranslation(context, 'taskDistribution'),
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 200,
          child: PieChart(
            PieChartData(
              sections: [
                PieChartSectionData(
                  value: totalCompleted.toDouble(),
                  title: 'Terminées\n$totalCompleted',
                  color: Theme.of(context).colorScheme.tertiary,
                  radius: 60,
                  titleStyle: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                PieChartSectionData(
                  value: pending.toDouble(),
                  title: 'En attente\n$pending',
                  color: Theme.of(context).colorScheme.primary,
                  radius: 60,
                  titleStyle: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                PieChartSectionData(
                  value: totalOverdue.toDouble(),
                  title: '${TranslationService.getTranslation(context, 'overdue')}\n$totalOverdue',
                  color: Theme.of(context).colorScheme.error,
                  radius: 60,
                  titleStyle: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
              sectionsSpace: 2,
              centerSpaceRadius: 40,
            ),
          ),
        ),
      ],
    )
    .animate()
    .fadeIn(duration: 500.ms)
    .scale(begin: const Offset(0.8, 0.8), end: const Offset(1, 1), duration: 500.ms);
  }

  Widget _buildDailyChart() {
    if (_dailyStats.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          TranslationService.getTranslation(context, 'dailyProgress'),
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
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
                topTitles: AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                rightTitles: AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      if (value.toInt() % 5 == 0) {
                        final date = DateTime.parse(_dailyStats[value.toInt()]['day']);
                        return Text(
                          '${date.day}/${date.month}',
                          style: const TextStyle(fontSize: 10),
                        );
                      }
                      return const Text('');
                    },
                  ),
                ),
              ),
              borderData: FlBorderData(show: true),
              lineBarsData: [
                LineChartBarData(
                  spots: _dailyStats.asMap().entries.map((entry) {
                    final index = entry.key;
                    final data = entry.value;
                    return FlSpot(index.toDouble(), (data['completed'] as int).toDouble());
                  }).toList(),
                  isCurved: true,
                  color: Theme.of(context).colorScheme.primary,
                  barWidth: 3,
                  dotData: FlDotData(show: false),
                  belowBarData: BarAreaData(
                    show: true,
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    )
    .animate()
    .fadeIn(duration: 500.ms)
    .slideX(begin: 0.1, end: 0, duration: 500.ms);
  }
}
