import 'package:fitnessrecording/data/database.dart';
import 'package:flutter/material.dart';
import 'package:drift/drift.dart';
import './data/database.dart ';

void main() {
  final db = AppDatabase();

  await db.WorkoutDao.insertWorkoutSession(
    WorkoutSessionsCompanion.insert(
      startTime: DateTime.now(),
      duration: Value(60),
      totalSets: 10,
      notes: Value('test data')
    ),
    [
      ExercisesRecordsCompanion.insert(
        exercise: 1,
        sets: 5,
        repsPerSet: Value(10),
        weight: Value(50.0),
        maxWeight: Value(60.0),
        duration: Value(15.0),
        restTime: Value(60),
        notes: Value('test exercise')
      )
    ],
    [
      List.generate(5, (index) => SetRecordsCompanion.insert(
        exerciseRecordId: 1,
        setNumber: index + 1,
        reps: Value(10),
        weight: Value(50.0 + index * 2),
        duration: Value(3.0),
        restTime: Value(60),
        notes: Value('set ${index + 1}')
      ))
    ]
  );
}

// class MyHomePage extends StatefulWidget {
//   const MyHomePage({super.key, required this.title});
//   final String title;
//   @override
//   State<MyHomePage> createState() => _MyHomePageState();
// }

// class _MyHomePageState extends State<MyHomePage> {
//   int _counter = 0;

//   void _incrementCounter() {
//     setState(() {
//       _counter++;
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         backgroundColor: Theme.of(context).colorScheme.inversePrimary,
//         title: Text(widget.title),
//       ),
//       body: Center(

//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: <Widget>[
//             const Text('You have pushed the button this many times:'),
//             Text(
//               '$_counter',
//               style: Theme.of(context).textTheme.headlineMedium,
//             ),
//           ],
//         ),
//       ),
//       floatingActionButton: FloatingActionButton(
//         onPressed: _incrementCounter,
//         tooltip: 'Increment',
//         child: const Icon(Icons.add),
//       ), // This trailing comma makes auto-formatting nicer for build methods.
//     );
//   }
// }
