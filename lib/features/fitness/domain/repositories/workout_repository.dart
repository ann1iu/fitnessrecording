import 'package:fitnessrecording/core/database/database.dart';

// Use FullWorkout from database.dart

class WorkoutRepository {
  final AppDatabase _database;

  WorkoutRepository(this._database);


  Future<int> insertWorkoutSession( // 插入一次训练
      WorkoutSession workoutSession,
      List<ExercisesRecord> exercises,
      List<List<SetRecord>> sets) async {
    return await _database.transaction(() async {
      final workoutSessionId =
          await _database.workoutDao.insertWorkoutSession(workoutSession,exercises,sets);
      return workoutSessionId;
    });
  }

  Future<int> deleteWorkoutSession(int id) async {
    return await _database.transaction(() async {
      final rowsDeleted = await _database.workoutDao.deleteWorkoutSession(id);
      return rowsDeleted;
    });
  }

  // 更新完整的训练记录（直接使用 FullWorkout 对象）
  Future<void> updateFullWorkout(FullWorkout fullWorkout) async {
    return await _database.transaction(() async {
      await _database.workoutDao.updateFullWorkout(fullWorkout);
    });
  }

  // 更新完整的训练记录（接收分开的参数）
  Future<int> updateFullWorkouts(
      WorkoutSession session,
      List<ExercisesRecord> exercises,
      List<List<SetRecord>> sets) async {
    // 构建 FullWorkout 对象
    final fullExercises = <FullExercise>[];
    for (int i = 0; i < exercises.length; i++) {
      // 注意：这里我们没有 anaerobicType 和 muscleGroup 的详细信息，
      // 但 DAO 的 updateFullWorkout 方法只需要 exercise 和 sets 信息
      fullExercises.add(FullExercise(
        exercise: exercises[i],
        sets: sets[i],
        anaerobicType: null,
        muscleGroup: null,
      ));
    }
    
    final fullWorkout = FullWorkout(
      session: session,
      exercises: fullExercises,
    );
    
    await updateFullWorkout(fullWorkout);
    return session.id;
  }

  // 获取所有训练
  Future<List<WorkoutSession>> getAllWorkoutSessions() async { 
    return await _database.workoutDao.getAllWorkoutSessions();
  }

  // 获取所有训练及其相关的动作和组数据
  Future<List<FullWorkout>> getAllWorkoutSessionsWithExercises() async {
    return await _database.workoutDao.getAllWorkoutSessionsWithExercises();
  }

  // 根据ID获取某次训练及其相关的动作和组数据
  Future<FullWorkout?> getWorkoutSessionById(int id) { 
    return _database.workoutDao.getWorkoutSession(id);
  }

  // 获取所有肌肉组
  Future<List<MuscleGroup>> getAllMuscleGroups() async {
    return await _database.workoutDao.getAllMuscleGroups();
  }

  // 根据时间范围获取训练记录及其相关的动作和组数据
  Future<List<FullWorkout>> getWorkoutSessionsByDateRange(DateTime? from, DateTime? to) async {
    return await _database.workoutDao.getWorkoutSessionsByDateRange(from, to);
  }

  Stream<FullWorkout?> watchWorkoutById(int id) {
    return Stream.fromFuture(getWorkoutSessionById(id));
  }

}
