import 'package:flutter/material.dart';

class BarItem {
  final String label;
  final double value; // can be negative; we show magnitude
  BarItem(this.label, this.value);
}

class SimpleBarChart extends StatelessWidget {
  final List<BarItem> items;
  const SimpleBarChart({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const Text('(No features)');
    final maxAbs = items.map((e) => e.value.abs()).fold<double>(0, (a, b) => a > b ? a : b);
    return Column(
      children: items.map((e) {
        final frac = maxAbs == 0 ? 0.0 : (e.value.abs() / maxAbs);
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              SizedBox(width: 120, child: Text(e.label, overflow: TextOverflow.ellipsis)),
              Expanded(
                child: Stack(
                  children: [
                    Container(height: 18, color: Colors.black12),
                    FractionallySizedBox(
                      widthFactor: frac.clamp(0.0, 1.0),
                      child: Container(height: 18, color: Theme.of(context).colorScheme.primaryContainer),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(e.value.toStringAsFixed(2)),
            ],
          ),
        );
      }).toList(),
    );
  }
}
