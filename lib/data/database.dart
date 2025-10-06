import 'dart:io';
import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:drift/native.dart';
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
  IntColumn get exerciseId => integer().references(AnaerobicTypes, #id)(); // 动作编号
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
@DriftAccessor(tables: [WorkoutSessions, ExercisesRecords, SetRecords, AnaerobicTypes, MuscleGroups])
class WorkoutDao extends DatabaseAccessor<AppDatabase> with _$WorkoutDaoMixin {
  
  WorkoutDao(super.db);

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
    
    final exercisesQuery = await( select(db.exercisesRecords)
      .join([
        innerJoin(db.anaerobicTypes, db.exercisesRecords.exerciseId.equalsExp(db.anaerobicTypes.id)), // 连接动作表
        innerJoin(db.muscleGroups,db.muscleGroups.id.equalsExp(db.anaerobicTypes.muscleGroupId)), // 连接肌肉群表
      ])
      ..where(db.exercisesRecords.sessionId.equals(id))).get();

    final setsQuery = await (select(db.setRecords)
      ..where((t) => t.exerciseRecordId.isIn(exercisesQuery.map((e) => e.readTable(db.exercisesRecords).id)))).get();

    final groupedSets = <int, List<SetRecord>>{};
    for (final set in setsQuery) {
      groupedSets.putIfAbsent(set.exerciseRecordId, () => []).add(set);
    }

    return FullWorkout(
      session: sessionQuery,
      exercises: exercisesQuery.map((e) => FullExercise(
        exercise: e.readTable(db.exercisesRecords),
        sets: groupedSets[e.readTable(db.exercisesRecords).id] ?? [],
        anaerobicType: e.readTableOrNull(db.anaerobicTypes),
        muscleGroup: e.readTableOrNull(db.muscleGroups),
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
class AppDatabase extends _$AppDatabase { 
// ======数据库部分======
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      await m.createAll();
      // 在这里可以添加初始数据插入逻辑
    },
    onUpgrade: (m, from, to) async {
      // 在这里可以添加数据库升级逻辑
    },
    beforeOpen: (details) async {
      if (details.wasCreated) {
        // 在这里可以添加数据库创建后的逻辑
      }
    },
  );

  static Future<void> initializeDatabase(AppDatabase db) async {
    // 在这里可以添加数据库初始化
    // 1. 插入肌肉群
    final mgMap = <String, int>{};
    final muscleGroups = [
      'chest', // 胸
      'back',  // 背中
      'legs',  // 腿
      'arms',  // 手臂
      'shoulders', // 肩膀
      'core',  // 核心
      'body', // 全身
    ];
    for (final name in muscleGroups) {
      final id = await db.into(db.muscleGroups).insert(MuscleGroupsCompanion.insert(name: name));
      mgMap[name] = id;
    }

    // 2. 插入无氧运动类型
    final anaerobicTypes = {
      'Pull-Up':'back', // 引体向上
      'Lat Pulldown': 'back', // 下拉
      'Bent-Over Row': 'back', // 俯身划船
      'Dumbbell Row':'back', // 哑铃划船

      'Dombbell Reverse  Fly': 'shoulders', // 俯身飞鸟
      'Machine Reverse Fly': 'shoulders', // 器械反向飞鸟

      'Bicep Curl': 'arms', // 二头肌弯举
      'barbell Curl': 'arms', // 杠铃弯举
      'Dombbell Curl': 'arms', // 哑铃弯举
      'Dumbbell Concentration Curl': 'arms', // 哑铃集中弯举
      'Pastorns stol Curl': 'arms', // 牧师椅弯举

      'BarBell Bench Press': 'chest', // 杠铃卧推
      'Dumbbell Bench Press': 'chest', // 哑铃卧推
      'Incline Bench Press': 'chest', // 上斜卧推
      'Push-Up': 'chest', // 俯卧撑
      'Pec Deck Machine': 'chest', // 蝴蝶机夹胸

      'Barbell Incline Press': 'shoulders', // 杠铃上斜推举
      'Dumbbell Incline Press': 'shoulders', // 哑铃上斜推举
      'Arnold Press': 'shoulders', // 阿诺德推举
      'Front Raise': 'shoulders', // 前平举
      'Shrug': 'shoulders', // 耸肩
      'Upright Row': 'shoulders', // 直立划船
      'Shoulder Press': 'shoulders', // 肩推
      'Lateral Raise': 'shoulders', // 侧平举

      'Narrow Grip Bench Press': 'arms', // 窄距卧推
      'Tricep Dip': 'arms', // 三头肌下压
      'Tricep Pushdown': 'arms', // 绳索下压
      'Barbell triceps Extension': 'arms', // 杠铃三头肌臂屈伸
      'Dumbbell Triceps Extension': 'arms', // 哑铃三头肌臂屈伸
      'Triceps cable press down': 'arms', // 绳索三头肌下压
      'Tricep Extension': 'arms', // 三头肌伸展

      'BarBell Squat': 'legs', // 杠铃深蹲
      'Dumbbell Squat': 'legs', // 哑铃深蹲
      'Deadlift': 'back', // 硬拉
      
      'Crunches': 'core', // 卷腹
      'Plank': 'core', // 平板支撑
      'Russian Twists': 'core', // 俄罗斯转体
      'Leg Raises': 'core', // 抬腿
      'Hanging Leg Raises': 'core', // 悬垂抬腿
      'Kneeling Crunches': 'core', // 跪姿卷腹
      'Mountain Climbers': 'core', // 登山者
      'Bicycle Crunches': 'core', // 自行车卷腹
      'Sit-Ups': 'core', // 仰卧起坐
      // ['Other', 'others'], // 其他
      // [link](https://www.bodybuilding.com/exercises/finder/sort/popularity/target/muscle/arms)
      // [link](https://zhuanlan.zhihu.com/p/245677109)
      // [link](https://www.zhihu.com/question/23167354)
    };

    for (final entry in anaerobicTypes.entries) {
      final name = entry.key;
      final mgName = entry.value;
      final mgId = mgMap[mgName]!;
      await db.into(db.anaerobicTypes).insert(AnaerobicTypesCompanion.insert(
        name: name,
        muscleGroupId: mgId,
      ));
    }
  }

  // 在这里可以添加数据库初始化或迁移逻辑
  static LazyDatabase _openConnection() {
    return LazyDatabase(() async {
      final dbFolder = await getApplicationDocumentsDirectory();
      final file = File(p.join(dbFolder.path, 'fitness_recording.sqlite'));

      if (!await file.exists()) {
        // 如果数据库文件不存在，创建并初始化
        await file.create(recursive: true);
      }

      return NativeDatabase(file, logStatements: kDebugMode);
    });
  }

  static QueryExecutor constructDb({String? path}) {
    if (path == null) {
      return _openConnection();
    } else {
      final file = File(path);
      return NativeDatabase(file, logStatements: kDebugMode);
    }
  }

}

// ======辅助数据类部分======
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
