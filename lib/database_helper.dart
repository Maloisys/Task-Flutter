import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'task.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._internal();
  factory DatabaseHelper() => instance;
  DatabaseHelper._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = await _getDatabasePath();
    print('Opening database at: $path');
    
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<String> _getDatabasePath() async {
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      // Для компа - в папку documents
      final documentsDir = await getApplicationDocumentsDirectory();
      return join(documentsDir.path, 'tasks.db');
    } else {
      // Для моб
      return join(await getDatabasesPath(), 'tasks.db');
    }
  }

  Future<void> _onCreate(Database db, int version) async {
    print('Creating database tables');
    await db.execute('''
      CREATE TABLE tasks(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        created INTEGER NOT NULL,
        duration INTEGER NOT NULL,
        completed INTEGER NOT NULL,
        deadline INTEGER,
        priority INTEGER NOT NULL
      )
    ''');
  }

  Future<String> getDatabasePath() async {
    return await _getDatabasePath();
  }

  Future<int> insertTask(Task task) async {
    try {
      Database db = await database;
      return await db.insert('tasks', task.toMap());
    } catch (e) {
      print('Error inserting task: $e');
      return -1;
    }
  }

  Future<List<Task>> getTasks() async {
    try {
      Database db = await database;
      final List<Map<String, dynamic>> maps = await db.query('tasks');
      return List.generate(maps.length, (i) => Task.fromMap(maps[i]));
    } catch (e) {
      print('Error getting tasks: $e');
      return [];
    }
  }

  Future<int> updateTask(Task task) async {
    try {
      Database db = await database;
      return await db.update(
        'tasks',
        task.toMap(),
        where: 'id = ?',
        whereArgs: [task.id],
      );
    } catch (e) {
      print('Error updating task: $e');
      return 0;
    }
  }

  Future<int> deleteTask(int id) async {
    try {
      Database db = await database;
      return await db.delete(
        'tasks',
        where: 'id = ?',
        whereArgs: [id],
      );
    } catch (e) {
      print('Error deleting task: $e');
      return 0;
    }
  }

  Future<void> deleteAllTasks() async {
    try {
      Database db = await database;
      await db.delete('tasks');
    } catch (e) {
      print('Error deleting all tasks: $e');
    }
  }
}