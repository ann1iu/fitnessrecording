import 'package:flutter/material.dart';

import './storage/file_operator.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      // home: const MyHomePage(title: 'Flutter Demo Home Page'),
      home: Center(
        child: ElevatedButton(onPressed: _demo, 
        child: const Text("点我写入 & 读取"),),
      )
    );
  }

  Future<void> _demo() async {
    final list = await readWorkouts();
    debugPrint('读到的数据: ${list.toString()}');
    list.add({
      "id": DateTime.now().millisecondsSinceEpoch.toString(),
      "date": DateTime.now().toIso8601String(),
      "title":"测试数据",
      "exercises": [
        {
          "name": "深蹲",
          "sets": [
            {"weight": 100, "reps": 10},
            {"weight": 100, "reps": 8},
            {"weight": 100, "reps": 6}
          ]
        },
        {
          "name": "卧推",
          "sets": [
            {"weight": 80, "reps": 10},
            {"weight": 80, "reps": 8},
            {"weight": 80, "reps": 6}
          ]
        }
      ]
    });
    await writeWorkouts(list);
    debugPrint('写入成功');
  }
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
