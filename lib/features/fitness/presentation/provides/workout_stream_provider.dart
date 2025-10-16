import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fitnessrecording/core/database/database.dart';
import 'package:fitnessrecording/features/fitness/presentation/provides/respository_provider.dart';

final workoutStreamProvider = StreamProvider.family.autoDispose<List<FullWorkout>,WorkoutFilter>((ref, filter) {
  final repo = ref.watch(workoutRepositoryProvider);
  return repo.getWorkoutSessionsByDateRange(
    filter.from, 
    filter.to,
    ).asStream(); 
});

class WorkoutFilter {
  final DateTime? from;
  final DateTime? to;
  // final int? muscleGroupId;

  WorkoutFilter({this.from, this.to});
}
