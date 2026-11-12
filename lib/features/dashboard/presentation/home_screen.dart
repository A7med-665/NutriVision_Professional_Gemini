import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../core/config/app_config.dart';
import '../../../core/theme/app_theme.dart';
import '../../meals/domain/meal.dart';
import '../../meals/presentation/add_meal_screen.dart';
import '../../meals/presentation/meal_cubit.dart';
import '../../meals/presentation/meal_history_screen.dart';
import '../../recipes/presentation/recipe_generator_screen.dart';
import '../../recipes/presentation/snack_alternatives_screen.dart';
import '../widgets/nutrition_chart.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) => BlocProvider(
        create: (_) => MealCubit()..startWatching(),
        child: const _Dashboard(),
      );
}

class _Dashboard extends StatelessWidget {
  const _Dashboard();

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Row(
            children: [
              Icon(Icons.eco_rounded, color: AppTheme.green),
              SizedBox(width: 8),
              Text('NutriVision', style: TextStyle(fontWeight: FontWeight.w800)),
            ],
          ),
          actions: [
            IconButton(
              tooltip: 'بدائل الوجبات الخفيفة',
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SnackAlternativesScreen()),
              ),
              icon: const Icon(Icons.auto_awesome),
            ),
            IconButton(
              tooltip: 'اقتراح وصفة',
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const RecipeGeneratorScreen()),
              ),
              icon: const Icon(Icons.soup_kitchen_outlined),
            ),
            if (AppConfig.firebaseReady)
              IconButton(
                tooltip: 'تسجيل الخروج',
                onPressed: () async {
                  await FirebaseAuth.instance.signOut();
                },
                icon: const Icon(Icons.logout),
              ),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => BlocProvider.value(
                value: context.read<MealCubit>(),
                child: const AddMealScreen(),
              ),
            ),
          ),
          icon: const Icon(Icons.add),
          label: const Text('إضافة وجبة'),
        ),
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) => BlocBuilder<MealCubit, MealState>(
              builder: (context, state) {
                final now = DateTime.now();
                final todayMeals = state.meals.where((meal) =>
                    meal.createdAt.year == now.year &&
                    meal.createdAt.month == now.month &&
                    meal.createdAt.day == now.day).toList(growable: false);
                final calories = todayMeals.fold<double>(0, (sum, meal) => sum + meal.calories);
                final protein = todayMeals.fold<double>(0, (sum, meal) => sum + meal.protein);
                final carbs = todayMeals.fold<double>(0, (sum, meal) => sum + meal.carbs);
                final fats = todayMeals.fold<double>(0, (sum, meal) => sum + meal.fats);
                final wide = constraints.maxWidth >= 760;

                return SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        DateFormat('EEEE, d MMMM').format(now),
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'صحتك تبدأ باختيارك',
                        style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: AppTheme.ink),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'تابع وجباتك وافهم عاداتك الغذائية خطوة بخطوة.',
                        style: TextStyle(color: Colors.grey.shade700),
                      ),
                      if (!AppConfig.firebaseReady) ...[
                        const SizedBox(height: 12),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF3D8),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(Icons.info_outline, color: Color(0xFF8A5A00)),
                              SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'أنت في الوضع التجريبي: تُحفظ الوجبات في الذاكرة فقط وقد تختفي عند إغلاق التطبيق. أعد إعداد Firebase لتفعيل الحسابات والمزامنة السحابية.',
                                  style: TextStyle(color: Color(0xFF704A00), height: 1.4),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 22),
                      _HeroCard(calories: calories, meals: todayMeals.length),
                      const SizedBox(height: 18),
                      if (wide)
                        GridView.extent(
                          maxCrossAxisExtent: 520,
                          mainAxisExtent: 260,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          children: [
                            _Macros(protein: protein, carbs: carbs, fats: fats),
                            NutritionChart(protein: protein, carbs: carbs, fats: fats),
                          ],
                        )
                      else ...[
                        _Macros(protein: protein, carbs: carbs, fats: fats),
                        const SizedBox(height: 16),
                        NutritionChart(protein: protein, carbs: carbs, fats: fats),
                      ],
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('سجل الوجبات', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                          TextButton(
                            onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => BlocProvider.value(
                                  value: context.read<MealCubit>(),
                                  child: const MealHistoryScreen(),
                                ),
                              ),
                            ),
                            child: const Text('عرض الكل'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (state.error != null) _Notice(text: state.error!),
                      if (state.loading && state.meals.isEmpty)
                        const Center(child: Padding(padding: EdgeInsets.all(28), child: CircularProgressIndicator())),
                      if (!state.loading && state.meals.isEmpty) const _EmptyMeals(),
                      ...state.meals.take(8).map(
                        (meal) => Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
                            leading: Container(
                              width: 46,
                              height: 46,
                              decoration: BoxDecoration(
                                color: AppTheme.green.withValues(alpha: .10),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: const Icon(Icons.restaurant, color: AppTheme.green),
                            ),
                            title: Text(meal.name, style: const TextStyle(fontWeight: FontWeight.w700)),
                            subtitle: Text(DateFormat('h:mm a').format(meal.createdAt)),
                            trailing: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text('${meal.calories.round()} kcal', style: const TextStyle(fontWeight: FontWeight.bold)),
                                const Text('سعرة حرارية', style: TextStyle(fontSize: 10)),
                              ],
                            ),
                            onTap: () => showModalBottomSheet<void>(
                              context: context,
                              isScrollControlled: true,
                              builder: (_) => _MealDetails(meal: meal),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      );
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.calories, required this.meals});
  final double calories;
  final int meals;

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [Color(0xFF1D7653), Color(0xFF32966A)]),
          borderRadius: BorderRadius.circular(26),
        ),
        child: Stack(
          children: [
            Positioned(
              right: -8,
              bottom: -16,
              child: Icon(Icons.spa, size: 112, color: Colors.white.withValues(alpha: .12)),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('إجمالي السعرات المسجلة اليوم', style: TextStyle(color: Colors.white70)),
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(calories.round().toString(), style: const TextStyle(color: Colors.white, fontSize: 40, fontWeight: FontWeight.w800)),
                    const Padding(
                      padding: EdgeInsets.only(bottom: 7, left: 8),
                      child: Text('kcal', style: TextStyle(color: Colors.white70)),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(color: Colors.white.withValues(alpha: .16), borderRadius: BorderRadius.circular(30)),
                  child: Text('$meals وجبات مسجلة • الرقم اليومي مرجعي وليس هدفًا شخصيًا', style: const TextStyle(color: Colors.white, fontSize: 12)),
                ),
              ],
            ),
          ],
        ),
      );
}

class _Macros extends StatelessWidget {
  const _Macros({required this.protein, required this.carbs, required this.fats});
  final double protein;
  final double carbs;
  final double fats;

  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('المغذيات الكبرى', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              _MacroRow(label: 'البروتين', value: protein, color: const Color(0xFF247A58)),
              const SizedBox(height: 13),
              _MacroRow(label: 'الكربوهيدرات', value: carbs, color: const Color(0xFFE7A64B)),
              const SizedBox(height: 13),
              _MacroRow(label: 'الدهون', value: fats, color: const Color(0xFF6F8CE8)),
            ],
          ),
        ),
      );
}

class _MacroRow extends StatelessWidget {
  const _MacroRow({required this.label, required this.value, required this.color});
  final String label;
  final double value;
  final Color color;

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 9),
          Expanded(child: Text(label)),
          Text('${value.round()} g', style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      );
}

class _EmptyMeals extends StatelessWidget {
  const _EmptyMeals();

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
        child: const Column(
          children: [
            Icon(Icons.no_meals_outlined, size: 38, color: AppTheme.green),
            SizedBox(height: 8),
            Text('لا توجد وجبات حتى الآن', style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(height: 4),
            Text('أضف أول وجبة لتبدأ متابعة تغذيتك.', textAlign: TextAlign.center),
          ],
        ),
      );
}

class _Notice extends StatelessWidget {
  const _Notice({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Text(text, style: TextStyle(color: Theme.of(context).colorScheme.error)),
      );
}

class _MealDetails extends StatelessWidget {
  const _MealDetails({required this.meal});
  final Meal meal;

  @override
  Widget build(BuildContext context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(meal.name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                Text('الكمية المسجلة: ${meal.portionGrams.round()} جم', style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.w600)),
                const SizedBox(height: 14),
                Wrap(spacing: 8, runSpacing: 8, children: [
                  _nutrientChip('السعرات', '${meal.calories.round()} kcal'),
                  _nutrientChip('البروتين', '${meal.protein.toStringAsFixed(1)} g'),
                  _nutrientChip('الكربوهيدرات', '${meal.carbs.toStringAsFixed(1)} g'),
                  _nutrientChip('الدهون', '${meal.fats.toStringAsFixed(1)} g'),
                  _nutrientChip('الألياف', '${meal.fiber.toStringAsFixed(1)} g'),
                  _nutrientChip('السكر', '${meal.sugar.toStringAsFixed(1)} g'),
                  _nutrientChip('الصوديوم', '${meal.sodiumMg.round()} mg'),
                  _nutrientChip('دهون مشبعة', '${meal.saturatedFat.toStringAsFixed(1)} g'),
                  _nutrientChip('الكوليسترول', '${meal.cholesterolMg.round()} mg'),
                ]),
                const SizedBox(height: 12),
                Text('مصدر القيم: ${meal.nutritionSource} ', style: const TextStyle(fontSize: 11, color: Colors.black54)),
                const SizedBox(height: 12),
                Text(meal.notes.isEmpty ? 'لا توجد ملاحظات إضافية.' : meal.notes),
                const SizedBox(height: 18),
                const Text('اقتراحات NutriVision', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text(meal.advice.isEmpty ? 'أضف الوجبة لتحصل على إرشادات عامة.' : meal.advice),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      );

  Widget _nutrientChip(String label, String value) => Chip(
    label: Text('$label: $value'),
    visualDensity: VisualDensity.compact,
  );
}
