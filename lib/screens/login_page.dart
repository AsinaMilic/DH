import 'package:flutter/material.dart';
import 'package:flutter_login/flutter_login.dart';
import 'dart:core';

import '../database/database_helper.dart';
import '../models/user.dart';
import 'first_screen.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  //loading time..
  Duration get loadingTime => const Duration(milliseconds: 2000);

  // login
  Future<String?> _authUser(LoginData data) async {
    String email = data.name;
    String password = data.password;
    DatabaseHelper dbHelper = DatabaseHelper.instance;
    User? user = await dbHelper.getUserByEmail(email);
    if (user != null) {
      String hashedInput = dbHelper.hashPassword(password);
      if (hashedInput == user.passwordHash) {
        return null; // Success
      } else {
        return 'Invalid password'; // Error message
      }
    } else {
      return 'User not found'; // Error message
    }
  }

  // forgot password
  Future<String?> _recoverPassword(String data) {
    return Future.delayed(loadingTime).then((value) => null);
  }

  // sign up
  Future<String?> _signupUser(SignupData data) async {
    String? email = data.name;
    String? password = data.password;

    // Validate email and password
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
        // Create User object with id set to null
        User newUser = User(username: email, email: email, passwordHash: hashedPassword);
        int result = await dbHelper.insertUser(newUser);
        if (result > 0) {
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
        // Preusmeri korisnika na FirstScreen nakon uspesnog logina
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => FirstScreen()),
          );
        },
      ),
    );
  }
}