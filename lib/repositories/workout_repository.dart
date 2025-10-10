import 'package:drift/drift.dart';
import 'package:fitnessrecording/data/database.dart';

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

  Future<List<WorkoutSession>> getAllWorkoutSessions() async { // 获取所有训练
    return await _database.workoutDao.getAllWorkoutSessions();
  }

  Future<FullWorkout?> getWorkoutSessionById(int id) { // 根据ID获取某次训练
    return _database.workoutDao.getWorkoutSession(id);
  }


  Future<int> deleteWorkoutSession(int id) async {
    return await _database.transaction(() async {
      final rowsDeleted = await _database.workoutDao.deleteWorkoutSession(id);
      return rowsDeleted;
    });
  }

  Stream<List<FullWorkout>> watchWorkouts({DateTime? from, DateTime? to,int? muscleGroupId}) {
    var query = _database.select(_database.workoutSessions).join([ // 每日动作记录
      leftOuterJoin(_database.exercisesRecords, _database.exercisesRecords.sessionId.equalsExp(_database.workoutSessions.id)), // 连接运动动作记录
      leftOuterJoin(_database.anaerobicTypes, _database.anaerobicTypes.id.equalsExp(_database.exercisesRecords.exerciseId)), // 连接动作表
      leftOuterJoin(_database.muscleGroups, _database.muscleGroups.id.equalsExp(_database.anaerobicTypes.muscleGroupId))
    ]);

    from = from?.toUtc();
    to = to?.toUtc();

    if (from != null) {
      query.where(_database.workoutSessions.startTime.isBiggerOrEqualValue(from));
    }
    if (to != null) {
      query.where(_database.workoutSessions.startTime.isSmallerOrEqualValue(to));
    }
    if (muscleGroupId != null) {
      query.where(_database.muscleGroups.id.equals(muscleGroupId));
    }
    query.orderBy([OrderingTerm.desc(_database.workoutSessions.startTime)]); // 按时间降序排列

    return query.watch().map((rows) {
      final Map<int, FullWorkout> workoutMap = {};

      for (final row in rows) {
        final workoutSession = row.readTable(_database.workoutSessions);
        final exerciseRecord = row.readTableOrNull(_database.exercisesRecords);
        final anaerobicType = row.readTableOrNull(_database.anaerobicTypes);
        final muscleGroup = row.readTableOrNull(_database.muscleGroups);

        workoutMap.putIfAbsent(workoutSession.id, () => FullWorkout(session: workoutSession, exercises: []));
        if (exerciseRecord != null) {

          workoutMap[workoutSession.id]!.exercises.add(FullExercise(
            exercise: exerciseRecord,
            sets: [], // Sets can be fetched separately if needed
            anaerobicType: anaerobicType,
            muscleGroup: muscleGroup,
          ));
        }
      }

      return workoutMap.values.toList();
    });
  }

  Future<List<MuscleGroup>> getAllMuscleGroups() async {
    return await _database.select(_database.muscleGroups).get();
  }

  Stream<FullWorkout?> watchWorkoutById(int id) {
    return Stream.fromFuture(getWorkoutSessionById(id));
  }

  Future<int> updateFullWorkout(
      WorkoutSession session,
      List<ExercisesRecord> exercises,
      List<List<SetRecord>> setsList) async {
    return await _database.transaction(() async {
      // 更新或插入 WorkoutSession
      final sessionId = session.id == 0
          ? await _database.workoutDao.insertWorkoutSession(session, exercises, setsList)
          : await _database.workoutDao.updateWorkoutSession(session);

      // 删除旧的 Exercises 和 Sets
      await _database.workoutDao.deleteExercisesForSession(sessionId);

      // 插入新的 Exercises 和 Sets
      for (int i = 0; i < exercises.length; i++) {
        final exercise = exercises[i];
        final exerciseId = await _database.workoutDao.insertExercise(
          exercise.copyWith(sessionId: sessionId),
        );

        for (final set in setsList[i]) {
          await _database.workoutDao.insertSet(
            set.copyWith(exerciseRecordId: exerciseId),
          );
        }
      }

      return sessionId;
    });
  }
}
