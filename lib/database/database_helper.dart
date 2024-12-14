import 'dart:async';
import 'dart:io';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';

import '../models/user.dart';

class DatabaseHelper {
  DatabaseHelper._privateConstructor();
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  _initDatabase() async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, 'app.db');
    return await openDatabase(path, version: 1, onCreate: _onCreate);
  }

  Future _onCreate(Database db, int version) async {
    // Create Users table
    await db.execute('''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        username TEXT NOT NULL,
        email TEXT NOT NULL UNIQUE,
        password_hash TEXT NOT NULL
      )
    ''');

    // Create Questions table (user-specific)
    await db.execute('''
      CREATE TABLE questions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        question_text TEXT NOT NULL,
        FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
      )
    ''');

    // Create Answers table
    await db.execute('''
      CREATE TABLE answers (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        question_id INTEGER NOT NULL,
        user_id INTEGER NOT NULL,
        answer_text TEXT NOT NULL,
        FOREIGN KEY (question_id) REFERENCES questions (id) ON DELETE CASCADE,
        FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
      )
    ''');
  }

  // Insert a new user
  Future<int> insertUser(User user) async {
    Database db = await database;
    return await db.insert('users', user.toJson(),
        conflictAlgorithm: ConflictAlgorithm.fail);
  }

  // Insert a new question for a user
  Future<int> insertQuestion(int userId, String questionText) async {
    Database db = await database;
    return await db.insert('questions', {
      'user_id': userId,
      'question_text': questionText,
    });
  }

  // Insert predefined questions for a new user
  Future<void> insertPredefinedQuestions(int userId) async {
    final predefinedQuestions = [
      'What is your name?',
      'How old are you?',
      'Where do you live?',
    ];
    for (var question in predefinedQuestions) {
      await insertQuestion(userId, question);
    }
  }

  // Insert a new answer
  Future<int> insertAnswer(int userId, int questionId, String answerText) async {
    Database db = await database;
    return await db.insert('answers', {
      'user_id': userId,
      'question_id': questionId,
      'answer_text': answerText,
    });
  }

  // Fetch all questions for a user
  Future<List<Map<String, dynamic>>> getQuestionsByUser(int userId) async {
    Database db = await database;
    return await db.query('questions',
        where: 'user_id = ?', whereArgs: [userId]);
  }

  // Fetch all answers provided by a user
  Future<List<Map<String, dynamic>>> getAnswersByUser(int userId) async {
    Database db = await database;
    return await db.query('answers',
        where: 'user_id = ?', whereArgs: [userId]);
  }

  // Fetch all answers for a specific question
  Future<List<Map<String, dynamic>>> getAnswersForQuestion(
      int questionId) async {
    Database db = await database;
    return await db.query('answers',
        where: 'question_id = ?', whereArgs: [questionId]);
  }

  // Fetch a user by email
  Future<User?> getUserByEmail(String email) async {
    Database db = await database;
    List<Map<String, dynamic>> results = await db.query('users',
        columns: ['id', 'username', 'email', 'password_hash'],
        where: 'email = ?',
        whereArgs: [email]);
    if (results.isNotEmpty) {
      return User.fromJson(results.first);
    } else {
      return null;
    }
  }

  // Hashing function for password
  String hashPassword(String password) {
    var bytes = utf8.encode(password);
    var digest = sha256.convert(bytes);
    return digest.toString();
  }
}
