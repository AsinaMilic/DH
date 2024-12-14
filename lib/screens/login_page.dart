import 'package:flutter/material.dart';
import 'package:flutter_login/flutter_login.dart';
import 'package:just_work/screens/question_screen.dart';
import 'dart:core';

import '../database/database_helper.dart';
import '../models/user.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  late int userId; // Add a field to store the userId

  // Loading time
  Duration get loadingTime => const Duration(milliseconds: 2000);

  // Login
  Future<String?> _authUser(LoginData data) async {
    String email = data.name;
    String password = data.password;
    DatabaseHelper dbHelper = DatabaseHelper.instance;
    User? user = await dbHelper.getUserByEmail(email);
    if (user != null) {
      String hashedInput = dbHelper.hashPassword(password);
      if (hashedInput == user.passwordHash) {
        userId = user.id!; // Store userId
        return null; // Success
      } else {
        return 'Invalid password'; // Error message
      }
    } else {
      return 'User not found'; // Error message
    }
  }

  // Forgot password
  Future<String?> _recoverPassword(String data) {
    return Future.delayed(loadingTime).then((value) => null);
  }

  // Sign up
  Future<String?> _signupUser(SignupData data) async {
    String? email = data.name;
    String? password = data.password;

    if (email == null || !_isEmailValid(email)) {
      return 'Please enter a valid email';
    }
    if (password == null || !_isPasswordValid(password)) {
      return 'Password must be at least 6 characters and contain letters and numbers';
    }

    DatabaseHelper dbHelper = DatabaseHelper.instance;

    try {
      User? user = await dbHelper.getUserByEmail(email);
      if (user != null) {
        return 'Email already in use';
      } else {
        String hashedPassword = dbHelper.hashPassword(password);
        User newUser = User(username: email, email: email, passwordHash: hashedPassword);
        int result = await dbHelper.insertUser(newUser);
        if (result > 0) {
          userId = result;
          try {
            await dbHelper.insertPredefinedQuestions(userId);
          } catch (e) {
            return 'Failed to insert predefined questions: $e';
          }
          return null; // Success
        } else {
          return 'Sign up failed';
        }
      }
    } catch (e) {
      return 'An error occurred: $e';
    }
  }

  bool _isEmailValid(String? email) {
    if (email == null) return false;
    // Simple email validation regex
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  bool _isPasswordValid(String? password) {
    if (password == null) return false;
    // Password should be at least 6 characters
    return password.length >= 6;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FlutterLogin(
        onLogin: _authUser,
        onRecoverPassword: _recoverPassword,
        onSignup: _signupUser,
        onSubmitAnimationCompleted: () {
          // Navigate to QuestionsScreen with the userId
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => QuestionsScreen(userId: userId),
            ),
          );
        },
      ),
    );
  }
}