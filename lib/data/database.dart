import 'dart:ffi';
import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

part 'database.g.dart';

// enum MuscleGroup {
//   chest, // 胸
//   back,  // 背中
//   legs,  // 腿
//   arms,  // 手臂
//   shoulders, // 肩膀
//   core,  // 核心
// }

// enum AnaerobicType {
//   strengthTraining, // 力量训练
//   hypertrophy,      // 肌肉增长
//   endurance,       // 耐力训练
//   power,           // 爆发力训练
//   benchPress,      // 卧推
//   squat,           // 深蹲
//   inclineBenchPress, // 上斜卧推
//   deadlift,        // 硬拉
//   pullUp,          // 引体向上
//   pushUp,          // 俯卧撑
//   bicepCurl,       // 二头肌弯举
//   tricepExtension, // 三头肌伸展
//   shoulderPress,   // 肩推
//   legPress,        // 腿推
//   calfRaise,       // 提踵
//   plank,           // 平板支撑
//   crunches,        // 仰卧起坐
//   russianTwists,   // 俄罗斯转体
//   legRaises,       // 抬腿
//   mountainClimbers, // 登山者
//   others
// }

class MuscleGroups extends Table { // 肌肉群表
  IntColumn get id => integer().autoIncrement()(); // 主键，自增
  TextColumn get name => text()(); // 肌肉群名称
}

class AnaerobicTypes extends Table { // 无氧运动类型表
  IntColumn get id => integer().autoIncrement()(); // 主键，自增
  TextColumn get name => text()(); // 类型名称
  IntColumn get muscleGroupId => integer().references(MuscleGroups,#id)(); // 外键，关联肌肉群表
}

class WorkoutSessions extends Table { // 训练记录表 单日训练
  IntColumn get id => integer().autoIncrement()(); // 主键，自增
  // DateTimeColumn get date => dateTime().withDefault(currentDateAndTime)(); // 训练日期 -> 从开始时间中提取
  DateTimeColumn get startTime => dateTime().withDefault(currentDateAndTime)(); // 开始时间
  DateTimeColumn? get endTime => dateTime().nullable()(); // 结束时间
  IntColumn? get duration => integer().nullable()(); // 训练时长，单位分钟
  IntColumn get totalSets => integer()(); // 总组数
  TextColumn? get notes => text().nullable()(); // 备注
}

class ExercisesRecords extends Table { //健身动作表 // 一次健身中的一个动作
  IntColumn get id => integer().autoIncrement()(); // 主键，自增
  IntColumn get sessionId => integer().references(WorkoutSessions,#id)(); // 外键，关联训练记录表
  IntColumn get exercise => integer().references(AnaerobicTypes, #id)(); // 动作编号
  IntColumn get sets => integer()(); // 组数
  IntColumn? get repsPerSet => integer().nullable()(); // 每组次数
  RealColumn? get weight => real().nullable()(); // 使用重量，单位kg
  RealColumn? get maxWeight => real().nullable()(); // 最大重量，单位kg
  RealColumn? get duration => real().nullable()(); // 持续时间，单位分钟
  IntColumn? get restTime => integer().nullable()(); // 组间休息时间，单位秒
  TextColumn? get notes => text().nullable()(); // 备注
}

class SetRecords extends Table { // 每组记录表
  IntColumn get id => integer().autoIncrement()(); // 主键，自增
  IntColumn get exerciseRecordId => integer().references(ExercisesRecords,#id)(); // 外键，关联动作记录表
  IntColumn get setNumber => integer()(); // 组号
  IntColumn? get reps => integer().nullable()(); // 次数
  RealColumn? get weight => real().nullable()(); // 使用重量，单位kg
  RealColumn? get duration => real().nullable()(); // 持续时间，单位分钟
  IntColumn? get restTime => integer().nullable()(); // 组间休息时间，单位秒
  TextColumn? get notes => text().nullable()(); // 备注
}

// ======DAO部分======

class WorkoutDao extends DatabaseAccessor<AppDatabase> with _$WorkoutDaoMixin {
  
  WorkoutDao(AppDatabase db) : super(db);

  // 插入新的训练记录
  Future<int> insertWorkoutSession(
    WorkoutSession session,
    List<ExercisesRecord> exercises, 
    List<List<SetRecord>> sets) async {
      return transaction(() async {
        final sessionId = await into(db.workoutSessions).insert(session);
        for (int i = 0; i < exercises.length; i++) {
          final exercise = exercises[i].copyWith(sessionId: sessionId);
          final exerciseId = await into(db.exercisesRecords).insert(exercise);
          for (final set in sets[i]) {
            final setWithExerciseId = set.copyWith(exerciseRecordId: exerciseId);
            await into(db.setRecords).insert(setWithExerciseId);
          }
        }
        return sessionId;
      });
  }

  // 获取一次训练记录及其相关的动作和组数据
  Future<FullWorkout?> getWorkoutSession(int id) async{
    final sessionQuery = await (select(db.workoutSessions)
      ..where((t) => t.id.equals(id))).getSingleOrNull();
    if (sessionQuery == null) {
      return Future.value(null);
    }
    final exercisesQuery = await (select(db.exercisesRecords)
      ..where((t) => t.sessionId.equals(id))).get();
    
    final exercisersQuery = select(db.exercisesRecords).join([
      innerJoin(exercises, exercies.id.equalsExp(exercisesRecords.exercise)), // 连接动作表
      innerJoin(muscleGroups,muscleGroups().id.equalsExp(exercises.muscleGroupId)), // 连接肌肉群表
    ]);

    final setsQuery = await (select(db.setRecords)
      ..where((t) => t.exerciseRecordId.isIn(exercisesQuery.map((e) => e.id).toList()))).get();
    
    final groupedSets = <int, List<SetRecord>>{};
    for (final set in setsQuery) {
      groupedSets.putIfAbsent(set.exerciseRecordId, () => []).add(set);
    }

    return FullWorkout(
      session: sessionQuery,
      exercises: exercisesQuery.map((e) => FullExercise(
        exercise: e,
        sets: groupedSets[e.id] ?? [],
      )).toList(),
    );
  }

  // 获取所有训练记录，按日期降序排列
  Future<List<WorkoutSession>> getAllWorkoutSessions() {
    return (select(db.workoutSessions)
          ..orderBy([(t) => OrderingTerm(expression: t.startTime, mode: OrderingMode.desc)]))
        .get();
  }

  // 更新训练记录
  Future<bool> updateWorkoutSession(WorkoutSession entry) {
    return update(db.workoutSessions).replace(entry);
  }

  // 更新训练记录相关的动作和组数据
  Future<void> updateFullWorkout(FullWorkout fullWorkout) async {
    return transaction(() async {
      await update(db.workoutSessions).replace(fullWorkout.session);
      for (final exercise in fullWorkout.exercises) {
        await update(db.exercisesRecords).replace(exercise.exercise);
        for (final set in exercise.sets) {
          await update(db.setRecords).replace(set);
        }
      }
    });
  }

  // 删除训练记录
  Future<int> deleteWorkoutSession(int id) {
    return (delete(db.workoutSessions)..where((t) => t.id.equals(id))).go();
  }
}

@DriftDatabase(
  tables: [MuscleGroups, AnaerobicTypes, WorkoutSessions, ExercisesRecords, SetRecords],
  daos: [WorkoutDao],
)

// ======数据库部分======

class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;

  // 在这里可以添加数据库初始化或迁移逻辑
  static LazyDatabase _openConnection() {
    return LazyDatabase(() async {
      final dbFolder = await getApplicationDocumentsDirectory();
      final file = File(p.join(dbFolder.path, 'fitness_recording.sqlite'));

      if (!await file.exists()) {
        // 如果数据库文件不存在，创建并初始化
        await file.create(recursive: true);
      }

      return FlutterQueryExecutor(file: file, logStatements: true);
    });
  }

  static QueryExecutor constructDb({String? path}) {
    if (path == null) {
      return _openConnection();
    } else {
      final file = File(path);
      return FlutterQueryExecutor(file: file, logStatements: true);
    }
  }

}

// ======辅助数据类部分======
class FullExercise {
  final ExercisesRecord exercise;
  final List<SetRecord> sets;

  const FullExercise({
    required this.exercise,
    required this.sets,
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
