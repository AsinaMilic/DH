import 'package:flutter/material.dart';
import 'package:adaptive_dialog/adaptive_dialog.dart';
import 'package:sqflite/sqflite.dart';
import '../database/database_helper.dart'; // Import your database helper

class QuestionsScreen extends StatefulWidget {
  final int userId; // Pass userId to track answers by this user

  QuestionsScreen({required this.userId});

  @override
  _QuestionsScreenState createState() => _QuestionsScreenState();
}

class _QuestionsScreenState extends State<QuestionsScreen> {
  List<Map<String, dynamic>> questions = []; // List of questions from the database
  Map<int, String> answers = {}; // Maps question_id to user's answer

  @override
  void initState() {
    super.initState();
    _fetchQuestions();
    _fetchAnswers();
  }

  // Fetch predefined questions from the database for the current user
  Future<void> _fetchQuestions() async {
    final db = DatabaseHelper.instance;
    final List<Map<String, dynamic>> fetchedQuestions = await db.database.then((db) => db.query(
      'questions',
      where: 'user_id = ?', // Filter questions by the current user
      whereArgs: [widget.userId],
    ));
    setState(() {
      questions = fetchedQuestions;
    });
  }

  // Fetch user's previous answers from the database
  Future<void> _fetchAnswers() async {
    final db = DatabaseHelper.instance;
    final List<Map<String, dynamic>> fetchedAnswers = await db.database.then((db) => db.query(
      'answers',
      where: 'user_id = ?', // Filter answers by the current user
      whereArgs: [widget.userId],
    ));
    setState(() {
      answers = {
        for (var answer in fetchedAnswers) answer['question_id']: answer['answer_text']
      };
    });
  }

  // Save an answer to the database
  Future<void> _saveAnswer(int questionId, String answerText) async {
    final db = DatabaseHelper.instance;
    await db.database.then((db) => db.insert(
      'answers',
      {
        'question_id': questionId,
        'user_id': widget.userId,
        'answer_text': answerText,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    ));
    setState(() {
      answers[questionId] = answerText;
    });
  }

  void _showAnswerScreen(int questionId, String questionText) {
    String previousAnswer = answers[questionId] ?? '';
    showDialog(
      context: context,
      builder: (context) {
        String answer = previousAnswer;
        return AlertDialog(
          title: Text(questionText),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                decoration: InputDecoration(labelText: 'Your answer'),
                controller: TextEditingController(text: previousAnswer),
                onChanged: (value) {
                  answer = value;
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                if (answer.isNotEmpty) {
                  _saveAnswer(questionId, answer);
                  _showPopupDialog(context);
                }
              },
              child: Text('Answer'),
            ),
          ],
        );
      },
    );
  }

  void _showPopupDialog(BuildContext context) {
    showOkAlertDialog(
      context: context,
      title: 'Confirmation',
      message: 'Your answer has been submitted. Click Next Question to continue.',
      okLabel: 'Next Question',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Center(
          child: Text(
            'List of Questions',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        backgroundColor: Colors.purple,
      ),
      body: Container(
        color: Colors.purple[100],
        child: questions.isEmpty
            ? Center(child: CircularProgressIndicator())
            : ListView.builder(
          itemCount: questions.length,
          itemBuilder: (context, index) {
            final question = questions[index];
            final questionId = question['id'];
            final questionText = question['question_text'];
            final hasAnswered = answers.containsKey(questionId);

            return Card(
              color: hasAnswered ? Colors.green[100] : Colors.white,
              child: ListTile(
                title: Text(
                  questionText,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: hasAnswered ? Colors.green[800] : Colors.black,
                  ),
                ),
                onTap: () {
                  _showAnswerScreen(questionId, questionText);
                },
                subtitle: hasAnswered
                    ? Text(
                  'Answered: ${answers[questionId]}',
                  style: TextStyle(color: Colors.green[700]),
                )
                    : null,
              ),
            );
          },
        ),
      ),
    );
  }
}
