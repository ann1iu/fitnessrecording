import 'package:drift/drift.dart';
import 'package:fitnessrecording/core/database/database.dart';
import 'package:fitnessrecording/features/fitness/presentation/provides/respository_provider.dart';
import 'package:fitnessrecording/features/fitness/presentation/provides/workout_detail_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';


/// 训练详情页面
class WorkoutDetailPage extends ConsumerWidget {
  const WorkoutDetailPage({required this.workoutId, super.key});
  final int workoutId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncWorkout = ref.watch(workoutByIdStreamProvider(workoutId));
    final edit = ref.watch(workoutDetailNotifierProvider(workoutId));

    return Scaffold(
      appBar: AppBar(title: const Text('fitness detail'),
      actions: [
        IconButton(
          icon: const Icon(Icons.save),
          onPressed: () async {
            await ref.read(workoutDetailNotifierProvider(workoutId).notifier).save();
            Navigator.pop(context);
          })
      ]),
      body: asyncWorkout.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('错误: $e')),
        data: (_) {
          if (edit == null) return const SizedBox();
          return ListView(
            padding: const EdgeInsets.all(12),
            children: [
              // 1. 顶部 session 信息
              Container(
                margin: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.grey[200],
                ),
                child: ListTile(
                  title: Text('Date: ${DateFormat.yMMMd().add_Hm().format(edit.session.startTime)}'),
                  subtitle: Text('总计 ${edit.exercises.length} 动作'),
                ),
              ),
              const Divider(),

              // 2. 动作列表
              ...edit.exercises.indexed.map((item) {
                debugPrint("\n\n ** Begining"+item.toString());
                final exIndex = item.$1;
                final ex = item.$2;
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ExpansionTile(
                    title: Text(ex.anaerobicType?.name ?? '未知动作'),
                    subtitle: Text('${ex.sets.length} 组'),
                    trailing: IconButton(
                      icon: const Icon(Icons.settings),
                      onPressed: () => ref
                          .read(workoutDetailNotifierProvider(workoutId).notifier)
                          .deleteExercise(exIndex),
                    ),
                    children: [
                      // 组列表
                      ...ex.sets.indexed.map((Item) {
                        final setIndex = Item.$1;
                        final set = Item.$2;
                        return SetRow(
                          set: set,
                          onChanged: (newSet) => ref
                              .read(workoutDetailNotifierProvider(workoutId).notifier)
                              .updateSet(exIndex, setIndex, newSet),
                          onDelete: () => ref
                              .read(workoutDetailNotifierProvider(workoutId).notifier)
                              .deleteSet(exIndex, setIndex),
                        );
                      }),
                      TextButton.icon(
                        icon: const Icon(Icons.add),
                        label: const Text('加一组'),
                        onPressed: () => ref
                            .read(workoutDetailNotifierProvider(workoutId).notifier)
                            .addSet(exIndex),
                      ),
                      const SizedBox(height: 8),
                    ],
                  ),
                );
              }),

              // 3. 底部加新动作按钮
              FilledButton.icon(
                icon: const Icon(Icons.add),
                label: const Text('添加动作'),
                onPressed: () => _showAddExercise(context, ref),
              )
            ],
          );
        },
      ),
    );
  }

  void _showAddExercise(BuildContext context, WidgetRef ref) {
    // 弹个底部选择 sheet，把 AnaerobicType 列出来，点中选中的 insert 一条空 Exercise
    // 这里只示范调用仓库
    final repo = ref.read(workoutRepositoryProvider);
    // repo.insertEmptyExercise(workoutId, anaerobicTypeId);
    // 细节略，原理就是 insert 一条 ExercisesRecord + 一条空 SetRecord
  }
}

/* 单组编辑行 */
class SetRow extends StatelessWidget {
  const SetRow({required this.set, this.onChanged, this.onDelete, super.key});
  final SetRecord set;
  final ValueChanged<SetRecord>? onChanged;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final repsCtrl = TextEditingController(text: set.reps?.toString() ?? '');
    final weightCtrl = TextEditingController(text: set.weight?.toString() ?? '');
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
      child: Row(
        children: [
          Text('第${set.setNumber}组'),
          const SizedBox(width: 12),
          SizedBox(
            width: 60,
            child: TextField(
              controller: repsCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: '次数'),
              onSubmitted: (value) => _emit(repsCtrl, weightCtrl),
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 80,
            child: TextField(
              controller: weightCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: '重量(kg)'),
              onSubmitted: (value) => _emit(repsCtrl, weightCtrl),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete, size: 20),
            onPressed: onDelete,
          )
        ],
      ),
    );
  }

  void _emit(TextEditingController reps, TextEditingController weight) {
    if (onChanged == null) return;
    onChanged!(set.copyWith(
      reps: Value(int.tryParse(reps.text)),
      weight: Value(double.tryParse(weight.text)),
    ));
  }
}