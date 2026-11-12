import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import 'meal_cubit.dart';
import '../domain/meal.dart';

class MealHistoryScreen extends StatelessWidget {
  const MealHistoryScreen({super.key});

  Future<void> _confirmDelete(BuildContext context, Meal meal) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('حذف الوجبة؟'),
        content: Text('سيتم حذف "${meal.name}" من سجل الوجبات.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('إلغاء')),
          FilledButton.tonal(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('حذف')),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    try {
      await context.read<MealCubit>().deleteMeal(meal);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم حذف الوجبة.')));
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تعذر حذف الوجبة. حاول مرة أخرى.')));
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('سجل الوجبات')),
        body: SafeArea(
          child: BlocBuilder<MealCubit, MealState>(
            builder: (context, state) {
              if (state.loading && state.meals.isEmpty) {
                return const Center(child: CircularProgressIndicator());
              }
              if (state.meals.isEmpty) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.no_meals_outlined, size: 48, color: AppTheme.green),
                      SizedBox(height: 12),
                      Text('لا توجد وجبات مسجلة بعد', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                      SizedBox(height: 6),
                      Text('ستظهر وجباتك هنا بعد إضافتها.', textAlign: TextAlign.center),
                    ]),
                  ),
                );
              }
              return ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: state.meals.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final meal = state.meals[index];
                  return Card(
                    child: ListTile(
                      leading: const CircleAvatar(
                        backgroundColor: Color(0xFFE4F2E9),
                        child: Icon(Icons.restaurant, color: AppTheme.green),
                      ),
                      title: Text(meal.name, style: const TextStyle(fontWeight: FontWeight.w700)),
                      subtitle: Text('${DateFormat('yyyy/MM/dd  h:mm a').format(meal.createdAt)}\n${meal.calories.round()} kcal'),
                      isThreeLine: true,
                      trailing: IconButton(
                        tooltip: 'حذف الوجبة',
                        onPressed: () => _confirmDelete(context, meal),
                        icon: const Icon(Icons.delete_outline),
                      ),
                      onTap: () => showModalBottomSheet<void>(
                        context: context,
                        isScrollControlled: true,
                        builder: (_) => SafeArea(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: SingleChildScrollView(
                              child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                                Text(meal.name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                                const SizedBox(height: 12),
                                Text(meal.notes.isEmpty ? 'لا توجد ملاحظات إضافية.' : meal.notes),
                                const SizedBox(height: 16),
                                const Text('إرشادات عامة', style: TextStyle(fontWeight: FontWeight.bold)),
                                const SizedBox(height: 8),
                                Text(meal.advice.isEmpty ? 'لا توجد إرشادات محفوظة لهذه الوجبة.' : meal.advice),
                              ]),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      );
}
