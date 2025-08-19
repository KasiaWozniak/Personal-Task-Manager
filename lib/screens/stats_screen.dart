import 'package:flutter/material.dart';
import 'package:task_manager/models/task.dart';

class StatsScreen extends StatelessWidget {
  final List<Task> tasks;
  const StatsScreen({Key? key, required this.tasks}) : super(key: key);

  int get doneCount => tasks.where((t) => t.isDone).length;

  Map<int, int> get weekDayCounts {
    final now = DateTime.now();
    final monday = now.subtract(Duration(days: now.weekday - 1));
    final sunday = monday.add(const Duration(days: 6));
    final doneTasks = tasks.where((t) => t.isDone && t.doneDate != null);
    final Map<int, int> counts = {for (var i = 1; i <= 7; i++) i: 0};
    for (final task in doneTasks) {
      try {
        final date = DateTime.parse(task.doneDate!);
        if (date.isAfter(monday.subtract(const Duration(seconds: 1))) && date.isBefore(sunday.add(const Duration(days: 1)))) {
          counts[date.weekday] = (counts[date.weekday] ?? 0) + 1;
        }
      } catch (_) {}
    }
    return counts;
  }

  String get mostProductiveDay {
    final counts = weekDayCounts;
    if (counts.values.every((v) => v == 0)) return 'Brak danych';
    final maxDay = counts.entries.reduce((a, b) => a.value >= b.value ? a : b).key;
    const days = [
      'Poniedziałek', 'Wtorek', 'Środa', 'Czwartek', 'Piątek', 'Sobota', 'Niedziela'
    ];
    return days[maxDay - 1];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Statystyki')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Wykonane zadania: $doneCount', style: TextStyle(fontSize: 20)),
            SizedBox(height: 16),
            Text('Najbardziej produktywny dzień tygodnia:', style: TextStyle(fontSize: 16)),
            Text(mostProductiveDay, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            SizedBox(height: 32),
            Text('Wykonane zadania w tym tygodniu:', style: TextStyle(fontSize: 16)),
            SizedBox(height: 16),
            SizedBox(
              height: 180,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: List.generate(7, (i) {
                  final days = ['Pon', 'Wt', 'Śr', 'Czw', 'Pt', 'Sob', 'Nd'];
                  final value = weekDayCounts[i + 1] ?? 0;
                  final maxValue = weekDayCounts.values.fold(0, (prev, v) => v > prev ? v : prev);
                  return Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Container(
                          height: maxValue > 0 ? (120 * value / maxValue) : 0,
                          width: 24,
                          decoration: BoxDecoration(
                            color: Colors.blue,
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(days[i]),
                        SizedBox(height: 4),
                        Text('$value', style: TextStyle(fontSize: 12)),
                      ],
                    ),
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
