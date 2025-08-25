import 'dart:convert';
import 'local_storage.dart';

Future<List<dynamic>> readWorkouts() async {
  try {
    final filename = 'workouts.json';
    final file = await getLocalFile(filename);
    if (!await file.exists()) return [];
    final contents = await file.readAsString();
    return jsonDecode(contents) as List;
  }catch (e) {
    return [e.toString()]; // Return an empty list if encountering an error
  } finally {
    // Any cleanup if necessary
  }
}

Future<void> writeWorkouts(List<dynamic> list) async {
  final filename = 'workouts.json';
  final file = await getLocalFile(filename);
  final contents = jsonEncode(list);
  await file.writeAsString(contents);
}