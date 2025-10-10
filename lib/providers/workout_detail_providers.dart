
import 'package:fitnessrecording/data/database.dart';
import 'package:fitnessrecording/providers/respository_provider.dart';
import 'package:fitnessrecording/repositories/workout_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

final workoutByIdStreamProvider = 
    StreamProvider.family<FullWorkout?, int>((ref, id) {
  final repository = ref.watch(workoutRepositoryProvider);
  return repository.watchWorkouts().map((list) {
    final match = list.where((w) => w.session.id == id);
    return match.isEmpty ? null : match.first;
  });
});

class WorkoutDetailEdit {
  WorkoutDetailEdit({
    required this.session,
    required this.exercises
  });

  WorkoutSession session;
  List<FullExercise> exercises;
}

class WorkoutDetailNotifier extends StateNotifier<WorkoutDetailEdit?> {
  WorkoutDetailNotifier(this._repo) : super(null);
  final WorkoutRepository _repo;

  void init(FullWorkout src){
    state = WorkoutDetailEdit(
      session: src.session,
      exercises: src.exercises
          .map((e) => FullExercise(
                exercise: e.exercise,
                sets: List.of(e.sets),
                anaerobicType: e.anaerobicType,
                muscleGroup: e.muscleGroup,
              ))
          .toList(),
    );
  }

  void updateSet(int exIndex, int setIndex, SetRecord newSet){
    if(state == null) return ;
    final ex = state!.exercises[exIndex];
    final newSets = List<SetRecord>.of(ex.sets)..[setIndex] = newSet;
    state = WorkoutDetailEdit(
      session: state!.session,
      exercises: [
        for(int i = 0; i < state!.exercises.length; i++)
          if(i == exIndex)
            FullExercise(
              exercise: ex.exercise,
              sets: newSets,
              anaerobicType: ex.anaerobicType,
              muscleGroup: ex.muscleGroup,
            )
          else
            state!.exercises[i]
      ]
    );
  }

  void addSet(int exIndex) {
    if(state == null) return;
    final ex = state!.exercises[exIndex];
    final last = ex.sets.lastOrNull;
    final newSet = SetRecord(
      id: 0,
      exerciseRecordId: ex.exercise.id,
      setNumber: ex.sets.length + 1,
      reps: last?.reps ?? 10,
      weight: last?.weight ?? 20.0,
      duration: last?.duration,
      restTime: last?.restTime,
    );

    state = WorkoutDetailEdit(
      session: state!.session,
      exercises: [
        for(int i = 0; i < state!.exercises.length; i++)
          if(i == exIndex)
            FullExercise(
              exercise: ex.exercise,
              sets: [...ex.sets, newSet],
              anaerobicType: ex.anaerobicType,
              muscleGroup: ex.muscleGroup,
            )
          else
            state!.exercises[i]
      ]);
  }
  
  void deleteSet(int exIndex, int setIndex) {
    if(state == null) return;
    final ex = state!.exercises[exIndex];
    final newSets = List<SetRecord>.of(ex.sets)..removeAt(setIndex);
    state = WorkoutDetailEdit(
      session: state!.session,
      exercises: [
        for(int i = 0; i < state!.exercises.length; i++)
          if(i == exIndex)
            FullExercise(
              exercise: ex.exercise,
              sets: newSets,
              anaerobicType: ex.anaerobicType,
              muscleGroup: ex.muscleGroup,
            )
          else
            state!.exercises[i]
      ]
    );
  }

  void deleteExercise(int exIndex) {
    if(state == null) return;
    final list = List<FullExercise>.of(state!.exercises)..removeAt(exIndex);
    state = WorkoutDetailEdit(
      session: state!.session,
      exercises: list
    );
  }

  Future<int> save() async {
    if(state == null) return 0;
    final sessionId = await _repo.updateFullWorkout(
      state!.session, 
      state!.exercises.map((e) => e.exercise).toList(), 
      state!.exercises.map((e) => e.sets).toList()
    );
    return sessionId;
  }
}

final workoutDetailNotifierProvider =
    StateNotifierProvider.family<WorkoutDetailNotifier, WorkoutDetailEdit?, int>(
        (ref, id) {
  final repo = ref.watch(workoutRepositoryProvider);
  final notifier = WorkoutDetailNotifier(repo);
  // 监听原始数据，第一次加载时把副本初始化
  ref.listen(workoutByIdStreamProvider(id), (prev, next) {
    next.whenData((fw) => fw == null ? null : notifier.init(fw));
  });
  return notifier;
});
