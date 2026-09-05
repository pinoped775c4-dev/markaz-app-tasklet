import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:math' as math;

/// مخطط دائري ملون يظهر نسبة الإنجاز والمتبقي
class ProgressPie extends StatelessWidget {
  final int done;
  final int total;
  final String label;
  const ProgressPie({super.key, required this.done, required this.total, this.label = ''});

  @override
  Widget build(BuildContext context) {
    final pct = total <= 0 ? 0.0 : math.min(done / total, 1.0);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 120,
          height: 120,
          child: Stack(alignment: Alignment.center, children: [
            PieChart(PieChartData(
              sectionsSpace: 2,
              centerSpaceRadius: 34,
              startDegreeOffset: -90,
              sections: total <= 0
                  ? [PieChartSectionData(value: 1, color: Colors.grey.shade300, showTitle: false)]
                  : [
                      PieChartSectionData(
                        value: pct * 100,
                        color: Colors.green,
                        title: '${(pct * 100).toStringAsFixed(0)}%',
                        titleStyle: const TextStyle(
                            fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      if (pct < 1)
                        PieChartSectionData(
                          value: (1 - pct) * 100,
                          color: Colors.red.shade300,
                          title: '${((1 - pct) * 100).toStringAsFixed(0)}%',
                          titleStyle: const TextStyle(
                              fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                    ],
            )),
            Text('$done\nمن $total', textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
          ]),
        ),
        if (label.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(label, style: Theme.of(context).textTheme.bodySmall),
          ),
        Row(mainAxisSize: MainAxisSize.min, children: [
          _dot(Colors.green, 'منجز: $done'),
          const SizedBox(width: 10),
          _dot(Colors.red.shade300!, 'متبقٍ: ${total - done < 0 ? 0 : total - done}'),
        ]),
      ],
    );
  }

  static Widget _dot(Color c, String text) => Row(mainAxisSize: MainAxisSize.min, children: [
        CircleAvatar(radius: 4, backgroundColor: c),
        const SizedBox(width: 3),
        Text(text, style: const TextStyle(fontSize: 11)),
      ]);
}
