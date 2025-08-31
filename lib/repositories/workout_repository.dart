import 'package:drift/drift.dart';
import '../data/database.dart';

class WorkoutRepository {
  final AppDatabase _database;

  WorkoutRepository(this._database);


  Future<int> insertWorkoutSession( // 插入一次训练
      WorkoutSessionsCompanion workoutSession,
      List<ExercisesRecordsCompanion> exercises,
      List<List<SetRecordsCompanion>> sets) async {
    return await _database.transaction(() async {
      final workoutSessionId =
          await _database.insertWorkoutSession(workoutSession, exercises, sets);
      return workoutSessionId;
    });
  }

  Future<List<WorkoutSessionWithDetails>> getAllWorkoutSessions() async { // 获取所有训练
    return await _database.workoutDao.getAllWorkoutSessions();
  }

  Future<WorkoutSessionWithDetails?> getWorkoutSessionById(int id) async { // 根据ID获取某次训练
    return await _database.workoutDao.getWorkoutSessionById(id);
  }

  Future<int> updateWorkoutSession(
      int id,
      WorkoutSessionsCompanion workoutSession,
      List<ExercisesRecordsCompanion> exercises,
      List<List<SetRecordsCompanion>> sets) async {
    return await _database.transaction(() async {
      final rowsAffected = await _database.workoutDao.updateWorkoutSession(id, workoutSession, exercises, sets);
      return rowsAffected;
    });
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
      leftOuterJoin(_database.anaerobicTypes, _database.anaerobicTypes.id.equalsExp(_database.exercisesRecords.exercise)), // 连接动作表
      leftOuterJoin(_database.muscleGroups, _database.muscleGroups.id.equalsExp(_database.anaerobicTypes.muscleGroupId))
    ]);

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
            exerciseRecord: exerciseRecord,
            anaerobicType: anaerobicType,
            sets: [],
          ));
        }
      }

      return workoutMap.values.toList();
    });
  }

  Future<List<MuscleGroup>> getAllMuscleGroups() async {
    return await _database.select(_database.muscleGroups).get();
  }
}

class FullExercise {
  final ExercisesRecord exercise;
  final List<SetRecord> sets;
  final AnaerobicType? anaerobicType;
  final MuscleGroup? muscleGroup;

  const FullExercise({
    required this.exercise,
    required this.sets,
    this.anaerobicType,
    this.muscleGroup,
  });
}

class FullWorkout {
  final WorkoutSession session;
  final List<FullExercise> exercises;

  const FullWorkout({
    required this.session,
    required this.exercises,
  });
}