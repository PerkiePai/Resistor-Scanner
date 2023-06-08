import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

Future<Database> initializeDatabase() async {
  // Get the path to the database file
  String databasesPath = await getDatabasesPath();
  String path = join(databasesPath, 'video_database.db');

  // Open/create the database
  Database database = await openDatabase(path, version: 1,
      onCreate: (Database db, int version) async {
    // Create the video table
    await db.execute('''
      CREATE TABLE videos (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        videoData BLOB
      )
    ''');
  });

  return database;
}
