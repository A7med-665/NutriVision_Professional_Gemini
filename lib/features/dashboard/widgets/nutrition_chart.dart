import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class NutritionChart extends StatelessWidget {
  const NutritionChart({super.key, required this.protein, required this.carbs, required this.fats});
  final double protein, carbs, fats;

  @override
  Widget build(BuildContext context) {
    final proteinKcal = protein * 4;
    final carbsKcal = carbs * 4;
    final fatsKcal = fats * 9;
    final total = proteinKcal + carbsKcal + fatsKcal;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('توزيع المغذيات', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            SizedBox(
              height: 108,
              child: total <= 0
                ? const Center(child: Text('سيظهر الرسم بعد تسجيل وجباتك'))
                : PieChart(PieChartData(
                    centerSpaceRadius: 28,
                    sectionsSpace: 3,
                    sections: [
                      _section(proteinKcal, const Color(0xFF247A58)),
                      _section(carbsKcal, const Color(0xFFE7A64B)),
                      _section(fatsKcal, const Color(0xFF6F8CE8)),
                    ],
                  )),
            ),
            const SizedBox(height: 6),
            const Text(
              'تقدير الطاقة: البروتين 4، الكربوهيدرات 4، الدهون 9 سعرات/جرام. ليست نتيجة طبية.',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 11, color: Colors.black54),
            ),
          ],
        ),
      ),
    );
  }

  PieChartSectionData _section(double value, Color color) => PieChartSectionData(
    value: value <= 0 ? 0.001 : value,
    color: color,
    radius: 22,
    showTitle: false,
  );
}
