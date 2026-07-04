import 'package:flutter/material.dart';

import '../models.dart';
import '../widgets/performance_chart.dart';

class ProgressPage extends StatelessWidget {
  const ProgressPage({super.key, required this.records});

  final List<WorkoutRecord> records;

  @override
  Widget build(BuildContext context) {
    final exercises = records.map((record) => record.exercise).toSet().toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Padding(
          padding: EdgeInsets.only(bottom: 12),
          child: Text('진행 그래프', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
        ),
        Container(
          margin: const EdgeInsets.only(bottom: 18),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('최근 운동 기록', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
              const SizedBox(height: 12),
              SizedBox(height: 220, child: PerformanceChart(records: records)),
            ],
          ),
        ),
        const Text('운동 별 추세', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
        const SizedBox(height: 10),
        ...exercises.map((name) {
          final weights = records.where((r) => r.exercise == name).map((r) => r.weight).toList();
          final latest = weights.isNotEmpty ? weights.last : 0;
          return Card(
            color: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            margin: const EdgeInsets.only(bottom: 10),
            child: ListTile(
              title: Text(name, style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
              subtitle: Text('최근 중량: ${latest}kg', style: const TextStyle(color: Colors.black54)),
            ),
          );
        }),
      ],
    );
  }
}
