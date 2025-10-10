import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/workout_stream_provider.dart' as wsp;

class HomePage extends ConsumerWidget{
  HomePage({super.key});

  final currentFilterProvider = Provider<wsp.WorkoutFilter>((ref) {
    final now = DateTime.now();
    return wsp.WorkoutFilter(
      from: now.subtract(const Duration(days: 7)),
      to: now,
    );
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {

    final workouts = ref.watch(wsp.workoutStreamProvider(ref.watch(currentFilterProvider)));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Fitness Recording'),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.indigo, Colors.blue],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        actions:[
          IconButton(
            onPressed: () => {/* 打开日期筛选*/},
            icon: const Icon(Icons.calendar_today)
          )
        ]
      ),
      body:workouts.when(
        data: (list) => list.isEmpty 
        ? Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.fitness_center, size: 80, color: Colors.grey),
              const SizedBox(height: 16),
              Text(
                'No workouts logged yet.\nTap the + button to add your first workout!',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 8),
              FilledButton.icon(
                onPressed: () => {},
                icon: const Icon(Icons.add),
                label: const Text('Start Training'))
            ],
          )
        )
        : ListView.builder(
          itemCount: list.length,
          itemBuilder: (context, index) {
            final workout = list[index];
            return InkWell(
              onTap:() => {},
              child: Card(
                margin: const EdgeInsets.symmetric(horizontal: 10,vertical: 5),
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                      children: [
                        const Icon(Icons.fitness_center,color: Colors.indigo),
                        const SizedBox(width: 8),
                        Text(
                          'Workout ${DateFormat.yMMMd().add_Hm().format(workout.session.startTime)}',
                          style: Theme.of(context).textTheme.titleMedium,
                        )
                      ],),
                      const SizedBox(height: 8),
                      Text('${workout.exercises.length} exercises',style:Theme.of(context).textTheme.bodySmall),
                    ],
                  ),
                )
              )
            );
          },
        ),
        loading:() => const Center(child: CircularProgressIndicator()),
        /**
        loading: () => ListView.builder(
          itemCount: 6,
          itemBuilder: (_, __) => Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Skeleton(width: 48, height: 48, radius: 8),
                  const SizedBox(width: 12),
                  Expanded(child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Skeleton(height: 14),
                      SizedBox(height: 6),
                      Skeleton(height: 12, width: 100),
                    ],
                  )),
                ],
              ),
            ),
          ),
        ),
         */
        error: (e, st) => Center(child: Text('Error: $e')),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showSnack(context, 'Add workout button pressed');
          // Navigate to add workout page
        },
        tooltip: 'Add Workout',
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showSnack(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}