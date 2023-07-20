import 'package:hive/hive.dart';

class Storage {
  //singleton

  static final Storage _instance = Storage._internal();

  factory Storage() => _instance;

  Storage._internal();

  Box box = Hive.box('savedStops');
}