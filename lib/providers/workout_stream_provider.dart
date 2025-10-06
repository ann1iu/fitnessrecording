import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/database.dart';
import './respository_provider.dart' as rpd;

final workoutStreamProvider = StreamProvider.family.autoDispose<List<FullWorkout>,WorkoutFilter>((ref, filter) {
  final repo = ref.watch(rpd.workoutRepositoryProvider);
  return repo.watchWorkouts(
    from: filter.from, 
    to: filter.to,
    muscleGroupId: filter.muscleGroupId);
});

class WorkoutFilter {
  final DateTime? from;
  final DateTime? to;
  final int? muscleGroupId;

  WorkoutFilter({this.from, this.to, this.muscleGroupId});
}
