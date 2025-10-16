import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fitnessrecording/core/database/database.dart'; 
import 'package:fitnessrecording/features/fitness/domain/repositories/workout_repository.dart';

final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(() {
    db.close();
  });
  return db;
});

final workoutRepositoryProvider = Provider<WorkoutRepository>((ref) {
  final database = ref.watch(databaseProvider);
  return WorkoutRepository(database);
});