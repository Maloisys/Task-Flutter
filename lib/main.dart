import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Инициализация для десктопа (Windows, Mac, Linux)
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    // Инициализируем FFI для десктопа
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    print('Running on desktop - using FFI');
  } else {
    print('Running on mobile - using standard sqflite');
  }
  
  // Получаем путь для базы данных
  String databasePath;
  
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    // Для десктопа - в папку documents
    final documentsDir = await getApplicationDocumentsDirectory();
    databasePath = join(documentsDir.path, 'tasks.db');
  } else {
    // Для мобильных устройств - стандартный путь
    databasePath = join(await getDatabasesPath(), 'tasks.db');
  }
  
  print('Database will be created at: $databasePath');
  
  // Создаем базу данных
  try {
    Database db = await openDatabase(
      databasePath,
      version: 1,
      onCreate: (Database db, int version) async {
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
      },
    );
    await db.close();
    print('Database initialized successfully at: $databasePath');
  } catch (e) {
    print('Error initializing database: $e');
  }
  
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _isDarkTheme = false;

  void toggleTheme() {
    setState(() {
      _isDarkTheme = !_isDarkTheme;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'По делам IT TOP',
      theme: _isDarkTheme
          ? ThemeData.dark().copyWith(
              colorScheme: ColorScheme.fromSeed(
                seedColor: Colors.teal,
                brightness: Brightness.dark,
              ),
              scaffoldBackgroundColor: Colors.grey[900],
              appBarTheme: const AppBarTheme(
                backgroundColor: Color.fromARGB(255, 138, 109, 206),
              ),
            )
          : ThemeData(
              brightness: Brightness.light,
              colorScheme: ColorScheme.fromSeed(
                seedColor: Colors.blue,
                brightness: Brightness.light,
              ),
              scaffoldBackgroundColor: Colors.white,
              appBarTheme: const AppBarTheme(
                backgroundColor: Colors.purple,
                foregroundColor: Colors.white,
              ),
            ),
      debugShowCheckedModeBanner: false,
      home: HomeScreen(
        toggleTheme: toggleTheme,
        isDarkTheme: _isDarkTheme,
      ),
    );
  }
}