import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:math' as math;
import 'design.dart';

/// مخطط دائري ملون يظهر نسبة الإنجاز والمتبقي — بأسلوب التصميم المعتمد
class ProgressPie extends StatelessWidget {
  final int done;
  final int total;
  final String label;
  const ProgressPie({super.key, required this.done, required this.total, this.label = ''});

  @override
  Widget build(BuildContext context) {
    final pct = total <= 0 ? 0.0 : math.min(done / total, 1.0);
    final pctText = (pct * 100).toStringAsFixed(0);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(children: [
          SizedBox(
            width: 104,
            height: 104,
            child: Stack(alignment: Alignment.center, children: [
              PieChart(PieChartData(
                sectionsSpace: 0,
                centerSpaceRadius: 30,
                startDegreeOffset: -90,
                sections: total <= 0
                    ? [PieChartSectionData(value: 1, color: WColors.remaining, showTitle: false)]
                    : [
                        PieChartSectionData(
                          value: math.max(pct * 100, 2),
                          color: WColors.lightGreen,
                          showTitle: false,
                          radius: 13,
                        ),
                        if (pct < 1)
                          PieChartSectionData(
                            value: 100 - math.max(pct * 100, 2),
                            color: WColors.remaining,
                            showTitle: false,
                            radius: 13,
                          ),
                      ],
              )),
              Text('$pctText٪',
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w800, color: WColors.txt)),
            ]),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              if (label.isNotEmpty) ...[
                Text(label, style: const TextStyle(
                    fontSize: 13.5, fontWeight: FontWeight.w700, color: WColors.txt)),
                const SizedBox(height: 6),
              ],
              _legend(WColors.lightGreen, 'مُنجز: $done ${pctText}٪'),
              const SizedBox(height: 4),
              _legend(WColors.remaining, 'متبقٍ: ${math.max(total - done, 0)}',
                  dark: true),
              if (total > 0)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text('الإجمالي: $total',
                      style: const TextStyle(fontSize: 11.5, color: WColors.sub)),
                ),
            ]),
          ),
        ]),
      ],
    );
  }

  static Widget _legend(Color c, String text, {bool dark = false}) => Row(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 11, height: 11,
            decoration: BoxDecoration(
                color: c, borderRadius: BorderRadius.circular(3),
                border: Border.all(color: const Color(0xFFD1D7DB)))),
        const SizedBox(width: 6),
        Text(text, style: TextStyle(fontSize: 12.5, color: dark ? WColors.sub : WColors.txt,
            fontWeight: FontWeight.w600)),
      ]);
}
