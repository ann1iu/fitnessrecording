import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'providers/workout_stream_provider.dart' as wsp;

class HomePage extends ConsumerWidget{
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {

    print(wsp.workoutStreamProvider);

    var w = wsp.WorkoutFilter(
      from: DateTime.now().subtract(const Duration(days: 7)),
      to: DateTime.now(),
    );

    final workouts = ref.watch(wsp.workoutStreamProvider(w));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Fitness Recording Home Page'),
      ),
      body:workouts.when(
        data: (list) => list.isEmpty 
        ? const Center(child: Text('No workouts found in the last 7 days.'))
        : ListView.builder(
          itemCount: list.length,
          itemBuilder: (context, index) {
            final workout = list[index];
            return ListTile(
              title: Text('Workout on ${workout.session.startTime}'),
              subtitle: Text('${workout.exercises.length} exercises'),
            );
          },
        ),
        loading:() => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Error: $e')),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showSnack(context, 'Add workout button pressed');
          // Navigate to add workout page
        },
        child: const Icon(Icons.add),
        tooltip: 'Add Workout',
      ),
    );
  }

  void _showSnack(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}