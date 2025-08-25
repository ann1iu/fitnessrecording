import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:path_provider/path_provider.dart';

Future<String> _getlocalPath() async {
  final directory = await getApplicationDocumentsDirectory();
  return directory.path;
}

Future<File> getLocalFile(String filename) async {
  final path = await _getlocalPath();
  debugPrint('\n\npath:$path\n\n');
  debugPrint('filename:$path/$filename');
  return File('$path/storage/$filename');
}