import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:focus_me/main.dart';
import 'package:focus_me/viewmodels/task_viewmodel.dart';

void main() {
  group('FocusMe App Tests', () {
    testWidgets('App should start without crashing', (WidgetTester tester) async {
      // Build our app and trigger a frame.
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => TaskViewModel()),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: Center(
                child: Text('FocusMe Test'),
              ),
            ),
          ),
        ),
      );

      // Verify that the app starts
      expect(find.text('FocusMe Test'), findsOneWidget);
    });

    testWidgets('TaskViewModel should initialize correctly', (WidgetTester tester) async {
      final viewModel = TaskViewModel();
      
      // Test initial state
      expect(viewModel.isLoading, false);
      expect(viewModel.error, null);
      expect(viewModel.tasks, isEmpty);
      expect(viewModel.totalTasks, 0);
      expect(viewModel.completedTasksCount, 0);
      expect(viewModel.pendingTasksCount, 0);
      expect(viewModel.completionRate, 0.0);
    });
  });
}
